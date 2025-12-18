#version 450
#extension GL_EXT_shader_8bit_storage : require
#extension GL_EXT_shader_explicit_arithmetic_types : require
#extension GL_EXT_shader_16bit_storage : require
#extension GL_EXT_shader_realtime_clock : require
#extension GL_EXT_control_flow_attributes : require
layout(row_major) uniform;
layout(row_major) buffer;

#line 28 0
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
    bool exhaustive_0;
};


#line 47
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
    bool exhaustive_0;
}g_params_0;

#line 8
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


#line 56
layout(std430, binding = 3) buffer StructuredBuffer_Diagnostics_t_0 {
    Diagnostics_0 _data[];
} g_diagnostics_0;

#line 2
struct TextureBlock_0
{
    vec3  pixels_0[16];
};


#line 50
layout(std430, binding = 1) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;

#line 68
struct LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
};


#line 73
layout(binding = 8)
layout(std140) uniform block_LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
}g_lut_0;

#line 353
struct NonDifferentiableFP8Weights_0
{
    uint8_t  data_0[16];
};


#line 390
struct NonDifferentiableIntPartitions_0
{
    int8_t  data_1[16];
};


#line 407
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


#line 59
layout(std430, binding = 4) buffer StructuredBuffer_CompressedTextureBlock_t_0 {
    CompressedTextureBlock_0 _data[];
} g_compressedBlock3P_0;

#line 53
layout(std430, binding = 2) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;

#line 62
layout(std430, binding = 5) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 339
const u8vec2  VALID_3P_QUANTIZATION_RANGES_0[9] = { u8vec2(uint8_t(7U), uint8_t(5U)), u8vec2(uint8_t(5U), uint8_t(7U)), u8vec2(uint8_t(4U), uint8_t(9U)), u8vec2(uint8_t(3U), uint8_t(11U)), u8vec2(uint8_t(2U), uint8_t(15U)), u8vec2(uint8_t(1U), uint8_t(23U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)) };

#line 326
const u8vec2  VALID_2P_QUANTIZATION_RANGES_0[9] = { u8vec2(uint8_t(15U), uint8_t(5U)), u8vec2(uint8_t(11U), uint8_t(9U)), u8vec2(uint8_t(9U), uint8_t(11U)), u8vec2(uint8_t(7U), uint8_t(15U)), u8vec2(uint8_t(5U), uint8_t(23U)), u8vec2(uint8_t(4U), uint8_t(31U)), u8vec2(uint8_t(3U), uint8_t(39U)), u8vec2(uint8_t(2U), uint8_t(63U)), u8vec2(uint8_t(1U), uint8_t(95U)) };

#line 313
const u8vec2  VALID_1P_QUANTIZATION_RANGES_0[9] = { u8vec2(uint8_t(31U), uint8_t(31U)), u8vec2(uint8_t(23U), uint8_t(63U)), u8vec2(uint8_t(19U), uint8_t(95U)), u8vec2(uint8_t(15U), uint8_t(191U)), u8vec2(uint8_t(11U), uint8_t(255U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)) };

#line 589
const float  kClusterCutoffs_0[9] = { 0.6262199878692627, 0.9327700138092041, 0.27545401453971863, 0.31855800747871399, 0.24011300504207611, 0.00918999966233969, 0.34766098856925964, 0.7319599986076355, 0.15639099478721619 };

#line 78
struct PCG32_0
{
    uint state_0;
};


#line 82
PCG32_0 PCG32_x24init_0(uint seed_1)
{

#line 82
    PCG32_0 _S1;

    uint _S2 = seed_1 * 747796405U + 2891336453U;
    uint _S3 = ((_S2 >> ((_S2 >> 28U) + 4U)) ^ _S2) * 277803737U;
    _S1.state_0 = (_S3 >> 22U) ^ _S3;

#line 82
    return _S1;
}


#line 97
uint PCG32_nextUint_0(inout PCG32_0 this_0)
{
    uint oldState_0 = this_0.state_0;
    this_0.state_0 = this_0.state_0 * 747796405U + 2891336453U;
    uint word_0 = ((oldState_0 >> ((oldState_0 >> 28U) + 4U)) ^ oldState_0) * 277803737U;
    return (word_0 >> 22U) ^ word_0;
}


#line 446
uint CompressedTextureBlock_pack_partition_indices_0(uint8_t  partition_index_1[16])
{

#line 446
    int i_0 = 0;

#line 446
    uint raw_map_0 = 0U;


    for(;;)
    {

#line 449
        if(i_0 < 16)
        {
        }
        else
        {

#line 449
            break;
        }

        uint raw_map_1 = raw_map_0 | (uint(clamp(int(partition_index_1[i_0]), 0, 2)) << (i_0 * 2));

#line 449
        i_0 = i_0 + 1;

#line 449
        raw_map_0 = raw_map_1;

#line 449
    }

#line 454
    return raw_map_0;
}


#line 1225
struct RankedSeeds_0
{
    uint8_t slots_0;
    uint  seeds_masks_0[67];
    uint8_t  counts_0[8];
    uint entries_0;
};


#line 1225
RankedSeeds_0 RankedSeeds_x24init_0(uint8_t slots_1, uint  seeds_masks_1[67], uint8_t  counts_1[8], uint entries_1)
{

#line 1225
    RankedSeeds_0 _S4;

    _S4.slots_0 = slots_1;

#line 1234
    _S4.seeds_masks_0 = seeds_masks_1;
    _S4.counts_0 = counts_1;
    _S4.entries_0 = entries_1;

#line 1225
    return _S4;
}


#line 274
uint count_diffs_0(uint val_0)
{
    return bitCount((val_0 | (val_0 >> 1)) & 1431655765U);
}


#line 204
uint8_t best_perm_distance_s2_0(uint x_0, uint y_0, out uint8_t perm_1)
{
    uint base_0 = x_0 ^ y_0;

#line 214
    uint min01_0 = min(((count_diffs_0(base_0)) << 1) | 0U, ((count_diffs_0(base_0 ^ ((~(x_0 >> 1)) & 1431655765U))) << 1) | 1U);

    perm_1 = uint8_t(int(min01_0 & 1U));
    return uint8_t(min01_0 >> 1);
}


#line 174
uint8_t best_perm_distance_s3_0(uint x_1, uint y_1, out uint8_t perm_2)
{
    uint base_1 = x_1 ^ y_1;

    uint x_shr1_0 = x_1 >> 1;
    uint nz_0 = (x_1 | x_shr1_0) & 1431655765U;
    uint nz_shl1_0 = nz_0 << 1;

    uint m01_0 = (~x_shr1_0) & 1431655765U;

#line 198
    uint best_0 = min(min(min(((count_diffs_0(base_1)) << 3) | 0U, ((count_diffs_0(base_1 ^ m01_0)) << 3) | 1U), min(((count_diffs_0(base_1 ^ ((~(x_1 << 1)) & 2863311530U))) << 3) | 2U, ((count_diffs_0(base_1 ^ (nz_0 | nz_shl1_0))) << 3) | 3U)), min(((count_diffs_0(base_1 ^ (m01_0 | nz_shl1_0))) << 3) | 4U, ((count_diffs_0(base_1 ^ (nz_0 | (((~x_1) & 1431655765U) << 1)))) << 3) | 5U));

    perm_2 = uint8_t(int(best_0 & 7U));
    return uint8_t(best_0 >> 3);
}


#line 1245
void RankedSeeds_add_0(inout RankedSeeds_0 this_1, uint16_t seed_2, uint16_t distance_0)
{
    uint8_t count_0 = this_1.counts_0[distance_0];
    if((this_1.counts_0[distance_0]) < (this_1.slots_0))
    {
        uint16_t _S5 = distance_0 * uint16_t(25US) + uint16_t(count_0);

        this_1.seeds_masks_0[_S5 / uint16_t(3US)] = (this_1.seeds_masks_0[_S5 / uint16_t(3US)]) | (uint(seed_2 + uint16_t(1US)) << uint(_S5 % uint16_t(3US) * uint16_t(10US)));
        this_1.counts_0[distance_0] = this_1.counts_0[distance_0] + uint8_t(1U);
        this_1.entries_0 = this_1.entries_0 + 1U;

#line 1248
    }

#line 1256
    return;
}


#line 1238
uint16_t RankedSeeds_get_0(RankedSeeds_0 this_2, uint16_t n_0)
{
    return uint16_t((this_2.seeds_masks_0[n_0 / uint16_t(3US)]) >> uint(n_0 % uint16_t(3US) * uint16_t(10US))) & uint16_t(1023US);
}


#line 537
void CompressedTextureBlock_set_astc_seed_0(inout CompressedTextureBlock_0 this_3, uint16_t seed_3)
{
    this_3.astc_seed_0 = seed_3;

#line 539
    uint _S6;
    if((this_3.max_partitions_1) == uint8_t(2U))
    {

#line 540
        _S6 = g_lut_0.lut2_0[seed_3];

#line 540
    }
    else
    {

#line 540
        _S6 = g_lut_0.lut3_0[seed_3];

#line 540
    }

#line 540
    this_3.astc_partition_map_0 = _S6;

#line 540
    int i_1 = 0;


    [[unroll]]
    for(;;)
    {

#line 543
        if(i_1 < 16)
        {
        }
        else
        {

#line 543
            break;
        }
        this_3.partition_index_0.data_1[i_1] = int8_t(int(((this_3.astc_partition_map_0) >> (2 * i_1)) & 3U));

#line 543
        i_1 = i_1 + 1;

#line 543
    }



    return;
}


#line 395
int NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(NonDifferentiableIntPartitions_0 this_4, int n_1)
{
    return int(this_4.data_1[n_1]);
}


#line 1139
float estimate_partition_error_bound_0(mat3x3 scatter_matrix_0, float count_1)
{

#line 1145
    vec3 axis_0 = (((vec3(0.17000000178813934, 0.82999998331069946, 0.37999999523162842)) * (scatter_matrix_0)));

    vec3 axis_1 = (((axis_0 * (inversesqrt((dot(axis_0, axis_0) + 9.99999997475242708e-07)))) * (scatter_matrix_0)));


    return max(0.0, scatter_matrix_0[0][0] + scatter_matrix_0[1][1] + scatter_matrix_0[2][2] - sqrt(dot(axis_1, axis_1)));
}


