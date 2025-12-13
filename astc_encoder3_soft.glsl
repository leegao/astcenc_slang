#version 450
#extension GL_EXT_shader_realtime_clock : require
#extension GL_EXT_control_flow_attributes : require
layout(row_major) uniform;
layout(row_major) buffer;

#line 51 0
struct CompressStepParams_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
    uint snap_0;
};


#line 76
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


#line 67
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
    uint perm_0;
};


#line 70
layout(std430, binding = 3) buffer StructuredBuffer_CompressedTextureBlock3P_t_0 {
    CompressedTextureBlock3P_0 _data[];
} g_compressedBlock3P_0;

#line 8
struct TextureBlock_0
{
    vec3  pixels_0[16];
};


#line 61
layout(std430, binding = 0) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;

#line 82
struct LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
};


#line 87
layout(binding = 7)
layout(std140) uniform block_LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
}g_lut_0;

#line 64
layout(std430, binding = 1) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;

#line 73
layout(std430, binding = 4) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 91
struct PCG32_0
{
    uint state_0;
};


#line 95
PCG32_0 PCG32_x24init_0(uint seed_0)
{

#line 95
    PCG32_0 _S1;

    uint _S2 = seed_0 * 747796405U + 2891336453U;
    uint _S3 = ((_S2 >> ((_S2 >> 28U) + 4U)) ^ _S2) * 277803737U;
    _S1.state_0 = (_S3 >> 22U) ^ _S3;

#line 95
    return _S1;
}


#line 110
uint PCG32_nextUint_0(inout PCG32_0 this_0)
{
    uint oldState_0 = this_0.state_0;
    this_0.state_0 = this_0.state_0 * 747796405U + 2891336453U;
    uint word_0 = ((oldState_0 >> ((oldState_0 >> 28U) + 4U)) ^ oldState_0) * 277803737U;
    return (word_0 >> 22U) ^ word_0;
}


#line 115
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


#line 504 0
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


#line 442 0
TextureBlock_0 decompress3P_0(CompressedTextureBlock3P_0 blockCoefficients_0)
{

#line 451
    TextureBlock_0 outputBlock_0;

#line 451
    uint i_0 = 0U;
    for(;;)
    {

#line 452
        if(i_0 < 16U)
        {
        }
        else
        {

#line 452
            break;
        }
        int _S9 = int(i_0);

#line 454
        float _S10 = NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_0.weights_0, _S9);
        int partition_0 = int(NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_0.partition_logits_0, _S9));
        bool _S11 = partition_0 == 0;

#line 456
        vec3 e0_0;

#line 456
        if(_S11)
        {

#line 456
            e0_0 = blockCoefficients_0.ep0_0;

#line 456
        }
        else
        {

#line 456
            if(partition_0 == 1)
            {

#line 456
                e0_0 = blockCoefficients_0.ep2_0;

#line 456
            }
            else
            {

#line 456
                e0_0 = blockCoefficients_0.ep4_0;

#line 456
            }

#line 456
        }

#line 456
        vec3 e1_0;
        if(_S11)
        {

#line 457
            e1_0 = blockCoefficients_0.ep1_0;

#line 457
        }
        else
        {

#line 457
            if(partition_0 == 1)
            {

#line 457
                e1_0 = blockCoefficients_0.ep3_0;

#line 457
            }
            else
            {

#line 457
                e1_0 = blockCoefficients_0.ep5_0;

#line 457
            }

#line 457
        }
        outputBlock_0.pixels_0[i_0] = mix(e0_0, e1_0, vec3(_S10));

#line 452
        i_0 = i_0 + 1U;

#line 452
    }

#line 460
    return outputBlock_0;
}


#line 13408 4
vec3 saturate_0(vec3 x_1)
{

#line 13416
    return clamp(x_1, vec3(0.0), vec3(1.0));
}


#line 362 0
float distSq_0(vec3 P_0, vec3 L_0, float pDotL_0, float invLenSq_0)
{

    return dot(P_0, P_0) - pDotL_0 * pDotL_0 * invLenSq_0;
}


uint get_partition_0(float d1_0, float d2_0, float d3_0)
{

#line 369
    bool _S12;

    if(d1_0 < d2_0)
    {

#line 371
        _S12 = d1_0 < d3_0;

#line 371
    }
    else
    {

#line 371
        _S12 = false;

#line 371
    }

#line 371
    if(_S12)
    {

#line 371
        return 0U;
    }

#line 372
    if(d2_0 < d3_0)
    {

#line 372
        return 1U;
    }

#line 373
    return 2U;
}


#line 430
uint pack_partition_indices_to_mask_0(float  p_logits_0[16])
{

#line 430
    int i_1 = 0;

#line 430
    uint raw_map_0 = 0U;


    for(;;)
    {

#line 433
        if(i_1 < 16)
        {
        }
        else
        {

#line 433
            break;
        }

        uint raw_map_1 = raw_map_0 | (uint(clamp(round(p_logits_0[i_1]), 0.0, 2.0)) << (i_1 * 2));

#line 433
        i_1 = i_1 + 1;

#line 433
        raw_map_0 = raw_map_1;

#line 433
    }

#line 438
    return raw_map_0;
}


#line 133
uint count_diffs_0(uint val_0)
{
    return bitCount((val_0 | (val_0 >> 1)) & 1431655765U);
}


#line 142
uint best_perm_distance_0(uint x_2, uint y_0, out uint perm_1)
{
    uint base_0 = x_2 ^ y_0;

    uint x_shr1_0 = x_2 >> 1;
    uint nz_0 = (x_2 | x_shr1_0) & 1431655765U;
    uint nz_shl1_0 = nz_0 << 1;

    uint m01_0 = (~x_shr1_0) & 1431655765U;

#line 166
    uint best_0 = min(min(min(((count_diffs_0(base_0)) << 3) | 0U, ((count_diffs_0(base_0 ^ m01_0)) << 3) | 1U), min(((count_diffs_0(base_0 ^ ((~(x_2 << 1)) & 2863311530U))) << 3) | 2U, ((count_diffs_0(base_0 ^ (nz_0 | nz_shl1_0))) << 3) | 3U)), min(((count_diffs_0(base_0 ^ (m01_0 | nz_shl1_0))) << 3) | 4U, ((count_diffs_0(base_0 ^ (nz_0 | (((~x_2) & 1431655765U) << 1)))) << 3) | 5U));

    perm_1 = best_0 & 7U;
    return best_0 >> 3;
}


