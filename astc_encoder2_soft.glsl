#version 450
#extension GL_EXT_shader_realtime_clock : require
layout(row_major) uniform;
layout(row_major) buffer;

#line 49 0
struct CompressStepParams_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
    uint snap_0;
    uint max_partitions_0;
};


#line 75
layout(std430, binding = 5) buffer StructuredBuffer_CompressStepParams_t_0 {
    CompressStepParams_0 _data[];
} g_compress_step_params_0;

#line 14
struct Diagnostics_0
{
    uint partition_hamming_error_0;
    float  loss_log_0[20];
    uvec2 start_clock_0;
    uvec2 optim_ended_clock_0;
    uvec2 finished_clock_0;
    uvec2  timestamps_0[20];
    uint  partition_hamming_error_log_0[20];
    uint  ideal_partition_log_0[20];
};


#line 66
layout(std430, binding = 2) buffer StructuredBuffer_Diagnostics_t_0 {
    Diagnostics_0 _data[];
} g_diagnostics_0;

#line 27
struct NonDifferentiableWeights_0
{
    float  data_0[16];
};


#line 37
struct CompressedTextureBlock2P_0
{
    vec3 ep0_0;
    vec3 ep1_0;
    vec3 ep2_0;
    vec3 ep3_0;
    NonDifferentiableWeights_0 weights_0;
    NonDifferentiableWeights_0 partition_logits_0;
    uint astc_partition_map_0;
    uint ideal_partition_map_0;
    uint astc_seed_0;
};


#line 69
layout(std430, binding = 3) buffer StructuredBuffer_CompressedTextureBlock2P_t_0 {
    CompressedTextureBlock2P_0 _data[];
} g_compressedBlock2P_0;

#line 8
struct TextureBlock_0
{
    vec3  pixels_0[16];
};


#line 60
layout(std430, binding = 0) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;

#line 78
layout(std430, binding = 6) readonly buffer StructuredBuffer_uint_t_0 {
    uint _data[];
} g_lut_ideal_to_seed_0;
struct LUT_0
{
    uint  lut2_0[1024];
};


#line 85
layout(binding = 8)
layout(std140) uniform block_LUT_0
{
    uint  lut2_0[1024];
}g_lut_0;

#line 63
layout(std430, binding = 1) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;

#line 72
layout(std430, binding = 4) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 94
struct PCG32_0
{
    uint state_0;
};


#line 98
PCG32_0 PCG32_x24init_0(uint seed_0)
{

#line 98
    PCG32_0 _S1;

    uint _S2 = seed_0 * 747796405U + 2891336453U;
    uint _S3 = ((_S2 >> ((_S2 >> 28U) + 4U)) ^ _S2) * 277803737U;
    _S1.state_0 = (_S3 >> 22U) ^ _S3;

#line 98
    return _S1;
}


#line 113
uint PCG32_nextUint_0(inout PCG32_0 this_0)
{
    uint oldState_0 = this_0.state_0;
    this_0.state_0 = this_0.state_0 * 747796405U + 2891336453U;
    uint word_0 = ((oldState_0 >> ((oldState_0 >> 28U) + 4U)) ^ oldState_0) * 277803737U;
    return (word_0 >> 22U) ^ word_0;
}


#line 118
struct DiffPair_vectorx3Cfloatx2C3x3E_0
{
    vec3 primal_0;
    vec3 differential_0;
};


#line 1639 1
void _d_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpx_0, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpy_0, float dOut_0)
{
    vec3 x_d_result_0;



    x_d_result_0[0] = dpy_0.primal_0[0] * dOut_0;

#line 1641
    vec3 y_d_result_0;

#line 1646
    y_d_result_0[0] = dpx_0.primal_0[0] * dOut_0;

#line 1645
    x_d_result_0[1] = dpy_0.primal_0[1] * dOut_0;
    y_d_result_0[1] = dpx_0.primal_0[1] * dOut_0;

#line 1645
    x_d_result_0[2] = dpy_0.primal_0[2] * dOut_0;
    y_d_result_0[2] = dpx_0.primal_0[2] * dOut_0;

#line 1646
    dpx_0.primal_0 = dpx_0.primal_0;

#line 1646
    dpx_0.differential_0 = x_d_result_0;

#line 1646
    dpy_0.primal_0 = dpy_0.primal_0;

#line 1646
    dpy_0.differential_0 = y_d_result_0;



    return;
}


#line 311 0
float dist_0(vec3 x_0, vec3 ep0_1, vec3 ep1_1)
{
    vec3 lineDir_0 = ep1_1 - ep0_1;

    return length(cross(x_0 - ep0_1, lineDir_0)) / length(lineDir_0);
}


#line 37
struct CompressedTextureBlock2P_Differential_0
{
    vec3 ep0_2;
    vec3 ep1_2;
    vec3 ep2_1;
    vec3 ep3_1;
};


#line 37
CompressedTextureBlock2P_Differential_0 CompressedTextureBlock2P_x24_syn_dzero_0()
{

#line 37
    CompressedTextureBlock2P_Differential_0 result_0;

#line 2239 2
    vec3 _S4 = vec3(0.0);

#line 2239
    result_0.ep0_2 = _S4;

#line 2239
    result_0.ep1_2 = _S4;

#line 2239
    result_0.ep2_1 = _S4;

#line 2239
    result_0.ep3_1 = _S4;

#line 2239
    return result_0;
}


#line 31 0
float NonDifferentiableWeights_operatorx5Bx5D_get_0(NonDifferentiableWeights_0 this_1, int n_0)
{

#line 31
    return this_1.data_0[n_0];
}


#line 31
struct DiffPair_float_0
{
    float primal_0;
    float differential_0;
};


#line 2263 1
void _d_lerp_0(inout DiffPair_float_0 dpx_1, inout DiffPair_float_0 dpy_1, inout DiffPair_float_0 dps_0, float dOut_1)
{

#line 2263
    float _S5 = (1.0 - dps_0.primal_0) * dOut_1;

#line 2263
    dpx_1.primal_0 = dpx_1.primal_0;

#line 2263
    dpx_1.differential_0 = _S5;


    DiffPair_float_0 _S6 = dpy_1;

#line 2266
    float _S7 = dps_0.primal_0 * dOut_1;

#line 2266
    dpy_1.primal_0 = dpy_1.primal_0;

#line 2266
    dpy_1.differential_0 = _S7;

#line 2266
    float _S8 = (_S6.primal_0 - dpx_1.primal_0) * dOut_1;

#line 2266
    dps_0.primal_0 = _S6.primal_0;

#line 2266
    dps_0.differential_0 = _S8;

    return;
}


