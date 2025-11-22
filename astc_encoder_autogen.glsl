#version 450
#extension GL_EXT_shader_realtime_clock : require
layout(row_major) uniform;
layout(row_major) buffer;
struct CompressStepParams_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
};

layout(std430, binding = 6) buffer StructuredBuffer_CompressStepParams_t_0 {
    CompressStepParams_0 _data[];
} g_compress_step_params_0;
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

layout(std430, binding = 2) buffer StructuredBuffer_Diagnostics_t_0 {
    Diagnostics_0 _data[];
} g_diagnostics_0;
struct NonDifferentiableWeights_0
{
    float  weights_0[16];
};

struct CompressedTextureBlock_0
{
    vec3 ep0_0;
    vec3 ep1_0;
    NonDifferentiableWeights_0 weights_1;
};

layout(std430, binding = 3) buffer StructuredBuffer_CompressedTextureBlock_t_0 {
    CompressedTextureBlock_0 _data[];
} g_compressedBlock_0;
struct TextureBlock_0
{
    vec3  pixels_0[16];
};

layout(std430, binding = 0) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;
layout(std430, binding = 1) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;
layout(std430, binding = 5) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;
struct CompressedTextureBlock_Differential_0
{
    vec3 ep0_1;
    vec3 ep1_1;
};

CompressedTextureBlock_Differential_0 CompressedTextureBlock_x24_syn_dzero_0()
{
    CompressedTextureBlock_Differential_0 result_0;
    vec3 _S1 = vec3(0.0);
    result_0.ep0_1 = _S1;
    result_0.ep1_1 = _S1;
    return result_0;
}

float NonDifferentiableWeights_operatorx5Bx5D_get_0(NonDifferentiableWeights_0 this_0, int n_0)
{
    return this_0.weights_0[n_0];
}

struct DiffPair_float_0
{
    float primal_0;
    float differential_0;
};

void _d_lerp_0(inout DiffPair_float_0 dpx_0, inout DiffPair_float_0 dpy_0, inout DiffPair_float_0 dps_0, float dOut_0)
{
    float _S2 = (1.0 - dps_0.primal_0) * dOut_0;
    dpx_0.primal_0 = dpx_0.primal_0;
    dpx_0.differential_0 = _S2;
    DiffPair_float_0 _S3 = dpy_0;
    float _S4 = dps_0.primal_0 * dOut_0;
    dpy_0.primal_0 = dpy_0.primal_0;
    dpy_0.differential_0 = _S4;
    float _S5 = (_S3.primal_0 - dpx_0.primal_0) * dOut_0;
    dps_0.primal_0 = _S3.primal_0;
    dps_0.differential_0 = _S5;
    return;
}

struct DiffPair_vectorx3Cfloatx2C3x3E_0
{
    vec3 primal_0;
    vec3 differential_0;
};

void _d_lerp_vector_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpx_1, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpy_1, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpz_0, vec3 dOut_1)
{
    DiffPair_float_0 left_dp_0;
    left_dp_0.primal_0 = dpx_1.primal_0[0];
    left_dp_0.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_0;
    middle_dp_0.primal_0 = dpy_1.primal_0[0];
    middle_dp_0.differential_0 = 0.0;
    DiffPair_float_0 right_dp_0;
    right_dp_0.primal_0 = dpz_0.primal_0[0];
    right_dp_0.differential_0 = 0.0;
    _d_lerp_0(left_dp_0, middle_dp_0, right_dp_0, dOut_1[0]);
    vec3 left_d_result_0;
    left_d_result_0[0] = left_dp_0.differential_0;
    vec3 middle_d_result_0;
    middle_d_result_0[0] = middle_dp_0.differential_0;
    vec3 right_d_result_0;
    right_d_result_0[0] = right_dp_0.differential_0;
    DiffPair_float_0 left_dp_1;
    left_dp_1.primal_0 = dpx_1.primal_0[1];
    left_dp_1.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_1;
    middle_dp_1.primal_0 = dpy_1.primal_0[1];
    middle_dp_1.differential_0 = 0.0;
    DiffPair_float_0 right_dp_1;
    right_dp_1.primal_0 = dpz_0.primal_0[1];
    right_dp_1.differential_0 = 0.0;
    _d_lerp_0(left_dp_1, middle_dp_1, right_dp_1, dOut_1[1]);
    left_d_result_0[1] = left_dp_1.differential_0;
    middle_d_result_0[1] = middle_dp_1.differential_0;
    right_d_result_0[1] = right_dp_1.differential_0;
    DiffPair_float_0 left_dp_2;
    left_dp_2.primal_0 = dpx_1.primal_0[2];
    left_dp_2.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_2;
    middle_dp_2.primal_0 = dpy_1.primal_0[2];
    middle_dp_2.differential_0 = 0.0;
    DiffPair_float_0 right_dp_2;
    right_dp_2.primal_0 = dpz_0.primal_0[2];
    right_dp_2.differential_0 = 0.0;
    _d_lerp_0(left_dp_2, middle_dp_2, right_dp_2, dOut_1[2]);
    left_d_result_0[2] = left_dp_2.differential_0;
    middle_d_result_0[2] = middle_dp_2.differential_0;
    right_d_result_0[2] = right_dp_2.differential_0;
    dpx_1.primal_0 = dpx_1.primal_0;
    dpx_1.differential_0 = left_d_result_0;
    dpy_1.primal_0 = dpy_1.primal_0;
    dpy_1.differential_0 = middle_d_result_0;
    dpz_0.primal_0 = dpz_0.primal_0;
    dpz_0.differential_0 = right_d_result_0;
    return;
}

TextureBlock_0 decompress_0(CompressedTextureBlock_0 blockCoefficients_0)
{
    TextureBlock_0 outputBlock_0;
    int i_0 = 0;
    for(;;)
    {
        if(i_0 < 16)
        {
        }
        else
        {
            break;
        }
        outputBlock_0.pixels_0[i_0] = mix(blockCoefficients_0.ep0_0, blockCoefficients_0.ep1_0, vec3(NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_0.weights_1, i_0)));
        i_0 = i_0 + 1;
    }
    return outputBlock_0;
}

void _d_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpx_2, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpy_2, float dOut_2)
{
    vec3 x_d_result_0;
    x_d_result_0[0] = dpy_2.primal_0[0] * dOut_2;
    vec3 y_d_result_0;
    y_d_result_0[0] = dpx_2.primal_0[0] * dOut_2;
    x_d_result_0[1] = dpy_2.primal_0[1] * dOut_2;
    y_d_result_0[1] = dpx_2.primal_0[1] * dOut_2;
    x_d_result_0[2] = dpy_2.primal_0[2] * dOut_2;
    y_d_result_0[2] = dpx_2.primal_0[2] * dOut_2;
    dpx_2.primal_0 = dpx_2.primal_0;
    dpx_2.differential_0 = x_d_result_0;
    dpy_2.primal_0 = dpy_2.primal_0;
    dpy_2.differential_0 = y_d_result_0;
    return;
}

float saturate_0(float x_0)
{
    return clamp(x_0, 0.0, 1.0);
}

struct DiffPair_CompressedTextureBlock_0
{
    CompressedTextureBlock_0 primal_0;
    CompressedTextureBlock_Differential_0 differential_0;
};

vec3 s_primal_ctx_lerp_0(vec3 _S6, vec3 _S7, vec3 _S8)
{
    return mix(_S6, _S7, _S8);
}

TextureBlock_0 s_primal_ctx_decompress_0(CompressedTextureBlock_0 dpblockCoefficients_0)
{
    vec3 _S9 = vec3(0.0);
    vec3  _S10[16] = { _S9, _S9, _S9, _S9, _S9, _S9, _S9, _S9, _S9, _S9, _S9, _S9, _S9, _S9, _S9, _S9 };
    bool _runFlag_0 = true;
    int i_1 = 0;
    TextureBlock_0 outputBlock_1;
    outputBlock_1.pixels_0 = _S10;
    int _pc_0 = 0;
    for(;;)
    {
        if(_runFlag_0)
        {
        }
        else
        {
            break;
        }
        int _S11;
        if(i_1 < 16)
        {
            vec3 _S12 = s_primal_ctx_lerp_0(dpblockCoefficients_0.ep0_0, dpblockCoefficients_0.ep1_0, vec3(NonDifferentiableWeights_operatorx5Bx5D_get_0(dpblockCoefficients_0.weights_1, i_1)));
            TextureBlock_0 _S13 = outputBlock_1;
            _S13.pixels_0[i_1] = _S12;
            _S11 = 1;
            outputBlock_1 = _S13;
        }
        else
        {
            _S11 = 0;
        }
        if(_S11 != 1)
        {
            _runFlag_0 = false;
        }
        if(_runFlag_0)
        {
            i_1 = i_1 + 1;
        }
        _pc_0 = _pc_0 + 1;
    }
    return outputBlock_1;
}