#line 429
vec3 CompressedTextureBlock_ep0_get_0(CompressedTextureBlock_0 this_5)
{
    return vec3(this_5._ep0_0);
}


#line 429
vec3 CompressedTextureBlock_ep1_get_0(CompressedTextureBlock_0 this_6)
{
    return vec3(this_6._ep1_0);
}


#line 13408 1
vec3 saturate_0(vec3 x_2)
{

#line 13416
    return clamp(x_2, vec3(0.0), vec3(1.0));
}


#line 967 0
void bound_and_damp_0(vec3 x_3, vec3 y_2, inout vec3 x_out_0, inout vec3 y_out_0, float lr_0)
{
    vec3 _S7 = x_out_0;
    vec3 _S8 = y_out_0;

    const vec3 boxMin_0 = vec3(0.0, 0.0, 0.0);
    const vec3 boxMax_0 = vec3(1.0, 1.0, 1.0);

#line 973
    bool xInside_0;

    if((all(bvec3((greaterThanEqual(x_3,boxMin_0))))))
    {

#line 975
        xInside_0 = (all(bvec3((lessThanEqual(x_3,boxMax_0)))));

#line 975
    }
    else
    {

#line 975
        xInside_0 = false;

#line 975
    }

#line 975
    bool yInside_0;
    if((all(bvec3((greaterThanEqual(y_2,boxMin_0))))))
    {

#line 976
        yInside_0 = (all(bvec3((lessThanEqual(y_2,boxMax_0)))));

#line 976
    }
    else
    {

#line 976
        yInside_0 = false;

#line 976
    }

    vec3 d_0 = y_2 - x_3;
    float distSq_0 = dot(d_0, d_0);
    if(!xInside_0)
    {

#line 980
        xInside_0 = true;

#line 980
    }
    else
    {

#line 980
        xInside_0 = !yInside_0;

#line 980
    }

#line 980
    bool shouldClip_0;

#line 980
    if(xInside_0)
    {

#line 980
        shouldClip_0 = true;

#line 980
    }
    else
    {

#line 980
        shouldClip_0 = distSq_0 < 0.00999999977648258;

#line 980
    }

#line 980
    vec3 new_x_0;

#line 980
    vec3 new_y_0;

#line 985
    if(shouldClip_0)
    {
        vec3 invDir_0 = 1.0 / (d_0 + 9.99999997475242708e-07);
        vec3 t0_0 = (boxMin_0 - x_3) * invDir_0;
        vec3 t1_0 = (boxMax_0 - x_3) * invDir_0;
        vec3 tSmall_0 = min(t0_0, t1_0);
        vec3 tBig_0 = max(t0_0, t1_0);

#line 998
        vec3 _S9 = saturate_0(x_3 + d_0 * min(min(min(tBig_0.x, tBig_0.y), tBig_0.z), 1.0));

#line 998
        new_x_0 = saturate_0(x_3 + d_0 * max(max(max(tSmall_0.x, tSmall_0.y), tSmall_0.z), 0.0));

#line 998
        new_y_0 = _S9;

#line 985
    }
    else
    {

#line 985
        new_x_0 = x_3;

#line 985
        new_y_0 = y_2;

#line 985
    }

#line 1001
    vec3 _S10 = vec3(lr_0);

#line 1001
    x_out_0 = mix(_S7, new_x_0, _S10);
    y_out_0 = mix(_S8, new_y_0, _S10);
    return;
}


#line 307
f16vec3 quantize_0(f16vec3 value_0, uint range_0)
{
    f16vec3 scale_0 = f16vec3(float16_t(int(range_0)));
    return round(value_0 * scale_0) / scale_0;
}


#line 429
vec3 CompressedTextureBlock_ep2_get_0(CompressedTextureBlock_0 this_7)
{
    return vec3(this_7._ep2_0);
}


#line 429
vec3 CompressedTextureBlock_ep3_get_0(CompressedTextureBlock_0 this_8)
{
    return vec3(this_8._ep3_0);
}


#line 429
vec3 CompressedTextureBlock_ep4_get_0(CompressedTextureBlock_0 this_9)
{
    return vec3(this_9._ep4_0);
}


#line 429
vec3 CompressedTextureBlock_ep5_get_0(CompressedTextureBlock_0 this_10)
{
    return vec3(this_10._ep5_0);
}


#line 13393 1
float saturate_1(float x_4)
{

#line 13401
    return clamp(x_4, 0.0, 1.0);
}


#line 358 0
float NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(NonDifferentiableFP8Weights_0 this_11, int n_2)
{
    return float(this_11.data_0[n_2]) / 255.0;
}


#line 729
TextureBlock_0 CompressedTextureBlock_decompress3P_0(CompressedTextureBlock_0 this_12)
{
    TextureBlock_0 outputBlock_0;

#line 731
    uint i_2 = 0U;

    [[unroll]]
    for(;;)
    {

#line 733
        if(i_2 < 16U)
        {
        }
        else
        {

#line 733
            break;
        }
        int _S11 = int(i_2);

#line 735
        float w_0 = NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(this_12.weights_0, _S11);
        int partition_0 = clamp(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(this_12.partition_index_0, _S11), 0, int(this_12.max_partitions_1 - uint8_t(1U)));
        bool _S12 = partition_0 == 0;

#line 737
        vec3 e0_0;

#line 737
        if(_S12)
        {

#line 737
            e0_0 = CompressedTextureBlock_ep0_get_0(this_12);

#line 737
        }
        else
        {

#line 737
            if(partition_0 == 1)
            {

#line 737
                e0_0 = CompressedTextureBlock_ep2_get_0(this_12);

#line 737
            }
            else
            {

#line 737
                e0_0 = CompressedTextureBlock_ep4_get_0(this_12);

#line 737
            }

#line 737
        }

#line 737
        vec3 e1_0;
        if(_S12)
        {

#line 738
            e1_0 = CompressedTextureBlock_ep1_get_0(this_12);

#line 738
        }
        else
        {

#line 738
            if(partition_0 == 1)
            {

#line 738
                e1_0 = CompressedTextureBlock_ep3_get_0(this_12);

#line 738
            }
            else
            {

#line 738
                e1_0 = CompressedTextureBlock_ep5_get_0(this_12);

#line 738
            }

#line 738
        }
        outputBlock_0.pixels_0[i_2] = mix(e0_0, e1_0, vec3(w_0));

#line 733
        i_2 = i_2 + 1U;

#line 733
    }

#line 741
    return outputBlock_0;
}


#line 301
float quantize_1(float value_1, uint range_1)
{

#line 301
    float _S13 = float(int(range_1));


    return round(value_1 * _S13) / _S13;
}


#line 369
void NonDifferentiableFP8Weights_quantize_0(inout NonDifferentiableFP8Weights_0 this_13, uint8_t range_2)
{

#line 369
    int i_3 = 0;


    [[unroll]]
    for(;;)
    {

#line 372
        if(i_3 < 16)
        {
        }
        else
        {

#line 372
            break;
        }
        this_13.data_0[i_3] = uint8_t(round(saturate_1(quantize_1(NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(this_13, i_3), uint(range_2))) * 255.0));

#line 372
        i_3 = i_3 + 1;

#line 372
    }



    return;
}


