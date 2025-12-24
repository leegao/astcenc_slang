// Each ASTC/BC block is 16x vec3 of RGBs
struct TextureBlock
{
    vector<uint8_t, 3> pixels[16];

    __subscript(uint n)->half3
    {
        get {
            return half3(pixels[n]) / 255;
        }
        set {
            pixels[n] = vector<uint8_t, 3>(round(newValue * 255));
        }
    }
};

// Diagnostics data
struct Diagnostics
{
    uint partition_hamming_error;
    float3 loss_log[12];
    uint2 start_clock;
    uint2 optim_ended_clock;
    uint2 finished_clock;
    uint2 timestamps[12];
    uint partition_hamming_error_log[12];
    uint ideal_partition_log[12];
    uint partition_count[12];
    float final_unquantized_loss;
};

struct Params
{
    float learning_rate;
    uint steps;
    uint steps_1p;
    uint snap_steps;
    uint num_blocks;
    bool snap;
    uint8_t max_partitions;
    bool debug_reconstruction;
    bool debug_quant;
    bool debug_loss;
    uint exact_steps;
    bool use_pca;
    uint seed;
    bool no_quantization;
    bool ensemble;
    bool exhaustive;
};
ConstantBuffer<Params> g_params;

// The image to encode (or to compute the loss of)
StructuredBuffer<TextureBlock> g_groundtruth;

// The reconstructed image
RWStructuredBuffer<TextureBlock> g_reconstructed;

// Diagnostics for this run
RWStructuredBuffer<Diagnostics> g_diagnostics;

// The ASTC/BC compressed block parameters for the 2-partition problem (ep0,ep1,ep2,ep3, 16x weights, 16x partition logits)
RWStructuredBuffer<CompressedTextureBlockPayload> g_compressedBlock3P;

// The loss of the encoded block
RWStructuredBuffer<float> g_final_loss;

// ASTC 2-partition LUT to snap a partition map to a valid astc partition seed
// StructuredBuffer<uint> g_astc_2p_4x4_lut_s2; // 2^15 entries (42.7KB)
// StructuredBuffer<uint> g_astc_3p_4x4_lut_s3; // 2 * 3^14 entries (12.2MB)

struct LUT
{
    uint lut2[1024]; // 1024-entry (4KB)
    uint lut3[1024]; // 1024-entry (4KB)
};
ConstantBuffer<LUT> g_lut;

#define LUT2_LOOKUP g_lut.lut2
#define LUT3_LOOKUP g_lut.lut3

struct Scratch
{
    uint16_t partitions[256];
    CompressedTextureBlockPayload blocks[4];
    // RankedSeeds ranked_seeds;
};

RWStructuredBuffer<Scratch> g_scratch;

static const uint8_t2 VALID_1P_QUANTIZATION_RANGES[5] = {
    // w, c
    { 31, 31 },  // (5b, 5b)
    { 23, 63 },  // (1t3b, 6b)
    { 19, 95 },  // (1q2b, 1t5b)
    { 15, 191 }, // (4b, 1t6b)
    { 11, 255 }, // (1t2b, 8b)
};

static const uint8_t2 VALID_2P_QUANTIZATION_RANGES[9] = {
    // w, c
    { 15, 5 }, // (4b, 1t1b)
    { 11, 9 }, // (1t2b, 1q1b)
    { 9, 11 }, // (1q1b, 1t2b)
    { 7, 15 }, // (3b, 4b)
    { 5, 23 }, // (1t1b, 1t3b)
    { 4, 31 }, // (1q, 5b)
    { 3, 39 }, // (2b, 1q3b)
    { 2, 63 }, // (1t, 6b)
    { 1, 95 }, // (1b, 1t5b)
};

static const uint8_t2 VALID_3P_QUANTIZATION_RANGES[6] = {
    // w, c
    { 7, 5 },  // (3b, 1t1b)
    { 5, 7 },  // (1t1b, 3b)
    { 4, 9 },  // (1q, 1q1b)
    { 3, 11 }, // (2b, 1t2b)
    { 2, 15 }, // (1t, 4b)
    { 1, 23 }, // (1b, 1t3b)
};

struct PCG32
{
    uint state;

    __init(uint seed)
    {
        this.state = seed * 747796405u + 2891336453u;
        this.state = ((this.state >> ((this.state >> 28u) + 4u)) ^ this.state) * 277803737u;
        this.state = (this.state >> 22u) ^ this.state;
    }

    [mutating]
    float nextFloat()
    {
        uint result = this.nextUint();
        return asfloat(0x3F800000u | (result >> 9)) - 1.0f;
    }

    [mutating]
    uint nextUint()
    {
        uint oldState = this.state;
        this.state = oldState * 747796405u + 2891336453u;
        uint word = ((oldState >> ((oldState >> 28u) + 4u)) ^ oldState) * 277803737u;
        return (word >> 22u) ^ word;
    }
}

static const uint M5 = 0x55555555; // 0101...
static const uint MA = 0xAAAAAAAA; // 1010...

