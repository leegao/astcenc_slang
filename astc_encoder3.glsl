#version 450
#extension GL_EXT_shader_realtime_clock : require
#extension GL_EXT_control_flow_attributes : require
layout(row_major) uniform;
layout(row_major) buffer;

#line 50 0
struct CompressStepParams_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
    uint snap_0;
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
struct CompressedTextureBlock3P_0
{
    vec3 ep0_0;
    vec3 ep1_0;
    vec3 ep2_0;
    vec3 ep3_0;
    vec3 ep4_0;
    vec3 ep5_0;
    NonDifferentiableWeights_0 weights_0;
    NonDifferentiableWeights_0 partition_logits_0;
    uint astc_partition_map_0;
    uint ideal_partition_map_0;
    uint astc_seed_0;
};


#line 69
layout(std430, binding = 3) buffer StructuredBuffer_CompressedTextureBlock3P_t_0 {
    CompressedTextureBlock3P_0 _data[];
} g_compressedBlock3P_0;

#line 8
struct TextureBlock_0
{
    vec3  pixels_0[16];
};


#line 60
layout(std430, binding = 0) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;

#line 81
struct LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
};


#line 86
layout(binding = 7)
layout(std140) uniform block_LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
}g_lut_0;

#line 63
layout(std430, binding = 1) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;

#line 72
layout(std430, binding = 4) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 90
struct PCG32_0
{
    uint state_0;
};


#line 94
PCG32_0 PCG32_x24init_0(uint seed_0)
{

#line 94
    PCG32_0 _S1;

    uint _S2 = seed_0 * 747796405U + 2891336453U;
    uint _S3 = ((_S2 >> ((_S2 >> 28U) + 4U)) ^ _S2) * 277803737U;
    _S1.state_0 = (_S3 >> 22U) ^ _S3;

#line 94
    return _S1;
}


#line 109
uint PCG32_nextUint_0(inout PCG32_0 this_0)
{
    uint oldState_0 = this_0.state_0;
    this_0.state_0 = this_0.state_0 * 747796405U + 2891336453U;
    uint word_0 = ((oldState_0 >> ((oldState_0 >> 28U) + 4U)) ^ oldState_0) * 277803737U;
    return (word_0 >> 22U) ^ word_0;
}


#line 114
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


#line 299 0
float dist_0(vec3 x_0, vec3 ep0_1, vec3 ep1_1)
{
    vec3 lineDir_0 = ep1_1 - ep0_1;

    return length(cross(x_0 - ep0_1, lineDir_0)) / length(lineDir_0);
}


#line 37
struct CompressedTextureBlock3P_Differential_0
{
    vec3 ep0_2;
    vec3 ep1_2;
    vec3 ep2_1;
    vec3 ep3_1;
    vec3 ep4_1;
    vec3 ep5_1;
};


#line 37
CompressedTextureBlock3P_Differential_0 CompressedTextureBlock3P_x24_syn_dzero_0()
{

#line 37
    CompressedTextureBlock3P_Differential_0 result_0;

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
    result_0.ep4_1 = _S4;

#line 2239
    result_0.ep5_1 = _S4;

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


#line 237 0
TextureBlock_0 decompress3P_0(CompressedTextureBlock3P_0 blockCoefficients_0)
{

#line 246
    TextureBlock_0 outputBlock_0;

#line 246
    uint i_0 = 0U;
    for(;;)
    {

#line 247
        if(i_0 < 16U)
        {
        }
        else
        {

#line 247
            break;
        }
        int _S9 = int(i_0);

#line 249
        float _S10 = NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_0.weights_0, _S9);
        int partition_0 = int(NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_0.partition_logits_0, _S9));
        bool _S11 = partition_0 == 0;

#line 251
        vec3 e0_0;

#line 251
        if(_S11)
        {

#line 251
            e0_0 = blockCoefficients_0.ep0_0;

#line 251
        }
        else
        {

#line 251
            if(partition_0 == 1)
            {

#line 251
                e0_0 = blockCoefficients_0.ep2_0;

#line 251
            }
            else
            {

#line 251
                e0_0 = blockCoefficients_0.ep4_0;

#line 251
            }

#line 251
        }

#line 251
        vec3 e1_0;
        if(_S11)
        {

#line 252
            e1_0 = blockCoefficients_0.ep1_0;

#line 252
        }
        else
        {

#line 252
            if(partition_0 == 1)
            {

#line 252
                e1_0 = blockCoefficients_0.ep3_0;

#line 252
            }
            else
            {

#line 252
                e1_0 = blockCoefficients_0.ep5_0;

#line 252
            }

#line 252
        }
        outputBlock_0.pixels_0[i_0] = mix(e0_0, e1_0, vec3(_S10));

#line 247
        i_0 = i_0 + 1U;

#line 247
    }

#line 255
    return outputBlock_0;
}


#line 13408 4
vec3 saturate_0(vec3 x_1)
{

#line 13416
    return clamp(x_1, vec3(0.0), vec3(1.0));
}


#line 173 0
float distSq_0(vec3 P_0, vec3 L_0, float pDotL_0, float invLenSq_0)
{

    return dot(P_0, P_0) - pDotL_0 * pDotL_0 * invLenSq_0;
}


uint get_partition_0(float d1_0, float d2_0, float d3_0)
{

#line 180
    bool _S12;

    if(d1_0 < d2_0)
    {

#line 182
        _S12 = d1_0 < d3_0;

#line 182
    }
    else
    {

#line 182
        _S12 = false;

#line 182
    }

#line 182
    if(_S12)
    {

#line 182
        return 0U;
    }

#line 183
    if(d2_0 < d3_0)
    {

#line 183
        return 1U;
    }

#line 184
    return 2U;
}


