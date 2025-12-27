slangc astc_encoder2_soft.slang -target glsl > astc_encoder2_soft.glsl
slangc astc_encoder3_soft.slang -target glsl > astc_encoder3_soft.glsl
slangc astc_encoder_hard.slang -target glsl > astc_encoder_hard.glsl

slangc astc_encoder2_soft.slang -target spirv > astc_encoder2_soft.spv
slangc astc_encoder3_soft.slang -target spirv > astc_encoder3_soft.spv
slangc astc_encoder_hard.slang -target spirv > astc_encoder_hard.spv