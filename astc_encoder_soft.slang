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
    no_diff float3 ep0, ep1; // partition 1
    no_diff float3 ep2, ep3; // partition 2
    
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
    uint snap;
    uint max_partitions;
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

struct Means
{
    float3 mean;
    int count;
};

void calc_partition_means(
    TextureBlock groundtruth, 
    float partition_logits[16], 
    out Means s0, 
    out Means s1)
{
    float3 sum0 = float3(0.0);
    float3 sum1 = float3(0.0);
    s0.count = 0;
    s1.count = 0;

    [unroll]
    for (int i = 0; i < 16; i++)
    {
        float3 px = groundtruth.pixels[i];
        if (partition_logits[i] <= 0.0) { sum0 += px; s0.count++; }
        else                            { sum1 += px; s1.count++; }
    }

    s0.mean = s0.count > 0 ? sum0 / float(s0.count) : float3(0.0);
    s1.mean = s1.count > 0 ? sum1 / float(s1.count) : float3(0.0);
}

void calc_partition_covariances(
    TextureBlock groundtruth, 
    float partition_logits[16], 
    Means s0, 
    Means s1,
    out float3x3 cov0, 
    out float3x3 cov1)
{
    cov0 = float3x3(0.0);
    cov1 = float3x3(0.0);

    [unroll]
    for (int i = 0; i < 16; i++)
    {
        float3 px = groundtruth.pixels[i];
        if (partition_logits[i] <= 0.0)
        {
            float3 d = px - s0.mean;
            // Accumulate Outer Product: d * d^T
            cov0[0] += d * d.x; cov0[1] += d * d.y; cov0[2] += d * d.z;
        }
        else
        {
            float3 d = px - s1.mean;
            cov1[0] += d * d.x; cov1[1] += d * d.y; cov1[2] += d * d.z;
        }
    }
}

void calc_projection_bounds(
    TextureBlock groundtruth,
    float partition_logits[16],
    Means s0, Means s1,
    float3 axis0, float3 axis1,
    out float2 bounds0, // x=min, y=max
    out float2 bounds1)
{
    bounds0 = s0.count > 0 ? float2(1e9, -1e9) : float2(0, 0);
    bounds1 = s1.count > 0 ? float2(1e9, -1e9) : float2(0, 0);

    [unroll]
    for (int i = 0; i < 16; i++)
    {
        float3 px = groundtruth.pixels[i];
        if (partition_logits[i] <= 0.0)
        {
            float t = dot(px - s0.mean, axis0);
            bounds0.x = min(bounds0.x, t);
            bounds0.y = max(bounds0.y, t);
        }
        else
        {
            float t = dot(px - s1.mean, axis1);
            bounds1.x = min(bounds1.x, t);
            bounds1.y = max(bounds1.y, t);
        }
    }
}

// Standard Power Iteration to find the dominant eigenvector
float3 get_principal_axis(float3x3 covariance)
{
    float3 dir = float3(1.0, 1.0, 1.0);
    [unroll]
    for (int i = 0; i < 2; i++)
    {
        float3 next_dir = mul(covariance, dir);
        if (dot(next_dir, next_dir) < 1e-10)
        {
            return normalize(dir);
        }
        dir = normalize(next_dir);
    }
    return dir;
}

void get_partition_endpoints(inout CompressedTextureBlock2P block, TextureBlock groundtruth)
{
    Means s0, s1;
    calc_partition_means(groundtruth, block.partition_logits, s0, s1);

    float3x3 cov0, cov1;
    calc_partition_covariances(groundtruth, block.partition_logits, s0, s1, cov0, cov1);

    float3 axis0 = (s0.count > 1) ? get_principal_axis(cov0) : normalize(block.ep1 - block.ep0 + 1e-6);
    float3 axis1 = (s1.count > 1) ? get_principal_axis(cov1) : normalize(block.ep3 - block.ep2 + 1e-6);

    float2 bounds0, bounds1;
    calc_projection_bounds(groundtruth, block.partition_logits, s0, s1, axis0, axis1, bounds0, bounds1);

    if (s0.count > 0) {
        block.ep0 = s0.mean + axis0 * bounds0.x;
        block.ep1 = s0.mean + axis0 * bounds0.y;
    }
    if (s1.count > 0) {
        block.ep2 = s1.mean + axis1 * bounds1.x;
        block.ep3 = s1.mean + axis1 * bounds1.y;
    }
}

