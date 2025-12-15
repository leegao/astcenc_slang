#version 450
#extension GL_EXT_shader_8bit_storage : require
#extension GL_EXT_shader_explicit_arithmetic_types : require
#extension GL_EXT_shader_16bit_storage : require
#extension GL_EXT_shader_realtime_clock : require
#extension GL_EXT_control_flow_attributes : require
layout(row_major) uniform;
layout(row_major) buffer;

#line 27 0
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
    uint seed_0;
};


#line 40
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
    uint seed_0;
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


#line 49
layout(std430, binding = 3) buffer StructuredBuffer_Diagnostics_t_0 {
    Diagnostics_0 _data[];
} g_diagnostics_0;

#line 297
struct NonDifferentiableFP8Weights_0
{
    uint8_t  data_0[16];
};


#line 306
struct NonDifferentiableIntPartitions_0
{
    int8_t  data_1[16];
};


#line 316
struct CompressedTextureBlock_0
{
    f16vec3 _ep0_0;
    f16vec3 _ep1_0;
    f16vec3 _ep2_0;
    f16vec3 _ep3_0;
    f16vec3 _ep4_0;
    f16vec3 _ep5_0;
    NonDifferentiableFP8Weights_0 weights_0;
    NonDifferentiableIntPartitions_0 partition_index_0;
    uint astc_partition_map_0;
    uint ideal_partition_map_0;
    uint16_t astc_seed_0;
    uint8_t perm_0;
    uint8_t partition_count_1;
    uint8_t max_partitions_1;
    uint16_t padding_0;
};


#line 52
layout(std430, binding = 4) buffer StructuredBuffer_CompressedTextureBlock_t_0 {
    CompressedTextureBlock_0 _data[];
} g_compressedBlock3P_0;

#line 8
struct TextureBlock_0
{
    vec3  pixels_0[16];
};


#line 43
layout(std430, binding = 1) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;

#line 59
layout(std430, binding = 7) readonly buffer StructuredBuffer_uint_t_0 {
    uint _data[];
} g_astc_3p_4x4_lut_s3_0;

#line 61
struct LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
};


#line 66
layout(binding = 8)
layout(std140) uniform block_LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
}g_lut_0;

#line 58
layout(std430, binding = 6) readonly buffer StructuredBuffer_uint_t_1 {
    uint _data[];
} g_astc_2p_4x4_lut_s2_0;

#line 46
layout(std430, binding = 2) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;

#line 55
layout(std430, binding = 5) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 71
struct PCG32_0
{
    uint state_0;
};


#line 75
PCG32_0 PCG32_x24init_0(uint seed_1)
{

#line 75
    PCG32_0 _S1;

    uint _S2 = seed_1 * 747796405U + 2891336453U;
    uint _S3 = ((_S2 >> ((_S2 >> 28U) + 4U)) ^ _S2) * 277803737U;
    _S1.state_0 = (_S3 >> 22U) ^ _S3;

#line 75
    return _S1;
}


#line 90
uint PCG32_nextUint_0(inout PCG32_0 this_0)
{
    uint oldState_0 = this_0.state_0;
    this_0.state_0 = this_0.state_0 * 747796405U + 2891336453U;
    uint word_0 = ((oldState_0 >> ((oldState_0 >> 28U) + 4U)) ^ oldState_0) * 277803737U;
    return (word_0 >> 22U) ^ word_0;
}


#line 290
f16vec3 quantize_0(f16vec3 value_0, uint range_0)
{
    f16vec3 scale_0 = f16vec3(float16_t(int(range_0)));
    return round(value_0 * scale_0) / scale_0;
}


#line 337
vec3 CompressedTextureBlock_ep1_get_0(CompressedTextureBlock_0 this_1)
{

#line 337
    return vec3(this_1._ep1_0);
}


#line 337
vec3 CompressedTextureBlock_ep0_get_0(CompressedTextureBlock_0 this_2)
{

#line 337
    return vec3(this_2._ep0_0);
}


#line 337
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


#line 337 0
vec3 CompressedTextureBlock_ep2_get_0(CompressedTextureBlock_0 this_3)
{

#line 337
    return vec3(this_3._ep2_0);
}


#line 704
float dist_0(vec3 x_0, vec3 ep0_0, vec3 ep1_0)
{
    vec3 lineDir_0 = ep1_0 - ep0_0;

    return length(cross(x_0 - ep0_0, lineDir_0)) / length(lineDir_0);
}


#line 337
vec3 CompressedTextureBlock_ep3_get_0(CompressedTextureBlock_0 this_4)
{

#line 337
    return vec3(this_4._ep3_0);
}


#line 337
vec3 CompressedTextureBlock_ep4_get_0(CompressedTextureBlock_0 this_5)
{

#line 337
    return vec3(this_5._ep4_0);
}


#line 337
vec3 CompressedTextureBlock_ep5_get_0(CompressedTextureBlock_0 this_6)
{

#line 337
    return vec3(this_6._ep5_0);
}


#line 83
float PCG32_nextFloat_0(inout PCG32_0 this_7)
{
    uint result_0 = PCG32_nextUint_0(this_7);
    return uintBitsToFloat(1065353216U | (result_0 >> 9)) - 1.0;
}


#line 13393 2
float saturate_0(float x_1)
{

#line 13401
    return clamp(x_1, 0.0, 1.0);
}


#line 310 0
int NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(NonDifferentiableIntPartitions_0 this_8, int n_0)
{

#line 310
    return int(this_8.data_1[n_0]);
}


#line 13408 2
vec3 saturate_1(vec3 x_2)
{

#line 13416
    return clamp(x_2, vec3(0.0), vec3(1.0));
}


#line 316 0
struct CompressedTextureBlock_Differential_0
{
    f16vec3 _ep0_1;
    f16vec3 _ep1_1;
    f16vec3 _ep2_1;
    f16vec3 _ep3_1;
    f16vec3 _ep4_1;
    f16vec3 _ep5_1;
};


#line 316
CompressedTextureBlock_Differential_0 CompressedTextureBlock_x24_syn_dzero_0()
{

#line 316
    CompressedTextureBlock_Differential_0 result_1;

#line 2239 3
    f16vec3 _S4 = f16vec3(0.0HF);

#line 2239
    result_1._ep0_1 = _S4;

#line 2239
    result_1._ep1_1 = _S4;

#line 2239
    result_1._ep2_1 = _S4;

#line 2239
    result_1._ep3_1 = _S4;

#line 2239
    result_1._ep4_1 = _S4;

#line 2239
    result_1._ep5_1 = _S4;

#line 2239
    return result_1;
}


#line 2239
CompressedTextureBlock_Differential_0 CompressedTextureBlock_x24_syn_dadd_0(CompressedTextureBlock_Differential_0 SLANG_anonymous_0_0, CompressedTextureBlock_Differential_0 SLANG_anonymous_1_0)
{

#line 2239
    CompressedTextureBlock_Differential_0 result_2;

#line 2239
    result_2._ep0_1 = SLANG_anonymous_0_0._ep0_1 + SLANG_anonymous_1_0._ep0_1;

#line 2239
    result_2._ep1_1 = SLANG_anonymous_0_0._ep1_1 + SLANG_anonymous_1_0._ep1_1;

#line 2239
    result_2._ep2_1 = SLANG_anonymous_0_0._ep2_1 + SLANG_anonymous_1_0._ep2_1;

#line 2239
    result_2._ep3_1 = SLANG_anonymous_0_0._ep3_1 + SLANG_anonymous_1_0._ep3_1;

#line 2239
    result_2._ep4_1 = SLANG_anonymous_0_0._ep4_1 + SLANG_anonymous_1_0._ep4_1;

#line 2239
    result_2._ep5_1 = SLANG_anonymous_0_0._ep5_1 + SLANG_anonymous_1_0._ep5_1;

#line 2239
    return result_2;
}


#line 301 0
float NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(NonDifferentiableFP8Weights_0 this_9, int n_1)
{

#line 301
    return float(this_9.data_0[n_1]) / 255.0;
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


#line 513 0
TextureBlock_0 CompressedTextureBlock_decompress3P_0(CompressedTextureBlock_0 this_10)
{
    TextureBlock_0 outputBlock_0;

#line 515
    uint i_0 = 0U;
    for(;;)
    {

#line 516
        if(i_0 < 16U)
        {
        }
        else
        {

#line 516
            break;
        }
        int _S9 = int(i_0);

#line 518
        float _S10 = NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(this_10.weights_0, _S9);
        int partition_0 = clamp(int(float(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(this_10.partition_index_0, _S9))), 0, int(this_10.max_partitions_1 - uint8_t(1U)));
        bool _S11 = partition_0 == 0;

#line 520
        vec3 e0_0;

#line 520
        if(_S11)
        {

#line 520
            e0_0 = CompressedTextureBlock_ep0_get_0(this_10);

#line 520
        }
        else
        {

#line 520
            if(partition_0 == 1)
            {

#line 520
                e0_0 = CompressedTextureBlock_ep2_get_0(this_10);

#line 520
            }
            else
            {

#line 520
                e0_0 = CompressedTextureBlock_ep4_get_0(this_10);

#line 520
            }

#line 520
        }

#line 520
        vec3 e1_0;
        if(_S11)
        {

#line 521
            e1_0 = CompressedTextureBlock_ep1_get_0(this_10);

#line 521
        }
        else
        {

#line 521
            if(partition_0 == 1)
            {

#line 521
                e1_0 = CompressedTextureBlock_ep3_get_0(this_10);

#line 521
            }
            else
            {

#line 521
                e1_0 = CompressedTextureBlock_ep5_get_0(this_10);

#line 521
            }

#line 521
        }
        outputBlock_0.pixels_0[i_0] = mix(e0_0, e1_0, vec3(_S10));

#line 516
        i_0 = i_0 + 1U;

#line 516
    }

#line 524
    return outputBlock_0;
}


#line 425
float CompressedTextureBlock_distSq_0(vec3 P_0, vec3 L_0, float pDotL_0, float invLenSq_0)
{

    return dot(P_0, P_0) - pDotL_0 * pDotL_0 * invLenSq_0;
}

uint CompressedTextureBlock_argmin_0(float d1_0, float d2_0, float d3_0)
{

#line 431
    bool _S12;

    if(d1_0 < d2_0)
    {

#line 433
        _S12 = d1_0 < d3_0;

#line 433
    }
    else
    {

#line 433
        _S12 = false;

#line 433
    }

#line 433
    if(_S12)
    {

#line 433
        return 0U;
    }

#line 434
    if(d2_0 < d3_0)
    {

#line 434
        return 1U;
    }

#line 435
    return 2U;
}


#line 348
uint CompressedTextureBlock_pack_partition_indices_0(CompressedTextureBlock_0 this_11)
{

#line 348
    int i_1 = 0;

#line 348
    uint raw_map_0 = 0U;


    for(;;)
    {

#line 351
        if(i_1 < 16)
        {
        }
        else
        {

#line 351
            break;
        }

        uint raw_map_1 = raw_map_0 | (uint(clamp(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(this_11.partition_index_0, i_1), 0, 2)) << (i_1 * 2));

#line 351
        i_1 = i_1 + 1;

#line 351
        raw_map_0 = raw_map_1;

#line 351
    }

#line 356
    return raw_map_0;
}


#line 205
uint lut3_key_0(uint x_3)
{

#line 205
    uint result_3 = 0U;

#line 205
    int i_2 = 15;

#line 210
    [[unroll]]
    for(;;)
    {

#line 210
        if(i_2 >= 0)
        {
        }
        else
        {

#line 210
            break;
        }
        uint _S13 = result_3 * 3U + ((x_3 >> (i_2 * 2)) & 3U);

#line 210
        int _S14 = i_2 - 1;

#line 210
        result_3 = _S13;

#line 210
        i_2 = _S14;

#line 210
    }



    return result_3;
}


#line 110
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

#line 141
    return permute_cycle_120_0(permute_cycle_120_0(x_8));
}


