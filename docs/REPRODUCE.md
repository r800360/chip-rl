# Reproduce

## Setup (Ubuntu 24.04, x86-64)

```bash
# 1. System tools
sudo apt install -y git make g++ python3-venv verilator yosys graphviz   # Verilator 5.020
# Docker CE: https://docs.docker.com/engine/install/ubuntu/

# 2. OpenROAD-flow-scripts, built locally (the prebuilt image crashed with SIGILL on this CPU)
git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts ~/eda/OpenROAD-flow-scripts
git -C ~/eda/OpenROAD-flow-scripts checkout 3a964e13f11a4e435aac01ffa14db0a7d2853720
# build the image, tag it openroad/orfs:local, then:
echo 'export OR_IMAGE=openroad/orfs:local' >> ~/.bashrc

# 3. Python
cd chip-rl
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
```

Results in this repository were produced with image ID `sha256:8cae1bdb8296...`, ORFS commit `3a964e13`, Yosys 0.68 (in the image), Verilator 5.020 and Python 3.12. Every evaluation record stores these in its `fingerprint`, and cached results are only reused when the fingerprint matches.

## Smoke test

```bash
python -m chiprl.evaluate rtl/cmp32/baseline.v --benchmark cmp32
# expect: functional, formal_ok, place_route_ok = true; area 268.926; wns 7.62112; proxy_reward_v0 75.942274
pytest -q tests/                      # formal soundness suite, about 25 s
```