#line 655
void CompressedTextureBlock_cluster_astc_0(CompressedTextureBlock_0 _S14, uint _S15, inout uint8_t  _S16[16])
{

#line 597
    vec3  centroids_0[4];

    PCG32_0 prng_0 = PCG32_x24init_0(g_params_0.seed_0);

#line 599
    int iter_0 = 0;


    [[unroll]]
    for(;;)
    {

#line 602
        if(iter_0 < 3)
        {
        }
        else
        {

#line 602
            break;
        }

#line 602
        int i_4;

#line 602
        int safe_iter_0;

#line 602
        uint c_0;

#line 602
        float best_dist_0;

        if(iter_0 == 0)
        {

            centroids_0[0] = g_groundtruth_0._data[uint(_S15)].pixels_0[8];
            float  dists_0[16];

#line 608
            i_4 = 0;

            [[unroll]]
            for(;;)
            {

#line 610
                if(i_4 < 16)
                {
                }
                else
                {

#line 610
                    break;
                }
                vec3 d_1 = g_groundtruth_0._data[uint(_S15)].pixels_0[i_4] - centroids_0[0];
                dists_0[i_4] = dot(d_1, d_1);

#line 610
                i_4 = i_4 + 1;

#line 610
            }

#line 610
            c_0 = 1U;

#line 618
            [[unroll]]
            for(;;)
            {

#line 618
                if(c_0 < uint(_S14.max_partitions_1))
                {
                }
                else
                {

#line 618
                    break;
                }

#line 618
                safe_iter_0 = 0;

#line 618
                best_dist_0 = 0.0;



                [[unroll]]
                for(;;)
                {

#line 622
                    if(safe_iter_0 < 16)
                    {
                    }
                    else
                    {

#line 622
                        break;
                    }

#line 623
                    float total_dist_0 = best_dist_0 + dists_0[safe_iter_0];

#line 622
                    safe_iter_0 = safe_iter_0 + 1;

#line 622
                    best_dist_0 = total_dist_0;

#line 622
                }

#line 622
                uint selected_sample_0;



                float _S17 = best_dist_0 * kClusterCutoffs_0[c_0 - 1U + uint(uint8_t(3U) * (_S14.max_partitions_1 - uint8_t(2U)))];

#line 626
                uint sample_0 = 0U;

#line 626
                float running_sum_0 = 0.0;

#line 632
                [[unroll]]
                for(;;)
                {

#line 632
                    if(sample_0 < 16U)
                    {
                    }
                    else
                    {

#line 632
                        selected_sample_0 = 0U;

#line 632
                        break;
                    }
                    float running_sum_1 = running_sum_0 + dists_0[sample_0];
                    if(running_sum_1 >= _S17)
                    {

#line 635
                        selected_sample_0 = sample_0;


                        break;
                    }

#line 632
                    sample_0 = sample_0 + 1U;

#line 632
                    running_sum_0 = running_sum_1;

#line 632
                }

#line 642
                centroids_0[c_0] = g_groundtruth_0._data[uint(_S15)].pixels_0[selected_sample_0];

#line 642
                int t2_0 = 0;


                [[unroll]]
                for(;;)
                {

#line 645
                    if(t2_0 < 16)
                    {
                    }
                    else
                    {

#line 645
                        break;
                    }
                    vec3 d_2 = g_groundtruth_0._data[uint(_S15)].pixels_0[t2_0] - centroids_0[c_0];
                    dists_0[t2_0] = min(dists_0[t2_0], dot(d_2, d_2));

#line 645
                    t2_0 = t2_0 + 1;

#line 645
                }

#line 618
                c_0 = c_0 + 1U;

#line 618
            }

#line 604
        }
        else
        {

#line 654
            const vec3 _S18 = vec3(0.0, 0.0, 0.0);

#line 654
            vec3  color_sums_0[4];

#line 654
            color_sums_0[0] = _S18;

#line 654
            color_sums_0[1] = _S18;

#line 654
            color_sums_0[2] = _S18;

#line 654
            color_sums_0[3] = _S18;
            uint  counts_2[4];

#line 655
            counts_2[0] = 0U;

#line 655
            counts_2[1] = 0U;

#line 655
            counts_2[2] = 0U;

#line 655
            counts_2[3] = 0U;

#line 655
            i_4 = 0;


            [[unroll]]
            for(;;)
            {

#line 658
                if(i_4 < 16)
                {
                }
                else
                {

#line 658
                    break;
                }
                uint p_idx_0 = uint(_S16[i_4]);
                color_sums_0[p_idx_0] = color_sums_0[p_idx_0] + g_groundtruth_0._data[uint(_S15)].pixels_0[i_4];
                counts_2[p_idx_0] = counts_2[p_idx_0] + 1U;

#line 658
                i_4 = i_4 + 1;

#line 658
            }

#line 658
            c_0 = 0U;

#line 666
            [[unroll]]
            for(;;)
            {

#line 666
                if(c_0 < uint(_S14.max_partitions_1))
                {
                }
                else
                {

#line 666
                    break;
                }
                if((counts_2[c_0]) > 0U)
                {
                    centroids_0[c_0] = color_sums_0[c_0] / float(counts_2[c_0]);

#line 668
                }
                else
                {



                    centroids_0[c_0] = _S18;

#line 668
                }

#line 666
                c_0 = c_0 + 1U;

#line 666
            }

#line 604
        }

#line 604
        uint8_t best_idx_0;

#line 679
        uint  partition_counts_0[4];

#line 679
        partition_counts_0[0] = 0U;

#line 679
        partition_counts_0[1] = 0U;

#line 679
        partition_counts_0[2] = 0U;

#line 679
        partition_counts_0[3] = 0U;

#line 679
        i_4 = 0;

        [[unroll]]
        for(;;)
        {

#line 681
            if(i_4 < 16)
            {
            }
            else
            {

#line 681
                break;
            }

#line 681
            best_dist_0 = 1000.0;

#line 681
            best_idx_0 = uint8_t(0U);

#line 681
            uint8_t j_0 = uint8_t(0U);

#line 687
            [[unroll]]
            for(;;)
            {

#line 687
                if(j_0 < (_S14.max_partitions_1))
                {
                }
                else
                {

#line 687
                    break;
                }
                float d_3 = dot(g_groundtruth_0._data[uint(_S15)].pixels_0[i_4] - centroids_0[j_0], g_groundtruth_0._data[uint(_S15)].pixels_0[i_4] - centroids_0[j_0]);
                if(d_3 < best_dist_0)
                {

#line 690
                    best_dist_0 = d_3;

#line 690
                    best_idx_0 = j_0;

#line 690
                }

#line 687
                j_0 = j_0 + uint8_t(1U);

#line 687
            }

#line 696
            _S16[i_4] = best_idx_0;
            partition_counts_0[best_idx_0] = partition_counts_0[best_idx_0] + 1U;

#line 681
            i_4 = i_4 + 1;

#line 681
        }

#line 681
        bool problem_0 = true;

#line 681
        safe_iter_0 = 0;

#line 703
        [[unroll]]
        for(;;)
        {

#line 703
            if(safe_iter_0 < 4)
            {
            }
            else
            {

#line 703
                break;
            }
            if(!problem_0)
            {

#line 706
                break;
            }

#line 706
            bool problem_1 = false;

#line 706
            best_idx_0 = uint8_t(0U);



            [[unroll]]
            for(;;)
            {

#line 710
                if(best_idx_0 < (_S14.max_partitions_1))
                {
                }
                else
                {

#line 710
                    break;
                }
                if((partition_counts_0[best_idx_0]) == 0U)
                {

                    uint _S19 = PCG32_nextUint_0(prng_0);

#line 715
                    uint old_p_0 = uint(_S16[_S19 % 16U]);

#line 715
                    bool problem_2;
                    if(old_p_0 != uint(best_idx_0))
                    {
                        partition_counts_0[old_p_0] = partition_counts_0[old_p_0] - 1U;
                        partition_counts_0[best_idx_0] = partition_counts_0[best_idx_0] + 1U;
                        _S16[best_idx_0] = best_idx_0;

#line 720
                        problem_2 = true;

#line 716
                    }
                    else
                    {

#line 716
                        problem_2 = problem_1;

#line 716
                    }

#line 716
                    problem_1 = problem_2;

#line 712
                }

#line 710
                best_idx_0 = best_idx_0 + uint8_t(1U);

#line 710
            }

#line 703
            int _S20 = safe_iter_0 + 1;

#line 703
            problem_0 = problem_1;

#line 703
            safe_iter_0 = _S20;

#line 703
        }

#line 602
        iter_0 = iter_0 + 1;

#line 602
    }

#line 727
    return;
}


#line 727
uint16_t RankedSeeds_pack_0(RankedSeeds_0 _S21, out uint16_t  _S22[200], uint _S23)
{

#line 727
    uint16_t i_5 = uint16_t(0US);

#line 727
    uint16_t count_2 = uint16_t(0US);

#line 1261
    for(;;)
    {

#line 1261
        if(int(i_5) < 200)
        {
        }
        else
        {

#line 1261
            break;
        }
        uint16_t seed_4 = RankedSeeds_get_0(_S21, i_5);
        if(seed_4 == uint16_t(0US))
        {
            i_5 = i_5 + uint16_t(1US);

#line 1261
            continue;
        }

#line 1268
        _S22[count_2] = seed_4 - uint16_t(1US);
        uint16_t count_3 = count_2 + uint16_t(1US);
        if(uint(count_3) >= _S23)
        {

#line 1270
            count_2 = count_3;

            break;
        }

#line 1272
        count_2 = count_3;

#line 1261
        i_5 = i_5 + uint16_t(1US);

#line 1261
    }

#line 1275
    return count_2;
}


#line 1275
int find_top_partitions_0(inout CompressedTextureBlock_0 _S24, uint _S25, inout uint16_t  _S26[200], uint _S27)
{

#line 1281
    uint8_t  partition_index_2[16];

#line 1281
    CompressedTextureBlock_cluster_astc_0(_S24, _S25, partition_index_2);


    uint raw_map_2 = CompressedTextureBlock_pack_partition_indices_0(partition_index_2);
    _S24.ideal_partition_map_0 = raw_map_2;

#line 1234
    const uint  _S28[67] = { 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U };
    const uint8_t  _S29[8] = { uint8_t(0U), uint8_t(0U), uint8_t(0U), uint8_t(0U), uint8_t(0U), uint8_t(0U), uint8_t(0U), uint8_t(0U) };

#line 1286
    RankedSeeds_0 ranked_seeds_0 = RankedSeeds_x24init_0(uint8_t(clamp(_S27 / 8U, 4U, 25U)), _S28, _S29, 0U);

#line 1286
    uint16_t i_6 = uint16_t(0US);


    for(;;)
    {

#line 1289
        if(i_6 < uint16_t(1024US))
        {
        }
        else
        {

#line 1289
            break;
        }
        uint8_t permutation_0 = uint8_t(0U);

#line 1291
        uint final_map_0;
        if((_S24.max_partitions_1) == uint8_t(2U))
        {

#line 1292
            final_map_0 = g_lut_0.lut2_0[i_6];

#line 1292
        }
        else
        {

#line 1292
            final_map_0 = g_lut_0.lut3_0[i_6];

#line 1292
        }

#line 1292
        uint8_t perm_distance_0;
        if((_S24.max_partitions_1) == uint8_t(2U))
        {

#line 1293
            uint8_t _S30 = best_perm_distance_s2_0(raw_map_2, final_map_0, permutation_0);

#line 1293
            perm_distance_0 = _S30;

#line 1293
        }
        else
        {

#line 1294
            uint8_t _S31 = best_perm_distance_s3_0(raw_map_2, final_map_0, permutation_0);

#line 1294
            perm_distance_0 = _S31;

#line 1293
        }

        if(perm_distance_0 < uint8_t(8U))
        {
            RankedSeeds_add_0(ranked_seeds_0, i_6, uint16_t(perm_distance_0));

#line 1295
        }

#line 1289
        i_6 = i_6 + uint16_t(1US);

#line 1289
    }

#line 1289
    uint16_t _S32 = RankedSeeds_pack_0(ranked_seeds_0, _S26, _S27);

#line 1301
    return int(_S32);
}


