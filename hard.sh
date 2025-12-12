uv run python astc_encoder.py -o reconstructed_test_1p.png --m 40 test_rgb_hard_1.png
uv run python astc_encoder.py -o reconstructed_test_2p.png --use_2p --m 40 test_rgb_hard_1.png
uv run python astc_encoder.py -o reconstructed_test_3p.png --use_3p --m 40 test_rgb_hard_1.png