uint8_t best_perm_distance_s3(uint x, uint y)
{
    uint base = x ^ y;
    uint not_x = ~x;
    uint x_shr1 = x >> 1;
    uint nz = (x | x_shr1) & M5;
    uint nz_shl1 = nz << 1;

    uint m01 = (~x_shr1) & M5;
    uint m02 = (~(x << 1)) & MA;
    uint m12 = nz | nz_shl1;
    uint m_cp = m01 | nz_shl1;
    uint m_cm = nz | ((not_x & M5) << 1);

    uint p0 = (count_diffs(base) << 3) | 0;
    uint p1 = (count_diffs(base ^ m01) << 3) | 1;
    uint p2 = (count_diffs(base ^ m02) << 3) | 2;
    uint p3 = (count_diffs(base ^ m12) << 3) | 3;
    uint p4 = (count_diffs(base ^ m_cp) << 3) | 4;
    uint p5 = (count_diffs(base ^ m_cm) << 3) | 5;

    uint min01 = min(p0, p1);
    uint min23 = min(p2, p3);
    uint min45 = min(p4, p5);
    uint best = min(min(min01, min23), min45);

    return uint8_t(best >> 3);
}

uint8_t best_perm_distance_s2(uint x, uint y)
{
    uint base = x ^ y;
    uint x_shr1 = x >> 1;

    uint m01 = (~x_shr1) & M5;

    uint p0 = (count_diffs(base) << 1) | 0;
    uint p1 = (count_diffs(base ^ m01) << 1) | 1;

    uint min01 = min(p0, p1);

    return uint8_t(min01 >> 1);
}

uint8_t hamming_distance_2b(uint x, uint y)
{
    uint z = x ^ y;
    z |= z >> 1;
    z &= 0x55555555;
    return uint8_t(countbits(z));
}

uint8_t count_diffs(uint val)
{
    return uint8_t(countbits((val | (val >> 1)) & 0x55555555));
}

T quantize<T : __BuiltinFloatingPointType>(T value, uint range = 255)
{
    T scale = T(range);
    return round(value * scale) / scale;
}

vector<E, M> quantize<E : __BuiltinFloatingPointType, let M : int>(vector<E, M> value, uint range = 255)
{
    vector<E, M> scale = vector<E, M>(E(range));
    return round(value * scale) / scale;
}

struct BF8Weights
{
    uint8_t data[16];
    __subscript(int n)->half
    {
        get {
            // Best weight quant is 5b for 1p, 4b for 2p, 3b for 3p
            // Promote it to 63 in case we need to do ep scaling
            return half(data[n]) / 63;
        }
        set {
            data[n] = uint8_t(round(saturate(newValue) * 63));
        }
    }

    [mutating] void quantize(uint8_t range = 255)
    {
        for (int i = 0; i < 16; i++)
        {
            this[i] = quantize(this[i], range);
        }
    }
}

struct PartitionMap
{
    uint data;
    __subscript(int n)->uint8_t
    {
        get {
            return uint8_t((data >> (n * 2)) & 3);
        }
        set {
            data = (data & ~(3 << (n * 2))) | (newValue << (n * 2));
        }
    }
}

// #define STATIC_GROUND_TRUTH
#define GLOBAL_GROUND_TRUTH

#ifdef STATIC_GROUND_TRUTH
static TextureBlock my_groundtruth;
#define groundtruth my_groundtruth
#else
#ifdef GLOBAL_GROUND_TRUTH
#define groundtruth g_groundtruth[blockIdx]
#else
#define SHARED_GROUND_TRUTH
groupshared TextureBlock s_groundtruth[64];
#define groundtruth s_groundtruth[blockIdx % 64]
#endif
#endif

struct SharedScratchPad
{
    CompressedTextureBlockPayload blocks[2];
}

// groupshared SharedScratchPad s_scratch[64];

// #define SCRATCH_BLOCKS(i) (i == 0 ? g_scratch[blockIdx].blocks[i] : s_scratch[blockIdx % 64].blocks[i - 1])
// #define SET_SCRATCH_BLOCKS(i, f, v)          \
//     if (i == 0)                              \
//         g_scratch[blockIdx].blocks[i].f = v; \
//     else                                     \
//         s_scratch[blockIdx % 64].blocks[i - 1].f = v;
#define SCRATCH_BLOCKS(i) g_scratch[blockIdx].blocks[i]
#define SET_SCRATCH_BLOCKS(i, f, v) g_scratch[blockIdx].blocks[i].f = v
// #define SCRATCH_BLOCKS(i) s_scratch[blockIdx % 64].blocks[i]
// #define SET_SCRATCH_BLOCKS(i, f, v) s_scratch[blockIdx % 64].blocks[i].f = v

interface ICompressedTextureBlockPayload
{
#define PROPERTY(name, T) property T name { get; set; }

