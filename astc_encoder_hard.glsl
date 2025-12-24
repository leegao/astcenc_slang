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


#line 60
layout(std430, binding = 3) buffer StructuredBuffer_Diagnostics_t_0 {
    Diagnostics_0 _data[];
} g_diagnostics_0;

#line 2
struct TextureBlock_0
{
    u8vec3  pixels_0[16];
};


#line 54
layout(std430, binding = 1) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;

#line 72
struct LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
};


#line 77
layout(binding = 6)
layout(std140) uniform block_LUT_0
{
    uint  lut2_0[1024];
    uint  lut3_0[1024];
}g_lut_0;

#line 223
struct BF8Weights_0
{
    uint8_t  data_0[16];
};


#line 247
struct PartitionMap_0
{
    uint data_1;
};


#line 320
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


#line 82
struct Scratch_0
{
    uint16_t  partitions_0[256];
    CompressedTextureBlockPayload_0  blocks_0[4];
};


layout(std430, binding = 7) buffer StructuredBuffer_Scratch_t_0 {
    Scratch_0 _data[];
} g_scratch_0;

#line 57
layout(std430, binding = 2) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;



layout(std430, binding = 4) buffer StructuredBuffer_CompressedTextureBlockPayload_t_0 {
    CompressedTextureBlockPayload_0 _data[];
} g_compressedBlock3P_0;
layout(std430, binding = 5) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;

#line 113
const u8vec2  VALID_3P_QUANTIZATION_RANGES_0[6] = { u8vec2(uint8_t(7U), uint8_t(5U)), u8vec2(uint8_t(5U), uint8_t(7U)), u8vec2(uint8_t(4U), uint8_t(9U)), u8vec2(uint8_t(3U), uint8_t(11U)), u8vec2(uint8_t(2U), uint8_t(15U)), u8vec2(uint8_t(1U), uint8_t(23U)) };

#line 100
const u8vec2  VALID_2P_QUANTIZATION_RANGES_0[9] = { u8vec2(uint8_t(15U), uint8_t(5U)), u8vec2(uint8_t(11U), uint8_t(9U)), u8vec2(uint8_t(9U), uint8_t(11U)), u8vec2(uint8_t(7U), uint8_t(15U)), u8vec2(uint8_t(5U), uint8_t(23U)), u8vec2(uint8_t(4U), uint8_t(31U)), u8vec2(uint8_t(3U), uint8_t(39U)), u8vec2(uint8_t(2U), uint8_t(63U)), u8vec2(uint8_t(1U), uint8_t(95U)) };

#line 91
const u8vec2  VALID_1P_QUANTIZATION_RANGES_0[5] = { u8vec2(uint8_t(31U), uint8_t(31U)), u8vec2(uint8_t(23U), uint8_t(63U)), u8vec2(uint8_t(19U), uint8_t(95U)), u8vec2(uint8_t(15U), uint8_t(191U)), u8vec2(uint8_t(11U), uint8_t(255U)) };

#line 1022
uint blockIdx_0;


#line 347
struct CompressedTextureBlockProxyPayload_0
{
    int8_t index_0;
};


#line 391
struct CompressedTextureBlock_0
{
    CompressedTextureBlockProxyPayload_0 payload_0;
};


#line 355
u8vec3 CompressedTextureBlockProxyPayload_ep5_get_0(CompressedTextureBlockProxyPayload_0 this_0)
{

#line 356
    return g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_0.index_0]._ep5_0;
}


#line 400
f16vec3 CompressedTextureBlock_ep5_get_0(CompressedTextureBlock_0 this_1)
{

#line 401
    return f16vec3(CompressedTextureBlockProxyPayload_ep5_get_0(this_1.payload_0)) / 255.0HF;
}


#line 355
u8vec3 CompressedTextureBlockProxyPayload_ep4_get_0(CompressedTextureBlockProxyPayload_0 this_2)
{

#line 356
    return g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_2.index_0]._ep4_0;
}


#line 400
f16vec3 CompressedTextureBlock_ep4_get_0(CompressedTextureBlock_0 this_3)
{

#line 401
    return f16vec3(CompressedTextureBlockProxyPayload_ep4_get_0(this_3.payload_0)) / 255.0HF;
}


#line 355
u8vec3 CompressedTextureBlockProxyPayload_ep3_get_0(CompressedTextureBlockProxyPayload_0 this_4)
{

#line 356
    return g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_4.index_0]._ep3_0;
}


#line 400
f16vec3 CompressedTextureBlock_ep3_get_0(CompressedTextureBlock_0 this_5)
{

#line 401
    return f16vec3(CompressedTextureBlockProxyPayload_ep3_get_0(this_5.payload_0)) / 255.0HF;
}


#line 355
u8vec3 CompressedTextureBlockProxyPayload_ep2_get_0(CompressedTextureBlockProxyPayload_0 this_6)
{

#line 356
    return g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_6.index_0]._ep2_0;
}


#line 400
f16vec3 CompressedTextureBlock_ep2_get_0(CompressedTextureBlock_0 this_7)
{

#line 401
    return f16vec3(CompressedTextureBlockProxyPayload_ep2_get_0(this_7.payload_0)) / 255.0HF;
}


#line 355
u8vec3 CompressedTextureBlockProxyPayload_ep1_get_0(CompressedTextureBlockProxyPayload_0 this_8)
{

#line 356
    return g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_8.index_0]._ep1_0;
}


#line 400
f16vec3 CompressedTextureBlock_ep1_get_0(CompressedTextureBlock_0 this_9)
{

#line 401
    return f16vec3(CompressedTextureBlockProxyPayload_ep1_get_0(this_9.payload_0)) / 255.0HF;
}


#line 355
u8vec3 CompressedTextureBlockProxyPayload_ep0_get_0(CompressedTextureBlockProxyPayload_0 this_10)
{

#line 356
    return g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_10.index_0]._ep0_0;
}


#line 400
f16vec3 CompressedTextureBlock_ep0_get_0(CompressedTextureBlock_0 this_11)
{

#line 401
    return f16vec3(CompressedTextureBlockProxyPayload_ep0_get_0(this_11.payload_0)) / 255.0HF;
}


#line 355
PartitionMap_0 CompressedTextureBlockProxyPayload_partition_map_get_0(CompressedTextureBlockProxyPayload_0 this_12)
{

#line 356
    return g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_12.index_0].partition_map_0;
}


#line 418
PartitionMap_0 CompressedTextureBlock_partition_map_get_0(CompressedTextureBlock_0 this_13)
{

#line 419
    return CompressedTextureBlockProxyPayload_partition_map_get_0(this_13.payload_0);
}


#line 252
uint8_t PartitionMap_operatorx5Bx5D_get_0(PartitionMap_0 this_14, int n_0)
{

#line 253
    return uint8_t(((this_14.data_1) >> (n_0 * 2)) & 3U);
}


#line 682
float16_t estimate_partition_error_bound_0(f16mat3x3 scatter_matrix_0)
{

#line 689
    f16vec3 axis_0 = (((f16vec3(0.1700439453125HF, 0.830078125HF, 0.3798828125HF)) * (scatter_matrix_0)));

    f16vec3 axis_1 = (((axis_0 * (inversesqrt((dot(axis_0, axis_0) + 1.01327896118164062e-06HF)))) * (scatter_matrix_0)));


    return max(0.0HF, scatter_matrix_0[0][0] + scatter_matrix_0[1][1] + scatter_matrix_0[2][2] - sqrt(dot(axis_1, axis_1)));
}


#line 771
f16vec3 TextureBlock_operatorx5Bx5D_get_0(uint _S1, uint _S2)
{

#line 9
    return f16vec3(g_groundtruth_0._data[uint(_S1)].pixels_0[_S2]) / 255.0HF;
}


#line 698
float16_t compute_error_fast_0(CompressedTextureBlock_0 block_0)
{

    const f16vec3 _S3 = f16vec3(0.0HF);

#line 701
    f16vec3  means_0[2];

#line 701
    means_0[0] = _S3;

#line 701
    means_0[1] = _S3;


    const f16mat3x3 _S4 = f16mat3x3(0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF);

#line 704
    f16mat3x3  scatters_0[2];

#line 704
    scatters_0[0] = _S4;

#line 704
    scatters_0[1] = _S4;
    uint8_t  counts_0[2];

#line 705
    counts_0[0] = uint8_t(0U);

#line 705
    counts_0[1] = uint8_t(0U);
    PartitionMap_0 _S5 = CompressedTextureBlock_partition_map_get_0(block_0);

#line 706
    uint8_t i_0 = uint8_t(0U);
    for(;;)
    {

#line 707
        if(i_0 < uint8_t(16U))
        {
        }
        else
        {

#line 707
            break;
        }
        uint8_t _S6 = PartitionMap_operatorx5Bx5D_get_0(_S5, int(i_0));

#line 709
        f16vec3 _S7 = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_0));


        means_0[_S6] = means_0[_S6] + _S7;
        counts_0[_S6] = counts_0[_S6] + uint8_t(1U);


        scatters_0[_S6][0] = scatters_0[_S6][0] + _S7.x * _S7;
        scatters_0[_S6][1] = scatters_0[_S6][1] + _S7.y * _S7;
        scatters_0[_S6][2] = scatters_0[_S6][2] + _S7.z * _S7;

