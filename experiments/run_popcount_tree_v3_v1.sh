#!/usr/bin/env bash
# Run ONLY AFTER pilot gate passes AND v3 protocol + seed freeze are committed.
set -Eeuo pipefail
cd "$(dirname "$0")/.."
logdir=results/popcount_tree_v3_pilot_v1/logs
mkdir -p "$logdir"
for seed in 31001 31002 31003; do
  for method in v2_legacy v2_raw_aggregate v3_conditioned v2_frozen; do
    echo "======== $method / $seed ========"
    python -m experiments.run_popcount_tree_v3_v1 \
      --method "$method" --seed "$seed" 2>&1 \
      | tee -a "$logdir/${method}_${seed}.log"
  done
done
echo 'PASS: 12 trajectories, 192 scheduled logical queries'
