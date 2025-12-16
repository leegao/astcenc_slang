# astcenc_slang
ASTC Encoder in Slang

Now converges in ~20-40 steps for 2-partition

Caveat for 3-partition and above. The current approach is a coordinate descent to:

1. Use gradient descent on the color eps (this can be replaced by an exact PCA or lsq solver)
2. Choose the optimal partition based on distance to each color line
3. Project the ground truth pixels onto the color line to solve for the weights
4. For the last N steps, snap the ideal partition onto the set of valid ASTC partition patterns (1024)

## cat.jpg

**Original**:

![cat.jpg](cat.jpg)

**Single Partition**:

![reconstructed_1p.png](reconstructed_1p.png)

```
--- Starting 1-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 87.67 ms over 129600 threads
  Wall clock: 1.7885725498199463
Step 0: loss = 0.2535 (184467396935921.88 ms/thread mean, 184467396935878.00 ms / 184467396935964.69 ms)
Step 4: loss = 0.1281 (0.11 ms/thread mean, 0.07 ms / 0.21 ms)
Step 8: loss = 0.0074 (0.22 ms/thread mean, 0.16 ms / 0.66 ms)
Step 12: loss = 0.0067 (0.33 ms/thread mean, 0.24 ms / 0.97 ms)
Step 16: loss = 0.0068 (0.43 ms/thread mean, 0.33 ms / 1.06 ms)
Step 20: loss = 0.0069 (0.52 ms/thread mean, 0.41 ms / 1.16 ms)
Step 24: loss = 0.0070 (0.62 ms/thread mean, 0.50 ms / 1.26 ms)
Step 28: loss = 0.0071 (0.72 ms/thread mean, 0.58 ms / 1.35 ms)
Step 32: loss = 0.0071 (0.82 ms/thread mean, 0.66 ms / 1.45 ms)
Step 36: loss = 0.0071 (0.91 ms/thread mean, 0.75 ms / 1.57 ms)
Step 40: loss = 0.0071 (1.01 ms/thread mean, 0.83 ms / 1.84 ms)
 + diagnostics overhead per thread: 0.09133 ms / 0.06240 ms / 0.17732 ms
Final Mean L^2 Unquantized Loss per block: 0.0072
Final Mean L^2 Loss per block: 0.0074
Mean color mode quantization bits: 7.58 bits / [0 .. 208] range
Mean weight quantization bits: 3.72 bits / [0 .. 13] range
Mean predicted vs best color quantization method error: 0.419 bits
Color mode quantization histogram: [(31, 2059), (63, 9469), (95, 13195), (191, 24233), (255, 80644)]
```

**Dual Partition**:

![reconstructed_2p.png](reconstructed_2p.png)

~2x time, 4x better quality (need to include 2p LUT as well)