#line 217
uint canonicalize_lut3_0(uint x_9)
{

#line 229
    return min(min(lut3_key_0(x_9), lut3_key_0(permute_swap01_0(x_9))), min(min(lut3_key_0(permute_swap02_0(x_9)), lut3_key_0(permute_swap12_0(x_9))), min(lut3_key_0(permute_cycle_120_0(x_9)), lut3_key_0(permute_cycle_201_0(x_9)))));
}


#line 259
uint count_diffs_0(uint val_0)
{
    return bitCount((val_0 | (val_0 >> 1)) & 1431655765U);
}


#line 159
uint best_perm_distance_s3_0(uint x_10, uint y_0, out uint8_t perm_1)
{
    uint base_0 = x_10 ^ y_0;

    uint x_shr1_0 = x_10 >> 1;
    uint nz_0 = (x_10 | x_shr1_0) & 1431655765U;
    uint nz_shl1_0 = nz_0 << 1;

    uint m01_0 = (~x_shr1_0) & 1431655765U;

#line 183
    uint best_0 = min(min(min(((count_diffs_0(base_0)) << 3) | 0U, ((count_diffs_0(base_0 ^ m01_0)) << 3) | 1U), min(((count_diffs_0(base_0 ^ ((~(x_10 << 1)) & 2863311530U))) << 3) | 2U, ((count_diffs_0(base_0 ^ (nz_0 | nz_shl1_0))) << 3) | 3U)), min(((count_diffs_0(base_0 ^ (m01_0 | nz_shl1_0))) << 3) | 4U, ((count_diffs_0(base_0 ^ (nz_0 | (((~x_10) & 1431655765U) << 1)))) << 3) | 5U));

    perm_1 = uint8_t(int(best_0 & 7U));
    return best_0 >> 3;
}


#line 264
uint get_closest_seed3_0(uint input_0, out uint8_t perm_2, out uint final_pattern_0)
{

#line 265
    uint key_0 = canonicalize_lut3_0(input_0);
    uint seed_2 = ((g_astc_3p_4x4_lut_s3_0._data[uint(key_0 / 3U)]) >> (key_0 % 3U * 10U)) & 1023U;
    uint pattern_0 = g_lut_0.lut3_0[seed_2];
    uint _S15 = best_perm_distance_s3_0(input_0, g_lut_0.lut3_0[seed_2], perm_2);

    final_pattern_0 = pattern_0;
    return seed_2;
}


#line 232
uint lut2_key_0(uint x_11)
{

#line 232
    uint result_4 = 0U;

#line 232
    int i_3 = 15;

#line 237
    [[unroll]]
    for(;;)
    {

#line 237
        if(i_3 >= 0)
        {
        }
        else
        {

#line 237
            break;
        }
        uint _S16 = result_4 * 2U + ((x_11 >> (i_3 * 2)) & 3U);

#line 237
        int _S17 = i_3 - 1;

#line 237
        result_4 = _S16;

#line 237
        i_3 = _S17;

#line 237
    }



    return result_4;
}

uint canonicalize_lut2_0(uint x_12)
{


    return min(lut2_key_0(x_12), lut2_key_0(permute_swap01_0(x_12)));
}


#line 189
uint best_perm_distance_s2_0(uint x_13, uint y_1, out uint8_t perm_3)
{
    uint base_1 = x_13 ^ y_1;

#line 199
    uint min01_0 = min(((count_diffs_0(base_1)) << 1) | 0U, ((count_diffs_0(base_1 ^ ((~(x_13 >> 1)) & 1431655765U))) << 1) | 1U);

    perm_3 = uint8_t(int(min01_0 & 1U));
    return min01_0 >> 1;
}


#line 274
uint get_closest_seed2_0(uint input_1, out uint8_t permutation_0, out uint final_pattern_1)
{

#line 275
    uint key_1 = canonicalize_lut2_0(input_1);
    uint seed_3 = ((g_astc_2p_4x4_lut_s2_0._data[uint(key_1 / 3U)]) >> (key_1 % 3U * 10U)) & 1023U;
    uint pattern_1 = g_lut_0.lut2_0[seed_3];
    uint _S18 = best_perm_distance_s2_0(input_1, g_lut_0.lut2_0[seed_3], permutation_0);

    final_pattern_1 = pattern_1;
    return seed_3;
}


#line 360
void CompressedTextureBlock_swap_colors_0(inout CompressedTextureBlock_0 this_12, uint8_t perm_4)
{
    vec3 old_ep0_0 = CompressedTextureBlock_ep0_get_0(this_12);
    vec3 old_ep1_0 = CompressedTextureBlock_ep1_get_0(this_12);
    vec3 old_ep2_0 = CompressedTextureBlock_ep2_get_0(this_12);
    vec3 old_ep3_0 = CompressedTextureBlock_ep3_get_0(this_12);
    vec3 old_ep4_0 = CompressedTextureBlock_ep4_get_0(this_12);
    vec3 old_ep5_0 = CompressedTextureBlock_ep5_get_0(this_12);



    bool _S19 = perm_4 == uint8_t(1U);

#line 371
    bool from_pair1_0;

#line 371
    if(_S19)
    {

#line 371
        from_pair1_0 = true;

#line 371
    }
    else
    {

#line 371
        from_pair1_0 = perm_4 == uint8_t(5U);

#line 371
    }
    bool _S20 = perm_4 == uint8_t(2U);

#line 372
    bool from_pair2_0;

#line 372
    if(_S20)
    {

#line 372
        from_pair2_0 = true;

#line 372
    }
    else
    {

#line 372
        from_pair2_0 = perm_4 == uint8_t(4U);

#line 372
    }

#line 372
    vec3 _S21;
    if(from_pair1_0)
    {

#line 373
        _S21 = old_ep2_0;

#line 373
    }
    else
    {

#line 373
        if(from_pair2_0)
        {

#line 373
            _S21 = old_ep4_0;

#line 373
        }
        else
        {

#line 373
            _S21 = old_ep0_0;

#line 373
        }

#line 373
    }

#line 373
    this_12._ep0_0 = quantize_0(f16vec3(_S21), 255U);
    if(from_pair1_0)
    {

#line 374
        _S21 = old_ep3_0;

#line 374
    }
    else
    {

#line 374
        if(from_pair2_0)
        {

#line 374
            _S21 = old_ep5_0;

#line 374
        }
        else
        {

#line 374
            _S21 = old_ep1_0;

#line 374
        }

#line 374
    }

#line 374
    this_12._ep1_0 = quantize_0(f16vec3(_S21), 255U);

#line 374
    bool from_pair0_0;



    if(_S19)
    {

#line 378
        from_pair0_0 = true;

#line 378
    }
    else
    {

#line 378
        from_pair0_0 = perm_4 == uint8_t(4U);

#line 378
    }
    bool _S22 = perm_4 == uint8_t(3U);

#line 379
    if(_S22)
    {

#line 379
        from_pair2_0 = true;

#line 379
    }
    else
    {

#line 379
        from_pair2_0 = perm_4 == uint8_t(5U);

#line 379
    }
    if(from_pair0_0)
    {

#line 380
        _S21 = old_ep0_0;

#line 380
    }
    else
    {

#line 380
        if(from_pair2_0)
        {

#line 380
            _S21 = old_ep4_0;

#line 380
        }
        else
        {

#line 380
            _S21 = old_ep2_0;

#line 380
        }

#line 380
    }

#line 380
    this_12._ep2_0 = quantize_0(f16vec3(_S21), 255U);
    if(from_pair0_0)
    {

#line 381
        _S21 = old_ep1_0;

#line 381
    }
    else
    {

#line 381
        if(from_pair2_0)
        {

#line 381
            _S21 = old_ep5_0;

#line 381
        }
        else
        {

#line 381
            _S21 = old_ep3_0;

#line 381
        }

#line 381
    }

#line 381
    this_12._ep3_0 = quantize_0(f16vec3(_S21), 255U);



    if(_S20)
    {

#line 385
        from_pair0_0 = true;

#line 385
    }
    else
    {

#line 385
        from_pair0_0 = perm_4 == uint8_t(5U);

#line 385
    }
    if(_S22)
    {

#line 386
        from_pair1_0 = true;

#line 386
    }
    else
    {

#line 386
        from_pair1_0 = perm_4 == uint8_t(4U);

#line 386
    }
    if(from_pair0_0)
    {

#line 387
        _S21 = old_ep0_0;

#line 387
    }
    else
    {

#line 387
        if(from_pair1_0)
        {

#line 387
            _S21 = old_ep2_0;

#line 387
        }
        else
        {

#line 387
            _S21 = old_ep4_0;

#line 387
        }

#line 387
    }

#line 387
    this_12._ep4_0 = quantize_0(f16vec3(_S21), 255U);
    if(from_pair0_0)
    {

#line 388
        _S21 = old_ep1_0;

#line 388
    }
    else
    {

#line 388
        if(from_pair1_0)
        {

#line 388
            _S21 = old_ep3_0;

#line 388
        }
        else
        {

#line 388
            _S21 = old_ep5_0;

#line 388
        }

#line 388
    }

#line 388
    this_12._ep5_0 = quantize_0(f16vec3(_S21), 255U);
    return;
}