#line 1 3
void _d_lerp_vector_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpx_2, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpy_2, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpz_0, vec3 dOut_2)
{

#line 1841 1
    DiffPair_float_0 left_dp_0;

#line 1841
    left_dp_0.primal_0 = dpx_2.primal_0[0];

#line 1841
    left_dp_0.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_0;

#line 1842
    middle_dp_0.primal_0 = dpy_2.primal_0[0];

#line 1842
    middle_dp_0.differential_0 = 0.0;
    DiffPair_float_0 right_dp_0;

#line 1843
    right_dp_0.primal_0 = dpz_0.primal_0[0];

#line 1843
    right_dp_0.differential_0 = 0.0;
    _d_lerp_0(left_dp_0, middle_dp_0, right_dp_0, dOut_2[0]);

#line 1838
    vec3 left_d_result_0;

#line 1846
    left_d_result_0[0] = left_dp_0.differential_0;

#line 1838
    vec3 middle_d_result_0;

#line 1847
    middle_d_result_0[0] = middle_dp_0.differential_0;

#line 1838
    vec3 right_d_result_0;

#line 1848
    right_d_result_0[0] = right_dp_0.differential_0;

#line 1841
    DiffPair_float_0 left_dp_1;

#line 1841
    left_dp_1.primal_0 = dpx_2.primal_0[1];

#line 1841
    left_dp_1.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_1;

#line 1842
    middle_dp_1.primal_0 = dpy_2.primal_0[1];

#line 1842
    middle_dp_1.differential_0 = 0.0;
    DiffPair_float_0 right_dp_1;

#line 1843
    right_dp_1.primal_0 = dpz_0.primal_0[1];

#line 1843
    right_dp_1.differential_0 = 0.0;
    _d_lerp_0(left_dp_1, middle_dp_1, right_dp_1, dOut_2[1]);

    left_d_result_0[1] = left_dp_1.differential_0;
    middle_d_result_0[1] = middle_dp_1.differential_0;
    right_d_result_0[1] = right_dp_1.differential_0;

#line 1841
    DiffPair_float_0 left_dp_2;

#line 1841
    left_dp_2.primal_0 = dpx_2.primal_0[2];

#line 1841
    left_dp_2.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_2;

#line 1842
    middle_dp_2.primal_0 = dpy_2.primal_0[2];

#line 1842
    middle_dp_2.differential_0 = 0.0;
    DiffPair_float_0 right_dp_2;

#line 1843
    right_dp_2.primal_0 = dpz_0.primal_0[2];

#line 1843
    right_dp_2.differential_0 = 0.0;
    _d_lerp_0(left_dp_2, middle_dp_2, right_dp_2, dOut_2[2]);

    left_d_result_0[2] = left_dp_2.differential_0;
    middle_d_result_0[2] = middle_dp_2.differential_0;
    right_d_result_0[2] = right_dp_2.differential_0;

#line 1848
    dpx_2.primal_0 = dpx_2.primal_0;

#line 1848
    dpx_2.differential_0 = left_d_result_0;

#line 1848
    dpy_2.primal_0 = dpy_2.primal_0;

#line 1848
    dpy_2.differential_0 = middle_d_result_0;

#line 1848
    dpz_0.primal_0 = dpz_0.primal_0;

#line 1848
    dpz_0.differential_0 = right_d_result_0;

#line 1853
    return;
}


#line 275 0
TextureBlock_0 decompress2P_0(CompressedTextureBlock2P_0 blockCoefficients_0)
{

#line 282
    TextureBlock_0 outputBlock_0;

#line 282
    int i_0 = 0;
    for(;;)
    {

#line 283
        if(i_0 < 16)
        {
        }
        else
        {

#line 283
            break;
        }
        float _S9 = NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_0.weights_0, i_0);
        bool p1_0 = (NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_0.partition_logits_0, i_0)) <= 0.0;

#line 286
        vec3 e0_0;
        if(p1_0)
        {

#line 287
            e0_0 = blockCoefficients_0.ep0_0;

#line 287
        }
        else
        {

#line 287
            e0_0 = blockCoefficients_0.ep2_0;

#line 287
        }

#line 287
        vec3 e1_0;
        if(p1_0)
        {

#line 288
            e1_0 = blockCoefficients_0.ep1_0;

#line 288
        }
        else
        {

#line 288
            e1_0 = blockCoefficients_0.ep3_0;

#line 288
        }
        outputBlock_0.pixels_0[i_0] = mix(e0_0, e1_0, vec3(_S9));

#line 283
        i_0 = i_0 + 1;

#line 283
    }

#line 291
    return outputBlock_0;
}


#line 123
bool is_partition_1_0(vec3 x_1, vec3 ep0_3, vec3 ep1_3, vec3 ep2_2, vec3 ep3_2)
{
    vec3 d1_0 = ep1_3 - ep0_3;
    vec3 d2_0 = ep3_2 - ep2_2;

#line 134
    vec3 c1_0 = cross(x_1 - ep0_3, d1_0);
    vec3 c2_0 = cross(x_1 - ep2_2, d2_0);

#line 140
    return (dot(c1_0, c1_0) * dot(d2_0, d2_0)) < (dot(c2_0, c2_0) * dot(d1_0, d1_0));
}


#line 261
uint pack_partition_indices_to_mask_0(float  p_logits_0[16])
{

#line 261
    int i_1 = 0;

#line 261
    uint raw_map_0 = 0U;


    for(;;)
    {

#line 264
        if(i_1 < 16)
        {
        }
        else
        {

#line 264
            break;
        }
        if((p_logits_0[i_1]) > 0.0)
        {

#line 266
            raw_map_0 = raw_map_0 | uint(1 << i_1);

#line 266
        }

#line 264
        i_1 = i_1 + 1;

#line 264
    }

#line 271
    return raw_map_0;
}


