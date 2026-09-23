"""Freeze passed pilot + full v3 ablation protocol, before ALL new RL queries."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.popcount_tree_generator import PILOT_MASKS
from experiments.measure_popcount_tree_arch_seed_v1 import report
from experiments.run_popcount_tree_v3_v1 import METHODS, RNG_SEEDS, BUDGET


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def create(p, data):
    contents = json.dumps(data, sort_keys=True, indent=2) + '\n'
    if p.exists():
        if p.read_text() != contents:
            raise RuntimeError(f'Cannot overwrite already frozen {p}')
        print('PRESENT', p.relative_to(ROOT))
        return
    p.write_text(contents)
    print('CREATE', p.relative_to(ROOT))


def main():
    if not report():
        raise RuntimeError('Predeclared architecture-diversity gate failed: STOP')
    out = ROOT / 'results/popcount32_tree_arch_seed'
    result = out / 'results.json'
    rows = json.loads(result.read_text())
    assert len(rows) == 8 and [int(r['boundary_mask']) for r in rows] == list(PILOT_MASKS)
    summary = json.loads((out / 'summary.json').read_text())
    assert summary['diversity_gate_passed']
    existing = list((ROOT / 'results/rl_runs/popcount32_tree').glob('v3pilot_*/state.json'))
    if existing:
        raise RuntimeError('Search state already exists: STOP before preregistration')
    seed_freeze = {
        'status': 'SEEDS_FROZEN_BEFORE_NEW_RL_QUERIES',
        'benchmark': 'popcount32_tree',
        'pilot_protocol_sha256': sha(ROOT / 'experiments/protocol_popcount_tree_arch_pilot_v1.json'),
        'results_sha256': sha(result),
        'frontier_sha256': sha(out / 'frontier.json'),
        'summary_sha256': sha(out / 'summary.json'),
        'diversity_gate_passed': True,
        'seed_best_reward': summary['seed_best_reward'],
        'seed_masks': [f'0x{m:08x}' for m in PILOT_MASKS],
    }
    freeze_path = ROOT / 'experiments/popcount_tree_arch_seed_freeze_v1.json'
    create(freeze_path, seed_freeze)
    sources = (
        'chiprl/benchmarks.py', 'chiprl/evaluate.py',
        'chiprl/autoregressive_policy.py', 'chiprl/conditioned_autoregressive_policy.py',
        'chiprl/conditioned_policy_gradient.py', 'chiprl/rl_env.py',
        'chiprl/popcount_tree_generator.py',
        'experiments/run_popcount_tree_v3_v1.py',
        'experiments/preregister_popcount_tree_v3_v1.py',
        'experiments/measure_popcount_tree_arch_seed_v1.py',
        'rtl/reference/popcount32_tree_ref.v', 'sim/tb_popcount32_tree.sv',
        'orfs/popcount32_tree/config.mk', 'orfs/popcount32_tree/constraint.sdc',
    )
    protocol = {
        'experiment': 'popcount32_tree_v3_pilot_v1',
        'status': 'PREREGISTERED_AFTER_PILOT_BEFORE_ALL_NEW_RL_QUERIES',
        'role': 'exploratory mechanistic ablation; selected task for PPA variation, not held-out confirmation',
        'benchmark': 'popcount32_tree', 'budget': BUDGET,
        'methods': list(METHODS), 'rng_seeds': list(RNG_SEEDS),
        'logical_queries': len(METHODS) * len(RNG_SEEDS) * BUDGET,
        'rng_rule': 'random.Random(seed * 1000 + zero_based_query_index)',
        'seed_masks': [f'0x{m:08x}' for m in PILOT_MASKS],
        'seed_results_sha256': sha(result),
        'seed_freeze_sha256': sha(freeze_path),
        'source_sha256': {name: sha(ROOT / name) for name in sources},
        'isolated_history': 'methods see the eight shared seed rows and ONLY their own query history',
        'shared_physical_cache': 'allowed; logical queries and cache misses reported separately',
        'exact_initial_policy': 'same HierarchicalAutoregressiveMaskPolicy initialization and sampling',
        'v2_legacy': 'original unconditioned in-place ordered-position REINFORCE update',
        'v2_raw_aggregate': 'aggregate gradient and simultaneous step, but zero correction',
        'v3_conditioned': 'same aggregate update as raw control plus exact pre-query rejection correction',
        'v2_frozen': 'same initial policy and sampling, no updates',
        'primary': ['matched final seed-relative reward v3 minus raw_aggregate',
                    'matched final seed-relative reward v3 minus frozen'],
        'secondary': ['v3 minus legacy', 'first improvement query censored at 17',
                      'PPA Pareto contribution', 'validity', 'cache counts',
                      'mean K', 'policy acceptance probability'],
        'interpretation': 'three seeds on one post-selected benchmark are exploratory, not evidence of cross-task generalization',
        'no_hyperparameter_tuning_during_study': True,
    }
    path = ROOT / 'experiments/protocol_popcount_tree_v3_v1.json'
    create(path, protocol)
    print('PASS: pilot seed freeze + 192-query future ablation preregistration')


if __name__ == '__main__':
    main()