    PROPERTY(_ep0, uint8_t3)
    PROPERTY(_ep1, uint8_t3)
    PROPERTY(_ep2, uint8_t3)
    PROPERTY(_ep3, uint8_t3)
    PROPERTY(_ep4, uint8_t3)
    PROPERTY(_ep5, uint8_t3)
    PROPERTY(qwc, uint8_t2)
    PROPERTY(weights, BF8Weights)
    PROPERTY(partition_map, PartitionMap)
    PROPERTY(ideal_partition_map, PartitionMap)
    PROPERTY(astc_seed, uint16_t)
    PROPERTY(perm, uint8_t)
    PROPERTY(max_partitions, uint8_t)

    [mutating]
    void set(CompressedTextureBlockProxyPayload other);
    [mutating]
    void set(CompressedTextureBlockPayload other);
#undef PROPERTY
}

struct CompressedTextureBlockPayload : ICompressedTextureBlockPayload
{
    uint8_t perm;
    uint8_t3 _ep0, _ep1; // partition 1
    uint8_t3 _ep2, _ep3; // partition 2
    uint8_t3 _ep4, _ep5; // partition 2

    BF8Weights weights;         // we don't have to gradient descent on this since we can do a full solve
    PartitionMap partition_map; // Partition blend logits
    PartitionMap ideal_partition_map;
    uint16_t astc_seed;
    uint8_t max_partitions;
    uint8_t2 qwc;

    [mutating]
    void set(CompressedTextureBlockPayload other)
    {
        this = other;
    }

    [mutating]
    void set(CompressedTextureBlockProxyPayload other)
    {
        this = SCRATCH_BLOCKS(other.index);
    }
}

struct CompressedTextureBlockProxyPayload : ICompressedTextureBlockPayload
{
    int8_t index;
#define GET_FIELD(f) SCRATCH_BLOCKS(index).f
#define SET_FIELD(f) SET_SCRATCH_BLOCKS(index, f, newValue)
#define PROPERTY(f, T)           \
    property T f                 \
    {                            \
        get {                    \
            return GET_FIELD(f); \
        }                        \
        set {                    \
            SET_FIELD(f);        \
        }                        \
    }
    PROPERTY(_ep0, uint8_t3)
    PROPERTY(_ep1, uint8_t3)
    PROPERTY(_ep2, uint8_t3)
    PROPERTY(_ep3, uint8_t3)
    PROPERTY(_ep4, uint8_t3)
    PROPERTY(_ep5, uint8_t3)
    PROPERTY(qwc, uint8_t2)
    PROPERTY(weights, BF8Weights)
    PROPERTY(partition_map, PartitionMap)
    PROPERTY(ideal_partition_map, PartitionMap)
    PROPERTY(astc_seed, uint16_t)
    PROPERTY(perm, uint8_t)
    PROPERTY(max_partitions, uint8_t)
#undef PROPERTY
#undef GET_FIELD
#undef SET_FIELD
    [mutating]
    void set(CompressedTextureBlockProxyPayload other)
    {
        g_scratch[blockIdx].blocks[index] = g_scratch[blockIdx].blocks[other.index];
    }
    [mutating]
    void set(CompressedTextureBlockPayload other)
    {
        g_scratch[blockIdx].blocks[index] = other;
    }
}

// The ASTC/BC encoder problem (single-partition) is to solve for
struct CompressedTextureBlock<T : ICompressedTextureBlockPayload>
{
    // CompressedTextureBlockPayload payload; // use vregs
    // CompressedTextureBlockProxyPayload payload; // use dram
    T payload;

#define EP_PROPERTY(ep, _ep)                                         \
    property half3 ep                                                \
    {                                                                \
        get {                                                        \
            return half3(payload._ep) / 255;                         \
        }                                                            \
        set {                                                        \
            payload._ep = uint8_t3(round(saturate(newValue) * 255)); \
        }                                                            \
    }
    EP_PROPERTY(ep0, _ep0)
    EP_PROPERTY(ep1, _ep1)
    EP_PROPERTY(ep2, _ep2)
    EP_PROPERTY(ep3, _ep3)
    EP_PROPERTY(ep4, _ep4)
    EP_PROPERTY(ep5, _ep5)
#undef EP_PROPERTY

#define PROPERTY(f, T)            \
    property T f                  \
    {                             \
        get {                     \
            return payload.f;     \
        }                         \
        set {                     \
            payload.f = newValue; \
        }                         \
    }
    PROPERTY(weights, BF8Weights)
    PROPERTY(partition_map, PartitionMap)
    PROPERTY(ideal_partition_map, PartitionMap)
    PROPERTY(astc_seed, uint16_t)
    PROPERTY(perm, uint8_t)
    PROPERTY(max_partitions, uint8_t)
    PROPERTY(qwc, uint8_t2)
#undef PROPERTY

    [mutating]
    void set_astc_seed(uint16_t seed)
    {
        // Called up to 3 x (128 or 1024) times total
        astc_seed = seed;
        partition_map = max_partitions == 2 ? PartitionMap(LUT2_LOOKUP[seed]) : PartitionMap(LUT3_LOOKUP[seed]);
    }