TextureBlock_0 TextureBlock_x24_syn_dzero_0()
{
    TextureBlock_0 result_1;
    vec3 _S14 = vec3(0.0);
    result_1.pixels_0[0] = _S14;
    result_1.pixels_0[1] = _S14;
    result_1.pixels_0[2] = _S14;
    result_1.pixels_0[3] = _S14;
    result_1.pixels_0[4] = _S14;
    result_1.pixels_0[5] = _S14;
    result_1.pixels_0[6] = _S14;
    result_1.pixels_0[7] = _S14;
    result_1.pixels_0[8] = _S14;
    result_1.pixels_0[9] = _S14;
    result_1.pixels_0[10] = _S14;
    result_1.pixels_0[11] = _S14;
    result_1.pixels_0[12] = _S14;
    result_1.pixels_0[13] = _S14;
    result_1.pixels_0[14] = _S14;
    result_1.pixels_0[15] = _S14;
    return result_1;
}

TextureBlock_0 TextureBlock_x24_syn_dadd_0(TextureBlock_0 SLANG_anonymous_0_0, TextureBlock_0 SLANG_anonymous_1_0)
{
    TextureBlock_0 result_2;
    result_2.pixels_0[0] = SLANG_anonymous_0_0.pixels_0[0] + SLANG_anonymous_1_0.pixels_0[0];
    result_2.pixels_0[1] = SLANG_anonymous_0_0.pixels_0[1] + SLANG_anonymous_1_0.pixels_0[1];
    result_2.pixels_0[2] = SLANG_anonymous_0_0.pixels_0[2] + SLANG_anonymous_1_0.pixels_0[2];
    result_2.pixels_0[3] = SLANG_anonymous_0_0.pixels_0[3] + SLANG_anonymous_1_0.pixels_0[3];
    result_2.pixels_0[4] = SLANG_anonymous_0_0.pixels_0[4] + SLANG_anonymous_1_0.pixels_0[4];
    result_2.pixels_0[5] = SLANG_anonymous_0_0.pixels_0[5] + SLANG_anonymous_1_0.pixels_0[5];
    result_2.pixels_0[6] = SLANG_anonymous_0_0.pixels_0[6] + SLANG_anonymous_1_0.pixels_0[6];
    result_2.pixels_0[7] = SLANG_anonymous_0_0.pixels_0[7] + SLANG_anonymous_1_0.pixels_0[7];
    result_2.pixels_0[8] = SLANG_anonymous_0_0.pixels_0[8] + SLANG_anonymous_1_0.pixels_0[8];
    result_2.pixels_0[9] = SLANG_anonymous_0_0.pixels_0[9] + SLANG_anonymous_1_0.pixels_0[9];
    result_2.pixels_0[10] = SLANG_anonymous_0_0.pixels_0[10] + SLANG_anonymous_1_0.pixels_0[10];
    result_2.pixels_0[11] = SLANG_anonymous_0_0.pixels_0[11] + SLANG_anonymous_1_0.pixels_0[11];
    result_2.pixels_0[12] = SLANG_anonymous_0_0.pixels_0[12] + SLANG_anonymous_1_0.pixels_0[12];
    result_2.pixels_0[13] = SLANG_anonymous_0_0.pixels_0[13] + SLANG_anonymous_1_0.pixels_0[13];
    result_2.pixels_0[14] = SLANG_anonymous_0_0.pixels_0[14] + SLANG_anonymous_1_0.pixels_0[14];
    result_2.pixels_0[15] = SLANG_anonymous_0_0.pixels_0[15] + SLANG_anonymous_1_0.pixels_0[15];
    return result_2;
}

void s_bwd_prop_lerp_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S15, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S16, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S17, vec3 _S18)
{
    _d_lerp_vector_0(_S15, _S16, _S17, _S18);
    return;
}

void s_bwd_prop_decompress_0(inout DiffPair_CompressedTextureBlock_0 dpblockCoefficients_1, TextureBlock_0 _s_dOut_0)
{
    vec3 _S19 = dpblockCoefficients_1.primal_0.ep0_0;
    vec3 _S20 = dpblockCoefficients_1.primal_0.ep1_0;
    NonDifferentiableWeights_0 _S21 = dpblockCoefficients_1.primal_0.weights_1;
    vec3 _S22 = vec3(0.0);
    TextureBlock_0 _S23 = TextureBlock_x24_syn_dzero_0();
    TextureBlock_0 _S24 = TextureBlock_x24_syn_dadd_0(_s_dOut_0, _S23);
    int _dc_0 = 16;
    TextureBlock_0 _S25 = _S24;
    vec3 _S26 = _S22;
    vec3 _S27 = _S22;
    for(;;)
    {
        if(_dc_0 >= 0)
        {
        }
        else
        {
            break;
        }
        bool _S28 = _dc_0 < 16;
        vec3 _S29;
        if(_S28)
        {
            _S29 = vec3(NonDifferentiableWeights_operatorx5Bx5D_get_0(_S21, _dc_0));
        }
        else
        {
            _S29 = _S22;
        }
        TextureBlock_0 _S30 = TextureBlock_x24_syn_dadd_0(_S25, _S23);
        if(_S28)
        {
            TextureBlock_0 _S31 = _S30;
            _S31.pixels_0[_dc_0] = _S22;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S32;
            _S32.primal_0 = _S19;
            _S32.differential_0 = _S22;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S33;
            _S33.primal_0 = _S20;
            _S33.differential_0 = _S22;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S34;
            _S34.primal_0 = _S29;
            _S34.differential_0 = _S22;
            s_bwd_prop_lerp_0(_S32, _S33, _S34, _S30.pixels_0[_dc_0]);
            vec3 _S35 = _S33.differential_0 + _S26;
            vec3 _S36 = _S32.differential_0 + _S27;
            _S25 = TextureBlock_x24_syn_dadd_0(_S31, _S23);
            _S26 = _S35;
            _S27 = _S36;
        }
        else
        {
            _S25 = TextureBlock_x24_syn_dadd_0(_S30, _S23);
        }
        _dc_0 = _dc_0 - 1;
    }
    CompressedTextureBlock_Differential_0 _S37 = CompressedTextureBlock_x24_syn_dzero_0();
    _S37.ep1_1 = _S26;
    _S37.ep0_1 = _S27;
    dpblockCoefficients_1.primal_0 = dpblockCoefficients_1.primal_0;
    dpblockCoefficients_1.differential_0 = _S37;
    return;
}

void s_bwd_prop_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S38, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S39, float _S40)
{
    _d_dot_0(_S38, _S39, _S40);
    return;
}

void s_bwd_prop_loss_0(uint _S41, inout DiffPair_CompressedTextureBlock_0 _S42, float _S43)
{
    CompressedTextureBlock_0 _S44 = _S42.primal_0;
    TextureBlock_0 _S45 = s_primal_ctx_decompress_0(_S42.primal_0);
    vec3 _S46 = vec3(0.0);
    int _dc_1 = 16;
    float _S47 = _S43;
    vec3  _S48[16];
    _S48[0] = _S46;
    _S48[1] = _S46;
    _S48[2] = _S46;
    _S48[3] = _S46;
    _S48[4] = _S46;
    _S48[5] = _S46;
    _S48[6] = _S46;
    _S48[7] = _S46;
    _S48[8] = _S46;
    _S48[9] = _S46;
    _S48[10] = _S46;
    _S48[11] = _S46;
    _S48[12] = _S46;
    _S48[13] = _S46;
    _S48[14] = _S46;
    _S48[15] = _S46;
    for(;;)
    {
        if(_dc_1 >= 0)
        {
        }
        else
        {
            break;
        }
        bool _S49 = _dc_1 < 16;
        int _S50;
        vec3 _S51;
        if(_S49)
        {
            vec3 diff_0 = _S45.pixels_0[_dc_1] - g_groundtruth_0._data[uint(_S41)].pixels_0[_dc_1];
            _S50 = 1;
            _S51 = diff_0;
        }
        else
        {
            _S50 = 0;
            _S51 = _S46;
        }
        float _S52;
        float _S53;
        if(!(_S50 != 1))
        {
            _S52 = _S47;
            _S53 = 0.0;
        }
        else
        {
            _S52 = 0.0;
            _S53 = _S47;
        }
        if(_S49)
        {
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S54;
            _S54.primal_0 = _S51;
            _S54.differential_0 = _S46;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S55;
            _S55.primal_0 = _S51;
            _S55.differential_0 = _S46;
            s_bwd_prop_dot_0(_S54, _S55, _S52);
            vec3 _S56 = _S55.differential_0 + _S54.differential_0;
            float _S57 = _S52 + _S53;
            vec3  _S58[16];
            _S58[0] = _S46;
            _S58[1] = _S46;
            _S58[2] = _S46;
            _S58[3] = _S46;
            _S58[4] = _S46;
            _S58[5] = _S46;
            _S58[6] = _S46;
            _S58[7] = _S46;
            _S58[8] = _S46;
            _S58[9] = _S46;
            _S58[10] = _S46;
            _S58[11] = _S46;
            _S58[12] = _S46;
            _S58[13] = _S46;
            _S58[14] = _S46;
            _S58[15] = _S46;
            _S58[_dc_1] = _S56;
            vec3 _S59 = _S48[0] + _S58[0];
            vec3 _S60 = _S48[1] + _S58[1];
            vec3 _S61 = _S48[2] + _S58[2];
            vec3 _S62 = _S48[3] + _S58[3];
            vec3 _S63 = _S48[4] + _S58[4];
            vec3 _S64 = _S48[5] + _S58[5];
            vec3 _S65 = _S48[6] + _S58[6];
            vec3 _S66 = _S48[7] + _S58[7];
            vec3 _S67 = _S48[8] + _S58[8];
            vec3 _S68 = _S48[9] + _S58[9];
            vec3 _S69 = _S48[10] + _S58[10];
            vec3 _S70 = _S48[11] + _S58[11];
            vec3 _S71 = _S48[12] + _S58[12];
            vec3 _S72 = _S48[13] + _S58[13];
            vec3 _S73 = _S48[14] + _S58[14];
            vec3 _S74 = _S48[15] + _S58[15];
            _S47 = _S57;
            _S48[0] = _S59;
            _S48[1] = _S60;
            _S48[2] = _S61;
            _S48[3] = _S62;
            _S48[4] = _S63;
            _S48[5] = _S64;
            _S48[6] = _S65;
            _S48[7] = _S66;
            _S48[8] = _S67;
            _S48[9] = _S68;
            _S48[10] = _S69;
            _S48[11] = _S70;
            _S48[12] = _S71;
            _S48[13] = _S72;
            _S48[14] = _S73;
            _S48[15] = _S74;
        }
        else
        {
            _S47 = _S53;
        }
        _dc_1 = _dc_1 - 1;
    }
    TextureBlock_0 _S75 = TextureBlock_x24_syn_dzero_0();
    _S75.pixels_0 = _S48;
    CompressedTextureBlock_Differential_0 _S76 = CompressedTextureBlock_x24_syn_dzero_0();
    DiffPair_CompressedTextureBlock_0 _S77;
    _S77.primal_0 = _S44;
    _S77.differential_0 = _S76;
    s_bwd_prop_decompress_0(_S77, _S75);
    _S42.primal_0 = _S42.primal_0;
    _S42.differential_0 = _S77.differential_0;
    return;
}