#line 225
uint pack_partition_indices_to_mask_0(float  p_logits_0[16])
{

#line 225
    int i_1 = 0;

#line 225
    uint raw_map_0 = 0U;


    for(;;)
    {

#line 228
        if(i_1 < 16)
        {
        }
        else
        {

#line 228
            break;
        }

        uint raw_map_1 = raw_map_0 | (uint(clamp(round(p_logits_0[i_1]), 0.0, 2.0)) << (i_1 * 2));

#line 228
        i_1 = i_1 + 1;

#line 228
        raw_map_0 = raw_map_1;

#line 228
    }

#line 233
    return raw_map_0;
}


#line 124
uint hamming_distance_2b_0(uint x_2, uint y_0)
{
    uint z_0 = x_2 ^ y_0;


    return bitCount((z_0 | (z_0 >> 1)) & 1431655765U);
}

uint get_closest_seed_0(uint input_0)
{

#line 132
    uint best_dist_0 = 16U;

#line 132
    uint closest_0 = 0U;

#line 132
    int seed_1 = 0;

#line 137
    [[unroll]]
    for(;;)
    {

#line 137
        if(seed_1 < 1024)
        {
        }
        else
        {

#line 137
            break;
        }
        uint dist_1 = hamming_distance_2b_0(g_lut_0.lut3_0[seed_1], input_0);

        if(dist_1 < best_dist_0)
        {

#line 142
            uint _S13 = uint(seed_1);

#line 142
            best_dist_0 = dist_1;

#line 142
            closest_0 = _S13;

#line 141
        }

#line 137
        seed_1 = seed_1 + 1;

#line 137
    }

#line 146
    return closest_0;
}


#line 156
void snap_1(inout CompressedTextureBlock3P_0 block_0)
{
    uint raw_map_2 = pack_partition_indices_to_mask_0(block_0.partition_logits_0.data_0);
    uint closest_seed_0 = get_closest_seed_0(raw_map_2);
    uint final_mask_0 = g_lut_0.lut3_0[closest_seed_0];

    block_0.astc_seed_0 = closest_seed_0;
    block_0.astc_partition_map_0 = final_mask_0;
    block_0.ideal_partition_map_0 = raw_map_2;

#line 164
    int i_2 = 0;


    for(;;)
    {

#line 167
        if(i_2 < 16)
        {
        }
        else
        {

#line 167
            break;
        }
        block_0.partition_logits_0.data_0[i_2] = float((final_mask_0 >> (2 * i_2)) & 3U);

#line 167
        i_2 = i_2 + 1;

#line 167
    }



    return;
}


#line 13393 4
float saturate_1(float x_3)
{

#line 13401
    return clamp(x_3, 0.0, 1.0);
}


#line 276 0
TextureBlock_0 reconstruct_0(CompressedTextureBlock3P_0 blockCoefficients_1, uint blockIdx_0)
{

#line 296
    return decompress3P_0(blockCoefficients_1);
}


#line 309
struct DiffPair_CompressedTextureBlock3P_0
{
    CompressedTextureBlock3P_0 primal_0;
    CompressedTextureBlock3P_Differential_0 differential_0;
};


#line 370
vec3 s_primal_ctx_lerp_0(vec3 _S14, vec3 _S15, vec3 _S16)
{

#line 370
    return mix(_S14, _S15, _S16);
}


#line 370
TextureBlock_0 s_primal_ctx_decompress3P_0(CompressedTextureBlock3P_0 dpblockCoefficients_0)
{

#line 246
    vec3 _S17 = vec3(0.0);

#line 246
    vec3  _S18[16] = { _S17, _S17, _S17, _S17, _S17, _S17, _S17, _S17, _S17, _S17, _S17, _S17, _S17, _S17, _S17, _S17 };

#line 246
    bool _runFlag_0 = true;

#line 246
    uint i_3 = 0U;

#line 246
    TextureBlock_0 outputBlock_1;

#line 246
    outputBlock_1.pixels_0 = _S18;

#line 246
    int _pc_0 = 0;
    for(;;)
    {

#line 247
        if(_runFlag_0)
        {
        }
        else
        {

#line 247
            break;
        }

#line 247
        int _S19;

#line 247
        if(i_3 < 16U)
        {
            int _S20 = int(i_3);

#line 249
            float _S21 = NonDifferentiableWeights_operatorx5Bx5D_get_0(dpblockCoefficients_0.weights_0, _S20);
            int partition_1 = int(NonDifferentiableWeights_operatorx5Bx5D_get_0(dpblockCoefficients_0.partition_logits_0, _S20));
            bool _S22 = partition_1 == 0;

#line 251
            vec3 e0_1;

#line 251
            if(_S22)
            {

#line 251
                e0_1 = dpblockCoefficients_0.ep0_0;

#line 251
            }
            else
            {

#line 251
                if(partition_1 == 1)
                {

#line 251
                    e0_1 = dpblockCoefficients_0.ep2_0;

#line 251
                }
                else
                {

#line 251
                    e0_1 = dpblockCoefficients_0.ep4_0;

#line 251
                }

#line 251
            }

#line 251
            vec3 e1_1;
            if(_S22)
            {

#line 252
                e1_1 = dpblockCoefficients_0.ep1_0;

#line 252
            }
            else
            {

#line 252
                if(partition_1 == 1)
                {

#line 252
                    e1_1 = dpblockCoefficients_0.ep3_0;

#line 252
                }
                else
                {

#line 252
                    e1_1 = dpblockCoefficients_0.ep5_0;

#line 252
                }

#line 252
            }

#line 252
            vec3 _S23 = s_primal_ctx_lerp_0(e0_1, e1_1, vec3(_S21));

#line 252
            TextureBlock_0 _S24 = outputBlock_1;

#line 252
            _S24.pixels_0[i_3] = _S23;

#line 252
            _S19 = 1;

#line 252
            outputBlock_1 = _S24;

#line 252
        }
        else
        {

#line 252
            _S19 = 0;

#line 252
        }

#line 252
        if(_S19 != 1)
        {

#line 252
            _runFlag_0 = false;

#line 252
        }

#line 252
        if(_runFlag_0)
        {

#line 252
            i_3 = i_3 + 1U;

#line 252
        }

#line 252
        _pc_0 = _pc_0 + 1;

#line 247
    }

#line 247
    return outputBlock_1;
}