#line 125
uint hamming_distance_2b_0(uint x_3, uint y_1)
{
    uint z_0 = x_3 ^ y_1;


    return bitCount((z_0 | (z_0 >> 1)) & 1431655765U);
}


#line 233
uvec2 get_closest_seed_0(uint input_0, bool can_permute_0)
{

#line 233
    uint best_dist_0 = 16U;

#line 233
    uint closest_0 = 0U;

#line 233
    uint best_perm_0 = 0U;

#line 233
    int seed_1 = 0;

#line 239
    [[unroll]]
    for(;;)
    {

#line 239
        if(seed_1 < 1024)
        {
        }
        else
        {

#line 239
            break;
        }

#line 240
        uint pattern_0 = g_lut_0.lut3_0[seed_1];

        uint perm_2 = 0U;

#line 242
        uint dist_1;
        if(can_permute_0)
        {

#line 243
            uint _S13 = best_perm_distance_0(input_0, pattern_0, perm_2);

#line 243
            dist_1 = _S13;

#line 243
        }
        else
        {

#line 243
            dist_1 = hamming_distance_2b_0(input_0, pattern_0);

#line 243
        }

#line 243
        bool _S14;


        if(dist_1 < best_dist_0)
        {

#line 246
            _S14 = pattern_0 != 0U;

#line 246
        }
        else
        {

#line 246
            _S14 = false;

#line 246
        }

#line 246
        bool _S15;

#line 246
        if(_S14)
        {

#line 246
            _S15 = pattern_0 != 1431655765U;

#line 246
        }
        else
        {

#line 246
            _S15 = false;

#line 246
        }

#line 246
        bool _S16;

#line 246
        if(_S15)
        {

#line 246
            _S16 = pattern_0 != 2863311530U;

#line 246
        }
        else
        {

#line 246
            _S16 = false;

#line 246
        }

#line 246
        if(_S16)
        {

#line 247
            uint _S17 = uint(seed_1);

#line 247
            best_dist_0 = dist_1;

#line 247
            closest_0 = _S17;

#line 247
            best_perm_0 = perm_2;

#line 246
        }

#line 239
        seed_1 = seed_1 + 1;

#line 239
    }

#line 252
    return uvec2(closest_0, best_perm_0);
}


#line 276
void swap_0(uint perm_3, inout CompressedTextureBlock3P_0 blockCoefficients_1)
{
    vec3 ep0_3 = blockCoefficients_1.ep0_0;
    vec3 ep1_3 = blockCoefficients_1.ep1_0;
    vec3 ep2_2 = blockCoefficients_1.ep2_0;
    vec3 ep3_2 = blockCoefficients_1.ep3_0;
    vec3 ep4_2 = blockCoefficients_1.ep4_0;
    vec3 ep5_2 = blockCoefficients_1.ep5_0;

#line 296
    if(perm_3 == 1U)
    {
        blockCoefficients_1.ep0_0 = ep2_2;
        blockCoefficients_1.ep1_0 = ep3_2;
        blockCoefficients_1.ep2_0 = ep0_3;
        blockCoefficients_1.ep3_0 = ep1_3;

#line 296
    }
    else
    {



        if(perm_3 == 2U)
        {
            blockCoefficients_1.ep0_0 = ep4_2;
            blockCoefficients_1.ep1_0 = ep5_2;
            blockCoefficients_1.ep4_0 = ep0_3;
            blockCoefficients_1.ep5_0 = ep1_3;

#line 302
        }
        else
        {



            if(perm_3 == 3U)
            {
                blockCoefficients_1.ep2_0 = ep4_2;
                blockCoefficients_1.ep3_0 = ep5_2;
                blockCoefficients_1.ep4_0 = ep2_2;
                blockCoefficients_1.ep5_0 = ep3_2;

#line 308
            }
            else
            {



                if(perm_3 == 4U)
                {
                    blockCoefficients_1.ep0_0 = ep4_2;
                    blockCoefficients_1.ep1_0 = ep5_2;
                    blockCoefficients_1.ep2_0 = ep0_3;
                    blockCoefficients_1.ep3_0 = ep1_3;
                    blockCoefficients_1.ep4_0 = ep2_2;
                    blockCoefficients_1.ep5_0 = ep3_2;

#line 314
                }
                else
                {

#line 322
                    if(perm_3 == 5U)
                    {
                        blockCoefficients_1.ep0_0 = ep2_2;
                        blockCoefficients_1.ep1_0 = ep3_2;
                        blockCoefficients_1.ep2_0 = ep4_2;
                        blockCoefficients_1.ep3_0 = ep5_2;
                        blockCoefficients_1.ep4_0 = ep0_3;
                        blockCoefficients_1.ep5_0 = ep1_3;

#line 322
                    }

#line 314
                }

#line 308
            }

#line 302
        }

#line 296
    }

#line 331
    return;
}


#line 340
void snap_1(inout CompressedTextureBlock3P_0 block_0, bool can_permute_1)
{
    uint raw_map_2 = pack_partition_indices_to_mask_0(block_0.partition_logits_0.data_0);

    uvec2 search_0 = get_closest_seed_0(raw_map_2, can_permute_1);
    uint closest_seed_0 = search_0.x;
    uint perm_4 = search_0.y;
    uint final_mask_0 = g_lut_0.lut3_0[closest_seed_0];

    block_0.astc_seed_0 = closest_seed_0;
    block_0.astc_partition_map_0 = final_mask_0;
    block_0.ideal_partition_map_0 = raw_map_2;
    block_0.perm_0 = perm_4;


    swap_0(perm_4, block_0);

#line 355
    int i_2 = 0;
    for(;;)
    {

#line 356
        if(i_2 < 16)
        {
        }
        else
        {

#line 356
            break;
        }
        block_0.partition_logits_0.data_0[i_2] = float((final_mask_0 >> (2 * i_2)) & 3U);

#line 356
        i_2 = i_2 + 1;

#line 356
    }



    return;
}


#line 13393 4
float saturate_1(float x_4)
{

#line 13401
    return clamp(x_4, 0.0, 1.0);
}


#line 481 0
TextureBlock_0 reconstruct_0(CompressedTextureBlock3P_0 blockCoefficients_2, uint blockIdx_0)
{

#line 501
    return decompress3P_0(blockCoefficients_2);
}


