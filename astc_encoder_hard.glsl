#version 450
#extension GL_EXT_shader_8bit_storage : require
#extension GL_EXT_shader_explicit_arithmetic_types : require
#extension GL_EXT_shader_16bit_storage : require
#extension GL_EXT_shader_realtime_clock : require
#extension GL_EXT_control_flow_attributes : require
layout(row_major) uniform;
layout(row_major) buffer;

#line 32 0
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


#line 51
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

#line 18
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


#line 62
layout(std430, binding = 3) buffer StructuredBuffer_Diagnostics_t_0 {
    Diagnostics_0 _data[];
} g_diagnostics_0;

#line 232
struct BF8Weights_0
{
    uint8_t  data_0[16];
};


#line 257
struct PartitionMap_0
{
    uint data_1;
};


#line 287
struct CompressedTextureBlockPayload_0
{
    uint8_t perm_0;
    u8vec3 _ep0_0;
    u8vec3 _ep1_0;
    u8vec3 _ep2_0;
    u8vec3 _ep3_0;
    u8vec3 _ep4_0;
    u8vec3 _ep5_0;
    BF8Weights_0 weights_0;
    PartitionMap_0 partition_map_0;
    PartitionMap_0 ideal_partition_map_0;
    uint16_t astc_seed_0;
    uint8_t max_partitions_1;
    u8vec2 qwc_0;
};


#line 919
struct RankedSeeds_0
{
    uint8_t slots_0;
    uint  seeds_masks_0[43];
    uint8_t  counts_0[8];
};


#line 84
struct Scratch_0
{
    uint16_t  partitions_0[256];
    CompressedTextureBlockPayload_0  blocks_0[3];
    RankedSeeds_0 ranked_seeds_0;
};

layout(std430, binding = 7) buffer StructuredBuffer_Scratch_t_0 {
    Scratch_0 _data[];
} g_scratch_0;

#line 65
layout(std430, binding = 4) buffer StructuredBuffer_CompressedTextureBlockPayload_t_0 {
    CompressedTextureBlockPayload_0 _data[];
} g_compressedBlock3P_0;

#line 2
struct TextureBlock_0
{
    u8vec3  pixels_0[16];
};


#line 54
layout(std430, binding = 1) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;

#line 74
struct LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
};


#line 79
layout(binding = 6)
layout(std140) uniform block_LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
}g_lut_0;

#line 59
layout(std430, binding = 2) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;

#line 68
layout(std430, binding = 5) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 119
const u8vec2  VALID_3P_QUANTIZATION_RANGES_0[9] = { u8vec2(uint8_t(7U), uint8_t(5U)), u8vec2(uint8_t(5U), uint8_t(7U)), u8vec2(uint8_t(4U), uint8_t(9U)), u8vec2(uint8_t(3U), uint8_t(11U)), u8vec2(uint8_t(2U), uint8_t(15U)), u8vec2(uint8_t(1U), uint8_t(23U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)) };

#line 106
const u8vec2  VALID_2P_QUANTIZATION_RANGES_0[9] = { u8vec2(uint8_t(15U), uint8_t(5U)), u8vec2(uint8_t(11U), uint8_t(9U)), u8vec2(uint8_t(9U), uint8_t(11U)), u8vec2(uint8_t(7U), uint8_t(15U)), u8vec2(uint8_t(5U), uint8_t(23U)), u8vec2(uint8_t(4U), uint8_t(31U)), u8vec2(uint8_t(3U), uint8_t(39U)), u8vec2(uint8_t(2U), uint8_t(63U)), u8vec2(uint8_t(1U), uint8_t(95U)) };

#line 93
const u8vec2  VALID_1P_QUANTIZATION_RANGES_0[9] = { u8vec2(uint8_t(31U), uint8_t(31U)), u8vec2(uint8_t(23U), uint8_t(63U)), u8vec2(uint8_t(19U), uint8_t(95U)), u8vec2(uint8_t(15U), uint8_t(191U)), u8vec2(uint8_t(11U), uint8_t(255U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)), u8vec2(uint8_t(0U), uint8_t(0U)) };

#line 452
const float16_t  kClusterCutoffs_0[9] = { 0.6259765625HF, 0.9326171875HF, 0.275390625HF, 0.318603515625HF, 0.2401123046875HF, 0.00919342041015625HF, 0.34765625HF, 0.73193359375HF, 0.1563720703125HF };

#line 1069
uint blockIdx_0;


#line 132
struct PCG32_0
{
    uint state_0;
};


#line 136
PCG32_0 PCG32_x24init_0(uint seed_1)
{

#line 136
    PCG32_0 _S1;

    uint _S2 = seed_1 * 747796405U + 2891336453U;
    uint _S3 = ((_S2 >> ((_S2 >> 28U) + 4U)) ^ _S2) * 277803737U;
    _S1.state_0 = (_S3 >> 22U) ^ _S3;

#line 136
    return _S1;
}


#line 316
struct CompressedTextureBlockProxyPayload_0
{
    int8_t index_0;
};


#line 348
uint8_t CompressedTextureBlockProxyPayload_max_partitions_get_0(CompressedTextureBlockProxyPayload_0 this_0)
{

#line 348
    uint8_t _S4;

#line 319
    if((this_0.index_0) >= int8_t(0))
    {

#line 319
        _S4 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_0.index_0].max_partitions_1;

#line 319
    }
    else
    {

#line 319
        _S4 = g_compressedBlock3P_0._data[uint(blockIdx_0)].max_partitions_1;

#line 319
    }

#line 349
    return _S4;
}


#line 380
struct CompressedTextureBlock_0
{
    CompressedTextureBlockProxyPayload_0 payload_0;
};


#line 406
uint8_t CompressedTextureBlock_max_partitions_get_0(CompressedTextureBlock_0 this_1)
{

#line 407
    return CompressedTextureBlockProxyPayload_max_partitions_get_0(this_1.payload_0);
}


#line 262
uint8_t PartitionMap_operatorx5Bx5D_get_0(PartitionMap_0 this_2, int n_0)
{

#line 263
    return uint8_t(((this_2.data_1) >> (n_0 * 2)) & 3U);
}


#line 151
uint PCG32_nextUint_0(inout PCG32_0 this_3)
{
    uint oldState_0 = this_3.state_0;
    this_3.state_0 = this_3.state_0 * 747796405U + 2891336453U;
    uint word_0 = ((oldState_0 >> ((oldState_0 >> 28U) + 4U)) ^ oldState_0) * 277803737U;
    return (word_0 >> 22U) ^ word_0;
}


#line 460
f16vec3 TextureBlock_operatorx5Bx5D_get_0(uint _S5, uint _S6)
{

#line 9
    return f16vec3(g_groundtruth_0._data[uint(_S5)].pixels_0[_S6]) / 255.0HF;
}


#line 458
void CompressedTextureBlock_cluster_astc_0(CompressedTextureBlock_0 this_4, inout PartitionMap_0 partition_map_1)
{
    f16vec3  centroids_0[4];
    uint8_t _S7 = CompressedTextureBlock_max_partitions_get_0(this_4);
    PCG32_0 prng_0 = PCG32_x24init_0(g_params_0.seed_0);

#line 462
    int iter_0 = 0;

    for(;;)
    {

#line 464
        if(iter_0 < 3)
        {
        }
        else
        {

#line 464
            break;
        }

#line 464
        int i_0;

#line 464
        int safe_iter_0;

#line 464
        uint c_0;

#line 464
        float16_t best_dist_0;

        if(iter_0 == 0)
        {

            centroids_0[0] = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, 8U);
            float16_t  dists_0[16];

#line 470
            i_0 = 0;
            for(;;)
            {

#line 471
                if(i_0 < 16)
                {
                }
                else
                {

#line 471
                    break;
                }
                f16vec3 d_0 = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_0)) - centroids_0[0];
                dists_0[i_0] = dot(d_0, d_0);

#line 471
                i_0 = i_0 + 1;

#line 471
            }

#line 471
            c_0 = 1U;