#line 247
TextureBlock_0 TextureBlock_x24_syn_dzero_0()
{

#line 247
    TextureBlock_0 result_1;

#line 2239 2
    vec3 _S25 = vec3(0.0);

#line 2239
    result_1.pixels_0[0] = _S25;

#line 2239
    result_1.pixels_0[1] = _S25;

#line 2239
    result_1.pixels_0[2] = _S25;

#line 2239
    result_1.pixels_0[3] = _S25;

#line 2239
    result_1.pixels_0[4] = _S25;

#line 2239
    result_1.pixels_0[5] = _S25;

#line 2239
    result_1.pixels_0[6] = _S25;

#line 2239
    result_1.pixels_0[7] = _S25;

#line 2239
    result_1.pixels_0[8] = _S25;

#line 2239
    result_1.pixels_0[9] = _S25;

#line 2239
    result_1.pixels_0[10] = _S25;

#line 2239
    result_1.pixels_0[11] = _S25;

#line 2239
    result_1.pixels_0[12] = _S25;

#line 2239
    result_1.pixels_0[13] = _S25;

#line 2239
    result_1.pixels_0[14] = _S25;

#line 2239
    result_1.pixels_0[15] = _S25;

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
void s_bwd_prop_lerp_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S26, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S27, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S28, vec3 _S29)
{

#line 2239
    _d_lerp_vector_0(_S26, _S27, _S28, _S29);

#line 2239
    return;
}