#line 707
        i_0 = i_0 + uint8_t(1U);

#line 707
    }

#line 707
    uint8_t p_0 = uint8_t(0U);

#line 707
    float16_t loss_0 = 0.0HF;

#line 722
    for(;;)
    {

#line 722
        if(int(p_0) < 2)
        {
        }
        else
        {

#line 722
            break;
        }
        if((counts_0[p_0]) > uint8_t(0U))
        {

            float16_t _S8 = float16_t(counts_0[p_0]);
            scatters_0[p_0][0] = scatters_0[p_0][0] - means_0[p_0].x / _S8 * means_0[p_0];
            scatters_0[p_0][1] = scatters_0[p_0][1] - means_0[p_0].y / _S8 * means_0[p_0];
            scatters_0[p_0][2] = scatters_0[p_0][2] - means_0[p_0].z / _S8 * means_0[p_0];

#line 730
            loss_0 = loss_0 + estimate_partition_error_bound_0(scatters_0[p_0]);

#line 724
        }

#line 722
        p_0 = p_0 + uint8_t(1U);

#line 722
    }

#line 735
    return loss_0;
}


#line 698
float16_t compute_error_fast_1(CompressedTextureBlock_0 block_1)
{

    const f16vec3 _S9 = f16vec3(0.0HF);

#line 701
    f16vec3  means_1[3];

#line 701
    means_1[0] = _S9;

#line 701
    means_1[1] = _S9;

#line 701
    means_1[2] = _S9;


    const f16mat3x3 _S10 = f16mat3x3(0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF);

#line 704
    f16mat3x3  scatters_1[3];

#line 704
    scatters_1[0] = _S10;

#line 704
    scatters_1[1] = _S10;

#line 704
    scatters_1[2] = _S10;
    uint8_t  counts_1[3];

#line 705
    counts_1[0] = uint8_t(0U);

#line 705
    counts_1[1] = uint8_t(0U);

#line 705
    counts_1[2] = uint8_t(0U);
    PartitionMap_0 _S11 = CompressedTextureBlock_partition_map_get_0(block_1);

#line 706
    uint8_t i_1 = uint8_t(0U);
    for(;;)
    {

#line 707
        if(i_1 < uint8_t(16U))
        {
        }
        else
        {

#line 707
            break;
        }
        uint8_t _S12 = PartitionMap_operatorx5Bx5D_get_0(_S11, int(i_1));

#line 709
        f16vec3 _S13 = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_1));


        means_1[_S12] = means_1[_S12] + _S13;
        counts_1[_S12] = counts_1[_S12] + uint8_t(1U);


        scatters_1[_S12][0] = scatters_1[_S12][0] + _S13.x * _S13;
        scatters_1[_S12][1] = scatters_1[_S12][1] + _S13.y * _S13;
        scatters_1[_S12][2] = scatters_1[_S12][2] + _S13.z * _S13;

#line 707
        i_1 = i_1 + uint8_t(1U);

#line 707
    }

#line 707
    uint8_t p_1 = uint8_t(0U);

#line 707
    float16_t loss_1 = 0.0HF;

#line 722
    for(;;)
    {

#line 722
        if(int(p_1) < 3)
        {
        }
        else
        {

#line 722
            break;
        }
        if((counts_1[p_1]) > uint8_t(0U))
        {

            float16_t _S14 = float16_t(counts_1[p_1]);
            scatters_1[p_1][0] = scatters_1[p_1][0] - means_1[p_1].x / _S14 * means_1[p_1];
            scatters_1[p_1][1] = scatters_1[p_1][1] - means_1[p_1].y / _S14 * means_1[p_1];
            scatters_1[p_1][2] = scatters_1[p_1][2] - means_1[p_1].z / _S14 * means_1[p_1];

#line 730
            loss_1 = loss_1 + estimate_partition_error_bound_0(scatters_1[p_1]);

#line 724
        }

#line 722
        p_1 = p_1 + uint8_t(1U);

#line 722
    }

#line 735
    return loss_1;
}


#line 355
BF8Weights_0 CompressedTextureBlockProxyPayload_weights_get_0(CompressedTextureBlockProxyPayload_0 this_15)
{

#line 356
    return g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_15.index_0].weights_0;
}


#line 418
BF8Weights_0 CompressedTextureBlock_weights_get_0(CompressedTextureBlock_0 this_16)
{

#line 419
    return CompressedTextureBlockProxyPayload_weights_get_0(this_16.payload_0);
}


#line 13393 1
float16_t saturate_0(float16_t x_0)
{

#line 13401
    return clamp(x_0, 0.0HF, 1.0HF);
}


#line 443 0
void CompressedTextureBlock_solve_weights_0(inout CompressedTextureBlock_0 this_17)
{

    f16vec3 _S15 = CompressedTextureBlock_ep1_get_0(this_17) - CompressedTextureBlock_ep0_get_0(this_17);
    f16vec3 _S16 = CompressedTextureBlock_ep3_get_0(this_17) - CompressedTextureBlock_ep2_get_0(this_17);
    f16vec3 _S17 = CompressedTextureBlock_ep5_get_0(this_17) - CompressedTextureBlock_ep4_get_0(this_17);
    float16_t _S18 = 1.0HF / (dot(_S15, _S15) + 1.01327896118164062e-06HF);
    float16_t _S19 = 1.0HF / (dot(_S16, _S16) + 1.01327896118164062e-06HF);
    float16_t _S20 = 1.0HF / (dot(_S17, _S17) + 1.01327896118164062e-06HF);
    PartitionMap_0 _S21 = CompressedTextureBlock_partition_map_get_0(this_17);

#line 452
    int i_2 = 0;
    for(;;)
    {

#line 453
        if(i_2 < 16)
        {
        }
        else
        {

#line 453
            break;
        }

#line 453
        f16vec3 _S22 = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_2));


        uint8_t _S23 = PartitionMap_operatorx5Bx5D_get_0(_S21, i_2);
        bool _S24 = _S23 == uint8_t(0U);

#line 457
        float16_t _S25;

#line 457
        if(_S24)
        {

#line 457
            _S25 = dot(_S22 - CompressedTextureBlock_ep0_get_0(this_17), _S15);

#line 457
        }
        else
        {

#line 457
            if(_S23 == uint8_t(1U))
            {

#line 457
                _S25 = dot(_S22 - CompressedTextureBlock_ep2_get_0(this_17), _S16);

#line 457
            }
            else
            {

#line 457
                _S25 = dot(_S22 - CompressedTextureBlock_ep4_get_0(this_17), _S17);

#line 457
            }

#line 457
        }

#line 457
        float16_t _S26;
        if(_S24)
        {

#line 458
            _S26 = _S18;

#line 458
        }
        else
        {

#line 458
            if(_S23 == uint8_t(1U))
            {

#line 458
                _S26 = _S19;

#line 458
            }
            else
            {

#line 458
                _S26 = _S20;

#line 458
            }

#line 458
        }

        float16_t _S27 = saturate_0(_S25 * _S26);

#line 460
        BF8Weights_0 _S28 = CompressedTextureBlock_weights_get_0(this_17);

#line 460
        _S28.data_0[i_2] = uint8_t(round(saturate_0(_S27) * 63.0HF));

#line 460
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_17.payload_0.index_0].weights_0 = _S28;

#line 453
        i_2 = i_2 + 1;

#line 453
    }

#line 462
    return;
}


#line 13408 1
f16vec3 saturate_1(f16vec3 x_1)
{

#line 13416
    return clamp(x_1, f16vec3(0.0HF), f16vec3(1.0HF));
}


#line 579 0
void solve_pca_eps_0(inout CompressedTextureBlock_0 block_2, inout f16vec3 ep0_0, inout f16vec3 ep1_0, uint8_t partition_id_0)
{



    const f16vec3 _S29 = f16vec3(0.1700439453125HF, 0.830078125HF, 0.3798828125HF);
    f16vec3 _S30 = f16vec3(ivec3(0));

#line 585
    uint8_t i_3 = uint8_t(0U);

#line 585
    f16vec3 centroid_0 = _S30;

#line 585
    uint8_t count_0 = uint8_t(0U);


    for(;;)
    {

#line 588
        if(i_3 < uint8_t(16U))
        {
        }
        else
        {

#line 588
            break;
        }
        if((PartitionMap_operatorx5Bx5D_get_0(CompressedTextureBlock_partition_map_get_0(block_2), int(i_3))) == partition_id_0)
        {

            uint8_t count_1 = count_0 + uint8_t(1U);

#line 593
            centroid_0 = centroid_0 + TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_3));

#line 593
            count_0 = count_1;

#line 590
        }

