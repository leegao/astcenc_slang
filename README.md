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

~2x time, 3x better quality~ (need to include 2p LUT as well)

```
--- Starting 2-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 323.43 ms over 129600 threads
  Wall clock: 1.0977962017059326
Step 0: loss = 0.0412 (0.06 ms/thread mean, 0.04 ms / 0.23 ms)
  Partition hamming error at step 0: 143622
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [8625, 120975, 0, 0]
Step 2: loss = 0.0071 (0.23 ms/thread mean, 0.20 ms / 0.79 ms)
  Partition hamming error at step 1: 141535
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7533, 122067, 0, 0]
Step 4: loss = 0.0038 (0.40 ms/thread mean, 0.36 ms / 0.96 ms)
  Partition hamming error at step 2: 139618
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7437, 122163, 0, 0]
Step 6: loss = 0.0027 (0.56 ms/thread mean, 0.52 ms / 1.13 ms)
  Partition hamming error at step 3: 138816
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7401, 122199, 0, 0]
Step 8: loss = 0.0022 (0.73 ms/thread mean, 0.69 ms / 1.31 ms)
  Partition hamming error at step 4: 138562
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7379, 122221, 0, 0]
Step 10: loss = 0.0020 (0.90 ms/thread mean, 0.85 ms / 1.49 ms)
  Partition hamming error at step 5: 138387
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7361, 122239, 0, 0]
Step 12: loss = 0.0019 (1.07 ms/thread mean, 1.01 ms / 1.68 ms)
  Partition hamming error at step 6: 138430
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7352, 122248, 0, 0]
Step 14: loss = 0.0018 (1.24 ms/thread mean, 1.18 ms / 1.87 ms)
  Partition hamming error at step 7: 138249
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7343, 122257, 0, 0]
Step 16: loss = 0.0018 (1.40 ms/thread mean, 1.34 ms / 2.07 ms)
  Partition hamming error at step 8: 138306
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7339, 122261, 0, 0]
Step 18: loss = 0.0017 (1.57 ms/thread mean, 1.50 ms / 2.28 ms)
  Partition hamming error at step 9: 138340
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7329, 122271, 0, 0]
Step 20: loss = 0.0017 (1.74 ms/thread mean, 1.66 ms / 2.49 ms)
  Partition hamming error at step 10: 138407
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7317, 122283, 0, 0]
Step 22: loss = 0.0017 (1.91 ms/thread mean, 1.82 ms / 2.70 ms)
  Partition hamming error at step 11: 138375
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7296, 122304, 0, 0]
Step 24: loss = 0.0017 (2.09 ms/thread mean, 1.98 ms / 2.92 ms)
  Partition hamming error at step 12: 138361
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7293, 122307, 0, 0]
Step 26: loss = 0.0017 (2.25 ms/thread mean, 2.14 ms / 3.09 ms)
  Partition hamming error at step 13: 138370
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7289, 122311, 0, 0]
Step 28: loss = 0.0017 (2.42 ms/thread mean, 2.30 ms / 3.27 ms)
  Partition hamming error at step 14: 138373
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7280, 122320, 0, 0]
Step 30: loss = 0.0017 (2.59 ms/thread mean, 2.47 ms / 3.46 ms)
  Partition hamming error at step 15: 138396
  Mask: 00000000000000000000000000000000
  Histogram of partitions used: [7275, 122325, 0, 0]
Step 32: loss = 0.0039 (2.88 ms/thread mean, 2.75 ms / 3.78 ms)
  Partition hamming error at step 16: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 34: loss = 0.0029 (3.30 ms/thread mean, 3.17 ms / 4.24 ms)
  Partition hamming error at step 17: 0
  Mask: 00010101010101010101010101010101
  Histogram of partitions used: [0, 129600, 0, 0]
Step 36: loss = 0.0025 (3.73 ms/thread mean, 3.58 ms / 4.70 ms)
  Partition hamming error at step 18: 0
  Mask: 00000101010101000100000000000001
  Histogram of partitions used: [0, 129600, 0, 0]
Step 38: loss = 0.0023 (4.15 ms/thread mean, 3.99 ms / 5.14 ms)
  Partition hamming error at step 19: 0
  Mask: 00000000000000000000000000000101
  Histogram of partitions used: [0, 129600, 0, 0]
 + diagnostics overhead per thread: 0.01425 ms / 0.00456 ms / 0.05736 ms
Partition hamming error: 0.8520293209876543
Final Mean L^2 Loss per block: 0.0023
```

**3 Partitions**:

![reconstructed_3p.png](reconstructed_3p.png)

~ similar time and final quality