#line 179
uint get_closest_seed_0(uint input_0)
{

#line 196
    return g_lut_ideal_to_seed_0._data[uint(input_0)];
}


#line 143
uint get_mask_0(uint seed_mask_0)
{

#line 143
    int i_2 = 0;

#line 143
    uint result_1 = 0U;



    for(;;)
    {

#line 147
        if(i_2 < 16)
        {
        }
        else
        {

#line 147
            break;
        }
        if(((seed_mask_0 >> (2 * i_2)) & 3U) == 1U)
        {

#line 149
            result_1 = result_1 | uint(1 << i_2);

#line 149
        }

#line 147
        i_2 = i_2 + 1;

#line 147
    }



    return result_1;
}


#line 206
void snap_1(inout CompressedTextureBlock2P_0 block_0)
{
    uint raw_map_1 = pack_partition_indices_to_mask_0(block_0.partition_logits_0.data_0);
    uint closest_seed_0 = get_closest_seed_0(raw_map_1);
    uint final_mask_0 = g_lut_0.lut2_0[closest_seed_0];

    block_0.astc_seed_0 = closest_seed_0;
    block_0.astc_partition_map_0 = get_mask_0(final_mask_0);
    block_0.ideal_partition_map_0 = raw_map_1;

#line 214
    int i_3 = 0;


    for(;;)
    {

#line 217
        if(i_3 < 16)
        {
        }
        else
        {

#line 217
            break;
        }
        float logit_0 = abs(NonDifferentiableWeights_operatorx5Bx5D_get_0(block_0.partition_logits_0, i_3));

#line 219
        float logit_1;
        if(((final_mask_0 >> (2 * i_3)) & 3U) == 0U)
        {

#line 220
            logit_1 = - logit_0;

#line 220
        }
        else
        {

#line 220
            logit_1 = logit_0;

#line 220
        }
        block_0.partition_logits_0.data_0[i_3] = logit_1;

#line 217
        i_3 = i_3 + 1;

#line 217
    }

#line 223
    return;
}


#line 13393 4
float saturate_0(float x_2)
{

#line 13401
    return clamp(x_2, 0.0, 1.0);
}


#line 166 0
uint hamming_distance_0(uint x_3, uint y_0)
{
    return bitCount(x_3 ^ y_0);
}


#line 318
TextureBlock_0 reconstruct_0(CompressedTextureBlock2P_0 blockCoefficients_1, uint blockIdx_0)
{
    TextureBlock_0 outputBlock_1;

#line 320
    int i_4 = 0;

#line 336
    for(;;)
    {

#line 336
        if(i_4 < 16)
        {
        }
        else
        {

#line 336
            break;
        }
        float w_0 = NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_1.weights_0, i_4);
        bool p1_1 = (NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_1.partition_logits_0, i_4)) <= 0.0;

#line 339
        vec3 e0_1;
        if(p1_1)
        {

#line 340
            e0_1 = blockCoefficients_1.ep0_0;

#line 340
        }
        else
        {

#line 340
            e0_1 = blockCoefficients_1.ep2_0;

#line 340
        }

#line 340
        vec3 e1_1;
        if(p1_1)
        {

#line 341
            e1_1 = blockCoefficients_1.ep1_0;

#line 341
        }
        else
        {

#line 341
            e1_1 = blockCoefficients_1.ep3_0;

#line 341
        }
        outputBlock_1.pixels_0[i_4] = mix(e0_1, e1_1, vec3(w_0));

#line 336
        i_4 = i_4 + 1;

#line 336
    }

#line 346
    return outputBlock_1;
}


#line 353
struct DiffPair_CompressedTextureBlock2P_0
{
    CompressedTextureBlock2P_0 primal_0;
    CompressedTextureBlock2P_Differential_0 differential_0;
};


#line 402
vec3 s_primal_ctx_lerp_0(vec3 _S10, vec3 _S11, vec3 _S12)
{

#line 402
    return mix(_S10, _S11, _S12);
}


#line 402
TextureBlock_0 s_primal_ctx_decompress2P_0(CompressedTextureBlock2P_0 dpblockCoefficients_0)
{

#line 282
    vec3 _S13 = vec3(0.0);

#line 282
    vec3  _S14[16] = { _S13, _S13, _S13, _S13, _S13, _S13, _S13, _S13, _S13, _S13, _S13, _S13, _S13, _S13, _S13, _S13 };

#line 282
    bool _runFlag_0 = true;

#line 282
    int i_5 = 0;

#line 282
    TextureBlock_0 outputBlock_2;

#line 282
    outputBlock_2.pixels_0 = _S14;

#line 282
    int _pc_0 = 0;
    for(;;)
    {

#line 283
        if(_runFlag_0)
        {
        }
        else
        {

#line 283
            break;
        }

#line 283
        int _S15;

#line 283
        if(i_5 < 16)
        {
            float _S16 = NonDifferentiableWeights_operatorx5Bx5D_get_0(dpblockCoefficients_0.weights_0, i_5);
            bool p1_2 = (NonDifferentiableWeights_operatorx5Bx5D_get_0(dpblockCoefficients_0.partition_logits_0, i_5)) <= 0.0;

#line 286
            vec3 e0_2;
            if(p1_2)
            {

#line 287
                e0_2 = dpblockCoefficients_0.ep0_0;

#line 287
            }
            else
            {

#line 287
                e0_2 = dpblockCoefficients_0.ep2_0;

#line 287
            }

#line 287
            vec3 e1_2;
            if(p1_2)
            {

#line 288
                e1_2 = dpblockCoefficients_0.ep1_0;

#line 288
            }
            else
            {

#line 288
                e1_2 = dpblockCoefficients_0.ep3_0;

#line 288
            }

#line 288
            vec3 _S17 = s_primal_ctx_lerp_0(e0_2, e1_2, vec3(_S16));

#line 288
            TextureBlock_0 _S18 = outputBlock_2;

#line 288
            _S18.pixels_0[i_5] = _S17;

#line 288
            _S15 = 1;

#line 288
            outputBlock_2 = _S18;

#line 288
        }
        else
        {

#line 288
            _S15 = 0;

#line 288
        }

#line 288
        if(_S15 != 1)
        {

#line 288
            _runFlag_0 = false;

#line 288
        }

#line 288
        if(_runFlag_0)
        {

#line 288
            i_5 = i_5 + 1;

#line 288
        }

#line 288
        _pc_0 = _pc_0 + 1;

#line 283
    }

#line 283
    return outputBlock_2;
}