#line 237 0
void s_bwd_prop_decompress3P_0(inout DiffPair_CompressedTextureBlock3P_0 dpblockCoefficients_1, TextureBlock_0 _s_dOut_0)
{

#line 237
    vec3 _S30 = dpblockCoefficients_1.primal_0.ep0_0;

#line 237
    vec3 _S31 = dpblockCoefficients_1.primal_0.ep1_0;

#line 237
    vec3 _S32 = dpblockCoefficients_1.primal_0.ep2_0;

#line 237
    vec3 _S33 = dpblockCoefficients_1.primal_0.ep3_0;

#line 237
    vec3 _S34 = dpblockCoefficients_1.primal_0.ep4_0;

#line 237
    vec3 _S35 = dpblockCoefficients_1.primal_0.ep5_0;

#line 237
    NonDifferentiableWeights_0 _S36 = dpblockCoefficients_1.primal_0.weights_0;

#line 237
    NonDifferentiableWeights_0 _S37 = dpblockCoefficients_1.primal_0.partition_logits_0;

#line 2239 2
    vec3 _S38 = vec3(0.0);

#line 246 0
    TextureBlock_0 _S39 = TextureBlock_x24_syn_dzero_0();

#line 246
    TextureBlock_0 _S40 = TextureBlock_x24_syn_dadd_0(_s_dOut_0, _S39);

#line 246
    int _dc_0 = 16;

#line 246
    TextureBlock_0 _S41 = _S40;

#line 246
    vec3 _S42 = _S38;

#line 246
    vec3 _S43 = _S38;

#line 246
    vec3 _S44 = _S38;

#line 246
    vec3 _S45 = _S38;

#line 246
    vec3 _S46 = _S38;

#line 246
    vec3 _S47 = _S38;

#line 246
    vec3 _S48 = _S38;
    for(;;)
    {

#line 247
        uint _S49 = uint(_dc_0);

#line 247
        if(_dc_0 >= 0)
        {
        }
        else
        {

#line 247
            break;
        }

#line 247
        bool _S50 = _S49 < 16U;

#line 247
        vec3 e0_2;

#line 247
        vec3 e1_2;

#line 247
        vec3 _S51;

#line 247
        bool _S52;

#line 247
        bool _S53;

#line 247
        bool _S54;

#line 247
        if(_S50)
        {
            int _S55 = int(_S49);

#line 249
            float _S56 = NonDifferentiableWeights_operatorx5Bx5D_get_0(_S36, _S55);
            int partition_2 = int(NonDifferentiableWeights_operatorx5Bx5D_get_0(_S37, _S55));
            bool _S57 = partition_2 == 0;

#line 251
            if(_S57)
            {

#line 251
                e0_2 = _S30;

#line 251
                _S52 = false;

#line 251
            }
            else
            {

#line 251
                bool _S58 = partition_2 == 1;

#line 251
                if(_S58)
                {

#line 251
                    e0_2 = _S32;

#line 251
                }
                else
                {

#line 251
                    e0_2 = _S34;

#line 251
                }

#line 251
                _S52 = _S58;

#line 251
            }
            if(_S57)
            {

#line 252
                e1_2 = _S31;

#line 252
                _S53 = false;

#line 252
            }
            else
            {

#line 252
                bool _S59 = partition_2 == 1;

#line 252
                if(_S59)
                {

#line 252
                    e1_2 = _S33;

#line 252
                }
                else
                {

#line 252
                    e1_2 = _S35;

#line 252
                }

#line 252
                _S53 = _S59;

#line 252
            }

#line 251
            bool _S60 = _S52;

#line 251
            _S51 = vec3(_S56);

#line 251
            _S52 = _S57;

#line 251
            _S54 = _S60;

#line 251
        }
        else
        {

#line 251
            e0_2 = _S38;

#line 251
            e1_2 = _S38;

#line 251
            _S51 = _S38;

#line 251
            _S52 = false;

#line 251
            _S53 = false;

#line 251
            _S54 = false;

#line 251
        }

#line 246
        TextureBlock_0 _S61 = TextureBlock_x24_syn_dadd_0(_S41, _S39);

#line 246
        if(_S50)
        {

#line 246
            TextureBlock_0 _S62 = _S61;

#line 246
            _S62.pixels_0[_S49] = _S38;

#line 253
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S63;

#line 253
            _S63.primal_0 = e0_2;

#line 253
            _S63.differential_0 = _S38;

#line 253
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S64;

#line 253
            _S64.primal_0 = e1_2;

#line 253
            _S64.differential_0 = _S38;

#line 253
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S65;

#line 253
            _S65.primal_0 = _S51;

#line 253
            _S65.differential_0 = _S38;

#line 253
            s_bwd_prop_lerp_0(_S63, _S64, _S65, _S61.pixels_0[_S49]);

#line 253
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S66 = _S64;

#line 246
            TextureBlock_0 _S67 = TextureBlock_x24_syn_dadd_0(_S62, _S39);

#line 251
            vec3 _S68 = _S63.differential_0 + _S48;

#line 251
            vec3 _S69;

#line 251
            vec3 _S70;

#line 251
            vec3 _S71;

#line 251
            if(_S52)
            {

#line 2246 2
                vec3 _S72 = _S66.differential_0 + _S46;

#line 2246
                _S69 = _S42;

#line 2246
                _S70 = _S44;

#line 2246
                _S71 = _S72;

#line 2246
            }
            else
            {

#line 2246
                if(_S53)
                {

#line 2246
                    vec3 _S73 = _S66.differential_0 + _S44;

#line 2246
                    _S69 = _S42;

#line 2246
                    _S70 = _S73;

#line 2246
                }
                else
                {

#line 2246
                    _S69 = _S66.differential_0 + _S42;

#line 2246
                    _S70 = _S44;

#line 2246
                }

#line 2246
                _S71 = _S46;

#line 2246
            }

#line 2246
            vec3 _S74;

#line 2246
            vec3 _S75;

#line 2246
            vec3 _S76;

#line 2246
            if(_S52)
            {

#line 2246
                vec3 _S77 = _S68 + _S47;

#line 2246
                _S74 = _S43;

#line 2246
                _S75 = _S45;

#line 2246
                _S76 = _S77;

#line 2246
            }
            else
            {

#line 2246
                if(_S54)
                {

#line 2246
                    vec3 _S78 = _S68 + _S45;

#line 2246
                    _S74 = _S43;

#line 2246
                    _S75 = _S78;

#line 2246
                }
                else
                {

#line 2246
                    _S74 = _S68 + _S43;

#line 2246
                    _S75 = _S45;

#line 2246
                }

#line 2246
                _S76 = _S47;

#line 2246
            }

#line 2246
            _S41 = _S67;

#line 2246
            _S42 = _S69;

#line 2246
            _S43 = _S74;

#line 2246
            _S44 = _S70;

#line 2246
            _S45 = _S75;

#line 2246
            _S46 = _S71;

#line 2246
            _S47 = _S76;

#line 2246
            _S48 = _S38;

#line 2246
        }
        else
        {

#line 2246
            _S41 = TextureBlock_x24_syn_dadd_0(_S61, _S39);

#line 2246
        }

#line 2246
        _dc_0 = _dc_0 - 1;

#line 247 0
    }

#line 247
    CompressedTextureBlock3P_Differential_0 _S79 = CompressedTextureBlock3P_x24_syn_dzero_0();

#line 247
    _S79.ep5_1 = _S42;

#line 247
    _S79.ep4_1 = _S43;

#line 247
    _S79.ep3_1 = _S44;

#line 247
    _S79.ep2_1 = _S45;

#line 247
    _S79.ep1_2 = _S46;

#line 247
    _S79.ep0_2 = _S47;

#line 247
    dpblockCoefficients_1.primal_0 = dpblockCoefficients_1.primal_0;

#line 247
    dpblockCoefficients_1.differential_0 = _S79;

#line 237
    return;
}


#line 237
void s_bwd_prop_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S80, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S81, float _S82)
{

#line 237
    _d_dot_0(_S80, _S81, _S82);

#line 237
    return;
}


