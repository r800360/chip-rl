# Deterministic popcount-tree one-flip neighborhood study

Exploratory follow-up to the frozen 192-query v3 pilot. Earlier adaptive samplers did not propose any architecture with 24–30 carry-lookahead nodes; the best seed has all 31 nodes set to CLA. This study exhaustively evaluates all 31 Hamming-distance-one masks obtained by converting one CLA node to an arithmetic adder. The 31 candidate masks, their order, RTL hashes, existing seed measurements, physical flow fingerprints and primary metrics are fixed **before** any neighborhood PPA is taken. This is a deterministic sweep, **not another RL trial**.

1. Preserve the previous v3 ZIP and create tag `popcount-tree-v3-final-v1` if not already done.
2. Install the three Python files from this ZIP in `experiments/`.
3. Run `python -m experiments.preregister_popcount_tree_oneflip_v1`. This step only generates RTL and an immutable JSON protocol; no EDA is invoked.
4. `git add experiments/popcount_tree_oneflip_common_v1.py experiments/preregister_popcount_tree_oneflip_v1.py experiments/run_popcount_tree_oneflip_v1.py experiments/README_popcount_tree_oneflip_v1.md experiments/protocol_popcount_tree_oneflip_v1.json`; add all `rtl/generated/popcount32_tree_oneflip_v1/` using `git add -f` if ignored. Commit **before** measuring. Then `git tag -a popcount-tree-oneflip-preregistered-v1 -m 'Frozen deterministic K30 sweep protocol and RTL'`.
5. Run `python -m experiments.run_popcount_tree_oneflip_v1 --verify`, then `python -m experiments.run_popcount_tree_oneflip_v1 --run`. There are 31 uncached real simulation+formal+P&R evaluations in fixed bit-index order. After each query, `results.json` is atomically updated. A failed evaluation is retained and blocks resumption until investigated; do not silently replace or skip it.
6. Run `python -m experiments.run_popcount_tree_oneflip_v1 --report-only`. It checks the entire corpus and emits `results.json`, `results.csv`, `summary.json` and `pooled_frontier.json` to `results/popcount_tree_oneflip_v1/`.
7. Freeze all outputs and generated RTL in Git after the completed study.

If a toolchain source, Docker image or benchmark definition differs from the frozen seeds, the runner stops. Existing v2/v3 RL records and policies remain untouched. This local neighborhood was selected after inspecting previous data; do **not** treat results as held-out generalization or evidence that corrected RL v3 is superior.