void s_bwd_loss_0(uint _S78, inout DiffPair_CompressedTextureBlock_0 _S79, float _S80)
{
    s_bwd_prop_loss_0(_S78, _S79, _S80);
    return;
}

void optim_weights_0(inout CompressedTextureBlock_0 _S81, uint _S82)
{
    vec3 _S83 = _S81.ep1_0 - _S81.ep0_0;
    int i_2 = 0;
    for(;;)
    {
        if(i_2 < 16)
        {
        }
        else
        {
            break;
        }
        _S81.weights_1.weights_0[i_2] = saturate_0(dot(g_groundtruth_0._data[uint(_S82)].pixels_0[i_2] - _S81.ep0_0, _S83) / (dot(_S83, _S83) + 9.99999997475242708e-07));
        i_2 = i_2 + 1;
    }
    return;
}

float loss_0(uint _S84, CompressedTextureBlock_0 _S85)
{
    TextureBlock_0 _S86 = decompress_0(_S85);
    int i_3 = 0;
    float totalError_0 = 0.0;
    for(;;)
    {
        if(i_3 < 16)
        {
        }
        else
        {
            break;
        }
        vec3 diff_1 = _S86.pixels_0[i_3] - g_groundtruth_0._data[uint(_S84)].pixels_0[i_3];
        float totalError_1 = totalError_0 + dot(diff_1, diff_1);
        i_3 = i_3 + 1;
        totalError_0 = totalError_1;
    }
    return totalError_0;
}

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {
        return;
    }
    uvec2 _S87 = (clockRealtime2x32EXT());
    g_diagnostics_0._data[uint(blockIdx_0)].start_clock_0 = _S87;
    CompressedTextureBlock_0 value_0 = g_compressedBlock_0._data[uint(blockIdx_0)];
    float _S88 = g_compress_step_params_0._data[uint(0)].learning_rate_0;
    uint steps_1 = g_compress_step_params_0._data[uint(0)].steps_0;
    uint _S89 = g_compress_step_params_0._data[uint(0)].steps_0 / 20U;
    int step_0 = 0;
    for(;;)
    {
        if(step_0 < int(steps_1))
        {
        }
        else
        {
            break;
        }
        CompressedTextureBlock_Differential_0 _S90 = CompressedTextureBlock_x24_syn_dzero_0();
        DiffPair_CompressedTextureBlock_0 cb_pair_0;
        cb_pair_0.primal_0 = value_0;
        cb_pair_0.differential_0 = _S90;
        s_bwd_loss_0(blockIdx_0, cb_pair_0, 1.0);
        const vec3 _S91 = vec3(0.0);
        const vec3 _S92 = vec3(1.0);
        value_0.ep0_0 = clamp(value_0.ep0_0 - cb_pair_0.differential_0.ep0_1 * _S88, _S91, _S92);
        value_0.ep1_0 = clamp(value_0.ep1_0 - cb_pair_0.differential_0.ep1_1 * _S88, _S91, _S92);
        optim_weights_0(value_0, blockIdx_0);
        uint _S93 = uint(step_0);
        uint _S94 = _S93 % _S89;
        if(_S94 == 0U)
        {
            uint iter_0 = _S93 / _S89;
            uvec2 _S95 = (clockRealtime2x32EXT());
            g_diagnostics_0._data[uint(blockIdx_0)].timestamps_0[iter_0] = _S95;
            g_diagnostics_0._data[uint(blockIdx_0)].loss_log_0[iter_0] = loss_0(blockIdx_0, value_0);
        }
        step_0 = step_0 + 1;
    }
    uvec2 _S96 = (clockRealtime2x32EXT());
    g_diagnostics_0._data[uint(blockIdx_0)].optim_ended_clock_0 = _S96;
    g_compressedBlock_0._data[uint(blockIdx_0)] = value_0;
    g_reconstructed_0._data[uint(blockIdx_0)] = decompress_0(value_0);
    g_final_loss_0._data[uint(blockIdx_0)] = loss_0(blockIdx_0, value_0);
    uvec2 _S97 = (clockRealtime2x32EXT());
    g_diagnostics_0._data[uint(blockIdx_0)].finished_clock_0 = _S97;
    return;
}

#version 450
#extension GL_EXT_shader_realtime_clock : require
#extension GL_EXT_control_flow_attributes : require
layout(row_major) uniform;
layout(row_major) buffer;
struct CompressStepParams_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
};

layout(std430, binding = 6) buffer StructuredBuffer_CompressStepParams_t_0 {
    CompressStepParams_0 _data[];
} g_compress_step_params_0;
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

layout(std430, binding = 2) buffer StructuredBuffer_Diagnostics_t_0 {
    Diagnostics_0 _data[];
} g_diagnostics_0;
struct NonDifferentiableWeights_0
{
    float  weights_0[16];
};

struct CompressedTextureBlock2P_0
{
    vec3 ep0_0;
    vec3 ep1_0;
    vec3 ep2_0;
    vec3 ep3_0;
    NonDifferentiableWeights_0 weights_1;
    float  partition_logits_0[16];
    uint astc_partition_map_0;
    uint ideal_partition_map_0;
    uint astc_seed_0;
};

layout(std430, binding = 4) buffer StructuredBuffer_CompressedTextureBlock2P_t_0 {
    CompressedTextureBlock2P_0 _data[];
} g_compressedBlock2P_0;
struct TextureBlock_0
{
    vec3  pixels_0[16];
};

layout(std430, binding = 0) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;
layout(std430, binding = 7) readonly buffer StructuredBuffer_uint_t_0 {
    uint _data[];
} g_lut_ideal_to_seed_0;
layout(std430, binding = 8) readonly buffer StructuredBuffer_uint_t_1 {
    uint _data[];
} g_lut_seed_to_mask_0;
layout(std430, binding = 1) buffer StructuredBuffer_TextureBlock_t_1 {
    TextureBlock_0 _data[];
} g_reconstructed_0;
layout(std430, binding = 5) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;
struct CompressedTextureBlock2P_Differential_0
{
    float  partition_logits_1[16];
};

CompressedTextureBlock2P_Differential_0 CompressedTextureBlock2P_x24_syn_dzero_0()
{
    CompressedTextureBlock2P_Differential_0 result_0;
    result_0.partition_logits_1[0] = 0.0;
    result_0.partition_logits_1[1] = 0.0;
    result_0.partition_logits_1[2] = 0.0;
    result_0.partition_logits_1[3] = 0.0;
    result_0.partition_logits_1[4] = 0.0;
    result_0.partition_logits_1[5] = 0.0;
    result_0.partition_logits_1[6] = 0.0;
    result_0.partition_logits_1[7] = 0.0;
    result_0.partition_logits_1[8] = 0.0;
    result_0.partition_logits_1[9] = 0.0;
    result_0.partition_logits_1[10] = 0.0;
    result_0.partition_logits_1[11] = 0.0;
    result_0.partition_logits_1[12] = 0.0;
    result_0.partition_logits_1[13] = 0.0;
    result_0.partition_logits_1[14] = 0.0;
    result_0.partition_logits_1[15] = 0.0;
    return result_0;
}

float NonDifferentiableWeights_operatorx5Bx5D_get_0(NonDifferentiableWeights_0 this_0, int n_0)
{
    return this_0.weights_0[n_0];
}

float saturate_0(float x_0)
{
    return clamp(x_0, 0.0, 1.0);
}

struct DiffPair_float_0
{
    float primal_0;
    float differential_0;
};