#line 399
void CompressedTextureBlock_snap_0(inout CompressedTextureBlock_0 this_13)
{
    uint raw_map_2 = CompressedTextureBlock_pack_partition_indices_0(this_13);
    uint8_t permutation_1 = uint8_t(0U);
    uint final_mask_0 = 0U;

#line 403
    uint closest_seed_0;

    if((this_13.max_partitions_1) == uint8_t(3U))
    {
        uint _S23 = get_closest_seed3_0(raw_map_2, permutation_1, final_mask_0);

#line 407
        closest_seed_0 = _S23;

#line 405
    }
    else
    {

        uint _S24 = get_closest_seed2_0(raw_map_2, permutation_1, final_mask_0);

#line 409
        closest_seed_0 = _S24;

#line 405
    }

#line 412
    this_13.astc_seed_0 = uint16_t(closest_seed_0);
    this_13.astc_partition_map_0 = final_mask_0;
    this_13.ideal_partition_map_0 = raw_map_2;
    this_13.perm_0 = permutation_1;


    CompressedTextureBlock_swap_colors_0(this_13, permutation_1);

#line 418
    int i_4 = 0;
    for(;;)
    {

#line 419
        if(i_4 < 16)
        {
        }
        else
        {

#line 419
            break;
        }
        this_13.partition_index_0.data_1[i_4] = int8_t(int((final_mask_0 >> (2 * i_4)) & 3U));

#line 419
        i_4 = i_4 + 1;

#line 419
    }



    return;
}


#line 251
uint hamming_distance_2b_0(uint x_14, uint y_2)
{
    uint z_0 = x_14 ^ y_2;


    return bitCount((z_0 | (z_0 >> 1)) & 1431655765U);
}


#line 573
TextureBlock_0 CompressedTextureBlock_reconstruct_0(CompressedTextureBlock_0 this_14)
{
    if(g_params_0.debug_reconstruction_0)
    {

#line 576
        TextureBlock_0 outputBlock_1;

#line 576
        int i_5 = 0;
        for(;;)
        {

#line 577
            if(i_5 < 16)
            {
            }
            else
            {

#line 577
                break;
            }

            int partition_1 = clamp(int(float(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(this_14.partition_index_0, i_5))), 0, 2);

#line 580
            vec3 c_0;


            if(partition_1 == 0)
            {

#line 583
                c_0 = vec3(1.0, 1.0, 1.0);

#line 583
            }
            else
            {

#line 583
                if(partition_1 == 1)
                {

#line 583
                    c_0 = vec3(0.5, 0.5, 0.5);

#line 583
                }
                else
                {

#line 583
                    c_0 = vec3(0.0, 0.0, 0.0);

#line 583
                }

#line 583
            }
            outputBlock_1.pixels_0[i_5] = c_0;

#line 577
            i_5 = i_5 + 1;

#line 577
        }

#line 586
        return outputBlock_1;
    }
    return CompressedTextureBlock_decompress3P_0(this_14);
}


#line 714
void CompressedTextureBlock_random_initialize_0(inout CompressedTextureBlock_0 _S25, uint _S26, inout PCG32_0 _S27)
{

#line 532
    uint _S28 = PCG32_nextUint_0(_S27);

#line 532
    _S25._ep0_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S26)].pixels_0[_S28 % 16U]), 255U);
    uint _S29 = PCG32_nextUint_0(_S27);

#line 533
    _S25._ep1_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S26)].pixels_0[_S29 % 16U]), 255U);

#line 533
    int i_6 = 0;
    for(;;)
    {

#line 534
        if(i_6 < 8)
        {
        }
        else
        {

#line 534
            break;
        }

#line 535
        uint _S30 = PCG32_nextUint_0(_S27);

#line 535
        _S25._ep1_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S26)].pixels_0[_S30 % 16U]), 255U);
        vec3 d_0 = CompressedTextureBlock_ep1_get_0(_S25) - CompressedTextureBlock_ep0_get_0(_S25);
        if((dot(d_0, d_0)) > 0.30000001192092896)
        {

#line 538
            break;
        }

#line 534
        i_6 = i_6 + 1;

#line 534
    }

#line 534
    i_6 = 0;

#line 541
    for(;;)
    {

#line 541
        if(i_6 < 8)
        {
        }
        else
        {

#line 541
            break;
        }

#line 542
        uint _S31 = PCG32_nextUint_0(_S27);

#line 542
        _S25._ep2_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S26)].pixels_0[_S31 % 16U]), 255U);
        if((dist_0(CompressedTextureBlock_ep2_get_0(_S25), CompressedTextureBlock_ep0_get_0(_S25), CompressedTextureBlock_ep1_get_0(_S25))) > 0.30000001192092896)
        {

#line 544
            break;
        }

#line 541
        i_6 = i_6 + 1;

#line 541
    }

#line 541
    i_6 = 0;

#line 547
    for(;;)
    {

#line 547
        if(i_6 < 8)
        {
        }
        else
        {

#line 547
            break;
        }

#line 548
        uint _S32 = PCG32_nextUint_0(_S27);

#line 548
        _S25._ep3_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S26)].pixels_0[_S32 % 16U]), 255U);
        if((dist_0(CompressedTextureBlock_ep3_get_0(_S25), CompressedTextureBlock_ep0_get_0(_S25), CompressedTextureBlock_ep1_get_0(_S25))) > 0.30000001192092896)
        {

#line 550
            break;
        }

#line 547
        i_6 = i_6 + 1;

#line 547
    }

#line 547
    i_6 = 0;

#line 553
    for(;;)
    {

#line 553
        if(i_6 < 8)
        {
        }
        else
        {

#line 553
            break;
        }

#line 554
        uint _S33 = PCG32_nextUint_0(_S27);

#line 554
        _S25._ep4_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S26)].pixels_0[_S33 % 16U]), 255U);
        if((dist_0(CompressedTextureBlock_ep4_get_0(_S25), CompressedTextureBlock_ep0_get_0(_S25), CompressedTextureBlock_ep1_get_0(_S25))) <= 0.30000001192092896)
        {

#line 556
            i_6 = i_6 + 1;

#line 553
            continue;
        }



        if((dist_0(CompressedTextureBlock_ep4_get_0(_S25), CompressedTextureBlock_ep2_get_0(_S25), CompressedTextureBlock_ep3_get_0(_S25))) > 0.30000001192092896)
        {

#line 559
            break;
        }

#line 553
        i_6 = i_6 + 1;

#line 553
    }

#line 553
    i_6 = 0;

#line 562
    for(;;)
    {

#line 562
        if(i_6 < 8)
        {
        }
        else
        {

#line 562
            break;
        }

#line 563
        uint _S34 = PCG32_nextUint_0(_S27);

#line 563
        _S25._ep5_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S26)].pixels_0[_S34 % 16U]), 255U);
        if((dist_0(CompressedTextureBlock_ep5_get_0(_S25), CompressedTextureBlock_ep0_get_0(_S25), CompressedTextureBlock_ep1_get_0(_S25))) <= 0.30000001192092896)
        {

#line 565
            i_6 = i_6 + 1;

#line 562
            continue;
        }



        if((dist_0(CompressedTextureBlock_ep5_get_0(_S25), CompressedTextureBlock_ep2_get_0(_S25), CompressedTextureBlock_ep3_get_0(_S25))) > 0.30000001192092896)
        {

#line 568
            break;
        }

#line 562
        i_6 = i_6 + 1;

#line 562
    }

#line 571
    return;
}


#line 2675 3
uint solve_pca_eps_0(CompressedTextureBlock_0 _S35, inout vec3 _S36, inout vec3 _S37, uint _S38, int _S39)
{

#line 595 0
    const vec3 _S40 = vec3(0.17000000178813934, 0.82999998331069946, 0.37999999523162842);
    vec3 _S41 = vec3(ivec3(0));

#line 596
    int i_7 = 0;

#line 596
    vec3 centroid_0 = _S41;

#line 596
    uint count_0 = 0U;



    [[unroll]]
    for(;;)
    {

#line 600
        if(i_7 < 16)
        {
        }
        else
        {

#line 600
            break;
        }
        if((NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S35.partition_index_0, i_7)) == _S39)
        {

            uint count_1 = count_0 + 1U;

#line 605
            centroid_0 = centroid_0 + g_groundtruth_0._data[uint(_S38)].pixels_0[i_7];

#line 605
            count_0 = count_1;

#line 602
        }

#line 600
        i_7 = i_7 + 1;

#line 600
    }

#line 609
    if(count_0 <= 1U)
    {

#line 610
        if(count_0 > 0U)
        {

#line 610
            centroid_0 = centroid_0 / float(count_0);

#line 610
        }
        else
        {

#line 610
            centroid_0 = _S41;

#line 610
        }

#line 610
        vec3 _S42 = saturate_1(centroid_0);

#line 610
        _S36 = _S42;
        _S37 = _S42;
        return count_0;
    }

    vec3 centroid_1 = centroid_0 / float(count_0);

#line 615
    i_7 = 0;

#line 615
    float xx_0 = 0.0;

#line 615
    float xy_0 = 0.0;

#line 615
    float xz_0 = 0.0;

#line 615
    float yy_0 = 0.0;

#line 615
    float yz_0 = 0.0;

#line 615
    float zz_0 = 0.0;



    [[unroll]]
    for(;;)
    {

#line 619
        if(i_7 < 16)
        {
        }
        else
        {

#line 619
            break;
        }
        if((NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S35.partition_index_0, i_7)) == _S39)
        {
            vec3 d_1 = g_groundtruth_0._data[uint(_S38)].pixels_0[i_7] - centroid_1;
            float _S43 = d_1.x;
            float _S44 = d_1.y;

#line 625
            float xy_1 = xy_0 + _S43 * _S44;
            float _S45 = d_1.z;

#line 626
            float xz_1 = xz_0 + _S43 * _S45;
            float yy_1 = yy_0 + _S44 * _S44;
            float yz_1 = yz_0 + _S44 * _S45;
            float zz_1 = zz_0 + _S45 * _S45;

#line 629
            xx_0 = xx_0 + _S43 * _S43;

#line 629
            xy_0 = xy_1;

#line 629
            xz_0 = xz_1;

#line 629
            yy_0 = yy_1;

#line 629
            yz_0 = yz_1;

#line 629
            zz_0 = zz_1;

#line 621
        }

#line 619
        i_7 = i_7 + 1;

#line 619
    }

#line 619
    vec3 axis_0 = _S40;

