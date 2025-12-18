// Each ASTC/BC block is 16x vec3 of RGBs
struct TextureBlock : IDifferentiable
{
    float3 pixels[16];
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
    // float3 delta1[10];
    // float3 delta2[10];
    // float3 delta3[10];
    // float3 color_mean1[10];
    // float3 color_mean2[10];
    // float3 color_mean3[10];
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
RWStructuredBuffer<CompressedTextureBlock> g_compressedBlock3P;

// The loss of the encoded block
RWStructuredBuffer<float> g_final_loss;

// ASTC 2-partition LUT to snap a partition map to a valid astc partition seed
StructuredBuffer<uint> g_astc_2p_4x4_lut_s2; // 2^15 entries (42.7KB)
StructuredBuffer<uint> g_astc_3p_4x4_lut_s3; // 2 * 3^14 entries (12.2MB)

struct LUT
{
    uint lut2[1024]; // 1024-entry (4KB)
    uint lut3[1024]; // 1024-entry (4KB)
};
ConstantBuffer<LUT> g_lut;

#define LUT2_LOOKUP g_lut.lut2
#define LUT3_LOOKUP g_lut.lut3

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

[UnscopedEnum]
enum Permutation : uint8_t
{
    Id,
    Swap01,
    Swap02,
    Swap12,
    Cycle120,
    Cycle201
}

uint permute_swap01(uint x)
{
    return x ^ (~(x >> 1) & M5);
}

uint permute_swap02(uint x)
{
    return x ^ (~(x << 1) & MA);
}

uint permute_swap12(uint x)
{
    uint non_zero = (x | (x >> 1)) & M5;
    uint mask = non_zero | (non_zero << 1);
    return x ^ mask;
}

uint permute_cycle_120(uint x)
{
    // 0->1, 1->2, 2->0 (Forward)
    uint s = x + M5;
    uint mask = s & (s >> 1) & M5;
    return uint(s & ~(mask | (mask << 1)));
}

uint permute_cycle_201(uint x)
{
    // // 0->2, 2->1, 1->0 (Backward)
    // uint s = x - M5; // UNDERFLOWS
    // uint mask = s & (s >> 1) & M5;
    // return s & ~mask;
    return permute_cycle_120(permute_cycle_120(x));
}

uint apply_permutation(Permutation perm, uint x)
{
    switch (perm)
    {
    case Id:
        return x;
    case Swap01:
        return permute_swap01(x);
    case Swap02:
        return permute_swap02(x);
    case Swap12:
        return permute_swap12(x);
    case Cycle120:
        return permute_cycle_120(x);
    case Cycle201:
        return permute_cycle_201(x);
    }
    return x;
}

static const uint M5 = 0x55555555; // 0101...
static const uint MA = 0xAAAAAAAA; // 1010...

uint8_t best_perm_distance_s3(uint x, uint y, out Permutation perm)
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

    perm = Permutation(best & 7);
    return uint8_t(best >> 3);
}

uint8_t best_perm_distance_s2(uint x, uint y, out Permutation perm)
{
    uint base = x ^ y;
    uint x_shr1 = x >> 1;

    uint m01 = (~x_shr1) & M5;

    uint p0 = (count_diffs(base) << 1) | 0;
    uint p1 = (count_diffs(base ^ m01) << 1) | 1;

    uint min01 = min(p0, p1);

    perm = Permutation(min01 & 1);
    return uint8_t(min01 >> 1);
}

uint lut3_key(uint x)
{
    // pack into trits, preserve proper endianness
    uint result = 0;
    [unroll]
    for (int i = 15; i >= 0; i--)
    {
        result = result * 3 + ((x >> (i * 2)) & 3);
    }
    return result;
}

uint canonicalize_lut3(uint x)
{
    var p0 = lut3_key(x);
    var p1 = lut3_key(permute_swap01(x));
    var p2 = lut3_key(permute_swap02(x));
    var p3 = lut3_key(permute_swap12(x));
    var p4 = lut3_key(permute_cycle_120(x));
    var p5 = lut3_key(permute_cycle_201(x));

    uint min01 = min(p0, p1);
    uint min23 = min(p2, p3);
    uint min45 = min(p4, p5);
    return min(min01, min(min23, min45));
}

uint lut2_key(uint x)
{
    // pack into bits, preserve proper endianness
    uint result = 0;
    [unroll]
    for (int i = 15; i >= 0; i--)
    {
        result = result * 2 + ((x >> (i * 2)) & 3);
    }
    return result;
}

uint canonicalize_lut2(uint x)
{
    var p0 = lut2_key(x);
    var p1 = lut2_key(permute_swap01(x));
    return min(p0, p1);
}

uint hamming_distance_2b(uint x, uint y)
{
    uint z = x ^ y;
    z |= z >> 1;
    z &= 0x55555555;
    return countbits(z);
}

uint count_diffs(uint val)
{
    return countbits((val | (val >> 1)) & 0x55555555);
}

uint get_closest_seed3(uint input, out Permutation perm, out uint final_pattern)
{
    uint key = canonicalize_lut3(input);
    uint seed = (g_astc_3p_4x4_lut_s3[key / 3] >> ((key % 3) * 10)) & 0x3FF;
    uint pattern = LUT3_LOOKUP[seed];
    uint dist = best_perm_distance_s3(input, pattern, perm);

    final_pattern = pattern;
    return seed;
}