void _d_exp_0(inout DiffPair_float_0 dpx_0, float dOut_0)
{
    float _S1 = exp(dpx_0.primal_0) * dOut_0;
    dpx_0.primal_0 = dpx_0.primal_0;
    dpx_0.differential_0 = _S1;
    return;
}

float sigmoid_0(float x_1)
{
    return 1.0 / (1.0 + exp(- x_1));
}

void round_bwd_0(inout DiffPair_float_0 x_2, float d_out_0)
{
    x_2.primal_0 = x_2.primal_0;
    x_2.differential_0 = d_out_0;
    return;
}

float round_ste_0(float x_3)
{
    return round(x_3);
}

void _d_lerp_0(inout DiffPair_float_0 dpx_1, inout DiffPair_float_0 dpy_0, inout DiffPair_float_0 dps_0, float dOut_1)
{
    float _S2 = (1.0 - dps_0.primal_0) * dOut_1;
    dpx_1.primal_0 = dpx_1.primal_0;
    dpx_1.differential_0 = _S2;
    DiffPair_float_0 _S3 = dpy_0;
    float _S4 = dps_0.primal_0 * dOut_1;
    dpy_0.primal_0 = dpy_0.primal_0;
    dpy_0.differential_0 = _S4;
    float _S5 = (_S3.primal_0 - dpx_1.primal_0) * dOut_1;
    dps_0.primal_0 = _S3.primal_0;
    dps_0.differential_0 = _S5;
    return;
}

struct DiffPair_vectorx3Cfloatx2C3x3E_0
{
    vec3 primal_0;
    vec3 differential_0;
};

void _d_lerp_vector_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpx_2, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpy_1, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpz_0, vec3 dOut_2)
{
    DiffPair_float_0 left_dp_0;
    left_dp_0.primal_0 = dpx_2.primal_0[0];
    left_dp_0.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_0;
    middle_dp_0.primal_0 = dpy_1.primal_0[0];
    middle_dp_0.differential_0 = 0.0;
    DiffPair_float_0 right_dp_0;
    right_dp_0.primal_0 = dpz_0.primal_0[0];
    right_dp_0.differential_0 = 0.0;
    _d_lerp_0(left_dp_0, middle_dp_0, right_dp_0, dOut_2[0]);
    vec3 left_d_result_0;
    left_d_result_0[0] = left_dp_0.differential_0;
    vec3 middle_d_result_0;
    middle_d_result_0[0] = middle_dp_0.differential_0;
    vec3 right_d_result_0;
    right_d_result_0[0] = right_dp_0.differential_0;
    DiffPair_float_0 left_dp_1;
    left_dp_1.primal_0 = dpx_2.primal_0[1];
    left_dp_1.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_1;
    middle_dp_1.primal_0 = dpy_1.primal_0[1];
    middle_dp_1.differential_0 = 0.0;
    DiffPair_float_0 right_dp_1;
    right_dp_1.primal_0 = dpz_0.primal_0[1];
    right_dp_1.differential_0 = 0.0;
    _d_lerp_0(left_dp_1, middle_dp_1, right_dp_1, dOut_2[1]);
    left_d_result_0[1] = left_dp_1.differential_0;
    middle_d_result_0[1] = middle_dp_1.differential_0;
    right_d_result_0[1] = right_dp_1.differential_0;
    DiffPair_float_0 left_dp_2;
    left_dp_2.primal_0 = dpx_2.primal_0[2];
    left_dp_2.differential_0 = 0.0;
    DiffPair_float_0 middle_dp_2;
    middle_dp_2.primal_0 = dpy_1.primal_0[2];
    middle_dp_2.differential_0 = 0.0;
    DiffPair_float_0 right_dp_2;
    right_dp_2.primal_0 = dpz_0.primal_0[2];
    right_dp_2.differential_0 = 0.0;
    _d_lerp_0(left_dp_2, middle_dp_2, right_dp_2, dOut_2[2]);
    left_d_result_0[2] = left_dp_2.differential_0;
    middle_d_result_0[2] = middle_dp_2.differential_0;
    right_d_result_0[2] = right_dp_2.differential_0;
    dpx_2.primal_0 = dpx_2.primal_0;
    dpx_2.differential_0 = left_d_result_0;
    dpy_1.primal_0 = dpy_1.primal_0;
    dpy_1.differential_0 = middle_d_result_0;
    dpz_0.primal_0 = dpz_0.primal_0;
    dpz_0.differential_0 = right_d_result_0;
    return;
}

TextureBlock_0 decompress2P_0(CompressedTextureBlock2P_0 blockCoefficients_0)
{
    TextureBlock_0 outputBlock_0;
    int i_0 = 0;
    for(;;)
    {
        if(i_0 < 16)
        {
        }
        else
        {
            break;
        }
        vec3 _S6 = vec3(saturate_0(NonDifferentiableWeights_operatorx5Bx5D_get_0(blockCoefficients_0.weights_1, i_0)));
        outputBlock_0.pixels_0[i_0] = mix(mix(blockCoefficients_0.ep0_0, blockCoefficients_0.ep1_0, _S6), mix(blockCoefficients_0.ep2_0, blockCoefficients_0.ep3_0, _S6), vec3(round_ste_0(sigmoid_0(blockCoefficients_0.partition_logits_0[i_0]))));
        i_0 = i_0 + 1;
    }
    return outputBlock_0;
}

void _d_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpx_3, inout DiffPair_vectorx3Cfloatx2C3x3E_0 dpy_2, float dOut_3)
{
    vec3 x_d_result_0;
    x_d_result_0[0] = dpy_2.primal_0[0] * dOut_3;
    vec3 y_d_result_0;
    y_d_result_0[0] = dpx_3.primal_0[0] * dOut_3;
    x_d_result_0[1] = dpy_2.primal_0[1] * dOut_3;
    y_d_result_0[1] = dpx_3.primal_0[1] * dOut_3;
    x_d_result_0[2] = dpy_2.primal_0[2] * dOut_3;
    y_d_result_0[2] = dpx_3.primal_0[2] * dOut_3;
    dpx_3.primal_0 = dpx_3.primal_0;
    dpx_3.differential_0 = x_d_result_0;
    dpy_2.primal_0 = dpy_2.primal_0;
    dpy_2.differential_0 = y_d_result_0;
    return;
}

uint pack_logits_to_mask_0(float  p_logits_0[16])
{
    int i_1 = 0;
    uint raw_map_0 = 0U;
    for(;;)
    {
        if(i_1 < 16)
        {
        }
        else
        {
            break;
        }
        if((p_logits_0[i_1]) > 0.0)
        {
            raw_map_0 = raw_map_0 | uint(1 << i_1);
        }
        i_1 = i_1 + 1;
    }
    return raw_map_0;
}

void snap_0(inout CompressedTextureBlock2P_0 block_0, float snap_strength_0)
{
    uint raw_map_1 = pack_logits_to_mask_0(block_0.partition_logits_0);
    uint closest_seed_0 = g_lut_ideal_to_seed_0._data[uint(raw_map_1)];
    uint final_mask_0 = g_lut_seed_to_mask_0._data[uint(closest_seed_0)];
    block_0.astc_seed_0 = closest_seed_0;
    block_0.astc_partition_map_0 = final_mask_0;
    block_0.ideal_partition_map_0 = raw_map_1;
    int i_2 = 0;
    for(;;)
    {
        if(i_2 < 16)
        {
        }
        else
        {
            break;
        }
        float logit_0 = abs(block_0.partition_logits_0[i_2]);
        float logit_1;
        if(((final_mask_0 >> i_2) & 1U) == 0U)
        {
            logit_1 = - logit_0;
        }
        else
        {
            logit_1 = logit_0;
        }
        block_0.partition_logits_0[i_2] = logit_1;
        i_2 = i_2 + 1;
    }
    return;
}

vec3 get_principal_axis_0(mat3x3 covariance_0)
{
    vec3 dir_0 = vec3(1.0, 1.0, 1.0);
    int i_3 = 0;
    [[unroll]]
    for(;;)
    {
        if(i_3 < 2)
        {
        }
        else
        {
            break;
        }
        vec3 next_dir_0 = (((dir_0) * (covariance_0)));
        if((dot(next_dir_0, next_dir_0)) < 1.00000001335143196e-10)
        {
            return normalize(dir_0);
        }
        vec3 _S7 = normalize(next_dir_0);
        int _S8 = i_3 + 1;
        dir_0 = _S7;
        i_3 = _S8;
    }
    return dir_0;
}

int hamming_distance_0(uint n1_0, uint n2_0)
{
    int x_4 = int(n1_0 ^ n2_0);
    int output_0 = 0;
    for(;;)
    {
        if(x_4 > 0)
        {
        }
        else
        {
            break;
        }
        int output_1 = output_0 + (x_4 & 1);
        x_4 = x_4 >> 1;
        output_0 = output_1;
    }
    return output_0;
}

struct DiffPair_CompressedTextureBlock2P_0
{
    CompressedTextureBlock2P_0 primal_0;
    CompressedTextureBlock2P_Differential_0 differential_0;
};

float s_primal_ctx_saturate_0(float _S9)
{
    return saturate_0(_S9);
}

