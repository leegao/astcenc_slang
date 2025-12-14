# astcenc_slang
ASTC Encoder in Slang

Now converges in ~20-40 steps for 2-partition

Caveat for 3-partition and above. The current approach is a coordinate descent to:

1. Use gradient descent on the color eps (this can be replaced by an exact PCA or lsq solver)
2. Choose the optimal partition based on distance to each color line
3. Project the ground truth pixels onto the color line to solve for the weights
4. For the last N steps, snap the ideal partition onto the set of valid ASTC partition patterns (1024)

For 2-partition, this final step works great because your hamming error rate for pixel partition mismatch is like 0.6 - 1.2 pixels per 16 pixels.

~However, this jumps to like 11-12 pixels per 16 pixels for the 3-partition problem, because the valid partition space became so much smaller than the full set of valid patterns (2^10 out of 2^16 vs 2^25.5). As a result, this technique just collapses down to doing single partition search once you perform the snap.~

~It seems like the only way forward is to do (hard) bruteforce combinatorial search of each of the ~300 unique valid partition patterns. This will be ~50x more expensive than the current approach, going from something like 20 megapixels/s down to just 0.5 megapixels/s.~

## cat.jpg

**Original**:

![cat.jpg](cat.jpg)

**Single Partition**:

![reconstructed_1p.png](reconstructed_1p.png)

```
--- Starting 1-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 48.46 ms over 129600 threads
  Wall clock: 0.6455645561218262
Step 0: loss = 0.7794 (0.03 ms/thread mean, 0.02 ms / 0.12 ms)
Step 2: loss = 0.1151 (0.06 ms/thread mean, 0.05 ms / 0.26 ms)
Step 4: loss = 0.0373 (0.10 ms/thread mean, 0.08 ms / 0.40 ms)
Step 6: loss = 0.0201 (0.13 ms/thread mean, 0.11 ms / 0.54 ms)
Step 8: loss = 0.0152 (0.16 ms/thread mean, 0.14 ms / 0.68 ms)
Step 10: loss = 0.0133 (0.20 ms/thread mean, 0.17 ms / 0.82 ms)
Step 12: loss = 0.0123 (0.23 ms/thread mean, 0.20 ms / 0.88 ms)
Step 14: loss = 0.0117 (0.26 ms/thread mean, 0.23 ms / 0.91 ms)
Step 16: loss = 0.0112 (0.29 ms/thread mean, 0.26 ms / 0.94 ms)
Step 18: loss = 0.0109 (0.33 ms/thread mean, 0.29 ms / 0.97 ms)
Step 20: loss = 0.0106 (0.36 ms/thread mean, 0.32 ms / 1.00 ms)
Step 22: loss = 0.0104 (0.39 ms/thread mean, 0.35 ms / 1.03 ms)
Step 24: loss = 0.0102 (0.42 ms/thread mean, 0.38 ms / 1.07 ms)
Step 26: loss = 0.0100 (0.45 ms/thread mean, 0.41 ms / 1.13 ms)
Step 28: loss = 0.0098 (0.48 ms/thread mean, 0.44 ms / 1.17 ms)
Step 30: loss = 0.0097 (0.52 ms/thread mean, 0.47 ms / 1.20 ms)
Step 32: loss = 0.0096 (0.55 ms/thread mean, 0.50 ms / 1.23 ms)
Step 34: loss = 0.0095 (0.58 ms/thread mean, 0.53 ms / 1.26 ms)
Step 36: loss = 0.0093 (0.61 ms/thread mean, 0.56 ms / 1.29 ms)
Step 38: loss = 0.0092 (0.64 ms/thread mean, 0.59 ms / 1.32 ms)
 + diagnostics overhead per thread: 0.00735 ms / 0.00236 ms / 0.02276 ms
Final Mean L^2 Loss per block: 0.0092
Saved reconstructed image to 'reconstructed_1p.png'
```

**Dual Partition**:

![reconstructed_2p.png](reconstructed_2p.png)

~2x time, 4x better quality (need to include 2p LUT as well)