#line 514
struct DiffPair_CompressedTextureBlock3P_0
{
    CompressedTextureBlock3P_0 primal_0;
    CompressedTextureBlock3P_Differential_0 differential_0;
};


#line 576
vec3 s_primal_ctx_lerp_0(vec3 _S18, vec3 _S19, vec3 _S20)
{

#line 576
    return mix(_S18, _S19, _S20);
}


#line 576
TextureBlock_0 s_primal_ctx_decompress3P_0(CompressedTextureBlock3P_0 dpblockCoefficients_0)
{

#line 451
    vec3 _S21 = vec3(0.0);

#line 451
    vec3  _S22[16] = { _S21, _S21, _S21, _S21, _S21, _S21, _S21, _S21, _S21, _S21, _S21, _S21, _S21, _S21, _S21, _S21 };

#line 451
    bool _runFlag_0 = true;

#line 451
    uint i_3 = 0U;

#line 451
    TextureBlock_0 outputBlock_1;

#line 451
    outputBlock_1.pixels_0 = _S22;

#line 451
    int _pc_0 = 0;
    for(;;)
    {

#line 452
        if(_runFlag_0)
        {
        }
        else
        {

#line 452
            break;
        }

#line 452
        int _S23;

#line 452
        if(i_3 < 16U)
        {
            int _S24 = int(i_3);

#line 454
            float _S25 = NonDifferentiableWeights_operatorx5Bx5D_get_0(dpblockCoefficients_0.weights_0, _S24);
            int partition_1 = int(NonDifferentiableWeights_operatorx5Bx5D_get_0(dpblockCoefficients_0.partition_logits_0, _S24));
            bool _S26 = partition_1 == 0;

#line 456
            vec3 e0_1;

#line 456
            if(_S26)
            {

#line 456
                e0_1 = dpblockCoefficients_0.ep0_0;

#line 456
            }
            else
            {

#line 456
                if(partition_1 == 1)
                {

#line 456
                    e0_1 = dpblockCoefficients_0.ep2_0;

#line 456
                }
                else
                {

#line 456
                    e0_1 = dpblockCoefficients_0.ep4_0;

#line 456
                }

#line 456
            }

#line 456
            vec3 e1_1;
            if(_S26)
            {

#line 457
                e1_1 = dpblockCoefficients_0.ep1_0;

#line 457
            }
            else
            {

#line 457
                if(partition_1 == 1)
                {

#line 457
                    e1_1 = dpblockCoefficients_0.ep3_0;

#line 457
                }
                else
                {

#line 457
                    e1_1 = dpblockCoefficients_0.ep5_0;

#line 457
                }

#line 457
            }

#line 457
            vec3 _S27 = s_primal_ctx_lerp_0(e0_1, e1_1, vec3(_S25));

#line 457
            TextureBlock_0 _S28 = outputBlock_1;

#line 457
            _S28.pixels_0[i_3] = _S27;

#line 457
            _S23 = 1;

#line 457
            outputBlock_1 = _S28;

#line 457
        }
        else
        {

#line 457
            _S23 = 0;

#line 457
        }

#line 457
        if(_S23 != 1)
        {

#line 457
            _runFlag_0 = false;

#line 457
        }

#line 457
        if(_runFlag_0)
        {

#line 457
            i_3 = i_3 + 1U;

#line 457
        }

#line 457
        _pc_0 = _pc_0 + 1;

#line 452
    }

#line 452
    return outputBlock_1;
}


#line 452
TextureBlock_0 TextureBlock_x24_syn_dzero_0()
{

#line 452
    TextureBlock_0 result_1;

#line 2239 2
    vec3 _S29 = vec3(0.0);

#line 2239
    result_1.pixels_0[0] = _S29;

#line 2239
    result_1.pixels_0[1] = _S29;

#line 2239
    result_1.pixels_0[2] = _S29;

#line 2239
    result_1.pixels_0[3] = _S29;

#line 2239
    result_1.pixels_0[4] = _S29;

#line 2239
    result_1.pixels_0[5] = _S29;

#line 2239
    result_1.pixels_0[6] = _S29;

#line 2239
    result_1.pixels_0[7] = _S29;

#line 2239
    result_1.pixels_0[8] = _S29;

#line 2239
    result_1.pixels_0[9] = _S29;

#line 2239
    result_1.pixels_0[10] = _S29;

#line 2239
    result_1.pixels_0[11] = _S29;

#line 2239
    result_1.pixels_0[12] = _S29;

#line 2239
    result_1.pixels_0[13] = _S29;

#line 2239
    result_1.pixels_0[14] = _S29;

#line 2239
    result_1.pixels_0[15] = _S29;

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
void s_bwd_prop_lerp_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S30, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S31, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S32, vec3 _S33)
{

#line 2239
    _d_lerp_vector_0(_S30, _S31, _S32, _S33);

#line 2239
    return;
}


