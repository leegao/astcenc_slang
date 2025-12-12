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

// The ASTC/BC encoder problem (single-partition) is to solve for
struct CompressedTextureBlock3P : IDifferentiable
{
    float3 ep0, ep1; // partition 1
    float3 ep2, ep3; // partition 2
    float3 ep4, ep5; // partition 2
    
    no_diff NonDifferentiableWeights weights; // we don't have to gradient descent on this since we can do a full solve
    no_diff NonDifferentiableWeights partition_logits; // Partition blend logits
    no_diff uint astc_partition_map; // Final 16-bit valid partition map
    no_diff uint ideal_partition_map;
    no_diff uint astc_seed;
};

struct CompressStepParams
{
    float learning_rate;
    uint steps;
    uint snap_steps;
    uint num_blocks;
    uint snap;
};

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

// The learning rate and # of steps to take
RWStructuredBuffer<CompressStepParams> g_compress_step_params;

// ASTC 2-partition LUT to snap a partition map to a valid astc partition seed
StructuredBuffer<uint> g_lut_ideal_to_seed;  // 65536-entry (256KB)
// StructuredBuffer<uint> g_lut_seed_to_mask;  // 65536-entry (256KB)

struct LUT
{
    uint lut2[1024];
    uint lut3[1024];
};
ConstantBuffer<LUT> g_lut;   // 1024-entry (4KB)

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

// Used to evaluate the # of incorrect partitions when we snap a block to a valid astc partition seed
uint hamming_distance(uint x, uint y)
{
    return countbits(x ^ y);
}

uint hamming_distance_2b(uint x, uint y)
{
    uint z = x ^ y;
    z |= z >> 1;
    z &= 0x55555555;
    return countbits(z);
}

uint get_closest_seed(uint input) {
    // For 3P
    uint closest = 0;
    uint best_dist = 16;
    [unroll]
    for (int seed = 0; seed < 1024; seed++) {
        uint pattern = LUT3_LOOKUP[seed];
        uint dist = hamming_distance_2b(pattern, input);
        // // if (dist == 0) return seed; // the divergence actually doubles the time somehow
        if (dist < best_dist) {
            closest = seed;
            best_dist = dist;
        }
    }
    return closest;
}

// Snap the partition map within a 2P block into a valid astc partition seed
// Note: snapping actually introduces a local minimum problem for most greedy
// optimization strategies. In cases where you have 1-2 / 16 pixels with a 3rd
// color, and those 1-2 pixels cannot be selected into the ideal partition because
// there are no valid astc patterns for the given ep set that will assign those
// pixels to the right partition, then the only thing our optimizer can do
// is to compute this weird weighted avg color for the block instead.
void snap(inout CompressedTextureBlock3P block)
{
    var raw_map = pack_partition_indices_to_mask(block.partition_logits.data);
    var closest_seed = get_closest_seed(raw_map);
    var final_mask = LUT3_LOOKUP[closest_seed];

    block.astc_seed = closest_seed;
    block.astc_partition_map = final_mask;
    block.ideal_partition_map = raw_map;

    // Snap our partition logits into the final mask
    for (int i = 0; i < 16; i++)
    {
        block.partition_logits[i] = ((final_mask >> (2 * i)) & 3); // Comment this out to see what happens w/o snapping
    }
}

float distSq(float3 P, float3 L, float pDotL, float invLenSq)
{
    float pDotP = dot(P, P);
    return pDotP - (pDotL * pDotL * invLenSq);
}

// Check if a color is closer to the first line (ep1-ep0) or the second
uint get_partition(float d1, float d2, float d3)
{
    if (d1 < d2 && d1 < d3) return 0;
    if (d2 < d3) return 1;
    return 2;
}

