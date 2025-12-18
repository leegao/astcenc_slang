#version 450
#extension GL_EXT_shader_8bit_storage : require
#extension GL_EXT_shader_explicit_arithmetic_types : require
#extension GL_EXT_shader_16bit_storage : require
#extension GL_EXT_shader_realtime_clock : require
#extension GL_EXT_control_flow_attributes : require
layout(row_major) uniform;
layout(row_major) buffer;

#line 34 0
struct Params_0
{
    float learning_rate_0;
    uint steps_0;
    uint steps_1p_0;
    uint snap_steps_0;
    uint num_blocks_0;
    bool snap_0;
    uint8_t max_partitions_0;
    bool debug_reconstruction_0;
    bool debug_quant_0;
    bool debug_loss_0;
    uint exact_steps_0;
    bool use_pca_0;
    uint seed_0;
    bool no_quantization_0;
    bool ensemble_0;
};


#line 52
layout(binding = 0)
layout(std140) uniform block_Params_0
{
    float learning_rate_0;
    uint steps_0;
    uint steps_1p_0;
    uint snap_steps_0;
    uint num_blocks_0;
    bool snap_0;
    uint8_t max_partitions_0;
    bool debug_reconstruction_0;
    bool debug_quant_0;
    bool debug_loss_0;
    uint exact_steps_0;
    bool use_pca_0;
    uint seed_0;
    bool no_quantization_0;
    bool ensemble_0;
}g_params_0;

#line 14
struct Diagnostics_0
{
    uint partition_hamming_error_0;
    vec3  loss_log_0[12];
    uvec2 start_clock_0;
    uvec2 optim_ended_clock_0;
    uvec2 finished_clock_0;
    uvec2  timestamps_0[12];
    uint  partition_hamming_error_log_0[12];
    uint  ideal_partition_log_0[12];
    uint  partition_count_0[12];
    float final_unquantized_loss_0;
};


#line 61
layout(std430, binding = 3) buffer StructuredBuffer_Diagnostics_t_0 {
    Diagnostics_0 _data[];
} g_diagnostics_0;

#line 8
struct TextureBlock_0
{
    vec3  pixels_0[16];
};


#line 55
layout(std430, binding = 1) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;

#line 358
struct NonDifferentiableFP8Weights_0
{
    uint8_t  data_0[16];
};


#line 395
struct NonDifferentiableIntPartitions_0
{
    int8_t  data_1[16];
};


#line 412
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
    u8vec2 qwc_0;
    u8vec2 fqwc_0;
};


#line 64
layout(std430, binding = 4) buffer StructuredBuffer_CompressedTextureBlock_t_0 {
    CompressedTextureBlock_0 _data[];
} g_compressedBlock3P_0;

#line 71
layout(std430, binding = 7) readonly buffer StructuredBuffer_uint_t_0 {
    uint _data[];
} g_astc_3p_4x4_lut_s3_0;

#line 73
struct LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
};


#line 78
layout(binding = 8)
layout(std140) uniform block_LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
}g_lut_0;

#line 70
layout(std430, binding = 6) readonly buffer StructuredBuffer_uint_t_1 {
    uint _data[];
} g_astc_2p_4x4_lut_s2_0;

#line 58
layout(std430, binding = 2) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;

#line 67
layout(std430, binding = 5) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 344
const u8vec2  VALID_3P_QUANTIZATION_RANGES_0[9] = { u8vec2(uint8_t(7U), uint8_t(5U)), u8vec2(uint8_t(5U), uint8_t(7U)), u8vec2(uint8_t(4U), uint8_t(9U)), u8vec2(uint8_t(3U), uint8_t(11U)), u8vec2(uint8_t(2U), uint8_t(15U)), u8vec2(uint8_t(1U), uint8_t(23U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)) };

#line 331
const u8vec2  VALID_2P_QUANTIZATION_RANGES_0[9] = { u8vec2(uint8_t(15U), uint8_t(5U)), u8vec2(uint8_t(11U), uint8_t(9U)), u8vec2(uint8_t(9U), uint8_t(11U)), u8vec2(uint8_t(7U), uint8_t(15U)), u8vec2(uint8_t(5U), uint8_t(23U)), u8vec2(uint8_t(4U), uint8_t(31U)), u8vec2(uint8_t(3U), uint8_t(39U)), u8vec2(uint8_t(2U), uint8_t(63U)), u8vec2(uint8_t(1U), uint8_t(95U)) };

#line 318
const u8vec2  VALID_1P_QUANTIZATION_RANGES_0[9] = { u8vec2(uint8_t(31U), uint8_t(31U)), u8vec2(uint8_t(23U), uint8_t(63U)), u8vec2(uint8_t(19U), uint8_t(95U)), u8vec2(uint8_t(15U), uint8_t(191U)), u8vec2(uint8_t(11U), uint8_t(255U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)) };

#line 83
struct PCG32_0
{
    uint state_0;
};


#line 87
PCG32_0 PCG32_x24init_0(uint seed_1)
{

#line 87
    PCG32_0 _S1;

    uint _S2 = seed_1 * 747796405U + 2891336453U;
    uint _S3 = ((_S2 >> ((_S2 >> 28U) + 4U)) ^ _S2) * 277803737U;
    _S1.state_0 = (_S3 >> 22U) ^ _S3;

#line 87
    return _S1;
}


#line 102
uint PCG32_nextUint_0(inout PCG32_0 this_0)
{
    uint oldState_0 = this_0.state_0;
    this_0.state_0 = this_0.state_0 * 747796405U + 2891336453U;
    uint word_0 = ((oldState_0 >> ((oldState_0 >> 28U) + 4U)) ^ oldState_0) * 277803737U;
    return (word_0 >> 22U) ^ word_0;
}


#line 312
f16vec3 quantize_0(f16vec3 value_0, uint range_0)
{
    f16vec3 scale_0 = f16vec3(float16_t(int(range_0)));
    return round(value_0 * scale_0) / scale_0;
}


#line 95
float PCG32_nextFloat_0(inout PCG32_0 this_1)
{
    uint result_0 = PCG32_nextUint_0(this_1);
    return uintBitsToFloat(1065353216U | (result_0 >> 9)) - 1.0;
}


#line 13393 1
float saturate_0(float x_0)
{

#line 13401
    return clamp(x_0, 0.0, 1.0);
}


#line 434 0
vec3 CompressedTextureBlock_ep1_get_0(CompressedTextureBlock_0 this_2)
{
    return vec3(this_2._ep1_0);
}


#line 434
vec3 CompressedTextureBlock_ep0_get_0(CompressedTextureBlock_0 this_3)
{
    return vec3(this_3._ep0_0);
}


#line 436
struct DiffPair_vectorx3Cfloatx2C3x3E_0
{
    vec3 primal_0;
    vec3 differential_0;
};


#line 1639 2
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


#line 434 0
vec3 CompressedTextureBlock_ep2_get_0(CompressedTextureBlock_0 this_4)
{
    return vec3(this_4._ep2_0);
}


#line 1077
float dist_0(vec3 x_1, vec3 ep0_0, vec3 ep1_0)
{
    vec3 lineDir_0 = ep1_0 - ep0_0;

    return length(cross(x_1 - ep0_0, lineDir_0)) / length(lineDir_0);
}


#line 434
vec3 CompressedTextureBlock_ep3_get_0(CompressedTextureBlock_0 this_5)
{
    return vec3(this_5._ep3_0);
}


#line 434
vec3 CompressedTextureBlock_ep4_get_0(CompressedTextureBlock_0 this_6)
{
    return vec3(this_6._ep4_0);
}


#line 434
vec3 CompressedTextureBlock_ep5_get_0(CompressedTextureBlock_0 this_7)
{
    return vec3(this_7._ep5_0);
}


#line 363
float NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(NonDifferentiableFP8Weights_0 this_8, int n_0)
{
    return float(this_8.data_0[n_0]) / 255.0;
}


#line 400
int NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(NonDifferentiableIntPartitions_0 this_9, int n_1)
{
    return int(this_9.data_1[n_1]);
}


#line 8119 1
struct DiffPair_float_0
{
    float primal_0;
    float differential_0;
};


#line 2263 2
void _d_lerp_0(inout DiffPair_float_0 dpx_1, inout DiffPair_float_0 dpy_1, inout DiffPair_float_0 dps_0, float dOut_1)
{

#line 2263
    float _S4 = (1.0 - dps_0.primal_0) * dOut_1;

#line 2263
    dpx_1.primal_0 = dpx_1.primal_0;

#line 2263
    dpx_1.differential_0 = _S4;


    DiffPair_float_0 _S5 = dpy_1;

#line 2266
    float _S6 = dps_0.primal_0 * dOut_1;

#line 2266
    dpy_1.primal_0 = dpy_1.primal_0;

#line 2266
    dpy_1.differential_0 = _S6;

#line 2266
    float _S7 = (_S5.primal_0 - dpx_1.primal_0) * dOut_1;

#line 2266
    dps_0.primal_0 = _S5.primal_0;

#line 2266
    dps_0.differential_0 = _S7;

    return;
}