```
--- Starting 2-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 81.48 ms over 129600 threads
  Wall clock: 0.8588998317718506
Step 0: loss = 0.0416 (0.05 ms/thread mean, 0.03 ms / 0.50 ms)
  Partition hamming error at step 0: 134663
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 2: loss = 0.0073 (0.11 ms/thread mean, 0.08 ms / 0.73 ms)
  Partition hamming error at step 1: 135634
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 4: loss = 0.0039 (0.17 ms/thread mean, 0.13 ms / 0.96 ms)
  Partition hamming error at step 2: 134356
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 6: loss = 0.0027 (0.23 ms/thread mean, 0.17 ms / 1.17 ms)
  Partition hamming error at step 3: 133757
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 8: loss = 0.0022 (0.28 ms/thread mean, 0.22 ms / 1.39 ms)
  Partition hamming error at step 4: 133514
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 10: loss = 0.0020 (0.34 ms/thread mean, 0.26 ms / 1.55 ms)
  Partition hamming error at step 5: 133355
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 12: loss = 0.0018 (0.39 ms/thread mean, 0.31 ms / 1.60 ms)
  Partition hamming error at step 6: 133330
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 14: loss = 0.0018 (0.44 ms/thread mean, 0.35 ms / 1.65 ms)
  Partition hamming error at step 7: 133328
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 16: loss = 0.0017 (0.49 ms/thread mean, 0.39 ms / 1.70 ms)
  Partition hamming error at step 8: 133362
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 18: loss = 0.0017 (0.54 ms/thread mean, 0.43 ms / 1.79 ms)
  Partition hamming error at step 9: 133342
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 20: loss = 0.0036 (0.59 ms/thread mean, 0.48 ms / 1.91 ms)
  Partition hamming error at step 10: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 22: loss = 0.0027 (0.64 ms/thread mean, 0.53 ms / 2.02 ms)
  Partition hamming error at step 11: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 24: loss = 0.0024 (0.70 ms/thread mean, 0.57 ms / 2.07 ms)
  Partition hamming error at step 12: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 26: loss = 0.0023 (0.75 ms/thread mean, 0.62 ms / 2.13 ms)
  Partition hamming error at step 13: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 28: loss = 0.0022 (0.81 ms/thread mean, 0.67 ms / 2.18 ms)
  Partition hamming error at step 14: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 30: loss = 0.0022 (0.86 ms/thread mean, 0.72 ms / 2.23 ms)
  Partition hamming error at step 15: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 32: loss = 0.0021 (0.91 ms/thread mean, 0.77 ms / 2.28 ms)
  Partition hamming error at step 16: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 34: loss = 0.0021 (0.97 ms/thread mean, 0.81 ms / 2.33 ms)
  Partition hamming error at step 17: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 36: loss = 0.0021 (1.02 ms/thread mean, 0.86 ms / 2.38 ms)
  Partition hamming error at step 18: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 38: loss = 0.0021 (1.08 ms/thread mean, 0.91 ms / 2.44 ms)
  Partition hamming error at step 19: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
 + diagnostics overhead per thread: 0.00769 ms / 0.00496 ms / 0.05812 ms
Partition hamming error: 0.7934413580246914
Final Mean L^2 Loss per block: 0.0021
```

**3 Partitions**:

![reconstructed_3p.png](reconstructed_3p.png)

~ similar time and final quality as 2p

