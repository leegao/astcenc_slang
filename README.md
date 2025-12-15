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

Optimization finished in 95.15 ms over 129600 threads
  Wall clock: 1.0340008735656738
Step 0: loss = 0.0641 (0.10 ms/thread mean, 0.05 ms / 0.22 ms)
Step 2: loss = 0.0094 (0.18 ms/thread mean, 0.10 ms / 0.45 ms)
Step 4: loss = 0.0074 (0.24 ms/thread mean, 0.16 ms / 0.69 ms)
Step 6: loss = 0.0068 (0.30 ms/thread mean, 0.21 ms / 0.91 ms)
Step 8: loss = 0.0066 (0.36 ms/thread mean, 0.26 ms / 1.13 ms)
Step 10: loss = 0.0067 (0.42 ms/thread mean, 0.30 ms / 1.20 ms)
Step 12: loss = 0.0067 (0.47 ms/thread mean, 0.35 ms / 1.27 ms)
Step 14: loss = 0.0068 (0.53 ms/thread mean, 0.39 ms / 1.33 ms)
Step 16: loss = 0.0069 (0.58 ms/thread mean, 0.44 ms / 1.39 ms)
Step 18: loss = 0.0070 (0.64 ms/thread mean, 0.48 ms / 1.45 ms)
Step 20: loss = 0.0070 (0.69 ms/thread mean, 0.53 ms / 1.51 ms)
Step 22: loss = 0.0070 (0.75 ms/thread mean, 0.57 ms / 1.57 ms)
Step 24: loss = 0.0071 (0.80 ms/thread mean, 0.62 ms / 1.63 ms)
Step 26: loss = 0.0071 (0.86 ms/thread mean, 0.66 ms / 1.68 ms)
Step 28: loss = 0.0071 (0.91 ms/thread mean, 0.71 ms / 1.73 ms)
Step 30: loss = 0.0071 (0.96 ms/thread mean, 0.75 ms / 1.82 ms)
Step 32: loss = 0.0071 (1.02 ms/thread mean, 0.80 ms / 1.91 ms)
Step 34: loss = 0.0071 (1.07 ms/thread mean, 0.84 ms / 2.01 ms)
Step 36: loss = 0.0071 (1.12 ms/thread mean, 0.89 ms / 2.10 ms)
Step 38: loss = 0.0071 (1.18 ms/thread mean, 0.93 ms / 2.20 ms)
 + diagnostics overhead per thread: 0.09019 ms / 0.03048 ms / 0.12296 ms
Final Mean L^2 Unquantized Loss per block: 0.0071
Final Mean L^2 Loss per block: 0.0073
Mean predicted vs best color quantization method error: 0.375 bits
```

**Dual Partition**:

![reconstructed_2p.png](reconstructed_2p.png)

~2x time, 4x better quality (need to include 2p LUT as well)

```
--- Starting 2-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 102.98 ms over 129600 threads
  Wall clock: 1.0639865398406982
Step 0: loss = 0.0415 (0.07 ms/thread mean, 0.04 ms / 0.24 ms)
  Partition hamming error at step 0: 127225
  Mask: 01010000000000010001010101010000
  Histogram of partitions used: [0, 129600, 0, 0]
Step 2: loss = 0.0078 (0.14 ms/thread mean, 0.09 ms / 0.50 ms)
  Partition hamming error at step 1: 129589
  Mask: 01010000000000010001010101010000
  Histogram of partitions used: [0, 129600, 0, 0]
Step 4: loss = 0.0041 (0.20 ms/thread mean, 0.14 ms / 0.76 ms)
  Partition hamming error at step 2: 128705
  Mask: 01010000000000010001010101010000
  Histogram of partitions used: [0, 129600, 0, 0]
Step 6: loss = 0.0029 (0.26 ms/thread mean, 0.19 ms / 1.01 ms)
  Partition hamming error at step 3: 128116
  Mask: 01010000000000010001010101010000
  Histogram of partitions used: [0, 129600, 0, 0]