    [mutating]
    void solve_weights()
    {
        // Called up to 3 times total
        let L1 = ep1 - ep0;
        let L2 = ep3 - ep2;
        let L3 = ep5 - ep4;
        let invLenSq1 = 1.0h / (dot(L1, L1) + 0.000001h);
        let invLenSq2 = 1.0h / (dot(L2, L2) + 0.000001h);
        let invLenSq3 = 1.0h / (dot(L3, L3) + 0.000001h);
        let partition_map = this.partition_map;
        for (int i = 0; i < 16; i++)
        {
            let C = groundtruth[i];
            let p = partition_map[i];
            let pDotL = p == 0 ? dot(C - ep0, L1) : (p == 1 ? dot(C - ep2, L2) : dot(C - ep4, L3));
            let invLenSq = p == 0 ? invLenSq1 : (p == 1 ? invLenSq2 : invLenSq3);
            let w = pDotL * invLenSq;
            weights[i] = saturate(w);
        }
    }

    void decompress()
    {
        // Called once
        for (uint8_t i = 0; i < 16; i++)
        {
            let p = partition_map[i];
            let e0 = p == 0 ? ep0 : (p == 1 ? ep2 : ep4);
            let e1 = p == 0 ? ep1 : (p == 1 ? ep3 : ep5);
            g_reconstructed[blockIdx][i] = lerp(e0, e1, weights[i]);
        }
    }

    void reconstruct()
    {
        // if (g_params.debug_reconstruction)
        // {
        //     TextureBlock outputBlock;
        //     for (int i = 0; i < 16; i++)
        //     {
        //         float w = round(weights[i] * 4) / 4;
        //         int partition = clamp(partition_map[i], 0, 2);
        //         float3 e0 = partition == 0 ? ep0 : (partition == 1 ? ep2 : ep4);
        //         float3 e1 = partition == 0 ? ep1 : (partition == 1 ? ep3 : ep5);
        //         float3 c = partition == 0 ? float3(1, 1, 1) : (partition == 1 ? float3(0.5, 0.5, 0.5) : float3(0, 0, 0));
        //         outputBlock[i] = c; // lerp(e0, e1, w);
        //     }
        //     return outputBlock;
        // }
        // if (g_params.debug_loss)
        // {
        //     TextureBlock outputBlock;
        //     for (int i = 0; i < 16; i++)
        //     {
        //         float w = weights[i];
        //         int partition = clamp(partition_map[i], 0, 2);
        //         float3 e0 = partition == 0 ? ep0 : (partition == 1 ? ep2 : ep4);
        //         float3 e1 = partition == 0 ? ep1 : (partition == 1 ? ep3 : ep5);
        //         float3 c = lerp(e0, e1, w);
        //         outputBlock[i] = abs(groundtruth[i] - c);
        //     }
        //     return outputBlock;
        // }
        // if (g_params.debug_quant)
        // {
        //     TextureBlock outputBlock;
        //     for (int i = 0; i < 16; i++)
        //     {
        //         // R - 5,7,9 / 0, 0.5, 0.85
        //         // B - 11,15,23 / 1.14, 1.6, 2.2
        //         // G - 31,33,39 / 2.6, 2.7, 2.96
        //         // M - 63,95,191,255 / 3.65, 4.25, 5.25, 5.67
        //         // 3P - [5,7,9,11,15,23] - R to B
        //         // 2P - [5,9,11,15,23,31,39,63,95] R - M
        //         // 1P - [31,63,95,191,255] - G - M
        //         let R = float3(1, 0, 0);
        //         let G = float3(0, 1, 0);
        //         let B = float3(0, 0, 1);
        //         let M = float3(1, 0, 1);
        //         float3 c = 0;
        //         switch (payload.qwc.y)
        //         {
        //         case 5:
        //             c = R * 0.33;
        //             break;
        //         case 7:
        //             c = R * 0.67;
        //             break;
        //         case 9:
        //             c = R;
        //             break;

        //         case 11:
        //             c = B * 0.33;
        //             break;
        //         case 15:
        //             c = B * 0.50;
        //             break;
        //         case 23:
        //             c = B;
        //             break;

        //         case 31:
        //             c = G * 0.33;
        //             break;
        //         case 33:
        //             c = G * 0.50;
        //             break;
        //         case 39:
        //             c = G;
        //             break;

        //         case 63:
        //             c = M * 0.33;
        //             break;
        //         case 95:
        //             c = M * 0.67;
        //             break;
        //         case 191:
        //             c = M * 0.9;
        //             break;
        //         case 255:
        //             c = M;
        //             break;
        //         }

        //         outputBlock[i] = c; // lerp(e0, e1, w);
        //     }
        //     return outputBlock;
        // }
        decompress();
        return;
    }
};