```
--- Starting 3-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 82.60 ms over 129600 threads
  Wall clock: 0.851503849029541
Step 0: loss = 0.0329 (0.05 ms/thread mean, 0.03 ms / 0.26 ms)
  Partition hamming error at step 0: 294955
  Mask: 10100000000000100010101010100101
  Histogram of partitions used: [0, 28349, 101251, 0]
Step 2: loss = 0.0067 (0.11 ms/thread mean, 0.08 ms / 0.49 ms)
  Partition hamming error at step 1: 303168
  Mask: 10100000000000100010101010100101
  Histogram of partitions used: [0, 24998, 104602, 0]
Step 4: loss = 0.0032 (0.16 ms/thread mean, 0.13 ms / 0.71 ms)
  Partition hamming error at step 2: 303016
  Mask: 10100000000000100010101010100101
  Histogram of partitions used: [0, 24700, 104900, 0]
Step 6: loss = 0.0020 (0.22 ms/thread mean, 0.17 ms / 0.77 ms)
  Partition hamming error at step 3: 303184
  Mask: 10100000000000100010101010100101
  Histogram of partitions used: [0, 24591, 105009, 0]
Step 8: loss = 0.0015 (0.27 ms/thread mean, 0.22 ms / 0.82 ms)
  Partition hamming error at step 4: 303402
  Mask: 10100000000000100010101010100101
  Histogram of partitions used: [0, 24550, 105050, 0]
Step 10: loss = 0.0012 (0.32 ms/thread mean, 0.27 ms / 0.88 ms)
  Partition hamming error at step 5: 303530
  Mask: 10100000000000100010101010100101
  Histogram of partitions used: [0, 24517, 105083, 0]
Step 12: loss = 0.0011 (0.37 ms/thread mean, 0.31 ms / 0.93 ms)
  Partition hamming error at step 6: 303674
  Mask: 10100000000000100010101010100101
  Histogram of partitions used: [0, 24504, 105096, 0]
Step 14: loss = 0.0010 (0.42 ms/thread mean, 0.36 ms / 0.99 ms)
  Partition hamming error at step 7: 303833
  Mask: 10100000000000100010101010100101
  Histogram of partitions used: [0, 24508, 105092, 0]
Step 16: loss = 0.0010 (0.47 ms/thread mean, 0.40 ms / 1.05 ms)
  Partition hamming error at step 8: 303928
  Mask: 10100000000000100010101010100101
  Histogram of partitions used: [0, 24511, 105089, 0]
Step 18: loss = 0.0010 (0.53 ms/thread mean, 0.44 ms / 1.11 ms)
  Partition hamming error at step 9: 304027
  Mask: 10100000000000100010101010100101
  Histogram of partitions used: [0, 24505, 105095, 0]
Step 20: loss = 0.0064 (0.58 ms/thread mean, 0.49 ms / 1.16 ms)
  Partition hamming error at step 10: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 44385, 85215, 0]
Step 22: loss = 0.0039 (0.63 ms/thread mean, 0.54 ms / 1.22 ms)
  Partition hamming error at step 11: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 46074, 83526, 0]
Step 24: loss = 0.0029 (0.69 ms/thread mean, 0.59 ms / 1.28 ms)
  Partition hamming error at step 12: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 46679, 82921, 0]
Step 26: loss = 0.0025 (0.75 ms/thread mean, 0.64 ms / 1.33 ms)
  Partition hamming error at step 13: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 46907, 82693, 0]
Step 28: loss = 0.0023 (0.80 ms/thread mean, 0.69 ms / 1.40 ms)
  Partition hamming error at step 14: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 46981, 82619, 0]
Step 30: loss = 0.0021 (0.86 ms/thread mean, 0.74 ms / 1.47 ms)
  Partition hamming error at step 15: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 47095, 82505, 0]
Step 32: loss = 0.0020 (0.92 ms/thread mean, 0.79 ms / 1.53 ms)
  Partition hamming error at step 16: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 47145, 82455, 0]
Step 34: loss = 0.0020 (0.98 ms/thread mean, 0.84 ms / 1.60 ms)
  Partition hamming error at step 17: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 47216, 82384, 0]
Step 36: loss = 0.0019 (1.03 ms/thread mean, 0.89 ms / 1.67 ms)
  Partition hamming error at step 18: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 47241, 82359, 0]
Step 38: loss = 0.0018 (1.09 ms/thread mean, 0.94 ms / 1.77 ms)
  Partition hamming error at step 19: 0
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [0, 47321, 82279, 0]
 + diagnostics overhead per thread: 0.00851 ms / 0.00524 ms / 0.04596 ms
Partition hamming error: 1.7577854938271604
Final Mean L^2 Loss per block: 0.0018
```

## test_rgb_hard.png

**Original**:

![test_rgb_hard_1_6x.png](test_rgb_hard_1_6x.png)

**Single Partition**:

![reconstructed_test_1p_6x.png](reconstructed_test_1p_6x.png)