#line 237
void s_bwd_prop_loss_3P_0(uint _S83, inout DiffPair_CompressedTextureBlock3P_0 _S84, float _S85)
{

#line 237
    CompressedTextureBlock3P_0 _S86 = _S84.primal_0;

#line 237
    TextureBlock_0 _S87 = s_primal_ctx_decompress3P_0(_S84.primal_0);

#line 2239 2
    vec3 _S88 = vec3(0.0);

#line 2239
    int _dc_1 = 16;

#line 2239
    float _S89 = _S85;

#line 2239
    vec3  _S90[16];

#line 2239
    _S90[0] = _S88;

#line 2239
    _S90[1] = _S88;

#line 2239
    _S90[2] = _S88;

#line 2239
    _S90[3] = _S88;

#line 2239
    _S90[4] = _S88;

#line 2239
    _S90[5] = _S88;

#line 2239
    _S90[6] = _S88;

#line 2239
    _S90[7] = _S88;

#line 2239
    _S90[8] = _S88;

#line 2239
    _S90[9] = _S88;

#line 2239
    _S90[10] = _S88;

#line 2239
    _S90[11] = _S88;

#line 2239
    _S90[12] = _S88;

#line 2239
    _S90[13] = _S88;

#line 2239
    _S90[14] = _S88;

#line 2239
    _S90[15] = _S88;

#line 266 0
    for(;;)
    {

#line 266
        if(_dc_1 >= 0)
        {
        }
        else
        {

#line 266
            break;
        }

#line 266
        bool _S91 = _dc_1 < 16;

#line 266
        int _S92;

#line 266
        vec3 _S93;

#line 266
        if(_S91)
        {
            vec3 diff_0 = _S87.pixels_0[_dc_1] - g_groundtruth_0._data[uint(_S83)].pixels_0[_dc_1];

#line 268
            _S92 = 1;

#line 268
            _S93 = diff_0;

#line 268
        }
        else
        {

#line 268
            _S92 = 0;

#line 268
            _S93 = _S88;

#line 268
        }

#line 268
        float _S94;

#line 268
        float _S95;

#line 268
        if(!(_S92 != 1))
        {

#line 268
            _S94 = _S89;

#line 268
            _S95 = 0.0;

#line 268
        }
        else
        {

#line 268
            _S94 = 0.0;

#line 268
            _S95 = _S89;

#line 268
        }

#line 268
        if(_S91)
        {

#line 269
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S96;

#line 269
            _S96.primal_0 = _S93;

#line 269
            _S96.differential_0 = _S88;

#line 269
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S97;

#line 269
            _S97.primal_0 = _S93;

#line 269
            _S97.differential_0 = _S88;

#line 269
            s_bwd_prop_dot_0(_S96, _S97, _S94);

#line 268
            vec3 _S98 = _S97.differential_0 + _S96.differential_0;

#line 264
            float _S99 = _S94 + _S95;

#line 264
            vec3  _S100[16];

#line 264
            _S100[0] = _S88;

#line 264
            _S100[1] = _S88;

#line 264
            _S100[2] = _S88;

#line 264
            _S100[3] = _S88;

#line 264
            _S100[4] = _S88;

#line 264
            _S100[5] = _S88;

#line 264
            _S100[6] = _S88;

#line 264
            _S100[7] = _S88;

#line 264
            _S100[8] = _S88;

#line 264
            _S100[9] = _S88;

#line 264
            _S100[10] = _S88;

#line 264
            _S100[11] = _S88;

#line 264
            _S100[12] = _S88;

#line 264
            _S100[13] = _S88;

#line 264
            _S100[14] = _S88;

#line 264
            _S100[15] = _S88;

#line 264
            _S100[_dc_1] = _S98;

#line 2246 2
            vec3 _S101 = _S90[0] + _S100[0];

#line 2246
            vec3 _S102 = _S90[1] + _S100[1];

#line 2246
            vec3 _S103 = _S90[2] + _S100[2];

#line 2246
            vec3 _S104 = _S90[3] + _S100[3];

#line 2246
            vec3 _S105 = _S90[4] + _S100[4];

#line 2246
            vec3 _S106 = _S90[5] + _S100[5];

#line 2246
            vec3 _S107 = _S90[6] + _S100[6];

#line 2246
            vec3 _S108 = _S90[7] + _S100[7];

#line 2246
            vec3 _S109 = _S90[8] + _S100[8];

#line 2246
            vec3 _S110 = _S90[9] + _S100[9];

#line 2246
            vec3 _S111 = _S90[10] + _S100[10];

#line 2246
            vec3 _S112 = _S90[11] + _S100[11];

#line 2246
            vec3 _S113 = _S90[12] + _S100[12];

#line 2246
            vec3 _S114 = _S90[13] + _S100[13];

#line 2246
            vec3 _S115 = _S90[14] + _S100[14];

#line 2246
            vec3 _S116 = _S90[15] + _S100[15];

#line 2246
            _S89 = _S99;

#line 2246
            _S90[0] = _S101;

#line 2246
            _S90[1] = _S102;

#line 2246
            _S90[2] = _S103;

#line 2246
            _S90[3] = _S104;

#line 2246
            _S90[4] = _S105;

#line 2246
            _S90[5] = _S106;

#line 2246
            _S90[6] = _S107;

#line 2246
            _S90[7] = _S108;

#line 2246
            _S90[8] = _S109;

#line 2246
            _S90[9] = _S110;

#line 2246
            _S90[10] = _S111;

#line 2246
            _S90[11] = _S112;

#line 2246
            _S90[12] = _S113;

#line 2246
            _S90[13] = _S114;

#line 2246
            _S90[14] = _S115;

#line 2246
            _S90[15] = _S116;

#line 2246
        }
        else
        {

#line 2246
            _S89 = _S95;

#line 2246
        }

#line 2246
        _dc_1 = _dc_1 - 1;

#line 266 0
    }

#line 263
    TextureBlock_0 _S117 = TextureBlock_x24_syn_dzero_0();

#line 263
    _S117.pixels_0 = _S90;

#line 263
    CompressedTextureBlock3P_Differential_0 _S118 = CompressedTextureBlock3P_x24_syn_dzero_0();

#line 263
    DiffPair_CompressedTextureBlock3P_0 _S119;

#line 263
    _S119.primal_0 = _S86;

#line 263
    _S119.differential_0 = _S118;

#line 263
    s_bwd_prop_decompress3P_0(_S119, _S117);

#line 263
    _S84.primal_0 = _S84.primal_0;

#line 263
    _S84.differential_0 = _S119.differential_0;

#line 259
    return;
}