Step 8: loss = 0.0024 (0.33 ms/thread mean, 0.24 ms / 1.26 ms)
  Partition hamming error at step 4: 128051
  Mask: 01010000000000010001010101010000
  Histogram of partitions used: [0, 129600, 0, 0]
Step 10: loss = 0.0021 (0.39 ms/thread mean, 0.29 ms / 1.40 ms)
  Partition hamming error at step 5: 127899
  Mask: 01010000000000010001010101010000
  Histogram of partitions used: [0, 129600, 0, 0]
Step 12: loss = 0.0020 (0.45 ms/thread mean, 0.34 ms / 1.45 ms)
  Partition hamming error at step 6: 127890
  Mask: 01010000000000010001010101010000
  Histogram of partitions used: [0, 129600, 0, 0]
Step 14: loss = 0.0020 (0.51 ms/thread mean, 0.39 ms / 1.51 ms)
  Partition hamming error at step 7: 127873
  Mask: 01010000000000010001010101010000
  Histogram of partitions used: [0, 129600, 0, 0]
Step 16: loss = 0.0019 (0.58 ms/thread mean, 0.44 ms / 1.58 ms)
  Partition hamming error at step 8: 127886
  Mask: 01010000000000010001010101010000
  Histogram of partitions used: [0, 129600, 0, 0]
Step 18: loss = 0.0019 (0.64 ms/thread mean, 0.50 ms / 1.65 ms)
  Partition hamming error at step 9: 127896
  Mask: 01010000000000010001010101010000
  Histogram of partitions used: [0, 129600, 0, 0]
Step 20: loss = 0.0038 (0.70 ms/thread mean, 0.55 ms / 1.72 ms)
  Partition hamming error at step 10: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 22: loss = 0.0029 (0.76 ms/thread mean, 0.61 ms / 1.78 ms)
  Partition hamming error at step 11: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 24: loss = 0.0026 (0.83 ms/thread mean, 0.67 ms / 1.84 ms)
  Partition hamming error at step 12: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 26: loss = 0.0025 (0.89 ms/thread mean, 0.72 ms / 1.90 ms)
  Partition hamming error at step 13: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 28: loss = 0.0024 (0.95 ms/thread mean, 0.79 ms / 1.97 ms)
  Partition hamming error at step 14: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 30: loss = 0.0023 (1.02 ms/thread mean, 0.85 ms / 2.04 ms)
  Partition hamming error at step 15: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 32: loss = 0.0023 (1.08 ms/thread mean, 0.91 ms / 2.12 ms)
  Partition hamming error at step 16: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 34: loss = 0.0023 (1.14 ms/thread mean, 0.97 ms / 2.19 ms)
  Partition hamming error at step 17: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 36: loss = 0.0023 (1.21 ms/thread mean, 1.03 ms / 2.26 ms)
  Partition hamming error at step 18: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 38: loss = 0.0023 (1.27 ms/thread mean, 1.08 ms / 2.35 ms)
  Partition hamming error at step 19: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
 + diagnostics overhead per thread: 0.10477 ms / 0.04024 ms / 0.28384 ms
Partition hamming error: 0.9221990740740741
Final Mean L^2 Unquantized Loss per block: 0.0023
Final Mean L^2 Loss per block: 0.0057
Mean predicted vs best color quantization method error: 0.636 bits
```

**3 Partitions**:

![reconstructed_3p.png](reconstructed_3p.png)

~ similar time and final quality as 2p

```
--- Starting 3-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 105.39 ms over 129600 threads
  Wall clock: 1.0467612743377686
Step 0: loss = 0.0392 (0.07 ms/thread mean, 0.04 ms / 0.27 ms)
  Partition hamming error at step 0: 279897
  Mask: 01010000000000010001010101010101
  Histogram of partitions used: [0, 47428, 82172, 0]
