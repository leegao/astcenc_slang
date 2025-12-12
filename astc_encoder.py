import slangpy as spy
import numpy as np
import time
from pathlib import Path
import argparse
import imageio.v2 as imageio
from PIL import Image

Image.MAX_IMAGE_PIXELS = None 

class AstcPartitionLut:
    def __init__(self, device):
        self.device = device
        self.lut_ideal_to_seed_file = "astc_2p_4x4_lut.bin"
        self.lut_seed_to_mask_file = "lut2_packed.bin"
        
        if not (Path(self.lut_ideal_to_seed_file).exists() and Path(self.lut_seed_to_mask_file).exists()):
            raise Exception("astc_2p_4x4_lut.bin + astc_2p_seed_to_mask_lut.bin not found")

        self.lut_ideal_to_seed_np = np.fromfile(self.lut_ideal_to_seed_file, dtype=np.uint16).astype(np.uint32)
        self.lut_seed_to_mask_np = np.fromfile(self.lut_seed_to_mask_file, dtype=np.uint32).astype(np.uint32)
        self.lut3 = np.fromfile("lut3_packed.bin", dtype=np.uint32).astype(np.uint32)
        
        
        print(f"Loaded {len(self.lut_ideal_to_seed_np)} ideal-to-astc-seed entries.")
        print(f"Loaded {len(self.lut_seed_to_mask_np)} astc-seed-to-mask entries.")

    def create_gpu_buffers(self, ideal_layout, seed_layout):
        ideal_buffer = self.device.create_buffer(
            element_count=len(self.lut_ideal_to_seed_np),
            resource_type_layout=ideal_layout,
            usage=spy.BufferUsage.shader_resource,
            data=self.lut_ideal_to_seed_np
        )
        seed_buffer = self.device.create_buffer(
            element_count=len(self.lut_seed_to_mask_np),
            resource_type_layout=seed_layout,
            usage=spy.BufferUsage.shader_resource,
            data=self.lut_seed_to_mask_np
        )
        return ideal_buffer, seed_buffer

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
    img = img.astype(np.float32) / 255.0

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
    return tiled.astype(np.float32), (h, w), (ph, pw)

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
    final_img_u8 = (np.clip(final_img, 0, 1) * 255).astype(np.uint8)
    imageio.imwrite(output_path, final_img_u8)
    print(f"Saved reconstructed image to '{output_path}'")


