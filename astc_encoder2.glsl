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
};


#line 73
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


#line 64
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


#line 67
layout(std430, binding = 3) buffer StructuredBuffer_CompressedTextureBlock2P_t_0 {
    CompressedTextureBlock2P_0 _data[];
} g_compressedBlock2P_0;

#line 8
struct TextureBlock_0
{
    vec3  pixels_0[16];
};


#line 58
layout(std430, binding = 0) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;

#line 76
layout(std430, binding = 6) readonly buffer StructuredBuffer_uint_t_0 {
    uint _data[];
} g_lut_ideal_to_seed_0;

#line 77
layout(std430, binding = 7) readonly buffer StructuredBuffer_uint_t_1 {
    uint _data[];
} g_lut_seed_to_mask_0;

#line 61
layout(std430, binding = 1) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;

#line 70
layout(std430, binding = 4) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 37
struct CompressedTextureBlock2P_Differential_0
{
    vec3 ep0_1;
    vec3 ep1_1;
    vec3 ep2_1;
    vec3 ep3_1;
};


#line 37
CompressedTextureBlock2P_Differential_0 CompressedTextureBlock2P_x24_syn_dzero_0()
{

#line 37
    CompressedTextureBlock2P_Differential_0 result_0;

#line 2239 1
    vec3 _S1 = vec3(0.0);

#line 2239
    result_0.ep0_1 = _S1;

#line 2239
    result_0.ep1_1 = _S1;

#line 2239
    result_0.ep2_1 = _S1;

#line 2239
    result_0.ep3_1 = _S1;

#line 2239
    return result_0;
}


#line 31 0
float NonDifferentiableWeights_operatorx5Bx5D_get_0(NonDifferentiableWeights_0 this_0, int n_0)
{

#line 31
    return this_0.data_0[n_0];
}


#line 31
struct DiffPair_float_0
{
    float primal_0;
    float differential_0;
};


#line 2263 2
void _d_lerp_0(inout DiffPair_float_0 dpx_0, inout DiffPair_float_0 dpy_0, inout DiffPair_float_0 dps_0, float dOut_0)
{

#line 2263
    float _S2 = (1.0 - dps_0.primal_0) * dOut_0;

#line 2263
    dpx_0.primal_0 = dpx_0.primal_0;

#line 2263
    dpx_0.differential_0 = _S2;


    DiffPair_float_0 _S3 = dpy_0;

#line 2266
    float _S4 = dps_0.primal_0 * dOut_0;

#line 2266
    dpy_0.primal_0 = dpy_0.primal_0;

#line 2266
    dpy_0.differential_0 = _S4;

#line 2266
    float _S5 = (_S3.primal_0 - dpx_0.primal_0) * dOut_0;

#line 2266
    dps_0.primal_0 = _S3.primal_0;

#line 2266
    dps_0.differential_0 = _S5;

    return;
}


#line 2268
struct DiffPair_vectorx3Cfloatx2C3x3E_0
{
    vec3 primal_0;
    vec3 differential_0;
};


#line 1 3
void _d_lerp_vector_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpx_1, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpy_1, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpz_0, vec3 dOut_1)
{

#line 1841 2
    DiffPair_float_0 left_dp_0;

#line 1841
    left_dp_0.primal_0 = dpx_1.primal_0[0];

#line 1841
    left_dp_0.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_0;

#line 1842
    middle_dp_0.primal_0 = dpy_1.primal_0[0];

#line 1842
    middle_dp_0.differential_0 = 0.0;
    DiffPair_float_0 right_dp_0;

#line 1843
    right_dp_0.primal_0 = dpz_0.primal_0[0];

#line 1843
    right_dp_0.differential_0 = 0.0;
    _d_lerp_0(left_dp_0, middle_dp_0, right_dp_0, dOut_1[0]);

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
    left_dp_1.primal_0 = dpx_1.primal_0[1];

#line 1841
    left_dp_1.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_1;

#line 1842
    middle_dp_1.primal_0 = dpy_1.primal_0[1];

#line 1842
    middle_dp_1.differential_0 = 0.0;
    DiffPair_float_0 right_dp_1;

#line 1843
    right_dp_1.primal_0 = dpz_0.primal_0[1];

#line 1843
    right_dp_1.differential_0 = 0.0;
    _d_lerp_0(left_dp_1, middle_dp_1, right_dp_1, dOut_1[1]);

    left_d_result_0[1] = left_dp_1.differential_0;
    middle_d_result_0[1] = middle_dp_1.differential_0;
    right_d_result_0[1] = right_dp_1.differential_0;

#line 1841
    DiffPair_float_0 left_dp_2;

#line 1841
    left_dp_2.primal_0 = dpx_1.primal_0[2];

#line 1841
    left_dp_2.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_2;

#line 1842
    middle_dp_2.primal_0 = dpy_1.primal_0[2];

#line 1842
    middle_dp_2.differential_0 = 0.0;
    DiffPair_float_0 right_dp_2;

#line 1843
    right_dp_2.primal_0 = dpz_0.primal_0[2];

#line 1843
    right_dp_2.differential_0 = 0.0;
    _d_lerp_0(left_dp_2, middle_dp_2, right_dp_2, dOut_1[2]);

    left_d_result_0[2] = left_dp_2.differential_0;
    middle_d_result_0[2] = middle_dp_2.differential_0;
    right_d_result_0[2] = right_dp_2.differential_0;

#line 1848
    dpx_1.primal_0 = dpx_1.primal_0;

#line 1848
    dpx_1.differential_0 = left_d_result_0;

#line 1848
    dpy_1.primal_0 = dpy_1.primal_0;

#line 1848
    dpy_1.differential_0 = middle_d_result_0;

#line 1848
    dpz_0.primal_0 = dpz_0.primal_0;

#line 1848
    dpz_0.differential_0 = right_d_result_0;

#line 1853
    return;
}