Step 2: loss = 0.0076 (0.14 ms/thread mean, 0.10 ms / 0.54 ms)
  Partition hamming error at step 1: 290802
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [0, 41864, 87736, 0]
Step 4: loss = 0.0037 (0.20 ms/thread mean, 0.15 ms / 0.80 ms)
  Partition hamming error at step 2: 289939
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [0, 41724, 87876, 0]
Step 6: loss = 0.0023 (0.27 ms/thread mean, 0.20 ms / 1.07 ms)
  Partition hamming error at step 3: 289802
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [0, 41674, 87926, 0]
Step 8: loss = 0.0017 (0.34 ms/thread mean, 0.25 ms / 1.21 ms)
  Partition hamming error at step 4: 289684
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [0, 41688, 87912, 0]
Step 10: loss = 0.0015 (0.40 ms/thread mean, 0.31 ms / 1.27 ms)
  Partition hamming error at step 5: 289557
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [0, 41697, 87903, 0]
Step 12: loss = 0.0013 (0.46 ms/thread mean, 0.36 ms / 1.34 ms)
  Partition hamming error at step 6: 289531
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [0, 41704, 87896, 0]
Step 14: loss = 0.0013 (0.52 ms/thread mean, 0.41 ms / 1.41 ms)
  Partition hamming error at step 7: 289523
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [0, 41702, 87898, 0]
Step 16: loss = 0.0012 (0.59 ms/thread mean, 0.47 ms / 1.48 ms)
  Partition hamming error at step 8: 289532
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [0, 41700, 87900, 0]
Step 18: loss = 0.0012 (0.65 ms/thread mean, 0.52 ms / 1.54 ms)
  Partition hamming error at step 9: 289536
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [0, 41698, 87902, 0]
Step 20: loss = 0.0059 (0.72 ms/thread mean, 0.57 ms / 1.60 ms)
  Partition hamming error at step 10: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 64782, 64818, 0]
Step 22: loss = 0.0039 (0.79 ms/thread mean, 0.63 ms / 1.67 ms)
  Partition hamming error at step 11: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 64629, 64971, 0]
Step 24: loss = 0.0031 (0.85 ms/thread mean, 0.69 ms / 1.73 ms)
  Partition hamming error at step 12: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 64782, 64818, 0]
Step 26: loss = 0.0027 (0.92 ms/thread mean, 0.75 ms / 1.79 ms)
  Partition hamming error at step 13: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 64910, 64690, 0]
Step 28: loss = 0.0024 (0.99 ms/thread mean, 0.81 ms / 1.86 ms)
  Partition hamming error at step 14: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 64907, 64693, 0]
Step 30: loss = 0.0023 (1.05 ms/thread mean, 0.87 ms / 1.92 ms)
  Partition hamming error at step 15: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 64942, 64658, 0]
Step 32: loss = 0.0022 (1.12 ms/thread mean, 0.94 ms / 1.99 ms)
  Partition hamming error at step 16: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 64953, 64647, 0]
Step 34: loss = 0.0021 (1.19 ms/thread mean, 1.00 ms / 2.05 ms)
  Partition hamming error at step 17: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 64953, 64647, 0]
Step 36: loss = 0.0021 (1.26 ms/thread mean, 1.06 ms / 2.12 ms)
  Partition hamming error at step 18: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 64950, 64650, 0]
Step 38: loss = 0.0020 (1.32 ms/thread mean, 1.12 ms / 2.20 ms)
  Partition hamming error at step 19: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 64959, 64641, 0]
 + diagnostics overhead per thread: 0.08514 ms / 0.03420 ms / 0.26232 ms
Partition hamming error: 2.0238734567901235
Final Mean L^2 Unquantized Loss per block: 0.0020
Final Mean L^2 Loss per block: 0.0169
Mean predicted vs best color quantization method error: 0.337 bits
```

## test_rgb_hard.png

**Original**:

![test_rgb_hard_1_6x.png](test_rgb_hard_1_6x.png)

**Single Partition**:

![reconstructed_test_1p_6x.png](reconstructed_test_1p_6x.png)

```
--- Starting 1-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 1.48 ms over 1024 threads
  Wall clock: 0.472275972366333
