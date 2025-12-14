#version 450
#extension GL_EXT_shader_realtime_clock : require
#extension GL_EXT_control_flow_attributes : require
layout(row_major) uniform;
layout(row_major) buffer;

#line 46 0
struct Params_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
    bool snap_0;
    uint max_partitions_0;
    bool debug_reconstruction_0;
    uint exact_steps_0;
    bool use_pca_0;
};


#line 58
layout(binding = 0)
layout(std140) uniform block_Params_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
    bool snap_0;
    uint max_partitions_0;
    bool debug_reconstruction_0;
    uint exact_steps_0;
    bool use_pca_0;
}g_params_0;

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
    uint  partition_count_0[20];
};


#line 67
layout(std430, binding = 3) buffer StructuredBuffer_Diagnostics_t_0 {
    Diagnostics_0 _data[];
} g_diagnostics_0;

#line 28
struct NonDifferentiableWeights_0
{
    float  data_0[16];
};


#line 37
struct NonDifferentiableIntWeights_0
{
    int  data_1[16];
};


#line 303
struct CompressedTextureBlock3P_0
{
    vec3 ep0_0;
    vec3 ep1_0;
    vec3 ep2_0;
    vec3 ep3_0;
    vec3 ep4_0;
    vec3 ep5_0;
    NonDifferentiableWeights_0 weights_0;
    NonDifferentiableIntWeights_0 partition_index_0;
    uint astc_partition_map_0;
    uint ideal_partition_map_0;
    uint astc_seed_0;
    uint perm_0;
    uint partition_count_1;
    uint max_partitions_1;
};


#line 70
layout(std430, binding = 4) buffer StructuredBuffer_CompressedTextureBlock3P_t_0 {
    CompressedTextureBlock3P_0 _data[];
} g_compressedBlock3P_0;

#line 8
struct TextureBlock_0
{
    vec3  pixels_0[16];
};


#line 61
layout(std430, binding = 1) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;

#line 77
layout(std430, binding = 7) readonly buffer StructuredBuffer_uint_t_0 {
    uint _data[];
} g_astc_3p_4x4_lut_s3_0;

#line 79
struct LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
};


#line 84
layout(binding = 8)
layout(std140) uniform block_LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
}g_lut_0;

#line 76
layout(std430, binding = 6) readonly buffer StructuredBuffer_uint_t_1 {
    uint _data[];
} g_astc_2p_4x4_lut_s2_0;

#line 64
layout(std430, binding = 2) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;

#line 73
layout(std430, binding = 5) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 89
struct PCG32_0
{
    uint state_0;
};


#line 93
PCG32_0 PCG32_x24init_0(uint seed_0)
{

#line 93
    PCG32_0 _S1;

    uint _S2 = seed_0 * 747796405U + 2891336453U;
    uint _S3 = ((_S2 >> ((_S2 >> 28U) + 4U)) ^ _S2) * 277803737U;
    _S1.state_0 = (_S3 >> 22U) ^ _S3;

#line 93
    return _S1;
}


#line 108
uint PCG32_nextUint_0(inout PCG32_0 this_0)
{
    uint oldState_0 = this_0.state_0;
    this_0.state_0 = this_0.state_0 * 747796405U + 2891336453U;
    uint word_0 = ((oldState_0 >> ((oldState_0 >> 28U) + 4U)) ^ oldState_0) * 277803737U;
    return (word_0 >> 22U) ^ word_0;
}


#line 113
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


#line 674 0
float dist_0(vec3 x_0, vec3 ep0_1, vec3 ep1_1)
{
    vec3 lineDir_0 = ep1_1 - ep0_1;

    return length(cross(x_0 - ep0_1, lineDir_0)) / length(lineDir_0);
}


#line 41
int NonDifferentiableIntWeights_operatorx5Bx5D_get_0(NonDifferentiableIntWeights_0 this_1, int n_0)
{

#line 41
    return this_1.data_1[n_0];
}


#line 13408 2
vec3 saturate_0(vec3 x_1)
{

#line 13416
    return clamp(x_1, vec3(0.0), vec3(1.0));
}


#line 303 0
struct CompressedTextureBlock3P_Differential_0
{
    vec3 ep0_2;
    vec3 ep1_2;
    vec3 ep2_1;
    vec3 ep3_1;
    vec3 ep4_1;
    vec3 ep5_1;
};