#line 478
            for(;;)
            {

#line 478
                if(c_0 < uint(_S7))
                {
                }
                else
                {

#line 478
                    break;
                }

#line 478
                safe_iter_0 = 0;

#line 478
                best_dist_0 = 0.0HF;


                for(;;)
                {

#line 481
                    if(safe_iter_0 < 16)
                    {
                    }
                    else
                    {

#line 481
                        break;
                    }

#line 482
                    float16_t total_dist_0 = best_dist_0 + dists_0[safe_iter_0];

#line 481
                    safe_iter_0 = safe_iter_0 + 1;

#line 481
                    best_dist_0 = total_dist_0;

#line 481
                }

#line 481
                uint selected_sample_0;



                float16_t _S8 = best_dist_0 * kClusterCutoffs_0[c_0 - 1U + uint(uint8_t(3U) * (_S7 - uint8_t(2U)))];

#line 485
                uint sample_0 = 0U;

#line 485
                float16_t running_sum_0 = 0.0HF;

#line 490
                for(;;)
                {

#line 490
                    if(sample_0 < 16U)
                    {
                    }
                    else
                    {

#line 490
                        selected_sample_0 = 0U;

#line 490
                        break;
                    }
                    float16_t running_sum_1 = running_sum_0 + dists_0[sample_0];
                    if(running_sum_1 >= _S8)
                    {

#line 493
                        selected_sample_0 = sample_0;


                        break;
                    }

#line 490
                    sample_0 = sample_0 + 1U;

#line 490
                    running_sum_0 = running_sum_1;

#line 490
                }

#line 500
                centroids_0[c_0] = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, selected_sample_0);

#line 500
                int t2_0 = 0;

                for(;;)
                {

#line 502
                    if(t2_0 < 16)
                    {
                    }
                    else
                    {

#line 502
                        break;
                    }
                    f16vec3 d_1 = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(t2_0)) - centroids_0[c_0];
                    dists_0[t2_0] = min(dists_0[t2_0], dot(d_1, d_1));

#line 502
                    t2_0 = t2_0 + 1;

#line 502
                }

#line 478
                c_0 = c_0 + 1U;

#line 478
            }

#line 466
        }
        else
        {

#line 511
            const f16vec3 _S9 = f16vec3(0.0HF, 0.0HF, 0.0HF);

#line 511
            f16vec3  color_sums_0[4];

#line 511
            color_sums_0[0] = _S9;

#line 511
            color_sums_0[1] = _S9;

#line 511
            color_sums_0[2] = _S9;

#line 511
            color_sums_0[3] = _S9;
            uint  counts_1[4];

#line 512
            counts_1[0] = 0U;

#line 512
            counts_1[1] = 0U;

#line 512
            counts_1[2] = 0U;

#line 512
            counts_1[3] = 0U;

#line 512
            i_0 = 0;

            for(;;)
            {

#line 514
                if(i_0 < 16)
                {
                }
                else
                {

#line 514
                    break;
                }
                uint p_idx_0 = uint(PartitionMap_operatorx5Bx5D_get_0(partition_map_1, i_0));
                color_sums_0[p_idx_0] = color_sums_0[p_idx_0] + TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_0));
                counts_1[p_idx_0] = counts_1[p_idx_0] + 1U;

#line 514
                i_0 = i_0 + 1;

#line 514
            }

#line 514
            c_0 = 0U;

#line 521
            for(;;)
            {

#line 521
                if(c_0 < uint(_S7))
                {
                }
                else
                {

#line 521
                    break;
                }
                if((counts_1[c_0]) > 0U)
                {
                    centroids_0[c_0] = color_sums_0[c_0] / float16_t(counts_1[c_0]);

#line 523
                }
                else
                {



                    centroids_0[c_0] = _S9;

#line 523
                }

#line 521
                c_0 = c_0 + 1U;

#line 521
            }

#line 466
        }

#line 466
        uint8_t best_idx_0;

#line 534
        uint  partition_counts_0[4];

#line 534
        partition_counts_0[0] = 0U;

#line 534
        partition_counts_0[1] = 0U;

#line 534
        partition_counts_0[2] = 0U;

#line 534
        partition_counts_0[3] = 0U;

#line 534
        i_0 = 0;
        for(;;)
        {

#line 535
            if(i_0 < 16)
            {
            }
            else
            {

#line 535
                break;
            }

#line 535
            best_dist_0 = 1000.0HF;

#line 535
            best_idx_0 = uint8_t(0U);

#line 535
            uint8_t j_0 = uint8_t(0U);

#line 540
            for(;;)
            {

#line 540
                if(j_0 < _S7)
                {
                }
                else
                {

#line 540
                    break;
                }
                uint _S10 = uint(i_0);

#line 542
                float16_t d_2 = dot(TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, _S10) - centroids_0[j_0], TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, _S10) - centroids_0[j_0]);
                if(d_2 < best_dist_0)
                {

#line 543
                    best_dist_0 = d_2;

#line 543
                    best_idx_0 = j_0;

#line 543
                }

#line 540
                j_0 = j_0 + uint8_t(1U);

#line 540
            }

#line 549
            int _S11 = i_0 * 2;

#line 549
            partition_map_1.data_1 = ((partition_map_1.data_1) & uint(~(3 << _S11))) | uint(best_idx_0 << _S11);
            partition_counts_0[best_idx_0] = partition_counts_0[best_idx_0] + 1U;

#line 535
            i_0 = i_0 + 1;

#line 535
        }

#line 535
        bool problem_0 = true;

#line 535
        safe_iter_0 = 0;

#line 555
        for(;;)
        {

#line 555
            if(safe_iter_0 < 4)
            {
            }
            else
            {

#line 555
                break;
            }
            if(!problem_0)
            {

#line 558
                break;
            }

#line 558
            bool problem_1 = false;

#line 558
            best_idx_0 = uint8_t(0U);


            for(;;)
            {

#line 561
                if(best_idx_0 < _S7)
                {
                }
                else
                {

#line 561
                    break;
                }
                if((partition_counts_0[best_idx_0]) == 0U)
                {

                    uint _S12 = PCG32_nextUint_0(prng_0);

#line 566
                    uint old_p_0 = uint(PartitionMap_operatorx5Bx5D_get_0(partition_map_1, int(_S12 % 16U)));

#line 566
                    bool problem_2;
                    if(old_p_0 != uint(best_idx_0))
                    {
                        partition_counts_0[old_p_0] = partition_counts_0[old_p_0] - 1U;
                        partition_counts_0[best_idx_0] = partition_counts_0[best_idx_0] + 1U;
                        int _S13 = int(best_idx_0) * 2;

#line 571
                        partition_map_1.data_1 = ((partition_map_1.data_1) & uint(~(3 << _S13))) | uint(best_idx_0 << _S13);

#line 571
                        problem_2 = true;

#line 567
                    }
                    else
                    {

#line 567
                        problem_2 = problem_1;

#line 567
                    }

#line 567
                    problem_1 = problem_2;

#line 563
                }

#line 561
                best_idx_0 = best_idx_0 + uint8_t(1U);

#line 561
            }

#line 555
            int _S14 = safe_iter_0 + 1;

#line 555
            problem_0 = problem_1;

#line 555
            safe_iter_0 = _S14;

#line 555
        }

#line 464
        iter_0 = iter_0 + 1;

#line 464
    }

#line 578
    return;
}


#line 913
shared RankedSeeds_0  s_ranked_seeds_0[64];


#line 919
RankedSeeds_0 RankedSeeds_x24init_0(uint8_t slots_1, uint  seeds_masks_1[43], uint8_t  counts_2[8])
{

#line 919
    RankedSeeds_0 _S15;

    _S15.slots_0 = slots_1;

#line 928
    _S15.seeds_masks_0 = seeds_masks_1;
    _S15.counts_0 = counts_2;

#line 919
    return _S15;
}


#line 215
uint8_t count_diffs_0(uint val_0)
{
    return uint8_t(bitCount((val_0 | (val_0 >> 1)) & 1431655765U));
}


#line 192
uint8_t best_perm_distance_s2_0(uint x_0, uint y_0)
{
    uint base_0 = x_0 ^ y_0;

#line 204
    return uint8_t((min(uint(((count_diffs_0(base_0)) << 1) | uint8_t(0U)), uint(((count_diffs_0(base_0 ^ ((~(x_0 >> 1)) & 1431655765U))) << 1) | uint8_t(1U)))) >> 1);
}