#line 442 0
void s_bwd_prop_decompress3P_0(inout DiffPair_CompressedTextureBlock3P_0 dpblockCoefficients_1, TextureBlock_0 _s_dOut_0)
{

#line 442
    vec3 _S34 = dpblockCoefficients_1.primal_0.ep0_0;

#line 442
    vec3 _S35 = dpblockCoefficients_1.primal_0.ep1_0;

#line 442
    vec3 _S36 = dpblockCoefficients_1.primal_0.ep2_0;

#line 442
    vec3 _S37 = dpblockCoefficients_1.primal_0.ep3_0;

#line 442
    vec3 _S38 = dpblockCoefficients_1.primal_0.ep4_0;

#line 442
    vec3 _S39 = dpblockCoefficients_1.primal_0.ep5_0;

#line 442
    NonDifferentiableWeights_0 _S40 = dpblockCoefficients_1.primal_0.weights_0;

#line 442
    NonDifferentiableWeights_0 _S41 = dpblockCoefficients_1.primal_0.partition_logits_0;

#line 2239 2
    vec3 _S42 = vec3(0.0);

#line 451 0
    TextureBlock_0 _S43 = TextureBlock_x24_syn_dzero_0();

#line 451
    TextureBlock_0 _S44 = TextureBlock_x24_syn_dadd_0(_s_dOut_0, _S43);

#line 451
    int _dc_0 = 16;

#line 451
    TextureBlock_0 _S45 = _S44;

#line 451
    vec3 _S46 = _S42;

#line 451
    vec3 _S47 = _S42;

#line 451
    vec3 _S48 = _S42;

#line 451
    vec3 _S49 = _S42;

#line 451
    vec3 _S50 = _S42;

#line 451
    vec3 _S51 = _S42;

#line 451
    vec3 _S52 = _S42;
    for(;;)
    {

#line 452
        uint _S53 = uint(_dc_0);

#line 452
        if(_dc_0 >= 0)
        {
        }
        else
        {

#line 452
            break;
        }

#line 452
        bool _S54 = _S53 < 16U;

#line 452
        vec3 e0_2;

#line 452
        vec3 e1_2;

#line 452
        vec3 _S55;

#line 452
        bool _S56;

#line 452
        bool _S57;

#line 452
        bool _S58;

#line 452
        if(_S54)
        {
            int _S59 = int(_S53);

#line 454
            float _S60 = NonDifferentiableWeights_operatorx5Bx5D_get_0(_S40, _S59);
            int partition_2 = int(NonDifferentiableWeights_operatorx5Bx5D_get_0(_S41, _S59));
            bool _S61 = partition_2 == 0;

#line 456
            if(_S61)
            {

#line 456
                e0_2 = _S34;

#line 456
                _S56 = false;

#line 456
            }
            else
            {

#line 456
                bool _S62 = partition_2 == 1;

#line 456
                if(_S62)
                {

#line 456
                    e0_2 = _S36;

#line 456
                }
                else
                {

#line 456
                    e0_2 = _S38;

#line 456
                }

#line 456
                _S56 = _S62;

#line 456
            }
            if(_S61)
            {

#line 457
                e1_2 = _S35;

#line 457
                _S57 = false;

#line 457
            }
            else
            {

#line 457
                bool _S63 = partition_2 == 1;

#line 457
                if(_S63)
                {

#line 457
                    e1_2 = _S37;

#line 457
                }
                else
                {

#line 457
                    e1_2 = _S39;

#line 457
                }

#line 457
                _S57 = _S63;

#line 457
            }

#line 456
            bool _S64 = _S56;

#line 456
            _S55 = vec3(_S60);

#line 456
            _S56 = _S61;

#line 456
            _S58 = _S64;

#line 456
        }
        else
        {

#line 456
            e0_2 = _S42;

#line 456
            e1_2 = _S42;

#line 456
            _S55 = _S42;

#line 456
            _S56 = false;

#line 456
            _S57 = false;

#line 456
            _S58 = false;

#line 456
        }

#line 451
        TextureBlock_0 _S65 = TextureBlock_x24_syn_dadd_0(_S45, _S43);

#line 451
        if(_S54)
        {

#line 451
            TextureBlock_0 _S66 = _S65;

#line 451
            _S66.pixels_0[_S53] = _S42;

#line 458
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S67;

#line 458
            _S67.primal_0 = e0_2;

#line 458
            _S67.differential_0 = _S42;

#line 458
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S68;

#line 458
            _S68.primal_0 = e1_2;

#line 458
            _S68.differential_0 = _S42;

#line 458
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S69;

#line 458
            _S69.primal_0 = _S55;

#line 458
            _S69.differential_0 = _S42;

#line 458
            s_bwd_prop_lerp_0(_S67, _S68, _S69, _S65.pixels_0[_S53]);

#line 458
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S70 = _S68;

#line 451
            TextureBlock_0 _S71 = TextureBlock_x24_syn_dadd_0(_S66, _S43);

#line 456
            vec3 _S72 = _S67.differential_0 + _S52;

#line 456
            vec3 _S73;

#line 456
            vec3 _S74;

#line 456
            vec3 _S75;

#line 456
            if(_S56)
            {

#line 2246 2
                vec3 _S76 = _S70.differential_0 + _S50;

#line 2246
                _S73 = _S46;

#line 2246
                _S74 = _S48;

#line 2246
                _S75 = _S76;

#line 2246
            }
            else
            {

#line 2246
                if(_S57)
                {

#line 2246
                    vec3 _S77 = _S70.differential_0 + _S48;

#line 2246
                    _S73 = _S46;

#line 2246
                    _S74 = _S77;

#line 2246
                }
                else
                {

#line 2246
                    _S73 = _S70.differential_0 + _S46;

#line 2246
                    _S74 = _S48;

#line 2246
                }

#line 2246
                _S75 = _S50;

#line 2246
            }

#line 2246
            vec3 _S78;

#line 2246
            vec3 _S79;

#line 2246
            vec3 _S80;

#line 2246
            if(_S56)
            {

#line 2246
                vec3 _S81 = _S72 + _S51;

#line 2246
                _S78 = _S47;

#line 2246
                _S79 = _S49;

#line 2246
                _S80 = _S81;

#line 2246
            }
            else
            {

#line 2246
                if(_S58)
                {

#line 2246
                    vec3 _S82 = _S72 + _S49;

#line 2246
                    _S78 = _S47;

#line 2246
                    _S79 = _S82;

#line 2246
                }
                else
                {

#line 2246
                    _S78 = _S72 + _S47;

#line 2246
                    _S79 = _S49;

#line 2246
                }

#line 2246
                _S80 = _S51;

#line 2246
            }

#line 2246
            _S45 = _S71;

#line 2246
            _S46 = _S73;

#line 2246
            _S47 = _S78;

#line 2246
            _S48 = _S74;

#line 2246
            _S49 = _S79;

#line 2246
            _S50 = _S75;

#line 2246
            _S51 = _S80;

#line 2246
            _S52 = _S42;

#line 2246
        }
        else
        {

#line 2246
            _S45 = TextureBlock_x24_syn_dadd_0(_S65, _S43);

#line 2246
        }

#line 2246
        _dc_0 = _dc_0 - 1;

#line 452 0
    }

#line 452
    CompressedTextureBlock3P_Differential_0 _S83 = CompressedTextureBlock3P_x24_syn_dzero_0();

#line 452
    _S83.ep5_1 = _S46;

#line 452
    _S83.ep4_1 = _S47;

#line 452
    _S83.ep3_1 = _S48;

#line 452
    _S83.ep2_1 = _S49;

#line 452
    _S83.ep1_2 = _S50;

#line 452
    _S83.ep0_2 = _S51;

#line 452
    dpblockCoefficients_1.primal_0 = dpblockCoefficients_1.primal_0;

#line 452
    dpblockCoefficients_1.differential_0 = _S83;

#line 442
    return;
}