Step 0: loss = 2.2754 (0.23 ms/thread mean, 0.23 ms / 0.23 ms)
Step 2: loss = 0.4709 (0.45 ms/thread mean, 0.45 ms / 0.46 ms)
Step 4: loss = 0.4292 (0.60 ms/thread mean, 0.60 ms / 0.61 ms)
Step 6: loss = 0.4183 (0.65 ms/thread mean, 0.65 ms / 0.65 ms)
Step 8: loss = 0.4148 (0.70 ms/thread mean, 0.69 ms / 0.70 ms)
Step 10: loss = 0.4143 (0.74 ms/thread mean, 0.74 ms / 0.75 ms)
Step 12: loss = 0.4148 (0.79 ms/thread mean, 0.78 ms / 0.79 ms)
Step 14: loss = 0.4154 (0.83 ms/thread mean, 0.83 ms / 0.84 ms)
Step 16: loss = 0.4159 (0.88 ms/thread mean, 0.87 ms / 0.89 ms)
Step 18: loss = 0.4162 (0.93 ms/thread mean, 0.92 ms / 0.94 ms)
Step 20: loss = 0.4166 (0.97 ms/thread mean, 0.97 ms / 0.98 ms)
Step 22: loss = 0.4169 (1.02 ms/thread mean, 1.01 ms / 1.03 ms)
Step 24: loss = 0.4171 (1.07 ms/thread mean, 1.06 ms / 1.08 ms)
Step 26: loss = 0.4172 (1.11 ms/thread mean, 1.10 ms / 1.12 ms)
Step 28: loss = 0.4172 (1.16 ms/thread mean, 1.15 ms / 1.17 ms)
Step 30: loss = 0.4173 (1.20 ms/thread mean, 1.19 ms / 1.22 ms)
Step 32: loss = 0.4173 (1.25 ms/thread mean, 1.24 ms / 1.27 ms)
Step 34: loss = 0.4172 (1.30 ms/thread mean, 1.28 ms / 1.31 ms)
Step 36: loss = 0.4172 (1.34 ms/thread mean, 1.33 ms / 1.36 ms)
Step 38: loss = 0.4172 (1.39 ms/thread mean, 1.38 ms / 1.41 ms)
 + diagnostics overhead per thread: 0.06524 ms / 0.04504 ms / 0.07876 ms
Final Mean L^2 Unquantized Loss per block: 0.4168
Final Mean L^2 Loss per block: 0.4165
Mean predicted vs best color quantization method error: 1.91 bits
Saved reconstructed image to 'reconstructed_test_1p.png'
```

**Dual Partition**:

![reconstructed_test_2p_6x.png](reconstructed_test_2p_6x.png)

~2x time, 13x better quality

```
--- Starting 2-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 1.75 ms over 1024 threads
  Wall clock: 0.40790700912475586