#line 283
TextureBlock_0 TextureBlock_x24_syn_dzero_0()
{

#line 283
    TextureBlock_0 result_2;

#line 2239 2
    vec3 _S19 = vec3(0.0);

#line 2239
    result_2.pixels_0[0] = _S19;

#line 2239
    result_2.pixels_0[1] = _S19;

#line 2239
    result_2.pixels_0[2] = _S19;

#line 2239
    result_2.pixels_0[3] = _S19;

#line 2239
    result_2.pixels_0[4] = _S19;

#line 2239
    result_2.pixels_0[5] = _S19;

#line 2239
    result_2.pixels_0[6] = _S19;

#line 2239
    result_2.pixels_0[7] = _S19;

#line 2239
    result_2.pixels_0[8] = _S19;

#line 2239
    result_2.pixels_0[9] = _S19;

#line 2239
    result_2.pixels_0[10] = _S19;

#line 2239
    result_2.pixels_0[11] = _S19;

#line 2239
    result_2.pixels_0[12] = _S19;

#line 2239
    result_2.pixels_0[13] = _S19;

#line 2239
    result_2.pixels_0[14] = _S19;

#line 2239
    result_2.pixels_0[15] = _S19;

#line 2239
    return result_2;
}


#line 2239
TextureBlock_0 TextureBlock_x24_syn_dadd_0(TextureBlock_0 SLANG_anonymous_0_0, TextureBlock_0 SLANG_anonymous_1_0)
{

#line 2239
    TextureBlock_0 result_3;

#line 2239
    result_3.pixels_0[0] = SLANG_anonymous_0_0.pixels_0[0] + SLANG_anonymous_1_0.pixels_0[0];

#line 2239
    result_3.pixels_0[1] = SLANG_anonymous_0_0.pixels_0[1] + SLANG_anonymous_1_0.pixels_0[1];

#line 2239
    result_3.pixels_0[2] = SLANG_anonymous_0_0.pixels_0[2] + SLANG_anonymous_1_0.pixels_0[2];

#line 2239
    result_3.pixels_0[3] = SLANG_anonymous_0_0.pixels_0[3] + SLANG_anonymous_1_0.pixels_0[3];

#line 2239
    result_3.pixels_0[4] = SLANG_anonymous_0_0.pixels_0[4] + SLANG_anonymous_1_0.pixels_0[4];

#line 2239
    result_3.pixels_0[5] = SLANG_anonymous_0_0.pixels_0[5] + SLANG_anonymous_1_0.pixels_0[5];

#line 2239
    result_3.pixels_0[6] = SLANG_anonymous_0_0.pixels_0[6] + SLANG_anonymous_1_0.pixels_0[6];

#line 2239
    result_3.pixels_0[7] = SLANG_anonymous_0_0.pixels_0[7] + SLANG_anonymous_1_0.pixels_0[7];

#line 2239
    result_3.pixels_0[8] = SLANG_anonymous_0_0.pixels_0[8] + SLANG_anonymous_1_0.pixels_0[8];

#line 2239
    result_3.pixels_0[9] = SLANG_anonymous_0_0.pixels_0[9] + SLANG_anonymous_1_0.pixels_0[9];

#line 2239
    result_3.pixels_0[10] = SLANG_anonymous_0_0.pixels_0[10] + SLANG_anonymous_1_0.pixels_0[10];

#line 2239
    result_3.pixels_0[11] = SLANG_anonymous_0_0.pixels_0[11] + SLANG_anonymous_1_0.pixels_0[11];

#line 2239
    result_3.pixels_0[12] = SLANG_anonymous_0_0.pixels_0[12] + SLANG_anonymous_1_0.pixels_0[12];

#line 2239
    result_3.pixels_0[13] = SLANG_anonymous_0_0.pixels_0[13] + SLANG_anonymous_1_0.pixels_0[13];

#line 2239
    result_3.pixels_0[14] = SLANG_anonymous_0_0.pixels_0[14] + SLANG_anonymous_1_0.pixels_0[14];

#line 2239
    result_3.pixels_0[15] = SLANG_anonymous_0_0.pixels_0[15] + SLANG_anonymous_1_0.pixels_0[15];

#line 2239
    return result_3;
}


#line 2239
void s_bwd_prop_lerp_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S20, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S21, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S22, vec3 _S23)
{

#line 2239
    _d_lerp_vector_0(_S20, _S21, _S22, _S23);

#line 2239
    return;
}