#line 303
CompressedTextureBlock3P_Differential_0 CompressedTextureBlock3P_x24_syn_dzero_0()
{

#line 303
    CompressedTextureBlock3P_Differential_0 result_0;

#line 2239 3
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


#line 32 0
float NonDifferentiableWeights_operatorx5Bx5D_get_0(NonDifferentiableWeights_0 this_2, int n_1)
{

#line 32
    return this_2.data_0[n_1];
}


#line 8119 2
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


#line 1 4
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


#line 483 0
TextureBlock_0 CompressedTextureBlock3P_decompress3P_0(CompressedTextureBlock3P_0 this_3)
{
    TextureBlock_0 outputBlock_0;

#line 485
    uint i_0 = 0U;
    for(;;)
    {

#line 486
        if(i_0 < 16U)
        {
        }
        else
        {

#line 486
            break;
        }
        int _S9 = int(i_0);

#line 488
        float _S10 = NonDifferentiableWeights_operatorx5Bx5D_get_0(this_3.weights_0, _S9);
        uint partition_0 = clamp(uint(int(float(NonDifferentiableIntWeights_operatorx5Bx5D_get_0(this_3.partition_index_0, _S9)))), 0U, this_3.max_partitions_1 - 1U);
        bool _S11 = partition_0 == 0U;

#line 490
        vec3 e0_0;

#line 490
        if(_S11)
        {

#line 490
            e0_0 = this_3.ep0_0;

#line 490
        }
        else
        {

#line 490
            if(partition_0 == 1U)
            {

#line 490
                e0_0 = this_3.ep2_0;

#line 490
            }
            else
            {

#line 490
                e0_0 = this_3.ep4_0;

#line 490
            }

#line 490
        }

#line 490
        vec3 e1_0;
        if(_S11)
        {

#line 491
            e1_0 = this_3.ep1_0;

#line 491
        }
        else
        {

#line 491
            if(partition_0 == 1U)
            {

#line 491
                e1_0 = this_3.ep3_0;

#line 491
            }
            else
            {

#line 491
                e1_0 = this_3.ep5_0;

#line 491
            }

#line 491
        }
        outputBlock_0.pixels_0[i_0] = mix(e0_0, e1_0, vec3(_S10));

#line 486
        i_0 = i_0 + 1U;

#line 486
    }

#line 494
    return outputBlock_0;
}


#line 13393 2
float saturate_1(float x_2)
{

#line 13401
    return clamp(x_2, 0.0, 1.0);
}


#line 395 0
float CompressedTextureBlock3P_distSq_0(vec3 P_0, vec3 L_0, float pDotL_0, float invLenSq_0)
{

    return dot(P_0, P_0) - pDotL_0 * pDotL_0 * invLenSq_0;
}

uint CompressedTextureBlock3P_argmin_0(float d1_0, float d2_0, float d3_0)
{

#line 401
    bool _S12;

    if(d1_0 < d2_0)
    {

#line 403
        _S12 = d1_0 < d3_0;

#line 403
    }
    else
    {

#line 403
        _S12 = false;

#line 403
    }

#line 403
    if(_S12)
    {

#line 403
        return 0U;
    }

#line 404
    if(d2_0 < d3_0)
    {

#line 404
        return 1U;
    }

#line 405
    return 2U;
}


#line 318
uint CompressedTextureBlock3P_pack_partition_indices_0(CompressedTextureBlock3P_0 this_4)
{

#line 318
    int i_1 = 0;

#line 318
    uint raw_map_0 = 0U;


    for(;;)
    {

#line 321
        if(i_1 < 16)
        {
        }
        else
        {

#line 321
            break;
        }

        uint raw_map_1 = raw_map_0 | ((clamp(uint(round(float(NonDifferentiableIntWeights_operatorx5Bx5D_get_0(this_4.partition_index_0, i_1)))), 0U, 2U)) << (i_1 * 2));

#line 321
        i_1 = i_1 + 1;

#line 321
        raw_map_0 = raw_map_1;

#line 321
    }

#line 326
    return raw_map_0;
}


#line 223
uint lut3_key_0(uint x_3)
{

#line 223
    uint result_1 = 0U;

#line 223
    int i_2 = 15;

#line 228
    [[unroll]]
    for(;;)
    {

#line 228
        if(i_2 >= 0)
        {
        }
        else
        {

#line 228
            break;
        }
        uint _S13 = result_1 * 3U + ((x_3 >> (i_2 * 2)) & 3U);

#line 228
        int _S14 = i_2 - 1;

#line 228
        result_1 = _S13;

#line 228
        i_2 = _S14;

#line 228
    }



    return result_1;
}


#line 128
uint permute_swap01_0(uint x_4)
{
    return x_4 ^ ((~(x_4 >> 1)) & 1431655765U);
}

uint permute_swap02_0(uint x_5)
{
    return x_5 ^ ((~(x_5 << 1)) & 2863311530U);
}

uint permute_swap12_0(uint x_6)
{
    uint non_zero_0 = (x_6 | (x_6 >> 1)) & 1431655765U;

    return x_6 ^ (non_zero_0 | (non_zero_0 << 1));
}

uint permute_cycle_120_0(uint x_7)
{

    uint s_0 = x_7 + 1431655765U;
    uint mask_0 = (s_0 & (s_0 >> 1)) & 1431655765U;
    return s_0 & (~(mask_0 | (mask_0 << 1)));
}

uint permute_cycle_201_0(uint x_8)
{

#line 159
    return permute_cycle_120_0(permute_cycle_120_0(x_8));
}


#line 235
uint canonicalize_lut3_0(uint x_9)
{

#line 247
    return min(min(lut3_key_0(x_9), lut3_key_0(permute_swap01_0(x_9))), min(min(lut3_key_0(permute_swap02_0(x_9)), lut3_key_0(permute_swap12_0(x_9))), min(lut3_key_0(permute_cycle_120_0(x_9)), lut3_key_0(permute_cycle_201_0(x_9)))));
}


#line 277
uint count_diffs_0(uint val_0)
{
    return bitCount((val_0 | (val_0 >> 1)) & 1431655765U);
}


#line 177
uint best_perm_distance_s3_0(uint x_10, uint y_0, out uint perm_1)
{
    uint base_0 = x_10 ^ y_0;

    uint x_shr1_0 = x_10 >> 1;
    uint nz_0 = (x_10 | x_shr1_0) & 1431655765U;
    uint nz_shl1_0 = nz_0 << 1;

    uint m01_0 = (~x_shr1_0) & 1431655765U;

#line 201
    uint best_0 = min(min(min(((count_diffs_0(base_0)) << 3) | 0U, ((count_diffs_0(base_0 ^ m01_0)) << 3) | 1U), min(((count_diffs_0(base_0 ^ ((~(x_10 << 1)) & 2863311530U))) << 3) | 2U, ((count_diffs_0(base_0 ^ (nz_0 | nz_shl1_0))) << 3) | 3U)), min(((count_diffs_0(base_0 ^ (m01_0 | nz_shl1_0))) << 3) | 4U, ((count_diffs_0(base_0 ^ (nz_0 | (((~x_10) & 1431655765U) << 1)))) << 3) | 5U));

    perm_1 = best_0 & 7U;
    return best_0 >> 3;
}


#line 282
uint get_closest_seed3_0(uint input_0, out uint perm_2, out uint final_pattern_0)
{

#line 283
    uint key_0 = canonicalize_lut3_0(input_0);
    uint seed_1 = ((g_astc_3p_4x4_lut_s3_0._data[uint(key_0 / 3U)]) >> (key_0 % 3U * 10U)) & 1023U;
    uint pattern_0 = g_lut_0.lut3_0[seed_1];
    uint _S15 = best_perm_distance_s3_0(input_0, g_lut_0.lut3_0[seed_1], perm_2);

    final_pattern_0 = pattern_0;
    return seed_1;
}


#line 250
uint lut2_key_0(uint x_11)
{

#line 250
    uint result_2 = 0U;

#line 250
    int i_3 = 15;

#line 255
    [[unroll]]
    for(;;)
    {

#line 255
        if(i_3 >= 0)
        {
        }
        else
        {

#line 255
            break;
        }
        uint _S16 = result_2 * 2U + ((x_11 >> (i_3 * 2)) & 3U);

#line 255
        int _S17 = i_3 - 1;

#line 255
        result_2 = _S16;

#line 255
        i_3 = _S17;

#line 255
    }



    return result_2;
}

uint canonicalize_lut2_0(uint x_12)
{


    return min(lut2_key_0(x_12), lut2_key_0(permute_swap01_0(x_12)));
}


#line 207
uint best_perm_distance_s2_0(uint x_13, uint y_1, out uint perm_3)
{
    uint base_1 = x_13 ^ y_1;

#line 217
    uint min01_0 = min(((count_diffs_0(base_1)) << 1) | 0U, ((count_diffs_0(base_1 ^ ((~(x_13 >> 1)) & 1431655765U))) << 1) | 1U);

    perm_3 = min01_0 & 1U;
    return min01_0 >> 1;
}


#line 292
uint get_closest_seed2_0(uint input_1, out uint permutation_0, out uint final_pattern_1)
{

#line 293
    uint key_1 = canonicalize_lut2_0(input_1);
    uint seed_2 = ((g_astc_2p_4x4_lut_s2_0._data[uint(key_1 / 3U)]) >> (key_1 % 3U * 10U)) & 1023U;
    uint pattern_1 = g_lut_0.lut2_0[seed_2];
    uint _S18 = best_perm_distance_s2_0(input_1, g_lut_0.lut2_0[seed_2], permutation_0);

    final_pattern_1 = pattern_1;
    return seed_2;
}


#line 330
void CompressedTextureBlock3P_swap_colors_0(inout CompressedTextureBlock3P_0 this_5, uint perm_4)
{
    vec3 old_ep0_0 = this_5.ep0_0;
    vec3 old_ep1_0 = this_5.ep1_0;
    vec3 old_ep2_0 = this_5.ep2_0;
    vec3 old_ep3_0 = this_5.ep3_0;
    vec3 old_ep4_0 = this_5.ep4_0;
    vec3 old_ep5_0 = this_5.ep5_0;



    bool _S19 = perm_4 == 1U;

#line 341
    bool from_pair1_0;

#line 341
    if(_S19)
    {

#line 341
        from_pair1_0 = true;

#line 341
    }
    else
    {

#line 341
        from_pair1_0 = perm_4 == 5U;

#line 341
    }
    bool _S20 = perm_4 == 2U;

#line 342
    bool from_pair2_0;

#line 342
    if(_S20)
    {

#line 342
        from_pair2_0 = true;

#line 342
    }
    else
    {

#line 342
        from_pair2_0 = perm_4 == 4U;

#line 342
    }

#line 342
    vec3 _S21;
    if(from_pair1_0)
    {

#line 343
        _S21 = old_ep2_0;

#line 343
    }
    else
    {

#line 343
        if(from_pair2_0)
        {

#line 343
            _S21 = old_ep4_0;

#line 343
        }
        else
        {

#line 343
            _S21 = old_ep0_0;

#line 343
        }

#line 343
    }

#line 343
    this_5.ep0_0 = _S21;
    if(from_pair1_0)
    {

#line 344
        _S21 = old_ep3_0;

#line 344
    }
    else
    {

#line 344
        if(from_pair2_0)
        {

#line 344
            _S21 = old_ep5_0;

#line 344
        }
        else
        {

#line 344
            _S21 = old_ep1_0;

#line 344
        }

#line 344
    }

#line 344
    this_5.ep1_0 = _S21;

#line 344
    bool from_pair0_0;



    if(_S19)
    {

#line 348
        from_pair0_0 = true;

#line 348
    }
    else
    {

#line 348
        from_pair0_0 = perm_4 == 4U;

#line 348
    }
    bool _S22 = perm_4 == 3U;

#line 349
    if(_S22)
    {

#line 349
        from_pair2_0 = true;

#line 349
    }
    else
    {

#line 349
        from_pair2_0 = perm_4 == 5U;

#line 349
    }
    if(from_pair0_0)
    {

#line 350
        _S21 = old_ep0_0;

#line 350
    }
    else
    {

#line 350
        if(from_pair2_0)
        {

#line 350
            _S21 = old_ep4_0;

#line 350
        }
        else
        {

#line 350
            _S21 = old_ep2_0;

#line 350
        }

#line 350
    }

#line 350
    this_5.ep2_0 = _S21;
    if(from_pair0_0)
    {

#line 351
        _S21 = old_ep1_0;

#line 351
    }
    else
    {

#line 351
        if(from_pair2_0)
        {

#line 351
            _S21 = old_ep5_0;

#line 351
        }
        else
        {

#line 351
            _S21 = old_ep3_0;

#line 351
        }

#line 351
    }

#line 351
    this_5.ep3_0 = _S21;



    if(_S20)
    {

#line 355
        from_pair0_0 = true;

#line 355
    }
    else
    {

#line 355
        from_pair0_0 = perm_4 == 5U;

#line 355
    }
    if(_S22)
    {

#line 356
        from_pair1_0 = true;

#line 356
    }
    else
    {

#line 356
        from_pair1_0 = perm_4 == 4U;

#line 356
    }
    if(from_pair0_0)
    {

#line 357
        _S21 = old_ep0_0;

#line 357
    }
    else
    {

#line 357
        if(from_pair1_0)
        {

#line 357
            _S21 = old_ep2_0;

#line 357
        }
        else
        {

#line 357
            _S21 = old_ep4_0;

#line 357
        }

#line 357
    }

#line 357
    this_5.ep4_0 = _S21;
    if(from_pair0_0)
    {

#line 358
        _S21 = old_ep1_0;

#line 358
    }
    else
    {

#line 358
        if(from_pair1_0)
        {

#line 358
            _S21 = old_ep3_0;

#line 358
        }
        else
        {

#line 358
            _S21 = old_ep5_0;

#line 358
        }

#line 358
    }

#line 358
    this_5.ep5_0 = _S21;
    return;
}


#line 369
void CompressedTextureBlock3P_snap_0(inout CompressedTextureBlock3P_0 this_6)
{
    uint raw_map_2 = CompressedTextureBlock3P_pack_partition_indices_0(this_6);
    uint permutation_1 = 0U;
    uint final_mask_0 = 0U;

#line 373
    uint closest_seed_0;

    if((this_6.max_partitions_1) == 3U)
    {
        uint _S23 = get_closest_seed3_0(raw_map_2, permutation_1, final_mask_0);

#line 377
        closest_seed_0 = _S23;

#line 375
    }
    else
    {

        uint _S24 = get_closest_seed2_0(raw_map_2, permutation_1, final_mask_0);

#line 379
        closest_seed_0 = _S24;

#line 375
    }

#line 382
    this_6.astc_seed_0 = closest_seed_0;
    this_6.astc_partition_map_0 = final_mask_0;
    this_6.ideal_partition_map_0 = raw_map_2;
    this_6.perm_0 = permutation_1;


    CompressedTextureBlock3P_swap_colors_0(this_6, permutation_1);

#line 388
    int i_4 = 0;
    for(;;)
    {

#line 389
        if(i_4 < 16)
        {
        }
        else
        {

#line 389
            break;
        }
        this_6.partition_index_0.data_1[i_4] = int((final_mask_0 >> (2 * i_4)) & 3U);

#line 389
        i_4 = i_4 + 1;

#line 389
    }



    return;
}


#line 269
uint hamming_distance_2b_0(uint x_14, uint y_2)
{
    uint z_0 = x_14 ^ y_2;


    return bitCount((z_0 | (z_0 >> 1)) & 1431655765U);
}


#line 543
TextureBlock_0 CompressedTextureBlock3P_reconstruct_0(CompressedTextureBlock3P_0 this_7)
{
    if(g_params_0.debug_reconstruction_0)
    {

#line 546
        TextureBlock_0 outputBlock_1;

#line 546
        int i_5 = 0;
        for(;;)
        {

#line 547
            if(i_5 < 16)
            {
            }
            else
            {

#line 547
                break;
            }

            int partition_1 = clamp(int(float(NonDifferentiableIntWeights_operatorx5Bx5D_get_0(this_7.partition_index_0, i_5))), 0, 2);

#line 550
            vec3 c_0;


            if(partition_1 == 0)
            {

#line 553
                c_0 = vec3(1.0, 1.0, 1.0);

#line 553
            }
            else
            {

#line 553
                if(partition_1 == 1)
                {

#line 553
                    c_0 = vec3(0.5, 0.5, 0.5);

#line 553
                }
                else
                {

#line 553
                    c_0 = vec3(0.0, 0.0, 0.0);

#line 553
                }

#line 553
            }
            outputBlock_1.pixels_0[i_5] = c_0;

#line 547
            i_5 = i_5 + 1;

#line 547
        }

#line 556
        return outputBlock_1;
    }
    return CompressedTextureBlock3P_decompress3P_0(this_7);
}


#line 684
void CompressedTextureBlock3P_random_initialize_0(inout CompressedTextureBlock3P_0 _S25, uint _S26, inout PCG32_0 _S27)
{

#line 502
    uint _S28 = PCG32_nextUint_0(_S27);

#line 502
    _S25.ep0_0 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S28 % 16U];
    uint _S29 = PCG32_nextUint_0(_S27);

#line 503
    _S25.ep1_0 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S29 % 16U];