#line 1 3
void _d_lerp_vector_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpx_2, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpy_2, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpz_0, vec3 dOut_2)
{

#line 1841 2
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


#line 626 0
TextureBlock_0 CompressedTextureBlock_decompress3P_0(CompressedTextureBlock_0 this_10)
{
    TextureBlock_0 outputBlock_0;

#line 628
    uint i_0 = 0U;

    [[unroll]]
    for(;;)
    {

#line 630
        if(i_0 < 16U)
        {
        }
        else
        {

#line 630
            break;
        }
        int _S8 = int(i_0);

#line 632
        float _S9 = NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(this_10.weights_0, _S8);
        int partition_0 = clamp(int(float(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(this_10.partition_index_0, _S8))), 0, int(this_10.max_partitions_1 - uint8_t(1U)));
        bool _S10 = partition_0 == 0;

#line 634
        vec3 e0_0;

#line 634
        if(_S10)
        {

#line 634
            e0_0 = CompressedTextureBlock_ep0_get_0(this_10);

#line 634
        }
        else
        {

#line 634
            if(partition_0 == 1)
            {

#line 634
                e0_0 = CompressedTextureBlock_ep2_get_0(this_10);

#line 634
            }
            else
            {

#line 634
                e0_0 = CompressedTextureBlock_ep4_get_0(this_10);

#line 634
            }

#line 634
        }

#line 634
        vec3 e1_0;
        if(_S10)
        {

#line 635
            e1_0 = CompressedTextureBlock_ep1_get_0(this_10);

#line 635
        }
        else
        {

#line 635
            if(partition_0 == 1)
            {

#line 635
                e1_0 = CompressedTextureBlock_ep3_get_0(this_10);

#line 635
            }
            else
            {

#line 635
                e1_0 = CompressedTextureBlock_ep5_get_0(this_10);

#line 635
            }

#line 635
        }
        outputBlock_0.pixels_0[i_0] = mix(e0_0, e1_0, vec3(_S9));

#line 630
        i_0 = i_0 + 1U;

#line 630
    }

#line 638
    return outputBlock_0;
}


#line 13408 1
vec3 saturate_1(vec3 x_2)
{

#line 13416
    return clamp(x_2, vec3(0.0), vec3(1.0));
}


#line 889 0
void bound_and_damp_0(vec3 x_3, vec3 y_0, inout vec3 x_out_0, inout vec3 y_out_0, float lr_0)
{
    vec3 _S11 = x_out_0;
    vec3 _S12 = y_out_0;

    const vec3 boxMin_0 = vec3(0.0, 0.0, 0.0);
    const vec3 boxMax_0 = vec3(1.0, 1.0, 1.0);

#line 895
    bool xInside_0;

    if((all(bvec3((greaterThanEqual(x_3,boxMin_0))))))
    {

#line 897
        xInside_0 = (all(bvec3((lessThanEqual(x_3,boxMax_0)))));

#line 897
    }
    else
    {

#line 897
        xInside_0 = false;

#line 897
    }

#line 897
    bool yInside_0;
    if((all(bvec3((greaterThanEqual(y_0,boxMin_0))))))
    {

#line 898
        yInside_0 = (all(bvec3((lessThanEqual(y_0,boxMax_0)))));

#line 898
    }
    else
    {

#line 898
        yInside_0 = false;

#line 898
    }

    vec3 d_0 = y_0 - x_3;
    float distSq_0 = dot(d_0, d_0);
    if(!xInside_0)
    {

#line 902
        xInside_0 = true;

#line 902
    }
    else
    {

#line 902
        xInside_0 = !yInside_0;

#line 902
    }

#line 902
    bool shouldClip_0;

#line 902
    if(xInside_0)
    {

#line 902
        shouldClip_0 = true;

#line 902
    }
    else
    {

#line 902
        shouldClip_0 = distSq_0 < 0.00999999977648258;

#line 902
    }

#line 902
    vec3 new_x_0;

#line 902
    vec3 new_y_0;

#line 907
    if(shouldClip_0)
    {
        vec3 invDir_0 = 1.0 / (d_0 + 9.99999997475242708e-07);
        vec3 t0_0 = (boxMin_0 - x_3) * invDir_0;
        vec3 t1_0 = (boxMax_0 - x_3) * invDir_0;
        vec3 tSmall_0 = min(t0_0, t1_0);
        vec3 tBig_0 = max(t0_0, t1_0);

#line 920
        vec3 _S13 = saturate_1(x_3 + d_0 * min(min(min(tBig_0.x, tBig_0.y), tBig_0.z), 1.0));

#line 920
        new_x_0 = saturate_1(x_3 + d_0 * max(max(max(tSmall_0.x, tSmall_0.y), tSmall_0.z), 0.0));

#line 920
        new_y_0 = _S13;

#line 907
    }
    else
    {

#line 907
        new_x_0 = x_3;

#line 907
        new_y_0 = y_0;

#line 907
    }

#line 923
    vec3 _S14 = vec3(lr_0);

#line 923
    x_out_0 = mix(_S11, new_x_0, _S14);
    y_out_0 = mix(_S12, new_y_0, _S14);
    return;
}


#line 412
struct CompressedTextureBlock_Differential_0
{
    f16vec3 _ep0_1;
    f16vec3 _ep1_1;
    f16vec3 _ep2_1;
    f16vec3 _ep3_1;
    f16vec3 _ep4_1;
    f16vec3 _ep5_1;
};


#line 412
CompressedTextureBlock_Differential_0 CompressedTextureBlock_x24_syn_dzero_0()
{

#line 412
    CompressedTextureBlock_Differential_0 result_1;

#line 2239 4
    f16vec3 _S15 = f16vec3(0.0HF);

#line 2239
    result_1._ep0_1 = _S15;

#line 2239
    result_1._ep1_1 = _S15;

#line 2239
    result_1._ep2_1 = _S15;

#line 2239
    result_1._ep3_1 = _S15;

#line 2239
    result_1._ep4_1 = _S15;

#line 2239
    result_1._ep5_1 = _S15;

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


#line 530 0
float CompressedTextureBlock_distSq_0(vec3 P_0, vec3 L_0, float pDotL_0, float invLenSq_0)
{

    return dot(P_0, P_0) - pDotL_0 * pDotL_0 * invLenSq_0;
}

uint CompressedTextureBlock_argmin_0(float d1_0, float d2_0, float d3_0)
{

#line 536
    bool _S16;

    if(d1_0 < d2_0)
    {

#line 538
        _S16 = d1_0 < d3_0;

#line 538
    }
    else
    {

#line 538
        _S16 = false;

#line 538
    }

#line 538
    if(_S16)
    {

#line 539
        return 0U;
    }

#line 540
    if(d2_0 < d3_0)
    {

#line 541
        return 1U;
    }

#line 542
    return 2U;
}


#line 451
uint CompressedTextureBlock_pack_partition_indices_0(CompressedTextureBlock_0 this_11)
{

#line 451
    int i_1 = 0;

#line 451
    uint raw_map_0 = 0U;


    for(;;)
    {

#line 454
        if(i_1 < 16)
        {
        }
        else
        {

#line 454
            break;
        }

        uint raw_map_1 = raw_map_0 | (uint(clamp(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(this_11.partition_index_0, i_1), 0, 2)) << (i_1 * 2));

#line 454
        i_1 = i_1 + 1;

#line 454
        raw_map_0 = raw_map_1;

#line 454
    }

#line 459
    return raw_map_0;
}


#line 225
uint lut3_key_0(uint x_4)
{

#line 225
    uint result_3 = 0U;

#line 225
    int i_2 = 15;

#line 230
    [[unroll]]
    for(;;)
    {

#line 230
        if(i_2 >= 0)
        {
        }
        else
        {

#line 230
            break;
        }
        uint _S17 = result_3 * 3U + ((x_4 >> (i_2 * 2)) & 3U);

#line 230
        int _S18 = i_2 - 1;

#line 230
        result_3 = _S17;

#line 230
        i_2 = _S18;

#line 230
    }



    return result_3;
}


#line 122
uint permute_swap01_0(uint x_5)
{
    return x_5 ^ ((~(x_5 >> 1)) & 1431655765U);
}

uint permute_swap02_0(uint x_6)
{
    return x_6 ^ ((~(x_6 << 1)) & 2863311530U);
}

uint permute_swap12_0(uint x_7)
{
    uint non_zero_0 = (x_7 | (x_7 >> 1)) & 1431655765U;

    return x_7 ^ (non_zero_0 | (non_zero_0 << 1));
}

uint permute_cycle_120_0(uint x_8)
{

    uint s_0 = x_8 + 1431655765U;
    uint mask_0 = (s_0 & (s_0 >> 1)) & 1431655765U;
    return s_0 & (~(mask_0 | (mask_0 << 1)));
}

uint permute_cycle_201_0(uint x_9)
{

#line 153
    return permute_cycle_120_0(permute_cycle_120_0(x_9));
}


#line 237
uint canonicalize_lut3_0(uint x_10)
{

#line 249
    return min(min(lut3_key_0(x_10), lut3_key_0(permute_swap01_0(x_10))), min(min(lut3_key_0(permute_swap02_0(x_10)), lut3_key_0(permute_swap12_0(x_10))), min(lut3_key_0(permute_cycle_120_0(x_10)), lut3_key_0(permute_cycle_201_0(x_10)))));
}


#line 279
uint count_diffs_0(uint val_0)
{
    return bitCount((val_0 | (val_0 >> 1)) & 1431655765U);
}


#line 179
uint best_perm_distance_s3_0(uint x_11, uint y_1, out uint8_t perm_1)
{
    uint base_0 = x_11 ^ y_1;

    uint x_shr1_0 = x_11 >> 1;
    uint nz_0 = (x_11 | x_shr1_0) & 1431655765U;
    uint nz_shl1_0 = nz_0 << 1;

    uint m01_0 = (~x_shr1_0) & 1431655765U;

#line 203
    uint best_0 = min(min(min(((count_diffs_0(base_0)) << 3) | 0U, ((count_diffs_0(base_0 ^ m01_0)) << 3) | 1U), min(((count_diffs_0(base_0 ^ ((~(x_11 << 1)) & 2863311530U))) << 3) | 2U, ((count_diffs_0(base_0 ^ (nz_0 | nz_shl1_0))) << 3) | 3U)), min(((count_diffs_0(base_0 ^ (m01_0 | nz_shl1_0))) << 3) | 4U, ((count_diffs_0(base_0 ^ (nz_0 | (((~x_11) & 1431655765U) << 1)))) << 3) | 5U));

    perm_1 = uint8_t(int(best_0 & 7U));
    return best_0 >> 3;
}


#line 284
uint get_closest_seed3_0(uint input_0, out uint8_t perm_2, out uint final_pattern_0)
{
    uint key_0 = canonicalize_lut3_0(input_0);
    uint seed_2 = ((g_astc_3p_4x4_lut_s3_0._data[uint(key_0 / 3U)]) >> (key_0 % 3U * 10U)) & 1023U;
    uint pattern_0 = g_lut_0.lut3_0[seed_2];
    uint _S19 = best_perm_distance_s3_0(input_0, g_lut_0.lut3_0[seed_2], perm_2);

    final_pattern_0 = pattern_0;
    return seed_2;
}


#line 252
uint lut2_key_0(uint x_12)
{

#line 252
    uint result_4 = 0U;

#line 252
    int i_3 = 15;

#line 257
    [[unroll]]
    for(;;)
    {

#line 257
        if(i_3 >= 0)
        {
        }
        else
        {

#line 257
            break;
        }
        uint _S20 = result_4 * 2U + ((x_12 >> (i_3 * 2)) & 3U);

#line 257
        int _S21 = i_3 - 1;

#line 257
        result_4 = _S20;

#line 257
        i_3 = _S21;

#line 257
    }



    return result_4;
}

uint canonicalize_lut2_0(uint x_13)
{


    return min(lut2_key_0(x_13), lut2_key_0(permute_swap01_0(x_13)));
}


#line 209
uint best_perm_distance_s2_0(uint x_14, uint y_2, out uint8_t perm_3)
{
    uint base_1 = x_14 ^ y_2;

#line 219
    uint min01_0 = min(((count_diffs_0(base_1)) << 1) | 0U, ((count_diffs_0(base_1 ^ ((~(x_14 >> 1)) & 1431655765U))) << 1) | 1U);

    perm_3 = uint8_t(int(min01_0 & 1U));
    return min01_0 >> 1;
}


#line 295
uint get_closest_seed2_0(uint input_1, out uint8_t permutation_0, out uint final_pattern_1)
{
    uint key_1 = canonicalize_lut2_0(input_1);
    uint seed_3 = ((g_astc_2p_4x4_lut_s2_0._data[uint(key_1 / 3U)]) >> (key_1 % 3U * 10U)) & 1023U;
    uint pattern_1 = g_lut_0.lut2_0[seed_3];
    uint _S22 = best_perm_distance_s2_0(input_1, g_lut_0.lut2_0[seed_3], permutation_0);

    final_pattern_1 = pattern_1;
    return seed_3;
}


#line 463
void CompressedTextureBlock_swap_colors_0(inout CompressedTextureBlock_0 this_12, uint8_t perm_4)
{
    vec3 old_ep0_0 = CompressedTextureBlock_ep0_get_0(this_12);
    vec3 old_ep1_0 = CompressedTextureBlock_ep1_get_0(this_12);
    vec3 old_ep2_0 = CompressedTextureBlock_ep2_get_0(this_12);
    vec3 old_ep3_0 = CompressedTextureBlock_ep3_get_0(this_12);
    vec3 old_ep4_0 = CompressedTextureBlock_ep4_get_0(this_12);
    vec3 old_ep5_0 = CompressedTextureBlock_ep5_get_0(this_12);



    bool _S23 = perm_4 == uint8_t(1U);

#line 474
    bool from_pair1_0;

#line 474
    if(_S23)
    {

#line 474
        from_pair1_0 = true;

#line 474
    }
    else
    {

#line 474
        from_pair1_0 = perm_4 == uint8_t(5U);

#line 474
    }
    bool _S24 = perm_4 == uint8_t(2U);

#line 475
    bool from_pair2_0;

#line 475
    if(_S24)
    {

#line 475
        from_pair2_0 = true;

#line 475
    }
    else
    {

#line 475
        from_pair2_0 = perm_4 == uint8_t(4U);

#line 475
    }

#line 475
    vec3 _S25;
    if(from_pair1_0)
    {

#line 476
        _S25 = old_ep2_0;

#line 476
    }
    else
    {

#line 476
        if(from_pair2_0)
        {

#line 476
            _S25 = old_ep4_0;

#line 476
        }
        else
        {

#line 476
            _S25 = old_ep0_0;

#line 476
        }

#line 476
    }

#line 476
    this_12._ep0_0 = quantize_0(f16vec3(_S25), 255U);
    if(from_pair1_0)
    {

#line 477
        _S25 = old_ep3_0;

#line 477
    }
    else
    {

#line 477
        if(from_pair2_0)
        {

#line 477
            _S25 = old_ep5_0;

#line 477
        }
        else
        {

#line 477
            _S25 = old_ep1_0;

#line 477
        }

#line 477
    }

#line 477
    this_12._ep1_0 = quantize_0(f16vec3(_S25), 255U);

#line 477
    bool from_pair0_0;



    if(_S23)
    {

#line 481
        from_pair0_0 = true;

#line 481
    }
    else
    {

#line 481
        from_pair0_0 = perm_4 == uint8_t(4U);

#line 481
    }
    bool _S26 = perm_4 == uint8_t(3U);

#line 482
    if(_S26)
    {

#line 482
        from_pair2_0 = true;

#line 482
    }
    else
    {

#line 482
        from_pair2_0 = perm_4 == uint8_t(5U);

#line 482
    }
    if(from_pair0_0)
    {

#line 483
        _S25 = old_ep0_0;

#line 483
    }
    else
    {

#line 483
        if(from_pair2_0)
        {

#line 483
            _S25 = old_ep4_0;

#line 483
        }
        else
        {

#line 483
            _S25 = old_ep2_0;

#line 483
        }

#line 483
    }

#line 483
    this_12._ep2_0 = quantize_0(f16vec3(_S25), 255U);
    if(from_pair0_0)
    {

#line 484
        _S25 = old_ep1_0;

#line 484
    }
    else
    {

#line 484
        if(from_pair2_0)
        {

#line 484
            _S25 = old_ep5_0;

#line 484
        }
        else
        {

#line 484
            _S25 = old_ep3_0;

#line 484
        }

#line 484
    }

#line 484
    this_12._ep3_0 = quantize_0(f16vec3(_S25), 255U);



    if(_S24)
    {

#line 488
        from_pair0_0 = true;

#line 488
    }
    else
    {

#line 488
        from_pair0_0 = perm_4 == uint8_t(5U);

#line 488
    }
    if(_S26)
    {

#line 489
        from_pair1_0 = true;

#line 489
    }
    else
    {

#line 489
        from_pair1_0 = perm_4 == uint8_t(4U);

#line 489
    }
    if(from_pair0_0)
    {

#line 490
        _S25 = old_ep0_0;

#line 490
    }
    else
    {

#line 490
        if(from_pair1_0)
        {

#line 490
            _S25 = old_ep2_0;

#line 490
        }
        else
        {

#line 490
            _S25 = old_ep4_0;

#line 490
        }

#line 490
    }

#line 490
    this_12._ep4_0 = quantize_0(f16vec3(_S25), 255U);
    if(from_pair0_0)
    {

#line 491
        _S25 = old_ep1_0;

#line 491
    }
    else
    {

#line 491
        if(from_pair1_0)
        {

#line 491
            _S25 = old_ep3_0;

#line 491
        }
        else
        {

#line 491
            _S25 = old_ep5_0;

#line 491
        }

#line 491
    }

#line 491
    this_12._ep5_0 = quantize_0(f16vec3(_S25), 255U);
    return;
}


#line 502
void CompressedTextureBlock_snap_0(inout CompressedTextureBlock_0 this_13)
{
    uint raw_map_2 = CompressedTextureBlock_pack_partition_indices_0(this_13);
    uint8_t permutation_1 = uint8_t(0U);
    uint final_mask_0 = 0U;

#line 506
    uint closest_seed_0;

    if((this_13.max_partitions_1) == uint8_t(3U))
    {
        uint _S27 = get_closest_seed3_0(raw_map_2, permutation_1, final_mask_0);

#line 510
        closest_seed_0 = _S27;

#line 508
    }
    else
    {



        uint _S28 = get_closest_seed2_0(raw_map_2, permutation_1, final_mask_0);

#line 514
        closest_seed_0 = _S28;

#line 508
    }

#line 517
    this_13.astc_seed_0 = uint16_t(closest_seed_0);
    this_13.astc_partition_map_0 = final_mask_0;
    this_13.ideal_partition_map_0 = raw_map_2;
    this_13.perm_0 = permutation_1;


    CompressedTextureBlock_swap_colors_0(this_13, permutation_1);

#line 523
    int i_4 = 0;
    for(;;)
    {

#line 524
        if(i_4 < 16)
        {
        }
        else
        {

#line 524
            break;
        }
        this_13.partition_index_0.data_1[i_4] = int8_t(int((final_mask_0 >> (2 * i_4)) & 3U));

#line 524
        i_4 = i_4 + 1;

#line 524
    }



    return;
}


#line 271
uint hamming_distance_2b_0(uint x_15, uint y_3)
{
    uint z_0 = x_15 ^ y_3;


    return bitCount((z_0 | (z_0 >> 1)) & 1431655765U);
}


#line 306
float quantize_1(float value_1, uint range_1)
{

#line 306
    float _S29 = float(int(range_1));


    return round(value_1 * _S29) / _S29;
}


#line 374
void NonDifferentiableFP8Weights_quantize_0(inout NonDifferentiableFP8Weights_0 this_14, uint8_t range_2)
{

#line 374
    int i_5 = 0;


    [[unroll]]
    for(;;)
    {

#line 377
        if(i_5 < 16)
        {
        }
        else
        {

#line 377
            break;
        }
        this_14.data_0[i_5] = uint8_t(round(saturate_0(quantize_1(NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(this_14, i_5), uint(range_2))) * 255.0));

#line 377
        i_5 = i_5 + 1;

#line 377
    }



    return;
}


#line 383
float NonDifferentiableFP8Weights_mean_0(NonDifferentiableFP8Weights_0 this_15)
{

#line 383
    int i_6 = 0;

#line 383
    float sum_0 = 0.0;



    [[unroll]]
    for(;;)
    {

#line 387
        if(i_6 < 16)
        {
        }
        else
        {

#line 387
            break;
        }
        float sum_1 = sum_0 + NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(this_15, i_6);

#line 387
        i_6 = i_6 + 1;

#line 387
        sum_0 = sum_1;

#line 387
    }



    return sum_0 / 16.0;
}


#line 720
void CompressedTextureBlock_random_initialize_0(inout CompressedTextureBlock_0 _S30, uint _S31, inout PCG32_0 _S32)
{

#line 646
    uint _S33 = PCG32_nextUint_0(_S32);

#line 646
    _S30._ep0_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S31)].pixels_0[_S33 % 16U]), 255U);
    uint _S34 = PCG32_nextUint_0(_S32);