float s_primal_ctx_exp_0(float _S10)
{
    return exp(_S10);
}

float s_primal_ctx_sigmoid_0(float dpx_4)
{
    return 1.0 / (1.0 + s_primal_ctx_exp_0(- dpx_4));
}

float s_primal_ctx_round_ste_0(float _S11)
{
    return round_ste_0(_S11);
}

vec3 s_primal_ctx_lerp_0(vec3 _S12, vec3 _S13, vec3 _S14)
{
    return mix(_S12, _S13, _S14);
}

TextureBlock_0 s_primal_ctx_decompress2P_0(CompressedTextureBlock2P_0 dpblockCoefficients_0)
{
    vec3 _S15 = vec3(0.0);
    vec3  _S16[16] = { _S15, _S15, _S15, _S15, _S15, _S15, _S15, _S15, _S15, _S15, _S15, _S15, _S15, _S15, _S15, _S15 };
    bool _runFlag_0 = true;
    int i_4 = 0;
    TextureBlock_0 outputBlock_1;
    outputBlock_1.pixels_0 = _S16;
    int _pc_0 = 0;
    for(;;)
    {
        if(_runFlag_0)
        {
        }
        else
        {
            break;
        }
        int _S17;
        if(i_4 < 16)
        {
            vec3 _S18 = vec3(s_primal_ctx_saturate_0(NonDifferentiableWeights_operatorx5Bx5D_get_0(dpblockCoefficients_0.weights_1, i_4)));
            vec3 _S19 = s_primal_ctx_lerp_0(s_primal_ctx_lerp_0(dpblockCoefficients_0.ep0_0, dpblockCoefficients_0.ep1_0, _S18), s_primal_ctx_lerp_0(dpblockCoefficients_0.ep2_0, dpblockCoefficients_0.ep3_0, _S18), vec3(s_primal_ctx_round_ste_0(s_primal_ctx_sigmoid_0(dpblockCoefficients_0.partition_logits_0[i_4]))));
            TextureBlock_0 _S20 = outputBlock_1;
            _S20.pixels_0[i_4] = _S19;
            _S17 = 1;
            outputBlock_1 = _S20;
        }
        else
        {
            _S17 = 0;
        }
        if(_S17 != 1)
        {
            _runFlag_0 = false;
        }
        if(_runFlag_0)
        {
            i_4 = i_4 + 1;
        }
        _pc_0 = _pc_0 + 1;
    }
    return outputBlock_1;
}

TextureBlock_0 TextureBlock_x24_syn_dzero_0()
{
    TextureBlock_0 result_1;
    vec3 _S21 = vec3(0.0);
    result_1.pixels_0[0] = _S21;
    result_1.pixels_0[1] = _S21;
    result_1.pixels_0[2] = _S21;
    result_1.pixels_0[3] = _S21;
    result_1.pixels_0[4] = _S21;
    result_1.pixels_0[5] = _S21;
    result_1.pixels_0[6] = _S21;
    result_1.pixels_0[7] = _S21;
    result_1.pixels_0[8] = _S21;
    result_1.pixels_0[9] = _S21;
    result_1.pixels_0[10] = _S21;
    result_1.pixels_0[11] = _S21;
    result_1.pixels_0[12] = _S21;
    result_1.pixels_0[13] = _S21;
    result_1.pixels_0[14] = _S21;
    result_1.pixels_0[15] = _S21;
    return result_1;
}

TextureBlock_0 TextureBlock_x24_syn_dadd_0(TextureBlock_0 SLANG_anonymous_0_0, TextureBlock_0 SLANG_anonymous_1_0)
{
    TextureBlock_0 result_2;
    result_2.pixels_0[0] = SLANG_anonymous_0_0.pixels_0[0] + SLANG_anonymous_1_0.pixels_0[0];
    result_2.pixels_0[1] = SLANG_anonymous_0_0.pixels_0[1] + SLANG_anonymous_1_0.pixels_0[1];
    result_2.pixels_0[2] = SLANG_anonymous_0_0.pixels_0[2] + SLANG_anonymous_1_0.pixels_0[2];
    result_2.pixels_0[3] = SLANG_anonymous_0_0.pixels_0[3] + SLANG_anonymous_1_0.pixels_0[3];
    result_2.pixels_0[4] = SLANG_anonymous_0_0.pixels_0[4] + SLANG_anonymous_1_0.pixels_0[4];
    result_2.pixels_0[5] = SLANG_anonymous_0_0.pixels_0[5] + SLANG_anonymous_1_0.pixels_0[5];
    result_2.pixels_0[6] = SLANG_anonymous_0_0.pixels_0[6] + SLANG_anonymous_1_0.pixels_0[6];
    result_2.pixels_0[7] = SLANG_anonymous_0_0.pixels_0[7] + SLANG_anonymous_1_0.pixels_0[7];
    result_2.pixels_0[8] = SLANG_anonymous_0_0.pixels_0[8] + SLANG_anonymous_1_0.pixels_0[8];
    result_2.pixels_0[9] = SLANG_anonymous_0_0.pixels_0[9] + SLANG_anonymous_1_0.pixels_0[9];
    result_2.pixels_0[10] = SLANG_anonymous_0_0.pixels_0[10] + SLANG_anonymous_1_0.pixels_0[10];
    result_2.pixels_0[11] = SLANG_anonymous_0_0.pixels_0[11] + SLANG_anonymous_1_0.pixels_0[11];
    result_2.pixels_0[12] = SLANG_anonymous_0_0.pixels_0[12] + SLANG_anonymous_1_0.pixels_0[12];
    result_2.pixels_0[13] = SLANG_anonymous_0_0.pixels_0[13] + SLANG_anonymous_1_0.pixels_0[13];
    result_2.pixels_0[14] = SLANG_anonymous_0_0.pixels_0[14] + SLANG_anonymous_1_0.pixels_0[14];
    result_2.pixels_0[15] = SLANG_anonymous_0_0.pixels_0[15] + SLANG_anonymous_1_0.pixels_0[15];
    return result_2;
}

void s_bwd_prop_lerp_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S22, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S23, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S24, vec3 _S25)
{
    _d_lerp_vector_0(_S22, _S23, _S24, _S25);
    return;
}

void s_bwd_prop_round_ste_0(inout DiffPair_float_0 _S26, float _S27)
{
    round_bwd_0(_S26, _S27);
    return;
}

void s_bwd_prop_exp_0(inout DiffPair_float_0 _S28, float _S29)
{
    _d_exp_0(_S28, _S29);
    return;
}

void s_bwd_prop_sigmoid_0(inout DiffPair_float_0 dpx_5, float _s_dOut_0)
{
    float _S30 = - dpx_5.primal_0;
    float _S31 = 1.0 + s_primal_ctx_exp_0(_S30);
    float _S32 = - (_s_dOut_0 / (_S31 * _S31));
    DiffPair_float_0 _S33;
    _S33.primal_0 = _S30;
    _S33.differential_0 = 0.0;
    s_bwd_prop_exp_0(_S33, _S32);
    float _S34 = - _S33.differential_0;
    dpx_5.primal_0 = dpx_5.primal_0;
    dpx_5.differential_0 = _S34;
    return;
}