```
--- Starting 2-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 96.36 ms over 129600 threads
  Wall clock: 1.861638069152832
Step 0: loss = 0.2380 (184467396931743.16 ms/thread mean, 184467396931695.12 ms / 184467396931790.28 ms)
  Partition hamming error at step 0: 0
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [0, 0, 0, 0]
Step 4: loss = 0.0704 (0.08 ms/thread mean, 0.04 ms / 0.34 ms)
  Partition hamming error at step 1: 109567
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 8: loss = 0.0045 (0.20 ms/thread mean, 0.14 ms / 0.78 ms)
  Partition hamming error at step 2: 121212
  Mask: 00000101010101000100000000000101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 12: loss = 0.0026 (0.31 ms/thread mean, 0.24 ms / 0.95 ms)
  Partition hamming error at step 3: 121024
  Mask: 00000101010101000100000000000101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 16: loss = 0.0021 (0.42 ms/thread mean, 0.33 ms / 1.10 ms)
  Partition hamming error at step 4: 120891
  Mask: 00000101010101000100000000000101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 20: loss = 0.0020 (0.53 ms/thread mean, 0.43 ms / 1.26 ms)
  Partition hamming error at step 5: 120880
  Mask: 00000101010101000100000000000101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 24: loss = 0.0038 (0.65 ms/thread mean, 0.53 ms / 1.40 ms)
  Partition hamming error at step 6: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 28: loss = 0.0027 (0.77 ms/thread mean, 0.64 ms / 1.53 ms)
  Partition hamming error at step 7: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 32: loss = 0.0024 (0.89 ms/thread mean, 0.75 ms / 1.66 ms)
  Partition hamming error at step 8: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 36: loss = 0.0023 (1.00 ms/thread mean, 0.86 ms / 1.78 ms)
  Partition hamming error at step 9: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 40: loss = 0.0023 (1.11 ms/thread mean, 0.97 ms / 1.89 ms)
  Partition hamming error at step 10: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
 + diagnostics overhead per thread: 0.10643 ms / 0.04544 ms / 0.27428 ms
Partition hamming error: 0.9026157407407407
Final Mean L^2 Unquantized Loss per block: 0.0023
Final Mean L^2 Loss per block: 0.0058
Mean color mode quantization bits: 5.76 bits / [0 .. 62] range
Mean weight quantization bits: 1.02 bits / [0 .. 2] range
Mean predicted vs best color quantization method error: 0.65 bits
Color mode quantization histogram: [(5, 26), (9, 768), (11, 1733), (15, 4740), (23, 9667), (31, 14677), (39, 15206), (63, 35224), (95, 47559)]
```

**3 Partitions**:

![reconstructed_3p.png](reconstructed_3p.png)

~ similar time and final quality as 2p

```
--- Starting 3-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 96.21 ms over 129600 threads
  Wall clock: 1.8566687107086182
Step 0: loss = 0.2342 (184467396927081.47 ms/thread mean, 184467396927033.84 ms / 184467396927128.81 ms)
  Partition hamming error at step 0: 0
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [0, 0, 0, 0]
Step 4: loss = 0.0537 (0.07 ms/thread mean, 0.04 ms / 0.34 ms)
  Partition hamming error at step 1: 289751
  Mask: 10100000000000100010101010101010
  Histogram of partitions used: [0, 29035, 100565, 0]
Step 8: loss = 0.0039 (0.19 ms/thread mean, 0.14 ms / 0.78 ms)
  Partition hamming error at step 2: 292112
  Mask: 01010000000000010001010101011010
  Histogram of partitions used: [0, 27752, 101848, 0]
Step 12: loss = 0.0017 (0.31 ms/thread mean, 0.24 ms / 0.92 ms)
  Partition hamming error at step 3: 291557
  Mask: 01010000000000010001010101011010
  Histogram of partitions used: [0, 27802, 101798, 0]
Step 16: loss = 0.0013 (0.42 ms/thread mean, 0.34 ms / 1.03 ms)
  Partition hamming error at step 4: 291590
  Mask: 01010000000000010001010101011010
  Histogram of partitions used: [0, 27785, 101815, 0]
Step 20: loss = 0.0012 (0.53 ms/thread mean, 0.43 ms / 1.14 ms)
  Partition hamming error at step 5: 291608
  Mask: 01010000000000010001010101011010
  Histogram of partitions used: [0, 27785, 101815, 0]
Step 24: loss = 0.0059 (0.65 ms/thread mean, 0.54 ms / 1.25 ms)
  Partition hamming error at step 6: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 51093, 78507, 0]
Step 28: loss = 0.0030 (0.77 ms/thread mean, 0.65 ms / 1.38 ms)
  Partition hamming error at step 7: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 51740, 77860, 0]
Step 32: loss = 0.0023 (0.89 ms/thread mean, 0.77 ms / 1.56 ms)
  Partition hamming error at step 8: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 51774, 77826, 0]
Step 36: loss = 0.0021 (1.01 ms/thread mean, 0.88 ms / 1.74 ms)
  Partition hamming error at step 9: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 51802, 77798, 0]
Step 40: loss = 0.0020 (1.14 ms/thread mean, 1.00 ms / 1.92 ms)
  Partition hamming error at step 10: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 51796, 77804, 0]
 + diagnostics overhead per thread: 0.07651 ms / 0.03424 ms / 0.13744 ms
Partition hamming error: 2.0084104938271605
Final Mean L^2 Unquantized Loss per block: 0.0020
Final Mean L^2 Loss per block: 0.0166
Mean color mode quantization bits: 4.14 bits / [0 .. 18] range
Mean weight quantization bits: 0.57 bits / [0 .. 1] range
Mean predicted vs best color quantization method error: 0.332 bits
Color mode quantization histogram: [(5, 590), (7, 3073), (9, 8666), (11, 12288), (15, 28341), (23, 76642)]
```