#line 275 0
void s_bwd_prop_decompress2P_0(inout DiffPair_CompressedTextureBlock2P_0 dpblockCoefficients_1, TextureBlock_0 _s_dOut_0)
{

#line 275
    vec3 _S24 = dpblockCoefficients_1.primal_0.ep0_0;

#line 275
    vec3 _S25 = dpblockCoefficients_1.primal_0.ep1_0;

#line 275
    vec3 _S26 = dpblockCoefficients_1.primal_0.ep2_0;

#line 275
    vec3 _S27 = dpblockCoefficients_1.primal_0.ep3_0;

#line 275
    NonDifferentiableWeights_0 _S28 = dpblockCoefficients_1.primal_0.weights_0;

#line 275
    NonDifferentiableWeights_0 _S29 = dpblockCoefficients_1.primal_0.partition_logits_0;

#line 2239 2
    vec3 _S30 = vec3(0.0);

#line 282 0
    TextureBlock_0 _S31 = TextureBlock_x24_syn_dzero_0();

#line 282
    TextureBlock_0 _S32 = TextureBlock_x24_syn_dadd_0(_s_dOut_0, _S31);

#line 282
    int _dc_0 = 16;

#line 282
    TextureBlock_0 _S33 = _S32;

#line 282
    vec3 _S34 = _S30;

#line 282
    vec3 _S35 = _S30;

#line 282
    vec3 _S36 = _S30;

#line 282
    vec3 _S37 = _S30;

#line 282
    vec3 _S38 = _S30;
    for(;;)
    {

#line 283
        if(_dc_0 >= 0)
        {
        }
        else
        {

#line 283
            break;
        }

#line 283
        bool _S39 = _dc_0 < 16;

#line 283
        vec3 e0_3;

#line 283
        vec3 e1_3;

#line 283
        vec3 _S40;

#line 283
        bool _S41;

#line 283
        if(_S39)
        {
            float _S42 = NonDifferentiableWeights_operatorx5Bx5D_get_0(_S28, _dc_0);
            bool p1_3 = (NonDifferentiableWeights_operatorx5Bx5D_get_0(_S29, _dc_0)) <= 0.0;
            if(p1_3)
            {

#line 287
                e0_3 = _S24;

#line 287
            }
            else
            {

#line 287
                e0_3 = _S26;

#line 287
            }
            if(p1_3)
            {

#line 288
                e1_3 = _S25;

#line 288
            }
            else
            {

#line 288
                e1_3 = _S27;

#line 288
            }

#line 288
            _S40 = vec3(_S42);

#line 288
            _S41 = p1_3;

#line 288
        }
        else
        {

#line 288
            e0_3 = _S30;

#line 288
            e1_3 = _S30;

#line 288
            _S40 = _S30;

#line 288
            _S41 = false;

#line 288
        }

#line 282
        TextureBlock_0 _S43 = TextureBlock_x24_syn_dadd_0(_S33, _S31);

#line 282
        if(_S39)
        {

#line 282
            TextureBlock_0 _S44 = _S43;

#line 282
            _S44.pixels_0[_dc_0] = _S30;

#line 289
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S45;

#line 289
            _S45.primal_0 = e0_3;

#line 289
            _S45.differential_0 = _S30;

#line 289
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S46;

#line 289
            _S46.primal_0 = e1_3;

#line 289
            _S46.differential_0 = _S30;

#line 289
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S47;

#line 289
            _S47.primal_0 = _S40;

#line 289
            _S47.differential_0 = _S30;

#line 289
            s_bwd_prop_lerp_0(_S45, _S46, _S47, _S43.pixels_0[_dc_0]);

#line 289
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S48 = _S46;

#line 282
            TextureBlock_0 _S49 = TextureBlock_x24_syn_dadd_0(_S44, _S31);

#line 287
            vec3 _S50 = _S45.differential_0 + _S38;

#line 287
            vec3 _S51;

#line 287
            vec3 _S52;

#line 287
            if(_S41)
            {

#line 2246 2
                vec3 _S53 = _S48.differential_0 + _S36;

#line 2246
                _S51 = _S34;

#line 2246
                _S52 = _S53;

#line 2246
            }
            else
            {

#line 2246
                _S51 = _S48.differential_0 + _S34;

#line 2246
                _S52 = _S36;

#line 2246
            }

#line 2246
            vec3 _S54;

#line 2246
            vec3 _S55;

#line 2246
            if(_S41)
            {

#line 2246
                vec3 _S56 = _S50 + _S37;

#line 2246
                _S54 = _S35;

#line 2246
                _S55 = _S56;

#line 2246
            }
            else
            {

#line 2246
                _S54 = _S50 + _S35;

#line 2246
                _S55 = _S37;

#line 2246
            }

#line 2246
            _S33 = _S49;

#line 2246
            _S34 = _S51;

#line 2246
            _S35 = _S54;

#line 2246
            _S36 = _S52;

#line 2246
            _S37 = _S55;

#line 2246
            _S38 = _S30;

#line 2246
        }
        else
        {

#line 2246
            _S33 = TextureBlock_x24_syn_dadd_0(_S43, _S31);

#line 2246
        }

#line 2246
        _dc_0 = _dc_0 - 1;

#line 283 0
    }

#line 283
    CompressedTextureBlock2P_Differential_0 _S57 = CompressedTextureBlock2P_x24_syn_dzero_0();

#line 283
    _S57.ep3_1 = _S34;

#line 283
    _S57.ep2_1 = _S35;

#line 283
    _S57.ep1_2 = _S36;

#line 283
    _S57.ep0_2 = _S37;

#line 283
    dpblockCoefficients_1.primal_0 = dpblockCoefficients_1.primal_0;

#line 283
    dpblockCoefficients_1.differential_0 = _S57;

#line 275
    return;
}


#line 275
void s_bwd_prop_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S58, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S59, float _S60)
{

#line 275
    _d_dot_0(_S58, _S59, _S60);

#line 275
    return;
}