#line 647
    _S30._ep1_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S31)].pixels_0[_S34 % 16U]), 255U);

#line 647
    int i_7 = 0;


    [[unroll]]
    for(;;)
    {

#line 650
        if(i_7 < 16)
        {
        }
        else
        {

#line 650
            break;
        }
        float _S35 = PCG32_nextFloat_0(_S32);

#line 652
        _S30.weights_0.data_0[i_7] = uint8_t(round(saturate_0(_S35) * 255.0));

#line 650
        i_7 = i_7 + 1;

#line 650
    }

#line 650
    i_7 = 0;

#line 656
    [[unroll]]
    for(;;)
    {

#line 656
        if(i_7 < 8)
        {
        }
        else
        {

#line 656
            break;
        }
        uint _S36 = PCG32_nextUint_0(_S32);

#line 658
        _S30._ep1_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S31)].pixels_0[_S36 % 16U]), 255U);
        vec3 d_1 = CompressedTextureBlock_ep1_get_0(_S30) - CompressedTextureBlock_ep0_get_0(_S30);
        if((dot(d_1, d_1)) > 0.30000001192092896)
        {
            break;
        }

#line 656
        i_7 = i_7 + 1;

#line 656
    }

#line 666
    if((_S30.max_partitions_1) == uint8_t(1U))
    {

#line 667
        return;
    }

#line 667
    i_7 = 0;


    [[unroll]]
    for(;;)
    {

#line 670
        if(i_7 < 8)
        {
        }
        else
        {

#line 670
            break;
        }
        uint _S37 = PCG32_nextUint_0(_S32);

#line 672
        _S30._ep2_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S31)].pixels_0[_S37 % 16U]), 255U);
        if((dist_0(CompressedTextureBlock_ep2_get_0(_S30), CompressedTextureBlock_ep0_get_0(_S30), CompressedTextureBlock_ep1_get_0(_S30))) > 0.30000001192092896)
        {
            break;
        }

#line 670
        i_7 = i_7 + 1;

#line 670
    }

#line 670
    i_7 = 0;

#line 680
    [[unroll]]
    for(;;)
    {

#line 680
        if(i_7 < 8)
        {
        }
        else
        {

#line 680
            break;
        }
        uint _S38 = PCG32_nextUint_0(_S32);

#line 682
        _S30._ep3_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S31)].pixels_0[_S38 % 16U]), 255U);
        if((dist_0(CompressedTextureBlock_ep3_get_0(_S30), CompressedTextureBlock_ep0_get_0(_S30), CompressedTextureBlock_ep1_get_0(_S30))) > 0.30000001192092896)
        {
            break;
        }

#line 680
        i_7 = i_7 + 1;

#line 680
    }

#line 680
    i_7 = 0;

#line 690
    [[unroll]]
    for(;;)
    {

#line 690
        if(i_7 < 8)
        {
        }
        else
        {

#line 690
            break;
        }
        uint _S39 = PCG32_nextUint_0(_S32);

#line 692
        _S30._ep4_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S31)].pixels_0[_S39 % 16U]), 255U);
        if((dist_0(CompressedTextureBlock_ep4_get_0(_S30), CompressedTextureBlock_ep0_get_0(_S30), CompressedTextureBlock_ep1_get_0(_S30))) <= 0.30000001192092896)
        {
            i_7 = i_7 + 1;

#line 690
            continue;
        }

#line 697
        if((dist_0(CompressedTextureBlock_ep4_get_0(_S30), CompressedTextureBlock_ep2_get_0(_S30), CompressedTextureBlock_ep3_get_0(_S30))) > 0.30000001192092896)
        {
            break;
        }

#line 690
        i_7 = i_7 + 1;

#line 690
    }

#line 690
    i_7 = 0;

#line 704
    [[unroll]]
    for(;;)
    {

#line 704
        if(i_7 < 8)
        {
        }
        else
        {

#line 704
            break;
        }
        uint _S40 = PCG32_nextUint_0(_S32);

#line 706
        _S30._ep5_0 = quantize_0(f16vec3(g_groundtruth_0._data[uint(_S31)].pixels_0[_S40 % 16U]), 255U);
        if((dist_0(CompressedTextureBlock_ep5_get_0(_S30), CompressedTextureBlock_ep0_get_0(_S30), CompressedTextureBlock_ep1_get_0(_S30))) <= 0.30000001192092896)
        {
            i_7 = i_7 + 1;

#line 704
            continue;
        }

#line 711
        if((dist_0(CompressedTextureBlock_ep5_get_0(_S30), CompressedTextureBlock_ep2_get_0(_S30), CompressedTextureBlock_ep3_get_0(_S30))) > 0.30000001192092896)
        {
            break;
        }

#line 704
        i_7 = i_7 + 1;

#line 704
    }

#line 704
    i_7 = 0;

#line 718
    [[unroll]]
    for(;;)
    {

#line 718
        if(i_7 < 16)
        {
        }
        else
        {

#line 718
            break;
        }
        uint _S41 = PCG32_nextUint_0(_S32);

#line 720
        uint _S42 = _S41 % uint(_S30.max_partitions_1);

#line 720
        _S30.partition_index_0.data_1[i_7] = int8_t(int(_S42));

#line 718
        i_7 = i_7 + 1;

#line 718
    }



    return;
}


#line 722
float loss_3P_0(uint _S43, CompressedTextureBlock_0 _S44)
{

#line 1065
    TextureBlock_0 _S45 = CompressedTextureBlock_decompress3P_0(_S44);

#line 1065
    int i_8 = 0;

#line 1065
    float totalError_0 = 0.0;


    for(;;)
    {

#line 1068
        if(i_8 < 16)
        {
        }
        else
        {

#line 1068
            break;
        }
        vec3 diff_0 = _S45.pixels_0[i_8] - g_groundtruth_0._data[uint(_S43)].pixels_0[i_8];
        float totalError_1 = totalError_0 + dot(diff_0, diff_0);

#line 1068
        i_8 = i_8 + 1;

#line 1068
        totalError_0 = totalError_1;

#line 1068
    }

#line 1074
    return totalError_0;
}


#line 2675 4
vec3 sample_color_0(vec3 _S46, uint _S47)
{

#line 2675
    float max_dist_0 = 0.0;

#line 2675
    int max_idx_0 = 0;

#line 2675
    int i_9 = 0;

#line 933 0
    [[unroll]]
    for(;;)
    {

#line 933
        if(i_9 < 16)
        {
        }
        else
        {

#line 933
            break;
        }
        float dist_1 = length(g_groundtruth_0._data[uint(_S47)].pixels_0[i_9] - _S46);
        if(dist_1 > max_dist_0)
        {

#line 936
            max_dist_0 = dist_1;

#line 936
            max_idx_0 = i_9;

#line 936
        }

#line 933
        i_9 = i_9 + 1;

#line 933
    }

#line 942
    return g_groundtruth_0._data[uint(_S47)].pixels_0[max_idx_0];
}


#line 942
bool solve_pca_eps_0(CompressedTextureBlock_0 _S48, inout vec3 _S49, inout vec3 _S50, uint _S51, int _S52, float _S53)
{

#line 951
    vec3 _S54 = vec3(ivec3(0));

#line 951
    int i_10 = 0;

#line 951
    vec3 centroid_0 = _S54;

#line 951
    uint count_0 = 0U;



    [[unroll]]
    for(;;)
    {

#line 955
        if(i_10 < 16)
        {
        }
        else
        {

#line 955
            break;
        }
        if((NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S48.partition_index_0, i_10)) == _S52)
        {

            uint count_1 = count_0 + 1U;

#line 960
            centroid_0 = centroid_0 + g_groundtruth_0._data[uint(_S51)].pixels_0[i_10];

#line 960
            count_0 = count_1;

#line 957
        }

#line 955
        i_10 = i_10 + 1;

#line 955
    }

#line 963
    float _S55 = float(count_0);

#line 963
    vec3 centroid_1 = centroid_0 / _S55;

    if(count_0 == 0U)
    {

#line 966
        return true;
    }
    if(count_0 == 1U)
    {


        bound_and_damp_0(centroid_1, sample_color_0(centroid_1, _S51), _S49, _S50, _S53);
        return true;
    }

    mat3x3 C_0 = mat3x3(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

#line 976
    i_10 = 0;

    [[unroll]]
    for(;;)
    {

#line 978
        if(i_10 < 16)
        {
        }
        else
        {

#line 978
            break;
        }
        if((NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S48.partition_index_0, i_10)) == _S52)
        {
            vec3 d_2 = g_groundtruth_0._data[uint(_S51)].pixels_0[i_10] - centroid_1;
            C_0[0] = C_0[0] + d_2.x * d_2;
            C_0[1] = C_0[1] + d_2.y * d_2;
            C_0[2] = C_0[2] + d_2.z * d_2;

#line 980
        }

#line 978
        i_10 = i_10 + 1;

#line 978
    }

#line 988
    C_0 = C_0 / _S55;



    if((C_0[0].x + C_0[1].y + C_0[2].z) < 0.00030000001424924)
    {

#line 998
        bound_and_damp_0(centroid_1, sample_color_0(centroid_1, _S51), _S49, _S50, _S53);
        return false;
    }

    const vec3 _S56 = vec3(0.17000000178813934, 0.82999998331069946, 0.37999999523162842);

