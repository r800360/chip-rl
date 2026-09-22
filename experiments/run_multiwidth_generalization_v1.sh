#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

LOGDIR="results/multiwidth_generalization_v1/logs"
mkdir -p "$LOGDIR"

run() {
    local name="$1"
    shift

    echo
    echo "===================================================="
    echo "RUN: $name"
    echo "===================================================="

    "$@" 2>&1 | tee "$LOGDIR/${name}.log"

    echo "COMPLETE: $name"
}

# Uniform random: three fresh widths.
for w in 36 48 56; do
    run "addpipe${w}_random" \
        python -m "experiments.addpipe${w}_structural_search" \
        --algorithm random
done

# Evolution: same frozen seed corpus and query budget.
for w in 36 48 56; do
    run "addpipe${w}_evolution" \
        python -m "experiments.addpipe${w}_structural_search" \
        --algorithm evolution
done

# Independent-Bernoulli REINFORCE v1.
for w in 36 48 56; do
    run "addpipe${w}_reinforce_v1" \
        python -m "experiments.addpipe${w}_reinforce_v1"
done

# Frozen hierarchical count-and-position REINFORCE v2.
for w in 36 48 56; do
    run "addpipe${w}_reinforce_v2" \
        python -m "experiments.addpipe${w}_reinforce_v2"
done

# Restricted Claude structural search.
for w in 36 48 56; do
    run "addpipe${w}_claude_structural" \
        python -m "experiments.addpipe${w}_claude_structural"
done

echo
echo "PASS: all 15 preregistered search runs completed."