#line 275
void s_bwd_prop_loss_2P_0(uint _S61, inout DiffPair_CompressedTextureBlock2P_0 _S62, float _S63)
{

#line 275
    CompressedTextureBlock2P_0 _S64 = _S62.primal_0;

#line 275
    TextureBlock_0 _S65 = s_primal_ctx_decompress2P_0(_S62.primal_0);

#line 2239 2
    vec3 _S66 = vec3(0.0);

#line 2239
    int _dc_1 = 16;

#line 2239
    float _S67 = _S63;

#line 2239
    vec3  _S68[16];

#line 2239
    _S68[0] = _S66;

#line 2239
    _S68[1] = _S66;

#line 2239
    _S68[2] = _S66;

#line 2239
    _S68[3] = _S66;

#line 2239
    _S68[4] = _S66;

#line 2239
    _S68[5] = _S66;

#line 2239
    _S68[6] = _S66;

#line 2239
    _S68[7] = _S66;

#line 2239
    _S68[8] = _S66;

#line 2239
    _S68[9] = _S66;

#line 2239
    _S68[10] = _S66;

#line 2239
    _S68[11] = _S66;

#line 2239
    _S68[12] = _S66;

#line 2239
    _S68[13] = _S66;

#line 2239
    _S68[14] = _S66;

#line 2239
    _S68[15] = _S66;

#line 302 0
    for(;;)
    {

#line 302
        if(_dc_1 >= 0)
        {
        }
        else
        {

#line 302
            break;
        }

#line 302
        bool _S69 = _dc_1 < 16;

#line 302
        int _S70;

#line 302
        vec3 _S71;

#line 302
        if(_S69)
        {
            vec3 diff_0 = _S65.pixels_0[_dc_1] - g_groundtruth_0._data[uint(_S61)].pixels_0[_dc_1];

#line 304
            _S70 = 1;

#line 304
            _S71 = diff_0;

#line 304
        }
        else
        {

#line 304
            _S70 = 0;

#line 304
            _S71 = _S66;

#line 304
        }

#line 304
        float _S72;

#line 304
        float _S73;

#line 304
        if(!(_S70 != 1))
        {

#line 304
            _S72 = _S67;

#line 304
            _S73 = 0.0;

#line 304
        }
        else
        {

#line 304
            _S72 = 0.0;

#line 304
            _S73 = _S67;

#line 304
        }

#line 304
        if(_S69)
        {

#line 305
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S74;

#line 305
            _S74.primal_0 = _S71;

#line 305
            _S74.differential_0 = _S66;

#line 305
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S75;

#line 305
            _S75.primal_0 = _S71;

#line 305
            _S75.differential_0 = _S66;

#line 305
            s_bwd_prop_dot_0(_S74, _S75, _S72);

#line 304
            vec3 _S76 = _S75.differential_0 + _S74.differential_0;

#line 300
            float _S77 = _S72 + _S73;

#line 300
            vec3  _S78[16];

#line 300
            _S78[0] = _S66;

#line 300
            _S78[1] = _S66;

#line 300
            _S78[2] = _S66;

#line 300
            _S78[3] = _S66;

#line 300
            _S78[4] = _S66;

#line 300
            _S78[5] = _S66;

#line 300
            _S78[6] = _S66;

#line 300
            _S78[7] = _S66;

#line 300
            _S78[8] = _S66;

#line 300
            _S78[9] = _S66;

#line 300
            _S78[10] = _S66;

#line 300
            _S78[11] = _S66;

#line 300
            _S78[12] = _S66;

#line 300
            _S78[13] = _S66;

#line 300
            _S78[14] = _S66;

#line 300
            _S78[15] = _S66;

#line 300
            _S78[_dc_1] = _S76;

#line 2246 2
            vec3 _S79 = _S68[0] + _S78[0];

#line 2246
            vec3 _S80 = _S68[1] + _S78[1];

#line 2246
            vec3 _S81 = _S68[2] + _S78[2];

#line 2246
            vec3 _S82 = _S68[3] + _S78[3];

#line 2246
            vec3 _S83 = _S68[4] + _S78[4];

#line 2246
            vec3 _S84 = _S68[5] + _S78[5];

#line 2246
            vec3 _S85 = _S68[6] + _S78[6];

#line 2246
            vec3 _S86 = _S68[7] + _S78[7];

#line 2246
            vec3 _S87 = _S68[8] + _S78[8];

#line 2246
            vec3 _S88 = _S68[9] + _S78[9];

#line 2246
            vec3 _S89 = _S68[10] + _S78[10];

#line 2246
            vec3 _S90 = _S68[11] + _S78[11];

#line 2246
            vec3 _S91 = _S68[12] + _S78[12];

#line 2246
            vec3 _S92 = _S68[13] + _S78[13];

#line 2246
            vec3 _S93 = _S68[14] + _S78[14];

#line 2246
            vec3 _S94 = _S68[15] + _S78[15];

#line 2246
            _S67 = _S77;

#line 2246
            _S68[0] = _S79;

#line 2246
            _S68[1] = _S80;

#line 2246
            _S68[2] = _S81;

#line 2246
            _S68[3] = _S82;

#line 2246
            _S68[4] = _S83;

#line 2246
            _S68[5] = _S84;

#line 2246
            _S68[6] = _S85;

#line 2246
            _S68[7] = _S86;

#line 2246
            _S68[8] = _S87;

#line 2246
            _S68[9] = _S88;

#line 2246
            _S68[10] = _S89;

#line 2246
            _S68[11] = _S90;

#line 2246
            _S68[12] = _S91;

#line 2246
            _S68[13] = _S92;

#line 2246
            _S68[14] = _S93;

#line 2246
            _S68[15] = _S94;

#line 2246
        }
        else
        {

#line 2246
            _S67 = _S73;

#line 2246
        }

#line 2246
        _dc_1 = _dc_1 - 1;

#line 302 0
    }

#line 299
    TextureBlock_0 _S95 = TextureBlock_x24_syn_dzero_0();

#line 299
    _S95.pixels_0 = _S68;

#line 299
    CompressedTextureBlock2P_Differential_0 _S96 = CompressedTextureBlock2P_x24_syn_dzero_0();

#line 299
    DiffPair_CompressedTextureBlock2P_0 _S97;

#line 299
    _S97.primal_0 = _S64;

#line 299
    _S97.differential_0 = _S96;

#line 299
    s_bwd_prop_decompress2P_0(_S97, _S95);

#line 299
    _S62.primal_0 = _S62.primal_0;

#line 299
    _S62.differential_0 = _S97.differential_0;

#line 295
    return;
}


#line 295
void s_bwd_loss_2P_0(uint _S98, inout DiffPair_CompressedTextureBlock2P_0 _S99, float _S100)
{

#line 295
    s_bwd_prop_loss_2P_0(_S98, _S99, _S100);

#line 295
    return;
}


#line 444 5
void one_step_opt_0(inout CompressedTextureBlock2P_0 _S101, uint _S102, bool _S103)
{

#line 228 0
    vec3 _S104 = _S101.ep1_0 - _S101.ep0_0;
    vec3 _S105 = _S101.ep3_0 - _S101.ep2_0;

#line 229
    int i_6 = 0;

#line 237
    for(;;)
    {

#line 237
        if(i_6 < 16)
        {
        }
        else
        {

#line 237
            break;
        }

#line 237
        vec3 _S106 = g_groundtruth_0._data[uint(_S102)].pixels_0[i_6];

        bool p1_4 = is_partition_1_0(g_groundtruth_0._data[uint(_S102)].pixels_0[i_6], _S101.ep0_0, _S101.ep1_0, _S101.ep2_0, _S101.ep3_0);

        if(p1_4)
        {

#line 242
            _S101.partition_logits_0.data_0[i_6] = -0.5;

#line 241
        }
        else
        {
            _S101.partition_logits_0.data_0[i_6] = 0.5;

#line 241
        }

#line 241
        bool p1_5;

#line 246
        if(_S103)
        {

#line 247
            snap_1(_S101);

#line 247
            p1_5 = (NonDifferentiableWeights_operatorx5Bx5D_get_0(_S101.partition_logits_0, i_6)) <= 0.0;

#line 246
        }
        else
        {

#line 246
            p1_5 = p1_4;

#line 246
        }

#line 246
        vec3 _S107;

#line 252
        if(p1_5)
        {

#line 252
            _S107 = _S101.ep0_0;

#line 252
        }
        else
        {

#line 252
            _S107 = _S101.ep2_0;

#line 252
        }

#line 252
        vec3 P_0 = _S106 - _S107;

#line 252
        vec3 D_0;
        if(p1_5)
        {

#line 253
            D_0 = _S104;

#line 253
        }
        else
        {

#line 253
            D_0 = _S105;

#line 253
        }


        _S101.weights_0.data_0[i_6] = saturate_0(dot(P_0, D_0) / (dot(D_0, D_0) + 9.99999997475242708e-07));

#line 237
        i_6 = i_6 + 1;

#line 237
    }

#line 258
    return;
}