// Cheap 1-step update to find the optimal weights that best fits ep0/ep1, ep2/ep3 to groundtruth
// This is a shortcut to avoid n steps of descent on weight, and avoid computing weight derivatives
void one_step_opt(inout CompressedTextureBlock3P block, TextureBlock groundtruth, bool should_snap) {
    var L1 = block.ep1 - block.ep0;
    var L2 = block.ep3 - block.ep2;
    var L3 = block.ep5 - block.ep4;
    float invLenSq1 = 1.0 / (dot(L1, L1) + 1e-6f);
    float invLenSq2 = 1.0 / (dot(L2, L2) + 1e-6f);
    float invLenSq3 = 1.0 / (dot(L3, L3) + 1e-6f);

    for (int i = 0; i < 16; i++)
    {
        var C = groundtruth.pixels[i];
        var P1 = C - block.ep0;
        var P2 = C - block.ep2;
        var P3 = C - block.ep4;
        var pDotL1 = dot(P1, L1);
        var pDotL2 = dot(P2, L2);
        var pDotL3 = dot(P3, L3);
        var d1 = distSq(P1, L1, pDotL1, invLenSq1);
        var d2 = distSq(P2, L2, pDotL2, invLenSq2);
        var d3 = distSq(P3, L3, pDotL3, invLenSq3);
        var partition = get_partition(d1, d2, d3);
        block.partition_logits[i] = partition;
        if (should_snap) {
            snap(block);
            partition = int(block.partition_logits[i]);
        }

        var pDotL = partition == 0 ? pDotL1 : (partition == 1 ? pDotL2 : pDotL3);
        var invLenSq = partition == 0 ? invLenSq1 : (partition == 1 ? invLenSq2 : invLenSq3);
        
        var w = pDotL * invLenSq; // Add epsilon for safety
        block.weights[i] = saturate(w);
    }
}

// Transform the partition_logits to a uint16 partition map (index into the astc partition LUT)
uint pack_partition_indices_to_mask(float p_logits[16])
{
    uint raw_map = 0;
    for (int i = 0; i < 16; i++)
    {
        uint logit = clamp(round(p_logits[i]), 0, 2);
        raw_map |= (logit << (i * 2));
    }
    return raw_map;
}

[Differentiable]
TextureBlock decompress3P(CompressedTextureBlock3P blockCoefficients)
{
    var ep0 = blockCoefficients.ep0;
    var ep1 = blockCoefficients.ep1;
    var ep2 = blockCoefficients.ep2;
    var ep3 = blockCoefficients.ep3;
    var ep4 = blockCoefficients.ep4;
    var ep5 = blockCoefficients.ep5;

    TextureBlock outputBlock;
    for (uint i = 0; i < 16; i++)
    {
        var w = detach(blockCoefficients.weights[i]);
        var partition = int(detach(blockCoefficients.partition_logits[i]));
        var e0 = partition == 0 ? ep0 : (partition == 1 ? ep2 : ep4);
        var e1 = partition == 0 ? ep1 : (partition == 1 ? ep3 : ep5);
        outputBlock.pixels[i] = lerp(e0, e1, w);
    }
    return outputBlock;
}

[Differentiable]
float loss_3P(
    no_diff TextureBlock groundtruth, // frozen
    CompressedTextureBlock3P compressed)
{
    TextureBlock reconstructed = decompress3P(compressed);
    float totalError = 0.0f;
    
    for (int i = 0; i < 16; i++)
    {
        var diff = reconstructed.pixels[i] - groundtruth.pixels[i];
        totalError += dot(diff, diff); // L2 error
    }
    
    return totalError;
}