#line 176 0
TextureBlock_0 decompress2P_0(CompressedTextureBlock2P_0 blockCoefficients_0)
{

#line 183
    TextureBlock_0 outputBlock_0;

#line 183
    int i_0 = 0;
    for(;;)
    {

#line 184
        if(i_0 < 16)
        {
        }
        else
        {

#line 184
            break;
        }
        float _S6 = NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_0.weights_0, i_0);
        bool p1_0 = (NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_0.partition_logits_0, i_0)) <= 0.0;

#line 187
        vec3 e0_0;
        if(p1_0)
        {

#line 188
            e0_0 = blockCoefficients_0.ep0_0;

#line 188
        }
        else
        {

#line 188
            e0_0 = blockCoefficients_0.ep2_0;

#line 188
        }

#line 188
        vec3 e1_0;
        if(p1_0)
        {

#line 189
            e1_0 = blockCoefficients_0.ep1_0;

#line 189
        }
        else
        {

#line 189
            e1_0 = blockCoefficients_0.ep3_0;

#line 189
        }
        outputBlock_0.pixels_0[i_0] = mix(e0_0, e1_0, vec3(_S6));

#line 184
        i_0 = i_0 + 1;

#line 184
    }

#line 192
    return outputBlock_0;
}


#line 1639 2
void _d_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpx_2, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpy_2, float dOut_2)
{
    vec3 x_d_result_0;



    x_d_result_0[0] = dpy_2.primal_0[0] * dOut_2;

#line 1641
    vec3 y_d_result_0;

#line 1646
    y_d_result_0[0] = dpx_2.primal_0[0] * dOut_2;

#line 1645
    x_d_result_0[1] = dpy_2.primal_0[1] * dOut_2;
    y_d_result_0[1] = dpx_2.primal_0[1] * dOut_2;

#line 1645
    x_d_result_0[2] = dpy_2.primal_0[2] * dOut_2;
    y_d_result_0[2] = dpx_2.primal_0[2] * dOut_2;

#line 1646
    dpx_2.primal_0 = dpx_2.primal_0;

#line 1646
    dpx_2.differential_0 = x_d_result_0;

#line 1646
    dpy_2.primal_0 = dpy_2.primal_0;

#line 1646
    dpy_2.differential_0 = y_d_result_0;



    return;
}


#line 80 0
bool is_partition_1_0(vec3 x_0, vec3 ep0_2, vec3 ep1_2, vec3 ep2_2, vec3 ep3_2)
{
    vec3 d1_0 = ep1_2 - ep0_2;
    vec3 d2_0 = ep3_2 - ep2_2;

#line 91
    vec3 c1_0 = cross(x_0 - ep0_2, d1_0);
    vec3 c2_0 = cross(x_0 - ep2_2, d2_0);

#line 97
    return (dot(c1_0, c1_0) * dot(d2_0, d2_0)) < (dot(c2_0, c2_0) * dot(d1_0, d1_0));
}


#line 148
uint pack_partition_indices_to_mask_0(float  p_logits_0[16])
{

#line 148
    int i_1 = 0;

#line 148
    uint raw_map_0 = 0U;


    for(;;)
    {

#line 151
        if(i_1 < 16)
        {
        }
        else
        {

#line 151
            break;
        }
        if((p_logits_0[i_1]) > 0.0)
        {

#line 153
            raw_map_0 = raw_map_0 | uint(1 << i_1);

#line 153
        }

#line 151
        i_1 = i_1 + 1;

#line 151
    }

#line 158
    return raw_map_0;
}


#line 101
void snap_0(inout CompressedTextureBlock2P_0 block_0)
{
    uint raw_map_1 = pack_partition_indices_to_mask_0(block_0.partition_logits_0.data_0);
    uint closest_seed_0 = g_lut_ideal_to_seed_0._data[uint(raw_map_1)];
    uint final_mask_0 = g_lut_seed_to_mask_0._data[uint(closest_seed_0)];

    block_0.astc_seed_0 = closest_seed_0;
    block_0.astc_partition_map_0 = final_mask_0;
    block_0.ideal_partition_map_0 = raw_map_1;

#line 109
    int i_2 = 0;


    for(;;)
    {

#line 112
        if(i_2 < 16)
        {
        }
        else
        {

#line 112
            break;
        }
        float logit_0 = abs(NonDifferentiableWeights_operatorx5Bx5D_get_0(block_0.partition_logits_0, i_2));

#line 114
        float logit_1;
        if(((final_mask_0 >> i_2) & 1U) == 0U)
        {

#line 115
            logit_1 = - logit_0;

#line 115
        }
        else
        {

#line 115
            logit_1 = logit_0;

#line 115
        }
        block_0.partition_logits_0.data_0[i_2] = logit_1;

#line 112
        i_2 = i_2 + 1;

#line 112
    }

#line 118
    return;
}