#line 259
void s_bwd_loss_3P_0(uint _S120, inout DiffPair_CompressedTextureBlock3P_0 _S121, float _S122)
{

#line 259
    s_bwd_prop_loss_3P_0(_S120, _S121, _S122);

#line 259
    return;
}


#line 259
void one_step_opt_0(inout CompressedTextureBlock3P_0 _S123, uint _S124, bool _S125)
{

#line 190
    vec3 L1_0 = _S123.ep1_0 - _S123.ep0_0;
    vec3 L2_0 = _S123.ep3_0 - _S123.ep2_0;
    vec3 L3_0 = _S123.ep5_0 - _S123.ep4_0;
    float _S126 = 1.0 / (dot(L1_0, L1_0) + 9.99999997475242708e-07);
    float _S127 = 1.0 / (dot(L2_0, L2_0) + 9.99999997475242708e-07);
    float _S128 = 1.0 / (dot(L3_0, L3_0) + 9.99999997475242708e-07);

#line 195
    int i_4 = 0;

    for(;;)
    {

#line 197
        if(i_4 < 16)
        {
        }
        else
        {

#line 197
            break;
        }

        vec3 P1_0 = g_groundtruth_0._data[uint(_S124)].pixels_0[i_4] - _S123.ep0_0;
        vec3 P2_0 = g_groundtruth_0._data[uint(_S124)].pixels_0[i_4] - _S123.ep2_0;
        vec3 P3_0 = g_groundtruth_0._data[uint(_S124)].pixels_0[i_4] - _S123.ep4_0;
        float pDotL1_0 = dot(P1_0, L1_0);
        float pDotL2_0 = dot(P2_0, L2_0);
        float pDotL3_0 = dot(P3_0, L3_0);



        uint partition_3 = get_partition_0(distSq_0(P1_0, L1_0, pDotL1_0, _S126), distSq_0(P2_0, L2_0, pDotL2_0, _S127), distSq_0(P3_0, L3_0, pDotL3_0, _S128));
        _S123.partition_logits_0.data_0[i_4] = float(partition_3);

#line 210
        uint partition_4;
        if(_S125)
        {

#line 212
            snap_1(_S123);

#line 212
            partition_4 = uint(int(NonDifferentiableWeights_operatorx5Bx5D_get_0(_S123.partition_logits_0, i_4)));

#line 211
        }
        else
        {

#line 211
            partition_4 = partition_3;

#line 211
        }

#line 216
        bool _S129 = partition_4 == 0U;

#line 216
        float pDotL_1;

#line 216
        if(_S129)
        {

#line 216
            pDotL_1 = pDotL1_0;

#line 216
        }
        else
        {

#line 216
            if(partition_4 == 1U)
            {

#line 216
                pDotL_1 = pDotL2_0;

#line 216
            }
            else
            {

#line 216
                pDotL_1 = pDotL3_0;

#line 216
            }

#line 216
        }

#line 216
        float invLenSq_1;
        if(_S129)
        {

#line 217
            invLenSq_1 = _S126;

#line 217
        }
        else
        {

#line 217
            if(partition_4 == 1U)
            {

#line 217
                invLenSq_1 = _S127;

#line 217
            }
            else
            {

#line 217
                invLenSq_1 = _S128;

#line 217
            }

#line 217
        }


        _S123.weights_0.data_0[i_4] = saturate_1(pDotL_1 * invLenSq_1);

#line 197
        i_4 = i_4 + 1;

#line 197
    }

#line 222
    return;
}


#line 222
float loss_3P_0(uint _S130, CompressedTextureBlock3P_0 _S131)
{

#line 263
    TextureBlock_0 _S132 = decompress3P_0(_S131);

#line 263
    int i_5 = 0;

#line 263
    float totalError_0 = 0.0;


    for(;;)
    {

#line 266
        if(i_5 < 16)
        {
        }
        else
        {

#line 266
            break;
        }
        vec3 diff_1 = _S132.pixels_0[i_5] - g_groundtruth_0._data[uint(_S130)].pixels_0[i_5];
        float totalError_1 = totalError_0 + dot(diff_1, diff_1);

#line 266
        i_5 = i_5 + 1;

#line 266
        totalError_0 = totalError_1;

#line 266
    }

#line 272
    return totalError_0;
}


#line 309
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 311
    uint blockIdx_1 = gl_GlobalInvocationID.x;
    if(blockIdx_1 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {

#line 312
        return;
    }

#line 313
    uvec2 _S133 = (clockRealtime2x32EXT());

#line 313
    g_diagnostics_0._data[uint(blockIdx_1)].start_clock_0 = _S133;

    CompressedTextureBlock3P_0 value_0 = g_compressedBlock3P_0._data[uint(blockIdx_1)];

    float _S134 = g_compress_step_params_0._data[uint(0)].learning_rate_0;
    uint steps_1 = g_compress_step_params_0._data[uint(0)].steps_0;
    bool _S135 = (g_compress_step_params_0._data[uint(0)].snap_0) > 0U;
    uint _S136 = uint(float(g_compress_step_params_0._data[uint(0)].steps_0) * 0.69999998807907104);
    uint _S137 = max(1U, g_compress_step_params_0._data[uint(0)].steps_0 / 20U);

#line 326
    PCG32_0 prng_0 = PCG32_x24init_0(0U);
    uint _S138 = PCG32_nextUint_0(prng_0);

#line 327
    value_0.ep0_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S138 % 16U];
    uint _S139 = PCG32_nextUint_0(prng_0);