// Potentially use this vs solve_aabb_for_partition
void solve_pca_eps<T : ICompressedTextureBlockPayload>(inout CompressedTextureBlock<T> block, inout half3 ep0, inout half3 ep1, uint8_t partition_id)
{
    // Called up to 9 times total
    let old_ep1 = ep1;
    let old_ep0 = ep0;
    half3 axis = half3(0.17h, 0.83h, 0.38h);
    half3 centroid = half3(0);
    uint8_t count = 0;

    for (uint8_t i = 0; i < 16; i++)
    {
        if (block.partition_map[i] == partition_id)
        {
            centroid += groundtruth[i];
            count += 1;
        }
    }
    centroid /= half(count);

    if (count == 0)
        return;

    if (count == 1)
    {
        ep0 = saturate(centroid);
        ep1 = saturate(centroid);
        return;
    }

    half3x3 C = (half3x3)0;
    for (uint8_t i = 0; i < 16; i++)
    {
        if (block.partition_map[i] == partition_id)
        {
            half3 d = groundtruth[i] - centroid;
            C[0] += d.x * d; // Row 0: [xx, xy, xz]
            C[1] += d.y * d; // Row 1: [yx, yy, yz]
            C[2] += d.z * d; // Row 2: [zx, zy, zz]
        }
    }
    C /= half(count);

    // Check for degenerate cases of single color (low trace of C)
    var trace = C[0].x + C[1].y + C[2].z;
    if (trace < 3e-4)
    {
        ep0 = saturate(centroid);
        ep1 = saturate(centroid);
        return;
    }

    for (int iter = 0; iter < 4; iter++)
    {
        axis = mul(C, axis);
        var lenSq = dot(axis, axis);
        if (lenSq > 1e-8)
        {
            axis *= rsqrt(lenSq);
        }
    }

    // The data is isotropic (C ~ I), so any direction passing through the centroid is valid
    if (dot(axis, axis) < 1e-8)
    {
        ep0 = saturate(centroid);
        return;
    }

    axis = normalize(axis);
    var min_t = 1000.0h;
    var max_t = -1000.0h;

    for (int i = 0; i < 16; i++)
    {
        if (block.partition_map[i] == partition_id)
        {
            var d = groundtruth[i] - centroid;
            var t = dot(d, axis);
            min_t = min(min_t, t);
            max_t = max(max_t, t);
        }
    }

    ep0 = saturate(centroid + axis * (min_t));
    ep1 = saturate(centroid + axis * (max_t));
}

float loss_mse<T : ICompressedTextureBlockPayload>(CompressedTextureBlock<T> block, vector<uint8_t, 2> quant = { 255, 255 })
{
    // Called up to 3 + 5 + 9 + 6 times total
    float totalError = 0.0f;
    let partition_map = block.partition_map;
    for (uint8_t i = 0; i < 16; i++)
    {
        let p = partition_map[i];
        let e0 = quantize(p == 0 ? block.ep0 : (p == 1 ? block.ep2 : block.ep4), quant.y);
        let e1 = quantize(p == 0 ? block.ep1 : (p == 1 ? block.ep3 : block.ep5), quant.y);
        var diff = lerp(e0, e1, quantize(block.weights[i], quant.x)) - groundtruth[i];
        totalError += dot(diff, diff);
    }
    return totalError;
}

half estimate_partition_error_bound(half3x3 scatter_matrix)
{
    // Called (1 + 2 + 3) x 3 x (128 or 1024) times total
    var total_variance = scatter_matrix[0][0] + scatter_matrix[1][1] + scatter_matrix[2][2];
    var axis = half3(0.17h, 0.83h, 0.38h);

    // Two rounds of power iteration to approximate the principle component (lambda_max)
    axis = mul(scatter_matrix, axis);
    axis *= rsqrt(dot(axis, axis) + 0.000001h);
    axis = mul(scatter_matrix, axis);
    // Residue = variance - maximum lambda (from the 2 rounds of power iteration)
    var lambda_max = sqrt(dot(axis, axis));
    return max(0.0h, total_variance - lambda_max);
}

// Scans the partition map and computes the lower bound error cheaply
half compute_error_fast<let max_partitions : int, T : ICompressedTextureBlockPayload>(CompressedTextureBlock<T> block)
{
    // Called up to 3 x 128 (normal) or 3 x 1024 (exhaustive) times total
    half3 means[max_partitions] = {};

    // Cov x count
    half3x3 scatters[max_partitions] = {};
    uint8_t counts[max_partitions] = {};
    let partition_map = block.partition_map;
    for (uint8_t i = 0; i < 16; i++)
    {
        let p = partition_map[i];
        let px = groundtruth[i];

        means[p] += px;
        counts[p] += 1;

        // S = Sum(x*xT) - n * mean*meanT
        scatters[p][0] += px.x * px;
        scatters[p][1] += px.y * px;
        scatters[p][2] += px.z * px;
    }

    half loss = 0;
    for (uint8_t p = 0; p < max_partitions; p++)
    {
        if (counts[p] > 0)
        {
            let m = means[p];
            let count = half(counts[p]);
            scatters[p][0] -= (m.x / count) * m;
            scatters[p][1] -= (m.y / count) * m;
            scatters[p][2] -= (m.z / count) * m;
            loss += estimate_partition_error_bound(scatters[p]);
        }
    }

    return loss;
}