#line 163
uint8_t best_perm_distance_s3_0(uint x_1, uint y_1)
{
    uint base_1 = x_1 ^ y_1;

    uint x_shr1_0 = x_1 >> 1;
    uint nz_0 = (x_1 | x_shr1_0) & 1431655765U;
    uint nz_shl1_0 = nz_0 << 1;

    uint m01_0 = (~x_shr1_0) & 1431655765U;

#line 189
    return uint8_t((min(min(min(uint(((count_diffs_0(base_1)) << 3) | uint8_t(0U)), uint(((count_diffs_0(base_1 ^ m01_0)) << 3) | uint8_t(1U))), min(uint(((count_diffs_0(base_1 ^ ((~(x_1 << 1)) & 2863311530U))) << 3) | uint8_t(2U)), uint(((count_diffs_0(base_1 ^ (nz_0 | nz_shl1_0))) << 3) | uint8_t(3U)))), min(uint(((count_diffs_0(base_1 ^ (m01_0 | nz_shl1_0))) << 3) | uint8_t(4U)), uint(((count_diffs_0(base_1 ^ (nz_0 | (((~x_1) & 1431655765U) << 1)))) << 3) | uint8_t(5U))))) >> 3);
}


#line 939
void RankedSeeds_add_0(uint16_t seed_2, uint16_t distance_0)
{
    uint8_t count_0 = s_ranked_seeds_0[blockIdx_0 % 64U].counts_0[distance_0];
    if((s_ranked_seeds_0[blockIdx_0 % 64U].counts_0[distance_0]) < (s_ranked_seeds_0[blockIdx_0 % 64U].slots_0))
    {
        uint16_t _S16 = distance_0 * uint16_t(16US) + uint16_t(count_0);

        s_ranked_seeds_0[blockIdx_0 % 64U].seeds_masks_0[_S16 / uint16_t(3US)] = (s_ranked_seeds_0[blockIdx_0 % 64U].seeds_masks_0[_S16 / uint16_t(3US)]) | (uint(seed_2 + uint16_t(1US)) << uint(_S16 % uint16_t(3US) * uint16_t(10US)));
        s_ranked_seeds_0[blockIdx_0 % 64U].counts_0[distance_0] = s_ranked_seeds_0[blockIdx_0 % 64U].counts_0[distance_0] + uint8_t(1U);

#line 942
    }

#line 949
    return;
}


#line 932
uint16_t RankedSeeds_get_0(uint16_t n_1)
{
    return uint16_t((s_ranked_seeds_0[blockIdx_0 % 64U].seeds_masks_0[n_1 / uint16_t(3US)]) >> uint(n_1 % uint16_t(3US) * uint16_t(10US))) & uint16_t(1023US);
}


#line 951
uint16_t RankedSeeds_pack_0(uint max_items_0)
{

#line 951
    uint16_t i_1 = uint16_t(0US);

#line 951
    uint16_t count_1 = uint16_t(0US);


    for(;;)
    {

#line 954
        if(int(i_1) < 128)
        {
        }
        else
        {

#line 954
            break;
        }
        uint16_t seed_3 = RankedSeeds_get_0(i_1);
        if(seed_3 == uint16_t(0US))
        {
            i_1 = i_1 + uint16_t(1US);

#line 954
            continue;
        }

#line 961
        g_scratch_0._data[uint(blockIdx_0)].partitions_0[count_1] = seed_3 - uint16_t(1US);
        uint16_t count_2 = count_1 + uint16_t(1US);
        if(uint(count_2) >= max_items_0)
        {

#line 963
            count_1 = count_2;

            break;
        }

#line 965
        count_1 = count_2;

#line 954
        i_1 = i_1 + uint16_t(1US);

#line 954
    }

#line 968
    return count_1;
}

int find_top_partitions_0(inout CompressedTextureBlock_0 block_0, uint candidates_0)
{
    PartitionMap_0 ideal_map_0;
    CompressedTextureBlock_cluster_astc_0(block_0, ideal_map_0);
    PartitionMap_0 _S17 = ideal_map_0;

#line 975
    if((block_0.payload_0.index_0) >= int8_t(0))
    {

#line 975
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_0.payload_0.index_0].ideal_partition_map_0 = _S17;

#line 975
    }
    else
    {

#line 975
        g_compressedBlock3P_0._data[uint(blockIdx_0)].ideal_partition_map_0 = _S17;

#line 975
    }

#line 928
    const uint  _S18[43] = { 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U };
    const uint8_t  _S19[8] = { uint8_t(0U), uint8_t(0U), uint8_t(0U), uint8_t(0U), uint8_t(0U), uint8_t(0U), uint8_t(0U), uint8_t(0U) };

#line 976
    s_ranked_seeds_0[blockIdx_0 % 64U] = RankedSeeds_x24init_0(uint8_t(clamp(candidates_0 / 8U, 2U, 16U)), _S18, _S19);

#line 976
    uint16_t i_2 = uint16_t(0US);


    for(;;)
    {

#line 979
        if(i_2 < uint16_t(1024US))
        {
        }
        else
        {

#line 979
            break;
        }

#line 979
        uint final_map_0;

        if((CompressedTextureBlock_max_partitions_get_0(block_0)) == uint8_t(2U))
        {

#line 981
            final_map_0 = g_lut_0.lut2_0[i_2];

#line 981
        }
        else
        {

#line 981
            final_map_0 = g_lut_0.lut3_0[i_2];

#line 981
        }

#line 981
        uint8_t perm_distance_0;
        if((CompressedTextureBlock_max_partitions_get_0(block_0)) == uint8_t(2U))
        {

#line 982
            perm_distance_0 = best_perm_distance_s2_0(ideal_map_0.data_1, final_map_0);

#line 982
        }
        else
        {

#line 982
            perm_distance_0 = best_perm_distance_s3_0(ideal_map_0.data_1, final_map_0);

#line 982
        }

        if(perm_distance_0 < uint8_t(8U))
        {
            RankedSeeds_add_0(i_2, uint16_t(perm_distance_0));

#line 984
        }

#line 979
        i_2 = i_2 + uint16_t(1US);

#line 979
    }

#line 990
    uint16_t _S20 = RankedSeeds_pack_0(candidates_0);

#line 990
    return int(_S20);
}


#line 257
PartitionMap_0 PartitionMap_x24init_0(uint data_2)
{

#line 257
    PartitionMap_0 _S21;

    _S21.data_1 = data_2;

#line 257
    return _S21;
}


#line 422
void CompressedTextureBlock_set_astc_seed_0(inout CompressedTextureBlock_0 this_5, uint16_t seed_4)
{
    if((this_5.payload_0.index_0) >= int8_t(0))
    {

#line 424
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_5.payload_0.index_0].astc_seed_0 = seed_4;

#line 424
    }
    else
    {

#line 424
        g_compressedBlock3P_0._data[uint(blockIdx_0)].astc_seed_0 = seed_4;

#line 424
    }

#line 424
    PartitionMap_0 _S22;
    if((CompressedTextureBlock_max_partitions_get_0(this_5)) == uint8_t(2U))
    {

#line 425
        _S22 = PartitionMap_x24init_0(g_lut_0.lut2_0[seed_4]);

#line 425
    }
    else
    {

#line 425
        _S22 = PartitionMap_x24init_0(g_lut_0.lut3_0[seed_4]);

#line 425
    }

#line 425
    if((this_5.payload_0.index_0) >= int8_t(0))
    {

#line 425
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_5.payload_0.index_0].partition_map_0 = _S22;

#line 425
    }
    else
    {

#line 425
        g_compressedBlock3P_0._data[uint(blockIdx_0)].partition_map_0 = _S22;

#line 425
    }
    return;
}


#line 348
PartitionMap_0 CompressedTextureBlockProxyPayload_partition_map_get_0(CompressedTextureBlockProxyPayload_0 this_6)
{

#line 348
    PartitionMap_0 _S23;

#line 319
    if((this_6.index_0) >= int8_t(0))
    {

#line 319
        _S23 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_6.index_0].partition_map_0;

#line 319
    }
    else
    {

#line 319
        _S23 = g_compressedBlock3P_0._data[uint(blockIdx_0)].partition_map_0;

#line 319
    }

#line 349
    return _S23;
}


#line 406
PartitionMap_0 CompressedTextureBlock_partition_map_get_0(CompressedTextureBlock_0 this_7)
{

#line 407
    return CompressedTextureBlockProxyPayload_partition_map_get_0(this_7.payload_0);
}