**Ensemble**:

![reconstructed_ensemble.png](reconstructed_ensemble.png)


```
--- Starting 3-Partition Compression ---
Running gradient descent for 40 steps
/home/leegao/meh/astcenc_slang/astc_encoder.py:219: RuntimeWarning: overflow encountered in scalar subtract
  print(f"\nOptimization finished in {(diagnostics['finished_clock'].max() - diagnostics['start_clock'].min()) / 100000:.2f} ms over {num_blocks} threads")

Optimization finished in 184467440736488.97 ms over 129600 threads
  Wall clock: 2.08868408203125
Step 0: loss = 0.1916 (184467396918652.34 ms/thread mean, 184467396917717.59 ms / 184467396921843.06 ms)
  Ensemble 1P: 0.2535, 2P: 0.2380, 3P: 0.2342, Best: 0.1916
Step 4: loss = 0.0061 (184467440733169.44 ms/thread mean, 184467440732078.16 ms / 184467440736234.94 ms)
  Ensemble 1P: 0.0066, 2P: 0.0704, 3P: 0.0537, Best: 0.0061
Step 8: loss = 0.0023 (184467440733169.59 ms/thread mean, 184467440732078.41 ms / 184467440736235.41 ms)
  Ensemble 1P: 0.0066, 2P: 0.0045, 3P: 0.0039, Best: 0.0023
Step 12: loss = 0.0014 (184467440733169.72 ms/thread mean, 184467440732078.56 ms / 184467440736235.81 ms)
  Ensemble 1P: 0.0066, 2P: 0.0026, 3P: 0.0017, Best: 0.0014
Step 16: loss = 0.0012 (184467440733169.84 ms/thread mean, 184467440732078.69 ms / 184467440736236.25 ms)
  Ensemble 1P: 0.0066, 2P: 0.0021, 3P: 0.0013, Best: 0.0012
Step 20: loss = 0.0011 (184467440733170.00 ms/thread mean, 184467440732078.81 ms / 184467440736236.66 ms)
  Ensemble 1P: 0.0066, 2P: 0.0020, 3P: 0.0012, Best: 0.0011
Step 24: loss = 0.0023 (184467440733170.16 ms/thread mean, 184467440732078.97 ms / 184467440736237.00 ms)
  Ensemble 1P: 0.0066, 2P: 0.0038, 3P: 0.0059, Best: 0.0023
Step 28: loss = 0.0018 (184467440733170.28 ms/thread mean, 184467440732079.09 ms / 184467440736237.31 ms)
  Ensemble 1P: 0.0066, 2P: 0.0027, 3P: 0.0030, Best: 0.0018
Step 32: loss = 0.0017 (184467440733170.47 ms/thread mean, 184467440732079.28 ms / 184467440736237.62 ms)
  Ensemble 1P: 0.0066, 2P: 0.0024, 3P: 0.0023, Best: 0.0017
Step 36: loss = 0.0016 (184467440733170.59 ms/thread mean, 184467440732079.41 ms / 184467440736237.94 ms)
  Ensemble 1P: 0.0066, 2P: 0.0023, 3P: 0.0021, Best: 0.0016
Step 40: loss = 0.0016 (184467440733170.78 ms/thread mean, 184467440732079.56 ms / 184467440736238.25 ms)
  Ensemble 1P: 0.0066, 2P: 0.0023, 3P: 0.0020, Best: 0.0016
 + diagnostics overhead per thread: 0.52579 ms / 0.23508 ms / 2.29926 ms
Partition hamming error: 0.1963503086419753
Final Mean L^2 Unquantized Loss per block: 0.0030
  Ensemble 1P: 0.0066, 2P: 0.0023, 3P: 0.0020, Best: 0.0016
Final Mean L^2 Loss per block: 0.0040
Mean color mode quantization bits: 7.11 bits / [0 .. 168] range
Mean weight quantization bits: 3.14 bits / [0 .. 10] range
Mean predicted vs best color quantization method error: 0.5 bits
Color mode quantization histogram: [(5, 8), (9, 221), (11, 512), (15, 1327), (23, 2558), (31, 4265), (39, 3174), (63, 16293), (95, 22314), (191, 26873), (255, 52055)]

```