#line 503
    int i_6 = 0;
    for(;;)
    {

#line 504
        if(i_6 < 8)
        {
        }
        else
        {

#line 504
            break;
        }

#line 505
        uint _S30 = PCG32_nextUint_0(_S27);

#line 505
        vec3 _S31 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S30 % 16U];

#line 505
        _S25.ep1_0 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S30 % 16U];
        vec3 d_0 = _S31 - _S25.ep0_0;
        if((dot(d_0, d_0)) > 0.30000001192092896)
        {

#line 508
            break;
        }

#line 504
        i_6 = i_6 + 1;

#line 504
    }

#line 504
    i_6 = 0;

#line 511
    for(;;)
    {

#line 511
        if(i_6 < 8)
        {
        }
        else
        {

#line 511
            break;
        }

#line 512
        uint _S32 = PCG32_nextUint_0(_S27);

#line 512
        vec3 _S33 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S32 % 16U];

#line 512
        _S25.ep2_0 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S32 % 16U];
        if((dist_0(_S33, _S25.ep0_0, _S25.ep1_0)) > 0.30000001192092896)
        {

#line 514
            break;
        }

#line 511
        i_6 = i_6 + 1;

#line 511
    }

#line 511
    i_6 = 0;

#line 517
    for(;;)
    {

#line 517
        if(i_6 < 8)
        {
        }
        else
        {

#line 517
            break;
        }

#line 518
        uint _S34 = PCG32_nextUint_0(_S27);

#line 518
        vec3 _S35 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S34 % 16U];

#line 518
        _S25.ep3_0 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S34 % 16U];
        if((dist_0(_S35, _S25.ep0_0, _S25.ep1_0)) > 0.30000001192092896)
        {

#line 520
            break;
        }

#line 517
        i_6 = i_6 + 1;

#line 517
    }

#line 517
    i_6 = 0;

#line 523
    for(;;)
    {

#line 523
        if(i_6 < 8)
        {
        }
        else
        {

#line 523
            break;
        }

#line 524
        uint _S36 = PCG32_nextUint_0(_S27);

#line 524
        vec3 _S37 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S36 % 16U];

#line 524
        _S25.ep4_0 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S36 % 16U];
        if((dist_0(_S37, _S25.ep0_0, _S25.ep1_0)) <= 0.30000001192092896)
        {

#line 526
            i_6 = i_6 + 1;

#line 523
            continue;
        }



        if((dist_0(_S25.ep4_0, _S25.ep2_0, _S25.ep3_0)) > 0.30000001192092896)
        {

#line 529
            break;
        }

#line 523
        i_6 = i_6 + 1;

#line 523
    }

#line 523
    i_6 = 0;

#line 532
    for(;;)
    {

#line 532
        if(i_6 < 8)
        {
        }
        else
        {

#line 532
            break;
        }

#line 533
        uint _S38 = PCG32_nextUint_0(_S27);

#line 533
        vec3 _S39 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S38 % 16U];

#line 533
        _S25.ep5_0 = g_groundtruth_0._data[uint(_S26)].pixels_0[_S38 % 16U];
        if((dist_0(_S39, _S25.ep0_0, _S25.ep1_0)) <= 0.30000001192092896)
        {

#line 535
            i_6 = i_6 + 1;

#line 532
            continue;
        }



        if((dist_0(_S25.ep5_0, _S25.ep2_0, _S25.ep3_0)) > 0.30000001192092896)
        {

#line 538
            break;
        }

#line 532
        i_6 = i_6 + 1;

#line 532
    }

#line 541
    return;
}