#line 442
void s_bwd_prop_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S84, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S85, float _S86)
{

#line 442
    _d_dot_0(_S84, _S85, _S86);

#line 442
    return;
}


#line 442
void s_bwd_prop_loss_3P_0(uint _S87, inout DiffPair_CompressedTextureBlock3P_0 _S88, float _S89)
{

#line 442
    CompressedTextureBlock3P_0 _S90 = _S88.primal_0;

#line 442
    TextureBlock_0 _S91 = s_primal_ctx_decompress3P_0(_S88.primal_0);

#line 2239 2
    vec3 _S92 = vec3(0.0);

#line 2239
    int _dc_1 = 16;

#line 2239
    float _S93 = _S89;

#line 2239
    vec3  _S94[16];

#line 2239
    _S94[0] = _S92;

#line 2239
    _S94[1] = _S92;

#line 2239
    _S94[2] = _S92;

#line 2239
    _S94[3] = _S92;

#line 2239
    _S94[4] = _S92;

#line 2239
    _S94[5] = _S92;

#line 2239
    _S94[6] = _S92;

#line 2239
    _S94[7] = _S92;

#line 2239
    _S94[8] = _S92;

#line 2239
    _S94[9] = _S92;

#line 2239
    _S94[10] = _S92;

#line 2239
    _S94[11] = _S92;

#line 2239
    _S94[12] = _S92;

#line 2239
    _S94[13] = _S92;

#line 2239
    _S94[14] = _S92;

#line 2239
    _S94[15] = _S92;

#line 471 0
    for(;;)
    {

#line 471
        if(_dc_1 >= 0)
        {
        }
        else
        {

#line 471
            break;
        }

#line 471
        bool _S95 = _dc_1 < 16;

#line 471
        int _S96;

#line 471
        vec3 _S97;

#line 471
        if(_S95)
        {
            vec3 diff_0 = _S91.pixels_0[_dc_1] - g_groundtruth_0._data[uint(_S87)].pixels_0[_dc_1];

#line 473
            _S96 = 1;

#line 473
            _S97 = diff_0;

#line 473
        }
        else
        {

#line 473
            _S96 = 0;

#line 473
            _S97 = _S92;

#line 473
        }

#line 473
        float _S98;

#line 473
        float _S99;

#line 473
        if(!(_S96 != 1))
        {

#line 473
            _S98 = _S93;

#line 473
            _S99 = 0.0;

#line 473
        }
        else
        {

#line 473
            _S98 = 0.0;

#line 473
            _S99 = _S93;

#line 473
        }

#line 473
        if(_S95)
        {

#line 474
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S100;

#line 474
            _S100.primal_0 = _S97;

#line 474
            _S100.differential_0 = _S92;

#line 474
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S101;

#line 474
            _S101.primal_0 = _S97;

#line 474
            _S101.differential_0 = _S92;

#line 474
            s_bwd_prop_dot_0(_S100, _S101, _S98);

#line 473
            vec3 _S102 = _S101.differential_0 + _S100.differential_0;

#line 469
            float _S103 = _S98 + _S99;

#line 469
            vec3  _S104[16];

#line 469
            _S104[0] = _S92;

#line 469
            _S104[1] = _S92;

#line 469
            _S104[2] = _S92;

#line 469
            _S104[3] = _S92;

#line 469
            _S104[4] = _S92;

#line 469
            _S104[5] = _S92;

#line 469
            _S104[6] = _S92;

#line 469
            _S104[7] = _S92;

#line 469
            _S104[8] = _S92;

#line 469
            _S104[9] = _S92;

#line 469
            _S104[10] = _S92;

#line 469
            _S104[11] = _S92;

#line 469
            _S104[12] = _S92;

#line 469
            _S104[13] = _S92;

#line 469
            _S104[14] = _S92;

#line 469
            _S104[15] = _S92;

#line 469
            _S104[_dc_1] = _S102;

#line 2246 2
            vec3 _S105 = _S94[0] + _S104[0];

#line 2246
            vec3 _S106 = _S94[1] + _S104[1];

#line 2246
            vec3 _S107 = _S94[2] + _S104[2];

#line 2246
            vec3 _S108 = _S94[3] + _S104[3];

#line 2246
            vec3 _S109 = _S94[4] + _S104[4];

#line 2246
            vec3 _S110 = _S94[5] + _S104[5];

#line 2246
            vec3 _S111 = _S94[6] + _S104[6];

#line 2246
            vec3 _S112 = _S94[7] + _S104[7];

#line 2246
            vec3 _S113 = _S94[8] + _S104[8];

#line 2246
            vec3 _S114 = _S94[9] + _S104[9];

#line 2246
            vec3 _S115 = _S94[10] + _S104[10];

#line 2246
            vec3 _S116 = _S94[11] + _S104[11];

#line 2246
            vec3 _S117 = _S94[12] + _S104[12];

#line 2246
            vec3 _S118 = _S94[13] + _S104[13];

#line 2246
            vec3 _S119 = _S94[14] + _S104[14];

#line 2246
            vec3 _S120 = _S94[15] + _S104[15];

#line 2246
            _S93 = _S103;

#line 2246
            _S94[0] = _S105;

#line 2246
            _S94[1] = _S106;

#line 2246
            _S94[2] = _S107;

#line 2246
            _S94[3] = _S108;

#line 2246
            _S94[4] = _S109;

#line 2246
            _S94[5] = _S110;

#line 2246
            _S94[6] = _S111;

#line 2246
            _S94[7] = _S112;

#line 2246
            _S94[8] = _S113;

#line 2246
            _S94[9] = _S114;

#line 2246
            _S94[10] = _S115;

#line 2246
            _S94[11] = _S116;

#line 2246
            _S94[12] = _S117;

#line 2246
            _S94[13] = _S118;

#line 2246
            _S94[14] = _S119;

#line 2246
            _S94[15] = _S120;

#line 2246
        }
        else
        {

#line 2246
            _S93 = _S99;

#line 2246
        }

#line 2246
        _dc_1 = _dc_1 - 1;

#line 471 0
    }

#line 468
    TextureBlock_0 _S121 = TextureBlock_x24_syn_dzero_0();

#line 468
    _S121.pixels_0 = _S94;

#line 468
    CompressedTextureBlock3P_Differential_0 _S122 = CompressedTextureBlock3P_x24_syn_dzero_0();

#line 468
    DiffPair_CompressedTextureBlock3P_0 _S123;

#line 468
    _S123.primal_0 = _S90;

#line 468
    _S123.differential_0 = _S122;

#line 468
    s_bwd_prop_decompress3P_0(_S123, _S121);

#line 468
    _S88.primal_0 = _S88.primal_0;

#line 468
    _S88.differential_0 = _S123.differential_0;

#line 464
    return;
}


