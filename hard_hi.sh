uv run python astc_encoder.py -o reconstructed_hard_1p.png --m 40 hard_hi.png
uv run python astc_encoder.py -o reconstructed_hard_2p.png --use_2p --m 40 hard_hi.png
uv run python astc_encoder.py -o reconstructed_hard_3p.png --use_3p --m 40 hard_hi.png
uv run python astc_encoder.py -o reconstructed_hard_ensemble.png --ensemble --steps_1p 39 --m 40 hard_hi.png