```
--- Starting 3-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 73.86 ms over 129600 threads
  Wall clock: 0.7261512279510498
Step 0: loss = 0.0325 (0.05 ms/thread mean, 0.03 ms / 0.22 ms)
  Partition hamming error at step 0: 337565
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3553, 24871, 101176, 0]
Step 2: loss = 0.0067 (0.11 ms/thread mean, 0.08 ms / 0.45 ms)
  Partition hamming error at step 1: 348085
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3425, 21663, 104512, 0]
Step 4: loss = 0.0032 (0.16 ms/thread mean, 0.12 ms / 0.65 ms)
  Partition hamming error at step 2: 347715
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3415, 21373, 104812, 0]
Step 6: loss = 0.0020 (0.21 ms/thread mean, 0.17 ms / 0.74 ms)
  Partition hamming error at step 3: 347954
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3409, 21256, 104935, 0]
Step 8: loss = 0.0015 (0.25 ms/thread mean, 0.21 ms / 0.79 ms)
  Partition hamming error at step 4: 348425
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3406, 21206, 104988, 0]
Step 10: loss = 0.0012 (0.30 ms/thread mean, 0.25 ms / 0.84 ms)
  Partition hamming error at step 5: 348455
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3404, 21181, 105015, 0]
Step 12: loss = 0.0011 (0.35 ms/thread mean, 0.30 ms / 0.89 ms)
  Partition hamming error at step 6: 348725
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3403, 21171, 105026, 0]
Step 14: loss = 0.0010 (0.39 ms/thread mean, 0.34 ms / 0.94 ms)
  Partition hamming error at step 7: 348786
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3402, 21171, 105027, 0]
Step 16: loss = 0.0010 (0.44 ms/thread mean, 0.38 ms / 0.99 ms)
  Partition hamming error at step 8: 348983
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3402, 21178, 105020, 0]
Step 18: loss = 0.0009 (0.48 ms/thread mean, 0.42 ms / 1.04 ms)
  Partition hamming error at step 9: 349144
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3402, 21181, 105017, 0]
Step 20: loss = 0.0009 (0.53 ms/thread mean, 0.47 ms / 1.09 ms)
  Partition hamming error at step 10: 349252
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3401, 21181, 105018, 0]
Step 22: loss = 0.0009 (0.58 ms/thread mean, 0.51 ms / 1.14 ms)
  Partition hamming error at step 11: 349364
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3399, 21182, 105019, 0]
Step 24: loss = 0.0009 (0.62 ms/thread mean, 0.55 ms / 1.19 ms)
  Partition hamming error at step 12: 349453
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3399, 21182, 105019, 0]
Step 26: loss = 0.0009 (0.67 ms/thread mean, 0.60 ms / 1.23 ms)
  Partition hamming error at step 13: 349559
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3398, 21185, 105017, 0]
Step 28: loss = 0.0009 (0.71 ms/thread mean, 0.64 ms / 1.28 ms)
  Partition hamming error at step 14: 349579
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3398, 21186, 105016, 0]
Step 30: loss = 0.0009 (0.76 ms/thread mean, 0.68 ms / 1.33 ms)
  Partition hamming error at step 15: 349634
  Mask: 10100000000000100010101010100000
  Histogram of partitions used: [3394, 21192, 105014, 0]
Step 32: loss = 0.0079 (0.81 ms/thread mean, 0.73 ms / 1.38 ms)
  Partition hamming error at step 16: 36204
  Mask: 10100101010101100110101010101010
  Histogram of partitions used: [8066, 43174, 78360, 0]
Step 34: loss = 0.0049 (0.86 ms/thread mean, 0.78 ms / 1.43 ms)
  Partition hamming error at step 17: 23119
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [4241, 45410, 79949, 0]
Step 36: loss = 0.0035 (0.91 ms/thread mean, 0.82 ms / 1.49 ms)
  Partition hamming error at step 18: 20975
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [3516, 46209, 79875, 0]
Step 38: loss = 0.0030 (0.97 ms/thread mean, 0.87 ms / 1.54 ms)
  Partition hamming error at step 19: 19612
  Mask: 10101010101010101010101010100101
  Histogram of partitions used: [3250, 46467, 79883, 0]
 + diagnostics overhead per thread: 0.01725 ms / 0.00728 ms / 0.05320 ms
Partition hamming error: 2.0794753086419755
Final Mean L^2 Loss per block: 0.0027
Saved reconstructed image to 'reconstructed_3p.png'
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

~2x time, 2x better quality~ (need to include LUT as well)

Note that with the no-1p regularizer and the symmetry tables, this performs on part with 3p

```
--- Starting 2-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 4.85 ms over 1024 threads
  Wall clock: 0.22103142738342285
Step 0: loss = 1.1989 (0.22 ms/thread mean, 0.22 ms / 0.22 ms)
  Partition hamming error at step 0: 860
  Mask: 01000000010100000101000001010000
  Histogram of partitions used: [180, 844, 0, 0]