#line 588
        i_3 = i_3 + uint8_t(1U);

#line 588
    }

#line 596
    float16_t _S31 = float16_t(count_0);

#line 596
    f16vec3 centroid_1 = centroid_0 / _S31;

    if(count_0 == uint8_t(0U))
    {

#line 599
        return;
    }
    if(count_0 == uint8_t(1U))
    {
        f16vec3 _S32 = saturate_1(centroid_1);

#line 603
        ep0_0 = _S32;
        ep1_0 = _S32;
        return;
    }

    f16mat3x3 C_0 = f16mat3x3(0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF, 0.0HF);

#line 608
    i_3 = uint8_t(0U);
    for(;;)
    {

#line 609
        if(i_3 < uint8_t(16U))
        {
        }
        else
        {

#line 609
            break;
        }
        if((PartitionMap_operatorx5Bx5D_get_0(CompressedTextureBlock_partition_map_get_0(block_2), int(i_3))) == partition_id_0)
        {
            f16vec3 d_0 = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_3)) - centroid_1;
            C_0[0] = C_0[0] + d_0.x * d_0;
            C_0[1] = C_0[1] + d_0.y * d_0;
            C_0[2] = C_0[2] + d_0.z * d_0;

#line 611
        }

#line 609
        i_3 = i_3 + uint8_t(1U);

#line 609
    }

#line 619
    C_0 = C_0 / _S31;



    if(float(C_0[0].x + C_0[1].y + C_0[2].z) < 0.00030000001424924)
    {
        f16vec3 _S33 = saturate_1(centroid_1);

#line 625
        ep0_0 = _S33;
        ep1_0 = _S33;
        return;
    }

#line 627
    int iter_0 = 0;

#line 627
    f16vec3 axis_2 = _S29;


    for(;;)
    {

#line 630
        if(iter_0 < 4)
        {
        }
        else
        {

#line 630
            break;
        }
        f16vec3 axis_3 = (((axis_2) * (C_0)));
        float16_t lenSq_0 = dot(axis_3, axis_3);
        if(float(lenSq_0) > 9.99999993922529029e-09)
        {

#line 634
            axis_2 = axis_3 * (inversesqrt((lenSq_0)));

#line 634
        }
        else
        {

#line 634
            axis_2 = axis_3;

#line 634
        }

#line 630
        iter_0 = iter_0 + 1;

#line 630
    }

#line 641
    if(float(dot(axis_2, axis_2)) < 9.99999993922529029e-09)
    {
        ep0_0 = saturate_1(centroid_1);
        return;
    }

    f16vec3 axis_4 = normalize(axis_2);

#line 647
    float16_t min_t_0 = 1000.0HF;

#line 647
    float16_t max_t_0 = -1000.0HF;

#line 647
    int i_4 = 0;



    for(;;)
    {

#line 651
        if(i_4 < 16)
        {
        }
        else
        {

#line 651
            break;
        }
        if((PartitionMap_operatorx5Bx5D_get_0(CompressedTextureBlock_partition_map_get_0(block_2), i_4)) == partition_id_0)
        {

            float16_t t_0 = dot(TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_4)) - centroid_1, axis_4);

            float16_t _S34 = max(max_t_0, t_0);

#line 658
            min_t_0 = min(min_t_0, t_0);

#line 658
            max_t_0 = _S34;

#line 653
        }

#line 651
        i_4 = i_4 + 1;

#line 651
    }

#line 662
    ep0_0 = saturate_1(centroid_1 + axis_4 * min_t_0);
    ep1_0 = saturate_1(centroid_1 + axis_4 * max_t_0);
    return;
}


#line 355
uint8_t CompressedTextureBlockProxyPayload_max_partitions_get_0(CompressedTextureBlockProxyPayload_0 this_18)
{

#line 356
    return g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_18.index_0].max_partitions_1;
}


#line 418
uint8_t CompressedTextureBlock_max_partitions_get_0(CompressedTextureBlock_0 this_19)
{

#line 419
    return CompressedTextureBlockProxyPayload_max_partitions_get_0(this_19.payload_0);
}


#line 247
PartitionMap_0 PartitionMap_x24init_0(uint data_2)
{

#line 247
    PartitionMap_0 _S35;

    _S35.data_1 = data_2;

#line 247
    return _S35;
}


#line 435
void CompressedTextureBlock_set_astc_seed_0(inout CompressedTextureBlock_0 this_20, uint16_t seed_1)
{

    g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_20.payload_0.index_0].astc_seed_0 = seed_1;

#line 438
    PartitionMap_0 _S36;
    if((CompressedTextureBlock_max_partitions_get_0(this_20)) == uint8_t(2U))
    {

#line 439
        _S36 = PartitionMap_x24init_0(g_lut_0.lut2_0[seed_1]);

#line 439
    }
    else
    {

#line 439
        _S36 = PartitionMap_x24init_0(g_lut_0.lut3_0[seed_1]);

#line 439
    }

#line 439
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_20.payload_0.index_0].partition_map_0 = _S36;
    return;
}


#line 767
void cluster_0(inout PartitionMap_0 partition_map_1)
{

    f16vec3  centroids_0[2];
    uint8_t  partition_counts_0[2];

#line 771
    uint8_t k_0 = uint8_t(0U);


    [[unroll]]
    for(;;)
    {

#line 774
        if(int(k_0) < 2)
        {
        }
        else
        {

#line 774
            break;
        }
        centroids_0[k_0] = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(k_0 * uint8_t(4U) % uint8_t(16U)));

#line 774
        k_0 = k_0 + uint8_t(1U);

#line 774
    }

#line 774
    uint8_t iter_1 = uint8_t(0U);

#line 779
    for(;;)
    {

#line 779
        if(iter_1 < uint8_t(3U))
        {
        }
        else
        {

#line 779
            break;
        }

#line 779
        uint8_t c_0 = uint8_t(0U);



        [[unroll]]
        for(;;)
        {

#line 783
            if(int(c_0) < 2)
            {
            }
            else
            {

#line 783
                break;
            }

#line 784
            partition_counts_0[c_0] = uint8_t(0U);

#line 783
            c_0 = c_0 + uint8_t(1U);

#line 783
        }

#line 783
        uint8_t centroid_2;

#line 783
        uint8_t best_centroid_0;

#line 783
        uint8_t i_5 = uint8_t(0U);


        for(;;)
        {

#line 786
            if(i_5 < uint8_t(16U))
            {
            }
            else
            {

#line 786
                break;
            }

#line 786
            f16vec3 _S37 = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_5));

#line 786
            float16_t best_dist_0 = 1000.0HF;

#line 786
            best_centroid_0 = uint8_t(0U);

#line 786
            centroid_2 = uint8_t(0U);

#line 794
            for(;;)
            {

#line 794
                if(int(centroid_2) < 2)
                {
                }
                else
                {

#line 794
                    break;
                }
                f16vec3 delta_0 = _S37 - centroids_0[centroid_2];
                float16_t d_1 = dot(delta_0, delta_0);
                if(d_1 < best_dist_0)
                {

#line 798
                    best_dist_0 = d_1;

#line 798
                    best_centroid_0 = centroid_2;

#line 798
                }

#line 794
                centroid_2 = centroid_2 + uint8_t(1U);

#line 794
            }

#line 805
            int _S38 = int(i_5) * 2;

#line 805
            partition_map_1.data_1 = ((partition_map_1.data_1) & uint(~(3 << _S38))) | uint(best_centroid_0 << _S38);
            partition_counts_0[best_centroid_0] = partition_counts_0[best_centroid_0] + uint8_t(1U);

#line 786
            i_5 = i_5 + uint8_t(1U);

#line 786
        }

#line 786
        bool changed_map_0;

#line 786
        bool changed_map_1 = false;

#line 786
        best_centroid_0 = uint8_t(0U);

#line 810
        for(;;)
        {

#line 810
            if(int(best_centroid_0) < 2)
            {
            }
            else
            {

#line 810
                break;
            }
            if((partition_counts_0[best_centroid_0]) == uint8_t(0U))
            {


                int _S39 = int((best_centroid_0 * uint8_t(4U) + uint8_t(1U)) % uint8_t(16U));
                if((partition_counts_0[PartitionMap_operatorx5Bx5D_get_0(partition_map_1, _S39)]) > uint8_t(1U))
                {
                    int _S40 = _S39 * 2;

#line 819
                    partition_map_1.data_1 = ((partition_map_1.data_1) & uint(~(3 << _S40))) | uint(best_centroid_0 << _S40);
                    partition_counts_0[best_centroid_0] = partition_counts_0[best_centroid_0] + uint8_t(1U);
                    partition_counts_0[PartitionMap_operatorx5Bx5D_get_0(partition_map_1, _S39)] = partition_counts_0[PartitionMap_operatorx5Bx5D_get_0(partition_map_1, _S39)] - uint8_t(1U);

#line 821
                    changed_map_0 = true;

#line 817
                }
                else
                {

#line 817
                    changed_map_0 = changed_map_1;

#line 817
                }

#line 817
                changed_map_1 = changed_map_0;

#line 812
            }

#line 810
            best_centroid_0 = best_centroid_0 + uint8_t(1U);

#line 810
        }