#line 2675 3
uint solve_pca_eps_0(CompressedTextureBlock3P_0 _S40, inout vec3 _S41, inout vec3 _S42, uint _S43, int _S44)
{

#line 565 0
    const vec3 _S45 = vec3(0.17000000178813934, 0.82999998331069946, 0.37999999523162842);
    vec3 _S46 = vec3(ivec3(0));

#line 566
    int i_7 = 0;

#line 566
    vec3 centroid_0 = _S46;

#line 566
    uint count_0 = 0U;



    [[unroll]]
    for(;;)
    {

#line 570
        if(i_7 < 16)
        {
        }
        else
        {

#line 570
            break;
        }
        if((NonDifferentiableIntWeights_operatorx5Bx5D_get_0(_S40.partition_index_0, i_7)) == _S44)
        {

            uint count_1 = count_0 + 1U;

#line 575
            centroid_0 = centroid_0 + g_groundtruth_0._data[uint(_S43)].pixels_0[i_7];

#line 575
            count_0 = count_1;

#line 572
        }

#line 570
        i_7 = i_7 + 1;

#line 570
    }

#line 579
    if(count_0 <= 1U)
    {

#line 580
        if(count_0 > 0U)
        {

#line 580
            centroid_0 = centroid_0 / float(count_0);

#line 580
        }
        else
        {

#line 580
            centroid_0 = _S46;

#line 580
        }

#line 580
        vec3 _S47 = saturate_0(centroid_0);

#line 580
        _S41 = _S47;
        _S42 = _S47;
        return count_0;
    }

    vec3 centroid_1 = centroid_0 / float(count_0);

#line 585
    i_7 = 0;

#line 585
    float xx_0 = 0.0;

#line 585
    float xy_0 = 0.0;

#line 585
    float xz_0 = 0.0;

#line 585
    float yy_0 = 0.0;

#line 585
    float yz_0 = 0.0;

#line 585
    float zz_0 = 0.0;



    [[unroll]]
    for(;;)
    {

#line 589
        if(i_7 < 16)
        {
        }
        else
        {

#line 589
            break;
        }
        if((NonDifferentiableIntWeights_operatorx5Bx5D_get_0(_S40.partition_index_0, i_7)) == _S44)
        {
            vec3 d_1 = g_groundtruth_0._data[uint(_S43)].pixels_0[i_7] - centroid_1;
            float _S48 = d_1.x;
            float _S49 = d_1.y;

#line 595
            float xy_1 = xy_0 + _S48 * _S49;
            float _S50 = d_1.z;

#line 596
            float xz_1 = xz_0 + _S48 * _S50;
            float yy_1 = yy_0 + _S49 * _S49;
            float yz_1 = yz_0 + _S49 * _S50;
            float zz_1 = zz_0 + _S50 * _S50;

#line 599
            xx_0 = xx_0 + _S48 * _S48;

#line 599
            xy_0 = xy_1;

#line 599
            xz_0 = xz_1;

#line 599
            yy_0 = yy_1;

#line 599
            yz_0 = yz_1;

#line 599
            zz_0 = zz_1;

#line 591
        }

#line 589
        i_7 = i_7 + 1;

#line 589
    }

#line 589
    vec3 axis_0 = _S45;

#line 589
    int iter_0 = 0;

#line 605
    [[unroll]]
    for(;;)
    {

#line 605
        if(iter_0 < 4)
        {
        }
        else
        {

#line 605
            break;
        }
        vec3 new_axis_0;
        float _S51 = axis_0.x;

#line 608
        float _S52 = axis_0.y;

#line 608
        float _S53 = axis_0.z;

#line 608
        new_axis_0[0] = xx_0 * _S51 + xy_0 * _S52 + xz_0 * _S53;
        new_axis_0[1] = xy_0 * _S51 + yy_0 * _S52 + yz_0 * _S53;
        new_axis_0[2] = xz_0 * _S51 + yz_0 * _S52 + zz_0 * _S53;
        vec3 _S54 = new_axis_0;

#line 605
        int _S55 = iter_0 + 1;

#line 605
        axis_0 = _S54;

#line 605
        iter_0 = _S55;

#line 605
    }

#line 614
    if((dot(axis_0, axis_0)) < 9.99999993922529029e-09)
    {

#line 615
        vec3 _S56 = saturate_0(centroid_1);

#line 615
        _S41 = _S56;
        _S42 = _S56;
        return count_0;
    }

    vec3 axis_1 = normalize(axis_0);

#line 620
    float min_t_0 = 1000.0;

#line 620
    float max_t_0 = -1000.0;

#line 620
    i_7 = 0;

#line 625
    [[unroll]]
    for(;;)
    {

#line 625
        if(i_7 < 16)
        {
        }
        else
        {

#line 625
            break;
        }
        if((NonDifferentiableIntWeights_operatorx5Bx5D_get_0(_S40.partition_index_0, i_7)) == _S44)
        {

            float t_0 = dot(g_groundtruth_0._data[uint(_S43)].pixels_0[i_7] - centroid_1, axis_1);

            float _S57 = max(max_t_0, t_0);

#line 632
            min_t_0 = min(min_t_0, t_0);

#line 632
            max_t_0 = _S57;

#line 627
        }

#line 625
        i_7 = i_7 + 1;

#line 625
    }

#line 636
    _S41 = saturate_0(centroid_1 + axis_1 * min_t_0);
    _S42 = saturate_0(centroid_1 + axis_1 * max_t_0);
    return count_0;
}


#line 638
void solve_aabb_eps_0(CompressedTextureBlock3P_0 _S58, inout vec3 _S59, inout vec3 _S60, uint _S61, int _S62)
{



    vec3 _S63 = vec3(ivec3(1));

#line 643
    vec3 _S64 = vec3(ivec3(0));

#line 643
    vec3 min_ep_0 = _S63;

#line 643
    vec3 max_ep_0 = _S64;

#line 643
    int i_8 = 0;


    [[unroll]]
    for(;;)
    {

#line 646
        if(i_8 < 16)
        {
        }
        else
        {

#line 646
            break;
        }
        bool inlier_0 = (NonDifferentiableIntWeights_operatorx5Bx5D_get_0(_S58.partition_index_0, i_8)) == _S62;

#line 648
        vec3 _S65;
        if(inlier_0)
        {

#line 649
            _S65 = g_groundtruth_0._data[uint(_S61)].pixels_0[i_8];

#line 649
        }
        else
        {

#line 649
            _S65 = _S63;

#line 649
        }

#line 649
        vec3 _S66 = min(_S65, min_ep_0);

#line 649
        vec3 _S67;
        if(inlier_0)
        {

#line 650
            _S67 = g_groundtruth_0._data[uint(_S61)].pixels_0[i_8];

#line 650
        }
        else
        {

#line 650
            _S67 = _S64;

#line 650
        }

#line 650
        vec3 _S68 = max(_S67, max_ep_0);

#line 646
        int _S69 = i_8 + 1;

#line 646
        min_ep_0 = _S66;

#line 646
        max_ep_0 = _S68;

#line 646
        i_8 = _S69;

#line 646
    }

#line 653
    _S59 = saturate_0(min_ep_0);
    _S60 = saturate_0(max_ep_0);
    return;
}


#line 655
struct DiffPair_CompressedTextureBlock3P_0
{
    CompressedTextureBlock3P_0 primal_0;
    CompressedTextureBlock3P_Differential_0 differential_0;
};


#line 731
vec3 s_primal_ctx_lerp_0(vec3 _S70, vec3 _S71, vec3 _S72)
{

#line 731
    return mix(_S70, _S71, _S72);
}


#line 731
TextureBlock_0 s_primal_ctx_CompressedTextureBlock3P_decompress3P_0(CompressedTextureBlock3P_0 dpthis_0)
{

#line 485
    vec3 _S73 = vec3(0.0);

#line 485
    vec3  _S74[16] = { _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73 };



    uint _S75 = dpthis_0.max_partitions_1 - 1U;

#line 489
    bool _runFlag_0 = true;

#line 489
    uint i_9 = 0U;

#line 489
    TextureBlock_0 outputBlock_2;

#line 489
    outputBlock_2.pixels_0 = _S74;

#line 489
    int _pc_0 = 0;

#line 486
    for(;;)
    {

#line 486
        if(_runFlag_0)
        {
        }
        else
        {

#line 486
            break;
        }

#line 486
        int _S76;

#line 486
        if(i_9 < 16U)
        {
            int _S77 = int(i_9);

#line 488
            float _S78 = NonDifferentiableWeights_operatorx5Bx5D_get_0(dpthis_0.weights_0, _S77);
            uint partition_2 = clamp(uint(int(float(NonDifferentiableIntWeights_operatorx5Bx5D_get_0(dpthis_0.partition_index_0, _S77)))), 0U, _S75);
            bool _S79 = partition_2 == 0U;

#line 490
            vec3 e0_1;

#line 490
            if(_S79)
            {

#line 490
                e0_1 = dpthis_0.ep0_0;

#line 490
            }
            else
            {

#line 490
                if(partition_2 == 1U)
                {

#line 490
                    e0_1 = dpthis_0.ep2_0;

#line 490
                }
                else
                {

#line 490
                    e0_1 = dpthis_0.ep4_0;

#line 490
                }

#line 490
            }

#line 490
            vec3 e1_1;
            if(_S79)
            {

#line 491
                e1_1 = dpthis_0.ep1_0;

#line 491
            }
            else
            {

#line 491
                if(partition_2 == 1U)
                {

#line 491
                    e1_1 = dpthis_0.ep3_0;

#line 491
                }
                else
                {

#line 491
                    e1_1 = dpthis_0.ep5_0;

#line 491
                }

#line 491
            }

#line 491
            vec3 _S80 = s_primal_ctx_lerp_0(e0_1, e1_1, vec3(_S78));

#line 491
            TextureBlock_0 _S81 = outputBlock_2;

#line 491
            _S81.pixels_0[i_9] = _S80;

#line 491
            _S76 = 1;

#line 491
            outputBlock_2 = _S81;

#line 491
        }
        else
        {

#line 491
            _S76 = 0;

#line 491
        }

#line 491
        if(_S76 != 1)
        {

#line 491
            _runFlag_0 = false;

#line 491
        }

#line 491
        if(_runFlag_0)
        {

#line 491
            i_9 = i_9 + 1U;

#line 491
        }

#line 491
        _pc_0 = _pc_0 + 1;

#line 486
    }

#line 486
    return outputBlock_2;
}


