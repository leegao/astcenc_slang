# astcenc_slang
ASTC Encoder in Slang

Now converges in ~20-40 steps for 2-partition

Caveat for 3-partition and above. The current approach is a coordinate descent to:

1. Use gradient descent on the color eps (this can be replaced by an exact PCA or lsq solver)
2. Choose the optimal partition based on distance to each color line
3. Project the ground truth pixels onto the color line to solve for the weights
4. For the last N steps, snap the ideal partition onto the set of valid ASTC partition patterns (1024)

For 2-partition, this final step works great because your hamming error rate for pixel partition mismatch is like 0.6 - 1.2 pixels per 16 pixels.
However, this jumps to like 11-12 pixels per 16 pixels for the 3-partition problem, because the valid partition space became so much smaller than the full set of valid patterns (2^10 out of 2^16 vs 2^25.5). As a result, this technique just collapses down to doing single partition search once you perform the snap.

It seems like the only way forward is to do (hard) bruteforce combinatorial search of each of the ~300 unique valid partition patterns. This will be ~50x more expensive than the current approach, going from something like 20 megapixels/s down to just 0.5 megapixels/s.

## cat.jpg

**Original**:

![cat.jpg](cat.jpg)

**Single Partition**:

![reconstructed_1p.png](reconstructed_1p.png)

**Dual Partition**:

![reconstructed_2p.png](reconstructed_2p.png)

**3 Partitions, no-snapping, just partition pattern**:

![reconstructed_3p.png](reconstructed_3p.png)

## test_rgb_hard.png

**Original**:

![test_rgb_hard_1.png](test_rgb_hard_1.png)

**Single Partition**:

![reconstructed_test_1p.png](reconstructed_test_1p.png)

**Dual Partition**:

![reconstructed_test_2p.png](reconstructed_test_2p.png)

**3 Partitions, no-snapping, just partition pattern**:

![reconstructed_test_2p.png](reconstructed_test_2p.png)

## Ideas:

1. Full soft decoder with autodiff (done - slow convergence)
2. [2P] Coordinate descent with gradient descent on partition logits (done - poor stability)
3. [2P] Coordinate descent with gradient descent on the color eps (done - good results, ~but trapped in local minimums~)
4. Extend to 3P and 4P depending on # of distinct colors, using a combinatorial search of partition seeds
5. ~Use RANSAC to select partitions, using the inlier count as a statistic to uncover # of distinct color lines~
    * Turns out partition selection isn't the problem, it's astc snapping, and jointly modeling the optimization with that in mind
      is very hard without resorting to combinatorial search
6. Actually implement the bise encoding and the astc block format