#line 464
void s_bwd_loss_3P_0(uint _S124, inout DiffPair_CompressedTextureBlock3P_0 _S125, float _S126)
{

#line 464
    s_bwd_prop_loss_3P_0(_S124, _S125, _S126);

#line 464
    return;
}


#line 464
void one_step_opt_0(inout CompressedTextureBlock3P_0 _S127, uint _S128, bool _S129, bool _S130)
{

#line 379
    vec3 L1_0 = _S127.ep1_0 - _S127.ep0_0;
    vec3 L2_0 = _S127.ep3_0 - _S127.ep2_0;
    vec3 L3_0 = _S127.ep5_0 - _S127.ep4_0;
    float _S131 = 1.0 / (dot(L1_0, L1_0) + 9.99999997475242708e-07);
    float _S132 = 1.0 / (dot(L2_0, L2_0) + 9.99999997475242708e-07);
    float _S133 = 1.0 / (dot(L3_0, L3_0) + 9.99999997475242708e-07);

#line 384
    int i_4 = 0;

    for(;;)
    {

#line 386
        if(i_4 < 16)
        {
        }
        else
        {

#line 386
            break;
        }

        vec3 P1_0 = g_groundtruth_0._data[uint(_S128)].pixels_0[i_4] - _S127.ep0_0;
        vec3 P2_0 = g_groundtruth_0._data[uint(_S128)].pixels_0[i_4] - _S127.ep2_0;
        vec3 P3_0 = g_groundtruth_0._data[uint(_S128)].pixels_0[i_4] - _S127.ep4_0;

#line 399
        _S127.partition_logits_0.data_0[i_4] = float(get_partition_0(distSq_0(P1_0, L1_0, dot(P1_0, L1_0), _S131), distSq_0(P2_0, L2_0, dot(P2_0, L2_0), _S132), distSq_0(P3_0, L3_0, dot(P3_0, L3_0), _S133)));

#line 386
        i_4 = i_4 + 1;

#line 386
    }

#line 386
    vec3 L1_1;

#line 386
    vec3 L2_1;

#line 386
    vec3 L3_1;

#line 386
    float invLenSq1_0;

#line 386
    float invLenSq2_0;

#line 386
    float invLenSq3_0;

#line 401
    if(_S129)
    {

#line 402
        snap_1(_S127, _S130);
        vec3 L1_2 = _S127.ep1_0 - _S127.ep0_0;
        vec3 L2_2 = _S127.ep3_0 - _S127.ep2_0;
        vec3 L3_2 = _S127.ep5_0 - _S127.ep4_0;
        float _S134 = 1.0 / (dot(L1_2, L1_2) + 9.99999997475242708e-07);
        float _S135 = 1.0 / (dot(L2_2, L2_2) + 9.99999997475242708e-07);
        float _S136 = 1.0 / (dot(L3_2, L3_2) + 9.99999997475242708e-07);

#line 408
        L1_1 = L1_2;

#line 408
        L2_1 = L2_2;

#line 408
        L3_1 = L3_2;

#line 408
        invLenSq1_0 = _S134;

#line 408
        invLenSq2_0 = _S135;

#line 408
        invLenSq3_0 = _S136;

#line 401
    }
    else
    {

#line 401
        L1_1 = L1_0;

#line 401
        L2_1 = L2_0;

#line 401
        L3_1 = L3_0;

#line 401
        invLenSq1_0 = _S131;

#line 401
        invLenSq2_0 = _S132;

#line 401
        invLenSq3_0 = _S133;

#line 401
    }

#line 401
    i_4 = 0;

#line 410
    for(;;)
    {

#line 410
        if(i_4 < 16)
        {
        }
        else
        {

#line 410
            break;
        }

#line 416
        float pDotL1_0 = dot(g_groundtruth_0._data[uint(_S128)].pixels_0[i_4] - _S127.ep0_0, L1_1);
        float pDotL2_0 = dot(g_groundtruth_0._data[uint(_S128)].pixels_0[i_4] - _S127.ep2_0, L2_1);
        float pDotL3_0 = dot(g_groundtruth_0._data[uint(_S128)].pixels_0[i_4] - _S127.ep4_0, L3_1);

        float partition_3 = NonDifferentiableWeights_operatorx5Bx5D_get_0(_S127.partition_logits_0, i_4);
        bool _S137 = partition_3 == 0.0;

#line 421
        float pDotL_1;

#line 421
        if(_S137)
        {

#line 421
            pDotL_1 = pDotL1_0;

#line 421
        }
        else
        {

#line 421
            if(partition_3 == 1.0)
            {

#line 421
                pDotL_1 = pDotL2_0;

#line 421
            }
            else
            {

#line 421
                pDotL_1 = pDotL3_0;

#line 421
            }

#line 421
        }

#line 421
        float invLenSq_1;
        if(_S137)
        {

#line 422
            invLenSq_1 = invLenSq1_0;

#line 422
        }
        else
        {

#line 422
            if(partition_3 == 1.0)
            {

#line 422
                invLenSq_1 = invLenSq2_0;

#line 422
            }
            else
            {

#line 422
                invLenSq_1 = invLenSq3_0;

#line 422
            }

#line 422
        }


        _S127.weights_0.data_0[i_4] = saturate_1(pDotL_1 * invLenSq_1);

#line 410
        i_4 = i_4 + 1;

#line 410
    }

#line 427
    return;
}


#line 427
float loss_3P_0(uint _S138, CompressedTextureBlock3P_0 _S139)
{

#line 468
    TextureBlock_0 _S140 = decompress3P_0(_S139);

#line 468
    int i_5 = 0;

#line 468
    float totalError_0 = 0.0;


    for(;;)
    {

#line 471
        if(i_5 < 16)
        {
        }
        else
        {

#line 471
            break;
        }
        vec3 diff_1 = _S140.pixels_0[i_5] - g_groundtruth_0._data[uint(_S138)].pixels_0[i_5];
        float totalError_1 = totalError_0 + dot(diff_1, diff_1);

#line 471
        i_5 = i_5 + 1;

#line 471
        totalError_0 = totalError_1;

#line 471
    }

#line 477
    return totalError_0;
}


