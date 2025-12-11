# astcenc_slang
ASTC Encoder in Slang

Now converges in ~20 steps for 2-partition

## cat.jpg

**Original**:

![cat.jpg](cat.jpg)

**Single Partition**:

![reconstructed_1p.png](reconstructed_1p.png)

**Dual Partition**:

![reconstructed_2p.png](reconstructed_2p.png)

## test_rgb_hard.png

**Original**:

![test_rgb_hard_1.png](test_rgb_hard_1.png)

**Single Partition**:

![reconstructed_test_1p.png](reconstructed_test_1p.png)

**Dual Partition**:

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