#line 1163
float compute_error_fast_0(CompressedTextureBlock_0 _S33, uint _S34, float _S35)
{

#line 1159
    vec3 _S36 = vec3(ivec3(0));

#line 1159
    vec3  means_0[3];

#line 1159
    means_0[0] = _S36;

#line 1159
    means_0[1] = _S36;

#line 1159
    means_0[2] = _S36;


    const mat3x3 _S37 = mat3x3(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

#line 1162
    mat3x3  scatters_0[3];

#line 1162
    scatters_0[0] = _S37;

#line 1162
    scatters_0[1] = _S37;

#line 1162
    scatters_0[2] = _S37;
    float  counts_3[3];

#line 1163
    counts_3[0] = 0.0;

#line 1163
    counts_3[1] = 0.0;

#line 1163
    counts_3[2] = 0.0;

#line 1163
    int i_7 = 0;

    [[unroll]]
    for(;;)
    {

#line 1165
        if(i_7 < 16)
        {
        }
        else
        {

#line 1165
            break;
        }
        uint p_0 = uint(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S33.partition_index_0, i_7));


        means_0[p_0] = means_0[p_0] + g_groundtruth_0._data[uint(_S34)].pixels_0[i_7];
        counts_3[p_0] = counts_3[p_0] + 1.0;


        scatters_0[p_0][0] = scatters_0[p_0][0] + g_groundtruth_0._data[uint(_S34)].pixels_0[i_7].x * g_groundtruth_0._data[uint(_S34)].pixels_0[i_7];
        scatters_0[p_0][1] = scatters_0[p_0][1] + g_groundtruth_0._data[uint(_S34)].pixels_0[i_7].y * g_groundtruth_0._data[uint(_S34)].pixels_0[i_7];
        scatters_0[p_0][2] = scatters_0[p_0][2] + g_groundtruth_0._data[uint(_S34)].pixels_0[i_7].z * g_groundtruth_0._data[uint(_S34)].pixels_0[i_7];

#line 1165
        i_7 = i_7 + 1;

#line 1165
    }

#line 1165
    uint p_1 = 0U;

#line 1165
    float total_lb_0 = 0.0;

#line 1182
    [[unroll]]
    for(;;)
    {

#line 1182
        if(p_1 < 3U)
        {
        }
        else
        {

#line 1182
            break;
        }
        if(p_1 >= uint(_S33.max_partitions_1))
        {

#line 1185
            break;
        }
        if((counts_3[p_1]) > 0.0)
        {

            mat3x3 correction_0;
            correction_0[0] = means_0[p_1].x * means_0[p_1];
            correction_0[1] = means_0[p_1].y * means_0[p_1];
            correction_0[2] = means_0[p_1].z * means_0[p_1];

            mat3x3 _S38 = scatters_0[p_1] - correction_0 / counts_3[p_1];

#line 1195
            scatters_0[p_1] = _S38;

#line 1195
            total_lb_0 = total_lb_0 + estimate_partition_error_bound_0(_S38, counts_3[p_1]);

#line 1187
        }

#line 1182
        p_1 = p_1 + 1U;

#line 1182
    }

#line 1201
    return total_lb_0;
}


#line 1201
vec3 sample_color_0(vec3 _S39, uint _S40)
{

#line 1201
    float max_dist_0 = 0.0;

#line 1201
    int max_idx_0 = 0;

#line 1201
    int i_8 = 0;

#line 1011
    [[unroll]]
    for(;;)
    {

#line 1011
        if(i_8 < 16)
        {
        }
        else
        {

#line 1011
            break;
        }
        float dist_0 = length(g_groundtruth_0._data[uint(_S40)].pixels_0[i_8] - _S39);
        if(dist_0 > max_dist_0)
        {

#line 1014
            max_dist_0 = dist_0;

#line 1014
            max_idx_0 = i_8;

#line 1014
        }

#line 1011
        i_8 = i_8 + 1;

#line 1011
    }

#line 1020
    return g_groundtruth_0._data[uint(_S40)].pixels_0[max_idx_0];
}


#line 1020
bool solve_pca_eps_0(CompressedTextureBlock_0 _S41, inout vec3 _S42, inout vec3 _S43, uint _S44, int _S45, float _S46)
{

#line 1029
    vec3 _S47 = vec3(ivec3(0));

#line 1029
    int i_9 = 0;

#line 1029
    vec3 centroid_0 = _S47;

#line 1029
    uint count_4 = 0U;



    [[unroll]]
    for(;;)
    {

#line 1033
        if(i_9 < 16)
        {
        }
        else
        {

#line 1033
            break;
        }
        if((NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S41.partition_index_0, i_9)) == _S45)
        {

            uint count_5 = count_4 + 1U;

#line 1038
            centroid_0 = centroid_0 + g_groundtruth_0._data[uint(_S44)].pixels_0[i_9];

#line 1038
            count_4 = count_5;

#line 1035
        }

#line 1033
        i_9 = i_9 + 1;

#line 1033
    }

#line 1041
    float _S48 = float(count_4);

#line 1041
    vec3 centroid_1 = centroid_0 / _S48;

    if(count_4 == 0U)
    {

#line 1044
        return true;
    }
    if(count_4 == 1U)
    {


        bound_and_damp_0(centroid_1, centroid_1, _S42, _S43, _S46);
        return true;
    }

    mat3x3 C_0 = mat3x3(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

#line 1054
    i_9 = 0;

    [[unroll]]
    for(;;)
    {

#line 1056
        if(i_9 < 16)
        {
        }
        else
        {

#line 1056
            break;
        }
        if((NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S41.partition_index_0, i_9)) == _S45)
        {
            vec3 d_4 = g_groundtruth_0._data[uint(_S44)].pixels_0[i_9] - centroid_1;
            C_0[0] = C_0[0] + d_4.x * d_4;
            C_0[1] = C_0[1] + d_4.y * d_4;
            C_0[2] = C_0[2] + d_4.z * d_4;

#line 1058
        }

#line 1056
        i_9 = i_9 + 1;

#line 1056
    }

#line 1066
    C_0 = C_0 / _S48;



    if((C_0[0].x + C_0[1].y + C_0[2].z) < 0.00030000001424924)
    {

#line 1076
        bound_and_damp_0(centroid_1, centroid_1, _S42, _S43, _S46);
        return false;
    }

    const vec3 _S49 = vec3(0.17000000178813934, 0.82999998331069946, 0.37999999523162842);

#line 1080
    int iter_1 = 0;

#line 1080
    vec3 axis_2 = _S49;

    [[unroll]]
    for(;;)
    {

#line 1082
        if(iter_1 < 4)
        {
        }
        else
        {

#line 1082
            break;
        }
        vec3 axis_3 = (((axis_2) * (C_0)));
        float lenSq_0 = dot(axis_3, axis_3);
        if(lenSq_0 > 9.99999993922529029e-09)
        {

#line 1086
            axis_2 = axis_3 * (inversesqrt((lenSq_0)));

#line 1086
        }
        else
        {

#line 1086
            axis_2 = axis_3;

#line 1086
        }

#line 1082
        iter_1 = iter_1 + 1;

#line 1082
    }

#line 1093
    if((dot(axis_2, axis_2)) < 9.99999993922529029e-09)
    {


        bound_and_damp_0(centroid_1, sample_color_0(centroid_1, _S44), _S42, _S43, _S46);
        return false;
    }

    vec3 axis_4 = normalize(axis_2);

#line 1101
    float min_t_0 = 1000.0;

#line 1101
    float max_t_0 = -1000.0;

#line 1101
    i_9 = 0;

#line 1106
    [[unroll]]
    for(;;)
    {

#line 1106
        if(i_9 < 16)
        {
        }
        else
        {

#line 1106
            break;
        }
        if((NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S41.partition_index_0, i_9)) == _S45)
        {

            float t_0 = dot(g_groundtruth_0._data[uint(_S44)].pixels_0[i_9] - centroid_1, axis_4);

            float _S50 = max(max_t_0, t_0);

#line 1113
            min_t_0 = min(min_t_0, t_0);

#line 1113
            max_t_0 = _S50;

#line 1108
        }

#line 1106
        i_9 = i_9 + 1;

#line 1106
    }

#line 1119
    bound_and_damp_0(centroid_1 + axis_4 * min_t_0, centroid_1 + axis_4 * max_t_0, _S42, _S43, _S46);
    return true;
}


#line 1120
void CompressedTextureBlock_solve_weights_0(inout CompressedTextureBlock_0 _S51, uint _S52)
{

#line 570
    vec3 L1_0 = CompressedTextureBlock_ep1_get_0(_S51) - CompressedTextureBlock_ep0_get_0(_S51);
    vec3 L2_0 = CompressedTextureBlock_ep3_get_0(_S51) - CompressedTextureBlock_ep2_get_0(_S51);
    vec3 L3_0 = CompressedTextureBlock_ep5_get_0(_S51) - CompressedTextureBlock_ep4_get_0(_S51);
    float _S53 = 1.0 / (dot(L1_0, L1_0) + 9.99999997475242708e-07);
    float _S54 = 1.0 / (dot(L2_0, L2_0) + 9.99999997475242708e-07);
    float _S55 = 1.0 / (dot(L3_0, L3_0) + 9.99999997475242708e-07);

#line 575
    int i_10 = 0;

    [[unroll]]
    for(;;)
    {

#line 577
        if(i_10 < 16)
        {
        }
        else
        {

#line 577
            break;
        }

#line 577
        vec3 C_1 = g_groundtruth_0._data[uint(_S52)].pixels_0[i_10];


        int p_2 = NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S51.partition_index_0, i_10);
        bool _S56 = p_2 == 0;

#line 581
        float pDotL_0;

#line 581
        if(_S56)
        {

#line 581
            pDotL_0 = dot(C_1 - CompressedTextureBlock_ep0_get_0(_S51), L1_0);

#line 581
        }
        else
        {

#line 581
            if(p_2 == 1)
            {

#line 581
                pDotL_0 = dot(C_1 - CompressedTextureBlock_ep2_get_0(_S51), L2_0);

#line 581
            }
            else
            {

#line 581
                pDotL_0 = dot(C_1 - CompressedTextureBlock_ep4_get_0(_S51), L3_0);

#line 581
            }

#line 581
        }

#line 581
        float invLenSq_0;
        if(_S56)
        {

#line 582
            invLenSq_0 = _S53;

#line 582
        }
        else
        {

#line 582
            if(p_2 == 1)
            {

#line 582
                invLenSq_0 = _S54;

#line 582
            }
            else
            {

#line 582
                invLenSq_0 = _S55;

#line 582
            }

#line 582
        }

        _S51.weights_0.data_0[i_10] = uint8_t(round(saturate_1(saturate_1(pDotL_0 * invLenSq_0)) * 255.0));

#line 577
        i_10 = i_10 + 1;

#line 577
    }