struct PartitionSet
{
    uint data[32]; // 1024 bit mask
    __subscript(uint16_t n)->bool
    {
        get
        {
            return bool(data[n >> 5] & (1 << (n & 0x1f)));
        }
        set
        {
            uint mask = data[n >> 5];
            uint bits = (1 << (n & 0x1f));
            data[n >> 5] = newValue ? mask | bits : mask & (~bits);
        }
    }
}

// #define RADV_DEBUG

#ifdef RADV_DEBUG
#define DEBUG1(i, X) g_diagnostics[getRealtimeClockLow() % 64].partition_count[i] = ((0xCAFE0000) | ((X) & 0xFFFF))
#define DEBUG2(i, X) g_diagnostics[getRealtimeClockLow() % 64].partition_count[i] = ((0xBABE0000) | ((X) & 0xFFFF))
#else
#define DEBUG1(i, X)
#define DEBUG2(i, X)
#endif
#define L(X) (X << 12) | __LINE__

void cluster<let max_partitions : int>(inout PartitionMap partition_map)
{
    DEBUG1(0, L(max_partitions));
    half3 centroids[max_partitions];
    uint8_t partition_counts[max_partitions];

    [unroll]
    for (uint8_t k = 0; k < max_partitions; k++)
    {
        centroids[k] = groundtruth[(k * 4) % 16];
    }

    for (uint8_t iter = 0; iter < 3; iter++)
    {
        // Reset counts
        [unroll]
        for (uint8_t c = 0; c < max_partitions; c++)
            partition_counts[c] = 0;

        for (uint8_t i = 0; i < 16; i++)
        {
            var p = groundtruth[i];

            var best_dist = 1000.0h;
            uint8_t best_centroid = 0;

            // Nearest centroid through projection
            for (uint8_t centroid = 0; centroid < max_partitions; centroid++)
            {
                var delta = p - centroids[centroid];
                var d = dot(delta, delta);
                if (d < best_dist)
                {
                    best_dist = d;
                    best_centroid = centroid;
                }
            }

            partition_map[i] = best_centroid;
            partition_counts[best_centroid]++;
        }

        var changed_map = false;
        for (uint8_t p = 0; p < max_partitions; p++)
        {
            if (partition_counts[p] == 0)
            {
                // Steal a pixel from another partition to restart this one
                uint8_t steal_idx = (p * 4 + 1) % 16;
                uint8_t victim_p = partition_map[steal_idx];
                if (partition_counts[victim_p] > 1)
                {
                    partition_map[steal_idx] = p;
                    partition_counts[p]++;
                    partition_counts[victim_p]--;
                    changed_map = true;
                }
            }
        }

        // Update centroids
        if (iter < 2 || changed_map)
        {
            half3 new_sums[max_partitions] = {};
            for (uint8_t i = 0; i < 16; i++)
            {
                var p = groundtruth[i];
                var idx = partition_map[i];
                new_sums[idx] += p;
            }
            for (uint8_t centroid = 0; centroid < max_partitions; centroid++)
            {
                var count = partition_counts[centroid];
                if (count != 0)
                {
                    centroids[centroid] = new_sums[centroid] / half(count);
                }
            }
        }
    }

    DEBUG2(0, L(max_partitions));
}

#define MAX_DISTANCE 8
#define MAX_SLOTS 12 // Reduced from 16 to 12 to get down to <8k LDS

// #define STATIC_RANKED_SEEDS // needs MAX_SLOTS >= 25 (256b threshold) to force register spilling to avoid vregs explosion
// #define GLOBAL_RANKED_SEEDS
#define SHARED_RANKED_SEEDS // needs MAX_SLOTS <= 18 (192b - 204b), otherwise the extra speculative execution scales with MAX_SLOTS

#ifdef STATIC_RANKED_SEEDS
static RankedSeeds ranked_seeds;
#else
#ifdef GLOBAL_RANKED_SEEDS
#define ranked_seeds g_scratch[blockIdx].ranked_seeds
#else
groupshared RankedSeeds s_ranked_seeds[64];
#define ranked_seeds s_ranked_seeds[blockIdx % 64]
#endif
#endif

#define PACKED_SEEDS_MASKS

struct RankedSeeds
{
#ifndef PACKED_SEEDS_MASKS
    uint16_t seeds_masks[MAX_DISTANCE * MAX_SLOTS];
#define RANKSEEDS_GET(seeds, n) seeds.seeds_masks[n]
#define RANKSEEDS_ADD(seeds, n, v) seeds.seeds_masks[n] = v
#else
    uint seeds_masks[(MAX_DISTANCE * MAX_SLOTS + 2) / 3]; // 10 bits packed into 32 bits
#define RANKSEEDS_GET(seeds, n) uint16_t(seeds.seeds_masks[n / 3] >> uint((n % 3) * 10)) & 0x3FF
#define RANKSEEDS_ADD(seeds, n, v) seeds.seeds_masks[n / 3] |= uint(v) << uint((n % 3) * 10)
#endif
}