A design that was already evaluated returns from cache (`"cache_hit": true`). Add `--no-cache --clean` to force a fresh run (this rewrites that design's record).

## Experiment index

Every study has a protocol committed before measurement and a git tag. Runners refuse to start if a hashed source file has changed, and refuse to overwrite existing results.

| Study (date) | Protocol | Runner | Results | Tag |
|---|---|---|---|---|
| 8-bit random search, loose and strict spec (Sept 20) | none (pre-protocol) | `experiments/random_search.py`, `random_search_v2.py` | `results/random_search/` | commits `48ed049`, `81e4c82` |
| 48-design map and search benchmark (Sept 20) | none | `experiments/exhaustive_v2.py`, `search_benchmark*.py` | `results/design_space_v2/`, `results/search_benchmark*/` | `34e9d2f`, `08ea608` |
| 16-bit searches and model-written RTL (Sept 20) | none | `experiments/addpipe16_*.py` | `results/addpipe16_*` | `b85b03f` |
| Autonomous Claude, 16-bit (Sept 21) | none | `experiments/run_rtl_agent.py` + `adapters/claude_rtl_agent.py` | `results/agent_runs/claude_sonnet5_history16/`, `results/analysis/claude_sonnet5_history16/` | `77a8f91` |
| 24-bit controlled and open-RTL (Sept 21) | `protocol_addpipe24*.json` | `addpipe24_structural_search.py`, `run_addpipe24_rtl_agent.py` | `results/addpipe24_*`, `results/analysis/addpipe24_final/` | `addpipe24-final-v1` |
| 32-bit RL v1 (Sept 21) | `protocol_addpipe32_rl_v1.json` | `addpipe32_structural_search.py`, `addpipe32_reinforce.py` | `results/addpipe32_*`, `results/rl_runs/addpipe32/` | `addpipe32-final-v1` |
| 40-bit RL v2 (Sept 22) | `protocol_addpipe40_rl_v2.json` | `addpipe40_reinforce_v2.py` and baselines | `results/addpipe40_*`, `results/analysis/addpipe40_rl_v2/` | `addpipe40-final-v1` |
| Fresh widths 36/48/56 (Sept 22) | `protocol_multiwidth_generalization_v1.json` | `run_multiwidth_generalization_v1.sh` | `results/multiwidth_generalization_v1/` | `multiwidth-final-v1` |
| Cross-family causal test (Sept 22 to 23) | `protocol_crossfamily_v1.json` | `run_crossfamily_v1.sh` | `results/crossfamily_policy_causality_v1/` | `crossfamily-final-v1` |
| Gradient audit (Sept 23) | none (zero EDA) | `audit_conditioned_policy_gradient_v1.py` | `results/conditioned_gradient_audit_v1.json` | `gradient-audit-v1` |
| Popcount-tree diversity pilot and v3 ablation (Sept 23) | `protocol_popcount_tree_*.json` | `measure_popcount_tree_arch_seed_v1.py`, `run_popcount_tree_v3_v1.sh` | `results/popcount32_tree_arch_seed/`, `results/popcount_tree_v3_pilot_v1/` | `popcount-tree-v3-final-v1` |
| One-flip sweep and replication (Sept 23) | `protocol_popcount_tree_oneflip_v1.json` | `run_popcount_tree_oneflip_v1.py` | `results/popcount_tree_oneflip_v1/` | `popcount-oneflip-replication-final-v1` |
| Fresh widths 16/64, global vs local (Sept 23) | `protocol_popcount_freshwidth_search_v1.json` | `run_popcount_freshwidth_search_v1.sh` | `results/popcount_freshwidth_search_v1/` | `popcount-freshwidth-search-final-v1` |
| Lane-sum formal amendment (Sept 24) | `amendment_lanesum_formal_v1.json` | `register_lanesum_formal_amendment_v1.py`, `lanesum_formal_hardness_v1.py` | `results/formal/` | `lanesum-formal-amendment-v1` |
| Lane-sum pilot and learned local edits (Sept 24) | `protocol_lanesum_pilot_v1.json`, `protocol_learned_local_study_v1.json` | `lanesum_pilot_v1_amend1.py`, `run_learned_local_v1_amend1.sh` | `results/lanesum16x8_arch_seed_v1/`, `results/rl_runs/lanesum16x8_tree/`, `results/learned_local_study_v1_audit/` | `lanesum-learned-local-final-v1` |
| Multi-fidelity proxy analysis (Sept 24) | none (zero EDA) | `python analysis/multifidelity.py` | `results/analysis/multifidelity_v1/` | `v1.0` |
| Agentic Claude eval (Sept 24) | `protocol_agentic_eval_v1.json` | `python -m experiments.agentic_rtl_eval_v1 ...`, then `python -m analysis.agentic_eval` | `results/agentic_eval_v1/`, `results/analysis/agentic_eval_v1/` | `agentic-eval-v1-protocol`, `v1.0` |
| EDA latency and throughput (Sept 24) | none | `python -m experiments.eda_latency_study_v1` | `results/eda_latency_v1/` | `v1.0` |
| Formatting noise (Sept 24) | none | `python -m experiments.flow_noise_study_v1 --workers 8` | `results/flow_noise_v1/` | `v1.0` |

## Figures

```bash
python -m analysis.figures_verification     # reward hack, formal scaling
python -m analysis.figures_multifidelity    # stage-proxy fidelity
python -m analysis.figures_rl               # learning vs frozen, search coverage
python -m analysis.figures_agentic          # agent eval
python -m analysis.figures_latency          # throughput and time breakdown
python -m analysis.figures_timeline         # project timeline
dot -Tpng -Gdpi=170 analysis/diagram_pipeline.dot -o docs/figures/pipeline.png
# layout renders (inside the ORFS image, KLayout 0.30)
bash analysis/render_layouts.sh
```

## Notes

- Physical outputs (`results/nangate45/`, `logs/`, `reports/`, about 30 GB) are not committed; the per-design metrics that matter are in `results/evaluations/`.
- The Claude API key is read from `ANTHROPIC_API_KEY` or `resources/.env` (`CLAUDE_KEY=...`), which is git-ignored.
- ORFS runs are single-design and deterministic for identical files; run several at once with `chiprl.parallel_eval.evaluate_many`, which serializes identical designs with file locks.
- Agent episodes whose API requests failed were rerun from scratch with the same command. Their partial first attempts are kept in `results/agentic_eval_v1/_first_attempt/` (RTL in `rtl/agentic_eval_v1/_first_attempt/`) and are not scored.
- A few folders were renamed after their designs were evaluated. `python -m experiments.relink_record_paths_v1` pointed those records at the moved files (matched by SHA-256) and kept the old path in `candidate_moved_from`.