#line 586
    return;
}


#line 586
float loss_mse_0(uint _S57, CompressedTextureBlock_0 _S58)
{

#line 1127
    TextureBlock_0 _S59 = CompressedTextureBlock_decompress3P_0(_S58);

#line 1127
    int i_11 = 0;

#line 1127
    float totalError_0 = 0.0;


    for(;;)
    {

#line 1130
        if(i_11 < 16)
        {
        }
        else
        {

#line 1130
            break;
        }
        vec3 diff_0 = _S59.pixels_0[i_11] - g_groundtruth_0._data[uint(_S57)].pixels_0[i_11];
        float totalError_1 = totalError_0 + dot(diff_0, diff_0);

#line 1130
        i_11 = i_11 + 1;

#line 1130
        totalError_0 = totalError_1;

#line 1130
    }

#line 1136
    return totalError_0;
}


#line 1136
float optimize_0(inout CompressedTextureBlock_0 _S60, uint _S61, uint _S62, bool _S63, uint _S64)
{

#line 1314
    uint max_partitions_2 = uint(_S60.max_partitions_1);

#line 1322
    uint16_t  partitions_0[200];

#line 1322
    partitions_0[0] = uint16_t(0US);

#line 1322
    partitions_0[1] = uint16_t(0US);

#line 1322
    partitions_0[2] = uint16_t(0US);

#line 1322
    partitions_0[3] = uint16_t(0US);

#line 1322
    partitions_0[4] = uint16_t(0US);

#line 1322
    partitions_0[5] = uint16_t(0US);

#line 1322
    partitions_0[6] = uint16_t(0US);

#line 1322
    partitions_0[7] = uint16_t(0US);

#line 1322
    partitions_0[8] = uint16_t(0US);

#line 1322
    partitions_0[9] = uint16_t(0US);

#line 1322
    partitions_0[10] = uint16_t(0US);

#line 1322
    partitions_0[11] = uint16_t(0US);

#line 1322
    partitions_0[12] = uint16_t(0US);

#line 1322
    partitions_0[13] = uint16_t(0US);

#line 1322
    partitions_0[14] = uint16_t(0US);

#line 1322
    partitions_0[15] = uint16_t(0US);

#line 1322
    partitions_0[16] = uint16_t(0US);

#line 1322
    partitions_0[17] = uint16_t(0US);

#line 1322
    partitions_0[18] = uint16_t(0US);

#line 1322
    partitions_0[19] = uint16_t(0US);

#line 1322
    partitions_0[20] = uint16_t(0US);

#line 1322
    partitions_0[21] = uint16_t(0US);

#line 1322
    partitions_0[22] = uint16_t(0US);

#line 1322
    partitions_0[23] = uint16_t(0US);

#line 1322
    partitions_0[24] = uint16_t(0US);

#line 1322
    partitions_0[25] = uint16_t(0US);

#line 1322
    partitions_0[26] = uint16_t(0US);

#line 1322
    partitions_0[27] = uint16_t(0US);

#line 1322
    partitions_0[28] = uint16_t(0US);

#line 1322
    partitions_0[29] = uint16_t(0US);

#line 1322
    partitions_0[30] = uint16_t(0US);

#line 1322
    partitions_0[31] = uint16_t(0US);

#line 1322
    partitions_0[32] = uint16_t(0US);

#line 1322
    partitions_0[33] = uint16_t(0US);

#line 1322
    partitions_0[34] = uint16_t(0US);

#line 1322
    partitions_0[35] = uint16_t(0US);

#line 1322
    partitions_0[36] = uint16_t(0US);

#line 1322
    partitions_0[37] = uint16_t(0US);

#line 1322
    partitions_0[38] = uint16_t(0US);

#line 1322
    partitions_0[39] = uint16_t(0US);

#line 1322
    partitions_0[40] = uint16_t(0US);

#line 1322
    partitions_0[41] = uint16_t(0US);

#line 1322
    partitions_0[42] = uint16_t(0US);

#line 1322
    partitions_0[43] = uint16_t(0US);

#line 1322
    partitions_0[44] = uint16_t(0US);

#line 1322
    partitions_0[45] = uint16_t(0US);

#line 1322
    partitions_0[46] = uint16_t(0US);

#line 1322
    partitions_0[47] = uint16_t(0US);

#line 1322
    partitions_0[48] = uint16_t(0US);

#line 1322
    partitions_0[49] = uint16_t(0US);

#line 1322
    partitions_0[50] = uint16_t(0US);

#line 1322
    partitions_0[51] = uint16_t(0US);

#line 1322
    partitions_0[52] = uint16_t(0US);

#line 1322
    partitions_0[53] = uint16_t(0US);

#line 1322
    partitions_0[54] = uint16_t(0US);

#line 1322
    partitions_0[55] = uint16_t(0US);

#line 1322
    partitions_0[56] = uint16_t(0US);

#line 1322
    partitions_0[57] = uint16_t(0US);

#line 1322
    partitions_0[58] = uint16_t(0US);

#line 1322
    partitions_0[59] = uint16_t(0US);

#line 1322
    partitions_0[60] = uint16_t(0US);

#line 1322
    partitions_0[61] = uint16_t(0US);

#line 1322
    partitions_0[62] = uint16_t(0US);

#line 1322
    partitions_0[63] = uint16_t(0US);

#line 1322
    partitions_0[64] = uint16_t(0US);

#line 1322
    partitions_0[65] = uint16_t(0US);

#line 1322
    partitions_0[66] = uint16_t(0US);

#line 1322
    partitions_0[67] = uint16_t(0US);

#line 1322
    partitions_0[68] = uint16_t(0US);

#line 1322
    partitions_0[69] = uint16_t(0US);

#line 1322
    partitions_0[70] = uint16_t(0US);

#line 1322
    partitions_0[71] = uint16_t(0US);

#line 1322
    partitions_0[72] = uint16_t(0US);

#line 1322
    partitions_0[73] = uint16_t(0US);

#line 1322
    partitions_0[74] = uint16_t(0US);

#line 1322
    partitions_0[75] = uint16_t(0US);

#line 1322
    partitions_0[76] = uint16_t(0US);

#line 1322
    partitions_0[77] = uint16_t(0US);

#line 1322
    partitions_0[78] = uint16_t(0US);

#line 1322
    partitions_0[79] = uint16_t(0US);

#line 1322
    partitions_0[80] = uint16_t(0US);

#line 1322
    partitions_0[81] = uint16_t(0US);

#line 1322
    partitions_0[82] = uint16_t(0US);

#line 1322
    partitions_0[83] = uint16_t(0US);

#line 1322
    partitions_0[84] = uint16_t(0US);

#line 1322
    partitions_0[85] = uint16_t(0US);

#line 1322
    partitions_0[86] = uint16_t(0US);

#line 1322
    partitions_0[87] = uint16_t(0US);

#line 1322
    partitions_0[88] = uint16_t(0US);

#line 1322
    partitions_0[89] = uint16_t(0US);

#line 1322
    partitions_0[90] = uint16_t(0US);

#line 1322
    partitions_0[91] = uint16_t(0US);

#line 1322
    partitions_0[92] = uint16_t(0US);

#line 1322
    partitions_0[93] = uint16_t(0US);

#line 1322
    partitions_0[94] = uint16_t(0US);

#line 1322
    partitions_0[95] = uint16_t(0US);

#line 1322
    partitions_0[96] = uint16_t(0US);

#line 1322
    partitions_0[97] = uint16_t(0US);

#line 1322
    partitions_0[98] = uint16_t(0US);

#line 1322
    partitions_0[99] = uint16_t(0US);

#line 1322
    partitions_0[100] = uint16_t(0US);

#line 1322
    partitions_0[101] = uint16_t(0US);

#line 1322
    partitions_0[102] = uint16_t(0US);

#line 1322
    partitions_0[103] = uint16_t(0US);

#line 1322
    partitions_0[104] = uint16_t(0US);

#line 1322
    partitions_0[105] = uint16_t(0US);

#line 1322
    partitions_0[106] = uint16_t(0US);

#line 1322
    partitions_0[107] = uint16_t(0US);

#line 1322
    partitions_0[108] = uint16_t(0US);

#line 1322
    partitions_0[109] = uint16_t(0US);

#line 1322
    partitions_0[110] = uint16_t(0US);

#line 1322
    partitions_0[111] = uint16_t(0US);

#line 1322
    partitions_0[112] = uint16_t(0US);

#line 1322
    partitions_0[113] = uint16_t(0US);

#line 1322
    partitions_0[114] = uint16_t(0US);

#line 1322
    partitions_0[115] = uint16_t(0US);

#line 1322
    partitions_0[116] = uint16_t(0US);

#line 1322
    partitions_0[117] = uint16_t(0US);

#line 1322
    partitions_0[118] = uint16_t(0US);

#line 1322
    partitions_0[119] = uint16_t(0US);

#line 1322
    partitions_0[120] = uint16_t(0US);

#line 1322
    partitions_0[121] = uint16_t(0US);

#line 1322
    partitions_0[122] = uint16_t(0US);

#line 1322
    partitions_0[123] = uint16_t(0US);

#line 1322
    partitions_0[124] = uint16_t(0US);

#line 1322
    partitions_0[125] = uint16_t(0US);

#line 1322
    partitions_0[126] = uint16_t(0US);

#line 1322
    partitions_0[127] = uint16_t(0US);

#line 1322
    partitions_0[128] = uint16_t(0US);

#line 1322
    partitions_0[129] = uint16_t(0US);

#line 1322
    partitions_0[130] = uint16_t(0US);

#line 1322
    partitions_0[131] = uint16_t(0US);

#line 1322
    partitions_0[132] = uint16_t(0US);

#line 1322
    partitions_0[133] = uint16_t(0US);

#line 1322
    partitions_0[134] = uint16_t(0US);

#line 1322
    partitions_0[135] = uint16_t(0US);

#line 1322
    partitions_0[136] = uint16_t(0US);

#line 1322
    partitions_0[137] = uint16_t(0US);

#line 1322
    partitions_0[138] = uint16_t(0US);

#line 1322
    partitions_0[139] = uint16_t(0US);

#line 1322
    partitions_0[140] = uint16_t(0US);

#line 1322
    partitions_0[141] = uint16_t(0US);

#line 1322
    partitions_0[142] = uint16_t(0US);

#line 1322
    partitions_0[143] = uint16_t(0US);

#line 1322
    partitions_0[144] = uint16_t(0US);

#line 1322
    partitions_0[145] = uint16_t(0US);

#line 1322
    partitions_0[146] = uint16_t(0US);

#line 1322
    partitions_0[147] = uint16_t(0US);

#line 1322
    partitions_0[148] = uint16_t(0US);

#line 1322
    partitions_0[149] = uint16_t(0US);

#line 1322
    partitions_0[150] = uint16_t(0US);

#line 1322
    partitions_0[151] = uint16_t(0US);

#line 1322
    partitions_0[152] = uint16_t(0US);

#line 1322
    partitions_0[153] = uint16_t(0US);

#line 1322
    partitions_0[154] = uint16_t(0US);

#line 1322
    partitions_0[155] = uint16_t(0US);

#line 1322
    partitions_0[156] = uint16_t(0US);

#line 1322
    partitions_0[157] = uint16_t(0US);

#line 1322
    partitions_0[158] = uint16_t(0US);

#line 1322
    partitions_0[159] = uint16_t(0US);

#line 1322
    partitions_0[160] = uint16_t(0US);

#line 1322
    partitions_0[161] = uint16_t(0US);

#line 1322
    partitions_0[162] = uint16_t(0US);

#line 1322
    partitions_0[163] = uint16_t(0US);

#line 1322
    partitions_0[164] = uint16_t(0US);

#line 1322
    partitions_0[165] = uint16_t(0US);

#line 1322
    partitions_0[166] = uint16_t(0US);

#line 1322
    partitions_0[167] = uint16_t(0US);

#line 1322
    partitions_0[168] = uint16_t(0US);

#line 1322
    partitions_0[169] = uint16_t(0US);

#line 1322
    partitions_0[170] = uint16_t(0US);

#line 1322
    partitions_0[171] = uint16_t(0US);

#line 1322
    partitions_0[172] = uint16_t(0US);

#line 1322
    partitions_0[173] = uint16_t(0US);

#line 1322
    partitions_0[174] = uint16_t(0US);

#line 1322
    partitions_0[175] = uint16_t(0US);

#line 1322
    partitions_0[176] = uint16_t(0US);

#line 1322
    partitions_0[177] = uint16_t(0US);

#line 1322
    partitions_0[178] = uint16_t(0US);

#line 1322
    partitions_0[179] = uint16_t(0US);

#line 1322
    partitions_0[180] = uint16_t(0US);

#line 1322
    partitions_0[181] = uint16_t(0US);

#line 1322
    partitions_0[182] = uint16_t(0US);

#line 1322
    partitions_0[183] = uint16_t(0US);

#line 1322
    partitions_0[184] = uint16_t(0US);

#line 1322
    partitions_0[185] = uint16_t(0US);

#line 1322
    partitions_0[186] = uint16_t(0US);

#line 1322
    partitions_0[187] = uint16_t(0US);

#line 1322
    partitions_0[188] = uint16_t(0US);

#line 1322
    partitions_0[189] = uint16_t(0US);

#line 1322
    partitions_0[190] = uint16_t(0US);

#line 1322
    partitions_0[191] = uint16_t(0US);

#line 1322
    partitions_0[192] = uint16_t(0US);

#line 1322
    partitions_0[193] = uint16_t(0US);

#line 1322
    partitions_0[194] = uint16_t(0US);

#line 1322
    partitions_0[195] = uint16_t(0US);

#line 1322
    partitions_0[196] = uint16_t(0US);

#line 1322
    partitions_0[197] = uint16_t(0US);

#line 1322
    partitions_0[198] = uint16_t(0US);

#line 1322
    partitions_0[199] = uint16_t(0US);

#line 1329
    bool _S65 = max_partitions_2 > 1U;

#line 1329
    uint found_0;

#line 1329
    if(_S65)
    {

#line 1329
        int _S66 = find_top_partitions_0(_S60, _S61, partitions_0, _S62);

#line 1329
        found_0 = uint(_S66);

#line 1329
    }
    else
    {

#line 1329
        found_0 = 0U;

#line 1329
    }

#line 1338
    g_diagnostics_0._data[uint(_S64)].partition_count_0[10] = 255U;
    CompressedTextureBlock_0 current_block_0 = _S60;

#line 1339
    float best_loss_0 = 1000.0;

#line 1339
    uint16_t best_seed_0 = uint16_t(0US);

#line 1339
    uint16_t best_candidate_id_0 = uint16_t(0US);

#line 1339
    uint16_t candidate_id_0 = uint16_t(0US);



    for(;;)
    {

#line 1343
        if(uint(candidate_id_0) < found_0)
        {
        }
        else
        {

#line 1343
            break;
        }

        uint16_t _S67 = partitions_0[candidate_id_0];


        CompressedTextureBlock_set_astc_seed_0(current_block_0, partitions_0[candidate_id_0]);

#line 1349
        float _S68 = compute_error_fast_0(current_block_0, _S61, best_loss_0);


        if(_S68 < best_loss_0)
        {

#line 1352
            best_loss_0 = _S68;

#line 1352
            best_seed_0 = _S67;

#line 1352
            best_candidate_id_0 = candidate_id_0;

#line 1352
        }

#line 1352
        bool _S69;

#line 1359
        if(_S63)
        {

#line 1359
            _S69 = candidate_id_0 < uint16_t(10US);

#line 1359
        }
        else
        {

#line 1359
            _S69 = false;

#line 1359
        }

#line 1359
        if(_S69)
        {
            uvec2 _S70 = (clockRealtime2x32EXT());

#line 1361
            g_diagnostics_0._data[uint(_S64)].timestamps_0[candidate_id_0] = _S70;
            g_diagnostics_0._data[uint(_S64)].loss_log_0[candidate_id_0][max_partitions_2 - 1U] = _S68;

#line 1359
        }

#line 1343
        candidate_id_0 = candidate_id_0 + uint16_t(1US);

#line 1343
    }

#line 1368
    if(_S65)
    {
        CompressedTextureBlock_set_astc_seed_0(current_block_0, best_seed_0);

#line 1368
    }



    vec3 _S71 = CompressedTextureBlock_ep0_get_0(current_block_0);

#line 1372
    vec3 _S72 = CompressedTextureBlock_ep1_get_0(current_block_0);

#line 1372
    bool _S73 = solve_pca_eps_0(current_block_0, _S71, _S72, _S61, 0, 1.0);

#line 1372
    current_block_0._ep0_0 = quantize_0(f16vec3(_S71), 255U);

#line 1372
    current_block_0._ep1_0 = quantize_0(f16vec3(_S72), 255U);
    if(_S65)
    {

#line 1374
        vec3 _S74 = CompressedTextureBlock_ep2_get_0(current_block_0);

#line 1374
        vec3 _S75 = CompressedTextureBlock_ep3_get_0(current_block_0);

#line 1374
        bool _S76 = solve_pca_eps_0(current_block_0, _S74, _S75, _S61, 1, 1.0);

#line 1374
        current_block_0._ep2_0 = quantize_0(f16vec3(_S74), 255U);

#line 1374
        current_block_0._ep3_0 = quantize_0(f16vec3(_S75), 255U);

#line 1373
    }

    if(max_partitions_2 > 2U)
    {

#line 1376
        vec3 _S77 = CompressedTextureBlock_ep4_get_0(current_block_0);

#line 1376
        vec3 _S78 = CompressedTextureBlock_ep5_get_0(current_block_0);

#line 1376
        bool _S79 = solve_pca_eps_0(current_block_0, _S77, _S78, _S61, 2, 1.0);

#line 1376
        current_block_0._ep4_0 = quantize_0(f16vec3(_S77), 255U);

#line 1376
        current_block_0._ep5_0 = quantize_0(f16vec3(_S78), 255U);

#line 1375
    }

#line 1375
    CompressedTextureBlock_solve_weights_0(current_block_0, _S61);

#line 1375
    float _S80 = loss_mse_0(_S61, current_block_0);



    if(_S63)
    {
        g_diagnostics_0._data[uint(_S64)].loss_log_0[11][max_partitions_2 - 1U] = _S80;

#line 1379
    }

#line 1384
    _S60 = current_block_0;
    _S60.astc_seed_0 = best_candidate_id_0;
    uint8_t id_0;

#line 1386
    uint8_t _S81;
    if((_S60.max_partitions_1) == uint8_t(2U))
    {

#line 1387
        uint8_t _S82 = best_perm_distance_s2_0(_S60.ideal_partition_map_0, _S60.astc_partition_map_0, id_0);

#line 1387
        _S81 = _S82;

#line 1387
    }
    else
    {

#line 1388
        uint8_t _S83 = best_perm_distance_s3_0(_S60.ideal_partition_map_0, _S60.astc_partition_map_0, id_0);

#line 1388
        _S81 = _S83;

#line 1387
    }

#line 1387
    _S60.perm_0 = _S81;

    return _S80;
}