uint get_closest_seed2(uint input, out Permutation permutation, out uint final_pattern)
{
    uint key = canonicalize_lut2(input);
    uint seed = (g_astc_2p_4x4_lut_s2[key / 3] >> ((key % 3) * 10)) & 0x3FF;
    uint pattern = LUT2_LOOKUP[seed];
    uint dist = best_perm_distance_s2(input, pattern, permutation);

    final_pattern = pattern;
    return seed;
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

static const vector<uint8_t, 2> VALID_1P_QUANTIZATION_RANGES[9] = {
    // w, c
    { 31, 31 },  // (5b, 5b)
    { 23, 63 },  // (1t3b, 6b)
    { 19, 95 },  // (1q2b, 1t5b)
    { 15, 191 }, // (4b, 1t6b)
    { 11, 255 }, // (1t2b, 8b)
    { 0, 0 },
    { 0, 0 },
    { 0, 0 },
    { 0, 0 }, // Padding
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
    { 0, 0 },
    { 0, 0 },
    { 0, 0 }, // Padding
};

// Frozen weights (to avoid generating expensive derivatives in the bkw pass)
struct NonDifferentiableFP8Weights
{
    uint8_t data[16];
    __subscript(int n)->float
    {
        get
        {
            return float(data[n]) / 255;
        }
        set
        {
            data[n] = uint8_t(round(saturate(newValue) * 255));
        }
    }

    [mutating]
    void quantize(uint8_t range = 255)
    {
        [unroll]
        for (int i = 0; i < 16; i++)
        {
            this[i] = quantize(this[i], range);
        }
    }

    float mean()
    {
        float sum = 0;
        [unroll]
        for (int i = 0; i < 16; i++)
        {
            sum += this[i];
        }
        return sum / 16;
    }
}

struct NonDifferentiableIntPartitions
{
    int8_t data[16];
    __subscript(int n)->int
    {
        get
        {
            return data[n];
        }
        set
        {
            data[n] = int8_t(newValue);
        }
    }
}

// The ASTC/BC encoder problem (single-partition) is to solve for
struct CompressedTextureBlock : IDifferentiable
{
    // Can't turn these private due to how autodiff works
    half3 _ep0, _ep1; // partition 1
    half3 _ep2, _ep3; // partition 2
    half3 _ep4, _ep5; // partition 2

    no_diff NonDifferentiableFP8Weights weights;            // we don't have to gradient descent on this since we can do a full solve
    no_diff NonDifferentiableIntPartitions partition_index; // Partition blend logits
    no_diff uint astc_partition_map;                        // Final 16-bit valid partition map
    no_diff uint ideal_partition_map;
    no_diff uint16_t astc_seed;
    no_diff uint8_t perm;
    no_diff uint8_t partition_count;
    no_diff uint8_t max_partitions;
    no_diff vector<uint8_t, 2> qwc;
    no_diff vector<uint8_t, 2> fqwc;

#define EP_PROPERTY(ep0, _ep0)                     \
    property float3 ep0                            \
    {                                              \
        [Differentiable]                           \
        get                                        \
        {                                          \
            return _ep0;                           \
        }                                          \
        set                                        \
        {                                          \
            _ep0 = quantize(half3(newValue), 255); \
        }                                          \
    }

    EP_PROPERTY(ep0, _ep0)
    EP_PROPERTY(ep1, _ep1)
    EP_PROPERTY(ep2, _ep2)
    EP_PROPERTY(ep3, _ep3)
    EP_PROPERTY(ep4, _ep4)
    EP_PROPERTY(ep5, _ep5)

    static uint pack_partition_indices(uint8_t partition_index[16])
    {
        uint raw_map = 0;
        for (int i = 0; i < 16; i++)
        {
            uint logit = clamp(partition_index[i], 0, 2);
            raw_map |= (logit << (i * 2));
        }
        return raw_map;
    }

    uint pack_partition_indices()
    {
        uint raw_map = 0;
        for (int i = 0; i < 16; i++)
        {
            uint logit = clamp(partition_index[i], 0, 2);
            raw_map |= (logit << (i * 2));
        }
        return raw_map;
    }

    [mutating]
    void swap_colors(Permutation perm)
    {
        var old_ep0 = ep0;
        var old_ep1 = ep1;
        var old_ep2 = ep2;
        var old_ep3 = ep3;
        var old_ep4 = ep4;
        var old_ep5 = ep5;

        // Destination (ep0, ep1)
        // From Pair 1 (Swap01, Cycle201) or Pair 2 (Swap02, Cycle120)
        bool from_pair1 = (perm == Swap01 || perm == Cycle201);
        bool from_pair2 = (perm == Swap02 || perm == Cycle120);
        ep0 = from_pair1 ? old_ep2 : (from_pair2 ? old_ep4 : old_ep0);
        ep1 = from_pair1 ? old_ep3 : (from_pair2 ? old_ep5 : old_ep1);

        // Destination (ep2, ep3)
        // From Pair 0 (Swap01, Cycle120) or Pair 2 (Swap12, Cycle201)
        bool from_pair0 = (perm == Swap01 || perm == Cycle120);
        from_pair2 = (perm == Swap12 || perm == Cycle201);
        ep2 = from_pair0 ? old_ep0 : (from_pair2 ? old_ep4 : old_ep2);
        ep3 = from_pair0 ? old_ep1 : (from_pair2 ? old_ep5 : old_ep3);

        // Destination (ep4, ep5)
        // From Pair 0 (Swap02, Cycle201) or Pair 1 (Swap12, Cycle120)
        from_pair0 = (perm == Swap02 || perm == Cycle201);
        from_pair1 = (perm == Swap12 || perm == Cycle120);
        ep4 = from_pair0 ? old_ep0 : (from_pair1 ? old_ep2 : old_ep4);
        ep5 = from_pair0 ? old_ep1 : (from_pair1 ? old_ep3 : old_ep5);
    }

    // Snap the partition map within a 2P block into a valid astc partition seed
    // Note: snapping actually introduces a local minimum problem for most greedy
    // optimization strategies. In cases where you have 1-2 / 16 pixels with a 3rd
    // color, and those 1-2 pixels cannot be selected into the ideal partition because
    // there are no valid astc patterns for the given ep set that will assign those
    // pixels to the right partition, then the only thing our optimizer can do
    // is to compute this weird weighted avg color for the block instead.
    [mutating]
    void snap()
    {
        var raw_map = pack_partition_indices();
        Permutation permutation = Id;
        uint final_mask = 0;
        uint closest_seed = 0;
        if (max_partitions == 3)
        {
            closest_seed = get_closest_seed3(raw_map, permutation, final_mask);
        }
        else
        {
            closest_seed = get_closest_seed2(raw_map, permutation, final_mask);
        }

        astc_seed = uint16_t(closest_seed);
        astc_partition_map = final_mask;
        ideal_partition_map = raw_map;
        perm = permutation;

        // Snap our partition logits into the final mask
        swap_colors(permutation);
        for (int i = 0; i < 16; i++)
        {
            partition_index[i] = ((final_mask >> (2 * i)) & 3); // Comment this out to see what happens w/o snapping
        }
    }

    [mutating]
    void set_astc_seed(uint16_t seed)
    {
        astc_seed = seed;
        astc_partition_map = max_partitions == 2 ? LUT2_LOOKUP[seed] : LUT3_LOOKUP[seed];

        [unroll]
        for (int i = 0; i < 16; i++)
        {
            partition_index[i] = ((astc_partition_map >> (2 * i)) & 3);
        }
    }

    static float distSq(float3 P, float3 L, float pDotL, float invLenSq)
    {
        float pDotP = dot(P, P);
        return pDotP - (pDotL * pDotL * invLenSq);
    }

    static uint argmin(float d1, float d2, float d3)
    {
        if (d1 < d2 && d1 < d3)
            return 0;
        if (d2 < d3)
            return 1;
        return 2;
    }

    // Cheap 1-step update to find the optimal weights that best fits ep0/ep1, ep2/ep3 to groundtruth
    // This is a shortcut to avoid n steps of descent on weight, and avoid computing weight derivatives
    [mutating]
    void solve_weights(TextureBlock groundtruth)
    {
        // Project weights again
        var L1 = ep1 - ep0;
        var L2 = ep3 - ep2;
        var L3 = ep5 - ep4;
        float invLenSq1 = 1.0 / (dot(L1, L1) + 1e-6f);
        float invLenSq2 = 1.0 / (dot(L2, L2) + 1e-6f);
        float invLenSq3 = 1.0 / (dot(L3, L3) + 1e-6f);
        [unroll]
        for (int i = 0; i < 16; i++)
        {
            var C = groundtruth.pixels[i];
            var p = partition_index[i];
            var pDotL = p == 0 ? dot(C - ep0, L1) : (p == 1 ? dot(C - ep2, L2) : dot(C - ep4, L3));
            var invLenSq = p == 0 ? invLenSq1 : (p == 1 ? invLenSq2 : invLenSq3);
            var w = pDotL * invLenSq;
            weights[i] = saturate(w);
        }
    }

    // ASTCENC magic numbers for weighted-random center selection
    static const float kClusterCutoffs[9] = {
        0.626220, 0.932770, 0.275454,
        0.318558, 0.240113, 0.009190,
        0.347661, 0.731960, 0.156391
    };

    void cluster_astc(TextureBlock groundtruth, inout uint8_t partition_index[16])
    {
        float3 centroids[4];
        uint8_t k = max_partitions;
        PCG32 prng = PCG32(g_params.seed);

        [unroll]
        for (int iter = 0; iter < 3; iter++)
        {
            if (iter == 0)
            {
                // Initialize the first centroid by picking a random sample
                centroids[0] = groundtruth.pixels[8];
                float dists[16];
                [unroll]
                for (int t = 0; t < 16; t++)
                {
                    var d = groundtruth.pixels[t] - centroids[0];
                    dists[t] = dot(d, d);
                }

                // Select the secondary centroids
                [unroll]
                for (uint c = 1; c < k; c++)
                {
                    float total_dist = 0;
                    [unroll]
                    for (int t1 = 0; t1 < 16; t1++)
                        total_dist += dists[t1];

                    uint cutoff_idx = (c - 1) + 3 * (k - 2);
                    float dist_cutoff = total_dist * kClusterCutoffs[cutoff_idx];

                    float running_sum = 0;
                    uint selected_sample = 0;

                    [unroll]
                    for (uint sample = 0; sample < 16; sample++)
                    {
                        running_sum += dists[sample];
                        if (running_sum >= dist_cutoff)
                        {
                            selected_sample = sample;
                            break;
                        }
                    }

                    centroids[c] = groundtruth.pixels[selected_sample];

                    [unroll]
                    for (int t2 = 0; t2 < 16; t2++)
                    {
                        var d = groundtruth.pixels[t2] - centroids[c];
                        dists[t2] = min(dists[t2], dot(d, d));
                    }
                }
            }
            else
            {
                float3 color_sums[4] = { float3(0, 0, 0), float3(0, 0, 0), float3(0, 0, 0), float3(0, 0, 0) };
                uint counts[4] = { 0, 0, 0, 0 };

                [unroll]
                for (int i = 0; i < 16; i++)
                {
                    uint p_idx = partition_index[i];
                    color_sums[p_idx] += groundtruth.pixels[i];
                    counts[p_idx]++;
                }

                [unroll]
                for (uint j = 0; j < k; j++)
                {
                    if (counts[j] > 0)
                    {
                        centroids[j] = color_sums[j] / float(counts[j]);
                    }
                    else
                    {
                        centroids[j] = float3(0, 0, 0);
                    }
                }
            }

            uint partition_counts[4] = { 0, 0, 0, 0 };
            [unroll]
            for (int i = 0; i < 16; i++)
            {
                float best_dist = 1e3;
                uint8_t best_idx = 0;

                [unroll]
                for (uint8_t j = 0; j < k; j++)
                {
                    float d = dot(groundtruth.pixels[i] - centroids[j], groundtruth.pixels[i] - centroids[j]);
                    if (d < best_dist)
                    {
                        best_dist = d;
                        best_idx = j;
                    }
                }
                partition_index[i] = best_idx;
                partition_counts[best_idx]++;
            }

            // Restart empty partitions
            bool problem = true;
            [unroll]
            for (int safe_iter = 0; safe_iter < 4; safe_iter++)
            {
                if (!problem)
                    break;
                problem = false;

                [unroll]
                for (uint8_t p = 0; p < k; p++)
                {
                    if (partition_counts[p] == 0)
                    {
                        // Pixel stealing
                        uint old_p = partition_index[prng.nextUint() % 16];
                        if (old_p != p)
                        {
                            partition_counts[old_p]--;
                            partition_counts[p]++;
                            partition_index[p] = p;
                            problem = true;
                        }
                    }
                }
            }
        }
    }

    TextureBlock decompress3P()
    {
        TextureBlock outputBlock;
        [unroll]
        for (uint i = 0; i < 16; i++)
        {
            var w = weights[i];
            var partition = clamp(int(partition_index[i]), 0, max_partitions - 1);
            var e0 = partition == 0 ? ep0 : (partition == 1 ? ep2 : ep4);
            var e1 = partition == 0 ? ep1 : (partition == 1 ? ep3 : ep5);
            outputBlock.pixels[i] = lerp(e0, e1, w);
        }
        return outputBlock;
    }

    [mutating]
    void random_initialize(TextureBlock groundtruth, inout PCG32 prng)
    {
        // Pick 6 random pairs of endpoints
        int i;
        ep0 = groundtruth.pixels[prng.nextUint() % 16];
        ep1 = groundtruth.pixels[prng.nextUint() % 16];

        [unroll]
        for (int i = 0; i < 16; i++)
        {
            weights[i] = prng.nextFloat();
        }

        [unroll]
        for (i = 0; i < 8; i++)
        {
            ep1 = groundtruth.pixels[prng.nextUint() % 16];
            var d = ep1 - ep0;
            if (dot(d, d) > 0.3)
            {
                break;
            }
        }

        if (max_partitions == 1)
            return;

        [unroll]
        for (i = 0; i < 8; i++)
        {
            ep2 = groundtruth.pixels[prng.nextUint() % 16];
            if (dist(ep2, ep0, ep1) > 0.3)
            {
                break;
            }
        }

        [unroll]
        for (i = 0; i < 8; i++)
        {
            ep3 = groundtruth.pixels[prng.nextUint() % 16];
            if (dist(ep3, ep0, ep1) > 0.3)
            {
                break;
            }
        }

        [unroll]
        for (i = 0; i < 8; i++)
        {
            ep4 = groundtruth.pixels[prng.nextUint() % 16];
            if (dist(ep4, ep0, ep1) <= 0.3)
            {
                continue;
            }
            if (dist(ep4, ep2, ep3) > 0.3)
            {
                break;
            }
        }

        [unroll]
        for (i = 0; i < 8; i++)
        {
            ep5 = groundtruth.pixels[prng.nextUint() % 16];
            if (dist(ep5, ep0, ep1) <= 0.3)
            {
                continue;
            }
            if (dist(ep5, ep2, ep3) > 0.3)
            {
                break;
            }
        }

        [unroll]
        for (int i = 0; i < 16; i++)
        {
            partition_index[i] = prng.nextUint() % max_partitions;
        }
    }

    [mutating]
    vector<uint8_t, 2> quantize(TextureBlock groundtruth)
    {
        float best_loss = 1000.0;
        vector<uint8_t, 2> best_wc;
        CompressedTextureBlock best_block;
        for (int i = 0; i < 9; i++)
        {
            vector<uint8_t, 2> wc = max_partitions == 1
                                        ? VALID_1P_QUANTIZATION_RANGES[i]
                                        : (max_partitions == 2 ? VALID_2P_QUANTIZATION_RANGES[i] : VALID_3P_QUANTIZATION_RANGES[i]);
            if (wc.x == 0)
                continue;

            // Make a copy of this block
            var c = wc.y;
            CompressedTextureBlock block = this;
            block._ep0 = quantize(_ep0, c);
            block._ep1 = quantize(_ep1, c);
            block._ep2 = quantize(_ep2, c);
            block._ep3 = quantize(_ep3, c);
            block._ep4 = quantize(_ep4, c);
            block._ep5 = quantize(_ep5, c);
            block.weights.quantize(wc.x);

            var loss = loss_mse(groundtruth, block);
            if (loss < best_loss || i == 0)
            {
                best_loss = loss;
                best_wc = wc;
                best_block = block;
            }
        }
        this = best_block;
        this.qwc = best_wc;
        return best_wc;
    }

    TextureBlock reconstruct(TextureBlock groundtruth)
    {
        if (g_params.debug_reconstruction)
        {
            TextureBlock outputBlock;
            for (int i = 0; i < 16; i++)
            {
                float w = round(detach(weights[i]) * 4) / 4;
                int partition = clamp(int(detach(partition_index[i])), 0, 2);
                float3 e0 = partition == 0 ? ep0 : (partition == 1 ? ep2 : ep4);
                float3 e1 = partition == 0 ? ep1 : (partition == 1 ? ep3 : ep5);
                float3 c = partition == 0 ? float3(1, 1, 1) : (partition == 1 ? float3(0.5, 0.5, 0.5) : float3(0, 0, 0));
                outputBlock.pixels[i] = c; // lerp(e0, e1, w);
            }
            return outputBlock;
        }
        if (g_params.debug_loss)
        {
            TextureBlock outputBlock;
            for (int i = 0; i < 16; i++)
            {
                float w = weights[i];
                int partition = clamp(int(partition_index[i]), 0, 2);
                float3 e0 = partition == 0 ? ep0 : (partition == 1 ? ep2 : ep4);
                float3 e1 = partition == 0 ? ep1 : (partition == 1 ? ep3 : ep5);
                float3 c = lerp(e0, e1, w);
                outputBlock.pixels[i] = abs(groundtruth.pixels[i] - c);
            }
            return outputBlock;
        }
        if (g_params.debug_quant)
        {
            TextureBlock outputBlock;
            for (int i = 0; i < 16; i++)
            {
                // R - 5,7,9 / 0, 0.5, 0.85
                // B - 11,15,23 / 1.14, 1.6, 2.2
                // G - 31,33,39 / 2.6, 2.7, 2.96
                // M - 63,95,191,255 / 3.65, 4.25, 5.25, 5.67
                // 3P - [5,7,9,11,15,23] - R to B
                // 2P - [5,9,11,15,23,31,39,63,95] R - M
                // 1P - [31,63,95,191,255] - G - M
                let R = float3(1, 0, 0);
                let G = float3(0, 1, 0);
                let B = float3(0, 0, 1);
                let M = float3(1, 0, 1);
                float3 c = 0;
                switch (qwc.y)
                {
                case 5:
                    c = R * 0.33;
                    break;
                case 7:
                    c = R * 0.67;
                    break;
                case 9:
                    c = R;
                    break;

                case 11:
                    c = B * 0.33;
                    break;
                case 15:
                    c = B * 0.50;
                    break;
                case 23:
                    c = B;
                    break;

                case 31:
                    c = G * 0.33;
                    break;
                case 33:
                    c = G * 0.50;
                    break;
                case 39:
                    c = G;
                    break;

                case 63:
                    c = M * 0.33;
                    break;
                case 95:
                    c = M * 0.67;
                    break;
                case 191:
                    c = M * 0.9;
                    break;
                case 255:
                    c = M;
                    break;
                }

                outputBlock.pixels[i] = c; // lerp(e0, e1, w);
            }
            return outputBlock;
        }
        return decompress3P();
    }
};

// Prevent line collapse by ensuring that all bound color lines are spread far apart
void bound_and_damp(float3 x, float3 y, inout float3 x_out, inout float3 y_out, float lr)
{
    let x_old = x_out;
    let y_old = y_out;

    float3 boxMin = float3(0.0, 0.0, 0.0);
    float3 boxMax = float3(1.0, 1.0, 1.0);

    bool xInside = all(x >= boxMin) && all(x <= boxMax);
    bool yInside = all(y >= boxMin) && all(y <= boxMax);

    float3 d = y - x;
    float distSq = dot(d, d);
    bool shouldClip = (!xInside || !yInside) || (distSq < 0.01);

    var new_x = x;
    var new_y = y;

    if (shouldClip)
    {
        float3 invDir = 1.0 / (d + 1e-6);
        float3 t0 = (boxMin - x) * invDir;
        float3 t1 = (boxMax - x) * invDir;
        float3 tSmall = min(t0, t1);
        float3 tBig = max(t0, t1);
        float tEnter = max(max(tSmall.x, tSmall.y), tSmall.z);
        float tExit = min(min(tBig.x, tBig.y), tBig.z);
        float tNewStart = max(tEnter, 0.0);
        float tNewEnd = min(tExit, 1.0);

        new_x = saturate(x + d * tNewStart);
        new_y = saturate(x + d * tNewEnd);
    }

    x_out = lerp(x_old, new_x, lr);
    y_out = lerp(y_old, new_y, lr);
}

float3 sample_color(float3 centroid, TextureBlock groundtruth)
{
    // find a pixel in groundtruth that is furthest from the centroid
    float max_dist = 0;
    int max_idx = 0;
    [unroll]
    for (int i = 0; i < 16; i++)
    {
        float dist = length(groundtruth.pixels[i] - centroid);
        if (dist > max_dist)
        {
            max_dist = dist;
            max_idx = i;
        }
    }
    return groundtruth.pixels[max_idx];
}

// Potentially use this vs solve_aabb_for_partition
bool solve_pca_eps(CompressedTextureBlock block, inout float3 ep0, inout float3 ep1, TextureBlock groundtruth, int partition_id, float lr = 1)
{
    let old_ep1 : float3 = ep1;
    let old_ep0 : float3 = ep0;
    float3 axis = float3(0.17, 0.83, 0.38);
    float3 centroid = float3(0);
    uint count = 0;

    [unroll]
    for (int i = 0; i < 16; i++)
    {
        if (int(block.partition_index[i]) == partition_id)
        {
            centroid += groundtruth.pixels[i];
            count += 1;
        }
    }
    centroid /= count;

    if (count == 0)
        return true;

    if (count == 1)
    {
        let new_ep0 = centroid;
        let new_ep1 = centroid;
        bound_and_damp(new_ep0, new_ep1, ep0, ep1, lr);
        return true;
    }

    float3x3 C = (float3x3)0;
    [unroll]
    for (int i = 0; i < 16; i++)
    {
        if (int(block.partition_index[i]) == partition_id)
        {
            float3 d = groundtruth.pixels[i] - centroid;
            C[0] += d.x * d; // Row 0: [xx, xy, xz]
            C[1] += d.y * d; // Row 1: [yx, yy, yz]
            C[2] += d.z * d; // Row 2: [zx, zy, zz]
        }
    }
    C /= count;

    // Check for degenerate cases of single color (low trace of C)
    float trace = C[0].x + C[1].y + C[2].z;
    if (trace < 3e-4)
    {
        // In this specific case, we need to push the pattern away from a single solid color
        // Gradient descent is great at this, but it's very slow
        let new_ep0 = centroid;
        let new_ep1 = centroid;
        bound_and_damp(new_ep0, new_ep1, ep0, ep1, lr);
        return false;
    }

    axis = float3(0.17, 0.83, 0.38);
    [unroll]
    for (int iter = 0; iter < 4; iter++)
    {
        axis = mul(C, axis);
        float lenSq = dot(axis, axis);
        if (lenSq > 1e-8)
        {
            axis *= rsqrt(lenSq);
        }
    }

    // The data is isotropic (C ~ I), so any direction passing through the centroid is valid
    if (dot(axis, axis) < 1e-8)
    {
        let new_ep0 = centroid;
        let new_ep1 = sample_color(centroid, groundtruth);
        bound_and_damp(new_ep0, new_ep1, ep0, ep1, lr);
        return false;
    }

    axis = normalize(axis);
    float min_t = 1000.0;
    float max_t = -1000.0;

    [unroll]
    for (int i = 0; i < 16; i++)
    {
        if (int(block.partition_index[i]) == partition_id)
        {
            float3 d = groundtruth.pixels[i] - centroid;
            float t = dot(d, axis);
            min_t = min(min_t, t);
            max_t = max(max_t, t);
        }
    }

    let new_ep0 = (centroid + axis * (min_t));
    let new_ep1 = (centroid + axis * (max_t));
    bound_and_damp(new_ep0, new_ep1, ep0, ep1, lr);
    return true;
}

float loss_mse(
    no_diff TextureBlock groundtruth, // frozen
    CompressedTextureBlock compressed)
{
    TextureBlock reconstructed = compressed.decompress3P();
    float totalError = 0.0f;

    for (int i = 0; i < 16; i++)
    {
        var diff = reconstructed.pixels[i] - groundtruth.pixels[i];
        totalError += dot(diff, diff); // L2 error
    }

    return totalError;
}

float estimate_partition_error_bound(float3x3 scatter_matrix, float count)
{
    float total_variance = scatter_matrix[0][0] + scatter_matrix[1][1] + scatter_matrix[2][2];
    float3 axis = float3(0.17, 0.83, 0.38);

    // Two rounds of power iteration to approximate the principle component (lambda_max)
    axis = mul(scatter_matrix, axis);
    axis *= rsqrt(dot(axis, axis) + 1e-6);
    axis = mul(scatter_matrix, axis);
    // Residue = variance - maximum lambda (from the 2 rounds of power iteration)
    float lambda_max = sqrt(dot(axis, axis));
    return max(0.0, total_variance - lambda_max);
}

// Scans the partition map and computes the lower bound error cheaply
float compute_error_fast(
    CompressedTextureBlock block,
    TextureBlock groundtruth,
    float current_best_loss)
{
    float3 means[3] = { float3(0), float3(0), float3(0) };

    // Cov x count
    float3x3 scatters[3] = { (float3x3)0, (float3x3)0, (float3x3)0 };
    float counts[3] = { 0, 0, 0 };
    [unroll]
    for (int i = 0; i < 16; i++)
    {
        uint p = block.partition_index[i];
        float3 px = groundtruth.pixels[i];

        means[p] += px;
        counts[p] += 1.0;

        // S = Sum(x*xT) - n * mean*meanT
        scatters[p][0] += px.x * px;
        scatters[p][1] += px.y * px;
        scatters[p][2] += px.z * px;
    }

    float total_lb = 0;

    [unroll]
    for (uint p = 0; p < 3; p++)
    {
        if (p >= block.max_partitions)
            break;

        if (counts[p] > 0)
        {
            float3 m = means[p];
            float3x3 correction;
            correction[0] = m.x * m;
            correction[1] = m.y * m;
            correction[2] = m.z * m;

            scatters[p] -= (correction / counts[p]);

            total_lb += estimate_partition_error_bound(scatters[p], counts[p]);
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
#define MAX_SLOTS 25

struct RankedSeeds
{
    uint8_t slots;
    // For some reason, if seeds/seeds_mask are not > 256 bytes, the shader performance suffers...
    // Likely due to VGPRs, which are inefficient to dynamically index as I am doing here
    // Ironically, using the L1/L2 cache here (the spilled memory) actually helps performance considerably
    // By forcing the masks to be at least 256 bytes, we trick the compiler into using the L1/L2 cache
    // and increase occupancy by reducing register pressure.
    // uint16_t seeds[MAX_DISTANCE * MAX_SLOTS]; // [dist][seeds] - up to 128 entries, use MAX_SLOTS >= 17
    uint seeds_masks[(MAX_DISTANCE * MAX_SLOTS + 2) / 3]; // 10 bits packed into 32 bits, use MAX_SLOTS >= 25
    uint8_t counts[MAX_DISTANCE];
    uint entries;

    uint16_t get(uint16_t n)
    {
        return uint16_t(seeds_masks[n / 3] >> uint((n % 3) * 10)) & 0x3FF;
        // return seeds[n];
    }

    [mutating]
    void add(uint16_t seed, uint16_t distance)
    {
        var count = counts[distance];
        if (count < slots)
        {
            let n = distance * MAX_SLOTS + count;
            // seeds[n] = seed + 1;
            seeds_masks[n / 3] |= uint(seed + 1) << uint((n % 3) * 10);
            counts[distance]++;
            entries++;
        }
    }

    uint16_t pack(out uint16_t partitions[], uint max_items)
    {
        uint16_t count = 0;
        for (uint16_t i = 0; i < MAX_DISTANCE * MAX_SLOTS; i++)
        {
            var seed = get(i);
            if (seed == 0)
            {
                continue;
            }
            partitions[count] = seed - 1;
            count++;
            if (count >= max_items)
            {
                break;
            }
        }
        return count;
    }
}

int find_top_partitions(inout CompressedTextureBlock block, TextureBlock groundtruth, inout uint16_t partitions[], uint candidates)
{
    uint8_t partition_index[16];
    block.cluster_astc(groundtruth, partition_index);

    var raw_map = CompressedTextureBlock.pack_partition_indices(partition_index);
    block.ideal_partition_map = raw_map;
    RankedSeeds ranked_seeds = { clamp(candidates / 8, 2, MAX_SLOTS) };
    // PCG32 prng = PCG32(g_params.seed);

    for (uint16_t i = 0; i < 1024; i++)
    {
        Permutation permutation = Id;
        var final_map = block.max_partitions == 2 ? LUT2_LOOKUP[i] : LUT3_LOOKUP[i];
        var perm_distance = block.max_partitions == 2 ? best_perm_distance_s2(raw_map, final_map, permutation)
                                                      : best_perm_distance_s3(raw_map, final_map, permutation);
        if (perm_distance < MAX_DISTANCE)
        {
            ranked_seeds.add(i, uint8_t(perm_distance));
        }
    }

    return ranked_seeds.pack(partitions, candidates);
}

float dist(float3 x, float3 ep0, float3 ep1)
{
    var lineDir = ep1 - ep0;
    var pointVec = x - ep0;
    return length(cross(pointVec, lineDir)) / length(lineDir);
}

float optimize<let exhaustive : bool = false>(inout CompressedTextureBlock block, TextureBlock groundtruth, uint steps, bool diagnostics_enabled, inout Diagnostics diagnostics)
{
    float lr = g_params.learning_rate;
    uint max_partitions = block.max_partitions;

    Permutation perm = Id;
    // if (diagnostics_enabled)
    // {
    //     diagnostics.loss_log[0][max_partitions - 1] = loss_mse(groundtruth, block);
    // }

    uint16_t partitions[MAX_DISTANCE * MAX_SLOTS] = { 0 };
    uint found = 0;
    if (exhaustive)
    {
        // TODO: scale down to only the LUT / S2 or S3 partitions (~400)
        found = steps;
    }
    else if (max_partitions > 1)
    {
        // This is ~100ms on cat.jpg (129600 threads)
        found = find_top_partitions(block, groundtruth, partitions, steps);
    }

    float best_loss = 1000;
    uint16_t best_candidate_id = 0;
    uint16_t best_seed = 0;
    diagnostics.partition_count[10] = 255;
    var current_block = block;
    PCG32 prng = PCG32(0);

    // Search for the best loss and parameters
    for (uint16_t candidate_id = 0; candidate_id < found; candidate_id++)
    {
        // uint16_t seed = prng.nextUint() % 1024; // partitions[candidate_id];
        uint16_t seed = exhaustive ? candidate_id : partitions[candidate_id];
        // uint16_t seed = ranked_seeds[candidate_id];
        // uint16_t seed = candidate_id;
        current_block.set_astc_seed(seed);

        float loss = compute_error_fast(current_block, groundtruth, best_loss);
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
        current_block.set_astc_seed(best_seed);
    }
    solve_pca_eps(current_block, current_block.ep0, current_block.ep1, groundtruth, 0);
    if (max_partitions > 1)
        solve_pca_eps(current_block, current_block.ep2, current_block.ep3, groundtruth, 1);
    if (max_partitions > 2)
        solve_pca_eps(current_block, current_block.ep4, current_block.ep5, groundtruth, 2);
    current_block.solve_weights(groundtruth);
    float loss = loss_mse(groundtruth, current_block);
    if (diagnostics_enabled)
    {
        diagnostics.loss_log[11][max_partitions - 1] = loss;
    }

    block = current_block;
    block.astc_seed = best_candidate_id;
    Permutation id;
    block.perm = block.max_partitions == 2 ? best_perm_distance_s2(block.ideal_partition_map, block.astc_partition_map, id)
                                           : best_perm_distance_s3(block.ideal_partition_map, block.astc_partition_map, id);
    return loss;
}

// [require(spvShaderClockKHR)]
[shader("compute")]
[numthreads(64, 1, 1)]
void compress_3P_step(uint3 dispatchThreadID: SV_DispatchThreadID, uint3 groupThreadId: SV_GroupThreadID)
{
    uint blockIdx = dispatchThreadID.x;
    if (blockIdx >= g_params.num_blocks)
        return;
    g_diagnostics[blockIdx].start_clock = getRealtimeClock();

    Permutation perm = Id;
    TextureBlock groundtruth = g_groundtruth[blockIdx];

    var prng = PCG32(g_params.seed);
    CompressedTextureBlock block;
    block.max_partitions = g_params.max_partitions;

    var block1 = block;
    var block2 = block;
    var block3 = block;
    float loss1 = 0;
    float loss2 = 0;
    float loss3 = 0;
    float loss = 0;

    let exhaustive = g_params.exhaustive;

    uint steps = g_params.steps;
    if (g_params.ensemble)
    {
        // 1P does not need exhaustive search
        block1.max_partitions = 1;
        loss1 = optimize<false>(block1, groundtruth, steps, true, g_diagnostics[blockIdx]);

        block2.max_partitions = 2;
        loss2 = exhaustive ? optimize<true>(block2, groundtruth, steps, true, g_diagnostics[blockIdx])
                           : optimize<false>(block2, groundtruth, steps, true, g_diagnostics[blockIdx]);

        if (g_params.max_partitions == 3)
        {
            block3.max_partitions = 3;
            loss3 = exhaustive ? optimize<true>(block3, groundtruth, steps, true, g_diagnostics[blockIdx])
                               : optimize<false>(block3, groundtruth, steps, true, g_diagnostics[blockIdx]);
        }
    }
    else
    {
        // 1P does not need exhaustive search
        block.max_partitions = g_params.max_partitions;
        loss = optimize<false>(block, groundtruth, steps, true, g_diagnostics[blockIdx]);
    }

    g_diagnostics[blockIdx].optim_ended_clock = getRealtimeClock();

    float final_loss = 0;
    if (!g_params.no_quantization)
    {
        if (g_params.ensemble)
        {
            block1.quantize(groundtruth);
            float quantized_loss1 = loss_mse(groundtruth, block1);
            block2.quantize(groundtruth);
            float quantized_loss2 = loss_mse(groundtruth, block2);
            float quantized_loss3 = 1000;
            if (g_params.max_partitions == 3)
            {
                block3.quantize(groundtruth);
                quantized_loss3 = loss_mse(groundtruth, block3);
            }
            if (quantized_loss3 < quantized_loss2 && quantized_loss3 < quantized_loss1)
            {
                g_diagnostics[blockIdx].final_unquantized_loss = loss3;
                block = block3;
                final_loss = quantized_loss3;
            }
            else if (quantized_loss2 < quantized_loss1)
            {
                g_diagnostics[blockIdx].final_unquantized_loss = loss2;
                block = block2;
                final_loss = quantized_loss2;
            }
            else
            {
                g_diagnostics[blockIdx].final_unquantized_loss = loss1;
                block = block1;
                final_loss = quantized_loss1;
            }
        }
        else
        {
            g_diagnostics[blockIdx].final_unquantized_loss = loss;
            block.quantize(groundtruth);
            final_loss = loss_mse(groundtruth, block);
        }
    }
    else
    {
        final_loss = loss_mse(groundtruth, block);
    }
    g_compressedBlock3P[blockIdx] = block;
    g_reconstructed[blockIdx] = block.reconstruct(groundtruth);
    // g_diagnostics[blockIdx].partition_hamming_error = best_perm_distance_s3(block.ideal_partition_map, block.astc_partition_map, perm);
    g_final_loss[blockIdx] = final_loss;
    g_diagnostics[blockIdx].finished_clock = getRealtimeClock();
}

// [shader("compute")]
// [numthreads(64, 1, 1)]
// void get_loss_mse(uint3 dispatchThreadID : SV_DispatchThreadID)
// {
//     uint blockIdx = dispatchThreadID.x;
//     if (blockIdx >= g_params.num_blocks) return;
//     g_final_loss[blockIdx] = loss_mse(g_groundtruth[blockIdx], g_compressedBlock3P[blockIdx]);
// }