TextureBlock reconstruct(CompressedTextureBlock3P blockCoefficients, uint blockIdx)
{
    // float3 ep0 = blockCoefficients.ep0;
    // float3 ep1 = blockCoefficients.ep1;
    // float3 ep2 = blockCoefficients.ep2;
    // float3 ep3 = blockCoefficients.ep3;
    // float3 ep4 = blockCoefficients.ep4;
    // float3 ep5 = blockCoefficients.ep5;

    // TextureBlock outputBlock;
    // for (int i = 0; i < 16; i++)
    // {
    //     float w = 0; // round(detach(blockCoefficients.weights[i]));
    //     int partition = clamp(int(detach(blockCoefficients.partition_logits[i])), 0, 2);
    //     float3 e0 = partition == 0 ? ep0 : (partition == 1 ? ep2 : ep4);
    //     float3 e1 = partition == 0 ? ep1 : (partition == 1 ? ep3 : ep5);
    //     float3 c = partition == 0 ? float3(1,1,1) : (partition == 1 ? float3(0.5, 0.5, 0.5) : float3(0,0,0));
    //     outputBlock.pixels[i] = c; // lerp(e0, e1, w);
    // }
    // return outputBlock;
    return decompress3P(blockCoefficients);
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
    if (blockIdx >= g_compress_step_params[0].num_blocks) return;
    g_diagnostics[blockIdx].start_clock = getRealtimeClock();

    CompressedTextureBlock3P value = g_compressedBlock3P[blockIdx];
    TextureBlock groundtruth = g_groundtruth[blockIdx];
    float lr = g_compress_step_params[0].learning_rate;
    uint steps = g_compress_step_params[0].steps;
    bool can_snap = g_compress_step_params[0].snap > 0;
    uint first_snap_step = uint(steps * 0.7);
    uint checkpoint = max(1, steps / 20);
    int step;
    int i;

    // Pick 6 random pairs of endpoints
    var prng = PCG32(0);
    value.ep0 = groundtruth.pixels[prng.nextUint() % 16];
    value.ep1 = groundtruth.pixels[prng.nextUint() % 16];
    for (i = 0; i < 8; i++) {
        value.ep1 = groundtruth.pixels[prng.nextUint() % 16];
        var d = value.ep1 - value.ep0;
        if (dot(d, d) > 0.3) {
            break;
        }
    }
    for (i = 0; i < 8; i++) {
        value.ep2 = groundtruth.pixels[prng.nextUint() % 16];
        if (dist(value.ep2, value.ep0, value.ep1) > 0.3) {
            break;
        }
    }
    for (i = 0; i < 8; i++) {
        value.ep3 = groundtruth.pixels[prng.nextUint() % 16];
        if (dist(value.ep3, value.ep0, value.ep1) > 0.3) {
            break;
        }
    }
    for (i = 0; i < 8; i++) {
        value.ep4 = groundtruth.pixels[prng.nextUint() % 16];
        if (dist(value.ep4, value.ep0, value.ep1) <= 0.3) {
            continue;
        }
        if (dist(value.ep4, value.ep2, value.ep3) > 0.3) {
            break;
        }
    }
    for (i = 0; i < 8; i++) {
        value.ep5 = groundtruth.pixels[prng.nextUint() % 16];
        if (dist(value.ep5, value.ep0, value.ep1) <= 0.3) {
            continue;
        }
        if (dist(value.ep5, value.ep2, value.ep3) > 0.3) {
            break;
        }
    }

    for (step = 0; step < int(steps); step++)
    {
        DifferentialPair<CompressedTextureBlock3P> cb_pair = diffPair(value);
        bwd_diff(loss_3P)(groundtruth, cb_pair, 1.0f);
        CompressedTextureBlock3P.Differential gradient = cb_pair.d;

        value.ep0 = saturate(value.ep0 - gradient.ep0 * lr);
        value.ep1 = saturate(value.ep1 - gradient.ep1 * lr);
        value.ep2 = saturate(value.ep2 - gradient.ep2 * lr);
        value.ep3 = saturate(value.ep3 - gradient.ep3 * lr);
        value.ep4 = saturate(value.ep4 - gradient.ep4 * lr);
        value.ep5 = saturate(value.ep5 - gradient.ep5 * lr);
        one_step_opt(value, groundtruth, can_snap && (step > first_snap_step || step >= steps - 1));

        if (step % checkpoint == 0) {
            uint iter = step / checkpoint;
            g_diagnostics[blockIdx].timestamps[iter] = getRealtimeClock();
            g_diagnostics[blockIdx].loss_log[iter] = loss_3P(groundtruth, value);

            uint raw_map = pack_partition_indices_to_mask(value.partition_logits.data);
            uint closest_seed = get_closest_seed(raw_map);
            uint final_mask = LUT3_LOOKUP[closest_seed];

            g_diagnostics[blockIdx].partition_hamming_error_log[iter] = hamming_distance_2b(raw_map, final_mask);
            g_diagnostics[blockIdx].ideal_partition_log[iter] = raw_map;
        }
    }

    g_diagnostics[blockIdx].optim_ended_clock = getRealtimeClock();
    g_compressedBlock3P[blockIdx] = value;
    g_reconstructed[blockIdx] = reconstruct(value, blockIdx);
    g_diagnostics[blockIdx].partition_hamming_error = hamming_distance_2b(value.ideal_partition_map, value.astc_partition_map);
    g_final_loss[blockIdx] = loss_3P(groundtruth, value);
    g_diagnostics[blockIdx].finished_clock = getRealtimeClock();
}

[shader("compute")]
[numthreads(64, 1, 1)]
void get_loss_3P(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint blockIdx = dispatchThreadID.x;
    if (blockIdx >= g_compress_step_params[0].num_blocks) return;
    g_final_loss[blockIdx] = loss_3P(g_groundtruth[blockIdx], g_compressedBlock3P[blockIdx]);
}