#line 1002
    int iter_0 = 0;

#line 1002
    vec3 axis_0 = _S56;

    [[unroll]]
    for(;;)
    {

#line 1004
        if(iter_0 < 4)
        {
        }
        else
        {

#line 1004
            break;
        }
        vec3 axis_1 = (((axis_0) * (C_0)));
        float lenSq_0 = dot(axis_1, axis_1);
        if(lenSq_0 > 9.99999993922529029e-09)
        {

#line 1008
            axis_0 = axis_1 * (inversesqrt((lenSq_0)));

#line 1008
        }
        else
        {

#line 1008
            axis_0 = axis_1;

#line 1008
        }

#line 1004
        iter_0 = iter_0 + 1;

#line 1004
    }

#line 1015
    if((dot(axis_0, axis_0)) < 9.99999993922529029e-09)
    {


        bound_and_damp_0(centroid_1, sample_color_0(centroid_1, _S51), _S49, _S50, _S53);
        return false;
    }

    vec3 axis_2 = normalize(axis_0);

#line 1023
    float min_t_0 = 1000.0;

#line 1023
    float max_t_0 = -1000.0;

#line 1023
    i_10 = 0;

#line 1028
    [[unroll]]
    for(;;)
    {

#line 1028
        if(i_10 < 16)
        {
        }
        else
        {

#line 1028
            break;
        }
        if((NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S48.partition_index_0, i_10)) == _S52)
        {

            float t_0 = dot(g_groundtruth_0._data[uint(_S51)].pixels_0[i_10] - centroid_1, axis_2);

            float _S57 = max(max_t_0, t_0);

#line 1035
            min_t_0 = min(min_t_0, t_0);

#line 1035
            max_t_0 = _S57;

#line 1030
        }

#line 1028
        i_10 = i_10 + 1;

#line 1028
    }

#line 1041
    bound_and_damp_0(centroid_1 + axis_2 * min_t_0, centroid_1 + axis_2 * max_t_0, _S49, _S50, _S53);
    return true;
}


#line 1042
void solve_aabb_eps_0(CompressedTextureBlock_0 _S58, inout vec3 _S59, inout vec3 _S60, uint _S61, int _S62)
{



    vec3 _S63 = vec3(ivec3(1));

#line 1047
    vec3 _S64 = vec3(ivec3(0));

#line 1047
    vec3 min_ep_0 = _S63;

#line 1047
    vec3 max_ep_0 = _S64;

#line 1047
    int i_11 = 0;

    [[unroll]]
    for(;;)
    {

#line 1049
        if(i_11 < 16)
        {
        }
        else
        {

#line 1049
            break;
        }
        bool inlier_0 = (NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S58.partition_index_0, i_11)) == _S62;

#line 1051
        vec3 _S65;
        if(inlier_0)
        {

#line 1052
            _S65 = g_groundtruth_0._data[uint(_S61)].pixels_0[i_11];

#line 1052
        }
        else
        {

#line 1052
            _S65 = _S63;

#line 1052
        }

#line 1052
        vec3 _S66 = min(_S65, min_ep_0);

#line 1052
        vec3 _S67;
        if(inlier_0)
        {

#line 1053
            _S67 = g_groundtruth_0._data[uint(_S61)].pixels_0[i_11];

#line 1053
        }
        else
        {

#line 1053
            _S67 = _S64;

#line 1053
        }

#line 1053
        vec3 _S68 = max(_S67, max_ep_0);

#line 1049
        int _S69 = i_11 + 1;

#line 1049
        min_ep_0 = _S66;

#line 1049
        max_ep_0 = _S68;

#line 1049
        i_11 = _S69;

#line 1049
    }

#line 1056
    _S59 = saturate_1(min_ep_0);
    _S60 = saturate_1(max_ep_0);
    return;
}


#line 1058
struct DiffPair_CompressedTextureBlock_0
{
    CompressedTextureBlock_0 primal_0;
    CompressedTextureBlock_Differential_0 differential_0;
};


#line 1126
vec3 s_primal_ctx_CompressedTextureBlock_ep0_get_0(CompressedTextureBlock_0 dpthis_0)
{

#line 434
    return vec3(dpthis_0._ep0_0);
}


#line 434
vec3 s_primal_ctx_CompressedTextureBlock_ep1_get_0(CompressedTextureBlock_0 dpthis_1)
{

#line 434
    return vec3(dpthis_1._ep1_0);
}


#line 434
vec3 s_primal_ctx_CompressedTextureBlock_ep2_get_0(CompressedTextureBlock_0 dpthis_2)
{

#line 434
    return vec3(dpthis_2._ep2_0);
}


#line 434
vec3 s_primal_ctx_CompressedTextureBlock_ep4_get_0(CompressedTextureBlock_0 dpthis_3)
{

#line 434
    return vec3(dpthis_3._ep4_0);
}


#line 434
vec3 s_primal_ctx_CompressedTextureBlock_ep3_get_0(CompressedTextureBlock_0 dpthis_4)
{

#line 434
    return vec3(dpthis_4._ep3_0);
}


#line 434
vec3 s_primal_ctx_CompressedTextureBlock_ep5_get_0(CompressedTextureBlock_0 dpthis_5)
{

#line 434
    return vec3(dpthis_5._ep5_0);
}


#line 434
vec3 s_primal_ctx_lerp_0(vec3 _S70, vec3 _S71, vec3 _S72)
{

#line 434
    return mix(_S70, _S71, _S72);
}


#line 434
TextureBlock_0 s_primal_ctx_CompressedTextureBlock_decompress3P_0(CompressedTextureBlock_0 dpthis_6)
{

#line 628
    vec3 _S73 = vec3(0.0);

#line 628
    vec3  _S74[16] = { _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73, _S73 };

#line 633
    int _S75 = int(dpthis_6.max_partitions_1 - uint8_t(1U));

#line 633
    vec3 _S76 = s_primal_ctx_CompressedTextureBlock_ep0_get_0(dpthis_6);

#line 633
    vec3 _S77 = s_primal_ctx_CompressedTextureBlock_ep1_get_0(dpthis_6);

#line 633
    vec3 _S78 = s_primal_ctx_CompressedTextureBlock_ep2_get_0(dpthis_6);

#line 633
    vec3 _S79 = s_primal_ctx_CompressedTextureBlock_ep4_get_0(dpthis_6);

#line 633
    vec3 _S80 = s_primal_ctx_CompressedTextureBlock_ep3_get_0(dpthis_6);

#line 633
    vec3 _S81 = s_primal_ctx_CompressedTextureBlock_ep5_get_0(dpthis_6);

#line 633
    bool _runFlag_0 = true;

#line 633
    uint i_12 = 0U;

#line 633
    TextureBlock_0 outputBlock_1;

#line 633
    outputBlock_1.pixels_0 = _S74;

#line 633
    int _pc_0 = 0;

#line 630
    for(;;)
    {

#line 630
        if(_runFlag_0)
        {
        }
        else
        {

#line 630
            break;
        }

#line 630
        int _S82;

#line 630
        if(i_12 < 16U)
        {
            int _S83 = int(i_12);

#line 632
            float _S84 = NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(dpthis_6.weights_0, _S83);
            int partition_1 = clamp(int(float(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(dpthis_6.partition_index_0, _S83))), 0, _S75);
            bool _S85 = partition_1 == 0;

#line 634
            vec3 e0_1;

#line 634
            if(_S85)
            {

#line 634
                e0_1 = _S76;

#line 634
            }
            else
            {

#line 634
                if(partition_1 == 1)
                {

#line 634
                    e0_1 = _S78;

#line 634
                }
                else
                {

#line 634
                    e0_1 = _S79;

#line 634
                }

#line 634
            }

#line 634
            vec3 e1_1;
            if(_S85)
            {

#line 635
                e1_1 = _S77;

#line 635
            }
            else
            {

#line 635
                if(partition_1 == 1)
                {

#line 635
                    e1_1 = _S80;

#line 635
                }
                else
                {

#line 635
                    e1_1 = _S81;

#line 635
                }

#line 635
            }

#line 635
            vec3 _S86 = s_primal_ctx_lerp_0(e0_1, e1_1, vec3(_S84));

#line 635
            TextureBlock_0 _S87 = outputBlock_1;

#line 635
            _S87.pixels_0[i_12] = _S86;

#line 635
            _S82 = 1;

#line 635
            outputBlock_1 = _S87;

#line 635
        }
        else
        {

#line 635
            _S82 = 0;

#line 635
        }

#line 635
        if(_S82 != 1)
        {

#line 635
            _runFlag_0 = false;

#line 635
        }

#line 635
        if(_runFlag_0)
        {

#line 635
            i_12 = i_12 + 1U;

#line 635
        }

#line 635
        _pc_0 = _pc_0 + 1;

#line 630
    }

#line 630
    return outputBlock_1;
}


#line 630
TextureBlock_0 TextureBlock_x24_syn_dzero_0()
{

#line 630
    TextureBlock_0 result_5;

#line 2239 4
    vec3 _S88 = vec3(0.0);

#line 2239
    result_5.pixels_0[0] = _S88;

#line 2239
    result_5.pixels_0[1] = _S88;

#line 2239
    result_5.pixels_0[2] = _S88;

#line 2239
    result_5.pixels_0[3] = _S88;

#line 2239
    result_5.pixels_0[4] = _S88;

#line 2239
    result_5.pixels_0[5] = _S88;

#line 2239
    result_5.pixels_0[6] = _S88;

#line 2239
    result_5.pixels_0[7] = _S88;

#line 2239
    result_5.pixels_0[8] = _S88;

#line 2239
    result_5.pixels_0[9] = _S88;

#line 2239
    result_5.pixels_0[10] = _S88;

#line 2239
    result_5.pixels_0[11] = _S88;

#line 2239
    result_5.pixels_0[12] = _S88;

#line 2239
    result_5.pixels_0[13] = _S88;

#line 2239
    result_5.pixels_0[14] = _S88;

#line 2239
    result_5.pixels_0[15] = _S88;

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


#line 434 0
void s_bwd_prop_CompressedTextureBlock_ep5_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_7, vec3 _s_dOut_0)
{

#line 449
    f16vec3 _S89 = f16vec3(_s_dOut_0);

#line 449
    CompressedTextureBlock_Differential_0 _S90 = CompressedTextureBlock_x24_syn_dzero_0();

#line 449
    _S90._ep5_1 = _S89;

#line 449
    dpthis_7.primal_0 = dpthis_7.primal_0;

#line 449
    dpthis_7.differential_0 = _S90;

#line 434
    return;
}


#line 434
void s_bwd_prop_CompressedTextureBlock_ep3_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_8, vec3 _s_dOut_1)
{

#line 447
    f16vec3 _S91 = f16vec3(_s_dOut_1);

#line 447
    CompressedTextureBlock_Differential_0 _S92 = CompressedTextureBlock_x24_syn_dzero_0();

#line 447
    _S92._ep3_1 = _S91;

#line 447
    dpthis_8.primal_0 = dpthis_8.primal_0;

#line 447
    dpthis_8.differential_0 = _S92;

#line 434
    return;
}


#line 434
void s_bwd_prop_CompressedTextureBlock_ep4_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_9, vec3 _s_dOut_2)
{

#line 448
    f16vec3 _S93 = f16vec3(_s_dOut_2);

#line 448
    CompressedTextureBlock_Differential_0 _S94 = CompressedTextureBlock_x24_syn_dzero_0();

#line 448
    _S94._ep4_1 = _S93;

#line 448
    dpthis_9.primal_0 = dpthis_9.primal_0;

#line 448
    dpthis_9.differential_0 = _S94;

#line 434
    return;
}


#line 434
void s_bwd_prop_CompressedTextureBlock_ep2_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_10, vec3 _s_dOut_3)
{

#line 446
    f16vec3 _S95 = f16vec3(_s_dOut_3);

#line 446
    CompressedTextureBlock_Differential_0 _S96 = CompressedTextureBlock_x24_syn_dzero_0();

#line 446
    _S96._ep2_1 = _S95;

#line 446
    dpthis_10.primal_0 = dpthis_10.primal_0;

#line 446
    dpthis_10.differential_0 = _S96;

#line 434
    return;
}


#line 434
void s_bwd_prop_CompressedTextureBlock_ep1_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_11, vec3 _s_dOut_4)
{

#line 445
    f16vec3 _S97 = f16vec3(_s_dOut_4);

#line 445
    CompressedTextureBlock_Differential_0 _S98 = CompressedTextureBlock_x24_syn_dzero_0();

#line 445
    _S98._ep1_1 = _S97;

#line 445
    dpthis_11.primal_0 = dpthis_11.primal_0;

#line 445
    dpthis_11.differential_0 = _S98;

#line 434
    return;
}


#line 434
void s_bwd_prop_CompressedTextureBlock_ep0_get_0(inout DiffPair_CompressedTextureBlock_0 dpthis_12, vec3 _s_dOut_5)
{

#line 444
    f16vec3 _S99 = f16vec3(_s_dOut_5);

#line 444
    CompressedTextureBlock_Differential_0 _S100 = CompressedTextureBlock_x24_syn_dzero_0();

#line 444
    _S100._ep0_1 = _S99;

#line 444
    dpthis_12.primal_0 = dpthis_12.primal_0;

#line 444
    dpthis_12.differential_0 = _S100;

#line 434
    return;
}