#line 13393 4
float saturate_0(float x_1)
{

#line 13401
    return clamp(x_1, 0.0, 1.0);
}


#line 162 0
int hamming_distance_0(uint n1_0, uint n2_0)
{

#line 162
    int x_2 = int(n1_0 ^ n2_0);

#line 162
    int output_0 = 0;

#line 167
    for(;;)
    {

#line 167
        if(x_2 > 0)
        {
        }
        else
        {

#line 167
            break;
        }

#line 168
        int output_1 = output_0 + (x_2 & 1);

#line 168
        x_2 = x_2 >> 1;

#line 168
        output_0 = output_1;

#line 167
    }

#line 172
    return output_0;
}


#line 215
struct DiffPair_CompressedTextureBlock2P_0
{
    CompressedTextureBlock2P_0 primal_0;
    CompressedTextureBlock2P_Differential_0 differential_0;
};


#line 232
vec3 s_primal_ctx_lerp_0(vec3 _S7, vec3 _S8, vec3 _S9)
{

#line 232
    return mix(_S7, _S8, _S9);
}


#line 232
TextureBlock_0 s_primal_ctx_decompress2P_0(CompressedTextureBlock2P_0 dpblockCoefficients_0)
{

#line 183
    vec3 _S10 = vec3(0.0);

#line 183
    vec3  _S11[16] = { _S10, _S10, _S10, _S10, _S10, _S10, _S10, _S10, _S10, _S10, _S10, _S10, _S10, _S10, _S10, _S10 };

#line 183
    bool _runFlag_0 = true;

#line 183
    int i_3 = 0;

#line 183
    TextureBlock_0 outputBlock_1;

#line 183
    outputBlock_1.pixels_0 = _S11;

#line 183
    int _pc_0 = 0;
    for(;;)
    {

#line 184
        if(_runFlag_0)
        {
        }
        else
        {

#line 184
            break;
        }

#line 184
        int _S12;

#line 184
        if(i_3 < 16)
        {
            float _S13 = NonDifferentiableWeights_operatorx5Bx5D_get_0(dpblockCoefficients_0.weights_0, i_3);
            bool p1_1 = (NonDifferentiableWeights_operatorx5Bx5D_get_0(dpblockCoefficients_0.partition_logits_0, i_3)) <= 0.0;

#line 187
            vec3 e0_1;
            if(p1_1)
            {

#line 188
                e0_1 = dpblockCoefficients_0.ep0_0;

#line 188
            }
            else
            {

#line 188
                e0_1 = dpblockCoefficients_0.ep2_0;

#line 188
            }

#line 188
            vec3 e1_1;
            if(p1_1)
            {

#line 189
                e1_1 = dpblockCoefficients_0.ep1_0;

#line 189
            }
            else
            {

#line 189
                e1_1 = dpblockCoefficients_0.ep3_0;

#line 189
            }

#line 189
            vec3 _S14 = s_primal_ctx_lerp_0(e0_1, e1_1, vec3(_S13));

#line 189
            TextureBlock_0 _S15 = outputBlock_1;

#line 189
            _S15.pixels_0[i_3] = _S14;

#line 189
            _S12 = 1;

#line 189
            outputBlock_1 = _S15;

#line 189
        }
        else
        {

#line 189
            _S12 = 0;

#line 189
        }

#line 189
        if(_S12 != 1)
        {

#line 189
            _runFlag_0 = false;

#line 189
        }

#line 189
        if(_runFlag_0)
        {

#line 189
            i_3 = i_3 + 1;

#line 189
        }

#line 189
        _pc_0 = _pc_0 + 1;

#line 184
    }

#line 184
    return outputBlock_1;
}


#line 184
TextureBlock_0 TextureBlock_x24_syn_dzero_0()
{

#line 184
    TextureBlock_0 result_1;

#line 2239 1
    vec3 _S16 = vec3(0.0);

#line 2239
    result_1.pixels_0[0] = _S16;

#line 2239
    result_1.pixels_0[1] = _S16;

#line 2239
    result_1.pixels_0[2] = _S16;

#line 2239
    result_1.pixels_0[3] = _S16;

#line 2239
    result_1.pixels_0[4] = _S16;

#line 2239
    result_1.pixels_0[5] = _S16;

#line 2239
    result_1.pixels_0[6] = _S16;

#line 2239
    result_1.pixels_0[7] = _S16;

#line 2239
    result_1.pixels_0[8] = _S16;

#line 2239
    result_1.pixels_0[9] = _S16;

#line 2239
    result_1.pixels_0[10] = _S16;

#line 2239
    result_1.pixels_0[11] = _S16;

#line 2239
    result_1.pixels_0[12] = _S16;

#line 2239
    result_1.pixels_0[13] = _S16;

#line 2239
    result_1.pixels_0[14] = _S16;

#line 2239
    result_1.pixels_0[15] = _S16;

#line 2239
    return result_1;
}