#line 514
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 516
    uint blockIdx_1 = gl_GlobalInvocationID.x;
    if(blockIdx_1 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {

#line 517
        return;
    }

#line 518
    uvec2 _S141 = (clockRealtime2x32EXT());

#line 518
    g_diagnostics_0._data[uint(blockIdx_1)].start_clock_0 = _S141;

    CompressedTextureBlock3P_0 value_0 = g_compressedBlock3P_0._data[uint(blockIdx_1)];

    float _S142 = g_compress_step_params_0._data[uint(0)].learning_rate_0;
    uint steps_1 = g_compress_step_params_0._data[uint(0)].steps_0;
    bool _S143 = (g_compress_step_params_0._data[uint(0)].snap_0) > 0U;
    float _S144 = float(g_compress_step_params_0._data[uint(0)].steps_0);

#line 525
    uint _S145 = uint(_S144 * 0.80000001192092896);
    uint _S146 = uint(_S144 * 0.94999998807907104);
    uint _S147 = max(1U, g_compress_step_params_0._data[uint(0)].steps_0 / 20U);

#line 532
    PCG32_0 prng_0 = PCG32_x24init_0(0U);
    uint _S148 = PCG32_nextUint_0(prng_0);

#line 533
    value_0.ep0_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S148 % 16U];
    uint _S149 = PCG32_nextUint_0(prng_0);

#line 534
    value_0.ep1_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S149 % 16U];

#line 534
    int i_6 = 0;
    for(;;)
    {

#line 535
        if(i_6 < 8)
        {
        }
        else
        {

#line 535
            break;
        }

#line 536
        uint _S150 = PCG32_nextUint_0(prng_0);

#line 536
        value_0.ep1_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S150 % 16U];
        vec3 d_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S150 % 16U] - value_0.ep0_0;
        if((dot(d_0, d_0)) > 0.30000001192092896)
        {

#line 539
            break;
        }

#line 535
        i_6 = i_6 + 1;

#line 535
    }

#line 535
    i_6 = 0;

#line 542
    for(;;)
    {

#line 542
        if(i_6 < 8)
        {
        }
        else
        {

#line 542
            break;
        }

#line 543
        uint _S151 = PCG32_nextUint_0(prng_0);

#line 543
        value_0.ep2_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S151 % 16U];
        if((dist_0(g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S151 % 16U], value_0.ep0_0, value_0.ep1_0)) > 0.30000001192092896)
        {

#line 545
            break;
        }

#line 542
        i_6 = i_6 + 1;

#line 542
    }

#line 542
    i_6 = 0;

#line 548
    for(;;)
    {

#line 548
        if(i_6 < 8)
        {
        }
        else
        {

#line 548
            break;
        }

#line 549
        uint _S152 = PCG32_nextUint_0(prng_0);

#line 549
        value_0.ep3_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S152 % 16U];
        if((dist_0(g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S152 % 16U], value_0.ep0_0, value_0.ep1_0)) > 0.30000001192092896)
        {

#line 551
            break;
        }

#line 548
        i_6 = i_6 + 1;

#line 548
    }

#line 548
    i_6 = 0;

#line 554
    for(;;)
    {

#line 554
        if(i_6 < 8)
        {
        }
        else
        {

#line 554
            break;
        }

#line 555
        uint _S153 = PCG32_nextUint_0(prng_0);

#line 555
        value_0.ep4_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S153 % 16U];
        if((dist_0(g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S153 % 16U], value_0.ep0_0, value_0.ep1_0)) <= 0.30000001192092896)
        {

#line 557
            i_6 = i_6 + 1;

#line 554
            continue;
        }



        if((dist_0(value_0.ep4_0, value_0.ep2_0, value_0.ep3_0)) > 0.30000001192092896)
        {

#line 560
            break;
        }

#line 554
        i_6 = i_6 + 1;

#line 554
    }

#line 554
    i_6 = 0;

#line 563
    for(;;)
    {

#line 563
        if(i_6 < 8)
        {
        }
        else
        {

#line 563
            break;
        }

#line 564
        uint _S154 = PCG32_nextUint_0(prng_0);

#line 564
        value_0.ep5_0 = g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S154 % 16U];
        if((dist_0(g_groundtruth_0._data[uint(blockIdx_1)].pixels_0[_S154 % 16U], value_0.ep0_0, value_0.ep1_0)) <= 0.30000001192092896)
        {

#line 566
            i_6 = i_6 + 1;

#line 563
            continue;
        }



        if((dist_0(value_0.ep5_0, value_0.ep2_0, value_0.ep3_0)) > 0.30000001192092896)
        {

#line 569
            break;
        }

#line 563
        i_6 = i_6 + 1;

#line 563
    }

#line 563
    int step_0 = 0;