#line 619
    int iter_0 = 0;

#line 635
    [[unroll]]
    for(;;)
    {

#line 635
        if(iter_0 < 4)
        {
        }
        else
        {

#line 635
            break;
        }
        vec3 new_axis_0;
        float _S46 = axis_0.x;

#line 638
        float _S47 = axis_0.y;

#line 638
        float _S48 = axis_0.z;

#line 638
        new_axis_0[0] = xx_0 * _S46 + xy_0 * _S47 + xz_0 * _S48;
        new_axis_0[1] = xy_0 * _S46 + yy_0 * _S47 + yz_0 * _S48;
        new_axis_0[2] = xz_0 * _S46 + yz_0 * _S47 + zz_0 * _S48;
        vec3 _S49 = new_axis_0;

#line 635
        int _S50 = iter_0 + 1;

#line 635
        axis_0 = _S49;

#line 635
        iter_0 = _S50;

#line 635
    }

#line 644
    if((dot(axis_0, axis_0)) < 9.99999993922529029e-09)
    {

#line 645
        vec3 _S51 = saturate_1(centroid_1);

#line 645
        _S36 = _S51;
        _S37 = _S51;
        return count_0;
    }

    vec3 axis_1 = normalize(axis_0);

#line 650
    float min_t_0 = 1000.0;

#line 650
    float max_t_0 = -1000.0;

#line 650
    i_7 = 0;

#line 655
    [[unroll]]
    for(;;)
    {

#line 655
        if(i_7 < 16)
        {
        }
        else
        {

#line 655
            break;
        }
        if((NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S35.partition_index_0, i_7)) == _S39)
        {

            float t_0 = dot(g_groundtruth_0._data[uint(_S38)].pixels_0[i_7] - centroid_1, axis_1);

            float _S52 = max(max_t_0, t_0);

#line 662
            min_t_0 = min(min_t_0, t_0);

#line 662
            max_t_0 = _S52;

#line 657
        }

#line 655
        i_7 = i_7 + 1;

#line 655
    }

#line 666
    _S36 = saturate_1(centroid_1 + axis_1 * min_t_0);
    _S37 = saturate_1(centroid_1 + axis_1 * max_t_0);
    return count_0;
}


#line 668
void solve_aabb_eps_0(CompressedTextureBlock_0 _S53, inout vec3 _S54, inout vec3 _S55, uint _S56, int _S57)
{



    vec3 _S58 = vec3(ivec3(1));

#line 673
    vec3 _S59 = vec3(ivec3(0));

#line 673
    vec3 min_ep_0 = _S58;

#line 673
    vec3 max_ep_0 = _S59;

#line 673
    int i_8 = 0;


    [[unroll]]
    for(;;)
    {

#line 676
        if(i_8 < 16)
        {
        }
        else
        {

#line 676
            break;
        }
        bool inlier_0 = (NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S53.partition_index_0, i_8)) == _S57;

#line 678
        vec3 _S60;
        if(inlier_0)
        {

#line 679
            _S60 = g_groundtruth_0._data[uint(_S56)].pixels_0[i_8];

#line 679
        }
        else
        {

#line 679
            _S60 = _S58;

#line 679
        }

#line 679
        vec3 _S61 = min(_S60, min_ep_0);

#line 679
        vec3 _S62;
        if(inlier_0)
        {

#line 680
            _S62 = g_groundtruth_0._data[uint(_S56)].pixels_0[i_8];

#line 680
        }
        else
        {

#line 680
            _S62 = _S59;

#line 680
        }

#line 680
        vec3 _S63 = max(_S62, max_ep_0);

#line 676
        int _S64 = i_8 + 1;

#line 676
        min_ep_0 = _S61;

#line 676
        max_ep_0 = _S63;

#line 676
        i_8 = _S64;

#line 676
    }

#line 683
    _S54 = saturate_1(min_ep_0);
    _S55 = saturate_1(max_ep_0);
    return;
}


#line 685
struct DiffPair_CompressedTextureBlock_0
{
    CompressedTextureBlock_0 primal_0;
    CompressedTextureBlock_Differential_0 differential_0;
};


#line 760
vec3 s_primal_ctx_CompressedTextureBlock_ep0_get_0(CompressedTextureBlock_0 dpthis_0)
{

#line 337
    return vec3(dpthis_0._ep0_0);
}


#line 337
vec3 s_primal_ctx_CompressedTextureBlock_ep1_get_0(CompressedTextureBlock_0 dpthis_1)
{

#line 337
    return vec3(dpthis_1._ep1_0);
}


#line 337
vec3 s_primal_ctx_CompressedTextureBlock_ep2_get_0(CompressedTextureBlock_0 dpthis_2)
{

#line 337
    return vec3(dpthis_2._ep2_0);
}


#line 337
vec3 s_primal_ctx_CompressedTextureBlock_ep4_get_0(CompressedTextureBlock_0 dpthis_3)
{

#line 337
    return vec3(dpthis_3._ep4_0);
}


#line 337
vec3 s_primal_ctx_CompressedTextureBlock_ep3_get_0(CompressedTextureBlock_0 dpthis_4)
{

#line 337
    return vec3(dpthis_4._ep3_0);
}


#line 337
vec3 s_primal_ctx_CompressedTextureBlock_ep5_get_0(CompressedTextureBlock_0 dpthis_5)
{

#line 337
    return vec3(dpthis_5._ep5_0);
}


#line 337
vec3 s_primal_ctx_lerp_0(vec3 _S65, vec3 _S66, vec3 _S67)
{

#line 337
    return mix(_S65, _S66, _S67);
}


#line 337
TextureBlock_0 s_primal_ctx_CompressedTextureBlock_decompress3P_0(CompressedTextureBlock_0 dpthis_6)
{

#line 515
    vec3 _S68 = vec3(0.0);

#line 515
    vec3  _S69[16] = { _S68, _S68, _S68, _S68, _S68, _S68, _S68, _S68, _S68, _S68, _S68, _S68, _S68, _S68, _S68, _S68 };



    int _S70 = int(dpthis_6.max_partitions_1 - uint8_t(1U));

#line 519
    vec3 _S71 = s_primal_ctx_CompressedTextureBlock_ep0_get_0(dpthis_6);

#line 519
    vec3 _S72 = s_primal_ctx_CompressedTextureBlock_ep1_get_0(dpthis_6);

#line 519
    vec3 _S73 = s_primal_ctx_CompressedTextureBlock_ep2_get_0(dpthis_6);

#line 519
    vec3 _S74 = s_primal_ctx_CompressedTextureBlock_ep4_get_0(dpthis_6);

#line 519
    vec3 _S75 = s_primal_ctx_CompressedTextureBlock_ep3_get_0(dpthis_6);

#line 519
    vec3 _S76 = s_primal_ctx_CompressedTextureBlock_ep5_get_0(dpthis_6);

#line 519
    bool _runFlag_0 = true;

#line 519
    uint i_9 = 0U;

#line 519
    TextureBlock_0 outputBlock_2;

#line 519
    outputBlock_2.pixels_0 = _S69;

#line 519
    int _pc_0 = 0;

#line 516
    for(;;)
    {

#line 516
        if(_runFlag_0)
        {
        }
        else
        {

#line 516
            break;
        }

#line 516
        int _S77;

#line 516
        if(i_9 < 16U)
        {
            int _S78 = int(i_9);

#line 518
            float _S79 = NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(dpthis_6.weights_0, _S78);
            int partition_2 = clamp(int(float(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(dpthis_6.partition_index_0, _S78))), 0, _S70);
            bool _S80 = partition_2 == 0;

#line 520
            vec3 e0_1;

#line 520
            if(_S80)
            {

#line 520
                e0_1 = _S71;

#line 520
            }
            else
            {

#line 520
                if(partition_2 == 1)
                {

#line 520
                    e0_1 = _S73;

#line 520
                }
                else
                {

#line 520
                    e0_1 = _S74;

#line 520
                }

#line 520
            }

#line 520
            vec3 e1_1;
            if(_S80)
            {

#line 521
                e1_1 = _S72;

#line 521
            }
            else
            {

#line 521
                if(partition_2 == 1)
                {

#line 521
                    e1_1 = _S75;

#line 521
                }
                else
                {

#line 521
                    e1_1 = _S76;

#line 521
                }

#line 521
            }

#line 521
            vec3 _S81 = s_primal_ctx_lerp_0(e0_1, e1_1, vec3(_S79));

#line 521
            TextureBlock_0 _S82 = outputBlock_2;

#line 521
            _S82.pixels_0[i_9] = _S81;

#line 521
            _S77 = 1;

#line 521
            outputBlock_2 = _S82;

#line 521
        }
        else
        {

#line 521
            _S77 = 0;

#line 521
        }

#line 521
        if(_S77 != 1)
        {

#line 521
            _runFlag_0 = false;

#line 521
        }

#line 521
        if(_runFlag_0)
        {

#line 521
            i_9 = i_9 + 1U;

#line 521
        }

#line 521
        _pc_0 = _pc_0 + 1;

#line 516
    }

#line 516
    return outputBlock_2;
}


#line 516
TextureBlock_0 TextureBlock_x24_syn_dzero_0()
{

#line 516
    TextureBlock_0 result_5;

#line 2239 3
    vec3 _S83 = vec3(0.0);

#line 2239
    result_5.pixels_0[0] = _S83;

#line 2239
    result_5.pixels_0[1] = _S83;

#line 2239
    result_5.pixels_0[2] = _S83;

#line 2239
    result_5.pixels_0[3] = _S83;

#line 2239
    result_5.pixels_0[4] = _S83;

#line 2239
    result_5.pixels_0[5] = _S83;

#line 2239
    result_5.pixels_0[6] = _S83;

#line 2239
    result_5.pixels_0[7] = _S83;

#line 2239
    result_5.pixels_0[8] = _S83;

#line 2239
    result_5.pixels_0[9] = _S83;

#line 2239
    result_5.pixels_0[10] = _S83;

#line 2239
    result_5.pixels_0[11] = _S83;

#line 2239
    result_5.pixels_0[12] = _S83;

#line 2239
    result_5.pixels_0[13] = _S83;

#line 2239
    result_5.pixels_0[14] = _S83;

#line 2239
    result_5.pixels_0[15] = _S83;

#line 2239
    return result_5;
}