#line 2239
TextureBlock_0 TextureBlock_x24_syn_dadd_0(TextureBlock_0 SLANG_anonymous_0_0, TextureBlock_0 SLANG_anonymous_1_0)
{

#line 2239
    TextureBlock_0 result_2;

#line 2239
    result_2.pixels_0[0] = SLANG_anonymous_0_0.pixels_0[0] + SLANG_anonymous_1_0.pixels_0[0];

#line 2239
    result_2.pixels_0[1] = SLANG_anonymous_0_0.pixels_0[1] + SLANG_anonymous_1_0.pixels_0[1];

#line 2239
    result_2.pixels_0[2] = SLANG_anonymous_0_0.pixels_0[2] + SLANG_anonymous_1_0.pixels_0[2];

#line 2239
    result_2.pixels_0[3] = SLANG_anonymous_0_0.pixels_0[3] + SLANG_anonymous_1_0.pixels_0[3];

#line 2239
    result_2.pixels_0[4] = SLANG_anonymous_0_0.pixels_0[4] + SLANG_anonymous_1_0.pixels_0[4];

#line 2239
    result_2.pixels_0[5] = SLANG_anonymous_0_0.pixels_0[5] + SLANG_anonymous_1_0.pixels_0[5];

#line 2239
    result_2.pixels_0[6] = SLANG_anonymous_0_0.pixels_0[6] + SLANG_anonymous_1_0.pixels_0[6];

#line 2239
    result_2.pixels_0[7] = SLANG_anonymous_0_0.pixels_0[7] + SLANG_anonymous_1_0.pixels_0[7];

#line 2239
    result_2.pixels_0[8] = SLANG_anonymous_0_0.pixels_0[8] + SLANG_anonymous_1_0.pixels_0[8];

#line 2239
    result_2.pixels_0[9] = SLANG_anonymous_0_0.pixels_0[9] + SLANG_anonymous_1_0.pixels_0[9];

#line 2239
    result_2.pixels_0[10] = SLANG_anonymous_0_0.pixels_0[10] + SLANG_anonymous_1_0.pixels_0[10];

#line 2239
    result_2.pixels_0[11] = SLANG_anonymous_0_0.pixels_0[11] + SLANG_anonymous_1_0.pixels_0[11];

#line 2239
    result_2.pixels_0[12] = SLANG_anonymous_0_0.pixels_0[12] + SLANG_anonymous_1_0.pixels_0[12];

#line 2239
    result_2.pixels_0[13] = SLANG_anonymous_0_0.pixels_0[13] + SLANG_anonymous_1_0.pixels_0[13];

#line 2239
    result_2.pixels_0[14] = SLANG_anonymous_0_0.pixels_0[14] + SLANG_anonymous_1_0.pixels_0[14];

#line 2239
    result_2.pixels_0[15] = SLANG_anonymous_0_0.pixels_0[15] + SLANG_anonymous_1_0.pixels_0[15];

#line 2239
    return result_2;
}


#line 2239
void s_bwd_prop_lerp_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S17, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S18, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S19, vec3 _S20)
{

#line 2239
    _d_lerp_vector_0(_S17, _S18, _S19, _S20);

#line 2239
    return;
}