#line 828
        if(iter_1 < uint8_t(2U))
        {

#line 828
            changed_map_0 = true;

#line 828
        }
        else
        {

#line 828
            changed_map_0 = changed_map_1;

#line 828
        }

#line 828
        if(changed_map_0)
        {
            const f16vec3 _S41 = f16vec3(0.0HF);

#line 830
            f16vec3  new_sums_0[2];

#line 830
            new_sums_0[0] = _S41;

#line 830
            new_sums_0[1] = _S41;

#line 830
            uint8_t i_6 = uint8_t(0U);
            for(;;)
            {

#line 831
                if(i_6 < uint8_t(16U))
                {
                }
                else
                {

#line 831
                    break;
                }


                new_sums_0[PartitionMap_operatorx5Bx5D_get_0(partition_map_1, int(i_6))] = new_sums_0[PartitionMap_operatorx5Bx5D_get_0(partition_map_1, int(i_6))] + TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_6));

#line 831
                i_6 = i_6 + uint8_t(1U);

#line 831
            }

#line 831
            centroid_2 = uint8_t(0U);

#line 837
            for(;;)
            {

#line 837
                if(int(centroid_2) < 2)
                {
                }
                else
                {

#line 837
                    break;
                }
                uint8_t count_2 = partition_counts_0[centroid_2];
                if((partition_counts_0[centroid_2]) != uint8_t(0U))
                {
                    centroids_0[centroid_2] = new_sums_0[centroid_2] / float16_t(count_2);

#line 840
                }

#line 837
                centroid_2 = centroid_2 + uint8_t(1U);

#line 837
            }

#line 828
        }

#line 779
        iter_1 = iter_1 + uint8_t(1U);

#line 779
    }

#line 849
    return;
}


#line 767
void cluster_1(inout PartitionMap_0 partition_map_2)
{

    f16vec3  centroids_1[3];
    uint8_t  partition_counts_1[3];

#line 771
    uint8_t k_1 = uint8_t(0U);


    [[unroll]]
    for(;;)
    {

#line 774
        if(int(k_1) < 3)
        {
        }
        else
        {

#line 774
            break;
        }
        centroids_1[k_1] = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(k_1 * uint8_t(4U) % uint8_t(16U)));

#line 774
        k_1 = k_1 + uint8_t(1U);

#line 774
    }

#line 774
    uint8_t iter_2 = uint8_t(0U);

#line 779
    for(;;)
    {

#line 779
        if(iter_2 < uint8_t(3U))
        {
        }
        else
        {

#line 779
            break;
        }

#line 779
        uint8_t c_1 = uint8_t(0U);



        [[unroll]]
        for(;;)
        {

#line 783
            if(int(c_1) < 3)
            {
            }
            else
            {

#line 783
                break;
            }

#line 784
            partition_counts_1[c_1] = uint8_t(0U);

#line 783
            c_1 = c_1 + uint8_t(1U);

#line 783
        }

#line 783
        uint8_t centroid_3;

#line 783
        uint8_t best_centroid_1;

#line 783
        uint8_t i_7 = uint8_t(0U);


        for(;;)
        {

#line 786
            if(i_7 < uint8_t(16U))
            {
            }
            else
            {

#line 786
                break;
            }

#line 786
            f16vec3 _S42 = TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_7));

#line 786
            float16_t best_dist_1 = 1000.0HF;

#line 786
            best_centroid_1 = uint8_t(0U);

#line 786
            centroid_3 = uint8_t(0U);

#line 794
            for(;;)
            {

#line 794
                if(int(centroid_3) < 3)
                {
                }
                else
                {

#line 794
                    break;
                }
                f16vec3 delta_1 = _S42 - centroids_1[centroid_3];
                float16_t d_2 = dot(delta_1, delta_1);
                if(d_2 < best_dist_1)
                {

#line 798
                    best_dist_1 = d_2;

#line 798
                    best_centroid_1 = centroid_3;

#line 798
                }

#line 794
                centroid_3 = centroid_3 + uint8_t(1U);

#line 794
            }

#line 805
            int _S43 = int(i_7) * 2;

#line 805
            partition_map_2.data_1 = ((partition_map_2.data_1) & uint(~(3 << _S43))) | uint(best_centroid_1 << _S43);
            partition_counts_1[best_centroid_1] = partition_counts_1[best_centroid_1] + uint8_t(1U);

#line 786
            i_7 = i_7 + uint8_t(1U);

#line 786
        }

#line 786
        bool changed_map_2;

#line 786
        bool changed_map_3 = false;

#line 786
        best_centroid_1 = uint8_t(0U);

#line 810
        for(;;)
        {

#line 810
            if(int(best_centroid_1) < 3)
            {
            }
            else
            {

#line 810
                break;
            }
            if((partition_counts_1[best_centroid_1]) == uint8_t(0U))
            {


                int _S44 = int((best_centroid_1 * uint8_t(4U) + uint8_t(1U)) % uint8_t(16U));
                if((partition_counts_1[PartitionMap_operatorx5Bx5D_get_0(partition_map_2, _S44)]) > uint8_t(1U))
                {
                    int _S45 = _S44 * 2;

#line 819
                    partition_map_2.data_1 = ((partition_map_2.data_1) & uint(~(3 << _S45))) | uint(best_centroid_1 << _S45);
                    partition_counts_1[best_centroid_1] = partition_counts_1[best_centroid_1] + uint8_t(1U);
                    partition_counts_1[PartitionMap_operatorx5Bx5D_get_0(partition_map_2, _S44)] = partition_counts_1[PartitionMap_operatorx5Bx5D_get_0(partition_map_2, _S44)] - uint8_t(1U);

#line 821
                    changed_map_2 = true;

#line 817
                }
                else
                {

#line 817
                    changed_map_2 = changed_map_3;

#line 817
                }

#line 817
                changed_map_3 = changed_map_2;

#line 812
            }

#line 810
            best_centroid_1 = best_centroid_1 + uint8_t(1U);

#line 810
        }

#line 828
        if(iter_2 < uint8_t(2U))
        {

#line 828
            changed_map_2 = true;

#line 828
        }
        else
        {

#line 828
            changed_map_2 = changed_map_3;

#line 828
        }

#line 828
        if(changed_map_2)
        {
            const f16vec3 _S46 = f16vec3(0.0HF);

#line 830
            f16vec3  new_sums_1[3];

#line 830
            new_sums_1[0] = _S46;

#line 830
            new_sums_1[1] = _S46;

#line 830
            new_sums_1[2] = _S46;

#line 830
            uint8_t i_8 = uint8_t(0U);
            for(;;)
            {

#line 831
                if(i_8 < uint8_t(16U))
                {
                }
                else
                {

#line 831
                    break;
                }


                new_sums_1[PartitionMap_operatorx5Bx5D_get_0(partition_map_2, int(i_8))] = new_sums_1[PartitionMap_operatorx5Bx5D_get_0(partition_map_2, int(i_8))] + TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_8));

#line 831
                i_8 = i_8 + uint8_t(1U);

#line 831
            }

#line 831
            centroid_3 = uint8_t(0U);

#line 837
            for(;;)
            {

#line 837
                if(int(centroid_3) < 3)
                {
                }
                else
                {

#line 837
                    break;
                }
                uint8_t count_3 = partition_counts_1[centroid_3];
                if((partition_counts_1[centroid_3]) != uint8_t(0U))
                {
                    centroids_1[centroid_3] = new_sums_1[centroid_3] / float16_t(count_3);

#line 840
                }

#line 837
                centroid_3 = centroid_3 + uint8_t(1U);

#line 837
            }

#line 828
        }

#line 779
        iter_2 = iter_2 + uint8_t(1U);

#line 779
    }

#line 849
    return;
}


#line 871
struct RankedSeeds_0
{
    uint  seeds_masks_0[32];
};


#line 864
shared RankedSeeds_0  s_ranked_seeds_0[64];


#line 871
RankedSeeds_0 RankedSeeds_x24init_0(uint  seeds_masks_1[32])
{

#line 871
    RankedSeeds_0 _S47;

#line 878
    _S47.seeds_masks_0 = seeds_masks_1;

#line 871
    return _S47;
}


#line 206
uint8_t count_diffs_0(uint val_0)
{
    return uint8_t(bitCount((val_0 | (val_0 >> 1)) & 1431655765U));
}


