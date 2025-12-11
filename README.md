# astcenc_slang
ASTC Encoder in Slang

Ideas:

1. Full soft decoder with autodiff (done - slow convergence)
2. [2P] Coordinate descent with gradient descent on partition logits (done - poor stability)
3. [2P] Coordinate descent with gradient descent on the color eps (done - good results, but trapped in local minimums)
4. Extend to 3P and 4P depending on # of distinct colors, using a combinatorial search of partition seeds
5. Use RANSAC to select partitions, using the inlier count as a statistic to uncover # of distinct color lines
6. Actually implement the bise encoding and the astc block format