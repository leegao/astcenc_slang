import slangpy as spy
import numpy as np
import time
from pathlib import Path
import argparse
import imageio.v2 as imageio
from PIL import Image
import collections

Image.MAX_IMAGE_PIXELS = None 

class AstcPartitionLut:
    def __init__(self, device):
        self.device = device
        self.lut2 = np.fromfile("lut2_packed.bin", dtype=np.uint32).astype(np.uint32)
        self.lut3 = np.fromfile("lut3_packed.bin", dtype=np.uint32).astype(np.uint32)
        self.astc_3p_4x4_lut_s3_np = np.fromfile("astc_3p_4x4_lut_s3.bin", dtype=np.uint32).astype(np.uint32)
        self.astc_2p_4x4_lut_s2_np = np.fromfile("astc_2p_4x4_lut_s2.bin", dtype=np.uint32).astype(np.uint32)

def load_and_tile_image(image_path):
    """Loads an image, pads it to be a multiple of 4x4, and tiles it into blocks."""
    try:
        img = imageio.imread(image_path)
    except FileNotFoundError:
        print(f"Error: Image file not found at {image_path}")
        exit()

    if img.ndim == 2: # Grayscale
        img = np.stack([img]*3, axis=-1)
    if img.shape[2] == 4: # RGBA
        img = img[:, :, :3]
    img = img.astype(np.uint8)

    h, w, c = img.shape
    
    pad_h = (4 - h % 4) % 4
    pad_w = (4 - w % 4) % 4
    padded_img = np.pad(img, ((0, pad_h), (0, pad_w), (0, 0)), mode='constant')
    
    ph, pw, _ = padded_img.shape
    num_blocks_y = ph // 4
    num_blocks_x = pw // 4
    num_blocks = num_blocks_y * num_blocks_x

    # Reshape and transpose to get a list of 4x4 blocks
    # (H, W, C) -> (num_y, 4, num_x, 4, C) -> (num_y, num_x, 4, 4, C) -> (num_blocks, 16, C)
    tiled = padded_img.reshape(num_blocks_y, 4, num_blocks_x, 4, c)
    tiled = tiled.transpose(0, 2, 1, 3, 4)
    tiled = tiled.reshape(num_blocks, 16, c)

    print(f"Loaded '{image_path}' ({h}x{w}) -> Padded to ({ph}x{pw}) -> {num_blocks} 4x4 blocks.")
    return tiled.astype(np.uint8), (h, w), (ph, pw)

def untile_and_save_image(tiled_data, original_dims, padded_dims, output_path):
    """Reconstructs an image from tiled blocks and saves it."""
    num_blocks, _, c = tiled_data.shape
    oh, ow = original_dims
    ph, pw = padded_dims
    num_blocks_y = ph // 4
    num_blocks_x = pw // 4

    # (num_blocks, 16, C) -> (num_y, num_x, 4, 4, C) -> (num_y, 4, num_x, 4, C) -> (H_pad, W_pad, C)
    img_reshaped = tiled_data.reshape(num_blocks_y, num_blocks_x, 4, 4, c)
    img_transposed = img_reshaped.transpose(0, 2, 1, 3, 4)
    padded_img = img_transposed.reshape(ph, pw, c)
    final_img = padded_img[:oh, :ow, :]
    final_img_u8 = final_img.astype(np.uint8)
    imageio.imwrite(output_path, final_img_u8)
    print(f"Saved reconstructed image to '{output_path}'")


