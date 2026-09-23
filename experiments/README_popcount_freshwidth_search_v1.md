# Fresh-width popcount global/local search v1

This package is **additive**. It does not modify `chiprl/autoregressive_policy.py`,
`chiprl/conditioned_autoregressive_policy.py`, the 32-bit archived experiments,
or the 16/64-bit physical diversity pilot.

## Study design

- Benchmarks: `popcount16_tree` and `popcount64_tree` (distinct widths in the same circuit family, **not** cross-family generalization).
- All methods share only the eight already-measured seed designs from each width.
- Four methods, three RNG seeds (`32001`, `32002`, `32003`), 16 queries each: **384 logical queries** total.
- `v3_global`: corrected conditioned v3 on global proposals, all 16 queries.
- `uniform_local`: select uniformly from unused Hamming-distance-one neighbors of the best own valid archived design that has at least one unused neighbor. 16 local queries. An exhausted incumbent is skipped in favor of the next-highest own archived design; ties use `(higher reward, lower area, lower numeric mask)`.
- `v3_hybrid`: query 1 local, query 2 global, alternating exactly eight each. Corrected v3 **updates only on its own global proposals**. The local archive adapts to its own physical results.
- `frozen_hybrid`: identical 50/50 schedule, identical global v3 initialization and sampler, identical adaptive *own local archive*, but **no gradient or baseline updates**.
- The global sampler rejects previously evaluated designs, including seeds and each trajectory's local discoveries. v3 receives the complete **pre-query** seen set for its rejection-conditioned gradient.
- RNG is `random.Random(seed*1000 + index*4 + channel)` (local=1, global=2). Fixed per-query streams enable matched comparisons and prevent overlap between runs.
- Each method can read only the eight physical seeds plus its *own* prior queries. Global EDA cache reuse is allowed, and must be reported separately from independent logical queries.
- Reward remains the frozen `-0.001 * area + 10 * WNS`, with the previous evaluator's failure behavior. No use of untrusted `fmax_hz`; reported power is auxiliary and not activity-annotated.

The primary preregistered contrast is **`v3_hybrid - frozen_hybrid`**, paired by width and RNG seed. The second primary contrast is **`v3_global - uniform_local`**. Secondary contrasts include hybrid versus global, first improvement, incumbent trajectory, Pareto-frontier contributions, boundary-count distributions, acceptance mass, and cache usage.

**Scope:** The generator and fresh widths were constructed in response to the exploratory 32-bit neighborhood result. No 16/64-bit *search results* are used to tune or initialize the algorithms, but these benchmarks should not be described as independently selected circuit families or a definitive generalization test.

## Run on Ubuntu

After the two completed eight-seed pilots and their `report --width` checks:

```bash
cd ~/fpga/chip-rl
unzip -n ~/Downloads/chiprl_popcount_freshwidth_search_v1.zip -d .
python -m experiments.preregister_popcount_freshwidth_search_v1 --freeze
python -m experiments.smoke_popcount_freshwidth_search_v1
python -m experiments.preregister_popcount_freshwidth_search_v1 --verify

git add experiments/popcount_freshwidth_search_v1.py \
        experiments/preregister_popcount_freshwidth_search_v1.py \
        experiments/smoke_popcount_freshwidth_search_v1.py \
        experiments/run_popcount_freshwidth_search_v1.sh \
        experiments/README_popcount_freshwidth_search_v1.md \
        experiments/popcount_freshwidth_seed_freeze_v1.json \
        experiments/protocol_popcount_freshwidth_search_v1.json

git add -f \
    results/popcount16_tree_arch_seed_v1/{results,frontier,summary}.json \
    results/popcount64_tree_arch_seed_v1/{results,frontier,summary}.json \
    results/popcount_freshwidth_baseline_v1/{popcount16_tree,popcount64_tree}.json

git diff --cached --check
# Inspect staged paths and diff before committing.
git diff --cached --stat
git commit -m "Freeze fresh-width popcount seeds and preregister local/global study"
git tag -a popcount-freshwidth-search-ready-v1 \
    -m "Two passed diversity gates, frozen 384-query global/local protocol"
```

**No search should start before that commit and tag exist.** Once frozen:

```bash
bash experiments/run_popcount_freshwidth_search_v1.sh
```

The launcher is sequential and stops on the first runner error. If interrupted, rerunning it replays completed trajectories and resumes incomplete ones; the evaluator never repeats a saved logical query. Do not delete, overwrite, change methods, retune learning rates or relax a failed benchmark gate. Look for `results/rl_runs/popcount{16,64}_tree/freshwidth_search_v1_<method>_seed_<seed>/state.json` and matching policy snapshots.

The 384-query budget could require several hours on the single-machine Nangate45 flow, depending on cache hits. Prefer `tmux` if running remotely. If a run fails, retain its saved state and logs and report the error before resuming.