#line 183
uint8_t best_perm_distance_s2_0(uint x_2, uint y_0)
{
    uint base_0 = x_2 ^ y_0;

#line 195
    return uint8_t((min(uint(((count_diffs_0(base_0)) << 1) | uint8_t(0U)), uint(((count_diffs_0(base_0 ^ ((~(x_2 >> 1)) & 1431655765U))) << 1) | uint8_t(1U)))) >> 1);
}


#line 154
uint8_t best_perm_distance_s3_0(uint x_3, uint y_1)
{
    uint base_1 = x_3 ^ y_1;

    uint x_shr1_0 = x_3 >> 1;
    uint nz_0 = (x_3 | x_shr1_0) & 1431655765U;
    uint nz_shl1_0 = nz_0 << 1;

    uint m01_0 = (~x_shr1_0) & 1431655765U;

#line 180
    return uint8_t((min(min(min(uint(((count_diffs_0(base_1)) << 3) | uint8_t(0U)), uint(((count_diffs_0(base_1 ^ m01_0)) << 3) | uint8_t(1U))), min(uint(((count_diffs_0(base_1 ^ ((~(x_3 << 1)) & 2863311530U))) << 3) | uint8_t(2U)), uint(((count_diffs_0(base_1 ^ (nz_0 | nz_shl1_0))) << 3) | uint8_t(3U)))), min(uint(((count_diffs_0(base_1 ^ (m01_0 | nz_shl1_0))) << 3) | uint8_t(4U)), uint(((count_diffs_0(base_1 ^ (nz_0 | (((~x_3) & 1431655765U) << 1)))) << 3) | uint8_t(5U))))) >> 3);
}


#line 884
bool RankedSeeds_add_0(uint16_t seed_2, uint16_t distance_0, uint8_t slots_0, inout uint8_t  counts_2[8])
{
    uint8_t _S48 = counts_2[distance_0];
    if((counts_2[distance_0]) < slots_0)
    {
        uint16_t _S49 = distance_0 * uint16_t(12US) + uint16_t(_S48);

#line 880
        s_ranked_seeds_0[blockIdx_0 % 64U].seeds_masks_0[_S49 / uint16_t(3US)] = (s_ranked_seeds_0[blockIdx_0 % 64U].seeds_masks_0[_S49 / uint16_t(3US)]) | (uint(seed_2 + uint16_t(1US)) << uint(_S49 % uint16_t(3US) * uint16_t(10US)));

#line 891
        counts_2[distance_0] = _S48 + uint8_t(1U);
        return true;
    }
    return false;
}


#line 912
uint8_t find_top_partitions_0(inout CompressedTextureBlock_0 block_3, uint candidates_0, inout uint16_t i_9)
{

#line 919
    uint8_t _S50 = uint8_t(clamp(candidates_0 / 8U, 2U, 12U));
    uint8_t  distances_0[8];

#line 920
    distances_0[0] = uint8_t(0U);

#line 920
    distances_0[1] = uint8_t(0U);

#line 920
    distances_0[2] = uint8_t(0U);

#line 920
    distances_0[3] = uint8_t(0U);

#line 920
    distances_0[4] = uint8_t(0U);

#line 920
    distances_0[5] = uint8_t(0U);

#line 920
    distances_0[6] = uint8_t(0U);

#line 920
    distances_0[7] = uint8_t(0U);

#line 917
    PartitionMap_0 ideal_map_0;

#line 923
    cluster_0(ideal_map_0);


    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_3.payload_0.index_0].ideal_partition_map_0 = ideal_map_0;

#line 878
    const uint  _S51[32] = { 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U };

#line 927
    s_ranked_seeds_0[blockIdx_0 % 64U] = RankedSeeds_x24init_0(_S51);

    i_9 = uint16_t(0US);

#line 929
    uint8_t count_4 = uint8_t(0U);

#line 929
    for(;;)
    {

#line 929
        if(i_9 < uint16_t(1024US))
        {
        }
        else
        {

#line 929
            break;
        }

        uint8_t _S52 = best_perm_distance_s2_0(ideal_map_0.data_1, g_lut_0.lut2_0[i_9]);

        if(_S52 < uint8_t(8U))
        {
            bool _S53 = RankedSeeds_add_0(i_9, uint16_t(_S52), _S50, distances_0);

#line 936
            uint8_t count_5 = count_4 + uint8_t(_S53);
            if(int(count_5) >= 96)
            {

#line 937
                count_4 = count_5;

                break;
            }

#line 939
            count_4 = count_5;

#line 934
        }

#line 929
        i_9 = i_9 + uint16_t(1US);

#line 929
    }

#line 945
    return count_4;
}


#line 912
uint8_t find_top_partitions_1(inout CompressedTextureBlock_0 block_4, uint candidates_1, inout uint16_t i_10)
{

#line 919
    uint8_t _S54 = uint8_t(clamp(candidates_1 / 8U, 2U, 12U));
    uint8_t  distances_1[8];

#line 920
    distances_1[0] = uint8_t(0U);

#line 920
    distances_1[1] = uint8_t(0U);

#line 920
    distances_1[2] = uint8_t(0U);

#line 920
    distances_1[3] = uint8_t(0U);

#line 920
    distances_1[4] = uint8_t(0U);

#line 920
    distances_1[5] = uint8_t(0U);

#line 920
    distances_1[6] = uint8_t(0U);

#line 920
    distances_1[7] = uint8_t(0U);

#line 917
    PartitionMap_0 ideal_map_1;

#line 923
    cluster_1(ideal_map_1);


    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_4.payload_0.index_0].ideal_partition_map_0 = ideal_map_1;

#line 878
    const uint  _S55[32] = { 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U };

#line 927
    s_ranked_seeds_0[blockIdx_0 % 64U] = RankedSeeds_x24init_0(_S55);

    i_10 = uint16_t(0US);

#line 929
    uint8_t count_6 = uint8_t(0U);

#line 929
    for(;;)
    {

#line 929
        if(i_10 < uint16_t(1024US))
        {
        }
        else
        {

#line 929
            break;
        }


        uint8_t _S56 = best_perm_distance_s3_0(ideal_map_1.data_1, g_lut_0.lut3_0[i_10]);
        if(_S56 < uint8_t(8U))
        {
            bool _S57 = RankedSeeds_add_0(i_10, uint16_t(_S56), _S54, distances_1);

#line 936
            uint8_t count_7 = count_6 + uint8_t(_S57);
            if(int(count_7) >= 96)
            {

#line 937
                count_6 = count_7;

                break;
            }

#line 939
            count_6 = count_7;

#line 934
        }

#line 929
        i_10 = i_10 + uint16_t(1US);

#line 929
    }

#line 945
    return count_6;
}


#line 897
int16_t RankedSeeds_next_0(inout uint8_t cursor_0)
{
    for(;;)
    {

#line 899
        if(int(cursor_0) < 96)
        {
        }
        else
        {

#line 899
            break;
        }

#line 879
        uint16_t _S58 = uint16_t((s_ranked_seeds_0[blockIdx_0 % 64U].seeds_masks_0[cursor_0 / uint8_t(3U)]) >> uint(cursor_0 % uint8_t(3U) * uint8_t(10U))) & uint16_t(1023US);

#line 902
        if(_S58 == uint16_t(0US))
        {

#line 899
            cursor_0 = cursor_0 + uint8_t(1U);

#line 899
            continue;
        }

#line 906
        cursor_0 = cursor_0 + uint8_t(1U);
        return int16_t(_S58 - uint16_t(1US));
    }
    return int16_t(-1S);
}


#line 949
float optimize_0(inout CompressedTextureBlock_0 block_5, uint steps_1, bool diagnostics_enabled_0, bool exhaustive_1)
{

#line 997
    f16vec3 _S59 = CompressedTextureBlock_ep0_get_0(block_5);

#line 997
    f16vec3 _S60 = CompressedTextureBlock_ep1_get_0(block_5);

#line 997
    solve_pca_eps_0(block_5, _S59, _S60, uint8_t(0U));

#line 997
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_5.payload_0.index_0]._ep0_0 = u8vec3(round(saturate_1(_S59) * 255.0HF));

#line 997
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_5.payload_0.index_0]._ep1_0 = u8vec3(round(saturate_1(_S60) * 255.0HF));

#line 1002
    CompressedTextureBlock_solve_weights_0(block_5);

#line 1015
    return 1000.0;
}