#line 1389
float optimize_1(inout CompressedTextureBlock_0 _S84, uint _S85, uint _S86, bool _S87, uint _S88)
{

#line 1314
    uint max_partitions_3 = uint(_S84.max_partitions_1);

#line 1338
    g_diagnostics_0._data[uint(_S88)].partition_count_0[10] = 255U;
    CompressedTextureBlock_0 current_block_1 = _S84;

#line 1339
    float best_loss_1 = 1000.0;

#line 1339
    uint16_t best_seed_1 = uint16_t(0US);

#line 1339
    uint16_t best_candidate_id_1 = uint16_t(0US);

#line 1339
    uint16_t candidate_id_1 = uint16_t(0US);



    for(;;)
    {

#line 1343
        if(uint(candidate_id_1) < _S86)
        {
        }
        else
        {

#line 1343
            break;
        }

#line 1349
        CompressedTextureBlock_set_astc_seed_0(current_block_1, candidate_id_1);

#line 1349
        float _S89 = compute_error_fast_0(current_block_1, _S85, best_loss_1);


        if(_S89 < best_loss_1)
        {

#line 1352
            best_loss_1 = _S89;

#line 1352
            best_seed_1 = candidate_id_1;

#line 1352
            best_candidate_id_1 = candidate_id_1;

#line 1352
        }

#line 1352
        bool _S90;

#line 1359
        if(_S87)
        {

#line 1359
            _S90 = candidate_id_1 < uint16_t(10US);

#line 1359
        }
        else
        {

#line 1359
            _S90 = false;

#line 1359
        }

#line 1359
        if(_S90)
        {
            uvec2 _S91 = (clockRealtime2x32EXT());

#line 1361
            g_diagnostics_0._data[uint(_S88)].timestamps_0[candidate_id_1] = _S91;
            g_diagnostics_0._data[uint(_S88)].loss_log_0[candidate_id_1][max_partitions_3 - 1U] = _S89;

#line 1359
        }

#line 1343
        candidate_id_1 = candidate_id_1 + uint16_t(1US);

#line 1343
    }

#line 1368
    bool _S92 = max_partitions_3 > 1U;

#line 1368
    if(_S92)
    {
        CompressedTextureBlock_set_astc_seed_0(current_block_1, best_seed_1);

#line 1368
    }



    vec3 _S93 = CompressedTextureBlock_ep0_get_0(current_block_1);

#line 1372
    vec3 _S94 = CompressedTextureBlock_ep1_get_0(current_block_1);

#line 1372
    bool _S95 = solve_pca_eps_0(current_block_1, _S93, _S94, _S85, 0, 1.0);

#line 1372
    current_block_1._ep0_0 = quantize_0(f16vec3(_S93), 255U);

#line 1372
    current_block_1._ep1_0 = quantize_0(f16vec3(_S94), 255U);
    if(_S92)
    {

#line 1374
        vec3 _S96 = CompressedTextureBlock_ep2_get_0(current_block_1);

#line 1374
        vec3 _S97 = CompressedTextureBlock_ep3_get_0(current_block_1);

#line 1374
        bool _S98 = solve_pca_eps_0(current_block_1, _S96, _S97, _S85, 1, 1.0);

#line 1374
        current_block_1._ep2_0 = quantize_0(f16vec3(_S96), 255U);

#line 1374
        current_block_1._ep3_0 = quantize_0(f16vec3(_S97), 255U);

#line 1373
    }

    if(max_partitions_3 > 2U)
    {

#line 1376
        vec3 _S99 = CompressedTextureBlock_ep4_get_0(current_block_1);

#line 1376
        vec3 _S100 = CompressedTextureBlock_ep5_get_0(current_block_1);

#line 1376
        bool _S101 = solve_pca_eps_0(current_block_1, _S99, _S100, _S85, 2, 1.0);

#line 1376
        current_block_1._ep4_0 = quantize_0(f16vec3(_S99), 255U);

#line 1376
        current_block_1._ep5_0 = quantize_0(f16vec3(_S100), 255U);

#line 1375
    }

#line 1375
    CompressedTextureBlock_solve_weights_0(current_block_1, _S85);

#line 1375
    float _S102 = loss_mse_0(_S85, current_block_1);



    if(_S87)
    {
        g_diagnostics_0._data[uint(_S88)].loss_log_0[11][max_partitions_3 - 1U] = _S102;

#line 1379
    }

#line 1384
    _S84 = current_block_1;
    _S84.astc_seed_0 = best_candidate_id_1;
    uint8_t id_1;

#line 1386
    uint8_t _S103;
    if((_S84.max_partitions_1) == uint8_t(2U))
    {

#line 1387
        uint8_t _S104 = best_perm_distance_s2_0(_S84.ideal_partition_map_0, _S84.astc_partition_map_0, id_1);

#line 1387
        _S103 = _S104;

#line 1387
    }
    else
    {

#line 1388
        uint8_t _S105 = best_perm_distance_s3_0(_S84.ideal_partition_map_0, _S84.astc_partition_map_0, id_1);

#line 1388
        _S103 = _S105;

#line 1387
    }

#line 1387
    _S84.perm_0 = _S103;

    return _S102;
}