#line 328
    value_0.ep1_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S139 % 16U];

#line 328
    int i_6 = 0;
    for(;;)
    {

#line 329
        if(i_6 < 8)
        {
        }
        else
        {

#line 329
            break;
        }

#line 330
        uint _S140 = PCG32_nextUint_0(prng_0);

#line 330
        value_0.ep1_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S140 % 16U];
        vec3 d_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S140 % 16U] - value_0.ep0_0;
        if((dot(d_0, d_0)) > 0.30000001192092896)
        {

#line 333
            break;
        }

#line 329
        i_6 = i_6 + 1;

#line 329
    }

#line 329
    i_6 = 0;

#line 336
    for(;;)
    {

#line 336
        if(i_6 < 8)
        {
        }
        else
        {

#line 336
            break;
        }

#line 337
        uint _S141 = PCG32_nextUint_0(prng_0);

#line 337
        value_0.ep2_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S141 % 16U];
        if((dist_0(g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S141 % 16U], value_0.ep0_0, value_0.ep1_0)) > 0.30000001192092896)
        {

#line 339
            break;
        }

#line 336
        i_6 = i_6 + 1;

#line 336
    }

#line 336
    i_6 = 0;

#line 342
    for(;;)
    {

#line 342
        if(i_6 < 8)
        {
        }
        else
        {

#line 342
            break;
        }

#line 343
        uint _S142 = PCG32_nextUint_0(prng_0);

#line 343
        value_0.ep3_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S142 % 16U];
        if((dist_0(g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S142 % 16U], value_0.ep0_0, value_0.ep1_0)) > 0.30000001192092896)
        {

#line 345
            break;
        }

#line 342
        i_6 = i_6 + 1;

#line 342
    }

#line 342
    i_6 = 0;

#line 348
    for(;;)
    {

#line 348
        if(i_6 < 8)
        {
        }
        else
        {

#line 348
            break;
        }

#line 349
        uint _S143 = PCG32_nextUint_0(prng_0);

#line 349
        value_0.ep4_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S143 % 16U];
        if((dist_0(g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S143 % 16U], value_0.ep0_0, value_0.ep1_0)) <= 0.30000001192092896)
        {

#line 351
            i_6 = i_6 + 1;

#line 348
            continue;
        }



        if((dist_0(value_0.ep4_0, value_0.ep2_0, value_0.ep3_0)) > 0.30000001192092896)
        {

#line 354
            break;
        }

#line 348
        i_6 = i_6 + 1;

#line 348
    }

#line 348
    i_6 = 0;

#line 357
    for(;;)
    {

#line 357
        if(i_6 < 8)
        {
        }
        else
        {

#line 357
            break;
        }

#line 358
        uint _S144 = PCG32_nextUint_0(prng_0);

#line 358
        value_0.ep5_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S144 % 16U];
        if((dist_0(g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S144 % 16U], value_0.ep0_0, value_0.ep1_0)) <= 0.30000001192092896)
        {

#line 360
            i_6 = i_6 + 1;

#line 357
            continue;
        }



        if((dist_0(value_0.ep5_0, value_0.ep2_0, value_0.ep3_0)) > 0.30000001192092896)
        {

#line 363
            break;
        }

#line 357
        i_6 = i_6 + 1;

#line 357
    }

#line 357
    int step_0 = 0;

#line 367
    for(;;)
    {

#line 367
        if(step_0 < int(steps_1))
        {
        }
        else
        {

#line 367
            break;
        }
        CompressedTextureBlock3P_Differential_0 _S145 = CompressedTextureBlock3P_x24_syn_dzero_0();

#line 369
        DiffPair_CompressedTextureBlock3P_0 cb_pair_0;

#line 369
        cb_pair_0.primal_0 = value_0;

#line 369
        cb_pair_0.differential_0 = _S145;

#line 369
        s_bwd_loss_3P_0(blockIdx_1, cb_pair_0, 1.0);



        value_0.ep0_0 = saturate_0(value_0.ep0_0 - cb_pair_0.differential_0.ep0_2 * _S134);
        value_0.ep1_0 = saturate_0(value_0.ep1_0 - cb_pair_0.differential_0.ep1_2 * _S134);
        value_0.ep2_0 = saturate_0(value_0.ep2_0 - cb_pair_0.differential_0.ep2_1 * _S134);
        value_0.ep3_0 = saturate_0(value_0.ep3_0 - cb_pair_0.differential_0.ep3_1 * _S134);
        value_0.ep4_0 = saturate_0(value_0.ep4_0 - cb_pair_0.differential_0.ep4_1 * _S134);
        value_0.ep5_0 = saturate_0(value_0.ep5_0 - cb_pair_0.differential_0.ep5_1 * _S134);

#line 378
        bool _S146;
        if(_S135)
        {

#line 379
            uint _S147 = uint(step_0);

#line 379
            if(_S147 > _S136)
            {

#line 379
                _S146 = true;

#line 379
            }
            else
            {

#line 379
                _S146 = _S147 >= (steps_1 - 1U);

#line 379
            }

#line 379
        }
        else
        {

#line 379
            _S146 = false;

#line 379
        }

#line 379
        one_step_opt_0(value_0, blockIdx_1, _S146);

        uint _S148 = uint(step_0);

#line 381
        uint _S149 = _S148 % _S137;

#line 381
        if(_S149 == 0U)
        {

#line 382
            uint iter_0 = _S148 / _S137;
            uvec2 _S150 = (clockRealtime2x32EXT());

#line 383
            g_diagnostics_0._data[uint(blockIdx_1)].timestamps_0[iter_0] = _S150;
            g_diagnostics_0._data[uint(blockIdx_1)].loss_log_0[iter_0] = loss_3P_0(blockIdx_1, value_0);

            uint raw_map_3 = pack_partition_indices_to_mask_0(value_0.partition_logits_0.data_0);



            g_diagnostics_0._data[uint(blockIdx_1)].partition_hamming_error_log_0[iter_0] = hamming_distance_2b_0(raw_map_3, g_lut_0.lut3_0[get_closest_seed_0(raw_map_3)]);
            g_diagnostics_0._data[uint(blockIdx_1)].ideal_partition_log_0[iter_0] = raw_map_3;

#line 381
        }

#line 367
        step_0 = step_0 + 1;

#line 367
    }