Step 0: loss = 1.0060 (0.27 ms/thread mean, 0.24 ms / 0.27 ms)
  Partition hamming error at step 0: 700
  Mask: 00000000010000000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 2: loss = 0.2014 (0.51 ms/thread mean, 0.48 ms / 0.53 ms)
  Partition hamming error at step 1: 749
  Mask: 00000000010001000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 4: loss = 0.0783 (0.71 ms/thread mean, 0.70 ms / 0.71 ms)
  Partition hamming error at step 2: 760
  Mask: 00010100010101000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 6: loss = 0.0337 (0.76 ms/thread mean, 0.75 ms / 0.77 ms)
  Partition hamming error at step 3: 760
  Mask: 00000100010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 8: loss = 0.0240 (0.81 ms/thread mean, 0.79 ms / 0.82 ms)
  Partition hamming error at step 4: 758
  Mask: 00000100010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 10: loss = 0.0129 (0.86 ms/thread mean, 0.84 ms / 0.88 ms)
  Partition hamming error at step 5: 761
  Mask: 00000100010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 12: loss = 0.0098 (0.92 ms/thread mean, 0.89 ms / 0.93 ms)
  Partition hamming error at step 6: 763
  Mask: 00000100010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 14: loss = 0.0080 (0.97 ms/thread mean, 0.94 ms / 0.99 ms)
  Partition hamming error at step 7: 763
  Mask: 00000100010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 16: loss = 0.0070 (1.02 ms/thread mean, 0.99 ms / 1.04 ms)
  Partition hamming error at step 8: 763
  Mask: 00000100010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 18: loss = 0.0066 (1.07 ms/thread mean, 1.04 ms / 1.10 ms)
  Partition hamming error at step 9: 765
  Mask: 00000100010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 20: loss = 0.1806 (1.13 ms/thread mean, 1.09 ms / 1.15 ms)
  Partition hamming error at step 10: 0
  Mask: 00000000010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 22: loss = 0.0949 (1.18 ms/thread mean, 1.14 ms / 1.21 ms)
  Partition hamming error at step 11: 0
  Mask: 00000000010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 24: loss = 0.0636 (1.24 ms/thread mean, 1.20 ms / 1.26 ms)
  Partition hamming error at step 12: 0
  Mask: 00000000010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 26: loss = 0.0454 (1.29 ms/thread mean, 1.25 ms / 1.32 ms)
  Partition hamming error at step 13: 0
  Mask: 00000000010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 28: loss = 0.0370 (1.34 ms/thread mean, 1.30 ms / 1.37 ms)
  Partition hamming error at step 14: 0
  Mask: 00000000010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 30: loss = 0.0331 (1.40 ms/thread mean, 1.36 ms / 1.43 ms)
  Partition hamming error at step 15: 0
  Mask: 00000000010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 32: loss = 0.0305 (1.45 ms/thread mean, 1.41 ms / 1.48 ms)
  Partition hamming error at step 16: 0
  Mask: 00000000010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 34: loss = 0.0290 (1.51 ms/thread mean, 1.47 ms / 1.54 ms)
  Partition hamming error at step 17: 0
  Mask: 00000000010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 36: loss = 0.0276 (1.56 ms/thread mean, 1.52 ms / 1.59 ms)
  Partition hamming error at step 18: 0
  Mask: 00000000010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 38: loss = 0.0269 (1.62 ms/thread mean, 1.57 ms / 1.65 ms)
  Partition hamming error at step 19: 0
  Mask: 00000000010100000101010001010101
  Histogram of partitions used: [0, 1024, 0, 0]
 + diagnostics overhead per thread: 0.07699 ms / 0.05892 ms / 0.11064 ms
Partition hamming error: 0.787109375
Final Mean L^2 Unquantized Loss per block: 0.0271
Final Mean L^2 Loss per block: 0.0299
Mean predicted vs best color quantization method error: 2.24 bits
```

**3 Partitions, no-snapping, just partition pattern**:

![reconstructed_test_3p_6x.png](reconstructed_test_3p_6x.png)

~ similar time, 2x better quality

```
--- Starting 3-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 1.81 ms over 1024 threads
  Wall clock: 0.4084346294403076
Step 0: loss = 0.6271 (0.27 ms/thread mean, 0.24 ms / 0.28 ms)
  Partition hamming error at step 0: 1571
  Mask: 10010101001001011000010110000101
  Histogram of partitions used: [0, 613, 411, 0]
Step 2: loss = 0.1514 (0.52 ms/thread mean, 0.48 ms / 0.54 ms)
  Partition hamming error at step 1: 1673
  Mask: 10010110001001011010010110000101
  Histogram of partitions used: [0, 585, 439, 0]
Step 4: loss = 0.0634 (0.74 ms/thread mean, 0.70 ms / 0.76 ms)
  Partition hamming error at step 2: 1668
  Mask: 10100110001010101000011010000101
  Histogram of partitions used: [0, 581, 443, 0]
Step 6: loss = 0.0269 (0.81 ms/thread mean, 0.79 ms / 0.82 ms)
  Partition hamming error at step 3: 1669
  Mask: 10011001001001011000010110000101
  Histogram of partitions used: [0, 585, 439, 0]
Step 8: loss = 0.0121 (0.86 ms/thread mean, 0.84 ms / 0.87 ms)
  Partition hamming error at step 4: 1687
  Mask: 10011010001001011000011010000101
  Histogram of partitions used: [0, 585, 439, 0]
Step 10: loss = 0.0057 (0.91 ms/thread mean, 0.89 ms / 0.93 ms)
  Partition hamming error at step 5: 1684
  Mask: 10011010001001011000011010000101
  Histogram of partitions used: [0, 585, 439, 0]