#line 838
float16_t estimate_partition_error_bound_0(f16mat3x3 scatter_matrix_0)
{

#line 844
    f16vec3 axis_0 = (((f16vec3(0.1700439453125HF, 0.830078125HF, 0.3798828125HF)) * (scatter_matrix_0)));

    f16vec3 axis_1 = (((axis_0 * (inversesqrt((dot(axis_0, axis_0) + 1.01327896118164062e-06HF)))) * (scatter_matrix_0)));


    return max(0.0HF, scatter_matrix_0[0][0] + scatter_matrix_0[1][1] + scatter_matrix_0[2][2] - sqrt(dot(axis_1, axis_1)));
}


float16_t compute_error_fast_0(CompressedTextureBlock_0 block_1)
{
    const f16vec3 _S24 = f16vec3(0.0HF, 0.0HF, 0.0HF);

#line 855
    const f16vec3 _S25 = f16vec3(0.0HF);

#line 855
    f16vec3  means_0[3];

#line 855
    means_0[0] = _S24;

#line 855
    means_0[1] = _S25;

#line 855
    means_0[2] = _S25;


    const f16mat3x3 _S26 = f16mat3x3(0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF);

#line 858
    f16mat3x3  scatters_0[3];

#line 858
    scatters_0[0] = f16mat3x3(_S24, _S25, _S25);

#line 858
    scatters_0[1] = _S26;

#line 858
    scatters_0[2] = _S26;
    uint8_t  counts_3[3];

#line 859
    counts_3[0] = uint8_t(0U);

#line 859
    counts_3[1] = uint8_t(0U);

#line 859
    counts_3[2] = uint8_t(0U);

#line 859
    uint8_t i_3 = uint8_t(0U);
    for(;;)
    {

#line 860
        if(i_3 < uint8_t(16U))
        {
        }
        else
        {

#line 860
            break;
        }
        uint8_t _S27 = PartitionMap_operatorx5Bx5D_get_0(CompressedTextureBlock_partition_map_get_0(block_1), int(i_3));

#line 862
        f16vec3 _S28 = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_3));


        means_0[_S27] = means_0[_S27] + _S28;
        counts_3[_S27] = counts_3[_S27] + uint8_t(1U);


        scatters_0[_S27][0] = scatters_0[_S27][0] + _S28.x * _S28;
        scatters_0[_S27][1] = scatters_0[_S27][1] + _S28.y * _S28;
        scatters_0[_S27][2] = scatters_0[_S27][2] + _S28.z * _S28;

#line 860
        i_3 = i_3 + uint8_t(1U);

#line 860
    }

#line 860
    uint8_t p_0 = uint8_t(0U);

#line 860
    float16_t total_lb_0 = 0.0HF;

#line 875
    for(;;)
    {

#line 875
        if(p_0 < (CompressedTextureBlock_max_partitions_get_0(block_1)))
        {
        }
        else
        {

#line 875
            break;
        }
        if((counts_3[p_0]) > uint8_t(0U))
        {

            float16_t _S29 = float16_t(counts_3[p_0]);
            scatters_0[p_0][0] = scatters_0[p_0][0] - means_0[p_0].x / _S29 * means_0[p_0];
            scatters_0[p_0][1] = scatters_0[p_0][1] - means_0[p_0].y / _S29 * means_0[p_0];
            scatters_0[p_0][2] = scatters_0[p_0][2] - means_0[p_0].z / _S29 * means_0[p_0];

#line 883
            total_lb_0 = total_lb_0 + estimate_partition_error_bound_0(scatters_0[p_0]);

#line 877
        }

#line 875
        p_0 = p_0 + uint8_t(1U);

#line 875
    }

#line 888
    return total_lb_0;
}


#line 330
u8vec3 CompressedTextureBlockProxyPayload_ep0_get_0(CompressedTextureBlockProxyPayload_0 this_8)
{

#line 330
    u8vec3 _S30;

#line 319
    if((this_8.index_0) >= int8_t(0))
    {

#line 319
        _S30 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_8.index_0]._ep0_0;

#line 319
    }
    else
    {

#line 319
        _S30 = g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep0_0;

#line 319
    }

#line 331
    return _S30;
}


#line 388
f16vec3 CompressedTextureBlock_ep0_get_0(CompressedTextureBlock_0 this_9)
{

#line 389
    return f16vec3(CompressedTextureBlockProxyPayload_ep0_get_0(this_9.payload_0)) / 255.0HF;
}


#line 330
u8vec3 CompressedTextureBlockProxyPayload_ep1_get_0(CompressedTextureBlockProxyPayload_0 this_10)
{

#line 330
    u8vec3 _S31;

#line 319
    if((this_10.index_0) >= int8_t(0))
    {

#line 319
        _S31 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_10.index_0]._ep1_0;

#line 319
    }
    else
    {

#line 319
        _S31 = g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep1_0;

#line 319
    }

#line 331
    return _S31;
}


#line 388
f16vec3 CompressedTextureBlock_ep1_get_0(CompressedTextureBlock_0 this_11)
{

#line 389
    return f16vec3(CompressedTextureBlockProxyPayload_ep1_get_0(this_11.payload_0)) / 255.0HF;
}


#line 13408 1
f16vec3 saturate_0(f16vec3 x_2)
{

#line 13416
    return clamp(x_2, f16vec3(0.0HF), f16vec3(1.0HF));
}


#line 738 0
void solve_pca_eps_0(CompressedTextureBlock_0 block_2, inout f16vec3 ep0_0, inout f16vec3 ep1_0, uint8_t partition_id_0)
{


    const f16vec3 _S32 = f16vec3(0.1700439453125HF, 0.830078125HF, 0.3798828125HF);
    f16vec3 _S33 = f16vec3(ivec3(0));

#line 743
    uint8_t i_4 = uint8_t(0U);

#line 743
    f16vec3 centroid_0 = _S33;

#line 743
    uint8_t count_3 = uint8_t(0U);


    for(;;)
    {

#line 746
        if(i_4 < uint8_t(16U))
        {
        }
        else
        {

#line 746
            break;
        }
        if((PartitionMap_operatorx5Bx5D_get_0(CompressedTextureBlock_partition_map_get_0(block_2), int(i_4))) == partition_id_0)
        {

            uint8_t count_4 = count_3 + uint8_t(1U);

#line 751
            centroid_0 = centroid_0 + TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_4));

#line 751
            count_3 = count_4;

#line 748
        }

#line 746
        i_4 = i_4 + uint8_t(1U);

#line 746
    }

#line 754
    float16_t _S34 = float16_t(count_3);

#line 754
    f16vec3 centroid_1 = centroid_0 / _S34;

    if(count_3 == uint8_t(0U))
    {

#line 757
        return;
    }
    if(count_3 == uint8_t(1U))
    {
        f16vec3 _S35 = saturate_0(centroid_1);

#line 761
        ep0_0 = _S35;
        ep1_0 = _S35;
        return;
    }

    f16mat3x3 C_0 = f16mat3x3(0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF);

#line 766
    i_4 = uint8_t(0U);
    for(;;)
    {

#line 767
        if(i_4 < uint8_t(16U))
        {
        }
        else
        {

#line 767
            break;
        }
        if((PartitionMap_operatorx5Bx5D_get_0(CompressedTextureBlock_partition_map_get_0(block_2), int(i_4))) == partition_id_0)
        {
            f16vec3 d_3 = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_4)) - centroid_1;
            C_0[0] = C_0[0] + d_3.x * d_3;
            C_0[1] = C_0[1] + d_3.y * d_3;
            C_0[2] = C_0[2] + d_3.z * d_3;

#line 769
        }

#line 767
        i_4 = i_4 + uint8_t(1U);

#line 767
    }

#line 777
    C_0 = C_0 / _S34;



    if(float(C_0[0].x + C_0[1].y + C_0[2].z) < 0.00030000001424924)
    {
        f16vec3 _S36 = saturate_0(centroid_1);

#line 783
        ep0_0 = _S36;
        ep1_0 = _S36;
        return;
    }

#line 785
    int iter_1 = 0;

#line 785
    f16vec3 axis_2 = _S32;


    for(;;)
    {

#line 788
        if(iter_1 < 4)
        {
        }
        else
        {

#line 788
            break;
        }
        f16vec3 axis_3 = (((axis_2) * (C_0)));
        float16_t lenSq_0 = dot(axis_3, axis_3);
        if(float(lenSq_0) > 9.99999993922529029e-09)
        {

#line 792
            axis_2 = axis_3 * (inversesqrt((lenSq_0)));

#line 792
        }
        else
        {

#line 792
            axis_2 = axis_3;

#line 792
        }

#line 788
        iter_1 = iter_1 + 1;

#line 788
    }