#line 395
    uvec2 _S151 = (clockRealtime2x32EXT());

#line 395
    g_diagnostics_0._data[uint(blockIdx_1)].optim_ended_clock_0 = _S151;
    g_compressedBlock3P_0._data[uint(blockIdx_1)] = value_0;
    g_reconstructed_0._data[uint(blockIdx_1)] = reconstruct_0(value_0, blockIdx_1);
    g_diagnostics_0._data[uint(blockIdx_1)].partition_hamming_error_0 = hamming_distance_2b_0(value_0.ideal_partition_map_0, value_0.astc_partition_map_0);
    g_final_loss_0._data[uint(blockIdx_1)] = loss_3P_0(blockIdx_1, value_0);
    uvec2 _S152 = (clockRealtime2x32EXT());

#line 400
    g_diagnostics_0._data[uint(blockIdx_1)].finished_clock_0 = _S152;
    return;
}

#version 450
layout(row_major) uniform;
layout(row_major) buffer;

#line 50 0
struct CompressStepParams_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
    uint snap_0;
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
struct CompressedTextureBlock3P_0
{
    vec3 ep0_0;
    vec3 ep1_0;
    vec3 ep2_0;
    vec3 ep3_0;
    vec3 ep4_0;
    vec3 ep5_0;
    NonDifferentiableWeights_0 weights_0;
    NonDifferentiableWeights_0 partition_logits_0;
    uint astc_partition_map_0;
    uint ideal_partition_map_0;
    uint astc_seed_0;
};


#line 69
layout(std430, binding = 3) buffer StructuredBuffer_CompressedTextureBlock3P_t_0 {
    CompressedTextureBlock3P_0 _data[];
} g_compressedBlock3P_0;

#line 31
float NonDifferentiableWeights_operatorx5Bx5D_get_0(NonDifferentiableWeights_0 this_0, int n_0)
{

#line 31
    return this_0.data_0[n_0];
}


#line 309
TextureBlock_0 decompress3P_0(uint _S1)
{

#line 309
    CompressedTextureBlock3P_0 _S2 = g_compressedBlock3P_0._data[uint(_S1)];

#line 246
    TextureBlock_0 outputBlock_0;

#line 246
    uint i_0 = 0U;
    for(;;)
    {

#line 247
        if(i_0 < 16U)
        {
        }
        else
        {

#line 247
            break;
        }
        int _S3 = int(i_0);

#line 249
        float _S4 = NonDifferentiableWeights_operatorx5Bx5D_get_0(_S2.weights_0, _S3);
        int partition_0 = int(NonDifferentiableWeights_operatorx5Bx5D_get_0(_S2.partition_logits_0, _S3));
        bool _S5 = partition_0 == 0;

#line 251
        vec3 e0_0;

#line 251
        if(_S5)
        {

#line 251
            e0_0 = _S2.ep0_0;

#line 251
        }
        else
        {

#line 251
            if(partition_0 == 1)
            {

#line 251
                e0_0 = _S2.ep2_0;

#line 251
            }
            else
            {

#line 251
                e0_0 = _S2.ep4_0;

#line 251
            }

#line 251
        }

#line 251
        vec3 e1_0;
        if(_S5)
        {

#line 252
            e1_0 = _S2.ep1_0;

#line 252
        }
        else
        {

#line 252
            if(partition_0 == 1)
            {

#line 252
                e1_0 = _S2.ep3_0;

#line 252
            }
            else
            {

#line 252
                e1_0 = _S2.ep5_0;

#line 252
            }

#line 252
        }
        outputBlock_0.pixels_0[i_0] = mix(e0_0, e1_0, vec3(_S4));

#line 247
        i_0 = i_0 + 1U;

#line 247
    }

#line 255
    return outputBlock_0;
}


#line 255
float loss_3P_0(uint _S6, uint _S7)
{

#line 255
    TextureBlock_0 _S8 = decompress3P_0(_S7);

#line 255
    int i_1 = 0;

#line 255
    float totalError_0 = 0.0;

#line 266
    for(;;)
    {

#line 266
        if(i_1 < 16)
        {
        }
        else
        {

#line 266
            break;
        }
        vec3 diff_0 = _S8.pixels_0[i_1] - g_groundtruth_0._data[uint(_S6)].pixels_0[i_1];
        float totalError_1 = totalError_0 + dot(diff_0, diff_0);

#line 266
        i_1 = i_1 + 1;

#line 266
        totalError_0 = totalError_1;

#line 266
    }

#line 272
    return totalError_0;
}


#line 405
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 407
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {

#line 408
        return;
    }

#line 409
    g_final_loss_0._data[uint(blockIdx_0)] = loss_3P_0(blockIdx_0, blockIdx_0);
    return;
}

