// See T42-Shannon-Woods-NVIDIA.pdf
// This implements an ASTC/BC7 texture encoder (or at least their parameters)
// by creating a differentiable decoding function (decompress), and then
// treat the ||(decompress(params) - groundtruth)||^2 as a blackbox optimization
// problem where we do gradient descent over.

// Each ASTC/BC block is 16x vec3 of RGBs
struct TextureBlock : IDifferentiable
{
    float3 pixels[16];
};

// Diagnostics data
struct Diagnostics
{
    uint partition_hamming_error;
    float loss_log[20];
    uint2 start_clock;
    uint2 optim_ended_clock;
    uint2 finished_clock;
    uint2 timestamps[20];
    uint partition_hamming_error_log[20];
    uint ideal_partition_log[20];
    uint partition_count[20];
};

// Frozen weights (to avoid generating expensive derivatives in the bkw pass)
struct NonDifferentiableWeights {
    float data[16];
    __subscript(int n) -> float
    {
        get { return data[n]; }
        set { data[n] = newValue; }
    }
}

struct NonDifferentiableIntWeights {
    int data[16];
    __subscript(int n) -> int
    {
        get { return data[n]; }
        set { data[n] = newValue; }
    }
}

struct Params
{
    float learning_rate;
    uint steps;
    uint snap_steps;
    uint num_blocks;
    bool snap;
    uint max_partitions;
    bool debug_reconstruction;
    uint exact_steps;
    bool use_pca;
};
ConstantBuffer<Params> g_params;

// The image to encode (or to compute the loss of)
StructuredBuffer<TextureBlock> g_groundtruth;

// The reconstructed image
RWStructuredBuffer<TextureBlock> g_reconstructed;

// Diagnostics for this run
RWStructuredBuffer<Diagnostics> g_diagnostics;

// The ASTC/BC compressed block parameters for the 2-partition problem (ep0,ep1,ep2,ep3, 16x weights, 16x partition logits)
RWStructuredBuffer<CompressedTextureBlock3P> g_compressedBlock3P;

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
enum Permutation : uint
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

uint apply_permutation(Permutation perm, uint x) {
    switch (perm) {
    case Id: return x;
    case Swap01: return permute_swap01(x);
    case Swap02: return permute_swap02(x);
    case Swap12: return permute_swap12(x);
    case Cycle120: return permute_cycle_120(x);
    case Cycle201: return permute_cycle_201(x);
    }
    return x;
}

static const uint M5 = 0x55555555; // 0101...
static const uint MA = 0xAAAAAAAA; // 1010...

uint best_perm_distance_s3(uint x, uint y, out Permutation perm)
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

    uint p0 = (count_diffs(base)        << 3) | 0;
    uint p1 = (count_diffs(base ^ m01)  << 3) | 1;
    uint p2 = (count_diffs(base ^ m02)  << 3) | 2;
    uint p3 = (count_diffs(base ^ m12)  << 3) | 3;
    uint p4 = (count_diffs(base ^ m_cp) << 3) | 4;
    uint p5 = (count_diffs(base ^ m_cm) << 3) | 5;

    uint min01 = min(p0, p1);
    uint min23 = min(p2, p3);
    uint min45 = min(p4, p5);
    uint best = min(min(min01, min23), min45);

    perm = Permutation(best & 7);
    return best >> 3;
}

uint best_perm_distance_s2(uint x, uint y, out Permutation perm)
{
    uint base = x ^ y;
    uint x_shr1 = x >> 1;
    
    uint m01 = (~x_shr1) & M5;

    uint p0 = (count_diffs(base)        << 1) | 0;
    uint p1 = (count_diffs(base ^ m01)  << 1) | 1;

    uint min01 = min(p0, p1);

    perm = Permutation(min01 & 1);
    return min01 >> 1;
}