## test_rgb_hard.png

**Original**:

![test_rgb_hard_1_6x.png](test_rgb_hard_1_6x.png)

**Single Partition**:

![reconstructed_test_1p_6x.png](reconstructed_test_1p_6x.png)

```
--- Starting 1-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 1.65 ms over 1024 threads
  Wall clock: 1.300274133682251
Step 0: loss = 6.6676 (184467396684691.56 ms/thread mean, 184467396684691.62 ms / 184467396684691.62 ms)
Step 4: loss = 2.3683 (0.15 ms/thread mean, 0.15 ms / 0.15 ms)
Step 8: loss = 0.4289 (0.55 ms/thread mean, 0.54 ms / 0.55 ms)
Step 12: loss = 0.4161 (0.91 ms/thread mean, 0.91 ms / 0.91 ms)
Step 16: loss = 0.4171 (1.00 ms/thread mean, 1.00 ms / 1.00 ms)
Step 20: loss = 0.4178 (1.08 ms/thread mean, 1.08 ms / 1.09 ms)
Step 24: loss = 0.4172 (1.17 ms/thread mean, 1.17 ms / 1.17 ms)
Step 28: loss = 0.4171 (1.25 ms/thread mean, 1.25 ms / 1.26 ms)
Step 32: loss = 0.4173 (1.34 ms/thread mean, 1.33 ms / 1.34 ms)
Step 36: loss = 0.4174 (1.42 ms/thread mean, 1.42 ms / 1.43 ms)
Step 40: loss = 0.4173 (1.51 ms/thread mean, 1.50 ms / 1.52 ms)
 + diagnostics overhead per thread: 0.05544 ms / 0.05032 ms / 0.05776 ms
Final Mean L^2 Unquantized Loss per block: 0.4183
Final Mean L^2 Loss per block: 0.4181
Mean color mode quantization bits: 6.3 bits / [0 .. 115] range
Mean weight quantization bits: 4.34 bits / [0 .. 21] range
Mean predicted vs best color quantization method error: 1.7 bits
Color mode quantization histogram: [(31, 427), (63, 142), (95, 75), (191, 115), (255, 265)]
```

**Dual Partition**:

![reconstructed_test_2p_6x.png](reconstructed_test_2p_6x.png)

~2x time, 13x better quality

