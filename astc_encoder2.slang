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
struct CompressedTextureBlock2P : IDifferentiable
{
    float3 ep0, ep1; // partition 1
    float3 ep2, ep3; // partition 2
    
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
};

// The image to encode (or to compute the loss of)
StructuredBuffer<TextureBlock> g_groundtruth;

// The reconstructed image
RWStructuredBuffer<TextureBlock> g_reconstructed;

// Diagnostics for this run
RWStructuredBuffer<Diagnostics> g_diagnostics;

// The ASTC/BC compressed block parameters for the 2-partition problem (ep0,ep1,ep2,ep3, 16x weights, 16x partition logits)
RWStructuredBuffer<CompressedTextureBlock2P> g_compressedBlock2P;

// The loss of the encoded block
RWStructuredBuffer<float> g_final_loss;

// The learning rate and # of steps to take
RWStructuredBuffer<CompressStepParams> g_compress_step_params;

// ASTC 2-partition LUT to snap a partition map to a valid astc partition seed
StructuredBuffer<uint> g_lut_ideal_to_seed;  // 65536-entry (256KB)
StructuredBuffer<uint> g_lut_seed_to_mask;   // 1024-entry (4KB)

// Check if a color is closer to the first line (ep1-ep0) or the second
bool is_partition_1(float3 x, float3 ep0, float3 ep1, float3 ep2, float3 ep3)
{
    float3 d1 = ep1 - ep0;
    float3 d2 = ep3 - ep2;

    float3 r1 = x - ep0;
    float3 r2 = x - ep2;

    float lenSqD1 = dot(d1, d1);
    float lenSqD2 = dot(d2, d2);

    float3 c1 = cross(r1, d1);
    float3 c2 = cross(r2, d2);

    float areaSq1 = dot(c1, c1);
    float areaSq2 = dot(c2, c2);

    return (areaSq1 * lenSqD2) < (areaSq2 * lenSqD1);
}

// Snap the partition map within a 2P block into a valid astc partition seed
void snap(inout CompressedTextureBlock2P block)
{
    uint raw_map = pack_partition_indices_to_mask(block.partition_logits.data);
    uint closest_seed = g_lut_ideal_to_seed[raw_map];
    uint final_mask = g_lut_seed_to_mask[closest_seed];

    block.astc_seed = closest_seed;
    block.astc_partition_map = final_mask;
    block.ideal_partition_map = raw_map;

    // Snap our partition logits into the final mask
    for (int i = 0; i < 16; i++)
    {
        float logit = abs(block.partition_logits[i]);
        if (((final_mask >> i) & 1) == 0) logit = -logit;
        block.partition_logits[i] = logit;
    }
}

// Cheap 1-step update to find the optimal weights that best fits ep0/ep1, ep2/ep3 to groundtruth
// This is a shortcut to avoid n steps of descent on weight, and avoid computing weight derivatives
void one_step_opt(inout CompressedTextureBlock2P block, TextureBlock groundtruth, bool should_snap) {
    float3 D1 = block.ep1 - block.ep0;
    float3 D2 = block.ep3 - block.ep2;
    for (int i = 0; i < 16; i++)
    {
        bool p1 = is_partition_1(groundtruth.pixels[i], block.ep0, block.ep1, block.ep2, block.ep3);
        if (p1) {
            block.partition_logits[i] = -0.5;
        } else {
            block.partition_logits[i] = 0.5;
        }
        if (should_snap) {
            snap(block);
            p1 = block.partition_logits[i] <= 0;
        }

        float3 C = groundtruth.pixels[i];
        float3 P = C - (p1 ? block.ep0 : block.ep2);
        float3 D = p1 ? D1 : D2;
        
        float w = dot(P, D) / (dot(D, D) + 1e-6f); // Add epsilon for safety
        block.weights[i] = saturate(w);
    }
}

// Transform the partition_logits to a uint16 partition map (index into the astc partition LUT)
uint pack_partition_indices_to_mask(float p_logits[16])
{
    uint raw_map = 0;
    for (int i = 0; i < 16; i++)
    {
        if (p_logits[i] > 0)
        {
            raw_map |= (1 << i);
        }
    }
    return raw_map;
}

// Used to evaluate the # of incorrect partitions when we snap a block to a valid astc partition seed
int hamming_distance(uint n1, uint n2)
{
    int x = n1 ^ n2;
    int output = 0;

    while (x > 0) {
        output += x & 1;
        x >>= 1;
    }

    return output;
}