#line 799
    if(float(dot(axis_2, axis_2)) < 9.99999993922529029e-09)
    {
        ep0_0 = saturate_0(centroid_1);
        return;
    }

    f16vec3 axis_4 = normalize(axis_2);

#line 805
    float16_t min_t_0 = 1000.0HF;

#line 805
    float16_t max_t_0 = -1000.0HF;

#line 805
    int i_5 = 0;



    for(;;)
    {

#line 809
        if(i_5 < 16)
        {
        }
        else
        {

#line 809
            break;
        }
        if((PartitionMap_operatorx5Bx5D_get_0(CompressedTextureBlock_partition_map_get_0(block_2), i_5)) == partition_id_0)
        {

            float16_t t_0 = dot(TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_5)) - centroid_1, axis_4);

            float16_t _S37 = max(max_t_0, t_0);

#line 816
            min_t_0 = min(min_t_0, t_0);

#line 816
            max_t_0 = _S37;

#line 811
        }

#line 809
        i_5 = i_5 + 1;

#line 809
    }

#line 820
    ep0_0 = saturate_0(centroid_1 + axis_4 * min_t_0);
    ep1_0 = saturate_0(centroid_1 + axis_4 * max_t_0);
    return;
}


#line 330
u8vec3 CompressedTextureBlockProxyPayload_ep2_get_0(CompressedTextureBlockProxyPayload_0 this_12)
{

#line 330
    u8vec3 _S38;

#line 319
    if((this_12.index_0) >= int8_t(0))
    {

#line 319
        _S38 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_12.index_0]._ep2_0;

#line 319
    }
    else
    {

#line 319
        _S38 = g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep2_0;

#line 319
    }

#line 331
    return _S38;
}


#line 388
f16vec3 CompressedTextureBlock_ep2_get_0(CompressedTextureBlock_0 this_13)
{

#line 389
    return f16vec3(CompressedTextureBlockProxyPayload_ep2_get_0(this_13.payload_0)) / 255.0HF;
}


#line 330
u8vec3 CompressedTextureBlockProxyPayload_ep3_get_0(CompressedTextureBlockProxyPayload_0 this_14)
{

#line 330
    u8vec3 _S39;

#line 319
    if((this_14.index_0) >= int8_t(0))
    {

#line 319
        _S39 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_14.index_0]._ep3_0;

#line 319
    }
    else
    {

#line 319
        _S39 = g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep3_0;

#line 319
    }

#line 331
    return _S39;
}


#line 388
f16vec3 CompressedTextureBlock_ep3_get_0(CompressedTextureBlock_0 this_15)
{

#line 389
    return f16vec3(CompressedTextureBlockProxyPayload_ep3_get_0(this_15.payload_0)) / 255.0HF;
}


#line 330
u8vec3 CompressedTextureBlockProxyPayload_ep4_get_0(CompressedTextureBlockProxyPayload_0 this_16)
{

#line 330
    u8vec3 _S40;

#line 319
    if((this_16.index_0) >= int8_t(0))
    {

#line 319
        _S40 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_16.index_0]._ep4_0;

#line 319
    }
    else
    {

#line 319
        _S40 = g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep4_0;

#line 319
    }

#line 331
    return _S40;
}


#line 388
f16vec3 CompressedTextureBlock_ep4_get_0(CompressedTextureBlock_0 this_17)
{

#line 389
    return f16vec3(CompressedTextureBlockProxyPayload_ep4_get_0(this_17.payload_0)) / 255.0HF;
}


#line 330
u8vec3 CompressedTextureBlockProxyPayload_ep5_get_0(CompressedTextureBlockProxyPayload_0 this_18)
{

#line 330
    u8vec3 _S41;

#line 319
    if((this_18.index_0) >= int8_t(0))
    {

#line 319
        _S41 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_18.index_0]._ep5_0;

#line 319
    }
    else
    {

#line 319
        _S41 = g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep5_0;

#line 319
    }

#line 331
    return _S41;
}


#line 388
f16vec3 CompressedTextureBlock_ep5_get_0(CompressedTextureBlock_0 this_19)
{

#line 389
    return f16vec3(CompressedTextureBlockProxyPayload_ep5_get_0(this_19.payload_0)) / 255.0HF;
}


#line 13393 1
float16_t saturate_1(float16_t x_3)
{

#line 13401
    return clamp(x_3, 0.0HF, 1.0HF);
}


#line 348 0
BF8Weights_0 CompressedTextureBlockProxyPayload_weights_get_0(CompressedTextureBlockProxyPayload_0 this_20)
{

#line 348
    BF8Weights_0 _S42;

#line 319
    if((this_20.index_0) >= int8_t(0))
    {

#line 319
        _S42 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_20.index_0].weights_0;

#line 319
    }
    else
    {

#line 319
        _S42 = g_compressedBlock3P_0._data[uint(blockIdx_0)].weights_0;

#line 319
    }

#line 349
    return _S42;
}


#line 406
BF8Weights_0 CompressedTextureBlock_weights_get_0(CompressedTextureBlock_0 this_21)
{

#line 407
    return CompressedTextureBlockProxyPayload_weights_get_0(this_21.payload_0);
}


#line 431
void CompressedTextureBlock_solve_weights_0(inout CompressedTextureBlock_0 this_22)
{

    f16vec3 L1_0 = CompressedTextureBlock_ep1_get_0(this_22) - CompressedTextureBlock_ep0_get_0(this_22);
    f16vec3 L2_0 = CompressedTextureBlock_ep3_get_0(this_22) - CompressedTextureBlock_ep2_get_0(this_22);
    f16vec3 L3_0 = CompressedTextureBlock_ep5_get_0(this_22) - CompressedTextureBlock_ep4_get_0(this_22);
    float16_t _S43 = 1.0HF / (dot(L1_0, L1_0) + 1.01327896118164062e-06HF);
    float16_t _S44 = 1.0HF / (dot(L2_0, L2_0) + 1.01327896118164062e-06HF);
    float16_t _S45 = 1.0HF / (dot(L3_0, L3_0) + 1.01327896118164062e-06HF);

#line 439
    int i_6 = 0;
    for(;;)
    {

#line 440
        if(i_6 < 16)
        {
        }
        else
        {

#line 440
            break;
        }

#line 440
        f16vec3 _S46 = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_6));


        uint8_t p_1 = PartitionMap_operatorx5Bx5D_get_0(CompressedTextureBlock_partition_map_get_0(this_22), i_6);
        bool _S47 = p_1 == uint8_t(0U);

#line 444
        float16_t pDotL_0;

#line 444
        if(_S47)
        {

#line 444
            pDotL_0 = dot(_S46 - CompressedTextureBlock_ep0_get_0(this_22), L1_0);

#line 444
        }
        else
        {

#line 444
            if(p_1 == uint8_t(1U))
            {

#line 444
                pDotL_0 = dot(_S46 - CompressedTextureBlock_ep2_get_0(this_22), L2_0);

#line 444
            }
            else
            {

#line 444
                pDotL_0 = dot(_S46 - CompressedTextureBlock_ep4_get_0(this_22), L3_0);

#line 444
            }

#line 444
        }

#line 444
        float16_t invLenSq_0;
        if(_S47)
        {

#line 445
            invLenSq_0 = _S43;

#line 445
        }
        else
        {

#line 445
            if(p_1 == uint8_t(1U))
            {

#line 445
                invLenSq_0 = _S44;

#line 445
            }
            else
            {

#line 445
                invLenSq_0 = _S45;

#line 445
            }

#line 445
        }

        float16_t _S48 = saturate_1(pDotL_0 * invLenSq_0);

#line 447
        BF8Weights_0 _S49 = CompressedTextureBlock_weights_get_0(this_22);

#line 447
        _S49.data_0[i_6] = uint8_t(round(saturate_1(_S48) * 63.0HF));

#line 447
        BF8Weights_0 _S50 = _S49;

#line 447
        if((this_22.payload_0.index_0) >= int8_t(0))
        {

#line 447
            g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_22.payload_0.index_0].weights_0 = _S50;

