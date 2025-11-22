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
};

// Frozen weights (to avoid generating expensive derivatives in the bkw pass)
struct NonDifferentiableWeights {
    float weights[16];
    __subscript(int n) -> float
    {
        get { return weights[n]; }
        set { weights[n] = newValue; }
    }
}

// The ASTC/BC encoder problem (single-partition) is to solve for:
// 1. a pair of color endpoints (ep0, ep1)
// 2. a set of 16 interpolation weights
// so that the final image is lerp(ep0, ep1, weights) : TextureBlock
struct CompressedTextureBlock : IDifferentiable
{
    float3 ep0, ep1;
    no_diff NonDifferentiableWeights weights; // we don't have to gradient descent on this since we can do a full solve
};

// This represents the 2-partition compressed parameters.
struct CompressedTextureBlock2P : IDifferentiable
{
    float3 ep0, ep1; // partition 1
    float3 ep2, ep3; // partition 2
    
    no_diff NonDifferentiableWeights weights; // we don't have to gradient descent on this since we can do a full solve
    
    // TODO: freeze these after N snaps (this is equivalent to coordinated descent)
    float partition_logits[16]; // Partition blend logits
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

// The ASTC/BC compressed block parameters (ep0, ep1, 16x weights)
RWStructuredBuffer<CompressedTextureBlock> g_compressedBlock;

// The ASTC/BC compressed block parameters for the 2-partition problem (ep0,ep1,ep2,ep3, 16x weights, 16x partition logits)
RWStructuredBuffer<CompressedTextureBlock2P> g_compressedBlock2P;

// The loss of the encoded block
RWStructuredBuffer<float> g_final_loss;

// The learning rate and # of steps to take
RWStructuredBuffer<CompressStepParams> g_compress_step_params;

// ASTC 2-partition LUT to snap a partition map to a valid astc partition seed
StructuredBuffer<uint> g_lut_ideal_to_seed;  // 65536-entry (256KB)
StructuredBuffer<uint> g_lut_seed_to_mask;   // 1024-entry (4KB)

// Cheap 1-step update to find the optimal weights that best fits ep0/ep1 to groundtruth
// This is a shortcut to avoid n steps of descent on weight, and avoid computing weight derivatives
void optim_weights(inout CompressedTextureBlock block, TextureBlock groundtruth) {
    float3 D = block.ep1 - block.ep0;
    for (int i = 0; i < 16; i++)
    {
        float3 C = groundtruth.pixels[i];
        
        // w = dot(C - E_start, E_end - E_start) / dot(E_end - E_start, E_end - E_start)
        float3 P = C - block.ep0;
        float w = dot(P, D) / (dot(D, D) + 1e-6f); // Add epsilon for safety
        
        block.weights[i] = saturate(w);
    }
}

// Cheap 1-step update to find the optimal weights that best fits ep0/ep1, ep2/ep3 to groundtruth
// This is a shortcut to avoid n steps of descent on weight, and avoid computing weight derivatives
void optim_weights_2P(inout CompressedTextureBlock2P block, TextureBlock groundtruth) {
    float3 D1 = block.ep1 - block.ep0;
    float3 D2 = block.ep3 - block.ep2;
    for (int i = 0; i < 16; i++)
    {
        float3 C = groundtruth.pixels[i];
        float3 P = C - block.ep0;
        float3 D = D1;
        
        // w = dot(C - E_start, E_end - E_start) / dot(E_end - E_start, E_end - E_start)
        if (block.partition_logits[i] > 0.0) // partition 2
        {
            P = C - block.ep2;
            D = D2;
        }

        float w = dot(P, D2) / (dot(D2, D2) + 1e-6f); // Add epsilon for safety
        block.weights[i] = saturate(w);
    }
}

// Transform the partition_logits to a uint16 partition map (index into the astc partition LUT)
uint pack_logits_to_mask(float p_logits[16])
{
    uint raw_map = 0;
    for (int i = 0; i < 16; i++)
    {
        if (p_logits[i] > 0.0)
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

// Snap the partition map within a 2P block into a valid astc partition seed
void snap(inout CompressedTextureBlock2P block, float snap_strength)
{
    uint raw_map = pack_logits_to_mask(block.partition_logits);
    uint closest_seed = g_lut_ideal_to_seed[raw_map];
    uint final_mask = g_lut_seed_to_mask[closest_seed];

    block.astc_seed = closest_seed;
    block.astc_partition_map = final_mask;
    block.ideal_partition_map = raw_map;

    // Snap our partition logits into the final mask
    for (int i = 0; i < 16; i++)
    {
        float logit = clamp(snap_strength * abs(block.partition_logits[i]), 0, 1);
        if (((final_mask >> i) & 1) == 0) logit = -logit;
        block.partition_logits[i] = logit;
    }
}

[Differentiable]
float sigmoid(float x)
{
    return 1.0 / (1.0 + exp(-x));
}

// The "fake" derivative of the straight-through estimator of round()
// which pretends that it's a linear (y=x) passthrough
void round_bwd(inout DifferentialPair<float> x, float d_out)
{
    // Pretend round() is the identity y=x for the STE
    // dLoss/dx = dLoss/d_out * (d_out / dx) = d_out * 1.0
    x = diffPair(x.p, d_out);
}

[BackwardDerivative(round_bwd)]
float round_ste(float x)
{
    return round(x);
}

// This function takes the compressed parameters and reconstructs
// the 16-pixel block by lerping the weights over the endpoint colors
[Differentiable]
TextureBlock decompress(CompressedTextureBlock blockCoefficients)
{
    TextureBlock outputBlock;
    float3 ep0 = blockCoefficients.ep0;
    float3 ep1 = blockCoefficients.ep1;
    for (int i = 0; i < 16; i++)
    {
        float w = blockCoefficients.weights[i];
        outputBlock.pixels[i] = lerp(ep0, ep1, w);
    }
    return outputBlock;
}

[Differentiable]
TextureBlock decompress2P(CompressedTextureBlock2P blockCoefficients)
{
    // Quantize colors
    float3 ep0 = (blockCoefficients.ep0);
    float3 ep1 = (blockCoefficients.ep1);
    float3 ep2 = (blockCoefficients.ep2);
    float3 ep3 = (blockCoefficients.ep3);

    TextureBlock outputBlock;
    for (int i = 0; i < 16; i++)
    {
        float w = saturate(blockCoefficients.weights[i]);
        float p_soft = sigmoid(blockCoefficients.partition_logits[i]);
        float p = round_ste(p_soft); // partition selector

        float3 color1 = lerp(ep0, ep1, w);
        float3 color2 = lerp(ep2, ep3, w);

        // Blend the two partition colors using the partition selector.
        outputBlock.pixels[i] = lerp(color1, color2, p);
    }
    return outputBlock;
}

// The L^2 norm of the error of the decoded texture from the current parameter vs the
// groundtruth. Blackbox optimizing this function will find the optimal parameters to
// encode the groundtruth image.
[Differentiable]
float loss(
    no_diff TextureBlock groundtruth, // frozen
    CompressedTextureBlock compressed)
{
    TextureBlock reconstructed = decompress(compressed);
    
    float totalError = 0.0f;
    
    for (int i = 0; i < 16; i++)
    {
        float3 diff = reconstructed.pixels[i] - groundtruth.pixels[i];
        totalError += dot(diff, diff); // L2 error
    }
    
    return totalError;
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
void compress_step(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint blockIdx = dispatchThreadID.x;
    if (blockIdx >= g_compress_step_params[0].num_blocks) return;
    g_diagnostics[blockIdx].start_clock = getRealtimeClock();

    CompressedTextureBlock value = g_compressedBlock[blockIdx];
    TextureBlock groundtruth = g_groundtruth[blockIdx];
    float lr = g_compress_step_params[0].learning_rate;
    uint steps = g_compress_step_params[0].steps;
    uint checkpoint = steps / 20;

    for (int step = 0; step < int(steps); step++)
    {
        DifferentialPair<CompressedTextureBlock> cb_pair = diffPair(value);
        bwd_diff(loss)(groundtruth, cb_pair, 1.0f);
        CompressedTextureBlock.Differential gradient = cb_pair.d;

        value.ep0 = clamp((value.ep0 - gradient.ep0 * lr), 0.0f, 1.0f);
        value.ep1 = clamp((value.ep1 - gradient.ep1 * lr), 0.0f, 1.0f);

        optim_weights(value, groundtruth);

        if (step % checkpoint == 0) {
            uint iter = step / checkpoint;
            g_diagnostics[blockIdx].timestamps[iter] = getRealtimeClock();
            g_diagnostics[blockIdx].loss_log[iter] = loss(groundtruth, value);
        }
    }

    g_diagnostics[blockIdx].optim_ended_clock = getRealtimeClock();
    g_compressedBlock[blockIdx] = value;
    g_reconstructed[blockIdx] = decompress(value);
    g_final_loss[blockIdx] = loss(groundtruth, value);
    g_diagnostics[blockIdx].finished_clock = getRealtimeClock();
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
    uint snap_steps = g_compress_step_params[0].snap_steps;
    uint first_snap_step = uint(steps) / 2;
    uint checkpoint = steps / 20;
    int step;

    for (step = 0; step < int(steps); step++)
    {
        DifferentialPair<CompressedTextureBlock2P> cb_pair = diffPair(value);
        bwd_diff(loss_2P)(groundtruth, cb_pair, 1.0f);
        CompressedTextureBlock2P.Differential gradient = cb_pair.d;

        value.ep0 = clamp(value.ep0 - gradient.ep0 * lr, 0.0f, 1.0f);
        value.ep1 = clamp(value.ep1 - gradient.ep1 * lr, 0.0f, 1.0f);
        value.ep2 = clamp(value.ep2 - gradient.ep2 * lr, 0.0f, 1.0f);
        value.ep3 = clamp(value.ep3 - gradient.ep3 * lr, 0.0f, 1.0f);
        for (int i = 0; i < 16; i++)
        {
            value.partition_logits[i] = (value.partition_logits[i] - gradient.partition_logits[i] * lr);
        }

        if (step > first_snap_step && step % snap_steps == 0) {
            snap(value, 1 + float(step - first_snap_step) / (snap_steps * 2));
        }
        
        optim_weights_2P(value, groundtruth);

        if (step % checkpoint == 0) {
            uint iter = step / checkpoint;
            g_diagnostics[blockIdx].timestamps[iter] = getRealtimeClock();
            g_diagnostics[blockIdx].loss_log[iter] = loss_2P(groundtruth, value);
        }
    }

    snap(value, 1 + float(step - first_snap_step) / (snap_steps * 2));
    optim_weights_2P(value, groundtruth);

    g_diagnostics[blockIdx].optim_ended_clock = getRealtimeClock();
    g_compressedBlock2P[blockIdx] = value;
    g_reconstructed[blockIdx] = decompress2P(value);
    g_diagnostics[blockIdx].partition_hamming_error = hamming_distance(value.ideal_partition_map, value.astc_partition_map);
    g_final_loss[blockIdx] = loss_2P(groundtruth, value);
    g_diagnostics[blockIdx].finished_clock = getRealtimeClock();
}

[shader("compute")]
[numthreads(64, 1, 1)]
void get_loss(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint blockIdx = dispatchThreadID.x;
    if (blockIdx >= g_compress_step_params[0].num_blocks) return;
    g_final_loss[blockIdx] = loss(g_groundtruth[blockIdx], g_compressedBlock[blockIdx]);
}

[shader("compute")]
[numthreads(64, 1, 1)]
void get_loss_2P(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint blockIdx = dispatchThreadID.x;
    if (blockIdx >= g_compress_step_params[0].num_blocks) return;
    g_final_loss[blockIdx] = loss_2P(g_groundtruth[blockIdx], g_compressedBlock2P[blockIdx]);
}