#line 2239
TextureBlock_0 TextureBlock_x24_syn_dadd_0(TextureBlock_0 SLANG_anonymous_0_1, TextureBlock_0 SLANG_anonymous_1_1)
{

#line 2239
    TextureBlock_0 result_6;

#line 2239
    result_6.pixels_0[0] = SLANG_anonymous_0_1.pixels_0[0] + SLANG_anonymous_1_1.pixels_0[0];

#line 2239
    result_6.pixels_0[1] = SLANG_anonymous_0_1.pixels_0[1] + SLANG_anonymous_1_1.pixels_0[1];

#line 2239
    result_6.pixels_0[2] = SLANG_anonymous_0_1.pixels_0[2] + SLANG_anonymous_1_1.pixels_0[2];

#line 2239
    result_6.pixels_0[3] = SLANG_anonymous_0_1.pixels_0[3] + SLANG_anonymous_1_1.pixels_0[3];

#line 2239
    result_6.pixels_0[4] = SLANG_anonymous_0_1.pixels_0[4] + SLANG_anonymous_1_1.pixels_0[4];

#line 2239
    result_6.pixels_0[5] = SLANG_anonymous_0_1.pixels_0[5] + SLANG_anonymous_1_1.pixels_0[5];

#line 2239
    result_6.pixels_0[6] = SLANG_anonymous_0_1.pixels_0[6] + SLANG_anonymous_1_1.pixels_0[6];

#line 2239
    result_6.pixels_0[7] = SLANG_anonymous_0_1.pixels_0[7] + SLANG_anonymous_1_1.pixels_0[7];

#line 2239
    result_6.pixels_0[8] = SLANG_anonymous_0_1.pixels_0[8] + SLANG_anonymous_1_1.pixels_0[8];

#line 2239
    result_6.pixels_0[9] = SLANG_anonymous_0_1.pixels_0[9] + SLANG_anonymous_1_1.pixels_0[9];

#line 2239
    result_6.pixels_0[10] = SLANG_anonymous_0_1.pixels_0[10] + SLANG_anonymous_1_1.pixels_0[10];

#line 2239
    result_6.pixels_0[11] = SLANG_anonymous_0_1.pixels_0[11] + SLANG_anonymous_1_1.pixels_0[11];

#line 2239
    result_6.pixels_0[12] = SLANG_anonymous_0_1.pixels_0[12] + SLANG_anonymous_1_1.pixels_0[12];

#line 2239
    result_6.pixels_0[13] = SLANG_anonymous_0_1.pixels_0[13] + SLANG_anonymous_1_1.pixels_0[13];

#line 2239
    result_6.pixels_0[14] = SLANG_anonymous_0_1.pixels_0[14] + SLANG_anonymous_1_1.pixels_0[14];

#line 2239
    result_6.pixels_0[15] = SLANG_anonymous_0_1.pixels_0[15] + SLANG_anonymous_1_1.pixels_0[15];

#line 2239
    return result_6;
}


#line 337 0
void s_bwd_prop_CompressedTextureBlock_ep5_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_7, vec3 _s_dOut_0)
{

#line 346
    f16vec3 _S84 = f16vec3(_s_dOut_0);

#line 346
    CompressedTextureBlock_Differential_0 _S85 = CompressedTextureBlock_x24_syn_dzero_0();

#line 346
    _S85._ep5_1 = _S84;

#line 346
    dpthis_7.primal_0 = dpthis_7.primal_0;

#line 346
    dpthis_7.differential_0 = _S85;

#line 337
    return;
}


#line 337
void s_bwd_prop_CompressedTextureBlock_ep3_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_8, vec3 _s_dOut_1)
{

#line 344
    f16vec3 _S86 = f16vec3(_s_dOut_1);

#line 344
    CompressedTextureBlock_Differential_0 _S87 = CompressedTextureBlock_x24_syn_dzero_0();

#line 344
    _S87._ep3_1 = _S86;

#line 344
    dpthis_8.primal_0 = dpthis_8.primal_0;

#line 344
    dpthis_8.differential_0 = _S87;

#line 337
    return;
}


#line 337
void s_bwd_prop_CompressedTextureBlock_ep4_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_9, vec3 _s_dOut_2)
{

#line 345
    f16vec3 _S88 = f16vec3(_s_dOut_2);

#line 345
    CompressedTextureBlock_Differential_0 _S89 = CompressedTextureBlock_x24_syn_dzero_0();

#line 345
    _S89._ep4_1 = _S88;

#line 345
    dpthis_9.primal_0 = dpthis_9.primal_0;

#line 345
    dpthis_9.differential_0 = _S89;

#line 337
    return;
}


#line 337
void s_bwd_prop_CompressedTextureBlock_ep2_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_10, vec3 _s_dOut_3)
{

#line 343
    f16vec3 _S90 = f16vec3(_s_dOut_3);

#line 343
    CompressedTextureBlock_Differential_0 _S91 = CompressedTextureBlock_x24_syn_dzero_0();

#line 343
    _S91._ep2_1 = _S90;

#line 343
    dpthis_10.primal_0 = dpthis_10.primal_0;

#line 343
    dpthis_10.differential_0 = _S91;

#line 337
    return;
}


#line 337
void s_bwd_prop_CompressedTextureBlock_ep1_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_11, vec3 _s_dOut_4)
{



    f16vec3 _S92 = f16vec3(_s_dOut_4);

#line 342
    CompressedTextureBlock_Differential_0 _S93 = CompressedTextureBlock_x24_syn_dzero_0();

#line 342
    _S93._ep1_1 = _S92;

#line 342
    dpthis_11.primal_0 = dpthis_11.primal_0;

#line 342
    dpthis_11.differential_0 = _S93;

#line 337
    return;
}


#line 337
void s_bwd_prop_CompressedTextureBlock_ep0_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_12, vec3 _s_dOut_5)
{


    f16vec3 _S94 = f16vec3(_s_dOut_5);

#line 341
    CompressedTextureBlock_Differential_0 _S95 = CompressedTextureBlock_x24_syn_dzero_0();

#line 341
    _S95._ep0_1 = _S94;

#line 341
    dpthis_12.primal_0 = dpthis_12.primal_0;

#line 341
    dpthis_12.differential_0 = _S95;

#line 337
    return;
}


#line 337
void s_bwd_prop_lerp_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S96, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S97, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S98, vec3 _S99)
{

#line 337
    _d_lerp_vector_0(_S96, _S97, _S98, _S99);

#line 337
    return;
}


#line 513
void s_bwd_prop_CompressedTextureBlock_decompress3P_0(inout DiffPair_CompressedTextureBlock_0 dpthis_13, TextureBlock_0 _s_dOut_6)
{

#line 513
    CompressedTextureBlock_0 _S100 = dpthis_13.primal_0;

#line 513
    CompressedTextureBlock_0 _S101 = dpthis_13.primal_0;

#line 513
    CompressedTextureBlock_0 _S102 = dpthis_13.primal_0;

#line 519
    int _S103 = int(dpthis_13.primal_0.max_partitions_1 - uint8_t(1U));

#line 519
    vec3 _S104 = s_primal_ctx_CompressedTextureBlock_ep0_get_0(dpthis_13.primal_0);

#line 519
    vec3 _S105 = s_primal_ctx_CompressedTextureBlock_ep1_get_0(dpthis_13.primal_0);

#line 519
    vec3 _S106 = s_primal_ctx_CompressedTextureBlock_ep2_get_0(dpthis_13.primal_0);

#line 519
    vec3 _S107 = s_primal_ctx_CompressedTextureBlock_ep4_get_0(dpthis_13.primal_0);

#line 519
    vec3 _S108 = s_primal_ctx_CompressedTextureBlock_ep3_get_0(dpthis_13.primal_0);

#line 519
    vec3 _S109 = s_primal_ctx_CompressedTextureBlock_ep5_get_0(dpthis_13.primal_0);
    vec3 _S110 = vec3(0.0);

#line 515
    TextureBlock_0 _S111 = TextureBlock_x24_syn_dzero_0();

#line 515
    TextureBlock_0 _S112 = TextureBlock_x24_syn_dadd_0(_s_dOut_6, _S111);

#line 515
    int _dc_0 = 16;

#line 515
    TextureBlock_0 _S113 = _S112;

#line 515
    vec3 _S114 = _S110;

#line 515
    vec3 _S115 = _S110;

#line 515
    vec3 _S116 = _S110;

#line 515
    vec3 _S117 = _S110;

#line 515
    vec3 _S118 = _S110;

#line 515
    vec3 _S119 = _S110;

#line 515
    vec3 _S120 = _S110;
    for(;;)
    {

#line 516
        uint _S121 = uint(_dc_0);

#line 516
        if(_dc_0 >= 0)
        {
        }
        else
        {

#line 516
            break;
        }

#line 516
        bool _S122 = _S121 < 16U;

#line 516
        vec3 e0_2;

#line 516
        vec3 e1_2;

#line 516
        vec3 _S123;

#line 516
        bool _S124;

#line 516
        bool _S125;

#line 516
        bool _S126;

#line 516
        if(_S122)
        {
            int _S127 = int(_S121);

#line 518
            float _S128 = NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(_S101.weights_0, _S127);
            int partition_3 = clamp(int(float(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S102.partition_index_0, _S127))), 0, _S103);
            bool _S129 = partition_3 == 0;

#line 520
            if(_S129)
            {

#line 520
                e0_2 = _S104;

#line 520
                _S124 = false;

#line 520
            }
            else
            {

#line 520
                bool _S130 = partition_3 == 1;

#line 520
                if(_S130)
                {

#line 520
                    e0_2 = _S106;

#line 520
                }
                else
                {

#line 520
                    e0_2 = _S107;

#line 520
                }

#line 520
                _S124 = _S130;

#line 520
            }
            if(_S129)
            {

#line 521
                e1_2 = _S105;

#line 521
                _S125 = false;

#line 521
            }
            else
            {

#line 521
                bool _S131 = partition_3 == 1;

#line 521
                if(_S131)
                {

#line 521
                    e1_2 = _S108;

#line 521
                }
                else
                {

#line 521
                    e1_2 = _S109;

#line 521
                }

#line 521
                _S125 = _S131;

#line 521
            }

#line 520
            bool _S132 = _S124;

#line 520
            _S123 = vec3(_S128);

#line 520
            _S124 = _S129;

#line 520
            _S126 = _S132;

#line 520
        }
        else
        {

#line 520
            e0_2 = _S110;

#line 520
            e1_2 = _S110;

#line 520
            _S123 = _S110;

#line 520
            _S124 = false;

#line 520
            _S125 = false;

#line 520
            _S126 = false;

#line 520
        }

#line 515
        TextureBlock_0 _S133 = TextureBlock_x24_syn_dadd_0(_S113, _S111);

#line 515
        if(_S122)
        {

#line 515
            TextureBlock_0 _S134 = _S133;

#line 515
            _S134.pixels_0[_S121] = _S110;

#line 522
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S135;

#line 522
            _S135.primal_0 = e0_2;

#line 522
            _S135.differential_0 = _S110;

#line 522
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S136;

#line 522
            _S136.primal_0 = e1_2;

#line 522
            _S136.differential_0 = _S110;

#line 522
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S137;

#line 522
            _S137.primal_0 = _S123;

#line 522
            _S137.differential_0 = _S110;

#line 522
            s_bwd_prop_lerp_0(_S135, _S136, _S137, _S133.pixels_0[_S121]);

#line 522
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S138 = _S136;

#line 515
            TextureBlock_0 _S139 = TextureBlock_x24_syn_dadd_0(_S134, _S111);

#line 520
            vec3 _S140 = _S135.differential_0 + _S120;

#line 520
            vec3 _S141;

#line 520
            vec3 _S142;

#line 520
            vec3 _S143;

#line 520
            if(_S124)
            {

#line 521
                vec3 _S144 = _S138.differential_0 + _S118;

#line 521
                _S141 = _S114;

#line 521
                _S142 = _S115;

#line 521
                _S143 = _S144;

#line 521
            }
            else
            {

#line 521
                if(_S125)
                {

#line 521
                    vec3 _S145 = _S138.differential_0 + _S115;

#line 521
                    _S141 = _S114;

#line 521
                    _S142 = _S145;

#line 521
                }
                else
                {

#line 521
                    _S141 = _S138.differential_0 + _S114;

#line 521
                    _S142 = _S115;

#line 521
                }

#line 521
                _S143 = _S118;

#line 521
            }

#line 521
            vec3 _S146;

#line 521
            vec3 _S147;

#line 521
            vec3 _S148;

#line 521
            if(_S124)
            {

#line 520
                vec3 _S149 = _S140 + _S119;

#line 520
                _S146 = _S116;

#line 520
                _S147 = _S117;

#line 520
                _S148 = _S149;

#line 520
            }
            else
            {

#line 520
                if(_S126)
                {

#line 520
                    vec3 _S150 = _S140 + _S117;

#line 520
                    _S146 = _S116;

#line 520
                    _S147 = _S150;

#line 520
                }
                else
                {

#line 520
                    _S146 = _S140 + _S116;

#line 520
                    _S147 = _S117;

#line 520
                }

#line 520
                _S148 = _S119;

#line 520
            }

#line 520
            _S113 = _S139;

#line 520
            _S114 = _S141;

#line 520
            _S115 = _S142;

#line 520
            _S116 = _S146;

#line 520
            _S117 = _S147;

#line 520
            _S118 = _S143;

#line 520
            _S119 = _S148;

#line 520
            _S120 = _S110;

#line 520
        }
        else
        {

#line 520
            _S113 = TextureBlock_x24_syn_dadd_0(_S133, _S111);

#line 520
        }

#line 520
        _dc_0 = _dc_0 - 1;

#line 516
    }