#line 1389
u8vec2 CompressedTextureBlock_quantize_0(inout CompressedTextureBlock_0 _S106, uint _S107)
{

#line 1389
    CompressedTextureBlock_0 best_block_0;

#line 1389
    u8vec2 best_wc_0;

#line 1389
    float best_loss_2 = 1000.0;

#line 1389
    int i_12 = 0;

#line 833
    for(;;)
    {

#line 833
        if(i_12 < 9)
        {
        }
        else
        {

#line 833
            break;
        }

#line 833
        u8vec2 wc_0;


        if((_S106.max_partitions_1) == uint8_t(1U))
        {

#line 836
            wc_0 = VALID_1P_QUANTIZATION_RANGES_0[i_12];

#line 836
        }
        else
        {

#line 837
            if((_S106.max_partitions_1) == uint8_t(2U))
            {

#line 837
                wc_0 = VALID_2P_QUANTIZATION_RANGES_0[i_12];

#line 837
            }
            else
            {

#line 837
                wc_0 = VALID_3P_QUANTIZATION_RANGES_0[i_12];

#line 837
            }

#line 836
        }

        uint8_t _S108 = wc_0.x;

#line 838
        if(_S108 == uint8_t(0U))
        {

#line 839
            i_12 = i_12 + 1;

#line 833
            continue;
        }

#line 842
        uint8_t c_1 = wc_0.y;
        CompressedTextureBlock_0 block_0 = _S106;
        uint _S109 = uint(c_1);

#line 844
        block_0._ep0_0 = quantize_0(_S106._ep0_0, _S109);
        block_0._ep1_0 = quantize_0(_S106._ep1_0, _S109);
        block_0._ep2_0 = quantize_0(_S106._ep2_0, _S109);
        block_0._ep3_0 = quantize_0(_S106._ep3_0, _S109);
        block_0._ep4_0 = quantize_0(_S106._ep4_0, _S109);
        block_0._ep5_0 = quantize_0(_S106._ep5_0, _S109);
        NonDifferentiableFP8Weights_quantize_0(block_0.weights_0, _S108);

#line 850
        float _S110 = loss_mse_0(_S107, block_0);

#line 850
        bool _S111;


        if(_S110 < best_loss_2)
        {

#line 853
            _S111 = true;

#line 853
        }
        else
        {

#line 853
            _S111 = i_12 == 0;

#line 853
        }

#line 853
        float best_loss_3;

#line 853
        CompressedTextureBlock_0 best_block_1;

#line 853
        u8vec2 best_wc_1;

#line 853
        if(_S111)
        {

#line 853
            best_loss_3 = _S110;

#line 853
            best_block_1 = block_0;

#line 853
            best_wc_1 = wc_0;

#line 853
        }
        else
        {

#line 853
            best_loss_3 = best_loss_2;

#line 853
            best_block_1 = best_block_0;

#line 853
            best_wc_1 = best_wc_0;

#line 853
        }

#line 853
        best_loss_2 = best_loss_3;

#line 853
        best_block_0 = best_block_1;

#line 853
        best_wc_0 = best_wc_1;

#line 833
        i_12 = i_12 + 1;

#line 833
    }

#line 860
    _S106 = best_block_0;
    _S106.qwc_0 = best_wc_0;
    return best_wc_0;
}


