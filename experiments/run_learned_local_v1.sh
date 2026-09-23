#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python -m experiments.freeze_learned_local_v1 --verify
for method in v3_global uniform_local learned_local frozen_hybrid learned_hybrid; do
  for seed in 33001 33002 33003; do
    echo "========== lanesum16x8_tree $method / $seed =========="
    python -m experiments.learned_local_study_v1 --method "$method" --seed "$seed"
  done
done
python -m experiments.summarize_learned_local_v1