void s_bwd_prop_decompress2P_0(inout DiffPair_CompressedTextureBlock2P_0 dpblockCoefficients_1, TextureBlock_0 _s_dOut_1)
{
    vec3 _S35 = dpblockCoefficients_1.primal_0.ep0_0;
    vec3 _S36 = dpblockCoefficients_1.primal_0.ep1_0;
    vec3 _S37 = dpblockCoefficients_1.primal_0.ep2_0;
    vec3 _S38 = dpblockCoefficients_1.primal_0.ep3_0;
    NonDifferentiableWeights_0 _S39 = dpblockCoefficients_1.primal_0.weights_1;
    float  _S40[16] = dpblockCoefficients_1.primal_0.partition_logits_0;
    TextureBlock_0 _S41 = TextureBlock_x24_syn_dzero_0();
    TextureBlock_0 _S42 = TextureBlock_x24_syn_dadd_0(_s_dOut_1, _S41);
    int _dc_0 = 16;
    TextureBlock_0 _S43 = _S42;
    float  _S44[16];
    _S44[0] = 0.0;
    _S44[1] = 0.0;
    _S44[2] = 0.0;
    _S44[3] = 0.0;
    _S44[4] = 0.0;
    _S44[5] = 0.0;
    _S44[6] = 0.0;
    _S44[7] = 0.0;
    _S44[8] = 0.0;
    _S44[9] = 0.0;
    _S44[10] = 0.0;
    _S44[11] = 0.0;
    _S44[12] = 0.0;
    _S44[13] = 0.0;
    _S44[14] = 0.0;
    _S44[15] = 0.0;
    for(;;)
    {
        vec3 _S45 = vec3(0.0);
        if(_dc_0 >= 0)
        {
        }
        else
        {
            break;
        }
        bool _S46 = _dc_0 < 16;
        vec3 _S47;
        vec3 _S48;
        vec3 _S49;
        float _S50;
        float _S51;
        if(_S46)
        {
            float _S52 = s_primal_ctx_sigmoid_0(_S40[_dc_0]);
            vec3 _S53 = vec3(s_primal_ctx_saturate_0(NonDifferentiableWeights_operatorx5Bx5D_get_0(_S39, _dc_0)));
            vec3 _S54 = s_primal_ctx_lerp_0(_S37, _S38, _S53);
            vec3 _S55 = vec3(s_primal_ctx_round_ste_0(_S52));
            _S47 = s_primal_ctx_lerp_0(_S35, _S36, _S53);
            _S48 = _S54;
            _S49 = _S55;
            _S50 = _S52;
            _S51 = _S40[_dc_0];
        }
        else
        {
            _S47 = _S45;
            _S48 = _S45;
            _S49 = _S45;
            _S50 = 0.0;
            _S51 = 0.0;
        }
        TextureBlock_0 _S56 = TextureBlock_x24_syn_dadd_0(_S43, _S41);
        if(_S46)
        {
            TextureBlock_0 _S57 = _S56;
            _S57.pixels_0[_dc_0] = _S45;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S58;
            _S58.primal_0 = _S47;
            _S58.differential_0 = _S45;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S59;
            _S59.primal_0 = _S48;
            _S59.differential_0 = _S45;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S60;
            _S60.primal_0 = _S49;
            _S60.differential_0 = _S45;
            s_bwd_prop_lerp_0(_S58, _S59, _S60, _S56.pixels_0[_dc_0]);
            float _S61 = _S60.differential_0[0] + _S60.differential_0[1] + _S60.differential_0[2];
            DiffPair_float_0 _S62;
            _S62.primal_0 = _S50;
            _S62.differential_0 = 0.0;
            s_bwd_prop_round_ste_0(_S62, _S61);
            DiffPair_float_0 _S63;
            _S63.primal_0 = _S51;
            _S63.differential_0 = 0.0;
            s_bwd_prop_sigmoid_0(_S63, _S62.differential_0);
            TextureBlock_0 _S64 = TextureBlock_x24_syn_dadd_0(_S57, _S41);
            float  _S65[16];
            _S65[0] = 0.0;
            _S65[1] = 0.0;
            _S65[2] = 0.0;
            _S65[3] = 0.0;
            _S65[4] = 0.0;
            _S65[5] = 0.0;
            _S65[6] = 0.0;
            _S65[7] = 0.0;
            _S65[8] = 0.0;
            _S65[9] = 0.0;
            _S65[10] = 0.0;
            _S65[11] = 0.0;
            _S65[12] = 0.0;
            _S65[13] = 0.0;
            _S65[14] = 0.0;
            _S65[15] = 0.0;
            _S65[_dc_0] = _S63.differential_0;
            float _S66 = _S44[0] + _S65[0];
            float _S67 = _S44[1] + _S65[1];
            float _S68 = _S44[2] + _S65[2];
            float _S69 = _S44[3] + _S65[3];
            float _S70 = _S44[4] + _S65[4];
            float _S71 = _S44[5] + _S65[5];
            float _S72 = _S44[6] + _S65[6];
            float _S73 = _S44[7] + _S65[7];
            float _S74 = _S44[8] + _S65[8];
            float _S75 = _S44[9] + _S65[9];
            float _S76 = _S44[10] + _S65[10];
            float _S77 = _S44[11] + _S65[11];
            float _S78 = _S44[12] + _S65[12];
            float _S79 = _S44[13] + _S65[13];
            float _S80 = _S44[14] + _S65[14];
            float _S81 = _S44[15] + _S65[15];
            _S43 = _S64;
            _S44[0] = _S66;
            _S44[1] = _S67;
            _S44[2] = _S68;
            _S44[3] = _S69;
            _S44[4] = _S70;
            _S44[5] = _S71;
            _S44[6] = _S72;
            _S44[7] = _S73;
            _S44[8] = _S74;
            _S44[9] = _S75;
            _S44[10] = _S76;
            _S44[11] = _S77;
            _S44[12] = _S78;
            _S44[13] = _S79;
            _S44[14] = _S80;
            _S44[15] = _S81;
        }
        else
        {
            _S43 = TextureBlock_x24_syn_dadd_0(_S56, _S41);
        }
        _dc_0 = _dc_0 - 1;
    }
    CompressedTextureBlock2P_Differential_0 _S82 = CompressedTextureBlock2P_x24_syn_dzero_0();
    _S82.partition_logits_1 = _S44;
    dpblockCoefficients_1.primal_0 = dpblockCoefficients_1.primal_0;
    dpblockCoefficients_1.differential_0 = _S82;
    return;
}

void s_bwd_prop_dot_0(inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S83, inout DiffPair_vectorx3Cfloatx2C3x3E_0 _S84, float _S85)
{
    _d_dot_0(_S83, _S84, _S85);
    return;
}

void s_bwd_prop_loss_2P_0(uint _S86, inout DiffPair_CompressedTextureBlock2P_0 _S87, float _S88)
{
    CompressedTextureBlock2P_0 _S89 = _S87.primal_0;
    TextureBlock_0 _S90 = s_primal_ctx_decompress2P_0(_S87.primal_0);
    vec3 _S91 = vec3(0.0);
    int _dc_1 = 16;
    float _S92 = _S88;
    vec3  _S93[16];
    _S93[0] = _S91;
    _S93[1] = _S91;
    _S93[2] = _S91;
    _S93[3] = _S91;
    _S93[4] = _S91;
    _S93[5] = _S91;
    _S93[6] = _S91;
    _S93[7] = _S91;
    _S93[8] = _S91;
    _S93[9] = _S91;
    _S93[10] = _S91;
    _S93[11] = _S91;
    _S93[12] = _S91;
    _S93[13] = _S91;
    _S93[14] = _S91;
    _S93[15] = _S91;
    for(;;)
    {
        if(_dc_1 >= 0)
        {
        }
        else
        {
            break;
        }
        bool _S94 = _dc_1 < 16;
        int _S95;
        vec3 _S96;
        if(_S94)
        {
            vec3 diff_0 = _S90.pixels_0[_dc_1] - g_groundtruth_0._data[uint(_S86)].pixels_0[_dc_1];
            _S95 = 1;
            _S96 = diff_0;
        }
        else
        {
            _S95 = 0;
            _S96 = _S91;
        }
        float _S97;
        float _S98;
        if(!(_S95 != 1))
        {
            _S97 = _S92;
            _S98 = 0.0;
        }
        else
        {
            _S97 = 0.0;
            _S98 = _S92;
        }
        if(_S94)
        {
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S99;
            _S99.primal_0 = _S96;
            _S99.differential_0 = _S91;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S100;
            _S100.primal_0 = _S96;
            _S100.differential_0 = _S91;
            s_bwd_prop_dot_0(_S99, _S100, _S97);
            vec3 _S101 = _S100.differential_0 + _S99.differential_0;
            float _S102 = _S97 + _S98;
            vec3  _S103[16];
            _S103[0] = _S91;
            _S103[1] = _S91;
            _S103[2] = _S91;
            _S103[3] = _S91;
            _S103[4] = _S91;
            _S103[5] = _S91;
            _S103[6] = _S91;
            _S103[7] = _S91;
            _S103[8] = _S91;
            _S103[9] = _S91;
            _S103[10] = _S91;
            _S103[11] = _S91;
            _S103[12] = _S91;
            _S103[13] = _S91;
            _S103[14] = _S91;
            _S103[15] = _S91;
            _S103[_dc_1] = _S101;
            vec3 _S104 = _S93[0] + _S103[0];
            vec3 _S105 = _S93[1] + _S103[1];
            vec3 _S106 = _S93[2] + _S103[2];
            vec3 _S107 = _S93[3] + _S103[3];
            vec3 _S108 = _S93[4] + _S103[4];
            vec3 _S109 = _S93[5] + _S103[5];
            vec3 _S110 = _S93[6] + _S103[6];
            vec3 _S111 = _S93[7] + _S103[7];
            vec3 _S112 = _S93[8] + _S103[8];
            vec3 _S113 = _S93[9] + _S103[9];
            vec3 _S114 = _S93[10] + _S103[10];
            vec3 _S115 = _S93[11] + _S103[11];
            vec3 _S116 = _S93[12] + _S103[12];
            vec3 _S117 = _S93[13] + _S103[13];
            vec3 _S118 = _S93[14] + _S103[14];
            vec3 _S119 = _S93[15] + _S103[15];
            _S92 = _S102;
            _S93[0] = _S104;
            _S93[1] = _S105;
            _S93[2] = _S106;
            _S93[3] = _S107;
            _S93[4] = _S108;
            _S93[5] = _S109;
            _S93[6] = _S110;
            _S93[7] = _S111;
            _S93[8] = _S112;
            _S93[9] = _S113;
            _S93[10] = _S114;
            _S93[11] = _S115;
            _S93[12] = _S116;
            _S93[13] = _S117;
            _S93[14] = _S118;
            _S93[15] = _S119;
        }
        else
        {
            _S92 = _S98;
        }
        _dc_1 = _dc_1 - 1;
    }
    TextureBlock_0 _S120 = TextureBlock_x24_syn_dzero_0();
    _S120.pixels_0 = _S93;
    CompressedTextureBlock2P_Differential_0 _S121 = CompressedTextureBlock2P_x24_syn_dzero_0();
    DiffPair_CompressedTextureBlock2P_0 _S122;
    _S122.primal_0 = _S89;
    _S122.differential_0 = _S121;
    s_bwd_prop_decompress2P_0(_S122, _S120);
    _S87.primal_0 = _S87.primal_0;
    _S87.differential_0 = _S122.differential_0;
    return;
}