#line 486
TextureBlock_0 TextureBlock_x24_syn_dzero_0()
{

#line 486
    TextureBlock_0 result_3;

#line 2239 3
    vec3 _S82 = vec3(0.0);

#line 2239
    result_3.pixels_0[0] = _S82;

#line 2239
    result_3.pixels_0[1] = _S82;

#line 2239
    result_3.pixels_0[2] = _S82;

#line 2239
    result_3.pixels_0[3] = _S82;

#line 2239
    result_3.pixels_0[4] = _S82;

#line 2239
    result_3.pixels_0[5] = _S82;

#line 2239
    result_3.pixels_0[6] = _S82;

#line 2239
    result_3.pixels_0[7] = _S82;

#line 2239
    result_3.pixels_0[8] = _S82;

#line 2239
    result_3.pixels_0[9] = _S82;

#line 2239
    result_3.pixels_0[10] = _S82;

#line 2239
    result_3.pixels_0[11] = _S82;

#line 2239
    result_3.pixels_0[12] = _S82;

#line 2239
    result_3.pixels_0[13] = _S82;

#line 2239
    result_3.pixels_0[14] = _S82;

#line 2239
    result_3.pixels_0[15] = _S82;

#line 2239
    return result_3;
}


#line 2239
TextureBlock_0 TextureBlock_x24_syn_dadd_0(TextureBlock_0 SLANG_anonymous_0_0, TextureBlock_0 SLANG_anonymous_1_0)
{

#line 2239
    TextureBlock_0 result_4;

#line 2239
    result_4.pixels_0[0] = SLANG_anonymous_0_0.pixels_0[0] + SLANG_anonymous_1_0.pixels_0[0];

#line 2239
    result_4.pixels_0[1] = SLANG_anonymous_0_0.pixels_0[1] + SLANG_anonymous_1_0.pixels_0[1];

#line 2239
    result_4.pixels_0[2] = SLANG_anonymous_0_0.pixels_0[2] + SLANG_anonymous_1_0.pixels_0[2];

#line 2239
    result_4.pixels_0[3] = SLANG_anonymous_0_0.pixels_0[3] + SLANG_anonymous_1_0.pixels_0[3];

#line 2239
    result_4.pixels_0[4] = SLANG_anonymous_0_0.pixels_0[4] + SLANG_anonymous_1_0.pixels_0[4];

#line 2239
    result_4.pixels_0[5] = SLANG_anonymous_0_0.pixels_0[5] + SLANG_anonymous_1_0.pixels_0[5];

#line 2239
    result_4.pixels_0[6] = SLANG_anonymous_0_0.pixels_0[6] + SLANG_anonymous_1_0.pixels_0[6];

#line 2239
    result_4.pixels_0[7] = SLANG_anonymous_0_0.pixels_0[7] + SLANG_anonymous_1_0.pixels_0[7];

#line 2239
    result_4.pixels_0[8] = SLANG_anonymous_0_0.pixels_0[8] + SLANG_anonymous_1_0.pixels_0[8];

#line 2239
    result_4.pixels_0[9] = SLANG_anonymous_0_0.pixels_0[9] + SLANG_anonymous_1_0.pixels_0[9];

#line 2239
    result_4.pixels_0[10] = SLANG_anonymous_0_0.pixels_0[10] + SLANG_anonymous_1_0.pixels_0[10];

#line 2239
    result_4.pixels_0[11] = SLANG_anonymous_0_0.pixels_0[11] + SLANG_anonymous_1_0.pixels_0[11];

#line 2239
    result_4.pixels_0[12] = SLANG_anonymous_0_0.pixels_0[12] + SLANG_anonymous_1_0.pixels_0[12];

#line 2239
    result_4.pixels_0[13] = SLANG_anonymous_0_0.pixels_0[13] + SLANG_anonymous_1_0.pixels_0[13];

#line 2239
    result_4.pixels_0[14] = SLANG_anonymous_0_0.pixels_0[14] + SLANG_anonymous_1_0.pixels_0[14];

#line 2239
    result_4.pixels_0[15] = SLANG_anonymous_0_0.pixels_0[15] + SLANG_anonymous_1_0.pixels_0[15];

#line 2239
    return result_4;
}


#line 2239
void s_bwd_prop_lerp_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S83, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S84, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S85, vec3 _S86)
{

#line 2239
    _d_lerp_vector_0(_S83, _S84, _S85, _S86);

#line 2239
    return;
}


#line 483 0
void s_bwd_prop_CompressedTextureBlock3P_decompress3P_0(inout DiffPair_CompressedTextureBlock3P_0 dpthis_1, TextureBlock_0 _s_dOut_0)
{

#line 483
    NonDifferentiableWeights_0 _S87 = dpthis_1.primal_0.weights_0;

#line 483
    NonDifferentiableIntWeights_0 _S88 = dpthis_1.primal_0.partition_index_0;

#line 489
    uint _S89 = dpthis_1.primal_0.max_partitions_1 - 1U;

#line 489
    vec3 _S90 = dpthis_1.primal_0.ep0_0;

#line 489
    vec3 _S91 = dpthis_1.primal_0.ep1_0;

#line 489
    vec3 _S92 = dpthis_1.primal_0.ep2_0;

#line 489
    vec3 _S93 = dpthis_1.primal_0.ep4_0;

#line 489
    vec3 _S94 = dpthis_1.primal_0.ep3_0;

#line 489
    vec3 _S95 = dpthis_1.primal_0.ep5_0;

#line 2239 3
    vec3 _S96 = vec3(0.0);

#line 485 0
    TextureBlock_0 _S97 = TextureBlock_x24_syn_dzero_0();

#line 485
    TextureBlock_0 _S98 = TextureBlock_x24_syn_dadd_0(_s_dOut_0, _S97);

#line 485
    int _dc_0 = 16;

#line 485
    TextureBlock_0 _S99 = _S98;

#line 485
    vec3 _S100 = _S96;

#line 485
    vec3 _S101 = _S96;

#line 485
    vec3 _S102 = _S96;

#line 485
    vec3 _S103 = _S96;

#line 485
    vec3 _S104 = _S96;

#line 485
    vec3 _S105 = _S96;

#line 485
    vec3 _S106 = _S96;
    for(;;)
    {

#line 486
        uint _S107 = uint(_dc_0);

#line 486
        if(_dc_0 >= 0)
        {
        }
        else
        {

#line 486
            break;
        }

#line 486
        bool _S108 = _S107 < 16U;

#line 486
        vec3 e0_2;

#line 486
        vec3 e1_2;

#line 486
        vec3 _S109;

#line 486
        bool _S110;

#line 486
        bool _S111;

#line 486
        bool _S112;

#line 486
        if(_S108)
        {
            int _S113 = int(_S107);

#line 488
            float _S114 = NonDifferentiableWeights_operatorx5Bx5D_get_0(_S87, _S113);
            uint partition_3 = clamp(uint(int(float(NonDifferentiableIntWeights_operatorx5Bx5D_get_0(_S88, _S113)))), 0U, _S89);
            bool _S115 = partition_3 == 0U;

#line 490
            if(_S115)
            {

#line 490
                e0_2 = _S90;

#line 490
                _S110 = false;

#line 490
            }
            else
            {

#line 490
                bool _S116 = partition_3 == 1U;

#line 490
                if(_S116)
                {

#line 490
                    e0_2 = _S92;

#line 490
                }
                else
                {

#line 490
                    e0_2 = _S93;

#line 490
                }

#line 490
                _S110 = _S116;

#line 490
            }
            if(_S115)
            {

#line 491
                e1_2 = _S91;

#line 491
                _S111 = false;

#line 491
            }
            else
            {

#line 491
                bool _S117 = partition_3 == 1U;

#line 491
                if(_S117)
                {

#line 491
                    e1_2 = _S94;

#line 491
                }
                else
                {

#line 491
                    e1_2 = _S95;

#line 491
                }

#line 491
                _S111 = _S117;

#line 491
            }

#line 490
            bool _S118 = _S110;

#line 490
            _S109 = vec3(_S114);

#line 490
            _S110 = _S115;

#line 490
            _S112 = _S118;

#line 490
        }
        else
        {

#line 490
            e0_2 = _S96;

#line 490
            e1_2 = _S96;

#line 490
            _S109 = _S96;

#line 490
            _S110 = false;

#line 490
            _S111 = false;

#line 490
            _S112 = false;

#line 490
        }

#line 485
        TextureBlock_0 _S119 = TextureBlock_x24_syn_dadd_0(_S99, _S97);

#line 485
        if(_S108)
        {

#line 485
            TextureBlock_0 _S120 = _S119;

#line 485
            _S120.pixels_0[_S107] = _S96;

#line 492
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S121;

#line 492
            _S121.primal_0 = e0_2;

#line 492
            _S121.differential_0 = _S96;

#line 492
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S122;

#line 492
            _S122.primal_0 = e1_2;

#line 492
            _S122.differential_0 = _S96;

#line 492
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S123;

#line 492
            _S123.primal_0 = _S109;

#line 492
            _S123.differential_0 = _S96;

#line 492
            s_bwd_prop_lerp_0(_S121, _S122, _S123, _S119.pixels_0[_S107]);

#line 492
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S124 = _S122;

#line 485
            TextureBlock_0 _S125 = TextureBlock_x24_syn_dadd_0(_S120, _S97);

#line 490
            vec3 _S126 = _S121.differential_0 + _S106;

#line 490
            vec3 _S127;

#line 490
            vec3 _S128;

#line 490
            vec3 _S129;

#line 490
            if(_S110)
            {

#line 2246 3
                vec3 _S130 = _S124.differential_0 + _S104;

#line 2246
                _S127 = _S100;

#line 2246
                _S128 = _S101;

#line 2246
                _S129 = _S130;

#line 2246
            }
            else
            {

#line 2246
                if(_S111)
                {

#line 2246
                    vec3 _S131 = _S124.differential_0 + _S101;

#line 2246
                    _S127 = _S100;

#line 2246
                    _S128 = _S131;

#line 2246
                }
                else
                {

#line 2246
                    _S127 = _S124.differential_0 + _S100;

#line 2246
                    _S128 = _S101;

#line 2246
                }

#line 2246
                _S129 = _S104;

#line 2246
            }

#line 2246
            vec3 _S132;

#line 2246
            vec3 _S133;

#line 2246
            vec3 _S134;

#line 2246
            if(_S110)
            {

#line 2246
                vec3 _S135 = _S126 + _S105;

#line 2246
                _S132 = _S102;

#line 2246
                _S133 = _S103;

#line 2246
                _S134 = _S135;

#line 2246
            }
            else
            {

#line 2246
                if(_S112)
                {

#line 2246
                    vec3 _S136 = _S126 + _S103;

#line 2246
                    _S132 = _S102;

#line 2246
                    _S133 = _S136;

#line 2246
                }
                else
                {

#line 2246
                    _S132 = _S126 + _S102;

#line 2246
                    _S133 = _S103;

#line 2246
                }

#line 2246
                _S134 = _S105;

#line 2246
            }

#line 2246
            _S99 = _S125;

#line 2246
            _S100 = _S127;

#line 2246
            _S101 = _S128;

#line 2246
            _S102 = _S132;

#line 2246
            _S103 = _S133;

#line 2246
            _S104 = _S129;

#line 2246
            _S105 = _S134;

#line 2246
            _S106 = _S96;

#line 2246
        }
        else
        {

#line 2246
            _S99 = TextureBlock_x24_syn_dadd_0(_S119, _S97);

#line 2246
        }

#line 2246
        _dc_0 = _dc_0 - 1;

#line 486 0
    }

#line 486
    CompressedTextureBlock3P_Differential_0 _S137 = CompressedTextureBlock3P_x24_syn_dzero_0();

#line 486
    _S137.ep5_1 = _S100;

#line 486
    _S137.ep3_1 = _S101;

#line 486
    _S137.ep4_1 = _S102;

#line 486
    _S137.ep2_1 = _S103;

#line 486
    _S137.ep1_2 = _S104;

#line 486
    _S137.ep0_2 = _S105;

#line 486
    dpthis_1.primal_0 = dpthis_1.primal_0;

#line 486
    dpthis_1.differential_0 = _S137;

#line 483
    return;
}