#line 434
void s_bwd_prop_lerp_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S101, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S102, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S103, vec3 _S104)
{

#line 434
    _d_lerp_vector_0(_S101, _S102, _S103, _S104);

#line 434
    return;
}


#line 626
void s_bwd_prop_CompressedTextureBlock_decompress3P_0(inout DiffPair_CompressedTextureBlock_0 dpthis_13, TextureBlock_0 _s_dOut_6)
{

#line 626
    CompressedTextureBlock_0 _S105 = dpthis_13.primal_0;

#line 626
    CompressedTextureBlock_0 _S106 = dpthis_13.primal_0;

#line 626
    CompressedTextureBlock_0 _S107 = dpthis_13.primal_0;

#line 633
    int _S108 = int(dpthis_13.primal_0.max_partitions_1 - uint8_t(1U));

#line 633
    vec3 _S109 = s_primal_ctx_CompressedTextureBlock_ep0_get_0(dpthis_13.primal_0);

#line 633
    vec3 _S110 = s_primal_ctx_CompressedTextureBlock_ep1_get_0(dpthis_13.primal_0);

#line 633
    vec3 _S111 = s_primal_ctx_CompressedTextureBlock_ep2_get_0(dpthis_13.primal_0);

#line 633
    vec3 _S112 = s_primal_ctx_CompressedTextureBlock_ep4_get_0(dpthis_13.primal_0);

#line 633
    vec3 _S113 = s_primal_ctx_CompressedTextureBlock_ep3_get_0(dpthis_13.primal_0);

#line 633
    vec3 _S114 = s_primal_ctx_CompressedTextureBlock_ep5_get_0(dpthis_13.primal_0);
    vec3 _S115 = vec3(0.0);

#line 628
    TextureBlock_0 _S116 = TextureBlock_x24_syn_dzero_0();

#line 628
    TextureBlock_0 _S117 = TextureBlock_x24_syn_dadd_0(_s_dOut_6, _S116);

#line 628
    int _dc_0 = 16;

#line 628
    TextureBlock_0 _S118 = _S117;

#line 628
    vec3 _S119 = _S115;

#line 628
    vec3 _S120 = _S115;

#line 628
    vec3 _S121 = _S115;

#line 628
    vec3 _S122 = _S115;

#line 628
    vec3 _S123 = _S115;

#line 628
    vec3 _S124 = _S115;

#line 628
    vec3 _S125 = _S115;

    for(;;)
    {

#line 630
        uint _S126 = uint(_dc_0);

#line 630
        if(_dc_0 >= 0)
        {
        }
        else
        {

#line 630
            break;
        }

#line 630
        bool _S127 = _S126 < 16U;

#line 630
        vec3 e0_2;

#line 630
        vec3 e1_2;

#line 630
        vec3 _S128;

#line 630
        bool _S129;

#line 630
        bool _S130;

#line 630
        bool _S131;

#line 630
        if(_S127)
        {
            int _S132 = int(_S126);

#line 632
            float _S133 = NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(_S106.weights_0, _S132);
            int partition_2 = clamp(int(float(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S107.partition_index_0, _S132))), 0, _S108);
            bool _S134 = partition_2 == 0;

#line 634
            if(_S134)
            {

#line 634
                e0_2 = _S109;

#line 634
                _S129 = false;

#line 634
            }
            else
            {

#line 634
                bool _S135 = partition_2 == 1;

#line 634
                if(_S135)
                {

#line 634
                    e0_2 = _S111;

#line 634
                }
                else
                {

#line 634
                    e0_2 = _S112;

#line 634
                }

#line 634
                _S129 = _S135;

#line 634
            }
            if(_S134)
            {

#line 635
                e1_2 = _S110;

#line 635
                _S130 = false;

#line 635
            }
            else
            {

#line 635
                bool _S136 = partition_2 == 1;

#line 635
                if(_S136)
                {

#line 635
                    e1_2 = _S113;

#line 635
                }
                else
                {

#line 635
                    e1_2 = _S114;

#line 635
                }

#line 635
                _S130 = _S136;

#line 635
            }

#line 634
            bool _S137 = _S129;

#line 634
            _S128 = vec3(_S133);

#line 634
            _S129 = _S134;

#line 634
            _S131 = _S137;

#line 634
        }
        else
        {

#line 634
            e0_2 = _S115;

#line 634
            e1_2 = _S115;

#line 634
            _S128 = _S115;

#line 634
            _S129 = false;

#line 634
            _S130 = false;

#line 634
            _S131 = false;

#line 634
        }

#line 628
        TextureBlock_0 _S138 = TextureBlock_x24_syn_dadd_0(_S118, _S116);

#line 628
        if(_S127)
        {

#line 628
            TextureBlock_0 _S139 = _S138;

#line 628
            _S139.pixels_0[_S126] = _S115;

#line 636
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S140;

#line 636
            _S140.primal_0 = e0_2;

#line 636
            _S140.differential_0 = _S115;

#line 636
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S141;

#line 636
            _S141.primal_0 = e1_2;

#line 636
            _S141.differential_0 = _S115;

#line 636
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S142;

#line 636
            _S142.primal_0 = _S128;

#line 636
            _S142.differential_0 = _S115;

#line 636
            s_bwd_prop_lerp_0(_S140, _S141, _S142, _S138.pixels_0[_S126]);

#line 636
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S143 = _S141;

#line 628
            TextureBlock_0 _S144 = TextureBlock_x24_syn_dadd_0(_S139, _S116);

#line 634
            vec3 _S145 = _S140.differential_0 + _S125;

#line 634
            vec3 _S146;

#line 634
            vec3 _S147;

#line 634
            vec3 _S148;

#line 634
            if(_S129)
            {

#line 635
                vec3 _S149 = _S143.differential_0 + _S123;

#line 635
                _S146 = _S119;

#line 635
                _S147 = _S120;

#line 635
                _S148 = _S149;

#line 635
            }
            else
            {

#line 635
                if(_S130)
                {

#line 635
                    vec3 _S150 = _S143.differential_0 + _S120;

#line 635
                    _S146 = _S119;

#line 635
                    _S147 = _S150;

#line 635
                }
                else
                {

#line 635
                    _S146 = _S143.differential_0 + _S119;

#line 635
                    _S147 = _S120;

#line 635
                }

#line 635
                _S148 = _S123;

#line 635
            }

#line 635
            vec3 _S151;

#line 635
            vec3 _S152;

#line 635
            vec3 _S153;

#line 635
            if(_S129)
            {

#line 634
                vec3 _S154 = _S145 + _S124;

#line 634
                _S151 = _S121;

#line 634
                _S152 = _S122;

#line 634
                _S153 = _S154;

#line 634
            }
            else
            {

#line 634
                if(_S131)
                {

#line 634
                    vec3 _S155 = _S145 + _S122;

#line 634
                    _S151 = _S121;

#line 634
                    _S152 = _S155;

#line 634
                }
                else
                {

#line 634
                    _S151 = _S145 + _S121;

#line 634
                    _S152 = _S122;

#line 634
                }

#line 634
                _S153 = _S124;

#line 634
            }

#line 634
            _S118 = _S144;

#line 634
            _S119 = _S146;

#line 634
            _S120 = _S147;

#line 634
            _S121 = _S151;

#line 634
            _S122 = _S152;

#line 634
            _S123 = _S148;

#line 634
            _S124 = _S153;

#line 634
            _S125 = _S115;

#line 634
        }
        else
        {

#line 634
            _S118 = TextureBlock_x24_syn_dadd_0(_S138, _S116);

#line 634
        }

#line 634
        _dc_0 = _dc_0 - 1;

#line 630
    }

#line 635
    CompressedTextureBlock_Differential_0 _S156 = CompressedTextureBlock_x24_syn_dzero_0();

#line 635
    DiffPair_CompressedTextureBlock_0 _S157;

#line 635
    _S157.primal_0 = _S105;

#line 635
    _S157.differential_0 = _S156;

#line 635
    s_bwd_prop_CompressedTextureBlock_ep5_get_0(_S157, _S119);

#line 635
    DiffPair_CompressedTextureBlock_0 _S158;

#line 635
    _S158.primal_0 = _S105;

#line 635
    _S158.differential_0 = _S156;

#line 635
    s_bwd_prop_CompressedTextureBlock_ep3_get_0(_S158, _S120);

#line 634
    DiffPair_CompressedTextureBlock_0 _S159;

#line 634
    _S159.primal_0 = _S105;

#line 634
    _S159.differential_0 = _S156;

#line 634
    s_bwd_prop_CompressedTextureBlock_ep4_get_0(_S159, _S121);

#line 634
    DiffPair_CompressedTextureBlock_0 _S160;

#line 634
    _S160.primal_0 = _S105;

#line 634
    _S160.differential_0 = _S156;

#line 634
    s_bwd_prop_CompressedTextureBlock_ep2_get_0(_S160, _S122);
    DiffPair_CompressedTextureBlock_0 _S161;

#line 635
    _S161.primal_0 = _S105;

#line 635
    _S161.differential_0 = _S156;

#line 635
    s_bwd_prop_CompressedTextureBlock_ep1_get_0(_S161, _S123);

#line 634
    DiffPair_CompressedTextureBlock_0 _S162;

#line 634
    _S162.primal_0 = _S105;

#line 634
    _S162.differential_0 = _S156;

#line 634
    s_bwd_prop_CompressedTextureBlock_ep0_get_0(_S162, _S124);

#line 634
    CompressedTextureBlock_Differential_0 _S163 = CompressedTextureBlock_x24_syn_dadd_0(CompressedTextureBlock_x24_syn_dadd_0(CompressedTextureBlock_x24_syn_dadd_0(CompressedTextureBlock_x24_syn_dadd_0(CompressedTextureBlock_x24_syn_dadd_0(_S157.differential_0, _S158.differential_0), _S159.differential_0), _S160.differential_0), _S161.differential_0), _S162.differential_0);

#line 634
    dpthis_13.primal_0 = dpthis_13.primal_0;

#line 634
    dpthis_13.differential_0 = _S163;

#line 626
    return;
}


#line 626
void s_bwd_prop_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S164, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S165, float _S166)
{

#line 626
    _d_dot_0(_S164, _S165, _S166);

#line 626
    return;
}