Step 12: loss = 0.0031 (0.97 ms/thread mean, 0.94 ms / 0.99 ms)
  Partition hamming error at step 6: 1686
  Mask: 10011010001001011000011010000101
  Histogram of partitions used: [0, 585, 439, 0]
Step 14: loss = 0.0021 (1.02 ms/thread mean, 0.99 ms / 1.04 ms)
  Partition hamming error at step 7: 1688
  Mask: 10011010001001011000011010000101
  Histogram of partitions used: [0, 584, 440, 0]
Step 16: loss = 0.0016 (1.07 ms/thread mean, 1.03 ms / 1.10 ms)
  Partition hamming error at step 8: 1687
  Mask: 10011010001001011000011010000101
  Histogram of partitions used: [0, 584, 440, 0]
Step 18: loss = 0.0014 (1.13 ms/thread mean, 1.08 ms / 1.15 ms)
  Partition hamming error at step 9: 1687
  Mask: 10011010001001011000011010000101
  Histogram of partitions used: [0, 584, 440, 0]
Step 20: loss = 0.3377 (1.18 ms/thread mean, 1.14 ms / 1.21 ms)
  Partition hamming error at step 10: 0
  Mask: 00000000000010000001100000011000
  Histogram of partitions used: [0, 765, 259, 0]
Step 22: loss = 0.0938 (1.24 ms/thread mean, 1.19 ms / 1.27 ms)
  Partition hamming error at step 11: 0
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [0, 767, 257, 0]
Step 24: loss = 0.0510 (1.29 ms/thread mean, 1.25 ms / 1.33 ms)
  Partition hamming error at step 12: 0
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [0, 769, 255, 0]
Step 26: loss = 0.0267 (1.35 ms/thread mean, 1.30 ms / 1.38 ms)
  Partition hamming error at step 13: 0
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [0, 772, 252, 0]
Step 28: loss = 0.0190 (1.41 ms/thread mean, 1.36 ms / 1.44 ms)
  Partition hamming error at step 14: 0
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [0, 774, 250, 0]
Step 30: loss = 0.0154 (1.46 ms/thread mean, 1.42 ms / 1.50 ms)
  Partition hamming error at step 15: 0
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [0, 773, 251, 0]
Step 32: loss = 0.0176 (1.52 ms/thread mean, 1.47 ms / 1.55 ms)
  Partition hamming error at step 16: 0
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [0, 770, 254, 0]
Step 34: loss = 0.0140 (1.58 ms/thread mean, 1.53 ms / 1.61 ms)
  Partition hamming error at step 17: 0
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [0, 773, 251, 0]
Step 36: loss = 0.0133 (1.63 ms/thread mean, 1.59 ms / 1.67 ms)
  Partition hamming error at step 18: 0
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [0, 773, 251, 0]
Step 38: loss = 0.0126 (1.69 ms/thread mean, 1.64 ms / 1.73 ms)
  Partition hamming error at step 19: 0
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [0, 775, 249, 0]
 + diagnostics overhead per thread: 0.05370 ms / 0.03392 ms / 0.08820 ms
Partition hamming error: 1.3671875
Final Mean L^2 Unquantized Loss per block: 0.0123
Final Mean L^2 Loss per block: 0.0219
Mean predicted vs best color quantization method error: 0.77 bits
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
8. Do an ensemble of 1P, 2P, and 3P
6. Actually implement the bise encoding and the astc block format
15. Look into other astc modes (e.g. scaling, blue contract, etc) to expand the search space
16. [Done] Look into whether the fast astc quantization method estimator is useful (general gap of between 0.3 to 1 bits for the color ep, which corresponds to between 20% to 50% error on the potential color range, it's not bad, but not optimal like a full search)
    * That said, if you have a block without a lot of smoother color/weight variation (e.g. the hard test png), then the quantization estimator will do poorly since it assumes that you have ~ uniform distribution of quantization errors. E.g. for the hard test which is just a solid block of alternating colors, the estimate can get up to 3-4 bits wrong, which is like misusing 8-16x the amount of bits necessary.