Step 2: loss = 0.1513 (0.77 ms/thread mean, 0.77 ms / 0.77 ms)
  Partition hamming error at step 1: 876
  Mask: 01000000000000000101000001000000
  Histogram of partitions used: [165, 859, 0, 0]
Step 4: loss = 0.0719 (0.93 ms/thread mean, 0.93 ms / 0.94 ms)
  Partition hamming error at step 2: 871
  Mask: 01000000000000000100000001000000
  Histogram of partitions used: [166, 858, 0, 0]
Step 6: loss = 0.0382 (1.10 ms/thread mean, 1.09 ms / 1.10 ms)
  Partition hamming error at step 3: 877
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [167, 857, 0, 0]
Step 8: loss = 0.0239 (1.26 ms/thread mean, 1.26 ms / 1.26 ms)
  Partition hamming error at step 4: 881
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [168, 856, 0, 0]
Step 10: loss = 0.0151 (1.42 ms/thread mean, 1.42 ms / 1.42 ms)
  Partition hamming error at step 5: 884
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [165, 859, 0, 0]
Step 12: loss = 0.0115 (1.58 ms/thread mean, 1.58 ms / 1.58 ms)
  Partition hamming error at step 6: 881
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [165, 859, 0, 0]
Step 14: loss = 0.0098 (1.74 ms/thread mean, 1.74 ms / 1.75 ms)
  Partition hamming error at step 7: 875
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [164, 860, 0, 0]
Step 16: loss = 0.0091 (1.91 ms/thread mean, 1.90 ms / 1.91 ms)
  Partition hamming error at step 8: 875
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [164, 860, 0, 0]
Step 18: loss = 0.0089 (2.07 ms/thread mean, 2.06 ms / 2.07 ms)
  Partition hamming error at step 9: 873
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [164, 860, 0, 0]
Step 20: loss = 0.0085 (2.23 ms/thread mean, 2.23 ms / 2.23 ms)
  Partition hamming error at step 10: 876
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [164, 860, 0, 0]
Step 22: loss = 0.0086 (2.39 ms/thread mean, 2.39 ms / 2.39 ms)
  Partition hamming error at step 11: 876
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [164, 860, 0, 0]
Step 24: loss = 0.0082 (2.55 ms/thread mean, 2.55 ms / 2.56 ms)
  Partition hamming error at step 12: 872
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [164, 860, 0, 0]
Step 26: loss = 0.0082 (2.72 ms/thread mean, 2.71 ms / 2.72 ms)
  Partition hamming error at step 13: 876
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [164, 860, 0, 0]
Step 28: loss = 0.0082 (2.88 ms/thread mean, 2.87 ms / 2.88 ms)
  Partition hamming error at step 14: 876
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [164, 860, 0, 0]
Step 30: loss = 0.0090 (3.04 ms/thread mean, 3.04 ms / 3.04 ms)
  Partition hamming error at step 15: 876
  Mask: 01000000000000000000000001000000
  Histogram of partitions used: [163, 861, 0, 0]
Step 32: loss = 0.2414 (3.33 ms/thread mean, 3.32 ms / 3.33 ms)
  Partition hamming error at step 16: 0
  Mask: 00010101010101010101010100010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 34: loss = 0.1312 (3.74 ms/thread mean, 3.74 ms / 3.75 ms)
  Partition hamming error at step 17: 0
  Mask: 00010101010101010101010100010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 36: loss = 0.0814 (4.15 ms/thread mean, 4.15 ms / 4.16 ms)
  Partition hamming error at step 18: 0
  Mask: 00010101010101010101010100010101
  Histogram of partitions used: [0, 1024, 0, 0]
Step 38: loss = 0.0561 (4.57 ms/thread mean, 4.56 ms / 4.57 ms)
  Partition hamming error at step 19: 0
  Mask: 00010101010101010101010100010101
  Histogram of partitions used: [0, 1024, 0, 0]
 + diagnostics overhead per thread: 0.01393 ms / 0.00996 ms / 0.01760 ms
Partition hamming error: 0.7548828125
Final Mean L^2 Loss per block: 0.0473
```

**3 Partitions, no-snapping, just partition pattern**:

![reconstructed_test_3p_6x.png](reconstructed_test_3p_6x.png)

~ similar time, 4x better quality

```
--- Starting 3-Partition Compression ---
Running gradient descent for 40 steps

Optimization finished in 1.35 ms over 1024 threads
  Wall clock: 0.21284699440002441
Step 0: loss = 0.6659 (0.20 ms/thread mean, 0.20 ms / 0.20 ms)
  Partition hamming error at step 0: 2054
  Mask: 00010101000101010010010100100100
  Histogram of partitions used: [51, 456, 517, 0]