#line 626
void s_bwd_prop_loss_3P_0(uint _S167, inout DiffPair_CompressedTextureBlock_0 _S168, float _S169)
{

#line 626
    CompressedTextureBlock_0 _S170 = _S168.primal_0;

#line 626
    TextureBlock_0 _S171 = s_primal_ctx_CompressedTextureBlock_decompress3P_0(_S168.primal_0);

#line 2239 4
    vec3 _S172 = vec3(0.0);

#line 2239
    int _dc_1 = 16;

#line 2239
    float _S173 = _S169;

#line 2239
    vec3  _S174[16];

#line 2239
    _S174[0] = _S172;

#line 2239
    _S174[1] = _S172;

#line 2239
    _S174[2] = _S172;

#line 2239
    _S174[3] = _S172;

#line 2239
    _S174[4] = _S172;

#line 2239
    _S174[5] = _S172;

#line 2239
    _S174[6] = _S172;

#line 2239
    _S174[7] = _S172;

#line 2239
    _S174[8] = _S172;

#line 2239
    _S174[9] = _S172;

#line 2239
    _S174[10] = _S172;

#line 2239
    _S174[11] = _S172;

#line 2239
    _S174[12] = _S172;

#line 2239
    _S174[13] = _S172;

#line 2239
    _S174[14] = _S172;

#line 2239
    _S174[15] = _S172;

#line 1068 0
    for(;;)
    {

#line 1068
        if(_dc_1 >= 0)
        {
        }
        else
        {

#line 1068
            break;
        }

#line 1068
        bool _S175 = _dc_1 < 16;

#line 1068
        int _S176;

#line 1068
        vec3 _S177;

#line 1068
        if(_S175)
        {
            vec3 diff_1 = _S171.pixels_0[_dc_1] - g_groundtruth_0._data[uint(_S167)].pixels_0[_dc_1];

#line 1070
            _S176 = 1;

#line 1070
            _S177 = diff_1;

#line 1070
        }
        else
        {

#line 1070
            _S176 = 0;

#line 1070
            _S177 = _S172;

#line 1070
        }

#line 1070
        float _S178;

#line 1070
        float _S179;

#line 1070
        if(!(_S176 != 1))
        {

#line 1070
            _S178 = _S173;

#line 1070
            _S179 = 0.0;

#line 1070
        }
        else
        {

#line 1070
            _S178 = 0.0;

#line 1070
            _S179 = _S173;

#line 1070
        }

#line 1070
        if(_S175)
        {

#line 1071
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S180;

#line 1071
            _S180.primal_0 = _S177;

#line 1071
            _S180.differential_0 = _S172;

#line 1071
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S181;

#line 1071
            _S181.primal_0 = _S177;

#line 1071
            _S181.differential_0 = _S172;

#line 1071
            s_bwd_prop_dot_0(_S180, _S181, _S178);

#line 1070
            vec3 _S182 = _S181.differential_0 + _S180.differential_0;

#line 1066
            float _S183 = _S178 + _S179;

#line 1066
            vec3  _S184[16];

#line 1066
            _S184[0] = _S172;

#line 1066
            _S184[1] = _S172;

#line 1066
            _S184[2] = _S172;

#line 1066
            _S184[3] = _S172;

#line 1066
            _S184[4] = _S172;

#line 1066
            _S184[5] = _S172;

#line 1066
            _S184[6] = _S172;

#line 1066
            _S184[7] = _S172;

#line 1066
            _S184[8] = _S172;

#line 1066
            _S184[9] = _S172;

#line 1066
            _S184[10] = _S172;

#line 1066
            _S184[11] = _S172;

#line 1066
            _S184[12] = _S172;

#line 1066
            _S184[13] = _S172;

#line 1066
            _S184[14] = _S172;

#line 1066
            _S184[15] = _S172;

#line 1066
            _S184[_dc_1] = _S182;

#line 2246 4
            vec3 _S185 = _S174[0] + _S184[0];

#line 2246
            vec3 _S186 = _S174[1] + _S184[1];

#line 2246
            vec3 _S187 = _S174[2] + _S184[2];

#line 2246
            vec3 _S188 = _S174[3] + _S184[3];

#line 2246
            vec3 _S189 = _S174[4] + _S184[4];

#line 2246
            vec3 _S190 = _S174[5] + _S184[5];

#line 2246
            vec3 _S191 = _S174[6] + _S184[6];

#line 2246
            vec3 _S192 = _S174[7] + _S184[7];

#line 2246
            vec3 _S193 = _S174[8] + _S184[8];

#line 2246
            vec3 _S194 = _S174[9] + _S184[9];

#line 2246
            vec3 _S195 = _S174[10] + _S184[10];

#line 2246
            vec3 _S196 = _S174[11] + _S184[11];

#line 2246
            vec3 _S197 = _S174[12] + _S184[12];

#line 2246
            vec3 _S198 = _S174[13] + _S184[13];

#line 2246
            vec3 _S199 = _S174[14] + _S184[14];

#line 2246
            vec3 _S200 = _S174[15] + _S184[15];

#line 2246
            _S173 = _S183;

#line 2246
            _S174[0] = _S185;

#line 2246
            _S174[1] = _S186;

#line 2246
            _S174[2] = _S187;

#line 2246
            _S174[3] = _S188;

#line 2246
            _S174[4] = _S189;

#line 2246
            _S174[5] = _S190;

#line 2246
            _S174[6] = _S191;

#line 2246
            _S174[7] = _S192;

#line 2246
            _S174[8] = _S193;

#line 2246
            _S174[9] = _S194;

#line 2246
            _S174[10] = _S195;

#line 2246
            _S174[11] = _S196;

#line 2246
            _S174[12] = _S197;

#line 2246
            _S174[13] = _S198;

#line 2246
            _S174[14] = _S199;

#line 2246
            _S174[15] = _S200;

#line 2246
        }
        else
        {

#line 2246
            _S173 = _S179;

#line 2246
        }

#line 2246
        _dc_1 = _dc_1 - 1;

#line 1068 0
    }

#line 1065
    TextureBlock_0 _S201 = TextureBlock_x24_syn_dzero_0();

#line 1065
    _S201.pixels_0 = _S174;

#line 1065
    CompressedTextureBlock_Differential_0 _S202 = CompressedTextureBlock_x24_syn_dzero_0();

#line 1065
    DiffPair_CompressedTextureBlock_0 _S203;

#line 1065
    _S203.primal_0 = _S170;

#line 1065
    _S203.differential_0 = _S202;

#line 1065
    s_bwd_prop_CompressedTextureBlock_decompress3P_0(_S203, _S201);

#line 1065
    _S168.primal_0 = _S168.primal_0;

#line 1065
    _S168.differential_0 = _S203.differential_0;

#line 1061
    return;
}


#line 1061
void s_bwd_loss_3P_0(uint _S204, inout DiffPair_CompressedTextureBlock_0 _S205, float _S206)
{

#line 1061
    s_bwd_prop_loss_3P_0(_S204, _S205, _S206);

#line 1061
    return;
}


#line 1061
void CompressedTextureBlock_solve_weights_0(inout CompressedTextureBlock_0 _S207, uint _S208)
{

#line 551
    vec3 L1_0 = CompressedTextureBlock_ep1_get_0(_S207) - CompressedTextureBlock_ep0_get_0(_S207);
    vec3 L2_0 = CompressedTextureBlock_ep3_get_0(_S207) - CompressedTextureBlock_ep2_get_0(_S207);
    vec3 L3_0 = CompressedTextureBlock_ep5_get_0(_S207) - CompressedTextureBlock_ep4_get_0(_S207);
    float _S209 = 1.0 / (dot(L1_0, L1_0) + 9.99999997475242708e-07);
    float _S210 = 1.0 / (dot(L2_0, L2_0) + 9.99999997475242708e-07);
    float _S211 = 1.0 / (dot(L3_0, L3_0) + 9.99999997475242708e-07);

#line 556
    int i_13 = 0;

    [[unroll]]
    for(;;)
    {

#line 558
        if(i_13 < 16)
        {
        }
        else
        {

#line 558
            break;
        }

#line 558
        vec3 C_1 = g_groundtruth_0._data[uint(_S208)].pixels_0[i_13];


        int p_0 = NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S207.partition_index_0, i_13);
        bool _S212 = p_0 == 0;

#line 562
        float pDotL_1;

#line 562
        if(_S212)
        {

#line 562
            pDotL_1 = dot(C_1 - CompressedTextureBlock_ep0_get_0(_S207), L1_0);

#line 562
        }
        else
        {

#line 562
            if(p_0 == 1)
            {

#line 562
                pDotL_1 = dot(C_1 - CompressedTextureBlock_ep2_get_0(_S207), L2_0);

#line 562
            }
            else
            {

#line 562
                pDotL_1 = dot(C_1 - CompressedTextureBlock_ep4_get_0(_S207), L3_0);

#line 562
            }

#line 562
        }

#line 562
        float invLenSq_1;
        if(_S212)
        {

#line 563
            invLenSq_1 = _S209;

#line 563
        }
        else
        {

#line 563
            if(p_0 == 1)
            {

#line 563
                invLenSq_1 = _S210;

#line 563
            }
            else
            {

#line 563
                invLenSq_1 = _S211;

#line 563
            }

#line 563
        }

        _S207.weights_0.data_0[i_13] = uint8_t(round(saturate_0(saturate_0(pDotL_1 * invLenSq_1)) * 255.0));

#line 558
        i_13 = i_13 + 1;

#line 558
    }

#line 567
    return;
}


#line 567
uint CompressedTextureBlock_solve_partition_0(inout CompressedTextureBlock_0 _S213, uint _S214)
{



    vec3 L1_1 = CompressedTextureBlock_ep1_get_0(_S213) - CompressedTextureBlock_ep0_get_0(_S213);
    vec3 L2_1 = CompressedTextureBlock_ep3_get_0(_S213) - CompressedTextureBlock_ep2_get_0(_S213);
    vec3 L3_1 = CompressedTextureBlock_ep5_get_0(_S213) - CompressedTextureBlock_ep4_get_0(_S213);
    float _S215 = 1.0 / (dot(L1_1, L1_1) + 9.99999997475242708e-07);
    float _S216 = 1.0 / (dot(L2_1, L2_1) + 9.99999997475242708e-07);
    float _S217 = 1.0 / (dot(L3_1, L3_1) + 9.99999997475242708e-07);

#line 577
    int i_14 = 0;

#line 577
    uint partitions_0 = 0U;

    for(;;)
    {

#line 579
        if(i_14 < 16)
        {
        }
        else
        {

#line 579
            break;
        }

        vec3 P1_0 = g_groundtruth_0._data[uint(_S214)].pixels_0[i_14] - CompressedTextureBlock_ep0_get_0(_S213);
        vec3 P2_0 = g_groundtruth_0._data[uint(_S214)].pixels_0[i_14] - CompressedTextureBlock_ep2_get_0(_S213);
        vec3 P3_0 = g_groundtruth_0._data[uint(_S214)].pixels_0[i_14] - CompressedTextureBlock_ep4_get_0(_S213);
        float pDotL1_0 = dot(P1_0, L1_1);
        float pDotL2_0 = dot(P2_0, L2_1);
        float pDotL3_0 = dot(P3_0, L3_1);
        float d1_1 = CompressedTextureBlock_distSq_0(P1_0, L1_1, pDotL1_0, _S215);
        float d2_1 = CompressedTextureBlock_distSq_0(P2_0, L2_1, pDotL2_0, _S216);

#line 589
        float d3_1;
        if((_S213.max_partitions_1) == uint8_t(3U))
        {

#line 590
            d3_1 = CompressedTextureBlock_distSq_0(P3_0, L3_1, pDotL3_0, _S217);

#line 590
        }
        else
        {

#line 590
            d3_1 = 1000.0;

#line 590
        }
        uint p_1 = CompressedTextureBlock_argmin_0(d1_1, d2_1, d3_1);
        _S213.partition_index_0.data_1[i_14] = int8_t(int(p_1));
        uint partitions_1 = partitions_0 | uint(1 << p_1);


        bool _S218 = p_1 == 0U;

#line 596
        float pDotL_2;

#line 596
        if(_S218)
        {

#line 596
            pDotL_2 = pDotL1_0;

#line 596
        }
        else
        {

#line 596
            if(p_1 == 1U)
            {

#line 596
                pDotL_2 = pDotL2_0;

#line 596
            }
            else
            {

#line 596
                pDotL_2 = pDotL3_0;

#line 596
            }

#line 596
        }

#line 596
        float invLenSq_2;
        if(_S218)
        {

#line 597
            invLenSq_2 = _S215;

#line 597
        }
        else
        {

#line 597
            if(p_1 == 1U)
            {

#line 597
                invLenSq_2 = _S216;

#line 597
            }
            else
            {

#line 597
                invLenSq_2 = _S217;

#line 597
            }

#line 597
        }

        _S213.weights_0.data_0[i_14] = uint8_t(round(saturate_0(saturate_0(pDotL_2 * invLenSq_2)) * 255.0));

#line 579
        i_14 = i_14 + 1;

#line 579
        partitions_0 = partitions_1;

#line 579
    }

#line 601
    return partitions_0;
}


#line 601
void CompressedTextureBlock_one_step_solve_partition_0(inout CompressedTextureBlock_0 _S219, uint _S220, bool _S221)
{

#line 607
    if((_S219.max_partitions_1) == uint8_t(1U))
    {

#line 607
        CompressedTextureBlock_solve_weights_0(_S219, _S220);


        return;
    }

#line 610
    uint _S222 = CompressedTextureBlock_solve_partition_0(_S219, _S220);

#line 610
    bool single_partition_0;

#line 616
    if((_S219.max_partitions_1) > uint8_t(1U))
    {

#line 616
        if(_S222 == 1U)
        {

#line 616
            single_partition_0 = true;

#line 616
        }
        else
        {

#line 616
            single_partition_0 = _S222 == 2U;

#line 616
        }

#line 616
        if(single_partition_0)
        {

#line 616
            single_partition_0 = true;

#line 616
        }
        else
        {

#line 616
            single_partition_0 = _S222 == 4U;

#line 616
        }

#line 616
    }
    else
    {

#line 616
        single_partition_0 = false;

#line 616
    }
    if(_S221)
    {

#line 617
        single_partition_0 = true;

#line 617
    }

#line 617
    if(single_partition_0)
    {
        CompressedTextureBlock_snap_0(_S219);

#line 619
        CompressedTextureBlock_solve_weights_0(_S219, _S220);

#line 617
    }

#line 623
    return;
}