#line 176 0
void s_bwd_prop_decompress2P_0(inout DiffPair_CompressedTextureBlock2P_0 dpblockCoefficients_1, TextureBlock_0 _s_dOut_0)
{

#line 176
    vec3 _S21 = dpblockCoefficients_1.primal_0.ep0_0;

#line 176
    vec3 _S22 = dpblockCoefficients_1.primal_0.ep1_0;

#line 176
    vec3 _S23 = dpblockCoefficients_1.primal_0.ep2_0;

#line 176
    vec3 _S24 = dpblockCoefficients_1.primal_0.ep3_0;

#line 176
    NonDifferentiableWeights_0 _S25 = dpblockCoefficients_1.primal_0.weights_0;

#line 176
    NonDifferentiableWeights_0 _S26 = dpblockCoefficients_1.primal_0.partition_logits_0;

#line 2239 1
    vec3 _S27 = vec3(0.0);

#line 183 0
    TextureBlock_0 _S28 = TextureBlock_x24_syn_dzero_0();

#line 183
    TextureBlock_0 _S29 = TextureBlock_x24_syn_dadd_0(_s_dOut_0, _S28);

#line 183
    int _dc_0 = 16;

#line 183
    TextureBlock_0 _S30 = _S29;

#line 183
    vec3 _S31 = _S27;

#line 183
    vec3 _S32 = _S27;

#line 183
    vec3 _S33 = _S27;

#line 183
    vec3 _S34 = _S27;

#line 183
    vec3 _S35 = _S27;
    for(;;)
    {

#line 184
        if(_dc_0 >= 0)
        {
        }
        else
        {

#line 184
            break;
        }

#line 184
        bool _S36 = _dc_0 < 16;

#line 184
        vec3 e0_2;

#line 184
        vec3 e1_2;

#line 184
        vec3 _S37;

#line 184
        bool _S38;

#line 184
        if(_S36)
        {
            float _S39 = NonDifferentiableWeights_operatorx5Bx5D_get_0(_S25, _dc_0);
            bool p1_2 = (NonDifferentiableWeights_operatorx5Bx5D_get_0(_S26, _dc_0)) <= 0.0;
            if(p1_2)
            {

#line 188
                e0_2 = _S21;

#line 188
            }
            else
            {

#line 188
                e0_2 = _S23;

#line 188
            }
            if(p1_2)
            {

#line 189
                e1_2 = _S22;

#line 189
            }
            else
            {

#line 189
                e1_2 = _S24;

#line 189
            }

#line 189
            _S37 = vec3(_S39);

#line 189
            _S38 = p1_2;

#line 189
        }
        else
        {

#line 189
            e0_2 = _S27;

#line 189
            e1_2 = _S27;

#line 189
            _S37 = _S27;

#line 189
            _S38 = false;

#line 189
        }

#line 183
        TextureBlock_0 _S40 = TextureBlock_x24_syn_dadd_0(_S30, _S28);

#line 183
        if(_S36)
        {

#line 183
            TextureBlock_0 _S41 = _S40;

#line 183
            _S41.pixels_0[_dc_0] = _S27;

#line 190
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S42;

#line 190
            _S42.primal_0 = e0_2;

#line 190
            _S42.differential_0 = _S27;

#line 190
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S43;

#line 190
            _S43.primal_0 = e1_2;

#line 190
            _S43.differential_0 = _S27;

#line 190
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S44;

#line 190
            _S44.primal_0 = _S37;

#line 190
            _S44.differential_0 = _S27;

#line 190
            s_bwd_prop_lerp_0(_S42, _S43, _S44, _S40.pixels_0[_dc_0]);

#line 190
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S45 = _S43;

#line 183
            TextureBlock_0 _S46 = TextureBlock_x24_syn_dadd_0(_S41, _S28);

#line 188
            vec3 _S47 = _S42.differential_0 + _S35;

#line 188
            vec3 _S48;

#line 188
            vec3 _S49;

#line 188
            if(_S38)
            {

#line 2246 1
                vec3 _S50 = _S45.differential_0 + _S33;

#line 2246
                _S48 = _S31;

#line 2246
                _S49 = _S50;

#line 2246
            }
            else
            {

#line 2246
                _S48 = _S45.differential_0 + _S31;

#line 2246
                _S49 = _S33;

#line 2246
            }

#line 2246
            vec3 _S51;

#line 2246
            vec3 _S52;

#line 2246
            if(_S38)
            {

#line 2246
                vec3 _S53 = _S47 + _S34;

#line 2246
                _S51 = _S32;

#line 2246
                _S52 = _S53;

#line 2246
            }
            else
            {

#line 2246
                _S51 = _S47 + _S32;

#line 2246
                _S52 = _S34;

#line 2246
            }

#line 2246
            _S30 = _S46;

#line 2246
            _S31 = _S48;

#line 2246
            _S32 = _S51;

#line 2246
            _S33 = _S49;

#line 2246
            _S34 = _S52;

#line 2246
            _S35 = _S27;

#line 2246
        }
        else
        {

#line 2246
            _S30 = TextureBlock_x24_syn_dadd_0(_S40, _S28);

#line 2246
        }

#line 2246
        _dc_0 = _dc_0 - 1;

#line 184 0
    }

#line 184
    CompressedTextureBlock2P_Differential_0 _S54 = CompressedTextureBlock2P_x24_syn_dzero_0();

#line 184
    _S54.ep3_1 = _S31;

#line 184
    _S54.ep2_1 = _S32;

#line 184
    _S54.ep1_1 = _S33;

#line 184
    _S54.ep0_1 = _S34;

#line 184
    dpblockCoefficients_1.primal_0 = dpblockCoefficients_1.primal_0;

#line 184
    dpblockCoefficients_1.differential_0 = _S54;

#line 176
    return;
}


#line 176
void s_bwd_prop_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S55, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S56, float _S57)
{

#line 176
    _d_dot_0(_S55, _S56, _S57);

#line 176
    return;
}