#line 573
    for(;;)
    {

#line 573
        if(step_0 < int(steps_1))
        {
        }
        else
        {

#line 573
            break;
        }
        CompressedTextureBlock3P_Differential_0 _S155 = CompressedTextureBlock3P_x24_syn_dzero_0();

#line 575
        DiffPair_CompressedTextureBlock3P_0 cb_pair_0;

#line 575
        cb_pair_0.primal_0 = value_0;

#line 575
        cb_pair_0.differential_0 = _S155;

#line 575
        s_bwd_loss_3P_0(blockIdx_1, cb_pair_0, 1.0);



        value_0.ep0_0 = saturate_0(value_0.ep0_0 - cb_pair_0.differential_0.ep0_2 * _S142);
        value_0.ep1_0 = saturate_0(value_0.ep1_0 - cb_pair_0.differential_0.ep1_2 * _S142);
        value_0.ep2_0 = saturate_0(value_0.ep2_0 - cb_pair_0.differential_0.ep2_1 * _S142);
        value_0.ep3_0 = saturate_0(value_0.ep3_0 - cb_pair_0.differential_0.ep3_1 * _S142);
        value_0.ep4_0 = saturate_0(value_0.ep4_0 - cb_pair_0.differential_0.ep4_1 * _S142);
        value_0.ep5_0 = saturate_0(value_0.ep5_0 - cb_pair_0.differential_0.ep5_1 * _S142);

#line 584
        bool _S156;
        if(_S143)
        {

#line 585
            uint _S157 = uint(step_0);

#line 585
            if(_S157 >= _S145)
            {

#line 585
                _S156 = true;

#line 585
            }
            else
            {

#line 585
                _S156 = _S157 >= (steps_1 - 1U);

#line 585
            }

#line 585
        }
        else
        {

#line 585
            _S156 = false;

#line 585
        }

#line 585
        uint _S158 = uint(step_0);

#line 585
        one_step_opt_0(value_0, blockIdx_1, _S156, _S158 <= _S146);

        uint _S159 = _S158 % _S147;

#line 587
        if(_S159 == 0U)
        {

#line 588
            uint iter_0 = _S158 / _S147;
            uvec2 _S160 = (clockRealtime2x32EXT());

#line 589
            g_diagnostics_0._data[uint(blockIdx_1)].timestamps_0[iter_0] = _S160;
            g_diagnostics_0._data[uint(blockIdx_1)].loss_log_0[iter_0] = loss_3P_0(blockIdx_1, value_0);

            uint raw_map_3 = pack_partition_indices_to_mask_0(value_0.partition_logits_0.data_0);



            g_diagnostics_0._data[uint(blockIdx_1)].partition_hamming_error_log_0[iter_0] = hamming_distance_2b_0(raw_map_3, g_lut_0.lut3_0[get_closest_seed_0(raw_map_3, false).x]);
            g_diagnostics_0._data[uint(blockIdx_1)].ideal_partition_log_0[iter_0] = raw_map_3;

#line 587
        }

#line 573
        step_0 = step_0 + 1;

#line 573
    }

#line 601
    uvec2 _S161 = (clockRealtime2x32EXT());

#line 601
    g_diagnostics_0._data[uint(blockIdx_1)].optim_ended_clock_0 = _S161;
    g_compressedBlock3P_0._data[uint(blockIdx_1)] = value_0;
    g_reconstructed_0._data[uint(blockIdx_1)] = reconstruct_0(value_0, blockIdx_1);
    g_diagnostics_0._data[uint(blockIdx_1)].partition_hamming_error_0 = hamming_distance_2b_0(value_0.ideal_partition_map_0, value_0.astc_partition_map_0);
    g_final_loss_0._data[uint(blockIdx_1)] = loss_3P_0(blockIdx_1, value_0);
    uvec2 _S162 = (clockRealtime2x32EXT());

#line 606
    g_diagnostics_0._data[uint(blockIdx_1)].finished_clock_0 = _S162;
    return;
}

#version 450
layout(row_major) uniform;
layout(row_major) buffer;

#line 51 0
struct CompressStepParams_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
    uint snap_0;
};


#line 76
layout(std430, binding = 5) buffer StructuredBuffer_CompressStepParams_t_0 {
    CompressStepParams_0 _data[];
} g_compress_step_params_0;

#line 73
layout(std430, binding = 4) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 8
struct TextureBlock_0
{
    vec3  pixels_0[16];
};


#line 61
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
    uint perm_0;
};


#line 70
layout(std430, binding = 3) buffer StructuredBuffer_CompressedTextureBlock3P_t_0 {
    CompressedTextureBlock3P_0 _data[];
} g_compressedBlock3P_0;

#line 31
float NonDifferentiableWeights_operatorx5Bx5D_get_0(NonDifferentiableWeights_0 this_0, int n_0)
{

#line 31
    return this_0.data_0[n_0];
}


#line 514
TextureBlock_0 decompress3P_0(uint _S1)
{

#line 514
    CompressedTextureBlock3P_0 _S2 = g_compressedBlock3P_0._data[uint(_S1)];

#line 451
    TextureBlock_0 outputBlock_0;

#line 451
    uint i_0 = 0U;
    for(;;)
    {

#line 452
        if(i_0 < 16U)
        {
        }
        else
        {

#line 452
            break;
        }
        int _S3 = int(i_0);

#line 454
        float _S4 = NonDifferentiableWeights_operatorx5Bx5D_get_0(_S2.weights_0, _S3);
        int partition_0 = int(NonDifferentiableWeights_operatorx5Bx5D_get_0(_S2.partition_logits_0, _S3));
        bool _S5 = partition_0 == 0;

#line 456
        vec3 e0_0;

#line 456
        if(_S5)
        {

#line 456
            e0_0 = _S2.ep0_0;

#line 456
        }
        else
        {

#line 456
            if(partition_0 == 1)
            {

#line 456
                e0_0 = _S2.ep2_0;

#line 456
            }
            else
            {

#line 456
                e0_0 = _S2.ep4_0;

#line 456
            }

#line 456
        }

#line 456
        vec3 e1_0;
        if(_S5)
        {

#line 457
            e1_0 = _S2.ep1_0;

#line 457
        }
        else
        {

#line 457
            if(partition_0 == 1)
            {

#line 457
                e1_0 = _S2.ep3_0;

#line 457
            }
            else
            {

#line 457
                e1_0 = _S2.ep5_0;

#line 457
            }

#line 457
        }
        outputBlock_0.pixels_0[i_0] = mix(e0_0, e1_0, vec3(_S4));

#line 452
        i_0 = i_0 + 1U;

#line 452
    }

#line 460
    return outputBlock_0;
}


#line 460
float loss_3P_0(uint _S6, uint _S7)
{

#line 460
    TextureBlock_0 _S8 = decompress3P_0(_S7);

#line 460
    int i_1 = 0;

#line 460
    float totalError_0 = 0.0;

#line 471
    for(;;)
    {

#line 471
        if(i_1 < 16)
        {
        }
        else
        {

#line 471
            break;
        }
        vec3 diff_0 = _S8.pixels_0[i_1] - g_groundtruth_0._data[uint(_S6)].pixels_0[i_1];
        float totalError_1 = totalError_0 + dot(diff_0, diff_0);

#line 471
        i_1 = i_1 + 1;

#line 471
        totalError_0 = totalError_1;

#line 471
    }

#line 477
    return totalError_0;
}


#line 611
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 613
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {

#line 614
        return;
    }

#line 615
    g_final_loss_0._data[uint(blockIdx_0)] = loss_3P_0(blockIdx_0, blockIdx_0);
    return;
}