#line 949
float optimize_1(inout CompressedTextureBlock_0 block_6, uint steps_2, bool diagnostics_enabled_1, bool exhaustive_2)
{

#line 957
    uint16_t max_seeds_checked_0 = uint16_t(0US);

#line 957
    uint8_t nearest_neighbors_0;

    if(!exhaustive_2)
    {

        uint8_t _S61 = find_top_partitions_0(block_6, steps_2, max_seeds_checked_0);

#line 962
        nearest_neighbors_0 = _S61;

#line 959
    }
    else
    {

#line 959
        nearest_neighbors_0 = uint8_t(0U);

#line 959
    }

#line 968
    uint8_t cursor_1 = uint8_t(0U);

#line 968
    float best_loss_0 = 1000.0;

#line 968
    uint16_t best_seed_0 = uint16_t(0US);

#line 968
    uint16_t candidate_id_0 = uint16_t(0US);



    for(;;)
    {

#line 972
        if(uint(candidate_id_0) < steps_2)
        {
        }
        else
        {

#line 972
            break;
        }
        uint16_t _S62 = uint16_t(nearest_neighbors_0);

#line 974
        uint16_t next_unchecked_seed_0 = candidate_id_0 - _S62 + max_seeds_checked_0;

#line 974
        uint16_t _S63;
        if(exhaustive_2)
        {

#line 975
            _S63 = candidate_id_0;

#line 975
        }
        else
        {

#line 975
            if(candidate_id_0 < _S62)
            {

#line 975
                int16_t _S64 = RankedSeeds_next_0(cursor_1);

#line 975
                _S63 = uint16_t(_S64);

#line 975
            }
            else
            {

#line 975
                _S63 = next_unchecked_seed_0;

#line 975
            }

#line 975
        }
        uint16_t _S65 = uint16_t(int16_t(_S63));

#line 976
        CompressedTextureBlock_set_astc_seed_0(block_6, _S65);
        float loss_2 = float(compute_error_fast_0(block_6));

        if(loss_2 < best_loss_0)
        {

#line 979
            best_loss_0 = loss_2;

#line 979
            best_seed_0 = _S65;

#line 979
        }

#line 979
        bool _S66;

#line 986
        if(diagnostics_enabled_1)
        {

#line 986
            _S66 = candidate_id_0 < uint16_t(10US);

#line 986
        }
        else
        {

#line 986
            _S66 = false;

#line 986
        }

#line 986
        if(_S66)
        {
            uvec2 _S67 = (clockRealtime2x32EXT());

#line 988
            g_diagnostics_0._data[uint(blockIdx_0)].timestamps_0[candidate_id_0] = _S67;
            g_diagnostics_0._data[uint(blockIdx_0)].loss_log_0[candidate_id_0][1] = loss_2;

#line 986
        }

#line 972
        candidate_id_0 = candidate_id_0 + uint16_t(1US);

#line 972
    }

#line 995
    CompressedTextureBlock_set_astc_seed_0(block_6, best_seed_0);

    f16vec3 _S68 = CompressedTextureBlock_ep0_get_0(block_6);

#line 997
    f16vec3 _S69 = CompressedTextureBlock_ep1_get_0(block_6);

#line 997
    solve_pca_eps_0(block_6, _S68, _S69, uint8_t(0U));

#line 997
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_6.payload_0.index_0]._ep0_0 = u8vec3(round(saturate_1(_S68) * 255.0HF));

#line 997
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_6.payload_0.index_0]._ep1_0 = u8vec3(round(saturate_1(_S69) * 255.0HF));

    f16vec3 _S70 = CompressedTextureBlock_ep2_get_0(block_6);

#line 999
    f16vec3 _S71 = CompressedTextureBlock_ep3_get_0(block_6);

#line 999
    solve_pca_eps_0(block_6, _S70, _S71, uint8_t(1U));

#line 999
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_6.payload_0.index_0]._ep2_0 = u8vec3(round(saturate_1(_S70) * 255.0HF));

#line 999
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_6.payload_0.index_0]._ep3_0 = u8vec3(round(saturate_1(_S71) * 255.0HF));


    CompressedTextureBlock_solve_weights_0(block_6);

#line 1015
    return best_loss_0;
}


#line 949
float optimize_2(inout CompressedTextureBlock_0 block_7, uint steps_3, bool diagnostics_enabled_2, bool exhaustive_3)
{

#line 957
    uint16_t max_seeds_checked_1 = uint16_t(0US);

#line 957
    uint8_t nearest_neighbors_1;

    if(!exhaustive_3)
    {

        uint8_t _S72 = find_top_partitions_1(block_7, steps_3, max_seeds_checked_1);

#line 962
        nearest_neighbors_1 = _S72;

#line 959
    }
    else
    {

#line 959
        nearest_neighbors_1 = uint8_t(0U);

#line 959
    }

#line 968
    uint8_t cursor_2 = uint8_t(0U);

#line 968
    float best_loss_1 = 1000.0;

#line 968
    uint16_t best_seed_1 = uint16_t(0US);

#line 968
    uint16_t candidate_id_1 = uint16_t(0US);



    for(;;)
    {

#line 972
        if(uint(candidate_id_1) < steps_3)
        {
        }
        else
        {

#line 972
            break;
        }
        uint16_t _S73 = uint16_t(nearest_neighbors_1);

#line 974
        uint16_t next_unchecked_seed_1 = candidate_id_1 - _S73 + max_seeds_checked_1;

#line 974
        uint16_t _S74;
        if(exhaustive_3)
        {

#line 975
            _S74 = candidate_id_1;

#line 975
        }
        else
        {

#line 975
            if(candidate_id_1 < _S73)
            {

#line 975
                int16_t _S75 = RankedSeeds_next_0(cursor_2);

#line 975
                _S74 = uint16_t(_S75);

#line 975
            }
            else
            {

#line 975
                _S74 = next_unchecked_seed_1;

#line 975
            }

#line 975
        }
        uint16_t _S76 = uint16_t(int16_t(_S74));

#line 976
        CompressedTextureBlock_set_astc_seed_0(block_7, _S76);
        float loss_3 = float(compute_error_fast_1(block_7));

        if(loss_3 < best_loss_1)
        {

#line 979
            best_loss_1 = loss_3;

#line 979
            best_seed_1 = _S76;

#line 979
        }

#line 979
        bool _S77;

#line 986
        if(diagnostics_enabled_2)
        {

#line 986
            _S77 = candidate_id_1 < uint16_t(10US);

#line 986
        }
        else
        {

#line 986
            _S77 = false;

#line 986
        }

#line 986
        if(_S77)
        {
            uvec2 _S78 = (clockRealtime2x32EXT());

#line 988
            g_diagnostics_0._data[uint(blockIdx_0)].timestamps_0[candidate_id_1] = _S78;
            g_diagnostics_0._data[uint(blockIdx_0)].loss_log_0[candidate_id_1][2] = loss_3;

#line 986
        }

#line 972
        candidate_id_1 = candidate_id_1 + uint16_t(1US);

#line 972
    }

#line 995
    CompressedTextureBlock_set_astc_seed_0(block_7, best_seed_1);

    f16vec3 _S79 = CompressedTextureBlock_ep0_get_0(block_7);

#line 997
    f16vec3 _S80 = CompressedTextureBlock_ep1_get_0(block_7);

#line 997
    solve_pca_eps_0(block_7, _S79, _S80, uint8_t(0U));

#line 997
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_7.payload_0.index_0]._ep0_0 = u8vec3(round(saturate_1(_S79) * 255.0HF));

#line 997
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_7.payload_0.index_0]._ep1_0 = u8vec3(round(saturate_1(_S80) * 255.0HF));

    f16vec3 _S81 = CompressedTextureBlock_ep2_get_0(block_7);

#line 999
    f16vec3 _S82 = CompressedTextureBlock_ep3_get_0(block_7);

#line 999
    solve_pca_eps_0(block_7, _S81, _S82, uint8_t(1U));

#line 999
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_7.payload_0.index_0]._ep2_0 = u8vec3(round(saturate_1(_S81) * 255.0HF));

#line 999
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_7.payload_0.index_0]._ep3_0 = u8vec3(round(saturate_1(_S82) * 255.0HF));

    f16vec3 _S83 = CompressedTextureBlock_ep4_get_0(block_7);

#line 1001
    f16vec3 _S84 = CompressedTextureBlock_ep5_get_0(block_7);

#line 1001
    solve_pca_eps_0(block_7, _S83, _S84, uint8_t(2U));

#line 1001
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_7.payload_0.index_0]._ep4_0 = u8vec3(round(saturate_1(_S83) * 255.0HF));

#line 1001
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_7.payload_0.index_0]._ep5_0 = u8vec3(round(saturate_1(_S84) * 255.0HF));
    CompressedTextureBlock_solve_weights_0(block_7);

#line 1015
    return best_loss_1;
}


#line 217
f16vec3 quantize_0(f16vec3 value_0, uint range_0)
{
    f16vec3 scale_0 = f16vec3(float16_t(int(range_0)));
    return round(value_0 * scale_0) / scale_0;
}


#line 228
float16_t BF8Weights_operatorx5Bx5D_get_0(BF8Weights_0 this_21, int n_1)
{

    return float16_t(this_21.data_0[n_1]) / 63.0HF;
}


#line 211
float16_t quantize_1(float16_t value_1, uint range_1)
{

#line 211
    float16_t _S85 = float16_t(int(range_1));


    return round(value_1 * _S85) / _S85;
}