#line 862
TextureBlock_0 CompressedTextureBlock_reconstruct_0(CompressedTextureBlock_0 _S112, uint _S113)
{

#line 862
    int i_13;

#line 862
    vec3 c_2;

#line 867
    if(g_params_0.debug_reconstruction_0)
    {
        TextureBlock_0 outputBlock_1;

#line 869
        i_13 = 0;
        for(;;)
        {

#line 870
            if(i_13 < 16)
            {
            }
            else
            {

#line 870
                break;
            }

            int partition_1 = clamp(int(float(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S112.partition_index_0, i_13))), 0, 2);


            if(partition_1 == 0)
            {

#line 876
                c_2 = vec3(1.0, 1.0, 1.0);

#line 876
            }
            else
            {

#line 876
                if(partition_1 == 1)
                {

#line 876
                    c_2 = vec3(0.5, 0.5, 0.5);

#line 876
                }
                else
                {

#line 876
                    c_2 = vec3(0.0, 0.0, 0.0);

#line 876
                }

#line 876
            }
            outputBlock_1.pixels_0[i_13] = c_2;

#line 870
            i_13 = i_13 + 1;

#line 870
        }

#line 879
        return outputBlock_1;
    }
    if(g_params_0.debug_loss_0)
    {
        TextureBlock_0 outputBlock_2;

#line 883
        i_13 = 0;
        for(;;)
        {

#line 884
            if(i_13 < 16)
            {
            }
            else
            {

#line 884
                break;
            }
            float w_1 = NonDifferentiableFP8Weights_operatorx5Bx5D_get_0(_S112.weights_0, i_13);
            int partition_2 = clamp(NonDifferentiableIntPartitions_operatorx5Bx5D_get_0(_S112.partition_index_0, i_13), 0, 2);
            bool _S114 = partition_2 == 0;

#line 888
            if(_S114)
            {

#line 888
                c_2 = CompressedTextureBlock_ep0_get_0(_S112);

#line 888
            }
            else
            {

#line 888
                if(partition_2 == 1)
                {

#line 888
                    c_2 = CompressedTextureBlock_ep2_get_0(_S112);

#line 888
                }
                else
                {

#line 888
                    c_2 = CompressedTextureBlock_ep4_get_0(_S112);

#line 888
                }

#line 888
            }

#line 888
            vec3 e1_1;
            if(_S114)
            {

#line 889
                e1_1 = CompressedTextureBlock_ep1_get_0(_S112);

#line 889
            }
            else
            {

#line 889
                if(partition_2 == 1)
                {

#line 889
                    e1_1 = CompressedTextureBlock_ep3_get_0(_S112);

#line 889
                }
                else
                {

#line 889
                    e1_1 = CompressedTextureBlock_ep5_get_0(_S112);

#line 889
                }

#line 889
            }

            outputBlock_2.pixels_0[i_13] = abs(g_groundtruth_0._data[uint(_S113)].pixels_0[i_13] - mix(c_2, e1_1, vec3(w_1)));

#line 884
            i_13 = i_13 + 1;

#line 884
        }

#line 893
        return outputBlock_2;
    }
    if(g_params_0.debug_quant_0)
    {
        TextureBlock_0 outputBlock_3;

#line 897
        i_13 = 0;
        for(;;)
        {

#line 898
            if(i_13 < 16)
            {
            }
            else
            {

#line 898
                break;
            }

#line 907
            const vec3 _S115 = vec3(1.0, 0.0, 0.0);
            const vec3 _S116 = vec3(0.0, 1.0, 0.0);
            const vec3 _S117 = vec3(0.0, 0.0, 1.0);
            const vec3 _S118 = vec3(1.0, 0.0, 1.0);
            vec3 _S119 = vec3(ivec3(0));
            switch(_S112.qwc_0.y)
            {
            case uint8_t(5U):
                {

#line 912
                    c_2 = _S115 * 0.33000001311302185;



                    break;
                }
            case uint8_t(7U):
                {

#line 916
                    c_2 = _S115 * 0.67000001668930054;


                    break;
                }
            case uint8_t(9U):
                {

#line 919
                    c_2 = _S115;


                    break;
                }
            case uint8_t(11U):
                {

#line 922
                    c_2 = _S117 * 0.33000001311302185;



                    break;
                }
            case uint8_t(15U):
                {

#line 926
                    c_2 = _S117 * 0.5;


                    break;
                }
            case uint8_t(23U):
                {

#line 929
                    c_2 = _S117;


                    break;
                }
            case uint8_t(31U):
                {

#line 932
                    c_2 = _S116 * 0.33000001311302185;



                    break;
                }
            case uint8_t(33U):
                {

#line 936
                    c_2 = _S116 * 0.5;


                    break;
                }
            case uint8_t(39U):
                {

#line 939
                    c_2 = _S116;


                    break;
                }
            case uint8_t(63U):
                {

#line 942
                    c_2 = _S118 * 0.33000001311302185;



                    break;
                }
            case uint8_t(95U):
                {

#line 946
                    c_2 = _S118 * 0.67000001668930054;


                    break;
                }
            case uint8_t(191U):
                {

#line 949
                    c_2 = _S118 * 0.89999997615814209;


                    break;
                }
            case uint8_t(255U):
                {

#line 952
                    c_2 = _S118;


                    break;
                }
            default:
                {

#line 955
                    c_2 = _S119;

#line 955
                    break;
                }
            }
            outputBlock_3.pixels_0[i_13] = c_2;

#line 898
            i_13 = i_13 + 1;

#line 898
        }

#line 960
        return outputBlock_3;
    }
    return CompressedTextureBlock_decompress3P_0(_S112);
}


#line 1395
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 1397
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_params_0.num_blocks_0))
    {

#line 1399
        return;
    }

#line 1400
    uvec2 _S120 = (clockRealtime2x32EXT());

#line 1400
    g_diagnostics_0._data[uint(blockIdx_0)].start_clock_0 = _S120;

#line 1406
    CompressedTextureBlock_0 block_1;
    block_1.max_partitions_1 = g_params_0.max_partitions_0;

    CompressedTextureBlock_0 block1_0 = block_1;
    CompressedTextureBlock_0 block2_0 = block_1;
    CompressedTextureBlock_0 block3_0 = block_1;

#line 1417
    bool _S121 = g_params_0.exhaustive_0;

    uint steps_1 = g_params_0.steps_0;

#line 1419
    float loss2_0;

#line 1419
    float loss3_0;

#line 1419
    float loss1_0;

#line 1419
    float loss_0;
    if(g_params_0.ensemble_0)
    {

        block1_0.max_partitions_1 = uint8_t(1U);

#line 1423
        float _S122 = optimize_0(block1_0, blockIdx_0, steps_1, true, blockIdx_0);


        block2_0.max_partitions_1 = uint8_t(2U);
        if(_S121)
        {

#line 1427
            float _S123 = optimize_1(block2_0, blockIdx_0, steps_1, true, blockIdx_0);

#line 1427
            loss2_0 = _S123;

#line 1427
        }
        else
        {

#line 1427
            float _S124 = optimize_0(block2_0, blockIdx_0, steps_1, true, blockIdx_0);

#line 1427
            loss2_0 = _S124;

#line 1427
        }


        if((g_params_0.max_partitions_0) == uint8_t(3U))
        {
            block3_0.max_partitions_1 = uint8_t(3U);
            if(_S121)
            {

#line 1433
                float _S125 = optimize_1(block3_0, blockIdx_0, steps_1, true, blockIdx_0);

#line 1433
                loss3_0 = _S125;

#line 1433
            }
            else
            {

#line 1433
                float _S126 = optimize_0(block3_0, blockIdx_0, steps_1, true, blockIdx_0);

#line 1433
                loss3_0 = _S126;

#line 1433
            }

#line 1430
        }
        else
        {

#line 1430
            loss3_0 = 0.0;

#line 1430
        }

#line 1430
        loss1_0 = _S122;

#line 1430
        loss_0 = 0.0;

#line 1420
    }
    else
    {

#line 1440
        block_1.max_partitions_1 = g_params_0.max_partitions_0;

#line 1440
        float _S127 = optimize_0(block_1, blockIdx_0, steps_1, true, blockIdx_0);

#line 1440
        loss3_0 = 0.0;

#line 1440
        loss2_0 = 0.0;

#line 1440
        loss1_0 = 0.0;

#line 1440
        loss_0 = _S127;

#line 1420
    }

#line 1444
    uvec2 _S128 = (clockRealtime2x32EXT());

#line 1444
    g_diagnostics_0._data[uint(blockIdx_0)].optim_ended_clock_0 = _S128;

#line 1444
    float final_loss_0;


    if(!g_params_0.no_quantization_0)
    {
        if(g_params_0.ensemble_0)
        {

#line 1449
            u8vec2 _S129 = CompressedTextureBlock_quantize_0(block1_0, blockIdx_0);

#line 1449
            float _S130 = loss_mse_0(blockIdx_0, block1_0);

#line 1449
            u8vec2 _S131 = CompressedTextureBlock_quantize_0(block2_0, blockIdx_0);

#line 1449
            float _S132 = loss_mse_0(blockIdx_0, block2_0);

#line 1449
            float quantized_loss3_0;

#line 1456
            if((g_params_0.max_partitions_0) == uint8_t(3U))
            {

#line 1456
                u8vec2 _S133 = CompressedTextureBlock_quantize_0(block3_0, blockIdx_0);

#line 1456
                quantized_loss3_0 = loss_mse_0(blockIdx_0, block3_0);

#line 1456
            }
            else
            {

#line 1456
                quantized_loss3_0 = 1000.0;

#line 1456
            }

#line 1456
            bool _S134;

#line 1461
            if(quantized_loss3_0 < _S132)
            {

#line 1461
                _S134 = quantized_loss3_0 < _S130;

#line 1461
            }
            else
            {

#line 1461
                _S134 = false;

#line 1461
            }

#line 1461
            if(_S134)
            {
                g_diagnostics_0._data[uint(blockIdx_0)].final_unquantized_loss_0 = loss3_0;
                block_1 = block3_0;

#line 1464
                final_loss_0 = quantized_loss3_0;

#line 1461
            }
            else
            {



                if(_S132 < _S130)
                {
                    g_diagnostics_0._data[uint(blockIdx_0)].final_unquantized_loss_0 = loss2_0;
                    block_1 = block2_0;

#line 1470
                    final_loss_0 = _S132;

#line 1467
                }
                else
                {

#line 1475
                    g_diagnostics_0._data[uint(blockIdx_0)].final_unquantized_loss_0 = loss1_0;
                    block_1 = block1_0;

#line 1476
                    final_loss_0 = _S130;

#line 1467
                }

#line 1461
            }

#line 1449
        }
        else
        {

#line 1482
            g_diagnostics_0._data[uint(blockIdx_0)].final_unquantized_loss_0 = loss_0;

#line 1482
            u8vec2 _S135 = CompressedTextureBlock_quantize_0(block_1, blockIdx_0);

#line 1482
            final_loss_0 = loss_mse_0(blockIdx_0, block_1);

#line 1449
        }

#line 1447
    }
    else
    {

#line 1447
        final_loss_0 = loss_mse_0(blockIdx_0, block_1);

#line 1447
    }

#line 1491
    g_compressedBlock3P_0._data[uint(blockIdx_0)] = block_1;
    g_reconstructed_0._data[uint(blockIdx_0)] = CompressedTextureBlock_reconstruct_0(block_1, blockIdx_0);

    g_final_loss_0._data[uint(blockIdx_0)] = final_loss_0;
    uvec2 _S136 = (clockRealtime2x32EXT());

#line 1495
    g_diagnostics_0._data[uint(blockIdx_0)].finished_clock_0 = _S136;
    return;
}