#line 176
void s_bwd_prop_loss_2P_0(uint _S58, inout DiffPair_CompressedTextureBlock2P_0 _S59, float _S60)
{

#line 176
    CompressedTextureBlock2P_0 _S61 = _S59.primal_0;

#line 176
    TextureBlock_0 _S62 = s_primal_ctx_decompress2P_0(_S59.primal_0);

#line 2239 1
    vec3 _S63 = vec3(0.0);

#line 2239
    int _dc_1 = 16;

#line 2239
    float _S64 = _S60;

#line 2239
    vec3  _S65[16];

#line 2239
    _S65[0] = _S63;

#line 2239
    _S65[1] = _S63;

#line 2239
    _S65[2] = _S63;

#line 2239
    _S65[3] = _S63;

#line 2239
    _S65[4] = _S63;

#line 2239
    _S65[5] = _S63;

#line 2239
    _S65[6] = _S63;

#line 2239
    _S65[7] = _S63;

#line 2239
    _S65[8] = _S63;

#line 2239
    _S65[9] = _S63;

#line 2239
    _S65[10] = _S63;

#line 2239
    _S65[11] = _S63;

#line 2239
    _S65[12] = _S63;

#line 2239
    _S65[13] = _S63;

#line 2239
    _S65[14] = _S63;

#line 2239
    _S65[15] = _S63;

#line 203 0
    for(;;)
    {

#line 203
        if(_dc_1 >= 0)
        {
        }
        else
        {

#line 203
            break;
        }

#line 203
        bool _S66 = _dc_1 < 16;

#line 203
        int _S67;

#line 203
        vec3 _S68;

#line 203
        if(_S66)
        {
            vec3 diff_0 = _S62.pixels_0[_dc_1] - g_groundtruth_0._data[uint(_S58)].pixels_0[_dc_1];

#line 205
            _S67 = 1;

#line 205
            _S68 = diff_0;

#line 205
        }
        else
        {

#line 205
            _S67 = 0;

#line 205
            _S68 = _S63;

#line 205
        }

#line 205
        float _S69;

#line 205
        float _S70;

#line 205
        if(!(_S67 != 1))
        {

#line 205
            _S69 = _S64;

#line 205
            _S70 = 0.0;

#line 205
        }
        else
        {

#line 205
            _S69 = 0.0;

#line 205
            _S70 = _S64;

#line 205
        }

#line 205
        if(_S66)
        {

#line 206
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S71;

#line 206
            _S71.primal_0 = _S68;

#line 206
            _S71.differential_0 = _S63;

#line 206
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S72;

#line 206
            _S72.primal_0 = _S68;

#line 206
            _S72.differential_0 = _S63;

#line 206
            s_bwd_prop_dot_0(_S71, _S72, _S69);

#line 205
            vec3 _S73 = _S72.differential_0 + _S71.differential_0;

#line 201
            float _S74 = _S69 + _S70;

#line 201
            vec3  _S75[16];

#line 201
            _S75[0] = _S63;

#line 201
            _S75[1] = _S63;

#line 201
            _S75[2] = _S63;

#line 201
            _S75[3] = _S63;

#line 201
            _S75[4] = _S63;

#line 201
            _S75[5] = _S63;

#line 201
            _S75[6] = _S63;

#line 201
            _S75[7] = _S63;

#line 201
            _S75[8] = _S63;

#line 201
            _S75[9] = _S63;

#line 201
            _S75[10] = _S63;

#line 201
            _S75[11] = _S63;

#line 201
            _S75[12] = _S63;

#line 201
            _S75[13] = _S63;

#line 201
            _S75[14] = _S63;

#line 201
            _S75[15] = _S63;

#line 201
            _S75[_dc_1] = _S73;

#line 2246 1
            vec3 _S76 = _S65[0] + _S75[0];

#line 2246
            vec3 _S77 = _S65[1] + _S75[1];

#line 2246
            vec3 _S78 = _S65[2] + _S75[2];

#line 2246
            vec3 _S79 = _S65[3] + _S75[3];

#line 2246
            vec3 _S80 = _S65[4] + _S75[4];

#line 2246
            vec3 _S81 = _S65[5] + _S75[5];

#line 2246
            vec3 _S82 = _S65[6] + _S75[6];

#line 2246
            vec3 _S83 = _S65[7] + _S75[7];

#line 2246
            vec3 _S84 = _S65[8] + _S75[8];

#line 2246
            vec3 _S85 = _S65[9] + _S75[9];

#line 2246
            vec3 _S86 = _S65[10] + _S75[10];

#line 2246
            vec3 _S87 = _S65[11] + _S75[11];

#line 2246
            vec3 _S88 = _S65[12] + _S75[12];

#line 2246
            vec3 _S89 = _S65[13] + _S75[13];

#line 2246
            vec3 _S90 = _S65[14] + _S75[14];

#line 2246
            vec3 _S91 = _S65[15] + _S75[15];

#line 2246
            _S64 = _S74;

#line 2246
            _S65[0] = _S76;

#line 2246
            _S65[1] = _S77;

#line 2246
            _S65[2] = _S78;

#line 2246
            _S65[3] = _S79;

#line 2246
            _S65[4] = _S80;

#line 2246
            _S65[5] = _S81;

#line 2246
            _S65[6] = _S82;

#line 2246
            _S65[7] = _S83;

#line 2246
            _S65[8] = _S84;

#line 2246
            _S65[9] = _S85;

#line 2246
            _S65[10] = _S86;

#line 2246
            _S65[11] = _S87;

#line 2246
            _S65[12] = _S88;

#line 2246
            _S65[13] = _S89;

#line 2246
            _S65[14] = _S90;

#line 2246
            _S65[15] = _S91;

#line 2246
        }
        else
        {

#line 2246
            _S64 = _S70;

#line 2246
        }

#line 2246
        _dc_1 = _dc_1 - 1;

#line 203 0
    }

#line 200
    TextureBlock_0 _S92 = TextureBlock_x24_syn_dzero_0();

#line 200
    _S92.pixels_0 = _S65;

#line 200
    CompressedTextureBlock2P_Differential_0 _S93 = CompressedTextureBlock2P_x24_syn_dzero_0();

#line 200
    DiffPair_CompressedTextureBlock2P_0 _S94;

#line 200
    _S94.primal_0 = _S61;

#line 200
    _S94.differential_0 = _S93;

#line 200
    s_bwd_prop_decompress2P_0(_S94, _S92);

#line 200
    _S59.primal_0 = _S59.primal_0;

#line 200
    _S59.differential_0 = _S94.differential_0;

#line 196
    return;
}


