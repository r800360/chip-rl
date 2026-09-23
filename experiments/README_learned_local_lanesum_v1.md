# Lane-sum tree learned-local v1: staged preregistered protocol

This additive package **does not edit** the frozen 16/32/64-bit popcount
benchmarks, v3 policy or completed 384-query study. Install into your
existing `~/fpga/chip-rl` repository, with the working virtualenv active.

## Scientific question

Do exact, feedback-trained **local-edit** action preferences increase
final physical reward over *uniform* adaptive neighborhood search, with
identical initial policy, candidates, budget and RNG streams?

The new function is the registered unsigned sum of **16 × 8-bit lanes**,
eight lanes from each of `a_i`/`b_i` (64-bit inputs). Its 15-node balanced
reduction topology and arithmetic-ADD/explicit-CLA grammar intentionally
match the popcount-tree family. This is functional/datapath transfer within a
shared architecture grammar, **not** a test of unrelated circuit topologies.
The 16/32/64-bit popcount results are development data only and none are
loaded as physical seed results for this benchmark. The five-method study
starts afresh with the new circuit's eight preregistered pilot seeds.

## Fixed policy

- Ten width-normalized node features; zero-initialized linear softmax over
  *actual prequery eligible* one-bit edits (not a rejection approximation).
- Exact `∇log p(bit | eligible, parent)`; gradient audited by centered finite
  differences and categorical score-function identity at 15/63 nodes.
- Fixed learning rate 0.15; advantage = clipped `(candidate_reward -
  parent_reward) / 0.10`, range [-3,3]; parameter clip [-3,3].
- Parent: best own valid archived candidate with at least one eligible
  unseen one-flip neighbor. Ties break `(higher reward, lower area,
  lower integer mask)`. The *own* archive is always adaptive.
- Methods (`33001..33003`, 16 queries each): `v3_global` (only corrected
  global policy learns); `uniform_local` (frozen zero-weight local softmax);
  `learned_local` (only local learns); `frozen_hybrid` (8 uniform-local and
  8 frozen-v3 global); `learned_hybrid` (same, local policy learns, global
  policy remains frozen). Total planned 240 logical queries.
- All methods receive only eight **new-family** valid seed measurements;
  no method accesses any other's subsequent queries. Physical cache reuse
  permitted, reported separately. The hybrids' prequery global sampler is
  frozen in BOTH arms so the paired hybrid contrast isolates local learning.
- Paired primary: learned-local minus uniform-local and learned-hybrid
  minus frozen-hybrid final incumbent reward, within RNG seed. Three seeds
  are exploratory, not grounds for broad statistical generalization.

## Stage A: zero-EDA checks and register BEFORE PPA

```bash
cd ~/fpga/chip-rl
unzip -n ~/Downloads/chiprl_learned_local_lanesum_v1.zip -d .
python -m experiments.smoke_learned_local_v1
python -m experiments.lanesum_pilot_v1 scaffold
python -m experiments.lanesum_pilot_v1 verify

git add chiprl/lane_sum_tree_v1.py chiprl/learned_local_edit_v1.py \
  experiments/lanesum_pilot_v1.py \
  experiments/freeze_learned_local_v1.py \
  experiments/learned_local_study_v1.py \
  experiments/smoke_learned_local_v1.py \
  experiments/summarize_learned_local_v1.py \
  experiments/run_learned_local_v1.sh \
  experiments/README_learned_local_lanesum_v1.md \
  experiments/protocol_lanesum_pilot_v1.json \
  rtl/reference/lanesum16x8_tree_ref.v \
  rtl/lanesum16x8_tree/baseline.v \
  sim/tb_lanesum16x8_tree.sv \
  orfs/lanesum16x8_tree/config.mk \
  orfs/lanesum16x8_tree/constraint.sdc

git add -f rtl/generated/lanesum16x8_tree_arch_seed_v1/*.v
git diff --cached --check
git diff --cached --stat
git commit -m "Preregister lane-sum family and learned local-edit policy before PPA"
git tag -a lanesum-pilot-protocol-v1 \
  -m "Frozen eight new-family seeds, exact local policy and five search arms"
```

If any of the zero-EDA checks fail, STOP BEFORE generating the PPA records.
Review the source and create a new registration before PPA, not an overwrite
of a protocol with existing physical data.

## Stage B: HDL validation, baseline PPA, physical diversity gate

```bash
python -m experiments.lanesum_pilot_v1 hdl
python -m experiments.lanesum_pilot_v1 baseline
python -m experiments.lanesum_pilot_v1 seeds
python -m experiments.lanesum_pilot_v1 report
```

Eight seed masks and order: `0000, 7fff, 4000, 7000, 7f00,
00ff, 5555, 2aaa`. The gate is 8/8 successful **uncached** simulation,
formal, synthesis and routed evaluations; at least four physical area/WNS
signatures (area rounded 2 dp/WNS rounded 3 dp), at least three area
values (1 dp), at least 1% relative area spread and at least 0.10 scalar
reward spread. All thresholds are fixed in the Stage-A protocol.

`report` is read-only; `seeds` saves each record before validating and is
safe to resume after interruption. If the gate FAILS, **do not run search**
and do not relax these conditions for this grammar. Preserve negative data.

## Stage C: only after pilot gate passes

```bash
git add -f results/lanesum16x8_baseline_v1.json \
  results/lanesum16x8_arch_seed_v1/{results,frontier,summary}.json
git diff --cached --check
git commit -m "Freeze lane-sum eight-seed diversity pilot"
git tag -a lanesum-pilot-final-v1 -m "Frozen eight physical seeds"

python -m experiments.freeze_learned_local_v1 --freeze
python -m experiments.freeze_learned_local_v1 --verify

git add experiments/lanesum_seed_freeze_v1.json \
  experiments/protocol_learned_local_study_v1.json
git diff --cached --check
git commit -m "Freeze lane-sum seed corpus and preregister 240-query search"
git tag -a lanesum-learned-local-search-ready-v1 \
  -m "No search measurements before committed, frozen five-method protocol"
```

Only when the source/seed hashes pass and the search-ready tag exists:

```bash
bash experiments/run_learned_local_v1.sh
```

Each query is saved, replayed and checkpointed for resumability. The final
read-only audit produces `results/learned_local_study_v1_audit/summary.json`,
`runs.csv`, `queries.csv` and `paired.csv`. An evaluator exception consumes
one logical query and must be investigated without deleting its saved state.

## Limitations

This benchmark shares tree topology and ADD/CLA grammar with the exploratory
popcount family; it changes operand widths and function. A genuine unrelated
-topology test is a separate future preregistration. `proxy_reward_v0` is
`-0.001*area+10*WNS` at fixed 10-ns Nangate45 settings. Tool-reported
`power_w` is auxiliary; no activity/SAIF model is used. Do not interpret
`fmax_hz` as a trustworthy physical score.
