# Cross-family causal follow-up (v1) — 32-bit circuits

This bundle was generated from the user's uploaded, hash-validated
`multiwidth_results_bundle.zip`. It creates a **new** experiment; it does not
modify any previous search or reward. It implements three distinct circuit
families under a common 31-bit boundary mask: unsigned comparator, population
counter and highest-set-bit priority encoder. All hold their output during
invalid cycles and have explicit reset semantics.

Frozen comparison, 16 unique queries per method per trial:

- `v1_learn`: hash-verified original Bernoulli REINFORCE policy, changed only to
  a 31-bit action and run RNG seed.
- `v2_learn`: hash-verified original count/ordered-position policy with updates.
- `v2_frozen`: **exact same initial v2 policy and sampler**, but no updates.
- `count_matched_uniform`: exact same **initial K prior**, but K unique
  positions are sampled uniformly instead of using seed-informed position
  logits; no updates.

3 circuit families × 4 methods × 3 random seeds × 16 unique candidate
queries = **576 logical search queries**, plus 24 shared-seed physical
measurements, with possible physical cache reuse between methods.

## Stage A: finalize previous experiment, then preregister (NO NEW EDA)

Copy/extract the bundle into `~/fpga/chip-rl`, preserving paths. From the repo:

```bash
python experiments/bootstrap_crossfamily_v1.py freeze
git add experiments/multiwidth_final_freeze_v1.json
git add -f results/multiwidth_generalization_v1/multiwidth_results_bundle.zip
git commit -m "Freeze completed multiwidth 240-query experiment"
git tag -a multiwidth-final-v1 -m "Frozen 36/48/56-bit study"

python experiments/bootstrap_crossfamily_v1.py scaffold
python experiments/bootstrap_crossfamily_v1.py verify
python -m py_compile chiprl/circuit_family_generators.py \
  experiments/bootstrap_crossfamily_v1.py \
  experiments/crossfamily_runner.py \
  experiments/crossfamily_shared_seeds.py \
  experiments/smoke_crossfamily_policy_v1.py

python -m experiments.smoke_crossfamily_policy_v1

git add chiprl/benchmarks.py chiprl/evaluate.py \
  chiprl/circuit_family_generators.py \
  experiments/bootstrap_crossfamily_v1.py \
  experiments/crossfamily_runner.py \
  experiments/crossfamily_shared_seeds.py \
  experiments/smoke_crossfamily_policy_v1.py \
  experiments/run_crossfamily_v1.sh \
  experiments/README_crossfamily_v1.md \
  experiments/protocol_crossfamily_v1.json \
  rtl/reference/cmp32_ref.v rtl/reference/popcount32_ref.v \
  rtl/reference/priority32_ref.v \
  rtl/cmp32/baseline.v rtl/popcount32/baseline.v rtl/priority32/baseline.v \
  sim/tb_cmp32.sv sim/tb_popcount32.sv sim/tb_priority32.sv \
  orfs/cmp32 orfs/popcount32 orfs/priority32

git commit -m "Preregister comparator popcount priority RL causal study"
git tag -a crossfamily-protocol-v1 -m "Frozen before any new-family PPA"
```

## Stage B: mandatory correctness gate, then baseline PPA only

Run sequential formal equivalence of all three baselines against references:

```bash
python - <<'PY'
from pathlib import Path
from chiprl.benchmarks import get_benchmark
from chiprl.formal import check_equivalence
for name in ('cmp32','popcount32','priority32'):
    r=check_equivalence(Path(f'rtl/{name}/baseline.v'),get_benchmark(name))
    print(name, r['formal_ok'],r['formal_runtime_s'])
    if not r['formal_ok']:
        print(r['formal_output'][-4000:])
        raise RuntimeError(f'{name} formal failed')
PY
```

If all prove equivalent, run three **baseline-only** PPA checks:

```bash
for name in cmp32 popcount32 priority32; do
  python -m chiprl.evaluate "rtl/$name/baseline.v" \
    --benchmark "$name" --no-cache --clean || exit 1
done
```

**STOP after baseline PPA** and examine all three results. The supplied code
was statically compiled and its deterministic policy code exercised with
synthetic measurements, but RTL *must* be validated with your installed
Verilator, Yosys formal and local ORFS. Do not launch seed or search runs if
correctness, synthesis or routing fails.

## Stage C: 24 real shared seeds (after baseline sanity only)

```bash
for name in cmp32 popcount32 priority32; do
  python -m experiments.crossfamily_shared_seeds \
    --benchmark "$name" || exit 1
done
```

Freeze seed files and a separate seed manifest before running any search.
The reserved launcher `bash experiments/run_crossfamily_v1.sh` refuses to start
without `experiments/crossfamily_shared_seed_freeze_v1.json`; create and
commit that manifest only after inspecting every seed and fingerprint.

## Methodological caveats

- These tasks share one 32-bit action-mask encoding but represent three
  different functions and structural generators. Same width/floorplan
  reduce cross-family confounding; rewards are compared **within task**, not
  as raw absolute numbers across tasks.
- Three random seeds are pseudorandom search trajectories on the same
  deterministic physical evaluator; they are not 3 independent chip runs.
- `v2_frozen` isolates policy updates, not the effects of the seed-informed
  initialization or rejection sampling. `count_matched_uniform` controls initial count sparsity, but differs
  from v2-frozen in **both** positional priors and ordered-sampler geometry;
  it does not isolate positional logits alone.
- Current v2 policy position logits share parameters across conditional
  decisions; do not claim it is a fully context-dependent neural autoregressive
  model. Original REINFORCE gradient does not correct for unseen-mask
  rejection conditioning.
- Report valid/failed designs, fmax as untrusted, power as rough reported
  power, and runtime/cache-hit counts separately. A score improvement under
  this flow does not establish robust gains under other PDKs or placement seeds.