#line 196
void s_bwd_loss_2P_0(uint _S95, inout DiffPair_CompressedTextureBlock2P_0 _S96, float _S97)
{

#line 196
    s_bwd_prop_loss_2P_0(_S95, _S96, _S97);

#line 196
    return;
}


#line 196
void one_step_opt_0(inout CompressedTextureBlock2P_0 _S98, uint _S99, bool _S100)
{

#line 123
    vec3 _S101 = _S98.ep1_0 - _S98.ep0_0;
    vec3 _S102 = _S98.ep3_0 - _S98.ep2_0;

#line 124
    int i_4 = 0;
    for(;;)
    {

#line 125
        if(i_4 < 16)
        {
        }
        else
        {

#line 125
            break;
        }

#line 125
        vec3 _S103 = g_groundtruth_0._data[uint(_S99)].pixels_0[i_4];

        bool p1_3 = is_partition_1_0(g_groundtruth_0._data[uint(_S99)].pixels_0[i_4], _S98.ep0_0, _S98.ep1_0, _S98.ep2_0, _S98.ep3_0);
        if(p1_3)
        {

#line 129
            _S98.partition_logits_0.data_0[i_4] = -0.5;

#line 128
        }
        else
        {
            _S98.partition_logits_0.data_0[i_4] = 0.5;

#line 128
        }

#line 128
        bool p1_4;

#line 133
        if(_S100)
        {

#line 134
            snap_0(_S98);

#line 134
            p1_4 = (NonDifferentiableWeights_operatorx5Bx5D_get_0(_S98.partition_logits_0, i_4)) <= 0.0;

#line 133
        }
        else
        {

#line 133
            p1_4 = p1_3;

#line 133
        }

#line 133
        vec3 _S104;

#line 139
        if(p1_4)
        {

#line 139
            _S104 = _S98.ep0_0;

#line 139
        }
        else
        {

#line 139
            _S104 = _S98.ep2_0;

#line 139
        }

#line 139
        vec3 P_0 = _S103 - _S104;

#line 139
        vec3 D_0;
        if(p1_4)
        {

#line 140
            D_0 = _S101;

#line 140
        }
        else
        {

#line 140
            D_0 = _S102;

#line 140
        }


        _S98.weights_0.data_0[i_4] = saturate_0(dot(P_0, D_0) / (dot(D_0, D_0) + 9.99999997475242708e-07));

#line 125
        i_4 = i_4 + 1;

#line 125
    }

#line 145
    return;
}


#line 145
float loss_2P_0(uint _S105, CompressedTextureBlock2P_0 _S106)
{

#line 200
    TextureBlock_0 _S107 = decompress2P_0(_S106);

#line 200
    int i_5 = 0;

#line 200
    float totalError_0 = 0.0;


    for(;;)
    {

#line 203
        if(i_5 < 16)
        {
        }
        else
        {

#line 203
            break;
        }
        vec3 diff_1 = _S107.pixels_0[i_5] - g_groundtruth_0._data[uint(_S105)].pixels_0[i_5];
        float totalError_1 = totalError_0 + dot(diff_1, diff_1);

#line 203
        i_5 = i_5 + 1;

#line 203
        totalError_0 = totalError_1;

#line 203
    }

#line 209
    return totalError_0;
}




layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 217
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {

#line 218
        return;
    }

#line 219
    uvec2 _S108 = (clockRealtime2x32EXT());

#line 219
    g_diagnostics_0._data[uint(blockIdx_0)].start_clock_0 = _S108;

    CompressedTextureBlock2P_0 value_0 = g_compressedBlock2P_0._data[uint(blockIdx_0)];

    float _S109 = g_compress_step_params_0._data[uint(0)].learning_rate_0;
    uint steps_1 = g_compress_step_params_0._data[uint(0)].steps_0;
    uint _S110 = g_compress_step_params_0._data[uint(0)].steps_0 * 9U / 10U;
    uint _S111 = max(1U, g_compress_step_params_0._data[uint(0)].steps_0 / 20U);

#line 226
    int step_0 = 0;


    for(;;)
    {

#line 229
        if(step_0 < int(steps_1))
        {
        }
        else
        {

#line 229
            break;
        }
        CompressedTextureBlock2P_Differential_0 _S112 = CompressedTextureBlock2P_x24_syn_dzero_0();

#line 231
        DiffPair_CompressedTextureBlock2P_0 cb_pair_0;

#line 231
        cb_pair_0.primal_0 = value_0;

#line 231
        cb_pair_0.differential_0 = _S112;

#line 231
        s_bwd_loss_2P_0(blockIdx_0, cb_pair_0, 1.0);



        value_0.ep0_0 = value_0.ep0_0 - cb_pair_0.differential_0.ep0_1 * _S109;
        value_0.ep1_0 = value_0.ep1_0 - cb_pair_0.differential_0.ep1_1 * _S109;
        value_0.ep2_0 = value_0.ep2_0 - cb_pair_0.differential_0.ep2_1 * _S109;
        value_0.ep3_0 = value_0.ep3_0 - cb_pair_0.differential_0.ep3_1 * _S109;
        uint _S113 = uint(step_0);

#line 239
        bool _S114;

#line 239
        if(_S113 > _S110)
        {

#line 239
            _S114 = true;

#line 239
        }
        else
        {

#line 239
            _S114 = _S113 >= (steps_1 - 1U);

#line 239
        }

#line 239
        one_step_opt_0(value_0, blockIdx_0, _S114);

        uint _S115 = _S113 % _S111;

#line 241
        if(_S115 == 0U)
        {

#line 242
            uint iter_0 = _S113 / _S111;
            uvec2 _S116 = (clockRealtime2x32EXT());

#line 243
            g_diagnostics_0._data[uint(blockIdx_0)].timestamps_0[iter_0] = _S116;
            g_diagnostics_0._data[uint(blockIdx_0)].loss_log_0[iter_0] = loss_2P_0(blockIdx_0, value_0);

            uint raw_map_2 = pack_partition_indices_to_mask_0(value_0.partition_logits_0.data_0);



            g_diagnostics_0._data[uint(blockIdx_0)].partition_hamming_error_log_0[iter_0] = uint(hamming_distance_0(raw_map_2, g_lut_seed_to_mask_0._data[uint(g_lut_ideal_to_seed_0._data[uint(raw_map_2)])]));
            g_diagnostics_0._data[uint(blockIdx_0)].ideal_partition_log_0[iter_0] = raw_map_2;

#line 241
        }

#line 229
        step_0 = step_0 + 1;

#line 229
    }