#line 483
void s_bwd_prop_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S138, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S139, float _S140)
{

#line 483
    _d_dot_0(_S138, _S139, _S140);

#line 483
    return;
}


#line 483
void s_bwd_prop_loss_3P_0(uint _S141, inout DiffPair_CompressedTextureBlock3P_0 _S142, float _S143)
{

#line 483
    CompressedTextureBlock3P_0 _S144 = _S142.primal_0;

#line 483
    TextureBlock_0 _S145 = s_primal_ctx_CompressedTextureBlock3P_decompress3P_0(_S142.primal_0);

#line 2239 3
    vec3 _S146 = vec3(0.0);

#line 2239
    int _dc_1 = 16;

#line 2239
    float _S147 = _S143;

#line 2239
    vec3  _S148[16];

#line 2239
    _S148[0] = _S146;

#line 2239
    _S148[1] = _S146;

#line 2239
    _S148[2] = _S146;

#line 2239
    _S148[3] = _S146;

#line 2239
    _S148[4] = _S146;

#line 2239
    _S148[5] = _S146;

#line 2239
    _S148[6] = _S146;

#line 2239
    _S148[7] = _S146;

#line 2239
    _S148[8] = _S146;

#line 2239
    _S148[9] = _S146;

#line 2239
    _S148[10] = _S146;

#line 2239
    _S148[11] = _S146;

#line 2239
    _S148[12] = _S146;

#line 2239
    _S148[13] = _S146;

#line 2239
    _S148[14] = _S146;

#line 2239
    _S148[15] = _S146;

#line 665 0
    for(;;)
    {

#line 665
        if(_dc_1 >= 0)
        {
        }
        else
        {

#line 665
            break;
        }

#line 665
        bool _S149 = _dc_1 < 16;

#line 665
        int _S150;

#line 665
        vec3 _S151;

#line 665
        if(_S149)
        {
            vec3 diff_0 = _S145.pixels_0[_dc_1] - g_groundtruth_0._data[uint(_S141)].pixels_0[_dc_1];

#line 667
            _S150 = 1;

#line 667
            _S151 = diff_0;

#line 667
        }
        else
        {

#line 667
            _S150 = 0;

#line 667
            _S151 = _S146;

#line 667
        }

#line 667
        float _S152;

#line 667
        float _S153;

#line 667
        if(!(_S150 != 1))
        {

#line 667
            _S152 = _S147;

#line 667
            _S153 = 0.0;

#line 667
        }
        else
        {

#line 667
            _S152 = 0.0;

#line 667
            _S153 = _S147;

#line 667
        }

#line 667
        if(_S149)
        {

#line 668
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S154;

#line 668
            _S154.primal_0 = _S151;

#line 668
            _S154.differential_0 = _S146;

#line 668
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S155;

#line 668
            _S155.primal_0 = _S151;

#line 668
            _S155.differential_0 = _S146;

#line 668
            s_bwd_prop_dot_0(_S154, _S155, _S152);

#line 667
            vec3 _S156 = _S155.differential_0 + _S154.differential_0;

#line 663
            float _S157 = _S152 + _S153;

#line 663
            vec3  _S158[16];

#line 663
            _S158[0] = _S146;

#line 663
            _S158[1] = _S146;

#line 663
            _S158[2] = _S146;

#line 663
            _S158[3] = _S146;

#line 663
            _S158[4] = _S146;

#line 663
            _S158[5] = _S146;

#line 663
            _S158[6] = _S146;

#line 663
            _S158[7] = _S146;

#line 663
            _S158[8] = _S146;

#line 663
            _S158[9] = _S146;

#line 663
            _S158[10] = _S146;

#line 663
            _S158[11] = _S146;

#line 663
            _S158[12] = _S146;

#line 663
            _S158[13] = _S146;

#line 663
            _S158[14] = _S146;

#line 663
            _S158[15] = _S146;

#line 663
            _S158[_dc_1] = _S156;

#line 2246 3
            vec3 _S159 = _S148[0] + _S158[0];

#line 2246
            vec3 _S160 = _S148[1] + _S158[1];

#line 2246
            vec3 _S161 = _S148[2] + _S158[2];

#line 2246
            vec3 _S162 = _S148[3] + _S158[3];

#line 2246
            vec3 _S163 = _S148[4] + _S158[4];

#line 2246
            vec3 _S164 = _S148[5] + _S158[5];

#line 2246
            vec3 _S165 = _S148[6] + _S158[6];

#line 2246
            vec3 _S166 = _S148[7] + _S158[7];

#line 2246
            vec3 _S167 = _S148[8] + _S158[8];

#line 2246
            vec3 _S168 = _S148[9] + _S158[9];

#line 2246
            vec3 _S169 = _S148[10] + _S158[10];

#line 2246
            vec3 _S170 = _S148[11] + _S158[11];

#line 2246
            vec3 _S171 = _S148[12] + _S158[12];

#line 2246
            vec3 _S172 = _S148[13] + _S158[13];

#line 2246
            vec3 _S173 = _S148[14] + _S158[14];

#line 2246
            vec3 _S174 = _S148[15] + _S158[15];

#line 2246
            _S147 = _S157;

#line 2246
            _S148[0] = _S159;

#line 2246
            _S148[1] = _S160;

#line 2246
            _S148[2] = _S161;

#line 2246
            _S148[3] = _S162;

#line 2246
            _S148[4] = _S163;

#line 2246
            _S148[5] = _S164;

#line 2246
            _S148[6] = _S165;

#line 2246
            _S148[7] = _S166;

#line 2246
            _S148[8] = _S167;

#line 2246
            _S148[9] = _S168;

#line 2246
            _S148[10] = _S169;

#line 2246
            _S148[11] = _S170;

#line 2246
            _S148[12] = _S171;

#line 2246
            _S148[13] = _S172;

#line 2246
            _S148[14] = _S173;

#line 2246
            _S148[15] = _S174;

#line 2246
        }
        else
        {

#line 2246
            _S147 = _S153;

#line 2246
        }

#line 2246
        _dc_1 = _dc_1 - 1;

#line 665 0
    }

#line 662
    TextureBlock_0 _S175 = TextureBlock_x24_syn_dzero_0();

#line 662
    _S175.pixels_0 = _S148;

#line 662
    CompressedTextureBlock3P_Differential_0 _S176 = CompressedTextureBlock3P_x24_syn_dzero_0();

#line 662
    DiffPair_CompressedTextureBlock3P_0 _S177;

#line 662
    _S177.primal_0 = _S144;

#line 662
    _S177.differential_0 = _S176;

#line 662
    s_bwd_prop_CompressedTextureBlock3P_decompress3P_0(_S177, _S175);

#line 662
    _S142.primal_0 = _S142.primal_0;

#line 662
    _S142.differential_0 = _S177.differential_0;

#line 658
    return;
}