```
--- Starting 1-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 0.83 ms over 1024 threads
  Wall clock: 0.13380885124206543
Step 0: loss = 4.0983 (0.11 ms/thread mean, 0.11 ms / 0.11 ms)
Step 2: loss = 0.5616 (0.25 ms/thread mean, 0.25 ms / 0.25 ms)
Step 4: loss = 0.4537 (0.29 ms/thread mean, 0.29 ms / 0.29 ms)
Step 6: loss = 0.4304 (0.32 ms/thread mean, 0.32 ms / 0.32 ms)
Step 8: loss = 0.4225 (0.35 ms/thread mean, 0.35 ms / 0.35 ms)
Step 10: loss = 0.4205 (0.38 ms/thread mean, 0.38 ms / 0.38 ms)
Step 12: loss = 0.4198 (0.41 ms/thread mean, 0.41 ms / 0.41 ms)
Step 14: loss = 0.4198 (0.44 ms/thread mean, 0.44 ms / 0.44 ms)
Step 16: loss = 0.4199 (0.47 ms/thread mean, 0.47 ms / 0.47 ms)
Step 18: loss = 0.4199 (0.50 ms/thread mean, 0.50 ms / 0.50 ms)
Step 20: loss = 0.4202 (0.53 ms/thread mean, 0.53 ms / 0.53 ms)
Step 22: loss = 0.4206 (0.56 ms/thread mean, 0.56 ms / 0.56 ms)
Step 24: loss = 0.4209 (0.59 ms/thread mean, 0.59 ms / 0.59 ms)
Step 26: loss = 0.4211 (0.62 ms/thread mean, 0.62 ms / 0.62 ms)
Step 28: loss = 0.4213 (0.65 ms/thread mean, 0.65 ms / 0.65 ms)
Step 30: loss = 0.4215 (0.68 ms/thread mean, 0.68 ms / 0.69 ms)
Step 32: loss = 0.4217 (0.71 ms/thread mean, 0.71 ms / 0.72 ms)
Step 34: loss = 0.4218 (0.74 ms/thread mean, 0.74 ms / 0.75 ms)
Step 36: loss = 0.4219 (0.77 ms/thread mean, 0.77 ms / 0.78 ms)
Step 38: loss = 0.4219 (0.80 ms/thread mean, 0.80 ms / 0.81 ms)
 + diagnostics overhead per thread: 0.00678 ms / 0.00444 ms / 0.00796 ms
Final Mean L^2 Loss per block: 0.4216
```

**Dual Partition**:

![reconstructed_test_2p_6x.png](reconstructed_test_2p_6x.png)

~2x time, 13x better quality

```
--- Starting 2-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 1.63 ms over 1024 threads
  Wall clock: 0.23972678184509277
Step 0: loss = 1.1691 (0.23 ms/thread mean, 0.21 ms / 0.24 ms)
  Partition hamming error at step 0: 712
  Mask: 01000000010100000001000000010000
  Histogram of partitions used: [0, 1024, 0, 0]
Step 2: loss = 0.1906 (0.44 ms/thread mean, 0.42 ms / 0.45 ms)
  Partition hamming error at step 1: 725
  Mask: 01000000000000000100000001000000
  Histogram of partitions used: [0, 1024, 0, 0]
Step 4: loss = 0.0874 (0.65 ms/thread mean, 0.61 ms / 0.67 ms)
  Partition hamming error at step 2: 747
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [0, 1024, 0, 0]
Step 6: loss = 0.0478 (0.81 ms/thread mean, 0.80 ms / 0.82 ms)
  Partition hamming error at step 3: 748
  Mask: 01000000000000000000000000000000
  Histogram of partitions used: [0, 1024, 0, 0]
Step 8: loss = 0.0256 (0.86 ms/thread mean, 0.84 ms / 0.87 ms)
  Partition hamming error at step 4: 752
  Mask: 01000000000000000000000000000000
  Histogram of partitions used: [0, 1024, 0, 0]
Step 10: loss = 0.0160 (0.90 ms/thread mean, 0.89 ms / 0.92 ms)
  Partition hamming error at step 5: 754
  Mask: 01000000000000000000000000000000
  Histogram of partitions used: [0, 1024, 0, 0]
Step 12: loss = 0.0122 (0.95 ms/thread mean, 0.93 ms / 0.96 ms)
  Partition hamming error at step 6: 754
  Mask: 01000000000000000000000000000000
  Histogram of partitions used: [0, 1024, 0, 0]
Step 14: loss = 0.0094 (0.99 ms/thread mean, 0.97 ms / 1.01 ms)
  Partition hamming error at step 7: 757
  Mask: 01000000000000000000000000000000
  Histogram of partitions used: [0, 1024, 0, 0]
Step 16: loss = 0.0084 (1.04 ms/thread mean, 1.01 ms / 1.06 ms)
  Partition hamming error at step 8: 758
  Mask: 01000000000000000000000000000000
  Histogram of partitions used: [0, 1024, 0, 0]
Step 18: loss = 0.0079 (1.09 ms/thread mean, 1.06 ms / 1.11 ms)
  Partition hamming error at step 9: 756
  Mask: 01000000000000000000000000000000
  Histogram of partitions used: [0, 1024, 0, 0]
Step 20: loss = 0.2236 (1.13 ms/thread mean, 1.10 ms / 1.16 ms)
  Partition hamming error at step 10: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 22: loss = 0.1162 (1.18 ms/thread mean, 1.15 ms / 1.21 ms)
  Partition hamming error at step 11: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 24: loss = 0.0790 (1.23 ms/thread mean, 1.20 ms / 1.25 ms)
  Partition hamming error at step 12: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 26: loss = 0.0578 (1.28 ms/thread mean, 1.25 ms / 1.30 ms)
  Partition hamming error at step 13: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 28: loss = 0.0462 (1.33 ms/thread mean, 1.29 ms / 1.35 ms)
  Partition hamming error at step 14: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 30: loss = 0.0402 (1.38 ms/thread mean, 1.34 ms / 1.40 ms)
  Partition hamming error at step 15: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 32: loss = 0.0389 (1.43 ms/thread mean, 1.39 ms / 1.45 ms)
  Partition hamming error at step 16: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 34: loss = 0.0364 (1.47 ms/thread mean, 1.44 ms / 1.50 ms)
  Partition hamming error at step 17: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 36: loss = 0.0326 (1.52 ms/thread mean, 1.49 ms / 1.55 ms)
  Partition hamming error at step 18: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 38: loss = 0.0321 (1.57 ms/thread mean, 1.53 ms / 1.60 ms)
  Partition hamming error at step 19: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 1024, 0, 0]
 + diagnostics overhead per thread: 0.00681 ms / 0.00516 ms / 0.01276 ms
Partition hamming error: 0.7421875
Final Mean L^2 Loss per block: 0.0314
```