[Differentiable]
TextureBlock decompress2P(CompressedTextureBlock2P blockCoefficients)
{
    float3 ep0 = blockCoefficients.ep0;
    float3 ep1 = blockCoefficients.ep1;
    float3 ep2 = blockCoefficients.ep2;
    float3 ep3 = blockCoefficients.ep3;

    TextureBlock outputBlock;
    for (int i = 0; i < 16; i++)
    {
        float w = detach(blockCoefficients.weights[i]);
        bool p1 = detach(blockCoefficients.partition_logits[i]) <= 0;
        float3 e0 = p1 ? ep0 : ep2;
        float3 e1 = p1 ? ep1 : ep3;
        outputBlock.pixels[i] = lerp(e0, e1, w);
    }
    return outputBlock;
}

[Differentiable]
float loss_2P(
    no_diff TextureBlock groundtruth, // frozen
    CompressedTextureBlock2P compressed)
{
    TextureBlock reconstructed = decompress2P(compressed);
    float totalError = 0.0f;
    
    for (int i = 0; i < 16; i++)
    {
        float3 diff = reconstructed.pixels[i] - groundtruth.pixels[i];
        totalError += dot(diff, diff); // L2 error
    }
    
    return totalError;
}

// [require(spvShaderClockKHR)]
[shader("compute")]
[numthreads(64, 1, 1)]
void compress_2P_step(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint blockIdx = dispatchThreadID.x;
    if (blockIdx >= g_compress_step_params[0].num_blocks) return;
    g_diagnostics[blockIdx].start_clock = getRealtimeClock();

    CompressedTextureBlock2P value = g_compressedBlock2P[blockIdx];
    TextureBlock groundtruth = g_groundtruth[blockIdx];
    float lr = g_compress_step_params[0].learning_rate;
    uint steps = g_compress_step_params[0].steps;
    uint first_snap_step = uint(steps * 9 / 10);
    uint checkpoint = max(1, steps / 20);
    int step;

    for (step = 0; step < int(steps); step++)
    {
        DifferentialPair<CompressedTextureBlock2P> cb_pair = diffPair(value);
        bwd_diff(loss_2P)(groundtruth, cb_pair, 1.0f);
        CompressedTextureBlock2P.Differential gradient = cb_pair.d;

        value.ep0 = value.ep0 - gradient.ep0 * lr;
        value.ep1 = value.ep1 - gradient.ep1 * lr;
        value.ep2 = value.ep2 - gradient.ep2 * lr;
        value.ep3 = value.ep3 - gradient.ep3 * lr;
        one_step_opt(value, groundtruth, step > first_snap_step || step >= steps - 1);

        if (step % checkpoint == 0) {
            uint iter = step / checkpoint;
            g_diagnostics[blockIdx].timestamps[iter] = getRealtimeClock();
            g_diagnostics[blockIdx].loss_log[iter] = loss_2P(groundtruth, value);

            uint raw_map = pack_partition_indices_to_mask(value.partition_logits.data);
            uint closest_seed = g_lut_ideal_to_seed[raw_map];
            uint final_mask = g_lut_seed_to_mask[closest_seed];

            g_diagnostics[blockIdx].partition_hamming_error_log[iter] = hamming_distance(raw_map, final_mask);
            g_diagnostics[blockIdx].ideal_partition_log[iter] = raw_map;
        }
    }

    g_diagnostics[blockIdx].optim_ended_clock = getRealtimeClock();
    g_compressedBlock2P[blockIdx] = value;
    g_reconstructed[blockIdx] = decompress2P(value);
    g_diagnostics[blockIdx].partition_hamming_error = hamming_distance(value.ideal_partition_map, value.astc_partition_map);
    g_final_loss[blockIdx] = loss_2P(groundtruth, value);
    g_diagnostics[blockIdx].finished_clock = getRealtimeClock();
}

[shader("compute")]
[numthreads(64, 1, 1)]
void get_loss_2P(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint blockIdx = dispatchThreadID.x;
    if (blockIdx >= g_compress_step_params[0].num_blocks) return;
    g_final_loss[blockIdx] = loss_2P(g_groundtruth[blockIdx], g_compressedBlock2P[blockIdx]);
}