#line 666
float loss_mse_0(CompressedTextureBlock_0 block_8, u8vec2 quant_0)
{


    PartitionMap_0 _S86 = CompressedTextureBlock_partition_map_get_0(block_8);

#line 670
    uint8_t i_11 = uint8_t(0U);

#line 670
    float totalError_0 = 0.0;
    for(;;)
    {

#line 671
        if(i_11 < uint8_t(16U))
        {
        }
        else
        {

#line 671
            break;
        }
        int _S87 = int(i_11);

#line 673
        uint8_t _S88 = PartitionMap_operatorx5Bx5D_get_0(_S86, _S87);
        bool _S89 = _S88 == uint8_t(0U);

#line 674
        f16vec3 _S90;

#line 674
        if(_S89)
        {

#line 674
            _S90 = CompressedTextureBlock_ep0_get_0(block_8);

#line 674
        }
        else
        {

#line 674
            if(_S88 == uint8_t(1U))
            {

#line 674
                _S90 = CompressedTextureBlock_ep2_get_0(block_8);

#line 674
            }
            else
            {

#line 674
                _S90 = CompressedTextureBlock_ep4_get_0(block_8);

#line 674
            }

#line 674
        }

#line 674
        uint _S91 = uint(quant_0.y);

#line 674
        f16vec3 _S92 = quantize_0(_S90, _S91);

#line 674
        f16vec3 _S93;
        if(_S89)
        {

#line 675
            _S93 = CompressedTextureBlock_ep1_get_0(block_8);

#line 675
        }
        else
        {

#line 675
            if(_S88 == uint8_t(1U))
            {

#line 675
                _S93 = CompressedTextureBlock_ep3_get_0(block_8);

#line 675
            }
            else
            {

#line 675
                _S93 = CompressedTextureBlock_ep5_get_0(block_8);

#line 675
            }

#line 675
        }
        f16vec3 diff_0 = mix(_S92, quantize_0(_S93, _S91), f16vec3(quantize_1(BF8Weights_operatorx5Bx5D_get_0(CompressedTextureBlock_weights_get_0(block_8), _S87), uint(quant_0.x)))) - TextureBlock_operatorx5Bx5D_get_0(blockIdx_0, uint(i_11));
        float totalError_1 = totalError_0 + float(dot(diff_0, diff_0));

#line 671
        i_11 = i_11 + uint8_t(1U);

#line 671
        totalError_0 = totalError_1;

#line 671
    }

#line 679
    return totalError_0;
}


#line 1024
float find_best_quantization_0(inout CompressedTextureBlock_0 block_9)
{


    if(g_params_0.no_quantization_0)
    {
        const u8vec2 _S94 = u8vec2(uint8_t(255U), uint8_t(255U));

#line 1030
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_9.payload_0.index_0].qwc_0 = _S94;
        return loss_mse_0(block_9, _S94);
    }

#line 1031
    u8vec2 best_wc_0;

#line 1031
    float best_loss_2 = 1000.0;

#line 1031
    uint8_t i_12 = uint8_t(0U);

#line 1037
    for(;;)
    {

#line 1037
        if(int(i_12) < 5)
        {
        }
        else
        {

#line 1037
            break;
        }

#line 1037
        uint8_t _S95 = i_12;

#line 1043
        if((VALID_1P_QUANTIZATION_RANGES_0[i_12].x) == uint8_t(0U))
        {

#line 1044
            i_12 = i_12 + uint8_t(1U);

#line 1037
            continue;
        }

#line 1046
        float _S96 = loss_mse_0(block_9, VALID_1P_QUANTIZATION_RANGES_0[_S95]);

#line 1046
        bool _S97;
        if(_S96 < best_loss_2)
        {

#line 1047
            _S97 = true;

#line 1047
        }
        else
        {

#line 1047
            _S97 = i_12 == uint8_t(0U);

#line 1047
        }

#line 1047
        float best_loss_3;

#line 1047
        u8vec2 best_wc_1;

#line 1047
        if(_S97)
        {

#line 1047
            best_loss_3 = _S96;

#line 1047
            best_wc_1 = VALID_1P_QUANTIZATION_RANGES_0[_S95];

#line 1047
        }
        else
        {

#line 1047
            best_loss_3 = best_loss_2;

#line 1047
            best_wc_1 = best_wc_0;

#line 1047
        }

#line 1047
        best_loss_2 = best_loss_3;

#line 1047
        best_wc_0 = best_wc_1;

#line 1037
        i_12 = i_12 + uint8_t(1U);

#line 1037
    }

#line 1053
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_9.payload_0.index_0].qwc_0 = best_wc_0;
    return best_loss_2;
}


#line 1024
float find_best_quantization_1(inout CompressedTextureBlock_0 block_10)
{


    if(g_params_0.no_quantization_0)
    {
        const u8vec2 _S98 = u8vec2(uint8_t(255U), uint8_t(255U));

#line 1030
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_10.payload_0.index_0].qwc_0 = _S98;
        return loss_mse_0(block_10, _S98);
    }

#line 1031
    u8vec2 best_wc_2;

#line 1031
    float best_loss_4 = 1000.0;

#line 1031
    uint8_t i_13 = uint8_t(0U);

#line 1037
    for(;;)
    {

#line 1037
        if(int(i_13) < 9)
        {
        }
        else
        {

#line 1037
            break;
        }

#line 1037
        uint8_t _S99 = i_13;

#line 1043
        if((VALID_2P_QUANTIZATION_RANGES_0[i_13].x) == uint8_t(0U))
        {

#line 1044
            i_13 = i_13 + uint8_t(1U);

#line 1037
            continue;
        }

#line 1046
        float _S100 = loss_mse_0(block_10, VALID_2P_QUANTIZATION_RANGES_0[_S99]);

#line 1046
        bool _S101;
        if(_S100 < best_loss_4)
        {

#line 1047
            _S101 = true;

#line 1047
        }
        else
        {

#line 1047
            _S101 = i_13 == uint8_t(0U);

#line 1047
        }

#line 1047
        float best_loss_5;

#line 1047
        u8vec2 best_wc_3;

#line 1047
        if(_S101)
        {

#line 1047
            best_loss_5 = _S100;

#line 1047
            best_wc_3 = VALID_2P_QUANTIZATION_RANGES_0[_S99];

#line 1047
        }
        else
        {

#line 1047
            best_loss_5 = best_loss_4;

#line 1047
            best_wc_3 = best_wc_2;

#line 1047
        }

#line 1047
        best_loss_4 = best_loss_5;

#line 1047
        best_wc_2 = best_wc_3;

#line 1037
        i_13 = i_13 + uint8_t(1U);

#line 1037
    }

#line 1053
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_10.payload_0.index_0].qwc_0 = best_wc_2;
    return best_loss_4;
}


#line 1024
float find_best_quantization_2(inout CompressedTextureBlock_0 block_11)
{


    if(g_params_0.no_quantization_0)
    {
        const u8vec2 _S102 = u8vec2(uint8_t(255U), uint8_t(255U));

#line 1030
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_11.payload_0.index_0].qwc_0 = _S102;
        return loss_mse_0(block_11, _S102);
    }

#line 1031
    u8vec2 best_wc_4;

#line 1031
    float best_loss_6 = 1000.0;

#line 1031
    uint8_t i_14 = uint8_t(0U);

#line 1037
    for(;;)
    {

#line 1037
        if(int(i_14) < 6)
        {
        }
        else
        {

#line 1037
            break;
        }

#line 1037
        uint8_t _S103 = i_14;

#line 1043
        if((VALID_3P_QUANTIZATION_RANGES_0[i_14].x) == uint8_t(0U))
        {

#line 1044
            i_14 = i_14 + uint8_t(1U);

#line 1037
            continue;
        }

#line 1046
        float _S104 = loss_mse_0(block_11, VALID_3P_QUANTIZATION_RANGES_0[_S103]);

#line 1046
        bool _S105;
        if(_S104 < best_loss_6)
        {

#line 1047
            _S105 = true;

#line 1047
        }
        else
        {

#line 1047
            _S105 = i_14 == uint8_t(0U);

#line 1047
        }

#line 1047
        float best_loss_7;

#line 1047
        u8vec2 best_wc_5;

#line 1047
        if(_S105)
        {

#line 1047
            best_loss_7 = _S104;

#line 1047
            best_wc_5 = VALID_3P_QUANTIZATION_RANGES_0[_S103];

#line 1047
        }
        else
        {

#line 1047
            best_loss_7 = best_loss_6;

#line 1047
            best_wc_5 = best_wc_4;

#line 1047
        }

#line 1047
        best_loss_6 = best_loss_7;

#line 1047
        best_wc_4 = best_wc_5;

#line 1037
        i_14 = i_14 + uint8_t(1U);

#line 1037
    }

#line 1053
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_11.payload_0.index_0].qwc_0 = best_wc_4;
    return best_loss_6;
}


