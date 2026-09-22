#!/usr/bin/env bash
# Run only AFTER all three 8-seed corpora are valid and frozen in Git.
set -Eeuo pipefail
cd "$(dirname "$0")/.."
logdir=results/crossfamily_policy_causality_v1/logs
mkdir -p "$logdir"

python - <<'PY'
import json
from pathlib import Path
p=Path('experiments/crossfamily_shared_seed_freeze_v1.json')
if not p.is_file(): raise SystemExit('STOP: freeze all three shared seed corpora first')
for name in ('cmp32','popcount32','priority32'):
    rows=json.loads(Path(f'results/{name}_shared_seed/results.json').read_text())
    assert len(rows)==8 and all(x['functional'] and x['formal_ok'] and x['place_route_ok'] for x in rows)
print('PASS: three shared-seed corpora present and valid')
PY

for benchmark in cmp32 popcount32 priority32; do
  for seed in 20260923 20260924 20260925; do
    for method in v1_learn v2_learn v2_frozen count_matched_uniform; do
      name="${benchmark}_${method}_${seed}"
      echo "========== $name =========="
      python -m experiments.crossfamily_runner \
        --benchmark "$benchmark" \
        --method "$method" \
        --seed "$seed" 2>&1 | tee -a "${logdir}/${name}.log"
    done
  done
done

echo 'PASS: all 36 runs completed (576 saved logical search queries)'