bool RankedSeeds_add(uint16_t seed, uint16_t distance, uint8_t slots, inout uint8_t counts[MAX_DISTANCE])
{
    let count = counts[distance];
    if (count < slots)
    {
        let n = distance * MAX_SLOTS + count;
        RANKSEEDS_ADD(ranked_seeds, n, seed + 1);
        counts[distance] = count + 1;
        return true;
    }
    return false;
}

int16_t RankedSeeds_next(inout uint8_t cursor)
{
    for (; cursor < MAX_DISTANCE * MAX_SLOTS; cursor++)
    {
        let seed = RANKSEEDS_GET(ranked_seeds, cursor);
        if (seed == 0)
        {
            continue;
        }
        cursor++;
        return seed - 1;
    }
    return -1;
}

uint8_t find_top_partitions<let max_partitions : int, T : ICompressedTextureBlockPayload>(
    inout CompressedTextureBlock<T> block,
    uint candidates,
    inout uint16_t i)
{
    PartitionMap ideal_map;
    let is_p2 = max_partitions == 2;
    let slots : uint8_t = uint8_t(clamp(candidates / 8, 2, MAX_SLOTS));
    uint8_t distances[MAX_DISTANCE] = { 0 };
    uint8_t count = 0;

    cluster<max_partitions>(ideal_map);

    DEBUG1(1, L(max_partitions));
    block.ideal_partition_map = ideal_map;
    ranked_seeds = RankedSeeds();

    for (i = 0; i < 1024; i++)
    {
        var final_map = is_p2 ? LUT2_LOOKUP[i] : LUT3_LOOKUP[i];
        var dist = is_p2 ? best_perm_distance_s2(ideal_map.data, final_map)
                         : best_perm_distance_s3(ideal_map.data, final_map);
        if (dist < MAX_DISTANCE)
        {
            count += RankedSeeds_add(i, uint8_t(dist), slots, distances);
            if (count >= MAX_SLOTS * MAX_DISTANCE)
            {
                break;
            }
        }
    }

    DEBUG2(1, L(max_partitions));
    return count;
}

#define diagnostics g_diagnostics[blockIdx]
float optimize<let max_partitions : int, T : ICompressedTextureBlockPayload>(
    inout CompressedTextureBlock<T> block,
    uint steps,
    bool diagnostics_enabled,
    bool exhaustive = false)
{
    // Called up to 3 times total
    var candidates = max_partitions == 1 ? 0 : steps;
    uint16_t max_seeds_checked = 0;
    uint8_t nearest_neighbors = 0;
    if ((!exhaustive) && max_partitions > 1)
    {
        // This is ~100ms on cat.jpg (129600 threads)
        nearest_neighbors = find_top_partitions<max_partitions>(block, steps, max_seeds_checked);
    }

    float best_loss = 1000;
    uint16_t best_candidate_id = 0;
    uint16_t best_seed = 0;
    uint8_t cursor = 0;

    // Search for the best loss and parameters
    // [loop]
    for (uint16_t candidate_id = 0; candidate_id < candidates; candidate_id++)
    {
        var next_unchecked_seed = candidate_id - nearest_neighbors + max_seeds_checked;
        int16_t seed = exhaustive ? candidate_id : (candidate_id < nearest_neighbors ? RankedSeeds_next(cursor) : next_unchecked_seed);
        block.set_astc_seed(seed);
        float loss = compute_error_fast<max_partitions>(block);

        if (loss < best_loss)
        {
            best_loss = loss;
            best_candidate_id = candidate_id;
            best_seed = seed;
        }

        if (diagnostics_enabled && candidate_id < 10)
        {
            diagnostics.timestamps[candidate_id] = getRealtimeClock();
            diagnostics.loss_log[candidate_id][max_partitions - 1] = loss;
        }
    }

    if (max_partitions > 1)
    {
        block.set_astc_seed(best_seed);
    }
    solve_pca_eps(block, block.ep0, block.ep1, 0);
    if (max_partitions > 1)
        solve_pca_eps(block, block.ep2, block.ep3, 1);
    if (max_partitions > 2)
        solve_pca_eps(block, block.ep4, block.ep5, 2);
    block.solve_weights();

    float loss = best_loss;
    // if (diagnostics_enabled)
    // {
    //     loss = loss_mse(block);
    //     diagnostics.loss_log[11][max_partitions - 1] = loss;
    // }

    // block.astc_seed = best_candidate_id;

    // block.perm = max_partitions == 2 ? best_perm_distance_s2(block.ideal_partition_map.data, block.partition_map.data)
    //                                  : best_perm_distance_s3(block.ideal_partition_map.data, block.partition_map.data);
    return loss;
}

// #undef groundtruth
#undef diagnostics
// #undef partitions

static uint blockIdx; // the dedicated register for the block index