#line 258
float loss_2P_0(uint _S108, CompressedTextureBlock2P_0 _S109)
{

#line 299
    TextureBlock_0 _S110 = decompress2P_0(_S109);

#line 299
    int i_7 = 0;

#line 299
    float totalError_0 = 0.0;


    for(;;)
    {

#line 302
        if(i_7 < 16)
        {
        }
        else
        {

#line 302
            break;
        }
        vec3 diff_1 = _S110.pixels_0[i_7] - g_groundtruth_0._data[uint(_S108)].pixels_0[i_7];
        float totalError_1 = totalError_0 + dot(diff_1, diff_1);

#line 302
        i_7 = i_7 + 1;

#line 302
        totalError_0 = totalError_1;

#line 302
    }

#line 308
    return totalError_0;
}


#line 353
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 355
    uint blockIdx_1 = gl_GlobalInvocationID.x;
    if(blockIdx_1 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {

#line 356
        return;
    }

#line 357
    uvec2 _S111 = (clockRealtime2x32EXT());

#line 357
    g_diagnostics_0._data[uint(blockIdx_1)].start_clock_0 = _S111;

    CompressedTextureBlock2P_0 value_0 = g_compressedBlock2P_0._data[uint(blockIdx_1)];

    float _S112 = g_compress_step_params_0._data[uint(0)].learning_rate_0;
    uint steps_1 = g_compress_step_params_0._data[uint(0)].steps_0;
    bool _S113 = (g_compress_step_params_0._data[uint(0)].snap_0) > 0U;
    uint _S114 = uint(float(g_compress_step_params_0._data[uint(0)].steps_0) * 0.89999997615814209);
    uint _S115 = max(1U, g_compress_step_params_0._data[uint(0)].steps_0 / 20U);

#line 370
    PCG32_0 prng_0 = PCG32_x24init_0(0U);
    uint _S116 = PCG32_nextUint_0(prng_0);

#line 371
    value_0.ep0_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S116 % 16U];
    uint _S117 = PCG32_nextUint_0(prng_0);

#line 372
    value_0.ep1_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S117 % 16U];

#line 372
    int i_8 = 0;
    for(;;)
    {

#line 373
        if(i_8 < 8)
        {
        }
        else
        {

#line 373
            break;
        }

#line 374
        uint _S118 = PCG32_nextUint_0(prng_0);

#line 374
        value_0.ep1_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S118 % 16U];
        vec3 d_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S118 % 16U] - value_0.ep0_0;
        if((dot(d_0, d_0)) > 0.30000001192092896)
        {

#line 377
            break;
        }

#line 373
        i_8 = i_8 + 1;

#line 373
    }

#line 373
    i_8 = 0;

#line 380
    for(;;)
    {

#line 380
        if(i_8 < 8)
        {
        }
        else
        {

#line 380
            break;
        }

#line 381
        uint _S119 = PCG32_nextUint_0(prng_0);

#line 381
        value_0.ep2_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S119 % 16U];
        if((dist_0(g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S119 % 16U], value_0.ep0_0, value_0.ep1_0)) > 0.30000001192092896)
        {

#line 383
            break;
        }

#line 380
        i_8 = i_8 + 1;

#line 380
    }

#line 380
    i_8 = 0;

#line 386
    for(;;)
    {

#line 386
        if(i_8 < 8)
        {
        }
        else
        {

#line 386
            break;
        }

#line 387
        uint _S120 = PCG32_nextUint_0(prng_0);

#line 387
        value_0.ep3_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S120 % 16U];
        if((dist_0(g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S120 % 16U], value_0.ep0_0, value_0.ep1_0)) > 0.30000001192092896)
        {

#line 389
            break;
        }

#line 386
        i_8 = i_8 + 1;

#line 386
    }

#line 386
    int step_0 = 0;