#line 447
        }
        else
        {

#line 447
            g_compressedBlock3P_0._data[uint(blockIdx_0)].weights_0 = _S50;

#line 447
        }

#line 440
        i_6 = i_6 + 1;

#line 440
    }

#line 449
    return;
}


#line 237
float16_t BF8Weights_operatorx5Bx5D_get_0(BF8Weights_0 this_23, int n_2)
{

    return float16_t(this_23.data_0[n_2]) / 63.0HF;
}


#line 580
void CompressedTextureBlock_decompress3P_0(CompressedTextureBlock_0 this_24)
{

#line 580
    uint8_t i_7 = uint8_t(0U);


    for(;;)
    {

#line 583
        if(i_7 < uint8_t(16U))
        {
        }
        else
        {

#line 583
            break;
        }
        int _S51 = int(i_7);

#line 585
        uint8_t _S52 = PartitionMap_operatorx5Bx5D_get_0(CompressedTextureBlock_partition_map_get_0(this_24), _S51);
        bool _S53 = _S52 == uint8_t(0U);

#line 586
        f16vec3 _S54;

#line 586
        if(_S53)
        {

#line 586
            _S54 = CompressedTextureBlock_ep0_get_0(this_24);

#line 586
        }
        else
        {

#line 586
            if(_S52 == uint8_t(1U))
            {

#line 586
                _S54 = CompressedTextureBlock_ep2_get_0(this_24);

#line 586
            }
            else
            {

#line 586
                _S54 = CompressedTextureBlock_ep4_get_0(this_24);

#line 586
            }

#line 586
        }

#line 586
        f16vec3 _S55;
        if(_S53)
        {

#line 587
            _S55 = CompressedTextureBlock_ep1_get_0(this_24);

#line 587
        }
        else
        {

#line 587
            if(_S52 == uint8_t(1U))
            {

#line 587
                _S55 = CompressedTextureBlock_ep3_get_0(this_24);

#line 587
            }
            else
            {

#line 587
                _S55 = CompressedTextureBlock_ep5_get_0(this_24);

#line 587
            }

#line 587
        }
        g_reconstructed_0._data[uint(blockIdx_0)].pixels_0[uint(i_7)] = u8vec3(round(mix(_S54, _S55, f16vec3(BF8Weights_operatorx5Bx5D_get_0(CompressedTextureBlock_weights_get_0(this_24), _S51))) * 255.0HF));

#line 583
        i_7 = i_7 + uint8_t(1U);

#line 583
    }

#line 590
    return;
}


#line 1053
f16vec3 TextureBlock_operatorx5Bx5D_get_1(uint _S56, uint _S57)
{

#line 9
    return f16vec3(g_reconstructed_0._data[uint(_S56)].pixels_0[_S57]) / 255.0HF;
}


#line 824
float loss_mse_0(CompressedTextureBlock_0 compressed_0)
{
    CompressedTextureBlock_decompress3P_0(compressed_0);

#line 826
    int i_8 = 0;

#line 826
    float totalError_0 = 0.0;


    for(;;)
    {

#line 829
        if(i_8 < 16)
        {
        }
        else
        {

#line 829
            break;
        }
        uint _S58 = uint(i_8);

#line 831
        f16vec3 diff_0 = TextureBlock_operatorx5Bx5D_get_1(blockIdx_0, _S58) - TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, _S58);
        float totalError_1 = totalError_0 + float(dot(diff_0, diff_0));

#line 829
        i_8 = i_8 + 1;

#line 829
        totalError_0 = totalError_1;

#line 829
    }

#line 835
    return totalError_0;
}


#line 348
PartitionMap_0 CompressedTextureBlockProxyPayload_ideal_partition_map_get_0(CompressedTextureBlockProxyPayload_0 this_25)
{

#line 348
    PartitionMap_0 _S59;

#line 319
    if((this_25.index_0) >= int8_t(0))
    {

#line 319
        _S59 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_25.index_0].ideal_partition_map_0;

#line 319
    }
    else
    {

#line 319
        _S59 = g_compressedBlock3P_0._data[uint(blockIdx_0)].ideal_partition_map_0;

#line 319
    }

#line 349
    return _S59;
}


#line 406
PartitionMap_0 CompressedTextureBlock_ideal_partition_map_get_0(CompressedTextureBlock_0 this_26)
{

#line 407
    return CompressedTextureBlockProxyPayload_ideal_partition_map_get_0(this_26.payload_0);
}


#line 993
float optimize_0(inout CompressedTextureBlock_0 block_3, uint steps_1, bool diagnostics_enabled_0, bool exhaustive_1)
{

    uint8_t _S60 = CompressedTextureBlock_max_partitions_get_0(block_3);

#line 996
    uint candidates_1;



    if(exhaustive_1)
    {

        if(_S60 == uint8_t(1U))
        {

#line 1003
            candidates_1 = 1U;

#line 1003
        }
        else
        {

#line 1003
            candidates_1 = steps_1;

#line 1003
        }

#line 1000
    }
    else
    {


        if(_S60 > uint8_t(1U))
        {


            int _S61 = find_top_partitions_0(block_3, steps_1);

#line 1009
            candidates_1 = uint(_S61);

#line 1005
        }
        else
        {

#line 1005
            candidates_1 = 0U;

#line 1005
        }

#line 1000
    }

#line 1000
    float best_loss_0 = 1000.0;

#line 1000
    uint16_t best_seed_0 = uint16_t(0US);

#line 1000
    uint16_t best_candidate_id_0 = uint16_t(0US);

#line 1000
    uint16_t candidate_id_0 = uint16_t(0US);

#line 1018
    for(;;)
    {

#line 1018
        if(uint(candidate_id_0) < candidates_1)
        {
        }
        else
        {

#line 1018
            break;
        }

#line 1018
        uint16_t seed_5;


        if(exhaustive_1)
        {

#line 1021
            seed_5 = candidate_id_0;

#line 1021
        }
        else
        {

#line 1021
            seed_5 = g_scratch_0._data[uint(blockIdx_0)].partitions_0[candidate_id_0];

#line 1021
        }


        CompressedTextureBlock_set_astc_seed_0(block_3, seed_5);

        float loss_0 = float(compute_error_fast_0(block_3));
        if(loss_0 < best_loss_0)
        {

#line 1027
            best_loss_0 = loss_0;

#line 1027
            best_seed_0 = seed_5;

#line 1027
            best_candidate_id_0 = candidate_id_0;

#line 1027
        }

#line 1027
        bool _S62;

#line 1034
        if(diagnostics_enabled_0)
        {

#line 1034
            _S62 = candidate_id_0 < uint16_t(10US);

#line 1034
        }
        else
        {

#line 1034
            _S62 = false;

#line 1034
        }

#line 1034
        if(_S62)
        {
            uvec2 _S63 = (clockRealtime2x32EXT());

#line 1036
            g_diagnostics_0._data[uint(blockIdx_0)].timestamps_0[candidate_id_0] = _S63;
            g_diagnostics_0._data[uint(blockIdx_0)].loss_log_0[candidate_id_0][_S60 - uint8_t(1U)] = loss_0;

#line 1034
        }

#line 1018
        candidate_id_0 = candidate_id_0 + uint16_t(1US);

#line 1018
    }

#line 1043
    bool _S64 = _S60 > uint8_t(1U);

#line 1043
    if(_S64)
    {
        CompressedTextureBlock_set_astc_seed_0(block_3, best_seed_0);

#line 1043
    }



    f16vec3 _S65 = CompressedTextureBlock_ep0_get_0(block_3);

#line 1047
    f16vec3 _S66 = CompressedTextureBlock_ep1_get_0(block_3);

#line 1047
    solve_pca_eps_0(block_3, _S65, _S66, uint8_t(0U));

#line 1047
    f16vec3 _S67 = _S65;

#line 1047
    u8vec3 _S68 = u8vec3(round(saturate_0(_S67) * 255.0HF));

#line 1047
    if((block_3.payload_0.index_0) >= int8_t(0))
    {

#line 1047
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_3.payload_0.index_0]._ep0_0 = _S68;

#line 1047
    }
    else
    {

#line 1047
        g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep0_0 = _S68;

#line 1047
    }

#line 1047
    u8vec3 _S69 = u8vec3(round(saturate_0(_S66) * 255.0HF));

