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

#define groundtruth g_groundtruth[blockIdx]

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

static const vector<uint8_t, 2> VALID_1P_QUANTIZATION_RANGES[9] = {
    // w, c
    { 31, 31 },  // (5b, 5b)
    { 23, 63 },  // (1t3b, 6b)
    { 19, 95 },  // (1q2b, 1t5b)
    { 15, 191 }, // (4b, 1t6b)
    { 11, 255 }, // (1t2b, 8b)
    { 0, 0 },    // Padding
    { 0, 0 },    // Padding
    { 0, 0 },    // Padding
    { 0, 0 },    // Padding
};

static const vector<uint8_t, 2> VALID_2P_QUANTIZATION_RANGES[9] = {
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

static const vector<uint8_t, 2> VALID_3P_QUANTIZATION_RANGES[9] = {
    // w, c
    { 7, 5 },  // (3b, 1t1b)
    { 5, 7 },  // (1t1b, 3b)
    { 4, 9 },  // (1q, 1q1b)
    { 3, 11 }, // (2b, 1t2b)
    { 2, 15 }, // (1t, 4b)
    { 1, 23 }, // (1b, 1t3b)
    { 0, 0 },  // Padding
    { 0, 0 },  // Padding
    { 0, 0 },  // Padding
};

public struct PCG32
{
    uint state;

    public __init(uint seed)
    {
        this.state = seed * 747796405u + 2891336453u;
        this.state = ((this.state >> ((this.state >> 28u) + 4u)) ^ this.state) * 277803737u;
        this.state = (this.state >> 22u) ^ this.state;
    }

    [mutating]
    public float nextFloat()
    {
        uint result = this.nextUint();
        return asfloat(0x3F800000u | (result >> 9)) - 1.0f;
    }

    [mutating]
    public uint nextUint()
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
        [unroll]
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

struct CompressedTextureBlockPayload
{
    uint8_t perm;
    vector<uint8_t, 3> _ep0, _ep1; // partition 1
    vector<uint8_t, 3> _ep2, _ep3; // partition 2
    vector<uint8_t, 3> _ep4, _ep5; // partition 2

    BF8Weights weights;         // we don't have to gradient descent on this since we can do a full solve
    PartitionMap partition_map; // Partition blend logits
    PartitionMap ideal_partition_map;
    uint16_t astc_seed;
    uint8_t max_partitions;
    vector<uint8_t, 2> qwc;

    [mutating]
    void set(CompressedTextureBlockPayload other)
    {
        this = other;
    }

    [mutating]
    void set(CompressedTextureBlockProxyPayload other)
    {
        // var other_index = other.index;
        this = true ? SCRATCH_BLOCKS(other.index)
                    : g_compressedBlock3P[blockIdx];
    }
}

struct CompressedTextureBlockProxyPayload
{
    int8_t index;
#define GET_FIELD(f) true ? SCRATCH_BLOCKS(index).f : g_compressedBlock3P[blockIdx].f
#define SET_FIELD(f)                            \
    if (true)                                   \
    {                                           \
        SET_SCRATCH_BLOCKS(index, f, newValue); \
    }                                           \
    else                                        \
        g_compressedBlock3P[blockIdx].f = newValue;
#define EP_PROPERTY(f, n)         \
    property vector<uint8_t, n> f \
    {                             \
        get {                     \
            return GET_FIELD(f);  \
        }                         \
        set {                     \
            SET_FIELD(f);         \
        }                         \
    }
    EP_PROPERTY(_ep0, 3)
    EP_PROPERTY(_ep1, 3)
    EP_PROPERTY(_ep2, 3)
    EP_PROPERTY(_ep3, 3)
    EP_PROPERTY(_ep4, 3)
    EP_PROPERTY(_ep5, 3)
    EP_PROPERTY(qwc, 2)
#undef EP_PROPERTY
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
    PROPERTY(weights, BF8Weights)
    PROPERTY(partition_map, PartitionMap)
    PROPERTY(ideal_partition_map, PartitionMap)
    PROPERTY(astc_seed, uint16_t)
    PROPERTY(perm, uint8_t)
    PROPERTY(max_partitions, uint8_t)
#undef PROPERTY
#undef GET_FIELD
#undef SET_FIELD

    void set(CompressedTextureBlockProxyPayload other)
    {
        var other_index = other.index;
        if (true)
            g_scratch[blockIdx].blocks[index] =
                true ? g_scratch[blockIdx].blocks[other_index]
                     : g_compressedBlock3P[blockIdx];
        else
            g_compressedBlock3P[blockIdx] =
                true ? g_scratch[blockIdx].blocks[other_index]
                     : g_compressedBlock3P[blockIdx];
    }
}

// The ASTC/BC encoder problem (single-partition) is to solve for
struct CompressedTextureBlock
{
    // CompressedTextureBlockPayload payload; // use vregs
    CompressedTextureBlockProxyPayload payload; // use dram

#define EP_PROPERTY(ep, _ep)                                                   \
    property half3 ep                                                          \
    {                                                                          \
        get {                                                                  \
            return half3(payload._ep) / 255;                                   \
        }                                                                      \
        set {                                                                  \
            payload._ep = vector<uint8_t, 3>(round(saturate(newValue) * 255)); \
        }                                                                      \
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
#undef PROPERTY

    [mutating]
    void set_astc_seed(uint16_t seed)
    {
        astc_seed = seed;
        partition_map = max_partitions == 2 ? PartitionMap(LUT2_LOOKUP[seed]) : PartitionMap(LUT3_LOOKUP[seed]);
    }

    // Cheap 1-step update to find the optimal weights that best fits ep0/ep1, ep2/ep3 to groundtruth
    // This is a shortcut to avoid n steps of descent on weight, and avoid computing weight derivatives
    [mutating]
    void solve_weights()
    {
        // Project weights again
        var L1 = ep1 - ep0;
        var L2 = ep3 - ep2;
        var L3 = ep5 - ep4;
        half invLenSq1 = 1.0h / (dot(L1, L1) + 0.000001h);
        half invLenSq2 = 1.0h / (dot(L2, L2) + 0.000001h);
        half invLenSq3 = 1.0h / (dot(L3, L3) + 0.000001h);
        for (int i = 0; i < 16; i++)
        {
            var C = groundtruth[i];
            var p = partition_map[i];
            var pDotL = p == 0 ? dot(C - ep0, L1) : (p == 1 ? dot(C - ep2, L2) : dot(C - ep4, L3));
            var invLenSq = p == 0 ? invLenSq1 : (p == 1 ? invLenSq2 : invLenSq3);
            var w = pDotL * invLenSq;
            weights[i] = saturate(w);
        }
    }

    // ASTCENC magic numbers for weighted-random center selection
    static const half kClusterCutoffs[9] = {
        0.626220h, 0.932770h, 0.275454h,
        0.318558h, 0.240113h, 0.009190h,
        0.347661h, 0.731960h, 0.156391h
    };

    void cluster_astc(inout PartitionMap partition_map)
    {
        half3 centroids[4];
        uint8_t k = max_partitions;
        PCG32 prng = PCG32(g_params.seed);

        for (int iter = 0; iter < 3; iter++)
        {
            if (iter == 0)
            {
                // Initialize the first centroid by picking a random sample
                centroids[0] = groundtruth[8];
                half dists[16];
                for (int t = 0; t < 16; t++)
                {
                    var d = groundtruth[t] - centroids[0];
                    dists[t] = dot(d, d);
                }

                // Select the secondary centroids
                for (uint c = 1; c < k; c++)
                {
                    half total_dist = 0;
                    for (int t1 = 0; t1 < 16; t1++)
                        total_dist += dists[t1];

                    uint cutoff_idx = (c - 1) + 3 * (k - 2);
                    half dist_cutoff = total_dist * kClusterCutoffs[cutoff_idx];

                    half running_sum = 0;
                    uint selected_sample = 0;

                    for (uint sample = 0; sample < 16; sample++)
                    {
                        running_sum += dists[sample];
                        if (running_sum >= dist_cutoff)
                        {
                            selected_sample = sample;
                            break;
                        }
                    }

                    centroids[c] = groundtruth[selected_sample];

                    for (int t2 = 0; t2 < 16; t2++)
                    {
                        var d = groundtruth[t2] - centroids[c];
                        dists[t2] = min(dists[t2], dot(d, d));
                    }
                }
            }
            else
            {
                half3 color_sums[4] = { half3(0, 0, 0), half3(0, 0, 0), half3(0, 0, 0), half3(0, 0, 0) };
                uint counts[4] = { 0, 0, 0, 0 };

                for (int i = 0; i < 16; i++)
                {
                    uint p_idx = partition_map[i];
                    color_sums[p_idx] += groundtruth[i];
                    counts[p_idx]++;
                }

                for (uint j = 0; j < k; j++)
                {
                    if (counts[j] > 0)
                    {
                        centroids[j] = color_sums[j] / half(counts[j]);
                    }
                    else
                    {
                        centroids[j] = half3(0, 0, 0);
                    }
                }
            }

            uint partition_counts[4] = { 0, 0, 0, 0 };
            for (int i = 0; i < 16; i++)
            {
                half best_dist = 1000;
                uint8_t best_idx = 0;

                for (uint8_t j = 0; j < k; j++)
                {
                    half d = dot(groundtruth[i] - centroids[j], groundtruth[i] - centroids[j]);
                    if (d < best_dist)
                    {
                        best_dist = d;
                        best_idx = j;
                    }
                }
                partition_map[i] = best_idx;
                partition_counts[best_idx]++;
            }

            // Restart empty partitions
            bool problem = true;
            for (int safe_iter = 0; safe_iter < 4; safe_iter++)
            {
                if (!problem)
                    break;
                problem = false;

                for (uint8_t p = 0; p < k; p++)
                {
                    if (partition_counts[p] == 0)
                    {
                        // Pixel stealing
                        uint old_p = partition_map[prng.nextUint() % 16];
                        if (old_p != p)
                        {
                            partition_counts[old_p]--;
                            partition_counts[p]++;
                            partition_map[p] = p;
                            problem = true;
                        }
                    }
                }
            }
        }
    }

    void decompress3P()
    {
        // TextureBlock outputBlock;
        for (uint8_t i = 0; i < 16; i++)
        {
            let p = partition_map[i];
            let e0 = p == 0 ? ep0 : (p == 1 ? ep2 : ep4);
            let e1 = p == 0 ? ep1 : (p == 1 ? ep3 : ep5);
            g_reconstructed[blockIdx][i] = lerp(e0, e1, weights[i]);
        }
    }

    [mutating]
    float quantize()
    {
        if (g_params.no_quantization)
        {
            return loss_mse(this);
        }
        float best_loss = 1000.0;
        vector<uint8_t, 2> best_wc;
        CompressedTextureBlock best_block = CompressedTextureBlock(2);
        for (int i = 0; i < 9; i++)
        {
            vector<uint8_t, 2> wc = max_partitions == 1
                                        ? VALID_1P_QUANTIZATION_RANGES[i]
                                        : (max_partitions == 2 ? VALID_2P_QUANTIZATION_RANGES[i] : VALID_3P_QUANTIZATION_RANGES[i]);
            if (wc.x == 0)
                continue;

            // Make a copy of this block
            let c = wc.y;
            CompressedTextureBlock block = CompressedTextureBlock(3);
            block.payload.set(payload);
            block.ep0 = quantize(ep0, c);
            block.ep1 = quantize(ep1, c);
            block.ep2 = quantize(ep2, c);
            block.ep3 = quantize(ep3, c);
            block.ep4 = quantize(ep4, c);
            block.ep5 = quantize(ep5, c);
            block.weights.quantize(wc.x);

            let loss = loss_mse(block);
            if (loss < best_loss || i == 0)
            {
                best_loss = loss;
                best_wc = wc;
                best_block.payload.set(block.payload);
            }
        }
        this.payload.set(best_block.payload);
        this.payload.qwc = best_wc;
        return best_loss;
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
        decompress3P();
        return;
    }
};

// Potentially use this vs solve_aabb_for_partition
void solve_pca_eps(CompressedTextureBlock block, inout half3 ep0, inout half3 ep1, uint8_t partition_id)
{
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

float loss_mse(CompressedTextureBlock compressed)
{
    compressed.decompress3P();
    float totalError = 0.0f;

    for (int i = 0; i < 16; i++)
    {
        var diff = g_reconstructed[blockIdx][i] - groundtruth[i];
        totalError += dot(diff, diff); // L2 error
    }

    return totalError;
}

half estimate_partition_error_bound(half3x3 scatter_matrix)
{
    half total_variance = scatter_matrix[0][0] + scatter_matrix[1][1] + scatter_matrix[2][2];
    half3 axis = half3(0.17h, 0.83h, 0.38h);

    // Two rounds of power iteration to approximate the principle component (lambda_max)
    axis = mul(scatter_matrix, axis);
    axis *= rsqrt(dot(axis, axis) + 0.000001h);
    axis = mul(scatter_matrix, axis);
    // Residue = variance - maximum lambda (from the 2 rounds of power iteration)
    half lambda_max = sqrt(dot(axis, axis));
    return max(0.0h, total_variance - lambda_max);
}

// Scans the partition map and computes the lower bound error cheaply
half compute_error_fast(CompressedTextureBlock block)
{
    half3 means[3] = { 0 };

    // Cov x count
    half3x3 scatters[3] = { 0 };
    uint8_t counts[3] = { 0 };
    for (uint8_t i = 0; i < 16; i++)
    {
        let p = block.partition_map[i];
        let px = groundtruth[i];

        means[p] += px;
        counts[p] += 1;

        // S = Sum(x*xT) - n * mean*meanT
        scatters[p][0] += px.x * px;
        scatters[p][1] += px.y * px;
        scatters[p][2] += px.z * px;
    }

    half total_lb = 0;
    for (uint8_t p = 0; p < block.max_partitions; p++)
    {
        if (counts[p] > 0)
        {
            let m = means[p];
            let count = half(counts[p]);
            scatters[p][0] -= (m.x / count) * m;
            scatters[p][1] -= (m.y / count) * m;
            scatters[p][2] -= (m.z / count) * m;
            total_lb += estimate_partition_error_bound(scatters[p]);
        }
    }

    return total_lb;
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

#define MAX_DISTANCE 8
#define MAX_SLOTS 16 // Reduced from 16 to 10 to get down to <8k LDS

// groupshared uint16_t s_partitions[64][MAX_DISTANCE * MAX_SLOTS];
groupshared RankedSeeds s_ranked_seeds[64];
// #define partitions s_partitions[blockIdx % 64]
#define partitions g_scratch[blockIdx].partitions
#define ranked_seeds s_ranked_seeds[blockIdx % 64]
// #define ranked_seeds g_scratch[blockIdx].ranked_seeds

struct RankedSeeds
{
    // For some reason, if seeds/seeds_mask are not > 256 bytes, the shader performance suffers...
    // Likely due to VGPRs, which are inefficient to dynamically index as I am doing here
    // Ironically, using the L1/L2 cache here (the spilled memory) actually helps performance considerably
    // By forcing the masks to be at least 256 bytes, we trick the compiler into using the L1/L2 cache
    // and increase occupancy by reducing register pressure.
    // uint16_t seeds[MAX_DISTANCE * MAX_SLOTS]; // [dist][seeds] - up to 128 entries, use MAX_SLOTS >= 17
    uint seeds_masks[(MAX_DISTANCE * MAX_SLOTS + 2) / 3]; // 10 bits packed into 32 bits, use MAX_SLOTS >= 25
    uint8_t counts[MAX_DISTANCE];
}

#define RANKSEEDS_GET(seeds, n) \
    uint16_t(seeds.seeds_masks[n / 3] >> uint((n % 3) * 10)) & 0x3FF;
// return seeds[n];

[mutating]
void RankedSeeds_add(uint16_t seed, uint16_t distance, uint8_t slots)
{
    var count = ranked_seeds.counts[distance];
    if (count < slots)
    {
        let n = distance * MAX_SLOTS + count;
        // seeds[n] = seed + 1;
        ranked_seeds.seeds_masks[n / 3] |= uint(seed + 1) << uint((n % 3) * 10);
        ranked_seeds.counts[distance]++;
    }
}

uint16_t RankedSeeds_pack(uint max_items)
{
    uint16_t count = 0;
    let counts = ranked_seeds.counts;
    // [unroll]
    for (uint16_t i = 0; i < MAX_DISTANCE * MAX_SLOTS; i++)
    {
        if (i % MAX_SLOTS > counts[i / MAX_SLOTS])
        {
            continue;
        }
        var seed = RANKSEEDS_GET(ranked_seeds, i);
        // if (seed == 0)
        // {
        //     continue;
        // }
        partitions[count] = seed - 1;
        count++;
        if (count >= max_items)
        {
            break;
        }
    }
    return count;
}

int find_top_partitions(inout CompressedTextureBlock block, uint candidates)
{
    PartitionMap ideal_map;
    block.cluster_astc(ideal_map);
    block.ideal_partition_map = ideal_map;
    let slots : uint8_t = uint8_t(clamp(candidates / 8, 2, MAX_SLOTS));
    ranked_seeds = RankedSeeds();
    let p2 = block.max_partitions == 2;

    for (uint16_t i = 0; i < 1024; i++)
    {
        var final_map = p2 ? LUT2_LOOKUP[i] : LUT3_LOOKUP[i];
        var perm_distance = p2 ? best_perm_distance_s2(ideal_map.data, final_map)
                               : best_perm_distance_s3(ideal_map.data, final_map);
        if (perm_distance < MAX_DISTANCE)
        {
            RankedSeeds_add(i, uint8_t(perm_distance), slots);
        }
    }

    return RankedSeeds_pack(candidates);
}

float optimize(inout CompressedTextureBlock block, uint steps, bool diagnostics_enabled, bool exhaustive = false)
{
#define diagnostics g_diagnostics[blockIdx]
    let max_partitions = block.max_partitions;

    // uint16_t partitions[MAX_DISTANCE * MAX_SLOTS] = { 0 };
    uint candidates = 0;
    if (exhaustive)
    {
        // TODO: scale down to only the LUT / S2 or S3 partitions (~400)
        candidates = max_partitions == 1 ? 1 : steps;
    }
    else if (max_partitions > 1)
    {
        // This is ~100ms on cat.jpg (129600 threads)
        // partitions = { 0 };
        candidates = find_top_partitions(block, steps);
    }

    float best_loss = 1000;
    uint16_t best_candidate_id = 0;
    uint16_t best_seed = 0;
    PCG32 prng = PCG32(0);

    // Search for the best loss and parameters
    for (uint16_t candidate_id = 0; candidate_id < candidates; candidate_id++)
    {
        // uint16_t seed = prng.nextUint() % 1024; // partitions[candidate_id];
        uint16_t seed = exhaustive ? candidate_id : partitions[candidate_id];
        // uint16_t seed = ranked_seeds[candidate_id];
        // uint16_t seed = candidate_id;
        block.set_astc_seed(seed);

        float loss = compute_error_fast(block);
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

    // best_candidate_id = found - 1;
    // best_seed = partitions[best_candidate_id];
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
    float loss = loss_mse(block);
    if (diagnostics_enabled)
    {
        diagnostics.loss_log[11][max_partitions - 1] = loss;
    }

    block.astc_seed = best_candidate_id;
    block.perm = block.max_partitions == 2 ? best_perm_distance_s2(block.ideal_partition_map.data, block.partition_map.data)
                                           : best_perm_distance_s3(block.ideal_partition_map.data, block.partition_map.data);
    return loss;
}

// #undef groundtruth
#undef diagnostics
#undef partitions

static uint blockIdx; // the dedicated register for the block index

// [require(spvShaderClockKHR)]
[shader("compute")]
[numthreads(64, 1, 1)]
void compress_3P_step(uint3 dispatchThreadID: SV_DispatchThreadID)
{
    blockIdx = dispatchThreadID.x;
    if (blockIdx >= g_params.num_blocks)
        return;
    g_diagnostics[blockIdx].start_clock = getRealtimeClock();

    var prng = PCG32(g_params.seed);
    var block = CompressedTextureBlock(0);
    var block1 = CompressedTextureBlock(1);
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
    unquantized_loss = optimize(block, steps, diagnostics);
    quantized_loss = block.quantize();
    if (g_params.max_partitions >= 2)
    {
        // 1P does not need exhaustive search
        block1.max_partitions = 2;
        unquantized_loss1 = optimize(block1, steps, diagnostics, exhaustive);
        quantized_loss1 = block1.quantize();
        if (quantized_loss1 < quantized_loss)
        {
            quantized_loss = quantized_loss1;
            unquantized_loss = unquantized_loss1;
            block.payload.set(block1.payload);
        }
        if (g_params.max_partitions == 3)
        {
            block1.max_partitions = 3;
            unquantized_loss1 = optimize(block1, steps, diagnostics, exhaustive);
            quantized_loss1 = block1.quantize();
            if (quantized_loss1 < quantized_loss)
            {
                quantized_loss = quantized_loss1;
                unquantized_loss = unquantized_loss1;
                block.payload.set(block1.payload);
            }
        }
    }

    g_diagnostics[blockIdx].optim_ended_clock = getRealtimeClock();

    block.reconstruct();
    g_compressedBlock3P[blockIdx].set(block.payload);
    // g_reconstructed[blockIdx] = block.reconstruct();
    g_diagnostics[blockIdx].final_unquantized_loss = unquantized_loss;
    g_final_loss[blockIdx] = quantized_loss;
    g_diagnostics[blockIdx].finished_clock = getRealtimeClock();
}