#line 399
    for(;;)
    {

#line 399
        if(step_0 < int(steps_1))
        {
        }
        else
        {

#line 399
            break;
        }
        CompressedTextureBlock2P_Differential_0 _S121 = CompressedTextureBlock2P_x24_syn_dzero_0();

#line 401
        DiffPair_CompressedTextureBlock2P_0 cb_pair_0;

#line 401
        cb_pair_0.primal_0 = value_0;

#line 401
        cb_pair_0.differential_0 = _S121;

#line 401
        s_bwd_loss_2P_0(blockIdx_1, cb_pair_0, 1.0);



        const vec3 _S122 = vec3(0.0);

#line 405
        const vec3 _S123 = vec3(1.0);

#line 405
        value_0.ep0_0 = clamp(value_0.ep0_0 - cb_pair_0.differential_0.ep0_2 * _S112, _S122, _S123);
        value_0.ep1_0 = clamp(value_0.ep1_0 - cb_pair_0.differential_0.ep1_2 * _S112, _S122, _S123);
        value_0.ep2_0 = clamp(value_0.ep2_0 - cb_pair_0.differential_0.ep2_1 * _S112, _S122, _S123);
        value_0.ep3_0 = clamp(value_0.ep3_0 - cb_pair_0.differential_0.ep3_1 * _S112, _S122, _S123);

#line 408
        bool _S124;
        if(_S113)
        {

#line 409
            uint _S125 = uint(step_0);

#line 409
            if(_S125 > _S114)
            {

#line 409
                _S124 = true;

#line 409
            }
            else
            {

#line 409
                _S124 = _S125 >= (steps_1 - 1U);

#line 409
            }

#line 409
        }
        else
        {

#line 409
            _S124 = false;

#line 409
        }

#line 409
        one_step_opt_0(value_0, blockIdx_1, _S124);

        uint _S126 = uint(step_0);

#line 411
        uint _S127 = _S126 % _S115;

#line 411
        if(_S127 == 0U)
        {

#line 412
            uint iter_0 = _S126 / _S115;
            uvec2 _S128 = (clockRealtime2x32EXT());

#line 413
            g_diagnostics_0._data[uint(blockIdx_1)].timestamps_0[iter_0] = _S128;
            g_diagnostics_0._data[uint(blockIdx_1)].loss_log_0[iter_0] = loss_2P_0(blockIdx_1, value_0);

            uint raw_map_2 = pack_partition_indices_to_mask_0(value_0.partition_logits_0.data_0);



            g_diagnostics_0._data[uint(blockIdx_1)].partition_hamming_error_log_0[iter_0] = hamming_distance_0(raw_map_2, get_mask_0(g_lut_0.lut2_0[get_closest_seed_0(raw_map_2)]));
            g_diagnostics_0._data[uint(blockIdx_1)].ideal_partition_log_0[iter_0] = raw_map_2;

#line 411
        }

#line 399
        step_0 = step_0 + 1;

#line 399
    }

#line 425
    uvec2 _S129 = (clockRealtime2x32EXT());

#line 425
    g_diagnostics_0._data[uint(blockIdx_1)].optim_ended_clock_0 = _S129;
    g_compressedBlock2P_0._data[uint(blockIdx_1)] = value_0;
    g_reconstructed_0._data[uint(blockIdx_1)] = reconstruct_0(value_0, blockIdx_1);
    g_diagnostics_0._data[uint(blockIdx_1)].partition_hamming_error_0 = hamming_distance_0(value_0.ideal_partition_map_0, value_0.astc_partition_map_0);
    g_final_loss_0._data[uint(blockIdx_1)] = loss_2P_0(blockIdx_1, value_0);
    uvec2 _S130 = (clockRealtime2x32EXT());

#line 430
    g_diagnostics_0._data[uint(blockIdx_1)].finished_clock_0 = _S130;
    return;
}

#version 450
layout(row_major) uniform;
layout(row_major) buffer;

#line 49 0
struct CompressStepParams_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
    uint snap_0;
    uint max_partitions_0;
};


#line 75
layout(std430, binding = 5) buffer StructuredBuffer_CompressStepParams_t_0 {
    CompressStepParams_0 _data[];
} g_compress_step_params_0;

#line 72
layout(std430, binding = 4) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 8
struct TextureBlock_0
{
    vec3  pixels_0[16];
};


#line 60
layout(std430, binding = 0) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;

#line 27
struct NonDifferentiableWeights_0
{
    float  data_0[16];
};


#line 37
struct CompressedTextureBlock2P_0
{
    vec3 ep0_0;
    vec3 ep1_0;
    vec3 ep2_0;
    vec3 ep3_0;
    NonDifferentiableWeights_0 weights_0;
    NonDifferentiableWeights_0 partition_logits_0;
    uint astc_partition_map_0;
    uint ideal_partition_map_0;
    uint astc_seed_0;
};


#line 69
layout(std430, binding = 3) buffer StructuredBuffer_CompressedTextureBlock2P_t_0 {
    CompressedTextureBlock2P_0 _data[];
} g_compressedBlock2P_0;

#line 31
float NonDifferentiableWeights_operatorx5Bx5D_get_0(NonDifferentiableWeights_0 this_0, int n_0)
{

#line 31
    return this_0.data_0[n_0];
}


#line 353
TextureBlock_0 decompress2P_0(uint _S1)
{

#line 353
    CompressedTextureBlock2P_0 _S2 = g_compressedBlock2P_0._data[uint(_S1)];

#line 282
    TextureBlock_0 outputBlock_0;

#line 282
    int i_0 = 0;
    for(;;)
    {

#line 283
        if(i_0 < 16)
        {
        }
        else
        {

#line 283
            break;
        }
        float _S3 = NonDifferentiableWeights_operatorx5Bx5D_get_0(_S2.weights_0, i_0);
        bool p1_0 = (NonDifferentiableWeights_operatorx5Bx5D_get_0(_S2.partition_logits_0, i_0)) <= 0.0;

#line 286
        vec3 e0_0;
        if(p1_0)
        {

#line 287
            e0_0 = _S2.ep0_0;

#line 287
        }
        else
        {

#line 287
            e0_0 = _S2.ep2_0;

#line 287
        }

#line 287
        vec3 e1_0;
        if(p1_0)
        {

#line 288
            e1_0 = _S2.ep1_0;

#line 288
        }
        else
        {

#line 288
            e1_0 = _S2.ep3_0;

#line 288
        }
        outputBlock_0.pixels_0[i_0] = mix(e0_0, e1_0, vec3(_S3));

#line 283
        i_0 = i_0 + 1;

#line 283
    }

#line 291
    return outputBlock_0;
}


#line 291
float loss_2P_0(uint _S4, uint _S5)
{

#line 291
    TextureBlock_0 _S6 = decompress2P_0(_S5);

#line 291
    int i_1 = 0;

#line 291
    float totalError_0 = 0.0;

#line 302
    for(;;)
    {

#line 302
        if(i_1 < 16)
        {
        }
        else
        {

#line 302
            break;
        }
        vec3 diff_0 = _S6.pixels_0[i_1] - g_groundtruth_0._data[uint(_S4)].pixels_0[i_1];
        float totalError_1 = totalError_0 + dot(diff_0, diff_0);

#line 302
        i_1 = i_1 + 1;

#line 302
        totalError_0 = totalError_1;

#line 302
    }

#line 308
    return totalError_0;
}


#line 435
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 437
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {

#line 438
        return;
    }

#line 439
    g_final_loss_0._data[uint(blockIdx_0)] = loss_2P_0(blockIdx_0, blockIdx_0);
    return;
}