#line 1047
    if((block_3.payload_0.index_0) >= int8_t(0))
    {

#line 1047
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_3.payload_0.index_0]._ep1_0 = _S69;

#line 1047
    }
    else
    {

#line 1047
        g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep1_0 = _S69;

#line 1047
    }
    if(_S64)
    {

#line 1049
        f16vec3 _S70 = CompressedTextureBlock_ep2_get_0(block_3);

#line 1049
        f16vec3 _S71 = CompressedTextureBlock_ep3_get_0(block_3);

#line 1049
        solve_pca_eps_0(block_3, _S70, _S71, uint8_t(1U));

#line 1049
        u8vec3 _S72 = u8vec3(round(saturate_0(_S70) * 255.0HF));

#line 1049
        if((block_3.payload_0.index_0) >= int8_t(0))
        {

#line 1049
            g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_3.payload_0.index_0]._ep2_0 = _S72;

#line 1049
        }
        else
        {

#line 1049
            g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep2_0 = _S72;

#line 1049
        }

#line 1049
        u8vec3 _S73 = u8vec3(round(saturate_0(_S71) * 255.0HF));

#line 1049
        if((block_3.payload_0.index_0) >= int8_t(0))
        {

#line 1049
            g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_3.payload_0.index_0]._ep3_0 = _S73;

#line 1049
        }
        else
        {

#line 1049
            g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep3_0 = _S73;

#line 1049
        }

#line 1048
    }

    if(_S60 > uint8_t(2U))
    {

#line 1051
        f16vec3 _S74 = CompressedTextureBlock_ep4_get_0(block_3);

#line 1051
        f16vec3 _S75 = CompressedTextureBlock_ep5_get_0(block_3);

#line 1051
        solve_pca_eps_0(block_3, _S74, _S75, uint8_t(2U));

#line 1051
        u8vec3 _S76 = u8vec3(round(saturate_0(_S74) * 255.0HF));

#line 1051
        if((block_3.payload_0.index_0) >= int8_t(0))
        {

#line 1051
            g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_3.payload_0.index_0]._ep4_0 = _S76;

#line 1051
        }
        else
        {

#line 1051
            g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep4_0 = _S76;

#line 1051
        }

#line 1051
        u8vec3 _S77 = u8vec3(round(saturate_0(_S75) * 255.0HF));

#line 1051
        if((block_3.payload_0.index_0) >= int8_t(0))
        {

#line 1051
            g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_3.payload_0.index_0]._ep5_0 = _S77;

#line 1051
        }
        else
        {

#line 1051
            g_compressedBlock3P_0._data[uint(blockIdx_0)]._ep5_0 = _S77;

#line 1051
        }

#line 1050
    }

    CompressedTextureBlock_solve_weights_0(block_3);
    float loss_1 = loss_mse_0(block_3);
    if(diagnostics_enabled_0)
    {
        g_diagnostics_0._data[uint(blockIdx_0)].loss_log_0[11][_S60 - uint8_t(1U)] = loss_1;

#line 1054
    }

#line 1059
    if((block_3.payload_0.index_0) >= int8_t(0))
    {

#line 1059
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_3.payload_0.index_0].astc_seed_0 = best_candidate_id_0;

#line 1059
    }
    else
    {

#line 1059
        g_compressedBlock3P_0._data[uint(blockIdx_0)].astc_seed_0 = best_candidate_id_0;

#line 1059
    }

#line 1059
    uint8_t _S78;
    if((CompressedTextureBlock_max_partitions_get_0(block_3)) == uint8_t(2U))
    {

#line 1060
        _S78 = best_perm_distance_s2_0(CompressedTextureBlock_ideal_partition_map_get_0(block_3).data_1, CompressedTextureBlock_partition_map_get_0(block_3).data_1);

#line 1060
    }
    else
    {

#line 1060
        _S78 = best_perm_distance_s3_0(CompressedTextureBlock_ideal_partition_map_get_0(block_3).data_1, CompressedTextureBlock_partition_map_get_0(block_3).data_1);

#line 1060
    }

#line 1060
    if((block_3.payload_0.index_0) >= int8_t(0))
    {

#line 1060
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_3.payload_0.index_0].perm_0 = _S78;

#line 1060
    }
    else
    {

#line 1060
        g_compressedBlock3P_0._data[uint(blockIdx_0)].perm_0 = _S78;

#line 1060
    }

    return loss_1;
}


#line 365
void CompressedTextureBlockProxyPayload_set_0(CompressedTextureBlockProxyPayload_0 this_27, CompressedTextureBlockProxyPayload_0 other_0)
{

#line 365
    CompressedTextureBlockPayload_0 _S79;


    if((this_27.index_0) >= int8_t(0))
    {
        if((other_0.index_0) >= int8_t(0))
        {

#line 370
            _S79 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[other_0.index_0];

#line 370
        }
        else
        {

#line 370
            _S79 = g_compressedBlock3P_0._data[uint(blockIdx_0)];

#line 370
        }

#line 369
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_27.index_0] = _S79;

#line 368
    }
    else
    {



        if((other_0.index_0) >= int8_t(0))
        {

#line 374
            _S79 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[other_0.index_0];

#line 374
        }
        else
        {

#line 374
            _S79 = g_compressedBlock3P_0._data[uint(blockIdx_0)];

#line 374
        }

#line 373
        g_compressedBlock3P_0._data[uint(blockIdx_0)] = _S79;

#line 368
    }

#line 376
    return;
}


#line 226
f16vec3 quantize_0(f16vec3 value_0, uint range_0)
{
    f16vec3 scale_0 = f16vec3(float16_t(int(range_0)));
    return round(value_0 * scale_0) / scale_0;
}


#line 220
float16_t quantize_1(float16_t value_1, uint range_1)
{

#line 220
    float16_t _S80 = float16_t(int(range_1));


    return round(value_1 * _S80) / _S80;
}


#line 247
void BF8Weights_quantize_0(inout BF8Weights_0 this_28, uint8_t range_2)
{

#line 247
    int i_9 = 0;


    [[unroll]]
    for(;;)
    {

#line 250
        if(i_9 < 16)
        {
        }
        else
        {

#line 250
            break;
        }
        this_28.data_0[i_9] = uint8_t(round(saturate_1(quantize_1(BF8Weights_operatorx5Bx5D_get_0(this_28, i_9), uint(range_2))) * 63.0HF));

#line 250
        i_9 = i_9 + 1;

#line 250
    }



    return;
}