float find_best_quantization<let max_partitions : int, T : ICompressedTextureBlockPayload>(
    inout CompressedTextureBlock<T> block)
{
    // Called up to 3 times total
    if (g_params.no_quantization)
    {
        block.payload.qwc = { 255, 255 };
        return loss_mse(block);
    }

    float best_loss = 1000.0;
    uint8_t2 best_wc;
    let steps = max_partitions == 1 ? 5 : (max_partitions == 2 ? 9 : 6);
    for (uint8_t i = 0; i < steps; i++)
    {
        var wc = max_partitions == 1
                     ? VALID_1P_QUANTIZATION_RANGES[i]
                     : (max_partitions == 2 ? VALID_2P_QUANTIZATION_RANGES[i]
                                            : VALID_3P_QUANTIZATION_RANGES[i]);
        if (wc.x == 0)
            continue;

        let loss = loss_mse(block, wc);
        if (loss < best_loss || i == 0)
        {
            best_loss = loss;
            best_wc = wc;
        }
    }
    block.payload.qwc = best_wc;
    return best_loss;
}

// [require(spvShaderClockKHR)]

[shader("compute")]
// [amd_waves_per_eu(4, 8)]
[numthreads(64, 1, 1)]
void compress_3P_step(uint3 dispatchThreadID: SV_DispatchThreadID)
{
    blockIdx = dispatchThreadID.x;
    if (blockIdx >= g_params.num_blocks)
        return;
    g_diagnostics[blockIdx].start_clock = getRealtimeClock();

#ifdef STATIC_GROUND_TRUTH
    my_groundtruth = g_groundtruth[blockIdx];
#endif
#ifdef SHARED_GROUND_TRUTH
    groundtruth = g_groundtruth[blockIdx];
#endif

    var prng = PCG32(g_params.seed);
    var block = CompressedTextureBlock<CompressedTextureBlockProxyPayload>(0);
    float unquantized_loss = 1000.0f;
    float quantized_loss = 1000.0f;

    let exhaustive = g_params.exhaustive;
    // let exhaustive = false;
    let ensemble = g_params.ensemble;
    // let ensemble = false;
    let diagnostics = true;
    let steps = g_params.steps;

    // The loop variant of this is much slower
    // [unroll]
    // for (uint8_t p = 1; p <= g_params.max_partitions; p++)
    // {
    //     block1.max_partitions = p;
    //     float unquantized_loss1 = exhaustive ? optimize<true>(block1, steps, diagnostics)
    //                                          : optimize<false>(block1, steps, diagnostics);
    //     float quantized_loss1 = block1.quantize();
    //     if (quantized_loss1 < quantized_loss)
    //     {
    //         quantized_loss = quantized_loss1;
    //         unquantized_loss = unquantized_loss1;
    //         block.payload.set(block1.payload);
    //     }
    // }

    float unquantized_loss1, quantized_loss1;
    block.max_partitions = 1;
    unquantized_loss = optimize<1>(block, steps, diagnostics);
    quantized_loss = find_best_quantization<1>(block);
    if (g_params.max_partitions >= 2)
    {
        var block1 = CompressedTextureBlock<CompressedTextureBlockProxyPayload>(1);
        block1.max_partitions = 2;
        unquantized_loss1 = optimize<2>(block1, steps, diagnostics, exhaustive);
        quantized_loss1 = find_best_quantization<2>(block1);
        if (quantized_loss1 < quantized_loss)
        {
            quantized_loss = quantized_loss1;
            unquantized_loss = unquantized_loss1;
            var tmp = block;
            block = block1;
            block1 = tmp;
        }
        if (g_params.max_partitions == 3)
        {
            block1.max_partitions = 3;
            unquantized_loss1 = optimize<3>(block1, steps, diagnostics, exhaustive);
            quantized_loss1 = find_best_quantization<3>(block1);
            if (quantized_loss1 < quantized_loss)
            {
                quantized_loss = quantized_loss1;
                unquantized_loss = unquantized_loss1;
                var tmp = block;
                block = block1;
                block1 = tmp;
            }
        }
    }

    g_diagnostics[blockIdx].optim_ended_clock = getRealtimeClock();

    let best_wc = block.payload.qwc;
    block.ep0 = quantize(block.ep0, best_wc.y);
    block.ep1 = quantize(block.ep1, best_wc.y);
    block.ep2 = quantize(block.ep2, best_wc.y);
    block.ep3 = quantize(block.ep3, best_wc.y);
    block.ep4 = quantize(block.ep4, best_wc.y);
    block.ep5 = quantize(block.ep5, best_wc.y);
    block.weights.quantize(best_wc.x);

    block.reconstruct();
    g_compressedBlock3P[blockIdx].set(block.payload);
    // g_reconstructed[blockIdx] = block.reconstruct();
    g_diagnostics[blockIdx].final_unquantized_loss = unquantized_loss;
    g_final_loss[blockIdx] = quantized_loss;
    g_diagnostics[blockIdx].finished_clock = getRealtimeClock();
}