Step 2: loss = 0.1231 (0.42 ms/thread mean, 0.42 ms / 0.42 ms)
  Partition hamming error at step 1: 2189
  Mask: 00010101010001010010010100100101
  Histogram of partitions used: [47, 419, 558, 0]
Step 4: loss = 0.0548 (0.55 ms/thread mean, 0.55 ms / 0.55 ms)
  Partition hamming error at step 2: 2186
  Mask: 00010101010101010010010100100101
  Histogram of partitions used: [47, 418, 559, 0]
Step 6: loss = 0.0259 (0.59 ms/thread mean, 0.59 ms / 0.59 ms)
  Partition hamming error at step 3: 2182
  Mask: 00010101010101010010010100100101
  Histogram of partitions used: [47, 418, 559, 0]
Step 8: loss = 0.0132 (0.64 ms/thread mean, 0.64 ms / 0.64 ms)
  Partition hamming error at step 4: 2171
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 418, 559, 0]
Step 10: loss = 0.0074 (0.68 ms/thread mean, 0.68 ms / 0.68 ms)
  Partition hamming error at step 5: 2167
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 418, 559, 0]
Step 12: loss = 0.0047 (0.72 ms/thread mean, 0.72 ms / 0.73 ms)
  Partition hamming error at step 6: 2167
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 418, 559, 0]
Step 14: loss = 0.0035 (0.77 ms/thread mean, 0.77 ms / 0.77 ms)
  Partition hamming error at step 7: 2167
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 418, 559, 0]
Step 16: loss = 0.0029 (0.81 ms/thread mean, 0.81 ms / 0.81 ms)
  Partition hamming error at step 8: 2171
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 418, 559, 0]
Step 18: loss = 0.0026 (0.86 ms/thread mean, 0.85 ms / 0.86 ms)
  Partition hamming error at step 9: 2173
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 418, 559, 0]
Step 20: loss = 0.0025 (0.90 ms/thread mean, 0.90 ms / 0.90 ms)
  Partition hamming error at step 10: 2173
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 418, 559, 0]
Step 22: loss = 0.0025 (0.94 ms/thread mean, 0.94 ms / 0.94 ms)
  Partition hamming error at step 11: 2173
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 418, 559, 0]
Step 24: loss = 0.0024 (0.99 ms/thread mean, 0.98 ms / 0.99 ms)
  Partition hamming error at step 12: 2177
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 419, 558, 0]
Step 26: loss = 0.0024 (1.03 ms/thread mean, 1.03 ms / 1.03 ms)
  Partition hamming error at step 13: 2175
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 419, 558, 0]
Step 28: loss = 0.0024 (1.07 ms/thread mean, 1.07 ms / 1.08 ms)
  Partition hamming error at step 14: 2175
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 419, 558, 0]
Step 30: loss = 0.0024 (1.12 ms/thread mean, 1.11 ms / 1.12 ms)
  Partition hamming error at step 15: 2177
  Mask: 00010101010101010110010100100101
  Histogram of partitions used: [47, 419, 558, 0]
Step 32: loss = 1.0127 (1.16 ms/thread mean, 1.16 ms / 1.17 ms)
  Partition hamming error at step 16: 228
  Mask: 10101010101010101010101010101010
  Histogram of partitions used: [28, 621, 375, 0]
Step 34: loss = 0.2365 (1.21 ms/thread mean, 1.21 ms / 1.21 ms)
  Partition hamming error at step 17: 136
  Mask: 01000000000000000010000000100000
  Histogram of partitions used: [21, 622, 381, 0]
Step 36: loss = 0.1368 (1.26 ms/thread mean, 1.26 ms / 1.26 ms)
  Partition hamming error at step 18: 121
  Mask: 01000000000000000010000000100000
  Histogram of partitions used: [25, 624, 375, 0]
Step 38: loss = 0.0714 (1.31 ms/thread mean, 1.30 ms / 1.31 ms)
  Partition hamming error at step 19: 122
  Mask: 01000000000000000010000000100000
  Histogram of partitions used: [20, 626, 378, 0]
 + diagnostics overhead per thread: 0.01170 ms / 0.01016 ms / 0.01404 ms
Partition hamming error: 1.48828125
Final Mean L^2 Loss per block: 0.0533
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
11. [Done] Use a LUT for 3P as well (~80MB~ 12.2MB using permutation symmetry, plus we have the nice property that $T[\sigma(x)] = \argmin_{s}(\min(dist(\sigma_i(x), p_s))$ is also permutationally invariant, meaning we can quickly explore the full symmetry space during snapping)
12. [Done] Apply the no-1P regularizer to 2P and 3P
13. Create the symmetric LUT for 2P as well