#line 521
    CompressedTextureBlock_Differential_0 _S151 = CompressedTextureBlock_x24_syn_dzero_0();

#line 521
    DiffPair_CompressedTextureBlock_0 _S152;

#line 521
    _S152.primal_0 = _S100;

#line 521
    _S152.differential_0 = _S151;

#line 521
    s_bwd_prop_CompressedTextureBlock_ep5_get_0(_S152, _S114);

#line 521
    DiffPair_CompressedTextureBlock_0 _S153;

#line 521
    _S153.primal_0 = _S100;

#line 521
    _S153.differential_0 = _S151;

#line 521
    s_bwd_prop_CompressedTextureBlock_ep3_get_0(_S153, _S115);

#line 520
    DiffPair_CompressedTextureBlock_0 _S154;

#line 520
    _S154.primal_0 = _S100;

#line 520
    _S154.differential_0 = _S151;

#line 520
    s_bwd_prop_CompressedTextureBlock_ep4_get_0(_S154, _S116);

#line 520
    DiffPair_CompressedTextureBlock_0 _S155;

#line 520
    _S155.primal_0 = _S100;

#line 520
    _S155.differential_0 = _S151;

#line 520
    s_bwd_prop_CompressedTextureBlock_ep2_get_0(_S155, _S117);
    DiffPair_CompressedTextureBlock_0 _S156;

#line 521
    _S156.primal_0 = _S100;

#line 521
    _S156.differential_0 = _S151;

#line 521
    s_bwd_prop_CompressedTextureBlock_ep1_get_0(_S156, _S118);

#line 520
    DiffPair_CompressedTextureBlock_0 _S157;

#line 520
    _S157.primal_0 = _S100;

#line 520
    _S157.differential_0 = _S151;

#line 520
    s_bwd_prop_CompressedTextureBlock_ep0_get_0(_S157, _S119);

#line 520
    CompressedTextureBlock_Differential_0 _S158 = CompressedTextureBlock_x24_syn_dadd_0(CompressedTextureBlock_x24_syn_dadd_0(CompressedTextureBlock_x24_syn_dadd_0(CompressedTextureBlock_x24_syn_dadd_0(CompressedTextureBlock_x24_syn_dadd_0(_S152.differential_0, _S153.differential_0), _S154.differential_0), _S155.differential_0), _S156.differential_0), _S157.differential_0);

#line 520
    dpthis_13.primal_0 = dpthis_13.primal_0;

#line 520
    dpthis_13.differential_0 = _S158;

#line 513
    return;
}


#line 513
void s_bwd_prop_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S159, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S160, float _S161)
{

#line 513
    _d_dot_0(_S159, _S160, _S161);

#line 513
    return;
}


#line 513
void s_bwd_prop_loss_3P_0(uint _S162, inout DiffPair_CompressedTextureBlock_0 _S163, float _S164)
{

#line 513
    CompressedTextureBlock_0 _S165 = _S163.primal_0;

#line 513
    TextureBlock_0 _S166 = s_primal_ctx_CompressedTextureBlock_decompress3P_0(_S163.primal_0);

#line 2239 3
    vec3 _S167 = vec3(0.0);

#line 2239
    int _dc_1 = 16;

#line 2239
    float _S168 = _S164;

#line 2239
    vec3  _S169[16];

#line 2239
    _S169[0] = _S167;

#line 2239
    _S169[1] = _S167;

#line 2239
    _S169[2] = _S167;

#line 2239
    _S169[3] = _S167;

#line 2239
    _S169[4] = _S167;

#line 2239
    _S169[5] = _S167;

#line 2239
    _S169[6] = _S167;

#line 2239
    _S169[7] = _S167;

#line 2239
    _S169[8] = _S167;

#line 2239
    _S169[9] = _S167;

#line 2239
    _S169[10] = _S167;

#line 2239
    _S169[11] = _S167;

#line 2239
    _S169[12] = _S167;

#line 2239
    _S169[13] = _S167;

#line 2239
    _S169[14] = _S167;

#line 2239
    _S169[15] = _S167;

#line 695 0
    for(;;)
    {

#line 695
        if(_dc_1 >= 0)
        {
        }
        else
        {

#line 695
            break;
        }

#line 695
        bool _S170 = _dc_1 < 16;

#line 695
        int _S171;

#line 695
        vec3 _S172;

#line 695
        if(_S170)
        {
            vec3 diff_0 = _S166.pixels_0[_dc_1] - g_groundtruth_0._data[uint(_S162)].pixels_0[_dc_1];

#line 697
            _S171 = 1;

#line 697
            _S172 = diff_0;

#line 697
        }
        else
        {

#line 697
            _S171 = 0;

#line 697
            _S172 = _S167;

#line 697
        }

#line 697
        float _S173;

#line 697
        float _S174;

#line 697
        if(!(_S171 != 1))
        {

#line 697
            _S173 = _S168;

#line 697
            _S174 = 0.0;

#line 697
        }
        else
        {

#line 697
            _S173 = 0.0;

#line 697
            _S174 = _S168;

#line 697
        }

#line 697
        if(_S170)
        {

#line 698
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S175;

#line 698
            _S175.primal_0 = _S172;

#line 698
            _S175.differential_0 = _S167;

#line 698
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S176;

#line 698
            _S176.primal_0 = _S172;

#line 698
            _S176.differential_0 = _S167;

#line 698
            s_bwd_prop_dot_0(_S175, _S176, _S173);

#line 697
            vec3 _S177 = _S176.differential_0 + _S175.differential_0;

#line 693
            float _S178 = _S173 + _S174;

#line 693
            vec3  _S179[16];

#line 693
            _S179[0] = _S167;

#line 693
            _S179[1] = _S167;

#line 693
            _S179[2] = _S167;

#line 693
            _S179[3] = _S167;

#line 693
            _S179[4] = _S167;

#line 693
            _S179[5] = _S167;

#line 693
            _S179[6] = _S167;

#line 693
            _S179[7] = _S167;

#line 693
            _S179[8] = _S167;

#line 693
            _S179[9] = _S167;

#line 693
            _S179[10] = _S167;

#line 693
            _S179[11] = _S167;

#line 693
            _S179[12] = _S167;

#line 693
            _S179[13] = _S167;

#line 693
            _S179[14] = _S167;

#line 693
            _S179[15] = _S167;

#line 693
            _S179[_dc_1] = _S177;

#line 2246 3
            vec3 _S180 = _S169[0] + _S179[0];

#line 2246
            vec3 _S181 = _S169[1] + _S179[1];

#line 2246
            vec3 _S182 = _S169[2] + _S179[2];

#line 2246
            vec3 _S183 = _S169[3] + _S179[3];

#line 2246
            vec3 _S184 = _S169[4] + _S179[4];

#line 2246
            vec3 _S185 = _S169[5] + _S179[5];

#line 2246
            vec3 _S186 = _S169[6] + _S179[6];

#line 2246
            vec3 _S187 = _S169[7] + _S179[7];

#line 2246
            vec3 _S188 = _S169[8] + _S179[8];

#line 2246
            vec3 _S189 = _S169[9] + _S179[9];

#line 2246
            vec3 _S190 = _S169[10] + _S179[10];

#line 2246
            vec3 _S191 = _S169[11] + _S179[11];

#line 2246
            vec3 _S192 = _S169[12] + _S179[12];

#line 2246
            vec3 _S193 = _S169[13] + _S179[13];

#line 2246
            vec3 _S194 = _S169[14] + _S179[14];

#line 2246
            vec3 _S195 = _S169[15] + _S179[15];

#line 2246
            _S168 = _S178;

#line 2246
            _S169[0] = _S180;

#line 2246
            _S169[1] = _S181;

#line 2246
            _S169[2] = _S182;

#line 2246
            _S169[3] = _S183;

#line 2246
            _S169[4] = _S184;

#line 2246
            _S169[5] = _S185;

#line 2246
            _S169[6] = _S186;

#line 2246
            _S169[7] = _S187;

#line 2246
            _S169[8] = _S188;

#line 2246
            _S169[9] = _S189;

#line 2246
            _S169[10] = _S190;

#line 2246
            _S169[11] = _S191;

#line 2246
            _S169[12] = _S192;

#line 2246
            _S169[13] = _S193;

#line 2246
            _S169[14] = _S194;

#line 2246
            _S169[15] = _S195;

#line 2246
        }
        else
        {

#line 2246
            _S168 = _S174;

#line 2246
        }

#line 2246
        _dc_1 = _dc_1 - 1;

#line 695 0
    }

#line 692
    TextureBlock_0 _S196 = TextureBlock_x24_syn_dzero_0();

#line 692
    _S196.pixels_0 = _S169;

#line 692
    CompressedTextureBlock_Differential_0 _S197 = CompressedTextureBlock_x24_syn_dzero_0();

#line 692
    DiffPair_CompressedTextureBlock_0 _S198;

#line 692
    _S198.primal_0 = _S165;

#line 692
    _S198.differential_0 = _S197;

#line 692
    s_bwd_prop_CompressedTextureBlock_decompress3P_0(_S198, _S196);

#line 692
    _S163.primal_0 = _S163.primal_0;

#line 692
    _S163.differential_0 = _S198.differential_0;

#line 688
    return;
}