#line 255
    uvec2 _S117 = (clockRealtime2x32EXT());

#line 255
    g_diagnostics_0._data[uint(blockIdx_0)].optim_ended_clock_0 = _S117;
    g_compressedBlock2P_0._data[uint(blockIdx_0)] = value_0;
    g_reconstructed_0._data[uint(blockIdx_0)] = decompress2P_0(value_0);
    g_diagnostics_0._data[uint(blockIdx_0)].partition_hamming_error_0 = uint(hamming_distance_0(value_0.ideal_partition_map_0, value_0.astc_partition_map_0));
    g_final_loss_0._data[uint(blockIdx_0)] = loss_2P_0(blockIdx_0, value_0);
    uvec2 _S118 = (clockRealtime2x32EXT());

#line 260
    g_diagnostics_0._data[uint(blockIdx_0)].finished_clock_0 = _S118;
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
};


#line 73
layout(std430, binding = 5) buffer StructuredBuffer_CompressStepParams_t_0 {
    CompressStepParams_0 _data[];
} g_compress_step_params_0;

#line 70
layout(std430, binding = 4) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 8
struct TextureBlock_0
{
    vec3  pixels_0[16];
};


#line 58
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


#line 67
layout(std430, binding = 3) buffer StructuredBuffer_CompressedTextureBlock2P_t_0 {
    CompressedTextureBlock2P_0 _data[];
} g_compressedBlock2P_0;

#line 31
float NonDifferentiableWeights_operatorx5Bx5D_get_0(NonDifferentiableWeights_0 this_0, int n_0)
{

#line 31
    return this_0.data_0[n_0];
}


#line 215
TextureBlock_0 decompress2P_0(uint _S1)
{

#line 215
    CompressedTextureBlock2P_0 _S2 = g_compressedBlock2P_0._data[uint(_S1)];

#line 183
    TextureBlock_0 outputBlock_0;

#line 183
    int i_0 = 0;
    for(;;)
    {

#line 184
        if(i_0 < 16)
        {
        }
        else
        {

#line 184
            break;
        }
        float _S3 = NonDifferentiableWeights_operatorx5Bx5D_get_0(_S2.weights_0, i_0);
        bool p1_0 = (NonDifferentiableWeights_operatorx5Bx5D_get_0(_S2.partition_logits_0, i_0)) <= 0.0;

#line 187
        vec3 e0_0;
        if(p1_0)
        {

#line 188
            e0_0 = _S2.ep0_0;

#line 188
        }
        else
        {

#line 188
            e0_0 = _S2.ep2_0;

#line 188
        }

#line 188
        vec3 e1_0;
        if(p1_0)
        {

#line 189
            e1_0 = _S2.ep1_0;

#line 189
        }
        else
        {

#line 189
            e1_0 = _S2.ep3_0;

#line 189
        }
        outputBlock_0.pixels_0[i_0] = mix(e0_0, e1_0, vec3(_S3));

#line 184
        i_0 = i_0 + 1;

#line 184
    }

#line 192
    return outputBlock_0;
}


#line 192
float loss_2P_0(uint _S4, uint _S5)
{

#line 192
    TextureBlock_0 _S6 = decompress2P_0(_S5);

#line 192
    int i_1 = 0;

#line 192
    float totalError_0 = 0.0;

#line 203
    for(;;)
    {

#line 203
        if(i_1 < 16)
        {
        }
        else
        {

#line 203
            break;
        }
        vec3 diff_0 = _S6.pixels_0[i_1] - g_groundtruth_0._data[uint(_S4)].pixels_0[i_1];
        float totalError_1 = totalError_0 + dot(diff_0, diff_0);

#line 203
        i_1 = i_1 + 1;

#line 203
        totalError_0 = totalError_1;

#line 203
    }

#line 209
    return totalError_0;
}


#line 265
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 267
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {

#line 268
        return;
    }

#line 269
    g_final_loss_0._data[uint(blockIdx_0)] = loss_2P_0(blockIdx_0, blockIdx_0);
    return;
}

