# Chip-RL: corrected-gradient v3, new popcount architecture pilot

This is **additive** to the original projects and does not edit original v1,
v2, the existing popcount32 benchmark, or any completed experiment records.
Only `chiprl/benchmarks.py` is modified, by adding a new benchmark entry.
The stage-1 architecture pilot is exploratory; it is not an independent
confirmation of cross-family RL performance.

## Why this benchmark is different

The old `popcount32` grammar varied bit partitions around almost the same
arithmetic expression. Synthesis collapsed 142 masks to just three measured
physical outcomes. The new, distinctly named `popcount32_tree` grammar uses
**31 internal nodes in a balanced reduction tree**. Each architecture bit
selects either a width-minimal arithmetic adder or explicit parallel
carry-lookahead equations at the corresponding node. In all stored JSON,
`boundary_mask` is the evaluator's legacy integer action field; on this new
benchmark its bits are **adder architecture choices**, not partition cuts.
`K` now means the number of selected carry-lookahead nodes.

The eight preregistered pilot masks are `0x00000000`, `0x7fffffff`,
`0x40000000`, `0x70000000`, `0x7f000000`, `0x0000ffff`, `0x55555555`,
`0x2aaaaaaa` in that exact order. The predeclared diversity gate requires:
all eight pass simulation/formal/P&R; at least four distinct rounded
(area, WNS) pairs; three distinct areas (rounded 0.1); area span at least 1%
of minimum area; reward span at least 0.10. **If it fails, stop: do not launch
v3 RL on this grammar.** A future revised grammar must receive a new name
and be treated as a separate, exploratory experiment.

## Stage A: install and preregister before physical measurements

Copy the ZIP to `~/Downloads` and run in native Ubuntu:

```bash
cd ~/fpga/chip-rl
unzip -n ~/Downloads/chiprl_v3_popcount_tree_pilot_v1.zip -d .
python -m py_compile chiprl/popcount_tree_generator.py experiments/*popcount_tree*.py
python -m experiments.bootstrap_popcount_tree_v1 scaffold
python -m experiments.bootstrap_popcount_tree_v1 verify
python -m experiments.smoke_popcount_tree_v1
python -m experiments.smoke_popcount_tree_v3_v1
python -m experiments.smoke_conditioned_v3
```

The smoke tests perform **no formal/physical EDA** and will not write new
production run histories. They require your original, previously measured
`results/popcount32_shared_seed/results.json` for the policy replay test.

Commit all new code and the preregistration document **before** any physical
measurements. The existing finished experiments and v2 policy are untouched:

```bash
git add chiprl/benchmarks.py chiprl/popcount_tree_generator.py \
  experiments/*popcount_tree*.py \
  experiments/run_popcount_tree_v3_v1.sh \
  experiments/README_popcount_tree_v3_next_stage.md \
  experiments/protocol_popcount_tree_arch_pilot_v1.json \
  rtl/reference/popcount32_tree_ref.v rtl/popcount32_tree/baseline.v \
  sim/tb_popcount32_tree.sv orfs/popcount32_tree

git add -f rtl/generated/popcount32_tree_arch_seed
git diff --cached --stat
git commit -m 'Preregister popcount tree diversity pilot and corrected v3 ablation'
git tag -a popcount-tree-pilot-protocol-v1 -m 'Frozen before physical diversity checks'
```

### Stage B: check every HDL candidate before physical PPA

```bash
python -m experiments.check_popcount_tree_hdl_v1
```

This performs strict Verilator simulation of the inherited 10,000-test
protocol plus sequential Yosys formal equivalence on all eight designs.
It **does not run physical synthesis, placement or routing**. Stop if a
candidate fails. This machine-dependent HDL validation has not been run in
the model's container, which lacks your Verilator/Yosys/ORFS installation.

Then evaluate the one baseline through your full EDA flow:

```bash
python -m chiprl.evaluate rtl/popcount32_tree/baseline.v \
  --benchmark popcount32_tree --no-cache --clean
```

Verify `functional`, `formal_ok`, `synthesis_ok`, `place_route_ok` are all
`true`, and area, WNS and the frozen reward are reported. **Stop here and
share this baseline result** before committing to the remaining seven
architecture tests.

## Stage C: fixed eight-architecture diversity pilot

Once the HDL and baseline are healthy, run the fixed eight seeds. The pilot
measures the baseline again uncached as part of the auditable corpus:

```bash
python -m experiments.measure_popcount_tree_arch_seed_v1
python -m experiments.measure_popcount_tree_arch_seed_v1 --report-only
```

The runner writes each result immediately and resumes only missing masks;
it will not silently replace a failed or altered candidate. It prints the
predeclared area/reward variation thresholds and a `PASS`/`FAIL` decision.

If and only if the pilot gate passes, freeze the seed data and generate the
**second, search-specific preregistration** before any new policy queries:

```bash
python -m experiments.preregister_popcount_tree_v3_v1

git add experiments/popcount_tree_arch_seed_freeze_v1.json \
        experiments/protocol_popcount_tree_v3_v1.json

git add -f results/popcount32_tree_arch_seed/results.json \
           results/popcount32_tree_arch_seed/frontier.json \
           results/popcount32_tree_arch_seed/summary.json

git commit -m 'Freeze physical diversity pilot and preregister v3 ablation'
git tag -a popcount-tree-v3-search-ready-v1 -m 'Frozen before first v3 architecture query'
```

## Stage D: only after pilot passes and seed/search freeze is committed

```bash
bash experiments/run_popcount_tree_v3_v1.sh
```

The launcher runs four methods × three independent RNG seeds × 16 logical
queries = **192 scheduled queries**. It uses the eight shared physical seed
measurements and is designed for deterministic resume. If any run fails,
**preserve its state and log**; do not restart the full shell script.

- `v2_legacy`: original (source-frozen) sequential unconditioned gradient.
- `v2_raw_aggregate`: same aggregate/simultaneous update as v3, but no
  rejection-conditioning correction. This control isolates the gradient
  correction from update-order changes.
- `v3_conditioned`: exact rejection-conditioned update using the *pre-query*
  seen set, with the same initialization, sampler and hyperparameters.
- `v2_frozen`: exact initial v2 policy and sampler without training.

Primary comparisons are **v3 minus raw aggregate** and **v3 minus frozen** in
paired, seed-relative terminal reward. The legacy v2 difference is secondary.
Each method sees its own query history, not other methods' results; physical
cache reuse is allowed and must be counted separately from logical queries.
No `fmax_hz` conclusions; tool power is not activity calibrated. Three RNG
seeds on one post-selected circuit family are exploratory: even a positive
result would not establish broad generalization without fresh, unselected
tasks and repeated physical setups.