def main(args):
    groundtruth_data, orig_dims, padded_dims = load_and_tile_image(args.input)
    num_blocks = groundtruth_data.shape[0]

    device = spy.Device(enable_debug_layers=False)
    astc_lut = AstcPartitionLut(device)

    compress_program = device.load_program("astc_encoder.slang", ["compress_step"])
    compress_kernel = device.create_compute_kernel(compress_program)

    compress_2P_program = device.load_program("astc_encoder2.slang", ["compress_2P_step"])
    compress_2P_kernel = device.create_compute_kernel(compress_2P_program)

    compress_3P_program = device.load_program("astc_encoder3.slang", ["compress_3P_step"])
    compress_3P_kernel = device.create_compute_kernel(compress_3P_program)

    get_loss_program = device.load_program("astc_encoder.slang", ["get_loss"])
    get_loss_kernel = device.create_compute_kernel(get_loss_program)

    get_loss_2P_program = device.load_program("astc_encoder2.slang", ["get_loss_2P"])
    get_loss_2P_kernel = device.create_compute_kernel(get_loss_2P_program)
    
    texture_block_dtype = np.dtype([('pixels', (np.float32, (16, 3)))])
    diagnostics_dtype = np.dtype([
        ('partition_hamming_error', np.uint32),
        ('loss_log', (np.float32, 20)),
        ('start_clock', (np.uint64, 1)), # optim_ended_clock, finished_clock
        ('optim_ended_clock', (np.uint64, 1)),
        ('finished_clock', (np.uint64, 1)),
        ('timestamps', (np.uint64, 20)),
        ('partition_hamming_error_log', (np.uint32, 20)),
        ('ideal_partition_log', (np.uint32, 20)),
    ])
    
    comp_block_dtype_1P = np.dtype([
        ('ep0', (np.float32, 3)),
        ('ep1', (np.float32, 3)),
        ('weights', (np.float32, 16)),
    ])

    comp_block_dtype_2P = np.dtype([
        ('ep0', (np.float32, 3)), ('ep1', (np.float32, 3)),
        ('ep2', (np.float32, 3)), ('ep3', (np.float32, 3)),
        ('weights', (np.float32, 16)),
        ('partition_logits', (np.float32, 16)),
        ('astc_partition_map', np.uint32),
        ('ideal_partition_map', np.uint32),
        ('astc_seed', np.uint32),
    ])

    comp_block_dtype_3P = np.dtype([
        ('ep0', (np.float32, 3)), ('ep1', (np.float32, 3)),
        ('ep2', (np.float32, 3)), ('ep3', (np.float32, 3)),
        ('ep4', (np.float32, 3)), ('ep5', (np.float32, 3)),
        ('weights', (np.float32, 16)),
        ('partition_logits', (np.float32, 16)),
        ('astc_partition_map', np.uint32),
        ('ideal_partition_map', np.uint32),
        ('astc_seed', np.uint32),
    ])

    params_dtype = np.dtype([
        ('learning_rate', np.float32),
        ('steps', np.uint32),
        ('snap_steps', np.uint32),
        ('num_blocks', np.uint32),
        ('snap', np.uint32),
    ])

    reflection = compress_kernel.reflection

    groundtruth_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=reflection.g_groundtruth,
        usage=spy.BufferUsage.shader_resource, data=groundtruth_data
    )

    initial_params_1p = np.random.rand(num_blocks, 22).astype(np.float32) # ep0, ep1, weights
    compressed_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=reflection.g_compressedBlock,
        usage=spy.BufferUsage.unordered_access, data=initial_params_1p
    )
    
    initial_params_2p_struct = np.zeros(num_blocks, dtype=comp_block_dtype_2P)
    initial_params_2p_struct['ep0'] = np.random.rand(num_blocks, 3)
    initial_params_2p_struct['ep1'] = np.random.rand(num_blocks, 3)
    initial_params_2p_struct['ep2'] = np.random.rand(num_blocks, 3)
    initial_params_2p_struct['ep3'] = np.random.rand(num_blocks, 3)
    initial_params_2p_struct['weights'] = np.random.rand(num_blocks, 16)
    initial_params_2p_struct['partition_logits'] = (np.random.rand(num_blocks, 16) - 0.5) # Center around 0
    compressed_2P_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=reflection.g_compressedBlock2P,
        usage=spy.BufferUsage.unordered_access, data=initial_params_2p_struct.view(np.float32)
    )

    initial_params_3p_struct = np.zeros(num_blocks, dtype=comp_block_dtype_3P)
    initial_params_3p_struct['ep0'] = np.random.rand(num_blocks, 3)
    initial_params_3p_struct['ep1'] = np.random.rand(num_blocks, 3)
    initial_params_3p_struct['ep2'] = np.random.rand(num_blocks, 3)
    initial_params_3p_struct['ep3'] = np.random.rand(num_blocks, 3)
    initial_params_3p_struct['ep4'] = np.random.rand(num_blocks, 3)
    initial_params_3p_struct['ep5'] = np.random.rand(num_blocks, 3)
    initial_params_3p_struct['weights'] = np.random.rand(num_blocks, 16)
    initial_params_3p_struct['partition_logits'] = (np.random.rand(num_blocks, 16) * 2) # Center around 1
    compressed_3P_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=compress_3P_kernel.reflection.g_compressedBlock3P,
        usage=spy.BufferUsage.unordered_access, data=initial_params_3p_struct.view(np.float32)
    )

    compress_params_data = np.array(
        [(args.lr, args.m, args.m / 10 if args.snap_steps == 0 else args.snap_steps, num_blocks, 0 if args.no_snap else 1)],
        dtype=params_dtype
    )
    compress_params_buffer = device.create_buffer(
        element_count=1, resource_type_layout=reflection.g_compress_step_params,
        usage=spy.BufferUsage.unordered_access, data=compress_params_data.view(np.float32)
    )

    final_loss_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=reflection.g_final_loss,
        usage=spy.BufferUsage.unordered_access
    )

    final_reconstructed_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=reflection.g_reconstructed,
        usage=spy.BufferUsage.unordered_access
    )

    final_diagnostics_buffer = device.create_buffer(
        element_count=num_blocks, resource_type_layout=reflection.g_diagnostics,
        usage=spy.BufferUsage.unordered_access
    )

    lut_ideal_buffer, lut_seed_buffer = astc_lut.create_gpu_buffers(
        reflection.g_lut_ideal_to_seed, reflection.g_lut_seed_to_mask
    )

    dispatch_vars = {
        "g_groundtruth": groundtruth_buffer,
        "g_compressedBlock": compressed_buffer,
        "g_compressedBlock2P": compressed_2P_buffer,
        "g_compressedBlock3P": compressed_3P_buffer,
        "g_compress_step_params": compress_params_buffer,
        "g_final_loss": final_loss_buffer,
        "g_reconstructed": final_reconstructed_buffer,
        'g_diagnostics': final_diagnostics_buffer,
        "g_lut_ideal_to_seed": lut_ideal_buffer,
        "g_lut_seed_to_mask": lut_seed_buffer,
        "g_lut": {"lut2": astc_lut.lut_seed_to_mask_np, "lut3": astc_lut.lut3},
    }

    grid = (num_blocks, 1, 1)
    kernel_to_run = compress_2P_kernel if args.use_2p else compress_kernel
    if args.use_3p:
        kernel_to_run = compress_3P_kernel

    print(f"\n--- Starting {2 if args.use_2p else (3 if args.use_3p else 1)}-Partition Compression ---")
    print(f"Running gradient descent for {args.m} steps")
    wall_start = time.time()
    kernel_to_run.dispatch(grid, vars=dispatch_vars)
    diagnostics = final_diagnostics_buffer.to_numpy().view(diagnostics_dtype)
    wall_end = time.time()
    loss_log = diagnostics['loss_log']
    timestamps = diagnostics['timestamps']
    thread_timestamps = (timestamps - diagnostics['start_clock']).T / 100000
    print(f"\nOptimization finished in {(diagnostics['finished_clock'].max() - diagnostics['start_clock'].min()) / 100000:.2f} ms over {num_blocks} threads")
    print(f"  Wall clock: {wall_end - wall_start}")
    for i, loss in enumerate(loss_log.mean(0)):
        print(f"Step {i * (args.m // 20)}: loss = {loss:.4f} ({thread_timestamps[i].mean():0.2f} ms/thread mean, {thread_timestamps[i].min():0.2f} ms / {thread_timestamps[i].max():0.2f} ms)")
        if args.use_2p or args.use_3p:
            print(f"  Partition hamming error at step {i}: {diagnostics['partition_hamming_error_log'].sum(0)[i]}")
            print(f"  Mask: {diagnostics['ideal_partition_log'][0][i]:032b}")
            histogram = [0,0,0,0]
            for j in range(len(diagnostics['ideal_partition_log'])):
                partitions = diagnostics['ideal_partition_log'][j][i]
                seenp = set()
                for k in range(16):
                    if args.use_3p:
                        seenp.add((partitions >> (k * 2)) & 3)
                    else:
                        seenp.add((partitions >> k) & 1)
                histogram[len(seenp) - 1] += 1
            print(f"  Histogram of partitions used: {histogram}")
    finished = diagnostics['finished_clock']
    optim_ended = diagnostics['optim_ended_clock']
    print(f" + diagnostics overhead per thread: {(finished - optim_ended).mean() / 100000:.5f} ms / {(finished - optim_ended).min() / 100000:.5f} ms / {(finished - optim_ended).max() / 100000:.5f} ms")
    if args.use_2p or args.use_3p:
        print(f"Partition hamming error: {diagnostics['partition_hamming_error'].mean()}")
        astc_seeds = compressed_2P_buffer.to_numpy().view(comp_block_dtype_2P)['astc_seed']
    final_loss = final_loss_buffer.to_numpy().view(np.float32).mean()
    print(f"Final Mean L^2 Loss per block: {final_loss:.4f}")

    # for i in range(len(diagnostics['ideal_partition_log'])):
    #     print(i, diagnostics['ideal_partition_log'][i][19])

    reconstructed_data = final_reconstructed_buffer.to_numpy().view(texture_block_dtype)['pixels']
    untile_and_save_image(reconstructed_data, orig_dims, padded_dims, args.output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Differentiable ASTC/BCn-style Texture Compressor")
    parser.add_argument("input", type=str, help="Path to the input image file.")
    parser.add_argument("-o", "--output", type=str, default="reconstructed.png", help="Path to save the reconstructed output image.")
    parser.add_argument("--use_2p", action="store_true", help="Use the 2-partition compressor instead of the default 1-partition.")
    parser.add_argument("--use_3p", action="store_true", help="Use the 3-partition compressor instead of the default 1-partition.")
    parser.add_argument("--lr", type=float, default=0.1, help="Learning rate for gradient descent.")
    parser.add_argument("--m", type=int, default=100, help="Number of gradient descent steps per dispatch.")
    parser.add_argument("--snap_steps", type=int, default=0, help="Frequency of snapping partitions to valid ASTC maps (for 2P mode).")
    parser.add_argument("--no_snap", action="store_true", help="Don't snap to astc valid patterns")


    args = parser.parse_args()
    main(args)