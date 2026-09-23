# Fresh-width popcount-tree diversity pilots (16 and 64 bits)

This is additive. It **never edits** the completed `popcount32_tree` generator,
`chiprl/benchmarks.py`, `chiprl/evaluate.py`, old v2/v3 RL policies, or any
historical result. The fresh benchmarks are provided to the existing evaluator
as transient `Benchmark` objects. Therefore **do not** invoke the generic
`python -m chiprl.evaluate --benchmark popcount16_tree` CLI; it intentionally
only lists the frozen registry. Use this package's staged CLI instead.

## First stage: before ANY new-width EDA

From `~/fpga/chip-rl`, unpack the ZIP **without overwriting** local files:

```bash
unzip -n ~/Downloads/chiprl_popcount_freshwidth_v1.zip -d .
python -m experiments.smoke_popcount_tree_freshwidth_v1
python -m experiments.popcount_tree_freshwidth_pilot_v1 scaffold
python -m experiments.popcount_tree_freshwidth_pilot_v1 verify
```

Commit the source, generated RTL, and preregistration **before** doing even
one new-width physical evaluation:

```bash
git add chiprl/popcount_tree_widths_v1.py \
  experiments/popcount_tree_freshwidth_pilot_v1.py \
  experiments/smoke_popcount_tree_freshwidth_v1.py \
  experiments/README_popcount_tree_freshwidth_v1.md \
  experiments/protocol_popcount_tree_freshwidth_pilot_v1.json \
  rtl/reference/popcount16_tree_ref.v rtl/reference/popcount64_tree_ref.v \
  rtl/popcount16_tree/baseline.v rtl/popcount64_tree/baseline.v \
  sim/tb_popcount16_tree.sv sim/tb_popcount64_tree.sv \
  orfs/popcount16_tree orfs/popcount64_tree
git add -f rtl/generated/popcount16_tree_arch_seed_v1 \
  rtl/generated/popcount64_tree_arch_seed_v1
git diff --cached --check
git commit -m "Preregister fresh 16/64-bit popcount tree diversity pilots"
git tag -a popcount-freshwidth-pilot-protocol-v1 \
  -m "Frozen 16- and 64-bit HDL and PPA diversity pilots before measurement"
```

## Second stage: HDL validation, no physical EDA

```bash
python -m experiments.popcount_tree_freshwidth_pilot_v1 hdl --width 16
python -m experiments.popcount_tree_freshwidth_pilot_v1 hdl --width 64
```

Each executes the inherited 10,000-case Verilator testbench and 4-cycle
sequential formal equivalence for all eight selected RTLs. Failure is a
harness/RTL issue: stop, preserve diagnostics, and record any corrective
amendment before any new PPA.

## Third stage: physically validate baselines, then STOP for review

```bash
python -m experiments.popcount_tree_freshwidth_pilot_v1 baseline --width 16
python -m experiments.popcount_tree_freshwidth_pilot_v1 baseline --width 64
```

Records are `results/popcount_freshwidth_baseline_v1/popcount16_tree.json`
and `popcount64_tree.json`. A failure is recorded and never silently retried.
Do not change floorplans after successful measurements.

## Fourth stage: ONLY if both baselines pass

```bash
python -m experiments.popcount_tree_freshwidth_pilot_v1 seeds --width 16
python -m experiments.popcount_tree_freshwidth_pilot_v1 seeds --width 64
python -m experiments.popcount_tree_freshwidth_pilot_v1 report --width 16
python -m experiments.popcount_tree_freshwidth_pilot_v1 report --width 64
```

Each width gets its own prespecified physical-diversity gate: all eight valid,
>=4 distinct rounded (area,WNS) pairs, >=3 rounded areas, >=1% area variation,
and >=0.10 reward spread. A failed gate prevents the RL study **for that width**;
do not relax thresholds or substitute seeds. The seed runner saves every EDA
result immediately and supports a safe restart of incomplete width pilots.

## Follow-on RL study, intentionally NOT included in this PILOT

Before any post-seed online-search queries, implement and preregister the four
comparators: corrected v3 global, uniform incumbent-local one-flip, a fixed
50/50 v3 global/local mixture, and an identically initialized 50/50 frozen
policy/local mixture. Use matched independent RNG streams and the same 16-query
budget. Do not decide which widths to report based on pilot reward results;
apply the predefined gate separately and disclose any width excluded by it.
Widths 16 and 64 are new *width-transfer tasks*, not independent circuit
families, and the 32-bit local sweep remains exploratory training evidence.