void s_bwd_loss_2P_0(uint _S123, inout DiffPair_CompressedTextureBlock2P_0 _S124, float _S125)
{
    s_bwd_prop_loss_2P_0(_S123, _S124, _S125);
    return;
}

struct Means_0
{
    vec3 mean_0;
    int count_0;
};

void calc_partition_means_0(uint _S126, float  _S127[16], out Means_0 _S128, out Means_0 _S129)
{
    const vec3 _S130 = vec3(0.0);
    _S128.count_0 = 0;
    _S129.count_0 = 0;
    int i_5 = 0;
    vec3 sum0_0 = _S130;
    vec3 sum1_0 = _S130;
    [[unroll]]
    for(;;)
    {
        if(i_5 < 16)
        {
        }
        else
        {
            break;
        }
        vec3 px_0 = g_groundtruth_0._data[uint(_S126)].pixels_0[i_5];
        if((_S127[i_5]) <= 0.0)
        {
            vec3 sum0_1 = sum0_0 + px_0;
            _S128.count_0 = _S128.count_0 + 1;
            sum0_0 = sum0_1;
        }
        else
        {
            vec3 sum1_1 = sum1_0 + px_0;
            _S129.count_0 = _S129.count_0 + 1;
            sum1_0 = sum1_1;
        }
        i_5 = i_5 + 1;
    }
    if((_S128.count_0) > 0)
    {
        sum0_0 = sum0_0 / float(_S128.count_0);
    }
    else
    {
        sum0_0 = _S130;
    }
    _S128.mean_0 = sum0_0;
    if((_S129.count_0) > 0)
    {
        sum0_0 = sum1_0 / float(_S129.count_0);
    }
    else
    {
        sum0_0 = _S130;
    }
    _S129.mean_0 = sum0_0;
    return;
}

void calc_partition_covariances_0(uint _S131, float  _S132[16], Means_0 _S133, Means_0 _S134, out mat3x3 _S135, out mat3x3 _S136)
{
    const mat3x3 _S137 = mat3x3(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    _S135 = _S137;
    _S136 = _S137;
    int i_6 = 0;
    [[unroll]]
    for(;;)
    {
        if(i_6 < 16)
        {
        }
        else
        {
            break;
        }
        vec3 px_1 = g_groundtruth_0._data[uint(_S131)].pixels_0[i_6];
        if((_S132[i_6]) <= 0.0)
        {
            vec3 d_0 = px_1 - _S133.mean_0;
            _S135[0] = _S135[0] + d_0 * d_0.x;
            _S135[1] = _S135[1] + d_0 * d_0.y;
            _S135[2] = _S135[2] + d_0 * d_0.z;
        }
        else
        {
            vec3 d_1 = px_1 - _S134.mean_0;
            _S136[0] = _S136[0] + d_1 * d_1.x;
            _S136[1] = _S136[1] + d_1 * d_1.y;
            _S136[2] = _S136[2] + d_1 * d_1.z;
        }
        i_6 = i_6 + 1;
    }
    return;
}

void calc_projection_bounds_0(uint _S138, float  _S139[16], Means_0 _S140, Means_0 _S141, vec3 _S142, vec3 _S143, out vec2 _S144, out vec2 _S145)
{
    vec2 _S146;
    if((_S140.count_0) > 0)
    {
        _S146 = vec2(1.0e+09, -1.0e+09);
    }
    else
    {
        _S146 = vec2(0.0, 0.0);
    }
    _S144 = _S146;
    if((_S141.count_0) > 0)
    {
        _S146 = vec2(1.0e+09, -1.0e+09);
    }
    else
    {
        _S146 = vec2(0.0, 0.0);
    }
    _S145 = _S146;
    int i_7 = 0;
    [[unroll]]
    for(;;)
    {
        if(i_7 < 16)
        {
        }
        else
        {
            break;
        }
        vec3 px_2 = g_groundtruth_0._data[uint(_S138)].pixels_0[i_7];
        if((_S139[i_7]) <= 0.0)
        {
            float t_0 = dot(px_2 - _S140.mean_0, _S142);
            _S144[0] = min(_S144.x, t_0);
            _S144[1] = max(_S144.y, t_0);
        }
        else
        {
            float t_1 = dot(px_2 - _S141.mean_0, _S143);
            _S145[0] = min(_S145.x, t_1);
            _S145[1] = max(_S145.y, t_1);
        }
        i_7 = i_7 + 1;
    }
    return;
}

void get_partition_endpoints_0(inout CompressedTextureBlock2P_0 _S147, uint _S148)
{
    Means_0 s0_0;
    Means_0 s1_0;
    calc_partition_means_0(_S148, _S147.partition_logits_0, s0_0, s1_0);
    mat3x3 cov0_0;
    mat3x3 cov1_0;
    calc_partition_covariances_0(_S148, _S147.partition_logits_0, s0_0, s1_0, cov0_0, cov1_0);
    vec3 axis0_0;
    if((s0_0.count_0) > 1)
    {
        axis0_0 = get_principal_axis_0(cov0_0);
    }
    else
    {
        axis0_0 = normalize(_S147.ep1_0 - _S147.ep0_0 + 9.99999997475242708e-07);
    }
    vec3 axis1_0;
    if((s1_0.count_0) > 1)
    {
        axis1_0 = get_principal_axis_0(cov1_0);
    }
    else
    {
        axis1_0 = normalize(_S147.ep3_0 - _S147.ep2_0 + 9.99999997475242708e-07);
    }
    vec2 bounds0_0;
    vec2 bounds1_0;
    calc_projection_bounds_0(_S148, _S147.partition_logits_0, s0_0, s1_0, axis0_0, axis1_0, bounds0_0, bounds1_0);
    if((s0_0.count_0) > 0)
    {
        _S147.ep0_0 = s0_0.mean_0 + axis0_0 * bounds0_0.x;
        _S147.ep1_0 = s0_0.mean_0 + axis0_0 * bounds0_0.y;
    }
    if((s1_0.count_0) > 0)
    {
        _S147.ep2_0 = s1_0.mean_0 + axis1_0 * bounds1_0.x;
        _S147.ep3_0 = s1_0.mean_0 + axis1_0 * bounds1_0.y;
    }
    return;
}

void optim_weights_2P_0(inout CompressedTextureBlock2P_0 _S149, uint _S150)
{
    get_partition_endpoints_0(_S149, _S150);
    vec3 _S151 = _S149.ep1_0 - _S149.ep0_0;
    vec3 _S152 = _S149.ep3_0 - _S149.ep2_0;
    int i_8 = 0;
    for(;;)
    {
        if(i_8 < 16)
        {
        }
        else
        {
            break;
        }
        vec3 C_0 = g_groundtruth_0._data[uint(_S150)].pixels_0[i_8];
        vec3 _S153 = g_groundtruth_0._data[uint(_S150)].pixels_0[i_8] - _S149.ep0_0;
        vec3 P_0;
        vec3 D_0;
        if((_S149.partition_logits_0[i_8]) > 0.0)
        {
            P_0 = C_0 - _S149.ep2_0;
            D_0 = _S152;
        }
        else
        {
            P_0 = _S153;
            D_0 = _S151;
        }
        _S149.weights_1.weights_0[i_8] = saturate_0(dot(P_0, D_0) / (dot(D_0, D_0) + 9.99999997475242708e-07));
        i_8 = i_8 + 1;
    }
    return;
}

float loss_2P_0(uint _S154, CompressedTextureBlock2P_0 _S155)
{
    TextureBlock_0 _S156 = decompress2P_0(_S155);
    int i_9 = 0;
    float totalError_0 = 0.0;
    for(;;)
    {
        if(i_9 < 16)
        {
        }
        else
        {
            break;
        }
        vec3 diff_1 = _S156.pixels_0[i_9] - g_groundtruth_0._data[uint(_S154)].pixels_0[i_9];
        float totalError_1 = totalError_0 + dot(diff_1, diff_1);
        i_9 = i_9 + 1;
        totalError_0 = totalError_1;
    }
    return totalError_0;
}

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {
        return;
    }
    uvec2 _S157 = (clockRealtime2x32EXT());
    g_diagnostics_0._data[uint(blockIdx_0)].start_clock_0 = _S157;
    CompressedTextureBlock2P_0 value_0 = g_compressedBlock2P_0._data[uint(blockIdx_0)];
    float _S158 = g_compress_step_params_0._data[uint(0)].learning_rate_0;
    uint steps_1 = g_compress_step_params_0._data[uint(0)].steps_0;
    uint _S159 = g_compress_step_params_0._data[uint(0)].snap_steps_0;
    uint _S160 = g_compress_step_params_0._data[uint(0)].steps_0 / 2U;
    uint _S161 = max(1U, g_compress_step_params_0._data[uint(0)].steps_0 / 20U);
    int step_0 = 0;
    for(;;)
    {
        if(step_0 < int(steps_1))
        {
        }
        else
        {
            break;
        }
        CompressedTextureBlock2P_Differential_0 _S162 = CompressedTextureBlock2P_x24_syn_dzero_0();
        DiffPair_CompressedTextureBlock2P_0 cb_pair_0;
        cb_pair_0.primal_0 = value_0;
        cb_pair_0.differential_0 = _S162;
        s_bwd_loss_2P_0(blockIdx_0, cb_pair_0, 1.0);
        CompressedTextureBlock2P_Differential_0 _S163 = cb_pair_0.differential_0;
        int i_10 = 0;
        for(;;)
        {
            if(i_10 < 16)
            {
            }
            else
            {
                break;
            }
            value_0.partition_logits_0[i_10] = value_0.partition_logits_0[i_10] - _S163.partition_logits_1[i_10] * _S158;
            i_10 = i_10 + 1;
        }
        uint _S164 = uint(step_0);
        bool _S165;
        if(_S164 > _S160)
        {
            uint _S166 = _S164 % _S159;
            _S165 = _S166 == 0U;
        }
        else
        {
            _S165 = false;
        }
        if(_S165)
        {
            snap_0(value_0, 1.0 + float(_S164 - _S160) / float(_S159 * 2U));
        }
        optim_weights_2P_0(value_0, blockIdx_0);
        uint _S167 = _S164 % _S161;
        if(_S167 == 0U)
        {
            uint iter_0 = _S164 / _S161;
            uvec2 _S168 = (clockRealtime2x32EXT());
            g_diagnostics_0._data[uint(blockIdx_0)].timestamps_0[iter_0] = _S168;
            g_diagnostics_0._data[uint(blockIdx_0)].loss_log_0[iter_0] = loss_2P_0(blockIdx_0, value_0);
            uint raw_map_2 = pack_logits_to_mask_0(value_0.partition_logits_0);
            g_diagnostics_0._data[uint(blockIdx_0)].partition_hamming_error_log_0[iter_0] = uint(hamming_distance_0(raw_map_2, g_lut_seed_to_mask_0._data[uint(g_lut_ideal_to_seed_0._data[uint(raw_map_2)])]));
            g_diagnostics_0._data[uint(blockIdx_0)].ideal_partition_log_0[iter_0] = raw_map_2;
        }
        step_0 = step_0 + 1;
    }
    snap_0(value_0, 1.0);
    optim_weights_2P_0(value_0, blockIdx_0);
    uvec2 _S169 = (clockRealtime2x32EXT());
    g_diagnostics_0._data[uint(blockIdx_0)].optim_ended_clock_0 = _S169;
    g_compressedBlock2P_0._data[uint(blockIdx_0)] = value_0;
    g_reconstructed_0._data[uint(blockIdx_0)] = decompress2P_0(value_0);
    g_diagnostics_0._data[uint(blockIdx_0)].partition_hamming_error_0 = uint(hamming_distance_0(value_0.ideal_partition_map_0, value_0.astc_partition_map_0));
    g_final_loss_0._data[uint(blockIdx_0)] = loss_2P_0(blockIdx_0, value_0);
    uvec2 _S170 = (clockRealtime2x32EXT());
    g_diagnostics_0._data[uint(blockIdx_0)].finished_clock_0 = _S170;
    return;
}