#line 623
float optimize_0(inout CompressedTextureBlock_0 _S223, uint _S224, uint _S225, bool _S226, uint _S227, uint _S228)
{

#line 1086
    float _S229 = g_params_0.learning_rate_0;

#line 1086
    uint _S230;
    if(_S228 == 0U)
    {

#line 1087
        _S230 = g_params_0.exact_steps_0;

#line 1087
    }
    else
    {

#line 1087
        _S230 = _S228;

#line 1087
    }

    bool _S231 = int(g_params_0.snap_0) > 0;

#line 1089
    uint _S232;
    if((g_params_0.snap_steps_0) == 0U)
    {

#line 1090
        _S232 = uint(float(_S225) * 0.5);

#line 1090
    }
    else
    {

#line 1090
        _S232 = _S225 - g_params_0.snap_steps_0;

#line 1090
    }
    uint max_partitions_2 = uint(_S223.max_partitions_1);

    uint8_t perm_5 = uint8_t(0U);
    uint _S233 = max(1U, _S225 / 10U);
    if(_S226)
    {
        g_diagnostics_0._data[uint(_S227)].loss_log_0[0][max_partitions_2 - 1U] = loss_3P_0(_S224, _S223);

#line 1095
    }

#line 1095
    int step_0 = 0;



    for(;;)
    {

#line 1099
        uint _S234 = uint(step_0);

#line 1099
        if(_S234 < _S225)
        {
        }
        else
        {

#line 1099
            break;
        }

#line 1099
        bool _S235;


        if(_S230 > 0U)
        {

#line 1102
            _S235 = _S234 >= 0U;

#line 1102
        }
        else
        {

#line 1102
            _S235 = false;

#line 1102
        }

#line 1102
        bool should_use_lsq_0;

#line 1102
        if(_S235)
        {

#line 1102
            should_use_lsq_0 = _S234 <= _S230;

#line 1102
        }
        else
        {

#line 1102
            should_use_lsq_0 = false;

#line 1102
        }
        if(should_use_lsq_0)
        {



            if(g_params_0.use_pca_0)
            {
                vec3 _S236 = CompressedTextureBlock_ep0_get_0(_S223);

#line 1110
                vec3 _S237 = CompressedTextureBlock_ep1_get_0(_S223);

#line 1110
                bool _S238 = solve_pca_eps_0(_S223, _S236, _S237, _S224, 0, 1.0);

#line 1110
                _S223._ep0_0 = quantize_0(f16vec3(_S236), 255U);

#line 1110
                _S223._ep1_0 = quantize_0(f16vec3(_S237), 255U);
                vec3 _S239 = CompressedTextureBlock_ep2_get_0(_S223);

#line 1111
                vec3 _S240 = CompressedTextureBlock_ep3_get_0(_S223);

#line 1111
                bool _S241 = solve_pca_eps_0(_S223, _S239, _S240, _S224, 1, 1.0);

#line 1111
                _S223._ep2_0 = quantize_0(f16vec3(_S239), 255U);

#line 1111
                _S223._ep3_0 = quantize_0(f16vec3(_S240), 255U);
                vec3 _S242 = CompressedTextureBlock_ep4_get_0(_S223);

#line 1112
                vec3 _S243 = CompressedTextureBlock_ep5_get_0(_S223);

#line 1112
                bool _S244 = solve_pca_eps_0(_S223, _S242, _S243, _S224, 2, 1.0);

#line 1112
                _S223._ep4_0 = quantize_0(f16vec3(_S242), 255U);

#line 1112
                _S223._ep5_0 = quantize_0(f16vec3(_S243), 255U);

#line 1108
            }
            else
            {

#line 1116
                vec3 _S245 = CompressedTextureBlock_ep0_get_0(_S223);

#line 1116
                vec3 _S246 = CompressedTextureBlock_ep1_get_0(_S223);

#line 1116
                solve_aabb_eps_0(_S223, _S245, _S246, _S224, 0);

#line 1116
                _S223._ep0_0 = quantize_0(f16vec3(_S245), 255U);

#line 1116
                _S223._ep1_0 = quantize_0(f16vec3(_S246), 255U);
                vec3 _S247 = CompressedTextureBlock_ep2_get_0(_S223);

#line 1117
                vec3 _S248 = CompressedTextureBlock_ep3_get_0(_S223);

#line 1117
                solve_aabb_eps_0(_S223, _S247, _S248, _S224, 1);

#line 1117
                _S223._ep2_0 = quantize_0(f16vec3(_S247), 255U);

#line 1117
                _S223._ep3_0 = quantize_0(f16vec3(_S248), 255U);
                vec3 _S249 = CompressedTextureBlock_ep4_get_0(_S223);

#line 1118
                vec3 _S250 = CompressedTextureBlock_ep5_get_0(_S223);

#line 1118
                solve_aabb_eps_0(_S223, _S249, _S250, _S224, 2);

#line 1118
                _S223._ep4_0 = quantize_0(f16vec3(_S249), 255U);

#line 1118
                _S223._ep5_0 = quantize_0(f16vec3(_S250), 255U);

#line 1108
            }

#line 1103
        }
        else
        {

#line 1125
            CompressedTextureBlock_Differential_0 _S251 = CompressedTextureBlock_x24_syn_dzero_0();

#line 1125
            DiffPair_CompressedTextureBlock_0 cb_pair_0;

#line 1125
            cb_pair_0.primal_0 = _S223;

#line 1125
            cb_pair_0.differential_0 = _S251;

#line 1125
            s_bwd_loss_3P_0(_S224, cb_pair_0, 1.0);

#line 1125
            CompressedTextureBlock_Differential_0 _S252 = cb_pair_0.differential_0;


            _S223._ep0_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep0_get_0(_S223) - vec3(cb_pair_0.differential_0._ep0_1) * _S229)), 255U);
            _S223._ep1_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep1_get_0(_S223) - vec3(cb_pair_0.differential_0._ep1_1) * _S229)), 255U);
            if(max_partitions_2 >= 2U)
            {
                _S223._ep2_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep2_get_0(_S223) - vec3(_S252._ep2_1) * _S229)), 255U);
                _S223._ep3_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep3_get_0(_S223) - vec3(_S252._ep3_1) * _S229)), 255U);

#line 1130
            }

#line 1135
            if(max_partitions_2 == 3U)
            {
                _S223._ep4_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep4_get_0(_S223) - vec3(_S252._ep4_1) * _S229)), 255U);
                _S223._ep5_0 = quantize_0(f16vec3(saturate_1(CompressedTextureBlock_ep5_get_0(_S223) - vec3(_S252._ep5_1) * _S229)), 255U);

#line 1135
            }

#line 1103
        }

#line 1103
        bool _S253;

#line 1142
        if(_S231)
        {

#line 1142
            if(_S234 >= _S232)
            {

#line 1142
                _S253 = true;

#line 1142
            }
            else
            {

#line 1142
                _S253 = _S234 >= (_S225 - 1U);

#line 1142
            }

#line 1142
        }
        else
        {

#line 1142
            _S253 = false;

#line 1142
        }

#line 1142
        CompressedTextureBlock_one_step_solve_partition_0(_S223, _S224, _S253);

#line 1142
        bool _S254;

        if(_S226)
        {

#line 1144
            uint _S255 = _S234 % _S233;

#line 1144
            _S254 = _S255 == 0U;

#line 1144
        }
        else
        {

#line 1144
            _S254 = false;

#line 1144
        }

#line 1144
        if(_S254)
        {
            uint _S256 = _S234 / _S233;

#line 1146
            uint iter_1 = _S256 + 1U;
            uvec2 _S257 = (clockRealtime2x32EXT());

#line 1147
            g_diagnostics_0._data[uint(_S227)].timestamps_0[iter_1] = _S257;
            g_diagnostics_0._data[uint(_S227)].loss_log_0[iter_1][max_partitions_2 - 1U] = loss_3P_0(_S224, _S223);

            uint pattern_2 = CompressedTextureBlock_pack_partition_indices_0(_S223);
            uint final_mask_1 = 0U;
            bool _S258 = max_partitions_2 == 3U;
            if(_S258)
            {

#line 1153
                uint _S259 = get_closest_seed3_0(pattern_2, perm_5, final_mask_1);

#line 1153
            }
            else
            {

#line 1154
                uint _S260 = get_closest_seed2_0(pattern_2, perm_5, final_mask_1);

#line 1153
            }

#line 1153
            uint _S261;


            if(_S258)
            {

#line 1156
                uint _S262 = best_perm_distance_s3_0(pattern_2, final_mask_1, perm_5);

#line 1156
                _S261 = _S262;

#line 1156
            }
            else
            {

#line 1157
                uint _S263 = best_perm_distance_s2_0(pattern_2, final_mask_1, perm_5);

#line 1157
                _S261 = _S263;

#line 1156
            }

#line 1155
            g_diagnostics_0._data[uint(_S227)].partition_hamming_error_log_0[iter_1] = _S261;


            g_diagnostics_0._data[uint(_S227)].ideal_partition_log_0[iter_1] = pattern_2;

#line 1163
            g_diagnostics_0._data[uint(_S227)].partition_count_0[iter_1] = uint((hamming_distance_2b_0(pattern_2, 0U)) < 16U) + uint((hamming_distance_2b_0(pattern_2, 1431655765U)) < 16U) + uint((hamming_distance_2b_0(pattern_2, 2863311530U)) < 16U);

#line 1144
        }

#line 1099
        step_0 = step_0 + 1;

#line 1099
    }

#line 1099
    float _S264 = loss_3P_0(_S224, _S223);

#line 1175
    if(_S226)
    {
        g_diagnostics_0._data[uint(_S227)].loss_log_0[11][max_partitions_2 - 1U] = _S264;

#line 1175
    }



    return _S264;
}


#line 1179
u8vec2 CompressedTextureBlock_fast_quantize_0(CompressedTextureBlock_0 _S265, uint _S266)
{

#line 727
    bool _S267 = (_S265.max_partitions_1) == uint8_t(1U);

#line 727
    int i_15;

#line 727
    if(_S267)
    {

#line 727
        i_15 = 111;

#line 727
    }
    else
    {

#line 727
        i_15 = 99;

#line 727
    }
    float B_0 = float(uint8_t(6U) * _S265.max_partitions_1 / uint8_t(16U));
    vec3 _S268 = vec3(ivec3(1));

    float _S269 = pow(2.0, clamp((float(i_15 / 16) + log2((1.0 + 4.0 * NonDifferentiableFP8Weights_mean_0(_S265.weights_0) / 3.0) / (B_0 * ((dot(abs(CompressedTextureBlock_ep1_get_0(_S265) - CompressedTextureBlock_ep0_get_0(_S265)), _S268) + dot(abs(CompressedTextureBlock_ep3_get_0(_S265) - CompressedTextureBlock_ep2_get_0(_S265)), _S268) + dot(abs(CompressedTextureBlock_ep5_get_0(_S265) - CompressedTextureBlock_ep4_get_0(_S265)), _S268)) / 9.0 + 9.99999997475242708e-07)))) / (1.0 + B_0), 1.0, 8.0)) - 1.0;

#line 731
    u8vec2 best_wc_0;

#line 731
    i_15 = 0;


    for(;;)
    {

#line 734
        if(i_15 < 9)
        {
        }
        else
        {

#line 734
            break;
        }

#line 734
        u8vec2 wc_0;


        if(_S267)
        {

#line 737
            wc_0 = VALID_1P_QUANTIZATION_RANGES_0[i_15];

#line 737
        }
        else
        {

#line 738
            if((_S265.max_partitions_1) == uint8_t(2U))
            {

#line 738
                wc_0 = VALID_2P_QUANTIZATION_RANGES_0[i_15];

#line 738
            }
            else
            {

#line 738
                wc_0 = VALID_3P_QUANTIZATION_RANGES_0[i_15];

#line 738
            }

#line 737
        }

        uint8_t _S270 = wc_0.y;

#line 739
        if(_S270 == uint8_t(0U))
        {

#line 740
            i_15 = i_15 + 1;

#line 734
            continue;
        }

#line 741
        if(_S269 < float(_S270))
        {

#line 742
            break;
        }

#line 742
        best_wc_0 = wc_0;

#line 734
        i_15 = i_15 + 1;

#line 734
    }

#line 745
    return best_wc_0;
}


#line 745
u8vec2 CompressedTextureBlock_quantize_0(inout CompressedTextureBlock_0 _S271, uint _S272)
{

#line 745
    CompressedTextureBlock_0 best_block_0;

#line 745
    u8vec2 best_wc_1;

#line 745
    float best_loss_0 = 1000.0;

#line 745
    int i_16 = 0;

#line 754
    for(;;)
    {

#line 754
        if(i_16 < 9)
        {
        }
        else
        {

#line 754
            break;
        }

#line 754
        u8vec2 wc_1;


        if((_S271.max_partitions_1) == uint8_t(1U))
        {

#line 757
            wc_1 = VALID_1P_QUANTIZATION_RANGES_0[i_16];

#line 757
        }
        else
        {

#line 758
            if((_S271.max_partitions_1) == uint8_t(2U))
            {

#line 758
                wc_1 = VALID_2P_QUANTIZATION_RANGES_0[i_16];

#line 758
            }
            else
            {

#line 758
                wc_1 = VALID_3P_QUANTIZATION_RANGES_0[i_16];

#line 758
            }

#line 757
        }

        uint8_t _S273 = wc_1.x;

#line 759
        if(_S273 == uint8_t(0U))
        {

#line 760
            i_16 = i_16 + 1;

#line 754
            continue;
        }

#line 763
        uint8_t c_0 = wc_1.y;
        CompressedTextureBlock_0 block_0 = _S271;
        uint _S274 = uint(c_0);

#line 765
        block_0._ep0_0 = quantize_0(_S271._ep0_0, _S274);
        block_0._ep1_0 = quantize_0(_S271._ep1_0, _S274);
        block_0._ep2_0 = quantize_0(_S271._ep2_0, _S274);
        block_0._ep3_0 = quantize_0(_S271._ep3_0, _S274);
        block_0._ep4_0 = quantize_0(_S271._ep4_0, _S274);
        block_0._ep5_0 = quantize_0(_S271._ep5_0, _S274);
        NonDifferentiableFP8Weights_quantize_0(block_0.weights_0, _S273);

#line 771
        float _S275 = loss_3P_0(_S272, block_0);

#line 771
        bool _S276;


        if(_S275 < best_loss_0)
        {

#line 774
            _S276 = true;

#line 774
        }
        else
        {

#line 774
            _S276 = i_16 == 0;

#line 774
        }

#line 774
        float best_loss_1;

#line 774
        CompressedTextureBlock_0 best_block_1;

#line 774
        u8vec2 best_wc_2;

#line 774
        if(_S276)
        {

#line 774
            best_loss_1 = _S275;

#line 774
            best_block_1 = block_0;

#line 774
            best_wc_2 = wc_1;

#line 774
        }
        else
        {

#line 774
            best_loss_1 = best_loss_0;

#line 774
            best_block_1 = best_block_0;

#line 774
            best_wc_2 = best_wc_1;

#line 774
        }

#line 774
        best_loss_0 = best_loss_1;

#line 774
        best_block_0 = best_block_1;

#line 774
        best_wc_1 = best_wc_2;

#line 754
        i_16 = i_16 + 1;

#line 754
    }

#line 781
    _S271 = best_block_0;
    _S271.qwc_0 = best_wc_1;
    _S271.fqwc_0 = CompressedTextureBlock_fast_quantize_0(_S271, _S272);
    return best_wc_1;
}