def main(args):
    groundtruth_data, orig_dims, padded_dims = load_and_tile_image(args.input)
    num_blocks = groundtruth_data.shape[0]
    options = spy.SlangCompilerOptions()
    options.optimization = spy.SlangOptimizationLevel.maximal
    options.downstream_args = ["-O3"]
    device = spy.Device(type=spy.DeviceType.vulkan, enable_debug_layers=False, compiler_options=options)
    astc_lut = AstcPartitionLut(device)

    compress_3P_program = device.load_program("astc_encoder3_soft.slang", ["compress_3P_step"])
    compress_3P_kernel = device.create_compute_kernel(compress_3P_program)

    compress_hard_program = device.load_program("astc_encoder_hard.slang", ["compress_3P_step"])
    compress_hard_kernel = device.create_compute_kernel(compress_hard_program)
    
    texture_block_dtype = np.dtype([('pixels', (np.uint8, (16, 3)))])
    diagnostics_dtype = np.dtype([
        ('partition_hamming_error', np.uint32),
        ('loss_log', (np.float32, (12, 3))),
        ('start_clock', (np.uint64, 1)), # optim_ended_clock, finished_clock
        ('optim_ended_clock', (np.uint64, 1)),
        ('finished_clock', (np.uint64, 1)),
        ('timestamps', (np.uint64, 12)),
        ('partition_hamming_error_log', (np.uint32, 12)),
        ('ideal_partition_log', (np.uint32, 12)),
        ('partition_count', (np.uint32, 12)),
        ('final_unquantized_loss', np.float32),
        # ('delta1', (np.float32, (3, 10))),
        # ('delta2', (np.float32, (3, 10))),
        # ('delta3', (np.float32, (3, 10))),
        # ('color_mean1', (np.float32, (3, 10))),
        # ('color_mean2', (np.float32, (3, 10))),
        # ('color_mean3', (np.float32, (3, 10))),
    ])

    hard_comp_block_dtype_3P = np.dtype([
        ('ep0', (np.uint8, 3)), ('ep1', (np.uint8, 3)),
        ('ep2', (np.uint8, 3)), ('ep3', (np.uint8, 3)),
        ('ep4', (np.uint8, 3)), ('ep5', (np.uint8, 3)),
        ('weights', (np.uint8, 16)),
        ('astc_partition_map', np.int32),
        # ('astc_partition_map', np.uint32),
        ('ideal_partition_map', np.uint32),
        ('astc_seed', np.uint16),
        ('perm', np.uint8),
        ('max_partitions', np.uint8),
        ('wc', (np.uint8, 2)),
        ('fwc', (np.uint8, 2)),
        ('padding', (np.uint8, 2)),
    ])

    soft_comp_block_dtype_3P = np.dtype([
        ('ep0', (np.float16, 3)), ('ep1', (np.float16, 3)),
        ('ep2', (np.float16, 3)), ('ep3', (np.float16, 3)),
        ('ep4', (np.float16, 3)), ('ep5', (np.float16, 3)),
        ('weights', (np.uint8, 16)),
        ('partition_logits', (np.int8, 16)),
        ('astc_partition_map', np.uint32),
        ('ideal_partition_map', np.uint32),
        ('astc_seed', np.uint16),
        ('perm', np.uint8),
        ('partition_count', np.uint8),
        ('max_partitions', np.uint8),
        ('wc', (np.uint8, 2)),
        ('fwc', (np.uint8, 2)),
        ('padding', (np.uint8, 3)),
    ])

    comp_block_dtype_3P = soft_comp_block_dtype_3P if not args.hard else hard_comp_block_dtype_3P

    reflection_hard = compress_hard_kernel.reflection
    reflection_soft = compress_3P_kernel.reflection
    reflection = reflection_soft if not args.hard else reflection_hard

    groundtruth_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=reflection.g_groundtruth,
        usage=spy.BufferUsage.shader_resource, data=groundtruth_data
    )

    block_data = np.zeros(num_blocks, dtype=comp_block_dtype_3P)
    compressed_block_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=reflection.g_compressedBlock3P,
        usage=spy.BufferUsage.unordered_access, data=block_data.view(np.uint8)
    )

    loss_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=reflection.g_final_loss,
        usage=spy.BufferUsage.unordered_access
    )

    reconstructed_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=reflection.g_reconstructed,
        usage=spy.BufferUsage.unordered_access
    )

    initial_diagnostics_struct = np.zeros(num_blocks, dtype=diagnostics_dtype)
    diagnostics_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=reflection.g_diagnostics,
        usage=spy.BufferUsage.unordered_access, data=initial_diagnostics_struct.view(np.uint8)
    )

    astc_3p_4x4_lut_s3_buffer = device.create_buffer(
        element_count=len(astc_lut.astc_3p_4x4_lut_s3_np),
        resource_type_layout=reflection_soft.g_astc_3p_4x4_lut_s3,
        usage=spy.BufferUsage.shader_resource,
        data=astc_lut.astc_3p_4x4_lut_s3_np
    )

    astc_2p_4x4_lut_s2_buffer = device.create_buffer(
        element_count=len(astc_lut.astc_2p_4x4_lut_s2_np),
        resource_type_layout=reflection_soft.g_astc_2p_4x4_lut_s2,
        usage=spy.BufferUsage.shader_resource,
        data=astc_lut.astc_2p_4x4_lut_s2_np
    )

    ranked_seeds_dtype = np.dtype([
        ('slots', (np.uint8)),
        ('seeds', (np.uint32, (8 * 10 + 2) // 3)),
        ('counts', (np.uint8, 8)),
        ('padding', (np.uint8, 3)),
    ])

    scratch_dtype = np.dtype([
        ('partitions', (np.uint16, 256)),
        ('block1', comp_block_dtype_3P),
        ('block2', comp_block_dtype_3P),
        ('block3', comp_block_dtype_3P),
        ('block4', comp_block_dtype_3P),
        # ('ranked_seeds', ranked_seeds_dtype),
    ])
    scratch_data = np.zeros(num_blocks, dtype=scratch_dtype)
    scratch_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=compress_hard_kernel.reflection.g_scratch,
        usage=spy.BufferUsage.unordered_access, data=scratch_data.view(np.uint8)
    )

    if args.ensemble:
        if not args.use_2p:
            args.use_3p = True

    dispatch_vars = {
        "g_groundtruth": groundtruth_buffer,
        "g_compressedBlock3P": compressed_block_buffer,
        "g_final_loss": loss_buffer,
        "g_reconstructed": reconstructed_buffer,
        'g_diagnostics': diagnostics_buffer,
        'g_scratch': scratch_buffer,
        "g_astc_3p_4x4_lut_s3": astc_3p_4x4_lut_s3_buffer,
        "g_astc_2p_4x4_lut_s2": astc_2p_4x4_lut_s2_buffer,
        "g_lut": {
            "lut2": astc_lut.lut2,
            "lut3": astc_lut.lut3,
        },
        "g_params": {
            "learning_rate": args.lr,
            "steps": args.m,
            "steps_1p": args.steps_1p if args.steps_1p > 0 else args.m,
            "snap_steps": args.snap_steps,
            "num_blocks": num_blocks,
            "snap": bool(not args.no_snap),
            "max_partitions": 3 if args.use_3p else (2 if args.use_2p else 1),
            "debug_reconstruction": args.debug_reconstruction,
            "debug_quant": args.debug_quant,
            "debug_loss": args.debug_loss,
            "exact_steps": args.exact_steps,
            "use_pca": not args.use_aabb,
            "seed": args.seed,
            "no_quantization": args.no_quantization,
            "ensemble": args.ensemble,
            "exhaustive": args.exhaustive,
        }
    }

    grid = (num_blocks, 1, 1)
    kernel_to_run = compress_3P_kernel if not args.hard else compress_hard_kernel

    print(f"\n--- Starting {3 if args.use_3p else (2 if args.use_2p else 1)}-Partition Compression ---")
    print(f"Running gradient descent for {args.m} steps")
    wall_start = time.time()
    kernel_to_run.dispatch(grid, vars=dispatch_vars)
    diagnostics = diagnostics_buffer.to_numpy().view(diagnostics_dtype)
    wall_end = time.time()
    loss_log = diagnostics['loss_log'].mean(0)
    best_loss = diagnostics['loss_log'].min(2).mean(0)
    timestamps = diagnostics['timestamps']
    thread_timestamps = (timestamps - diagnostics['start_clock']).T / 100000
    print(f"\nOptimization finished in {(diagnostics['finished_clock'].max() - diagnostics['start_clock'].min()) / 100000:.2f} ms over {num_blocks} threads")
    print(f"  Wall clock: {wall_end - wall_start}")
    for i, loss in enumerate(loss_log):
        checkpoint = max(1, args.m // 10)
        if i * checkpoint >= args.m + 1: break
        print(f"Step {i * checkpoint}: loss = {best_loss[i] if args.ensemble else loss.max():.4f} ({thread_timestamps[i].mean():0.2f} ms/thread mean, {thread_timestamps[i].min():0.2f} ms / {thread_timestamps[i].max():0.2f} ms)")
        if (args.ensemble):
            print(f"  Ensemble 1P: {loss[0]:.4f}, 2P: {loss[1]:.4f}, 3P: {loss[2]:.4f}, Best: {best_loss[i]:.4f}")
        # if (args.use_2p or args.use_3p) and not args.ensemble:
        #     print(f"  Partition hamming error at step {i}: {diagnostics['partition_hamming_error_log'].sum(0)[i]}")
        #     print(f"  Mask: {diagnostics['ideal_partition_log'][0][i]:032b}")
        #     histogram = [0,0,0,0]
        #     partition_count = diagnostics['partition_count']
        #     for c in partition_count.T[i]:
        #         if 1 <= c <= 3:
        #             histogram[c-1] += 1
        #     print(f"  Histogram of partitions used: {histogram}")
            # delta1 = diagnostics['delta1'].T[i]
            # print(f"  [line 1] Mean spread: {np.sqrt((delta1.T ** 2).sum(1)).mean():.3f}")
            # delta2 = diagnostics['delta2'].T[i]
            # print(f"  [line 2] Mean spread: {np.sqrt((delta2.T ** 2).sum(1)).mean():.3f}")
            # delta3 = diagnostics['delta3'].T[i]
            # print(f"  [line 3] Mean spread: {np.sqrt((delta3.T ** 2).sum(1)).mean():.3f}")
            # print(delta1)

    finished = diagnostics['finished_clock']
    optim_ended = diagnostics['optim_ended_clock']
    print(f" + diagnostics overhead per thread: {(finished - optim_ended).mean() / 100000:.5f} ms / {(finished - optim_ended).min() / 100000:.5f} ms / {(finished - optim_ended).max() / 100000:.5f} ms")
    # if args.use_2p or args.use_3p:
    #     print(f"Partition hamming error: {diagnostics['partition_hamming_error'].mean()}")
    unquantized_loss = diagnostics['final_unquantized_loss'].mean(0)
    # final loss is the sum of 16 pixels' MSEs (of 3 components each - RGB)
    final_loss = loss_buffer.to_numpy().view(np.float32).mean(0)
    print(f"Final Mean L^2 Unquantized Loss per block: {unquantized_loss:.4f}")
    # if (args.ensemble):
    print(f"  Ensemble 1P: {loss_log[-1][0]:.4f}, 2P: {loss_log[-1][1]:.4f}, 3P: {loss_log[-1][2]:.4f}, Best: {best_loss[-1]:.4f}")
    print(f"Final Mean L^2 Loss per block: {final_loss:.4f}")
    print(f"Final PSNR: {10 * np.log10(1 / (final_loss / 16 / 3)):.4f} dB")

    # print(compressed_block_buffer.to_numpy().view(comp_block_dtype_3P)['perm'])
    # print(compressed_block_buffer.to_numpy().view(comp_block_dtype_3P)['astc_seed'])
    # print(np.histogram(compressed_block_buffer.to_numpy().view(comp_block_dtype_3P)['perm']))
    # print(np.histogram(compressed_block_buffer.to_numpy().view(comp_block_dtype_3P)['astc_seed']))

    # print(diagnostics['partition_count'][:,-1]) # Number of skips
    # print(diagnostics['partition_count'][:,-1].mean())
    # print(diagnostics['partition_count'][:,-2]) # First skip
    # print(diagnostics['loss_log'][:,-1,2])
    # for i in range(len(diagnostics['ideal_partition_log'])):
    #     print(i, diagnostics['ideal_partition_log'][i][19])
    # print(compressed_3P_buffer.to_numpy().view(comp_block_dtype_3P)['astc_partition_map'])
    # print(compressed_3P_buffer.to_numpy().view(comp_block_dtype_3P)['ideal_partition_map'])
    # print(compressed_3P_buffer.to_numpy().view(comp_block_dtype_3P)['perm'])
    # print(compressed_3P_buffer.to_numpy().view(comp_block_dtype_3P)['astc_seed'])
    wc = compressed_block_buffer.to_numpy().view(comp_block_dtype_3P)['wc']
    # fwc = compressed_block_buffer.to_numpy().view(comp_block_dtype_3P)['fwc']

    # print(diagnostics['loss_log'][:,0,2])

    if not args.no_quantization:
        print(f"Mean color mode quantization bits: {np.log2(wc.T[1]).mean():0.3} bits / [0 .. {round(wc.T[1].mean()) - 1}] range")
        print(f"Mean weight quantization bits: {np.log2(wc.T[0]).mean():0.3} bits / [0 .. {round(wc.T[0].mean()) - 1}] range")
        # print(f"Mean predicted vs best color quantization method error: {(((np.log2(wc.T[1]) - np.log2(fwc.T[1])) ** 2) ** 0.5).mean():0.3} bits")
        color_ranges = collections.defaultdict(int)
        for color_range in wc.T[1]:
            color_ranges[int(color_range)] += 1
        print(f"Color mode quantization histogram: {sorted(color_ranges.items())}")
    
    print(diagnostics_buffer.size / 1024 / 1024, compressed_block_buffer.size / 1024 / 1024, reconstructed_buffer.size / 1024 / 1024, scratch_buffer.size / 1024 / 1024)
    

    reconstructed_data = reconstructed_buffer.to_numpy().view(texture_block_dtype)['pixels']
    untile_and_save_image(reconstructed_data, orig_dims, padded_dims, args.output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Differentiable ASTC/BCn-style Texture Compressor")
    parser.add_argument("input", type=str, help="Path to the input image file.")
    parser.add_argument("-o", "--output", type=str, default="reconstructed.png", help="Path to save the reconstructed output image.")
    parser.add_argument("--use_2p", action="store_true", help="Use the 2-partition compressor instead of the default 1-partition.")
    parser.add_argument("--use_3p", action="store_true", help="Use the 3-partition compressor instead of the default 1-partition.")
    parser.add_argument("--lr", type=float, default=0.1, help="Learning rate for gradient descent.")
    parser.add_argument("--m", type=int, default=20, help="Number of gradient descent steps per dispatch.")
    parser.add_argument("--snap_steps", type=int, default=0, help="Frequency of snapping partitions to valid ASTC maps (for 2P mode).")
    parser.add_argument("--no_snap", action="store_true", help="Don't snap to astc valid patterns")
    parser.add_argument("--debug_reconstruction", action="store_true", help="Use debug output for reconstruction")
    parser.add_argument("--exact_steps", type=int, default=0, help="Number of exact steps to run")
    parser.add_argument("--use_aabb", action="store_true", help="Use PCA instead of AABB")
    parser.add_argument("--seed", type=int, default=0, help="Use PRNG seed (default 0)")
    parser.add_argument("--no_quantization", action="store_true", help="Don't quantize the image to a valid astc mode")
    parser.add_argument("--debug_quant", action="store_true", help="Use debug output for reconstruction")
    parser.add_argument("--debug_loss", action="store_true", help="Use debug output for loss")
    parser.add_argument("--ensemble", action="store_true", help="Ensemble 1P, 2P, and 3P compressors")
    parser.add_argument("--steps_1p", type=int, default=0, help="Number of gradient descent steps for just 1P search in ensemble mode")
    parser.add_argument("--hard", action="store_true", help="Use hard mode")
    parser.add_argument("--exhaustive", action="store_true", help="Use exhaustive search")

    args = parser.parse_args()
    main(args)