uint lut3_key(uint x)
{
    // pack into trits, preserve proper endianness
    uint result = 0;
    [unroll]
    for (int i = 15; i >= 0; i--)
    {
        result = result * 3 + ((x >> (i*2)) & 3);
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
        result = result * 2 + ((x >> (i*2)) & 3);
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

uint get_closest_seed3(uint input, out Permutation perm, out uint final_pattern) {
    uint key = canonicalize_lut3(input);
    uint seed = (g_astc_3p_4x4_lut_s3[key / 3] >> ((key % 3) * 10)) & 0x3FF;
    uint pattern = LUT3_LOOKUP[seed];
    uint dist = best_perm_distance_s3(input, pattern, perm);

    final_pattern = pattern;
    return seed;
}

uint get_closest_seed2(uint input, out Permutation permutation, out uint final_pattern) {
    uint key = canonicalize_lut2(input);
    uint seed = (g_astc_2p_4x4_lut_s2[key / 3] >> ((key % 3) * 10)) & 0x3FF;
    uint pattern = LUT2_LOOKUP[seed];
    uint dist = best_perm_distance_s2(input, pattern, permutation);

    final_pattern = pattern;
    return seed;
}

// The ASTC/BC encoder problem (single-partition) is to solve for
struct CompressedTextureBlock3P : IDifferentiable
{
    float3 ep0, ep1; // partition 1
    float3 ep2, ep3; // partition 2
    float3 ep4, ep5; // partition 2
    
    no_diff NonDifferentiableWeights weights; // we don't have to gradient descent on this since we can do a full solve
    no_diff NonDifferentiableIntWeights partition_index; // Partition blend logits
    no_diff uint astc_partition_map; // Final 16-bit valid partition map
    no_diff uint ideal_partition_map;
    no_diff uint astc_seed;
    no_diff uint perm;
    no_diff uint partition_count;
    no_diff uint max_partitions;

    uint pack_partition_indices()
    {
        uint raw_map = 0;
        for (int i = 0; i < 16; i++)
        {
            uint logit = clamp(uint(round(partition_index[i])), 0, 2);
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
        from_pair2      = (perm == Swap12 || perm == Cycle201);
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
        } else {
            closest_seed = get_closest_seed2(raw_map, permutation, final_mask);
        }

        astc_seed = closest_seed;
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

    static float distSq(float3 P, float3 L, float pDotL, float invLenSq)
    {
        float pDotP = dot(P, P);
        return pDotP - (pDotL * pDotL * invLenSq);
    }

    static uint argmin(float d1, float d2, float d3)
    {
        if (d1 < d2 && d1 < d3) return 0;
        if (d2 < d3) return 1;
        return 2; 
    }

    // Cheap 1-step update to find the optimal weights that best fits ep0/ep1, ep2/ep3 to groundtruth
    // This is a shortcut to avoid n steps of descent on weight, and avoid computing weight derivatives
    [mutating]
    void solve_weights(TextureBlock groundtruth) {
        // Project weights again
        var L1 = ep1 - ep0;
        var L2 = ep3 - ep2;
        var L3 = ep5 - ep4;
        float invLenSq1 = 1.0 / (dot(L1, L1) + 1e-6f);
        float invLenSq2 = 1.0 / (dot(L2, L2) + 1e-6f);
        float invLenSq3 = 1.0 / (dot(L3, L3) + 1e-6f);
        for (int i = 0; i < 16; i++)
        {
            var C = groundtruth.pixels[i];
            var p = partition_index[i];
            var pDotL    = p == 0 ? dot(C - ep0, L1) : (p == 1 ? dot(C - ep2, L2) : dot(C - ep4, L3));
            var invLenSq = p == 0 ? invLenSq1 : (p == 1 ? invLenSq2 : invLenSq3);
            var w = pDotL * invLenSq;
            weights[i] = saturate(w);
        }
    }

    [mutating]
    uint solve_partition(TextureBlock groundtruth) {
        var L1 = ep1 - ep0;
        var L2 = ep3 - ep2;
        var L3 = ep5 - ep4;
        float invLenSq1 = 1.0 / (dot(L1, L1) + 1e-6f);
        float invLenSq2 = 1.0 / (dot(L2, L2) + 1e-6f);
        float invLenSq3 = 1.0 / (dot(L3, L3) + 1e-6f);
        uint partitions = 0;
        for (int i = 0; i < 16; i++)
        {
            var C = groundtruth.pixels[i];
            var P1 = C - ep0;
            var P2 = C - ep2;
            var P3 = C - ep4;
            var pDotL1 = dot(P1, L1);
            var pDotL2 = dot(P2, L2);
            var pDotL3 = dot(P3, L3);
            var d1 = distSq(P1, L1, pDotL1, invLenSq1);
            var d2 = distSq(P2, L2, pDotL2, invLenSq2);
            var d3 = max_partitions == 3 ? distSq(P3, L3, pDotL3, invLenSq3) : 1000.0;
            var p = argmin(d1, d2, d3);
            partition_index[i] = p;
            partitions |= (1 << p);

            // Project the weights since it's pretty much free
            var pDotL    = p == 0 ? pDotL1 : (p == 1 ? pDotL2 : pDotL3);
            var invLenSq = p == 0 ? invLenSq1 : (p == 1 ? invLenSq2 : invLenSq3);
            var w = pDotL * invLenSq;
            weights[i] = saturate(w);
        }
        return partitions;
    }

    [mutating]
    void one_step_solve_partition(TextureBlock groundtruth, bool should_snap) {
        if (max_partitions == 1) {
            solve_weights(groundtruth);
            return;
        }
        // Assume that the color endpoints are already solved
        uint partitions = solve_partition(groundtruth);
        // "Scramble" any blocks that settle onto the single-partition basin
        // This is our poor man's gradient restart :)
        bool single_partition = max_partitions > 1 && (partitions == 1 || partitions == 2 || partitions == 4);
        if (should_snap || single_partition) {
            snap();
            // Project weights again
            solve_weights(groundtruth);
        }
    }

    [Differentiable]
    TextureBlock decompress3P()
    {
        TextureBlock outputBlock;
        for (uint i = 0; i < 16; i++)
        {
            var w = detach(weights[i]);
            var partition = clamp(int(detach(partition_index[i])), 0, max_partitions - 1);
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
        for (i = 0; i < 8; i++) {
            ep1 = groundtruth.pixels[prng.nextUint() % 16];
            var d = ep1 - ep0;
            if (dot(d, d) > 0.3) {
                break;
            }
        }
        for (i = 0; i < 8; i++) {
            ep2 = groundtruth.pixels[prng.nextUint() % 16];
            if (dist(ep2, ep0, ep1) > 0.3) {
                break;
            }
        }
        for (i = 0; i < 8; i++) {
            ep3 = groundtruth.pixels[prng.nextUint() % 16];
            if (dist(ep3, ep0, ep1) > 0.3) {
                break;
            }
        }
        for (i = 0; i < 8; i++) {
            ep4 = groundtruth.pixels[prng.nextUint() % 16];
            if (dist(ep4, ep0, ep1) <= 0.3) {
                continue;
            }
            if (dist(ep4, ep2, ep3) > 0.3) {
                break;
            }
        }
        for (i = 0; i < 8; i++) {
            ep5 = groundtruth.pixels[prng.nextUint() % 16];
            if (dist(ep5, ep0, ep1) <= 0.3) {
                continue;
            }
            if (dist(ep5, ep2, ep3) > 0.3) {
                break;
            }
        }
    }

    TextureBlock reconstruct()
    {
        if (g_params.debug_reconstruction) {
            TextureBlock outputBlock;
            for (int i = 0; i < 16; i++)
            {
                float w = round(detach(weights[i]) * 4) / 4;
                int partition = clamp(int(detach(partition_index[i])), 0, 2);
                float3 e0 = partition == 0 ? ep0 : (partition == 1 ? ep2 : ep4);
                float3 e1 = partition == 0 ? ep1 : (partition == 1 ? ep3 : ep5);
                float3 c = partition == 0 ? float3(1,1,1) : (partition == 1 ? float3(0.5, 0.5, 0.5) : float3(0,0,0));
                outputBlock.pixels[i] = c; // lerp(e0, e1, w);
            }
            return outputBlock;
        }
        return decompress3P();
    }
};

// Potentially use this vs solve_aabb_for_partition
uint solve_pca_eps(CompressedTextureBlock3P block, inout float3 ep0, inout float3 ep1, TextureBlock groundtruth, int partition_id)
{
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

    if (count <= 1) {
        ep0 = saturate(count > 0 ? centroid / count : float3(0));
        ep1 = ep0;
        return uint(count);
    }
    
    centroid /= count;
    float xx = 0, xy = 0, xz = 0, yy = 0, yz = 0, zz = 0;
    
    [unroll]
    for (int i = 0; i < 16; i++)
    {
        if (int(block.partition_index[i]) == partition_id)
        {
            float3 d = groundtruth.pixels[i] - centroid;
            xx += d.x * d.x;
            xy += d.x * d.y;
            xz += d.x * d.z;
            yy += d.y * d.y;
            yz += d.y * d.z;
            zz += d.z * d.z;
        }
    }

    // Power iterations
    [unroll]
    for(int iter = 0; iter < 4; iter++)
    {
        float3 new_axis;
        new_axis.x = xx * axis.x + xy * axis.y + xz * axis.z;
        new_axis.y = xy * axis.x + yy * axis.y + yz * axis.z;
        new_axis.z = xz * axis.x + yz * axis.y + zz * axis.z;
        axis = new_axis;
    }

    if (dot(axis, axis) < 1e-8) {
        ep0 = saturate(centroid);
        ep1 = saturate(centroid);
        return count;
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

    ep0 = saturate(centroid + axis * min_t);
    ep1 = saturate(centroid + axis * max_t);
    return count;
}

void solve_aabb_eps(CompressedTextureBlock3P block, inout float3 ep0, inout float3 ep1, TextureBlock groundtruth, int partition_id)
{
    float3 min_ep = 1, max_ep = 0;

    [unroll]
    for (int i = 0; i < 16; i++)
    {
        bool inlier = block.partition_index[i] == partition_id;
        min_ep = min(inlier ? groundtruth.pixels[i] : 1, min_ep);
        max_ep = max(inlier ? groundtruth.pixels[i] : 0, max_ep);
    }

    ep0 = saturate(min_ep);
    ep1 = saturate(max_ep);
}

[Differentiable]
float loss_3P(
    no_diff TextureBlock groundtruth, // frozen
    CompressedTextureBlock3P compressed)
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

float dist(float3 x, float3 ep0, float3 ep1)
{
    var lineDir = ep1 - ep0;
    var pointVec = x - ep0;
    return length(cross(pointVec, lineDir)) / length(lineDir);
}

// [require(spvShaderClockKHR)]
[shader("compute")]
[numthreads(64, 1, 1)]
void compress_3P_step(uint3 dispatchThreadID : SV_DispatchThreadID, uint3 groupThreadId : SV_GroupThreadID)
{
    uint blockIdx = dispatchThreadID.x;
    if (blockIdx >= g_params.num_blocks) return;
    g_diagnostics[blockIdx].start_clock = getRealtimeClock();

    Permutation perm = Id;
    CompressedTextureBlock3P block = g_compressedBlock3P[blockIdx];
    TextureBlock groundtruth = g_groundtruth[blockIdx];
    float lr = g_params.learning_rate;
    uint steps = g_params.steps;
    bool can_snap = g_params.snap > 0;
    uint first_snap_step = g_params.snap_steps == 0 ? uint(steps * 0.5) : steps - g_params.snap_steps;
    uint first_lsq_step = 1;
    uint exact_steps = g_params.exact_steps;

    var prng = PCG32(0);
    block.max_partitions = g_params.max_partitions;
    block.random_initialize(groundtruth, prng);
    for (int i = 0; i < 16; i++) {
        if (block.partition_index[i] >= block.max_partitions) {
            block.partition_index[i] = prng.nextUint() % block.max_partitions;
        }
    }

    uint checkpoint = max(1, steps / 20);
    for (int step = 0; step < steps; step++)
    {
        // Coordinate descent: gradient optimize ep, one-step solve partition
        bool should_use_lsq = exact_steps > 0 && (step >= first_lsq_step) && (step <= first_lsq_step + exact_steps);
        if (should_use_lsq) {
            // "Exact" approximate solve_pca_eps vs solve_aabb_eps
            // Note that the exact solves tend to get stuck in local optimums that even the gradient
            // optimizer can't climb out of. In some problems, reaches the local optimum faster
            if (g_params.use_pca) {
                solve_pca_eps(block, block.ep0, block.ep1, groundtruth, 0);
                solve_pca_eps(block, block.ep2, block.ep3, groundtruth, 1);
                solve_pca_eps(block, block.ep4, block.ep5, groundtruth, 2);
            } else {
                solve_aabb_eps(block, block.ep0, block.ep1, groundtruth, 0);
                solve_aabb_eps(block, block.ep2, block.ep3, groundtruth, 1);
                solve_aabb_eps(block, block.ep4, block.ep5, groundtruth, 2);
            }
        } else {
            // Backprop on the color eps
            // Generally reaches the optimum ~ same 
            DifferentialPair<CompressedTextureBlock3P> cb_pair = diffPair(block);
            bwd_diff(loss_3P)(groundtruth, cb_pair, 1.0f);
            CompressedTextureBlock3P.Differential gradient = cb_pair.d;
            block.ep0 = saturate(block.ep0 - gradient.ep0 * lr);
            block.ep1 = saturate(block.ep1 - gradient.ep1 * lr);
            block.ep2 = saturate(block.ep2 - gradient.ep2 * lr);
            block.ep3 = saturate(block.ep3 - gradient.ep3 * lr);
            block.ep4 = saturate(block.ep4 - gradient.ep4 * lr);
            block.ep5 = saturate(block.ep5 - gradient.ep5 * lr);
        }
        // One-step solve the partition
        block.one_step_solve_partition(groundtruth, can_snap && (step >= first_snap_step || step >= steps - 1));

        if (step % checkpoint == 0) {
            uint iter = step / checkpoint;
            g_diagnostics[blockIdx].timestamps[iter] = getRealtimeClock();
            g_diagnostics[blockIdx].loss_log[iter] = loss_3P(groundtruth, block);

            uint pattern = block.pack_partition_indices();
            uint final_mask = 0;
            uint2 closest_seed = block.max_partitions == 3
                ? get_closest_seed3(pattern, perm, final_mask)
                : get_closest_seed2(pattern, perm, final_mask);
            g_diagnostics[blockIdx].partition_hamming_error_log[iter] = block.max_partitions == 3 
                ? best_perm_distance_s3(pattern, final_mask, perm) 
                : best_perm_distance_s2(pattern, final_mask, perm);
            g_diagnostics[blockIdx].ideal_partition_log[iter] = pattern;

            uint p0 = hamming_distance_2b(pattern, 0) < 16;
            uint p1 = hamming_distance_2b(pattern, 0x55555555) < 16;
            uint p2 = hamming_distance_2b(pattern, 0xaaaaaaaa) < 16;
            g_diagnostics[blockIdx].partition_count[iter] = p0 + p1 + p2;
        }
    }

    g_diagnostics[blockIdx].optim_ended_clock = getRealtimeClock();
    g_compressedBlock3P[blockIdx] = block;
    g_reconstructed[blockIdx] = block.reconstruct();
    g_diagnostics[blockIdx].partition_hamming_error = best_perm_distance_s3(block.ideal_partition_map, block.astc_partition_map, perm);
    g_final_loss[blockIdx] = loss_3P(groundtruth, block);
    g_diagnostics[blockIdx].finished_clock = getRealtimeClock();
}

// [shader("compute")]
// [numthreads(64, 1, 1)]
// void get_loss_3P(uint3 dispatchThreadID : SV_DispatchThreadID)
// {
//     uint blockIdx = dispatchThreadID.x;
//     if (blockIdx >= g_params.num_blocks) return;
//     g_final_loss[blockIdx] = loss_3P(g_groundtruth[blockIdx], g_compressedBlock3P[blockIdx]);
// }