**3 Partitions, no-snapping, just partition pattern**:

![reconstructed_test_3p_6x.png](reconstructed_test_3p_6x.png)

~ similar time, 2x better quality

```
--- Starting 3-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 1.58 ms over 1024 threads
  Wall clock: 0.25887250900268555
Step 0: loss = 0.6657 (0.23 ms/thread mean, 0.21 ms / 0.25 ms)
  Partition hamming error at step 0: 1864
  Mask: 00010101000001011010010101100101
  Histogram of partitions used: [0, 526, 498, 0]
Step 2: loss = 0.1249 (0.45 ms/thread mean, 0.43 ms / 0.47 ms)
  Partition hamming error at step 1: 1985
  Mask: 00010101010101011010010101010101
  Histogram of partitions used: [0, 492, 532, 0]
Step 4: loss = 0.0564 (0.64 ms/thread mean, 0.62 ms / 0.65 ms)
  Partition hamming error at step 2: 1970
  Mask: 00010101010101011010010101010101
  Histogram of partitions used: [0, 489, 535, 0]
Step 6: loss = 0.0272 (0.69 ms/thread mean, 0.68 ms / 0.70 ms)
  Partition hamming error at step 3: 1968
  Mask: 00010101010101011010010101010101
  Histogram of partitions used: [0, 489, 535, 0]
Step 8: loss = 0.0134 (0.74 ms/thread mean, 0.72 ms / 0.75 ms)
  Partition hamming error at step 4: 1965
  Mask: 00010101010101011010010101010101
  Histogram of partitions used: [0, 489, 535, 0]
Step 10: loss = 0.0069 (0.79 ms/thread mean, 0.77 ms / 0.80 ms)
  Partition hamming error at step 5: 1966
  Mask: 00010101010101011010010101010101
  Histogram of partitions used: [0, 489, 535, 0]
Step 12: loss = 0.0039 (0.83 ms/thread mean, 0.81 ms / 0.85 ms)
  Partition hamming error at step 6: 1965
  Mask: 00010101010101011010010101010101
  Histogram of partitions used: [0, 489, 535, 0]
Step 14: loss = 0.0025 (0.88 ms/thread mean, 0.85 ms / 0.90 ms)
  Partition hamming error at step 7: 1969
  Mask: 00010101010101011010010101010101
  Histogram of partitions used: [0, 489, 535, 0]
Step 16: loss = 0.0018 (0.93 ms/thread mean, 0.90 ms / 0.95 ms)
  Partition hamming error at step 8: 1969
  Mask: 00010101010101011010010101010101
  Histogram of partitions used: [0, 489, 535, 0]
Step 18: loss = 0.0015 (0.97 ms/thread mean, 0.94 ms / 1.00 ms)
  Partition hamming error at step 9: 1971
  Mask: 00010101010101011010010101010101
  Histogram of partitions used: [0, 489, 535, 0]
Step 20: loss = 0.9799 (1.02 ms/thread mean, 0.99 ms / 1.05 ms)
  Partition hamming error at step 10: 0
  Mask: 10101010101010100000101010101010
  Histogram of partitions used: [0, 641, 383, 0]
Step 22: loss = 0.2205 (1.07 ms/thread mean, 1.04 ms / 1.11 ms)
  Partition hamming error at step 11: 0
  Mask: 10101010101010100000101010101010
  Histogram of partitions used: [0, 630, 394, 0]
Step 24: loss = 0.1242 (1.12 ms/thread mean, 1.09 ms / 1.16 ms)
  Partition hamming error at step 12: 0
  Mask: 10101010101010100000101010101010
  Histogram of partitions used: [0, 640, 384, 0]
Step 26: loss = 0.0628 (1.17 ms/thread mean, 1.14 ms / 1.21 ms)
  Partition hamming error at step 13: 0
  Mask: 01000000000000000010000000100000
  Histogram of partitions used: [0, 635, 389, 0]
Step 28: loss = 0.0348 (1.22 ms/thread mean, 1.19 ms / 1.26 ms)
  Partition hamming error at step 14: 0
  Mask: 00101010001010100000101000001010
  Histogram of partitions used: [0, 638, 386, 0]
Step 30: loss = 0.0225 (1.27 ms/thread mean, 1.24 ms / 1.31 ms)
  Partition hamming error at step 15: 0
  Mask: 10010101010101010101010101010101
  Histogram of partitions used: [0, 637, 387, 0]
Step 32: loss = 0.0173 (1.32 ms/thread mean, 1.29 ms / 1.36 ms)
  Partition hamming error at step 16: 0
  Mask: 10010101010101010101010101010101
  Histogram of partitions used: [0, 640, 384, 0]
Step 34: loss = 0.0133 (1.38 ms/thread mean, 1.34 ms / 1.41 ms)
  Partition hamming error at step 17: 0
  Mask: 10010101010101010101010101010101
  Histogram of partitions used: [0, 641, 383, 0]
Step 36: loss = 0.0185 (1.43 ms/thread mean, 1.38 ms / 1.48 ms)
  Partition hamming error at step 18: 0
  Mask: 10010101010101010101010101010101
  Histogram of partitions used: [0, 640, 384, 0]
Step 38: loss = 0.0125 (1.50 ms/thread mean, 1.45 ms / 1.54 ms)
  Partition hamming error at step 19: 0
  Mask: 10010101010101010101010101010101
  Histogram of partitions used: [0, 637, 387, 0]
 + diagnostics overhead per thread: 0.00985 ms / 0.00656 ms / 0.01560 ms
Partition hamming error: 1.279296875
Final Mean L^2 Loss per block: 0.0149
```