#line 658
void s_bwd_loss_3P_0(uint _S178, inout DiffPair_CompressedTextureBlock3P_0 _S179, float _S180)
{

#line 658
    s_bwd_prop_loss_3P_0(_S178, _S179, _S180);

#line 658
    return;
}


#line 658
void CompressedTextureBlock3P_solve_weights_0(inout CompressedTextureBlock3P_0 _S181, uint _S182)
{

#line 413
    vec3 L1_0 = _S181.ep1_0 - _S181.ep0_0;
    vec3 L2_0 = _S181.ep3_0 - _S181.ep2_0;
    vec3 L3_0 = _S181.ep5_0 - _S181.ep4_0;
    float _S183 = 1.0 / (dot(L1_0, L1_0) + 9.99999997475242708e-07);
    float _S184 = 1.0 / (dot(L2_0, L2_0) + 9.99999997475242708e-07);
    float _S185 = 1.0 / (dot(L3_0, L3_0) + 9.99999997475242708e-07);

#line 418
    int i_10 = 0;
    for(;;)
    {

#line 419
        if(i_10 < 16)
        {
        }
        else
        {

#line 419
            break;
        }

#line 419
        vec3 C_0 = g_groundtruth_0._data[uint(_S182)].pixels_0[i_10];


        int p_0 = NonDifferentiableIntWeights_operatorx5Bx5D_get_0(_S181.partition_index_0, i_10);
        bool _S186 = p_0 == 0;

#line 423
        float pDotL_1;

#line 423
        if(_S186)
        {

#line 423
            pDotL_1 = dot(C_0 - _S181.ep0_0, L1_0);

#line 423
        }
        else
        {

#line 423
            if(p_0 == 1)
            {

#line 423
                pDotL_1 = dot(C_0 - _S181.ep2_0, L2_0);

#line 423
            }
            else
            {

#line 423
                pDotL_1 = dot(C_0 - _S181.ep4_0, L3_0);

#line 423
            }

#line 423
        }

#line 423
        float invLenSq_1;
        if(_S186)
        {

#line 424
            invLenSq_1 = _S183;

#line 424
        }
        else
        {

#line 424
            if(p_0 == 1)
            {

#line 424
                invLenSq_1 = _S184;

#line 424
            }
            else
            {

#line 424
                invLenSq_1 = _S185;

#line 424
            }

#line 424
        }

        _S181.weights_0.data_0[i_10] = saturate_1(pDotL_1 * invLenSq_1);

#line 419
        i_10 = i_10 + 1;

#line 419
    }

#line 428
    return;
}


#line 428
uint CompressedTextureBlock3P_solve_partition_0(inout CompressedTextureBlock3P_0 _S187, uint _S188)
{


    vec3 L1_1 = _S187.ep1_0 - _S187.ep0_0;
    vec3 L2_1 = _S187.ep3_0 - _S187.ep2_0;
    vec3 L3_1 = _S187.ep5_0 - _S187.ep4_0;
    float _S189 = 1.0 / (dot(L1_1, L1_1) + 9.99999997475242708e-07);
    float _S190 = 1.0 / (dot(L2_1, L2_1) + 9.99999997475242708e-07);
    float _S191 = 1.0 / (dot(L3_1, L3_1) + 9.99999997475242708e-07);

#line 437
    int i_11 = 0;

#line 437
    uint partitions_0 = 0U;

    for(;;)
    {

#line 439
        if(i_11 < 16)
        {
        }
        else
        {

#line 439
            break;
        }

        vec3 P1_0 = g_groundtruth_0._data[uint(_S188)].pixels_0[i_11] - _S187.ep0_0;
        vec3 P2_0 = g_groundtruth_0._data[uint(_S188)].pixels_0[i_11] - _S187.ep2_0;
        vec3 P3_0 = g_groundtruth_0._data[uint(_S188)].pixels_0[i_11] - _S187.ep4_0;
        float pDotL1_0 = dot(P1_0, L1_1);
        float pDotL2_0 = dot(P2_0, L2_1);
        float pDotL3_0 = dot(P3_0, L3_1);
        float d1_1 = CompressedTextureBlock3P_distSq_0(P1_0, L1_1, pDotL1_0, _S189);
        float d2_1 = CompressedTextureBlock3P_distSq_0(P2_0, L2_1, pDotL2_0, _S190);

#line 449
        float d3_1;
        if((_S187.max_partitions_1) == 3U)
        {

#line 450
            d3_1 = CompressedTextureBlock3P_distSq_0(P3_0, L3_1, pDotL3_0, _S191);

#line 450
        }
        else
        {

#line 450
            d3_1 = 1000.0;

#line 450
        }
        uint p_1 = CompressedTextureBlock3P_argmin_0(d1_1, d2_1, d3_1);
        _S187.partition_index_0.data_1[i_11] = int(p_1);
        uint partitions_1 = partitions_0 | uint(1 << p_1);


        bool _S192 = p_1 == 0U;

#line 456
        float pDotL_2;

#line 456
        if(_S192)
        {

#line 456
            pDotL_2 = pDotL1_0;

#line 456
        }
        else
        {

#line 456
            if(p_1 == 1U)
            {

#line 456
                pDotL_2 = pDotL2_0;

#line 456
            }
            else
            {

#line 456
                pDotL_2 = pDotL3_0;

#line 456
            }

#line 456
        }

#line 456
        float invLenSq_2;
        if(_S192)
        {

#line 457
            invLenSq_2 = _S189;

#line 457
        }
        else
        {

#line 457
            if(p_1 == 1U)
            {

#line 457
                invLenSq_2 = _S190;

#line 457
            }
            else
            {

#line 457
                invLenSq_2 = _S191;

#line 457
            }

#line 457
        }

        _S187.weights_0.data_0[i_11] = saturate_1(pDotL_2 * invLenSq_2);

#line 439
        i_11 = i_11 + 1;

#line 439
        partitions_0 = partitions_1;

#line 439
    }

#line 461
    return partitions_0;
}


#line 461
void CompressedTextureBlock3P_one_step_solve_partition_0(inout CompressedTextureBlock3P_0 _S193, uint _S194, bool _S195)
{



    if((_S193.max_partitions_1) == 1U)
    {

#line 466
        CompressedTextureBlock3P_solve_weights_0(_S193, _S194);

        return;
    }

#line 468
    uint _S196 = CompressedTextureBlock3P_solve_partition_0(_S193, _S194);

#line 468
    bool single_partition_0;

#line 474
    if((_S193.max_partitions_1) > 1U)
    {

#line 474
        if(_S196 == 1U)
        {

#line 474
            single_partition_0 = true;

#line 474
        }
        else
        {

#line 474
            single_partition_0 = _S196 == 2U;

#line 474
        }

#line 474
        if(single_partition_0)
        {

#line 474
            single_partition_0 = true;

#line 474
        }
        else
        {

#line 474
            single_partition_0 = _S196 == 4U;

#line 474
        }

#line 474
    }
    else
    {

#line 474
        single_partition_0 = false;

#line 474
    }
    if(_S195)
    {

#line 475
        single_partition_0 = true;

#line 475
    }

#line 475
    if(single_partition_0)
    {

#line 476
        CompressedTextureBlock3P_snap_0(_S193);

#line 476
        CompressedTextureBlock3P_solve_weights_0(_S193, _S194);

#line 475
    }

#line 480
    return;
}


#line 480
float loss_3P_0(uint _S197, CompressedTextureBlock3P_0 _S198)
{

#line 662
    TextureBlock_0 _S199 = CompressedTextureBlock3P_decompress3P_0(_S198);

#line 662
    int i_12 = 0;

#line 662
    float totalError_0 = 0.0;


    for(;;)
    {

#line 665
        if(i_12 < 16)
        {
        }
        else
        {

#line 665
            break;
        }
        vec3 diff_1 = _S199.pixels_0[i_12] - g_groundtruth_0._data[uint(_S197)].pixels_0[i_12];
        float totalError_1 = totalError_0 + dot(diff_1, diff_1);

#line 665
        i_12 = i_12 + 1;

#line 665
        totalError_0 = totalError_1;

#line 665
    }

#line 671
    return totalError_0;
}


