#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."

# No EDA before the frozen protocol, seed results and implementation are checked.
python -m experiments.preregister_popcount_freshwidth_search_v1 --verify

mkdir -p results/popcount_freshwidth_search_v1/logs
for method in v3_global uniform_local v3_hybrid frozen_hybrid; do
  for width in 16 64; do
    for seed in 32001 32002 32003; do
      name="popcount${width}_tree_${method}_${seed}"
      echo "========== ${name} =========="
      python -m experiments.popcount_freshwidth_search_v1 \
        --width "$width" --method "$method" --seed "$seed" \
        2>&1 | tee "results/popcount_freshwidth_search_v1/logs/${name}.log"
    done
  done
done
printf 'PASS: 24 run commands completed; validate each saved state before research conclusions.\n'