```
--- Starting 2-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 1.67 ms over 1024 threads
  Wall clock: 1.3104891777038574
Step 0: loss = 7.0586 (184467396682444.47 ms/thread mean, 184467396682444.47 ms / 184467396682444.47 ms)
  Partition hamming error at step 0: 0
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [0, 0, 0, 0]
Step 4: loss = 1.4279 (0.24 ms/thread mean, 0.24 ms / 0.24 ms)
  Partition hamming error at step 1: 525
  Mask: 01010101010001010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 8: loss = 0.0850 (0.69 ms/thread mean, 0.68 ms / 0.69 ms)
  Partition hamming error at step 2: 664
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 12: loss = 0.0150 (0.79 ms/thread mean, 0.78 ms / 0.80 ms)
  Partition hamming error at step 3: 665
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 16: loss = 0.0052 (0.90 ms/thread mean, 0.87 ms / 0.90 ms)
  Partition hamming error at step 4: 672
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 20: loss = 0.0039 (1.00 ms/thread mean, 0.96 ms / 1.01 ms)
  Partition hamming error at step 5: 673
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 24: loss = 0.1540 (1.10 ms/thread mean, 1.06 ms / 1.11 ms)
  Partition hamming error at step 6: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 28: loss = 0.0581 (1.21 ms/thread mean, 1.16 ms / 1.22 ms)
  Partition hamming error at step 7: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 32: loss = 0.0241 (1.31 ms/thread mean, 1.27 ms / 1.33 ms)
  Partition hamming error at step 8: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 36: loss = 0.0151 (1.42 ms/thread mean, 1.37 ms / 1.43 ms)
  Partition hamming error at step 9: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 40: loss = 0.0139 (1.52 ms/thread mean, 1.48 ms / 1.54 ms)
  Partition hamming error at step 10: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
 + diagnostics overhead per thread: 0.05996 ms / 0.05028 ms / 0.08340 ms
Partition hamming error: 0.7275390625
Final Mean L^2 Unquantized Loss per block: 0.0133
Final Mean L^2 Loss per block: 0.0161
Mean color mode quantization bits: 3.77 bits / [0 .. 23] range
Mean weight quantization bits: 2.78 bits / [0 .. 8] range
Mean predicted vs best color quantization method error: 2.24 bits
Color mode quantization histogram: [(5, 493), (9, 32), (11, 37), (15, 51), (23, 29), (31, 67), (39, 112), (63, 174), (95, 29)]
```

**3 Partitions, no-snapping, just partition pattern**:

![reconstructed_test_3p_6x.png](reconstructed_test_3p_6x.png)

~ similar time, 2x better unquantized quality, ~ similar quantized quality due to much lower bit budget