#line 684
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 686
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_params_0.num_blocks_0))
    {

#line 687
        return;
    }

#line 688
    uvec2 _S200 = (clockRealtime2x32EXT());

#line 688
    g_diagnostics_0._data[uint(blockIdx_0)].start_clock_0 = _S200;

    uint perm_5 = 0U;
    CompressedTextureBlock3P_0 block_0 = g_compressedBlock3P_0._data[uint(blockIdx_0)];

    float _S201 = g_params_0.learning_rate_0;
    uint steps_1 = g_params_0.steps_0;
    bool _S202 = int(g_params_0.snap_0) > 0;

#line 695
    uint _S203;
    if((g_params_0.snap_steps_0) == 0U)
    {

#line 696
        _S203 = uint(float(steps_1) * 0.5);

#line 696
    }
    else
    {

#line 696
        _S203 = steps_1 - g_params_0.snap_steps_0;

#line 696
    }

    uint _S204 = g_params_0.exact_steps_0;

    PCG32_0 prng_0 = PCG32_x24init_0(0U);
    block_0.max_partitions_1 = g_params_0.max_partitions_0;

#line 701
    CompressedTextureBlock3P_random_initialize_0(block_0, blockIdx_0, prng_0);

#line 701
    int i_13 = 0;

    for(;;)
    {

#line 703
        if(i_13 < 16)
        {
        }
        else
        {

#line 703
            break;
        }

#line 704
        if(uint(NonDifferentiableIntWeights_operatorx5Bx5D_get_0(block_0.partition_index_0, i_13)) >= (block_0.max_partitions_1))
        {

#line 705
            uint _S205 = PCG32_nextUint_0(prng_0);

#line 705
            uint _S206 = _S205 % block_0.max_partitions_1;

#line 705
            block_0.partition_index_0.data_1[i_13] = int(_S206);

#line 704
        }

#line 703
        i_13 = i_13 + 1;

#line 703
    }

#line 709
    uint _S207 = max(1U, steps_1 / 20U);

#line 709
    int step_0 = 0;
    for(;;)
    {

#line 710
        uint _S208 = uint(step_0);

#line 710
        if(_S208 < steps_1)
        {
        }
        else
        {

#line 710
            break;
        }

#line 710
        bool _S209;


        if(_S204 > 0U)
        {

#line 713
            _S209 = _S208 >= 1U;

#line 713
        }
        else
        {

#line 713
            _S209 = false;

#line 713
        }

#line 713
        bool should_use_lsq_0;

#line 713
        if(_S209)
        {

#line 713
            should_use_lsq_0 = _S208 <= (1U + _S204);

#line 713
        }
        else
        {

#line 713
            should_use_lsq_0 = false;

#line 713
        }
        if(should_use_lsq_0)
        {


            if(g_params_0.use_pca_0)
            {

#line 718
                uint _S210 = solve_pca_eps_0(block_0, block_0.ep0_0, block_0.ep1_0, blockIdx_0, 0);

#line 718
                uint _S211 = solve_pca_eps_0(block_0, block_0.ep2_0, block_0.ep3_0, blockIdx_0, 1);

#line 718
                uint _S212 = solve_pca_eps_0(block_0, block_0.ep4_0, block_0.ep5_0, blockIdx_0, 2);

#line 718
            }
            else
            {

#line 718
                solve_aabb_eps_0(block_0, block_0.ep0_0, block_0.ep1_0, blockIdx_0, 0);

#line 718
                solve_aabb_eps_0(block_0, block_0.ep2_0, block_0.ep3_0, blockIdx_0, 1);

#line 718
                solve_aabb_eps_0(block_0, block_0.ep4_0, block_0.ep5_0, blockIdx_0, 2);

#line 718
            }

#line 714
        }
        else
        {

#line 730
            CompressedTextureBlock3P_Differential_0 _S213 = CompressedTextureBlock3P_x24_syn_dzero_0();

#line 730
            DiffPair_CompressedTextureBlock3P_0 cb_pair_0;

#line 730
            cb_pair_0.primal_0 = block_0;

#line 730
            cb_pair_0.differential_0 = _S213;

#line 730
            s_bwd_loss_3P_0(blockIdx_0, cb_pair_0, 1.0);


            block_0.ep0_0 = saturate_0(block_0.ep0_0 - cb_pair_0.differential_0.ep0_2 * _S201);
            block_0.ep1_0 = saturate_0(block_0.ep1_0 - cb_pair_0.differential_0.ep1_2 * _S201);
            block_0.ep2_0 = saturate_0(block_0.ep2_0 - cb_pair_0.differential_0.ep2_1 * _S201);
            block_0.ep3_0 = saturate_0(block_0.ep3_0 - cb_pair_0.differential_0.ep3_1 * _S201);
            block_0.ep4_0 = saturate_0(block_0.ep4_0 - cb_pair_0.differential_0.ep4_1 * _S201);
            block_0.ep5_0 = saturate_0(block_0.ep5_0 - cb_pair_0.differential_0.ep5_1 * _S201);

#line 714
        }

#line 714
        bool _S214;

#line 741
        if(_S202)
        {

#line 741
            if(_S208 >= _S203)
            {

#line 741
                _S214 = true;

#line 741
            }
            else
            {

#line 741
                _S214 = _S208 >= (steps_1 - 1U);

#line 741
            }

#line 741
        }
        else
        {

#line 741
            _S214 = false;

#line 741
        }

#line 741
        CompressedTextureBlock3P_one_step_solve_partition_0(block_0, blockIdx_0, _S214);

        uint _S215 = _S208 % _S207;

#line 743
        if(_S215 == 0U)
        {

#line 744
            uint iter_1 = _S208 / _S207;
            uvec2 _S216 = (clockRealtime2x32EXT());

#line 745
            g_diagnostics_0._data[uint(blockIdx_0)].timestamps_0[iter_1] = _S216;
            g_diagnostics_0._data[uint(blockIdx_0)].loss_log_0[iter_1] = loss_3P_0(blockIdx_0, block_0);

            uint pattern_2 = CompressedTextureBlock3P_pack_partition_indices_0(block_0);
            uint final_mask_1 = 0U;

            if((block_0.max_partitions_1) == 3U)
            {

#line 751
                uint _S217 = get_closest_seed3_0(pattern_2, perm_5, final_mask_1);

#line 751
            }
            else
            {

#line 752
                uint _S218 = get_closest_seed2_0(pattern_2, perm_5, final_mask_1);

#line 751
            }

#line 751
            uint _S219;


            if((block_0.max_partitions_1) == 3U)
            {

#line 754
                uint _S220 = best_perm_distance_s3_0(pattern_2, final_mask_1, perm_5);

#line 754
                _S219 = _S220;

#line 754
            }
            else
            {

#line 755
                uint _S221 = best_perm_distance_s2_0(pattern_2, final_mask_1, perm_5);

#line 755
                _S219 = _S221;

#line 754
            }

#line 753
            g_diagnostics_0._data[uint(blockIdx_0)].partition_hamming_error_log_0[iter_1] = _S219;


            g_diagnostics_0._data[uint(blockIdx_0)].ideal_partition_log_0[iter_1] = pattern_2;

#line 761
            g_diagnostics_0._data[uint(blockIdx_0)].partition_count_0[iter_1] = uint((hamming_distance_2b_0(pattern_2, 0U)) < 16U) + uint((hamming_distance_2b_0(pattern_2, 1431655765U)) < 16U) + uint((hamming_distance_2b_0(pattern_2, 2863311530U)) < 16U);

#line 743
        }

#line 710
        step_0 = step_0 + 1;

#line 710
    }

#line 765
    uvec2 _S222 = (clockRealtime2x32EXT());

#line 765
    g_diagnostics_0._data[uint(blockIdx_0)].optim_ended_clock_0 = _S222;
    g_compressedBlock3P_0._data[uint(blockIdx_0)] = block_0;
    g_reconstructed_0._data[uint(blockIdx_0)] = CompressedTextureBlock3P_reconstruct_0(block_0);
    uint _S223 = best_perm_distance_s3_0(block_0.ideal_partition_map_0, block_0.astc_partition_map_0, perm_5);

#line 768
    g_diagnostics_0._data[uint(blockIdx_0)].partition_hamming_error_0 = _S223;
    g_final_loss_0._data[uint(blockIdx_0)] = loss_3P_0(blockIdx_0, block_0);
    uvec2 _S224 = (clockRealtime2x32EXT());

#line 770
    g_diagnostics_0._data[uint(blockIdx_0)].finished_clock_0 = _S224;
    return;
}