#line 355
u8vec2 CompressedTextureBlockProxyPayload_qwc_get_0(CompressedTextureBlockProxyPayload_0 this_22)
{

#line 356
    return g_scratch_0._data[uint(blockIdx_0)].blocks_0[this_22.index_0].qwc_0;
}


#line 238
void BF8Weights_quantize_0(inout BF8Weights_0 this_23, uint8_t range_2)
{

#line 238
    int i_15 = 0;

    for(;;)
    {

#line 240
        if(i_15 < 16)
        {
        }
        else
        {

#line 240
            break;
        }
        this_23.data_0[i_15] = uint8_t(round(saturate_0(quantize_1(BF8Weights_operatorx5Bx5D_get_0(this_23, i_15), uint(range_2))) * 63.0HF));

#line 240
        i_15 = i_15 + 1;

#line 240
    }



    return;
}


#line 464
void CompressedTextureBlock_decompress_0(CompressedTextureBlock_0 this_24)
{

#line 464
    uint8_t i_16 = uint8_t(0U);


    for(;;)
    {

#line 467
        if(i_16 < uint8_t(16U))
        {
        }
        else
        {

#line 467
            break;
        }
        int _S106 = int(i_16);

#line 469
        uint8_t _S107 = PartitionMap_operatorx5Bx5D_get_0(CompressedTextureBlock_partition_map_get_0(this_24), _S106);
        bool _S108 = _S107 == uint8_t(0U);

#line 470
        f16vec3 _S109;

#line 470
        if(_S108)
        {

#line 470
            _S109 = CompressedTextureBlock_ep0_get_0(this_24);

#line 470
        }
        else
        {

#line 470
            if(_S107 == uint8_t(1U))
            {

#line 470
                _S109 = CompressedTextureBlock_ep2_get_0(this_24);

#line 470
            }
            else
            {

#line 470
                _S109 = CompressedTextureBlock_ep4_get_0(this_24);

#line 470
            }

#line 470
        }

#line 470
        f16vec3 _S110;
        if(_S108)
        {

#line 471
            _S110 = CompressedTextureBlock_ep1_get_0(this_24);

#line 471
        }
        else
        {

#line 471
            if(_S107 == uint8_t(1U))
            {

#line 471
                _S110 = CompressedTextureBlock_ep3_get_0(this_24);

#line 471
            }
            else
            {

#line 471
                _S110 = CompressedTextureBlock_ep5_get_0(this_24);

#line 471
            }

#line 471
        }
        g_reconstructed_0._data[uint(blockIdx_0)].pixels_0[uint(i_16)] = u8vec3(round(mix(_S109, _S110, f16vec3(BF8Weights_operatorx5Bx5D_get_0(CompressedTextureBlock_weights_get_0(this_24), _S106))) * 255.0HF));

#line 467
        i_16 = i_16 + uint8_t(1U);

#line 467
    }

#line 474
    return;
}


#line 476
void CompressedTextureBlock_reconstruct_0(CompressedTextureBlock_0 this_25)
{

#line 573
    CompressedTextureBlock_decompress_0(this_25);
    return;
}


#line 1062
void CompressedTextureBlockPayload_set_0(uint _S111, CompressedTextureBlockProxyPayload_0 _S112)
{

#line 343
    g_compressedBlock3P_0._data[uint(_S111)] = g_scratch_0._data[uint(blockIdx_0)].blocks_0[_S112.index_0];
    return;
}


#line 1062
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{

#line 1064
    uint _S113 = gl_GlobalInvocationID.x;

#line 1064
    blockIdx_0 = _S113;
    if(_S113 >= (g_params_0.num_blocks_0))
    {

#line 1066
        return;
    }

#line 1067
    uvec2 _S114 = (clockRealtime2x32EXT());

#line 1067
    g_diagnostics_0._data[uint(blockIdx_0)].start_clock_0 = _S114;

#line 1077
    CompressedTextureBlockProxyPayload_0 _S115 = { int8_t(0) };

#line 1077
    CompressedTextureBlock_0 block_12;

#line 1077
    block_12.payload_0 = _S115;



    bool _S116 = g_params_0.exhaustive_0;

#line 1086
    uint _S117 = g_params_0.steps_0;

#line 1105
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_12.payload_0.index_0].max_partitions_1 = uint8_t(1U);
    float _S118 = optimize_0(block_12, g_params_0.steps_0, true, false);
    float quantized_loss_0 = find_best_quantization_0(block_12);

#line 1107
    float quantized_loss_1;

#line 1107
    float unquantized_loss_0;
    if((g_params_0.max_partitions_0) >= uint8_t(2U))
    {
        CompressedTextureBlockProxyPayload_0 _S119 = { int8_t(1) };

#line 1110
        CompressedTextureBlock_0 block1_0;

#line 1110
        block1_0.payload_0 = _S119;
        g_scratch_0._data[uint(blockIdx_0)].blocks_0[block1_0.payload_0.index_0].max_partitions_1 = uint8_t(2U);
        float unquantized_loss1_0 = optimize_1(block1_0, _S117, true, _S116);
        float quantized_loss1_0 = find_best_quantization_1(block1_0);
        if(quantized_loss1_0 < quantized_loss_0)
        {


            CompressedTextureBlock_0 tmp_0 = block_12;
            block_12 = block1_0;
            block1_0 = tmp_0;

#line 1120
            quantized_loss_1 = quantized_loss1_0;

#line 1120
            unquantized_loss_0 = unquantized_loss1_0;

#line 1114
        }
        else
        {

#line 1114
            quantized_loss_1 = quantized_loss_0;

#line 1114
            unquantized_loss_0 = _S118;

#line 1114
        }

#line 1122
        if((g_params_0.max_partitions_0) == uint8_t(3U))
        {
            g_scratch_0._data[uint(blockIdx_0)].blocks_0[block1_0.payload_0.index_0].max_partitions_1 = uint8_t(3U);
            float unquantized_loss1_1 = optimize_2(block1_0, _S117, true, _S116);
            float quantized_loss1_1 = find_best_quantization_2(block1_0);
            if(quantized_loss1_1 < quantized_loss_1)
            {


                CompressedTextureBlock_0 tmp_1 = block_12;
                block_12 = block1_0;
                block1_0 = tmp_1;

#line 1133
                unquantized_loss_0 = unquantized_loss1_1;

#line 1133
                quantized_loss_1 = quantized_loss1_1;

#line 1127
            }

#line 1122
        }

#line 1108
    }
    else
    {

#line 1108
        unquantized_loss_0 = _S118;

#line 1108
        quantized_loss_1 = quantized_loss_0;

#line 1108
    }

#line 1138
    uvec2 _S120 = (clockRealtime2x32EXT());

#line 1138
    g_diagnostics_0._data[uint(blockIdx_0)].optim_ended_clock_0 = _S120;

    u8vec2 _S121 = CompressedTextureBlockProxyPayload_qwc_get_0(block_12.payload_0);
    uint _S122 = uint(_S121.y);

#line 1141
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_12.payload_0.index_0]._ep0_0 = u8vec3(round(saturate_1(quantize_0(CompressedTextureBlock_ep0_get_0(block_12), _S122)) * 255.0HF));
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_12.payload_0.index_0]._ep1_0 = u8vec3(round(saturate_1(quantize_0(CompressedTextureBlock_ep1_get_0(block_12), _S122)) * 255.0HF));
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_12.payload_0.index_0]._ep2_0 = u8vec3(round(saturate_1(quantize_0(CompressedTextureBlock_ep2_get_0(block_12), _S122)) * 255.0HF));
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_12.payload_0.index_0]._ep3_0 = u8vec3(round(saturate_1(quantize_0(CompressedTextureBlock_ep3_get_0(block_12), _S122)) * 255.0HF));
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_12.payload_0.index_0]._ep4_0 = u8vec3(round(saturate_1(quantize_0(CompressedTextureBlock_ep4_get_0(block_12), _S122)) * 255.0HF));
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_12.payload_0.index_0]._ep5_0 = u8vec3(round(saturate_1(quantize_0(CompressedTextureBlock_ep5_get_0(block_12), _S122)) * 255.0HF));
    BF8Weights_0 _S123 = CompressedTextureBlock_weights_get_0(block_12);

#line 1147
    BF8Weights_quantize_0(_S123, _S121.x);

#line 1147
    g_scratch_0._data[uint(blockIdx_0)].blocks_0[block_12.payload_0.index_0].weights_0 = _S123;

    CompressedTextureBlock_reconstruct_0(block_12);

#line 1149
    CompressedTextureBlockPayload_set_0(blockIdx_0, block_12.payload_0);


    g_diagnostics_0._data[uint(blockIdx_0)].final_unquantized_loss_0 = unquantized_loss_0;
    g_final_loss_0._data[uint(blockIdx_0)] = quantized_loss_1;
    uvec2 _S124 = (clockRealtime2x32EXT());

#line 1154
    g_diagnostics_0._data[uint(blockIdx_0)].finished_clock_0 = _S124;
    return;
}