#line 784
TextureBlock_0 CompressedTextureBlock_reconstruct_0(CompressedTextureBlock_0 _S277, uint _S278)
{

#line 784
    int i_17;

#line 784
    vec3 c_1;

#line 789
    if(g_params_0.debug_reconstruction_0)
    {
        TextureBlock_0 outputBlock_2;

#line 791
        i_17 = 0;
        for(;;)
        {

#line 792
            if(i_17 < 16)
            {
            }
            else
            {

#line 792
                break;
            }

            int partition_3 = clamp(int(float(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S277.partition_index_0, i_17))), 0, 2);


            if(partition_3 == 0)
            {

#line 798
                c_1 = vec3(1.0, 1.0, 1.0);

#line 798
            }
            else
            {

#line 798
                if(partition_3 == 1)
                {

#line 798
                    c_1 = vec3(0.5, 0.5, 0.5);

#line 798
                }
                else
                {

#line 798
                    c_1 = vec3(0.0, 0.0, 0.0);

#line 798
                }

#line 798
            }
            outputBlock_2.pixels_0[i_17] = c_1;

#line 792
            i_17 = i_17 + 1;

#line 792
        }

#line 801
        return outputBlock_2;
    }
    if(g_params_0.debug_loss_0)
    {
        TextureBlock_0 outputBlock_3;

#line 805
        i_17 = 0;
        for(;;)
        {

#line 806
            if(i_17 < 16)
            {
            }
            else
            {

#line 806
                break;
            }
            float w_0 = NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(_S277.weights_0, i_17);
            int partition_4 = clamp(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S277.partition_index_0, i_17), 0, 2);
            bool _S279 = partition_4 == 0;

#line 810
            if(_S279)
            {

#line 810
                c_1 = CompressedTextureBlock_ep0_get_0(_S277);

#line 810
            }
            else
            {

#line 810
                if(partition_4 == 1)
                {

#line 810
                    c_1 = CompressedTextureBlock_ep2_get_0(_S277);

#line 810
                }
                else
                {

#line 810
                    c_1 = CompressedTextureBlock_ep4_get_0(_S277);

#line 810
                }

#line 810
            }

#line 810
            vec3 e1_3;
            if(_S279)
            {

#line 811
                e1_3 = CompressedTextureBlock_ep1_get_0(_S277);

#line 811
            }
            else
            {

#line 811
                if(partition_4 == 1)
                {

#line 811
                    e1_3 = CompressedTextureBlock_ep3_get_0(_S277);

#line 811
                }
                else
                {

#line 811
                    e1_3 = CompressedTextureBlock_ep5_get_0(_S277);

#line 811
                }

#line 811
            }

            outputBlock_3.pixels_0[i_17] = abs(g_groundtruth_0._data[uint(_S278)].pixels_0[i_17] - mix(c_1, e1_3, vec3(w_0)));

#line 806
            i_17 = i_17 + 1;

#line 806
        }

#line 815
        return outputBlock_3;
    }
    if(g_params_0.debug_quant_0)
    {
        TextureBlock_0 outputBlock_4;

#line 819
        i_17 = 0;
        for(;;)
        {

#line 820
            if(i_17 < 16)
            {
            }
            else
            {

#line 820
                break;
            }

#line 829
            const vec3 _S280 = vec3(1.0, 0.0, 0.0);
            const vec3 _S281 = vec3(0.0, 1.0, 0.0);
            const vec3 _S282 = vec3(0.0, 0.0, 1.0);
            const vec3 _S283 = vec3(1.0, 0.0, 1.0);
            vec3 _S284 = vec3(ivec3(0));
            switch(_S277.qwc_0.y)
            {
            case uint8_t(5U):
                {

#line 834
                    c_1 = _S280 * 0.33000001311302185;



                    break;
                }
            case uint8_t(7U):
                {

#line 838
                    c_1 = _S280 * 0.67000001668930054;


                    break;
                }
            case uint8_t(9U):
                {

#line 841
                    c_1 = _S280;


                    break;
                }
            case uint8_t(11U):
                {

#line 844
                    c_1 = _S282 * 0.33000001311302185;



                    break;
                }
            case uint8_t(15U):
                {

#line 848
                    c_1 = _S282 * 0.5;


                    break;
                }
            case uint8_t(23U):
                {

#line 851
                    c_1 = _S282;


                    break;
                }
            case uint8_t(31U):
                {

#line 854
                    c_1 = _S281 * 0.33000001311302185;



                    break;
                }
            case uint8_t(33U):
                {

#line 858
                    c_1 = _S281 * 0.5;


                    break;
                }
            case uint8_t(39U):
                {

#line 861
                    c_1 = _S281;


                    break;
                }
            case uint8_t(63U):
                {

#line 864
                    c_1 = _S283 * 0.33000001311302185;



                    break;
                }
            case uint8_t(95U):
                {

#line 868
                    c_1 = _S283 * 0.67000001668930054;


                    break;
                }
            case uint8_t(191U):
                {

#line 871
                    c_1 = _S283 * 0.89999997615814209;


                    break;
                }
            case uint8_t(255U):
                {

#line 874
                    c_1 = _S283;


                    break;
                }
            default:
                {

#line 877
                    c_1 = _S284;

#line 877
                    break;
                }
            }
            outputBlock_4.pixels_0[i_17] = c_1;

#line 820
            i_17 = i_17 + 1;

#line 820
        }

#line 882
        return outputBlock_4;
    }
    return CompressedTextureBlock_decompress3P_0(_S277);
}


#line 1185
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 1187
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_params_0.num_blocks_0))
    {

#line 1189
        return;
    }

#line 1190
    uvec2 _S285 = (clockRealtime2x32EXT());

#line 1190
    g_diagnostics_0._data[uint(blockIdx_0)].start_clock_0 = _S285;

    uint8_t perm_6 = uint8_t(0U);


    PCG32_0 prng_0 = PCG32_x24init_0(g_params_0.seed_0);
    CompressedTextureBlock_0 block_1 = g_compressedBlock3P_0._data[uint(blockIdx_0)];
    block_1.max_partitions_1 = g_params_0.max_partitions_0;

    CompressedTextureBlock_0 block1_0 = block_1;
    CompressedTextureBlock_0 block2_0 = block_1;
    CompressedTextureBlock_0 block3_0 = block_1;

#line 1206
    uint steps_1 = g_params_0.steps_0;

#line 1206
    float loss3_0;

#line 1206
    float loss2_0;

#line 1206
    float loss1_0;
    if(g_params_0.ensemble_0)
    {
        prng_0 = PCG32_x24init_0(g_params_0.seed_0);
        block1_0.max_partitions_1 = uint8_t(1U);

#line 1210
        CompressedTextureBlock_random_initialize_0(block1_0, blockIdx_0, prng_0);

#line 1210
        uint exact_1p_steps_0;

        if((g_params_0.steps_1p_0) == (g_params_0.steps_0))
        {

#line 1212
            exact_1p_steps_0 = 0U;

#line 1212
        }
        else
        {

#line 1212
            exact_1p_steps_0 = g_params_0.steps_1p_0;

#line 1212
        }

#line 1212
        float _S286 = optimize_0(block1_0, blockIdx_0, g_params_0.steps_1p_0, true, blockIdx_0, exact_1p_steps_0);

        prng_0 = PCG32_x24init_0(g_params_0.seed_0);
        block2_0.max_partitions_1 = uint8_t(2U);

#line 1215
        CompressedTextureBlock_random_initialize_0(block2_0, blockIdx_0, prng_0);

#line 1215
        float _S287 = optimize_0(block2_0, blockIdx_0, steps_1, true, blockIdx_0, 0U);


        prng_0 = PCG32_x24init_0(g_params_0.seed_0);
        if((g_params_0.max_partitions_0) == uint8_t(3U))
        {
            block3_0.max_partitions_1 = uint8_t(3U);

#line 1221
            CompressedTextureBlock_random_initialize_0(block3_0, blockIdx_0, prng_0);

#line 1221
            float _S288 = optimize_0(block3_0, blockIdx_0, steps_1, true, blockIdx_0, 0U);

#line 1221
            loss3_0 = _S288;

#line 1219
        }
        else
        {

#line 1219
            loss3_0 = 0.0;

#line 1219
        }

#line 1219
        loss2_0 = _S287;

#line 1219
        loss1_0 = _S286;

#line 1207
    }
    else
    {

#line 1207
        CompressedTextureBlock_random_initialize_0(block_1, blockIdx_0, prng_0);

#line 1207
        float _S289 = optimize_0(block_1, blockIdx_0, steps_1, true, blockIdx_0, 0U);

#line 1207
        loss3_0 = 0.0;

#line 1207
        loss2_0 = 0.0;

#line 1207
        loss1_0 = 0.0;

#line 1207
    }

#line 1232
    uvec2 _S290 = (clockRealtime2x32EXT());

#line 1232
    g_diagnostics_0._data[uint(blockIdx_0)].optim_ended_clock_0 = _S290;

#line 1232
    float final_loss_0;


    if(!g_params_0.no_quantization_0)
    {
        if(g_params_0.ensemble_0)
        {

#line 1237
            u8vec2 _S291 = CompressedTextureBlock_quantize_0(block1_0, blockIdx_0);

#line 1237
            float _S292 = loss_3P_0(blockIdx_0, block1_0);

#line 1237
            u8vec2 _S293 = CompressedTextureBlock_quantize_0(block2_0, blockIdx_0);

#line 1237
            float _S294 = loss_3P_0(blockIdx_0, block2_0);

#line 1237
            float quantized_loss3_0;

#line 1244
            if((g_params_0.max_partitions_0) == uint8_t(3U))
            {

#line 1244
                u8vec2 _S295 = CompressedTextureBlock_quantize_0(block3_0, blockIdx_0);

#line 1244
                quantized_loss3_0 = loss_3P_0(blockIdx_0, block3_0);

#line 1244
            }
            else
            {

#line 1244
                quantized_loss3_0 = 1000.0;

#line 1244
            }

#line 1244
            bool _S296;

#line 1249
            if(quantized_loss3_0 < _S294)
            {

#line 1249
                _S296 = quantized_loss3_0 < _S292;

#line 1249
            }
            else
            {

#line 1249
                _S296 = false;

#line 1249
            }

#line 1249
            if(_S296)
            {
                g_diagnostics_0._data[uint(blockIdx_0)].final_unquantized_loss_0 = loss3_0;
                block_1 = block3_0;

#line 1252
                final_loss_0 = quantized_loss3_0;

#line 1249
            }
            else
            {



                if(_S294 < _S292)
                {
                    g_diagnostics_0._data[uint(blockIdx_0)].final_unquantized_loss_0 = loss2_0;
                    block_1 = block2_0;

#line 1258
                    final_loss_0 = _S294;

#line 1255
                }
                else
                {

#line 1263
                    g_diagnostics_0._data[uint(blockIdx_0)].final_unquantized_loss_0 = loss1_0;
                    block_1 = block1_0;

#line 1264
                    final_loss_0 = _S292;

#line 1255
                }

#line 1249
            }

#line 1237
        }
        else
        {

#line 1270
            g_diagnostics_0._data[uint(blockIdx_0)].final_unquantized_loss_0 = loss_3P_0(blockIdx_0, block_1);

#line 1270
            u8vec2 _S297 = CompressedTextureBlock_quantize_0(block_1, blockIdx_0);

#line 1270
            final_loss_0 = loss_3P_0(blockIdx_0, block_1);

#line 1237
        }

#line 1235
    }
    else
    {

#line 1235
        final_loss_0 = loss_3P_0(blockIdx_0, block_1);

#line 1235
    }

#line 1279
    g_compressedBlock3P_0._data[uint(blockIdx_0)] = block_1;
    g_reconstructed_0._data[uint(blockIdx_0)] = CompressedTextureBlock_reconstruct_0(block_1, blockIdx_0);
    g_diagnostics_0._data[uint(blockIdx_0)].partition_hamming_error_0 = best_perm_distance_s3_0(block_1.ideal_partition_map_0, block_1.astc_partition_map_0, perm_6);
    g_final_loss_0._data[uint(blockIdx_0)] = final_loss_0;
    uvec2 _S298 = (clockRealtime2x32EXT());

#line 1283
    g_diagnostics_0._data[uint(blockIdx_0)].finished_clock_0 = _S298;
    return;
}