Note that due to the much lower color quantization budget, you can start to see the quantization artifacts in the image (which isn't well captured by the MSE loss values)

```
--- Starting 3-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 1.90 ms over 1024 threads
  Wall clock: 1.3403432369232178
Step 0: loss = 7.1071 (184467396680169.47 ms/thread mean, 184467396680169.44 ms / 184467396680169.44 ms)
  Partition hamming error at step 0: 0
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [0, 0, 0, 0]
Step 4: loss = 0.6644 (0.24 ms/thread mean, 0.22 ms / 0.25 ms)
  Partition hamming error at step 1: 1515
  Mask: 10100010101000000101011001100101
  Histogram of partitions used: [0, 584, 440, 0]
Step 8: loss = 0.0536 (0.71 ms/thread mean, 0.66 ms / 0.74 ms)
  Partition hamming error at step 2: 1518
  Mask: 10100010011000001001011010100110
  Histogram of partitions used: [0, 584, 440, 0]
Step 12: loss = 0.0110 (0.92 ms/thread mean, 0.90 ms / 0.93 ms)
  Partition hamming error at step 3: 1513
  Mask: 10100010011000000101011010100110
  Histogram of partitions used: [0, 585, 439, 0]
Step 16: loss = 0.0038 (1.02 ms/thread mean, 0.99 ms / 1.04 ms)
  Partition hamming error at step 4: 1530
  Mask: 10100010011000000101011010100110
  Histogram of partitions used: [0, 587, 437, 0]
Step 20: loss = 0.0024 (1.12 ms/thread mean, 1.08 ms / 1.14 ms)
  Partition hamming error at step 5: 1540
  Mask: 10100010011000000101011010100110
  Histogram of partitions used: [0, 587, 437, 0]
Step 24: loss = 0.2472 (1.22 ms/thread mean, 1.18 ms / 1.25 ms)
  Partition hamming error at step 6: 0
  Mask: 10100110101001101010001010100010
  Histogram of partitions used: [0, 748, 276, 0]
Step 28: loss = 0.0512 (1.33 ms/thread mean, 1.29 ms / 1.36 ms)
  Partition hamming error at step 7: 0
  Mask: 10100110101001101010001010100010
  Histogram of partitions used: [0, 750, 274, 0]
Step 32: loss = 0.0228 (1.44 ms/thread mean, 1.40 ms / 1.48 ms)
  Partition hamming error at step 8: 0
  Mask: 10100110101001101010001010100010
  Histogram of partitions used: [0, 759, 265, 0]
Step 36: loss = 0.0188 (1.57 ms/thread mean, 1.52 ms / 1.61 ms)
  Partition hamming error at step 9: 0
  Mask: 10100110101001101010001010100010
  Histogram of partitions used: [0, 758, 266, 0]
Step 40: loss = 0.0181 (1.70 ms/thread mean, 1.65 ms / 1.74 ms)
  Partition hamming error at step 10: 0
  Mask: 10100110101001101010001010100010
  Histogram of partitions used: [0, 761, 263, 0]
 + diagnostics overhead per thread: 0.06114 ms / 0.04676 ms / 0.08140 ms
Partition hamming error: 1.25
Final Mean L^2 Unquantized Loss per block: 0.0184
Final Mean L^2 Loss per block: 0.0277
Mean color mode quantization bits: 3.13 bits / [0 .. 10] range
Mean weight quantization bits: 1.84 bits / [0 .. 4] range
Mean predicted vs best color quantization method error: 0.778 bits
Color mode quantization histogram: [(5, 525), (7, 50), (9, 52), (11, 35), (15, 131), (23, 231)]
```


**Ensemble**:

![reconstructed_test_ensemble_6x.png](reconstructed_test_ensemble_6x.png)

```
--- Starting 3-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 35835.76 ms over 1024 threads
  Wall clock: 1.3898646831512451
Step 0: loss = 5.8467 (184467396705884.28 ms/thread mean, 184467396702872.88 ms / 184467396713680.72 ms)
  Ensemble 1P: 6.6676, 2P: 7.0586, 3P: 7.1071, Best: 5.8467
Step 4: loss = 0.2506 (28037.98 ms/thread mean, 25026.58 ms / 35834.43 ms)
  Ensemble 1P: 0.4173, 2P: 1.4279, 3P: 0.6644, Best: 0.2506
Step 8: loss = 0.0296 (28038.09 ms/thread mean, 25026.68 ms / 35834.54 ms)
  Ensemble 1P: 0.4173, 2P: 0.0850, 3P: 0.0536, Best: 0.0296
Step 12: loss = 0.0064 (28038.18 ms/thread mean, 25026.78 ms / 35834.64 ms)
  Ensemble 1P: 0.4173, 2P: 0.0150, 3P: 0.0110, Best: 0.0064
Step 16: loss = 0.0024 (28038.28 ms/thread mean, 25026.88 ms / 35834.74 ms)
  Ensemble 1P: 0.4173, 2P: 0.0052, 3P: 0.0038, Best: 0.0024
Step 20: loss = 0.0018 (28038.38 ms/thread mean, 25026.98 ms / 35834.85 ms)
  Ensemble 1P: 0.4173, 2P: 0.0039, 3P: 0.0024, Best: 0.0018
Step 24: loss = 0.0279 (28038.47 ms/thread mean, 25027.08 ms / 35834.95 ms)
  Ensemble 1P: 0.4173, 2P: 0.1540, 3P: 0.2472, Best: 0.0279
Step 28: loss = 0.0135 (28038.58 ms/thread mean, 25027.19 ms / 35835.05 ms)
  Ensemble 1P: 0.4173, 2P: 0.0581, 3P: 0.0512, Best: 0.0135
Step 32: loss = 0.0099 (28038.68 ms/thread mean, 25027.29 ms / 35835.15 ms)
  Ensemble 1P: 0.4173, 2P: 0.0241, 3P: 0.0228, Best: 0.0099
Step 36: loss = 0.0088 (28038.78 ms/thread mean, 25027.39 ms / 35835.25 ms)
  Ensemble 1P: 0.4173, 2P: 0.0151, 3P: 0.0188, Best: 0.0088
Step 40: loss = 0.0084 (28038.88 ms/thread mean, 25027.49 ms / 35835.36 ms)
  Ensemble 1P: 0.4173, 2P: 0.0139, 3P: 0.0181, Best: 0.0084
 + diagnostics overhead per thread: 0.33534 ms / 0.30816 ms / 0.37932 ms
Partition hamming error: 0.3603515625
Final Mean L^2 Unquantized Loss per block: 0.0136
  Ensemble 1P: 0.4173, 2P: 0.0133, 3P: 0.0184, Best: 0.0083
Final Mean L^2 Loss per block: 0.0150
Mean color mode quantization bits: 4.85 bits / [0 .. 56] range
Mean weight quantization bits: 3.5 bits / [0 .. 15] range
Mean predicted vs best color quantization method error: 2.07 bits
Color mode quantization histogram: [(5, 248), (9, 21), (11, 16), (15, 24), (23, 14), (31, 295), (39, 66), (63, 160), (95, 53), (191, 53), (255, 74)]
```

## Ideas:

1. [Done] Full soft decoder with autodiff (done - slow convergence)
2. [Done] Coordinate descent with gradient descent on partition logits (done - poor stability)
3. [Done] Coordinate descent with gradient descent on the color eps (done - good results, ~but trapped in local minimums~)
4. [Done] Extend to 3P and 4P depending on # of distinct colors, using a combinatorial search of partition seeds (done, viable for 3P)
5. [Deprioritized] ~Use RANSAC to select partitions, using the inlier count as a statistic to uncover # of distinct color lines~
    * Turns out partition selection isn't the problem, it's astc snapping, and jointly modeling the optimization with that in mind
      is very hard without resorting to combinatorial search
7. [Done] ~Use PCA to replace the soft differentiable part~ (trapped in local minimums, also due to coordinate descent, takes ~ same # of steps to converge as gradient descent...)
9. [Done] Apply quantization (this is less destructive to the MSE than I expected...)
10. [Done] Apply permutations to available astc patterns to expand the search space (for 3P and 2P)
11. [Done] Use a LUT for 3P as well (~80MB~ 12.2MB using permutation symmetry, plus we have the nice property that $T[\sigma(x)] = \mathbf{argmin}_{s}(\min(dist(\sigma_i(x), p_s))$ is also permutationally invariant, meaning we can quickly explore the full symmetry space during snapping)
12. [Done] Apply the no-1P regularizer to 2P and 3P
13. [Done] Create the symmetric LUT for 2P as well (includes scripts to regenerate these)
14. Add PSNR metric as well
8. [Done] Do an ensemble of 1P, 2P, and 3P
6. Actually implement the bise encoding and the astc block format
15. Look into other astc modes (e.g. scaling, blue contract, etc) to expand the search space
16. [Done] Look into whether the fast astc quantization method estimator is useful (general gap of between 0.3 to 1 bits for the color ep, which corresponds to between 20% to 50% error on the potential color range, it's not bad, but not optimal like a full search)
    * That said, if you have a block without a lot of smoother color/weight variation (e.g. the hard test png), then the quantization estimator will do poorly since it assumes that you have ~ uniform distribution of quantization errors. E.g. for the hard test which is just a solid block of alternating colors, the estimate can get up to 3-4 bits wrong, which is like misusing 8-16x the amount of bits necessary.