## Ideas:

1. [Done] Full soft decoder with autodiff (done - slow convergence)
2. [Done] Coordinate descent with gradient descent on partition logits (done - poor stability)
3. [Done] Coordinate descent with gradient descent on the color eps (done - good results, ~but trapped in local minimums~)
4. [Done] Extend to 3P and 4P depending on # of distinct colors, using a combinatorial search of partition seeds (done, viable for 3P)
5. [Deprioritized] ~Use RANSAC to select partitions, using the inlier count as a statistic to uncover # of distinct color lines~
    * Turns out partition selection isn't the problem, it's astc snapping, and jointly modeling the optimization with that in mind
      is very hard without resorting to combinatorial search
6. Actually implement the bise encoding and the astc block format
7. Use PCA to replace the soft differentiable part
8. Do an ensemble of 1P, 2P, and 3P
9. Apply quantization
10. [Done] Apply permutations to available astc patterns to expand the search space (for 3P and 2P)
11. [Done] Use a LUT for 3P as well (~80MB~ 12.2MB using permutation symmetry, plus we have the nice property that $T[\sigma(x)] = \mathbf{argmin}_{s}(\min(dist(\sigma_i(x), p_s))$ is also permutationally invariant, meaning we can quickly explore the full symmetry space during snapping)
12. [Done] Apply the no-1P regularizer to 2P and 3P
13. [Done] Create the symmetric LUT for 2P as well (includes scripts to regenerate these)