#line 688
void s_bwd_loss_3P_0(uint _S199, inout DiffPair_CompressedTextureBlock_0 _S200, float _S201)
{

#line 688
    s_bwd_prop_loss_3P_0(_S199, _S200, _S201);

#line 688
    return;
}


#line 688
void CompressedTextureBlock_solve_weights_0(inout CompressedTextureBlock_0 _S202, uint _S203)
{

#line 443
    vec3 L1_0 = CompressedTextureBlock_ep1_get_0(_S202) - CompressedTextureBlock_ep0_get_0(_S202);
    vec3 L2_0 = CompressedTextureBlock_ep3_get_0(_S202) - CompressedTextureBlock_ep2_get_0(_S202);
    vec3 L3_0 = CompressedTextureBlock_ep5_get_0(_S202) - CompressedTextureBlock_ep4_get_0(_S202);
    float _S204 = 1.0 / (dot(L1_0, L1_0) + 9.99999997475242708e-07);
    float _S205 = 1.0 / (dot(L2_0, L2_0) + 9.99999997475242708e-07);
    float _S206 = 1.0 / (dot(L3_0, L3_0) + 9.99999997475242708e-07);

#line 448
    int i_10 = 0;
    for(;;)
    {

#line 449
        if(i_10 < 16)
        {
        }
        else
        {

#line 449
            break;
        }

#line 449
        vec3 C_0 = g_groundtruth_0._data[uint(_S203)].pixels_0[i_10];


        int p_0 = NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S202.partition_index_0, i_10);
        bool _S207 = p_0 == 0;

#line 453
        float pDotL_1;

#line 453
        if(_S207)
        {

#line 453
            pDotL_1 = dot(C_0 - CompressedTextureBlock_ep0_get_0(_S202), L1_0);

#line 453
        }
        else
        {

#line 453
            if(p_0 == 1)
            {

#line 453
                pDotL_1 = dot(C_0 - CompressedTextureBlock_ep2_get_0(_S202), L2_0);

#line 453
            }
            else
            {

#line 453
                pDotL_1 = dot(C_0 - CompressedTextureBlock_ep4_get_0(_S202), L3_0);

#line 453
            }

#line 453
        }

#line 453
        float invLenSq_1;
        if(_S207)
        {

#line 454
            invLenSq_1 = _S204;

#line 454
        }
        else
        {

#line 454
            if(p_0 == 1)
            {

#line 454
                invLenSq_1 = _S205;

#line 454
            }
            else
            {

#line 454
                invLenSq_1 = _S206;

#line 454
            }

#line 454
        }

        _S202.weights_0.data_0[i_10] = uint8_t(round(saturate_0(saturate_0(pDotL_1 * invLenSq_1)) * 255.0));

#line 449
        i_10 = i_10 + 1;

#line 449
    }

#line 458
    return;
}


#line 458
uint CompressedTextureBlock_solve_partition_0(inout CompressedTextureBlock_0 _S208, uint _S209)
{


    vec3 L1_1 = CompressedTextureBlock_ep1_get_0(_S208) - CompressedTextureBlock_ep0_get_0(_S208);
    vec3 L2_1 = CompressedTextureBlock_ep3_get_0(_S208) - CompressedTextureBlock_ep2_get_0(_S208);
    vec3 L3_1 = CompressedTextureBlock_ep5_get_0(_S208) - CompressedTextureBlock_ep4_get_0(_S208);
    float _S210 = 1.0 / (dot(L1_1, L1_1) + 9.99999997475242708e-07);
    float _S211 = 1.0 / (dot(L2_1, L2_1) + 9.99999997475242708e-07);
    float _S212 = 1.0 / (dot(L3_1, L3_1) + 9.99999997475242708e-07);

#line 467
    int i_11 = 0;

#line 467
    uint partitions_0 = 0U;

    for(;;)
    {

#line 469
        if(i_11 < 16)
        {
        }
        else
        {

#line 469
            break;
        }

        vec3 P1_0 = g_groundtruth_0._data[uint(_S209)].pixels_0[i_11] - CompressedTextureBlock_ep0_get_0(_S208);
        vec3 P2_0 = g_groundtruth_0._data[uint(_S209)].pixels_0[i_11] - CompressedTextureBlock_ep2_get_0(_S208);
        vec3 P3_0 = g_groundtruth_0._data[uint(_S209)].pixels_0[i_11] - CompressedTextureBlock_ep4_get_0(_S208);
        float pDotL1_0 = dot(P1_0, L1_1);
        float pDotL2_0 = dot(P2_0, L2_1);
        float pDotL3_0 = dot(P3_0, L3_1);
        float d1_1 = CompressedTextureBlock_distSq_0(P1_0, L1_1, pDotL1_0, _S210);
        float d2_1 = CompressedTextureBlock_distSq_0(P2_0, L2_1, pDotL2_0, _S211);

#line 479
        float d3_1;
        if((_S208.max_partitions_1) == uint8_t(3U))
        {

#line 480
            d3_1 = CompressedTextureBlock_distSq_0(P3_0, L3_1, pDotL3_0, _S212);

#line 480
        }
        else
        {

#line 480
            d3_1 = 1000.0;

#line 480
        }
        uint p_1 = CompressedTextureBlock_argmin_0(d1_1, d2_1, d3_1);
        _S208.partition_index_0.data_1[i_11] = int8_t(int(p_1));
        uint partitions_1 = partitions_0 | uint(1 << p_1);


        bool _S213 = p_1 == 0U;

#line 486
        float pDotL_2;

#line 486
        if(_S213)
        {

#line 486
            pDotL_2 = pDotL1_0;

#line 486
        }
        else
        {

#line 486
            if(p_1 == 1U)
            {

#line 486
                pDotL_2 = pDotL2_0;

#line 486
            }
            else
            {

#line 486
                pDotL_2 = pDotL3_0;

#line 486
            }

#line 486
        }

#line 486
        float invLenSq_2;
        if(_S213)
        {

#line 487
            invLenSq_2 = _S210;

#line 487
        }
        else
        {

#line 487
            if(p_1 == 1U)
            {

#line 487
                invLenSq_2 = _S211;

#line 487
            }
            else
            {

#line 487
                invLenSq_2 = _S212;

#line 487
            }

#line 487
        }

        _S208.weights_0.data_0[i_11] = uint8_t(round(saturate_0(saturate_0(pDotL_2 * invLenSq_2)) * 255.0));

#line 469
        i_11 = i_11 + 1;

#line 469
        partitions_0 = partitions_1;

#line 469
    }

#line 491
    return partitions_0;
}


#line 491
void CompressedTextureBlock_one_step_solve_partition_0(inout CompressedTextureBlock_0 _S214, uint _S215, bool _S216)
{



    if((_S214.max_partitions_1) == uint8_t(1U))
    {

#line 496
        CompressedTextureBlock_solve_weights_0(_S214, _S215);

        return;
    }

#line 498
    uint _S217 = CompressedTextureBlock_solve_partition_0(_S214, _S215);

#line 498
    bool single_partition_0;

#line 504
    if((_S214.max_partitions_1) > uint8_t(1U))
    {

#line 504
        if(_S217 == 1U)
        {

#line 504
            single_partition_0 = true;

#line 504
        }
        else
        {

#line 504
            single_partition_0 = _S217 == 2U;

#line 504
        }

#line 504
        if(single_partition_0)
        {

#line 504
            single_partition_0 = true;

#line 504
        }
        else
        {

#line 504
            single_partition_0 = _S217 == 4U;

#line 504
        }

#line 504
    }
    else
    {

#line 504
        single_partition_0 = false;

#line 504
    }
    if(_S216)
    {

#line 505
        single_partition_0 = true;

#line 505
    }

#line 505
    if(single_partition_0)
    {

#line 506
        CompressedTextureBlock_snap_0(_S214);

#line 506
        CompressedTextureBlock_solve_weights_0(_S214, _S215);

#line 505
    }

#line 510
    return;
}


#line 510
float loss_3P_0(uint _S218, CompressedTextureBlock_0 _S219)
{

#line 692
    TextureBlock_0 _S220 = CompressedTextureBlock_decompress3P_0(_S219);

#line 692
    int i_12 = 0;

#line 692
    float totalError_0 = 0.0;


    for(;;)
    {

#line 695
        if(i_12 < 16)
        {
        }
        else
        {

#line 695
            break;
        }
        vec3 diff_1 = _S220.pixels_0[i_12] - g_groundtruth_0._data[uint(_S218)].pixels_0[i_12];
        float totalError_1 = totalError_0 + dot(diff_1, diff_1);

#line 695
        i_12 = i_12 + 1;

#line 695
        totalError_0 = totalError_1;

#line 695
    }

#line 701
    return totalError_0;
}


#line 714
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 716
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_params_0.num_blocks_0))
    {

#line 717
        return;
    }