#version 450
layout(row_major) uniform;
layout(row_major) buffer;
struct CompressStepParams_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
};

layout(std430, binding = 6) buffer StructuredBuffer_CompressStepParams_t_0 {
    CompressStepParams_0 _data[];
} g_compress_step_params_0;
layout(std430, binding = 5) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;
struct TextureBlock_0
{
    vec3  pixels_0[16];
};

layout(std430, binding = 0) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;
struct NonDifferentiableWeights_0
{
    float  weights_0[16];
};

struct CompressedTextureBlock_0
{
    vec3 ep0_0;
    vec3 ep1_0;
    NonDifferentiableWeights_0 weights_1;
};

layout(std430, binding = 3) buffer StructuredBuffer_CompressedTextureBlock_t_0 {
    CompressedTextureBlock_0 _data[];
} g_compressedBlock_0;
float NonDifferentiableWeights_operatorx5Bx5D_get_0(NonDifferentiableWeights_0 this_0, int n_0)
{
    return this_0.weights_0[n_0];
}

TextureBlock_0 decompress_0(uint _S1)
{
    CompressedTextureBlock_0 _S2 = g_compressedBlock_0._data[uint(_S1)];
    TextureBlock_0 outputBlock_0;
    int i_0 = 0;
    for(;;)
    {
        if(i_0 < 16)
        {
        }
        else
        {
            break;
        }
        outputBlock_0.pixels_0[i_0] = mix(_S2.ep0_0, _S2.ep1_0, vec3(NonDifferentiableWeights_operatorx5Bx5D_get_0(_S2.weights_1, i_0)));
        i_0 = i_0 + 1;
    }
    return outputBlock_0;
}

float loss_0(uint _S3, uint _S4)
{
    TextureBlock_0 _S5 = decompress_0(_S4);
    int i_1 = 0;
    float totalError_0 = 0.0;
    for(;;)
    {
        if(i_1 < 16)
        {
        }
        else
        {
            break;
        }
        vec3 diff_0 = _S5.pixels_0[i_1] - g_groundtruth_0._data[uint(_S3)].pixels_0[i_1];
        float totalError_1 = totalError_0 + dot(diff_0, diff_0);
        i_1 = i_1 + 1;
        totalError_0 = totalError_1;
    }
    return totalError_0;
}

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {
        return;
    }
    g_final_loss_0._data[uint(blockIdx_0)] = loss_0(blockIdx_0, blockIdx_0);
    return;
}

#version 450
layout(row_major) uniform;
layout(row_major) buffer;
struct CompressStepParams_0
{
    float learning_rate_0;
    uint steps_0;
    uint snap_steps_0;
    uint num_blocks_0;
};

layout(std430, binding = 6) buffer StructuredBuffer_CompressStepParams_t_0 {
    CompressStepParams_0 _data[];
} g_compress_step_params_0;
layout(std430, binding = 5) buffer StructuredBuffer_float_t_0 {
    float _data[];
} g_final_loss_0;
struct TextureBlock_0
{
    vec3  pixels_0[16];
};

layout(std430, binding = 0) readonly buffer StructuredBuffer_TextureBlock_t_0 {
    TextureBlock_0 _data[];
} g_groundtruth_0;
struct NonDifferentiableWeights_0
{
    float  weights_0[16];
};

struct CompressedTextureBlock2P_0
{
    vec3 ep0_0;
    vec3 ep1_0;
    vec3 ep2_0;
    vec3 ep3_0;
    NonDifferentiableWeights_0 weights_1;
    float  partition_logits_0[16];
    uint astc_partition_map_0;
    uint ideal_partition_map_0;
    uint astc_seed_0;
};

layout(std430, binding = 4) buffer StructuredBuffer_CompressedTextureBlock2P_t_0 {
    CompressedTextureBlock2P_0 _data[];
} g_compressedBlock2P_0;
float NonDifferentiableWeights_operatorx5Bx5D_get_0(NonDifferentiableWeights_0 this_0, int n_0)
{
    return this_0.weights_0[n_0];
}

float saturate_0(float x_0)
{
    return clamp(x_0, 0.0, 1.0);
}

float sigmoid_0(float x_1)
{
    return 1.0 / (1.0 + exp(- x_1));
}

float round_ste_0(float x_2)
{
    return round(x_2);
}

TextureBlock_0 decompress2P_0(uint _S1)
{
    CompressedTextureBlock2P_0 _S2 = g_compressedBlock2P_0._data[uint(_S1)];
    TextureBlock_0 outputBlock_0;
    int i_0 = 0;
    for(;;)
    {
        if(i_0 < 16)
        {
        }
        else
        {
            break;
        }
        vec3 _S3 = vec3(saturate_0(NonDifferentiableWeights_operatorx5Bx5D_get_0(_S2.weights_1, i_0)));
        outputBlock_0.pixels_0[i_0] = mix(mix(_S2.ep0_0, _S2.ep1_0, _S3), mix(_S2.ep2_0, _S2.ep3_0, _S3), vec3(round_ste_0(sigmoid_0(_S2.partition_logits_0[i_0]))));
        i_0 = i_0 + 1;
    }
    return outputBlock_0;
}

float loss_2P_0(uint _S4, uint _S5)
{
    TextureBlock_0 _S6 = decompress2P_0(_S5);
    int i_1 = 0;
    float totalError_0 = 0.0;
    for(;;)
    {
        if(i_1 < 16)
        {
        }
        else
        {
            break;
        }
        vec3 diff_0 = _S6.pixels_0[i_1] - g_groundtruth_0._data[uint(_S4)].pixels_0[i_1];
        float totalError_1 = totalError_0 + dot(diff_0, diff_0);
        i_1 = i_1 + 1;
        totalError_0 = totalError_1;
    }
    return totalError_0;
}

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void main()
{
    uint blockIdx_0 = gl_GlobalInvocationID.x;
    if(blockIdx_0 >= (g_compress_step_params_0._data[uint(0)].num_blocks_0))
    {
        return;
    }
    g_final_loss_0._data[uint(blockIdx_0)] = loss_2P_0(blockIdx_0, blockIdx_0);
    return;
}