// Cheap 1-step update to find the optimal weights that best fits ep0/ep1, ep2/ep3 to groundtruth
// This is a shortcut to avoid n steps of descent on weight, and avoid computing weight derivatives
void optim_weights_2P(inout CompressedTextureBlock2P block, TextureBlock groundtruth) {
    get_partition_endpoints(block, groundtruth);
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

        float w = dot(P, D) / (dot(D, D) + 1e-6f); // Add epsilon for safety
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
        float logit = abs(block.partition_logits[i]);
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
    float3 ep0 = detach(blockCoefficients.ep0);
    float3 ep1 = detach(blockCoefficients.ep1);
    float3 ep2 = detach(blockCoefficients.ep2);
    float3 ep3 = detach(blockCoefficients.ep3);

    TextureBlock outputBlock;
    for (int i = 0; i < 16; i++)
    {
        float w = saturate(detach(blockCoefficients.weights[i]));
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
    float3x3 ycocg_proj = float3x3(
         0.25, 0.50,  0.25,
         0.50, 0.00, -0.50,
        -0.25, 0.50, -0.25
    );
    
    float totalError = 0.0f;
    
    for (int i = 0; i < 16; i++)
    {
        float3 diff = reconstructed.pixels[i] - groundtruth.pixels[i];
        // diff = mul(ycocg_proj, diff) * float3(1, 1.5, 1); // YCoCg
        totalError += dot(diff, diff); // L2 error
    }

    // Push colors away from each other
    // totalError -= dot(compressed.ep0 - compressed.ep2, compressed.ep0 - compressed.ep2);
    // totalError -= dot(compressed.ep1 - compressed.ep3, compressed.ep1 - compressed.ep3);
    // totalError -= dot(compressed.ep1 - compressed.ep2, compressed.ep1 - compressed.ep2);
    
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
    uint checkpoint = max(1, steps / 20);
    int step;

    for (step = 0; step < int(steps); step++)
    {
        DifferentialPair<CompressedTextureBlock2P> cb_pair = diffPair(value);
        bwd_diff(loss_2P)(groundtruth, cb_pair, 1.0f);
        CompressedTextureBlock2P.Differential gradient = cb_pair.d;

        for (int i = 0; i < 16; i++)
        {
            value.partition_logits[i] = (value.partition_logits[i] - gradient.partition_logits[i] * lr);
        }

        if (step > first_snap_step && step % snap_steps == 0) {
            // snap(value, 1 + float(step - first_snap_step) / (snap_steps * 2));
        }
        
        // snap(value, 1);
        optim_weights_2P(value, groundtruth);

        if (step % checkpoint == 0) {
            uint iter = step / checkpoint;
            g_diagnostics[blockIdx].timestamps[iter] = getRealtimeClock();
            g_diagnostics[blockIdx].loss_log[iter] = loss_2P(groundtruth, value);

            uint raw_map = pack_logits_to_mask(value.partition_logits);
            uint closest_seed = g_lut_ideal_to_seed[raw_map];
            uint final_mask = g_lut_seed_to_mask[closest_seed];

            // block.astc_seed = closest_seed;
            // block.astc_partition_map = final_mask;
            // block.ideal_partition_map = raw_map;
            g_diagnostics[blockIdx].partition_hamming_error_log[iter] = hamming_distance(raw_map, final_mask);
            g_diagnostics[blockIdx].ideal_partition_log[iter] = raw_map;
        }
    }

    // snap(value, 1 + float(step - first_snap_step) / (snap_steps * 2));
    snap(value, 1);
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