#line 718
    uvec2 _S221 = (clockRealtime2x32EXT());

#line 718
    g_diagnostics_0._data[uint(blockIdx_0)].start_clock_0 = _S221;

    uint8_t perm_5 = uint8_t(0U);
    CompressedTextureBlock_0 block_0 = g_compressedBlock3P_0._data[uint(blockIdx_0)];

    float _S222 = g_params_0.learning_rate_0;
    uint steps_1 = g_params_0.steps_0;
    bool _S223 = int(g_params_0.snap_0) > 0;

#line 725
    uint _S224;
    if((g_params_0.snap_steps_0) == 0U)
    {

#line 726
        _S224 = uint(float(steps_1) * 0.5);

#line 726
    }
    else
    {

#line 726
        _S224 = steps_1 - g_params_0.snap_steps_0;

#line 726
    }

    uint _S225 = g_params_0.exact_steps_0;

    PCG32_0 prng_0 = PCG32_x24init_0(g_params_0.seed_0);
    block_0.max_partitions_1 = uint8_t(g_params_0.max_partitions_0);

#line 731
    CompressedTextureBlock_random_initialize_0(block_0, blockIdx_0, prng_0);

#line 731
    int i_13 = 0;

    for(;;)
    {

#line 733
        if(i_13 < 16)
        {
        }
        else
        {

#line 733
            break;
        }

#line 734
        float _S226 = PCG32_nextFloat_0(prng_0);

#line 734
        block_0.weights_0.data_0[i_13] = uint8_t(round(saturate_0(_S226) * 255.0));
        uint _S227 = PCG32_nextUint_0(prng_0);

#line 735
        uint _S228 = _S227 % uint(block_0.max_partitions_1);

#line 735
        block_0.partition_index_0.data_1[i_13] = int8_t(int(_S228));

#line 733
        i_13 = i_13 + 1;

#line 733
    }

#line 738
    uint _S229 = max(1U, steps_1 / 20U);

#line 738
    int step_0 = 0;
    for(;;)
    {

#line 739
        uint _S230 = uint(step_0);

#line 739
        if(_S230 < steps_1)
        {
        }
        else
        {

#line 739
            break;
        }

#line 739
        bool _S231;


        if(_S225 > 0U)
        {

#line 742
            _S231 = _S230 >= 1U;

#line 742
        }
        else
        {

#line 742
            _S231 = false;

#line 742
        }

#line 742
        bool should_use_lsq_0;

#line 742
        if(_S231)
        {

#line 742
            should_use_lsq_0 = _S230 <= (1U + _S225);

#line 742
        }
        else
        {

#line 742
            should_use_lsq_0 = false;

#line 742
        }
        if(should_use_lsq_0)
        {


            if(g_params_0.use_pca_0)
            {

#line 748
                vec3 _S232 = CompressedTextureBlock_ep0_get_0(block_0);

#line 748
                vec3 _S233 = CompressedTextureBlock_ep1_get_0(block_0);

#line 748
                uint _S234 = solve_pca_eps_0(block_0, _S232, _S233, blockIdx_0, 0);

#line 748
                block_0._ep0_0 = quantize_0(f16vec3(_S232), 255U);

#line 748
                block_0._ep1_0 = quantize_0(f16vec3(_S233), 255U);
                vec3 _S235 = CompressedTextureBlock_ep2_get_0(block_0);

#line 749
                vec3 _S236 = CompressedTextureBlock_ep3_get_0(block_0);

#line 749
                uint _S237 = solve_pca_eps_0(block_0, _S235, _S236, blockIdx_0, 1);

#line 749
                block_0._ep2_0 = quantize_0(f16vec3(_S235), 255U);

#line 749
                block_0._ep3_0 = quantize_0(f16vec3(_S236), 255U);
                vec3 _S238 = CompressedTextureBlock_ep4_get_0(block_0);

#line 750
                vec3 _S239 = CompressedTextureBlock_ep5_get_0(block_0);

#line 750
                uint _S240 = solve_pca_eps_0(block_0, _S238, _S239, blockIdx_0, 2);

#line 750
                block_0._ep4_0 = quantize_0(f16vec3(_S238), 255U);

#line 750
                block_0._ep5_0 = quantize_0(f16vec3(_S239), 255U);

#line 747
            }
            else
            {


                vec3 _S241 = CompressedTextureBlock_ep0_get_0(block_0);

#line 752
                vec3 _S242 = CompressedTextureBlock_ep1_get_0(block_0);

#line 752
                solve_aabb_eps_0(block_0, _S241, _S242, blockIdx_0, 0);

#line 752
                block_0._ep0_0 = quantize_0(f16vec3(_S241), 255U);

#line 752
                block_0._ep1_0 = quantize_0(f16vec3(_S242), 255U);
                vec3 _S243 = CompressedTextureBlock_ep2_get_0(block_0);

#line 753
                vec3 _S244 = CompressedTextureBlock_ep3_get_0(block_0);

#line 753
                solve_aabb_eps_0(block_0, _S243, _S244, blockIdx_0, 1);

#line 753
                block_0._ep2_0 = quantize_0(f16vec3(_S243), 255U);

#line 753
                block_0._ep3_0 = quantize_0(f16vec3(_S244), 255U);
                vec3 _S245 = CompressedTextureBlock_ep4_get_0(block_0);

#line 754
                vec3 _S246 = CompressedTextureBlock_ep5_get_0(block_0);

#line 754
                solve_aabb_eps_0(block_0, _S245, _S246, blockIdx_0, 2);

#line 754
                block_0._ep4_0 = quantize_0(f16vec3(_S245), 255U);

#line 754
                block_0._ep5_0 = quantize_0(f16vec3(_S246), 255U);

#line 747
            }

#line 743
        }
        else
        {

#line 759
            CompressedTextureBlock_Differential_0 _S247 = CompressedTextureBlock_x24_syn_dzero_0();

#line 759
            DiffPair_CompressedTextureBlock_0 cb_pair_0;

#line 759
            cb_pair_0.primal_0 = block_0;

#line 759
            cb_pair_0.differential_0 = _S247;

#line 759
            s_bwd_loss_3P_0(blockIdx_0, cb_pair_0, 1.0);


            block_0._ep0_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep0_get_0(block_0) - vec3(cb_pair_0.differential_0._ep0_1) * _S222)), 255U);
            block_0._ep1_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep1_get_0(block_0) - vec3(cb_pair_0.differential_0._ep1_1) * _S222)), 255U);
            block_0._ep2_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep2_get_0(block_0) - vec3(cb_pair_0.differential_0._ep2_1) * _S222)), 255U);
            block_0._ep3_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep3_get_0(block_0) - vec3(cb_pair_0.differential_0._ep3_1) * _S222)), 255U);
            block_0._ep4_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep4_get_0(block_0) - vec3(cb_pair_0.differential_0._ep4_1) * _S222)), 255U);
            block_0._ep5_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep5_get_0(block_0) - vec3(cb_pair_0.differential_0._ep5_1) * _S222)), 255U);

#line 743
        }

#line 743
        bool _S248;

#line 770
        if(_S223)
        {

#line 770
            if(_S230 >= _S224)
            {

#line 770
                _S248 = true;

#line 770
            }
            else
            {

#line 770
                _S248 = _S230 >= (steps_1 - 1U);

#line 770
            }

#line 770
        }
        else
        {

#line 770
            _S248 = false;

#line 770
        }

#line 770
        CompressedTextureBlock_one_step_solve_partition_0(block_0, blockIdx_0, _S248);

        uint _S249 = _S230 % _S229;

#line 772
        if(_S249 == 0U)
        {

#line 773
            uint iter_1 = _S230 / _S229;
            uvec2 _S250 = (clockRealtime2x32EXT());

#line 774
            g_diagnostics_0._data[uint(blockIdx_0)].timestamps_0[iter_1] = _S250;
            g_diagnostics_0._data[uint(blockIdx_0)].loss_log_0[iter_1] = loss_3P_0(blockIdx_0, block_0);

            uint pattern_2 = CompressedTextureBlock_pack_partition_indices_0(block_0);
            uint final_mask_1 = 0U;

            if((block_0.max_partitions_1) == uint8_t(3U))
            {

#line 780
                uint _S251 = get_closest_seed3_0(pattern_2, perm_5, final_mask_1);

#line 780
            }
            else
            {

#line 781
                uint _S252 = get_closest_seed2_0(pattern_2, perm_5, final_mask_1);

#line 780
            }

#line 780
            uint _S253;


            if((block_0.max_partitions_1) == uint8_t(3U))
            {

#line 783
                uint _S254 = best_perm_distance_s3_0(pattern_2, final_mask_1, perm_5);

#line 783
                _S253 = _S254;

#line 783
            }
            else
            {

#line 784
                uint _S255 = best_perm_distance_s2_0(pattern_2, final_mask_1, perm_5);

#line 784
                _S253 = _S255;

#line 783
            }

#line 782
            g_diagnostics_0._data[uint(blockIdx_0)].partition_hamming_error_log_0[iter_1] = _S253;


            g_diagnostics_0._data[uint(blockIdx_0)].ideal_partition_log_0[iter_1] = pattern_2;

#line 790
            g_diagnostics_0._data[uint(blockIdx_0)].partition_count_0[iter_1] = uint((hamming_distance_2b_0(pattern_2, 0U)) < 16U) + uint((hamming_distance_2b_0(pattern_2, 1431655765U)) < 16U) + uint((hamming_distance_2b_0(pattern_2, 2863311530U)) < 16U);

#line 772
        }

#line 739
        step_0 = step_0 + 1;

#line 739
    }

#line 794
    uvec2 _S256 = (clockRealtime2x32EXT());

#line 794
    g_diagnostics_0._data[uint(blockIdx_0)].optim_ended_clock_0 = _S256;
    g_compressedBlock3P_0._data[uint(blockIdx_0)] = block_0;
    g_reconstructed_0._data[uint(blockIdx_0)] = CompressedTextureBlock_reconstruct_0(block_0);
    uint _S257 = best_perm_distance_s3_0(block_0.ideal_partition_map_0, block_0.astc_partition_map_0, perm_5);

#line 797
    g_diagnostics_0._data[uint(blockIdx_0)].partition_hamming_error_0 = _S257;
    g_final_loss_0._data[uint(blockIdx_0)] = loss_3P_0(blockIdx_0, block_0);
    uvec2 _S258 = (clockRealtime2x32EXT());

#line 799
    g_diagnostics_0._data[uint(blockIdx_0)].finished_clock_0 = _S258;
    return;
}