#line 593
float CompressedTextureBlock_quantize_0(inout CompressedTextureBlock_0 this_29)
{
    if(g_params_0.no_quantization_0)
    {
        float _S81 = loss_mse_0(this_29);

#line 597
        return _S81;
    }


    CompressedTextureBlockProxyPayload_0 _S82 = { int8_t(1) };

#line 601
    u8vec2 best_wc_0;

#line 601
    float best_loss_1 = 1000.0;

#line 601
    int i_10 = 0;
    for(;;)
    {

#line 602
        if(i_10 < 9)
        {
        }
        else
        {

#line 602
            break;
        }

#line 602
        u8vec2 wc_0;


        if((CompressedTextureBlock_max_partitions_get_0(this_29)) == uint8_t(1U))
        {

#line 605
            wc_0 = VALID_1P_QUANTIZATION_RANGES_0[i_10];

#line 605
        }
        else
        {

#line 606
            if((CompressedTextureBlock_max_partitions_get_0(this_29)) == uint8_t(2U))
            {

#line 606
                wc_0 = VALID_2P_QUANTIZATION_RANGES_0[i_10];

#line 606
            }
            else
            {

#line 606
                wc_0 = VALID_3P_QUANTIZATION_RANGES_0[i_10];

#line 606
            }

#line 605
        }

        uint8_t _S83 = wc_0.x;

#line 607
        if(_S83 == uint8_t(0U))
        {

#line 608
            i_10 = i_10 + 1;

#line 602
            continue;
        }

#line 611
        uint8_t _S84 = wc_0.y;
        CompressedTextureBlockProxyPayload_0 _S85 = { int8_t(2) };

#line 612
        CompressedTextureBlock_0 block_4 = { _S85 };
        CompressedTextureBlockProxyPayload_set_0(_S85, this_29.payload_0);
        uint _S86 = uint(_S84);

#line 614
        f16vec3 _S87 = quantize_0(CompressedTextureBlock_ep0_get_0(this_29), _S86);

#line 614
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[int8_t(2)]._ep0_0 = u8vec3(round(saturate_0(_S87) * 255.0HF));
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[int8_t(2)]._ep1_0 = u8vec3(round(saturate_0(quantize_0(CompressedTextureBlock_ep1_get_0(this_29), _S86)) * 255.0HF));
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[int8_t(2)]._ep2_0 = u8vec3(round(saturate_0(quantize_0(CompressedTextureBlock_ep2_get_0(this_29), _S86)) * 255.0HF));
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[int8_t(2)]._ep3_0 = u8vec3(round(saturate_0(quantize_0(CompressedTextureBlock_ep3_get_0(this_29), _S86)) * 255.0HF));
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[int8_t(2)]._ep4_0 = u8vec3(round(saturate_0(quantize_0(CompressedTextureBlock_ep4_get_0(this_29), _S86)) * 255.0HF));
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[int8_t(2)]._ep5_0 = u8vec3(round(saturate_0(quantize_0(CompressedTextureBlock_ep5_get_0(this_29), _S86)) * 255.0HF));
        BF8Weights_0 _S88 = CompressedTextureBlock_weights_get_0(block_4);

#line 620
        BF8Weights_quantize_0(_S88, _S83);

#line 620
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[int8_t(2)].weights_0 = _S88;

        float _S89 = loss_mse_0(block_4);

#line 622
        bool _S90;
        if(_S89 < best_loss_1)
        {

#line 623
            _S90 = true;

#line 623
        }
        else
        {

#line 623
            _S90 = i_10 == 0;

#line 623
        }

#line 623
        float best_loss_2;

#line 623
        u8vec2 best_wc_1;

#line 623
        if(_S90)
        {


            CompressedTextureBlockProxyPayload_set_0(_S82, _S85);

#line 627
            best_loss_2 = _S89;

#line 627
            best_wc_1 = wc_0;

#line 623
        }
        else
        {

#line 623
            best_loss_2 = best_loss_1;

#line 623
            best_wc_1 = best_wc_0;

#line 623
        }

#line 623
        best_loss_1 = best_loss_2;

#line 623
        best_wc_0 = best_wc_1;

#line 602
        i_10 = i_10 + 1;

#line 602
    }

#line 630
    CompressedTextureBlockProxyPayload_set_0(this_29.payload_0, _S82);
    if((this_29.payload_0.index_0) >= int8_t(0))
    {

#line 631
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_29.payload_0.index_0].qwc_0 = best_wc_0;

#line 631
    }
    else
    {

#line 631
        g_compressedBlock3P_0._data[uint(blockIdx_0)].qwc_0 = best_wc_0;

#line 631
    }
    return best_loss_1;
}

void CompressedTextureBlock_reconstruct_0(CompressedTextureBlock_0 this_30)
{

#line 732
    CompressedTextureBlock_decompress3P_0(this_30);
    return;
}


#line 1074
void CompressedTextureBlockPayload_set_0(uint _S91, CompressedTextureBlockProxyPayload_0 _S92)
{

#line 1074
    CompressedTextureBlockPayload_0 _S93;

#line 311
    if((_S92.index_0) >= int8_t(0))
    {

#line 311
        _S93 = g_scratch_0._data[uint(blockIdx_0)].blocks_0[_S92.index_0];

#line 311
    }
    else
    {

#line 311
        _S93 = g_compressedBlock3P_0._data[uint(blockIdx_0)];

#line 311
    }

#line 311
    g_compressedBlock3P_0._data[uint(_S91)] = _S93;

    return;
}


#line 1074
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 1076
    uint _S94 = gl_GlobalInvocationID.x;

#line 1076
    blockIdx_0 = _S94;
    if(_S94 >= (g_params_0.num_blocks_0))
    {

#line 1078
        return;
    }

#line 1079
    uvec2 _S95 = (clockRealtime2x32EXT());

#line 1079
    g_diagnostics_0._data[uint(blockIdx_0)].start_clock_0 = _S95;


    CompressedTextureBlockProxyPayload_0 _S96 = { int8_t(-1) };

#line 1082
    CompressedTextureBlock_0 block_5;

#line 1082
    block_5.payload_0 = _S96;
    CompressedTextureBlockProxyPayload_0 _S97 = { int8_t(0) };

#line 1083
    CompressedTextureBlock_0 block1_0;

#line 1083
    block1_0.payload_0 = _S97;



    bool _S98 = g_params_0.exhaustive_0;

#line 1092
    uint _S99 = g_params_0.steps_0;

#line 1111
    if((block_5.payload_0.index_0) >= int8_t(0))
    {

#line 1111
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_5.payload_0.index_0].max_partitions_1 = uint8_t(1U);

#line 1111
    }
    else
    {

#line 1111
        g_compressedBlock3P_0._data[uint(blockIdx_0)].max_partitions_1 = uint8_t(1U);

#line 1111
    }
    float _S100 = optimize_0(block_5, _S99, true, false);
    float quantized_loss_0 = CompressedTextureBlock_quantize_0(block_5);

#line 1113
    float quantized_loss_1;

#line 1113
    float unquantized_loss_0;
    if((g_params_0.max_partitions_0) >= uint8_t(2U))
    {

        if((block1_0.payload_0.index_0) >= int8_t(0))
        {

#line 1117
            g_scratch_0._data[uint(blockIdx_0)].blocks_0[block1_0.payload_0.index_0].max_partitions_1 = uint8_t(2U);

#line 1117
        }
        else
        {

#line 1117
            g_compressedBlock3P_0._data[uint(blockIdx_0)].max_partitions_1 = uint8_t(2U);

#line 1117
        }
        float unquantized_loss1_0 = optimize_0(block1_0, _S99, true, _S98);
        float quantized_loss1_0 = CompressedTextureBlock_quantize_0(block1_0);
        if(quantized_loss1_0 < quantized_loss_0)
        {


            CompressedTextureBlockProxyPayload_set_0(block_5.payload_0, block1_0.payload_0);

#line 1124
            quantized_loss_1 = quantized_loss1_0;

#line 1124
            unquantized_loss_0 = unquantized_loss1_0;

#line 1120
        }
        else
        {

#line 1120
            quantized_loss_1 = quantized_loss_0;

#line 1120
            unquantized_loss_0 = _S100;

#line 1120
        }

#line 1126
        if((g_params_0.max_partitions_0) == uint8_t(3U))
        {
            if((block1_0.payload_0.index_0) >= int8_t(0))
            {

#line 1128
                g_scratch_0._data[uint(blockIdx_0)].blocks_0[block1_0.payload_0.index_0].max_partitions_1 = uint8_t(3U);

#line 1128
            }
            else
            {

#line 1128
                g_compressedBlock3P_0._data[uint(blockIdx_0)].max_partitions_1 = uint8_t(3U);

#line 1128
            }
            float unquantized_loss1_1 = optimize_0(block1_0, _S99, true, _S98);
            float quantized_loss1_1 = CompressedTextureBlock_quantize_0(block1_0);
            if(quantized_loss1_1 < quantized_loss_1)
            {


                CompressedTextureBlockProxyPayload_set_0(block_5.payload_0, block1_0.payload_0);

#line 1135
                unquantized_loss_0 = unquantized_loss1_1;

#line 1135
                quantized_loss_1 = quantized_loss1_1;

#line 1131
            }

#line 1126
        }

#line 1114
    }
    else
    {

#line 1114
        unquantized_loss_0 = _S100;

#line 1114
        quantized_loss_1 = quantized_loss_0;

#line 1114
    }

#line 1140
    uvec2 _S101 = (clockRealtime2x32EXT());

#line 1140
    g_diagnostics_0._data[uint(blockIdx_0)].optim_ended_clock_0 = _S101;

    CompressedTextureBlock_reconstruct_0(block_5);

#line 1142
    CompressedTextureBlockPayload_set_0(blockIdx_0, block_5.payload_0);


    g_diagnostics_0._data[uint(blockIdx_0)].final_unquantized_loss_0 = unquantized_loss_0;
    g_final_loss_0._data[uint(blockIdx_0)] = quantized_loss_1;
    uvec2 _S102 = (clockRealtime2x32EXT());

#line 1147
    g_diagnostics_0._data[uint(blockIdx_0)].finished_clock_0 = _S102;
    return;
}

