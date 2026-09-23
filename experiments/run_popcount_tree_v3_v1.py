"""Fresh-popcount exploratory four-way RL mechanistic study.

Does not modify the original frozen v2, v3, or previously completed results.
Requires a passed preregistered physical-diversity pilot and seed freeze.
Methods (all share the eight seed measurements and initial v2 policy):
  v2_legacy: original sequential/in-place unconditioned update;
  v2_raw_aggregate: same learning rule as v3 but no rejection correction;
  v3_conditioned: exact pre-query rejection-conditioned gradient;
  v2_frozen: identical initializer and sampler but no updates.

The raw-aggregate control isolates the conditioning correction from the
aggregation/update-order difference between the frozen v2 and v3 code.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import random
from pathlib import Path

from chiprl.autoregressive_policy import HierarchicalAutoregressiveMaskPolicy
from chiprl.conditioned_autoregressive_policy import ConditionedHierarchicalMaskPolicy
from chiprl.benchmarks import ROOT
from chiprl.popcount_tree_generator import NAME, PILOT_MASKS, write_candidate
from chiprl.rl_env import EDAMaskEvaluator, StructuralMaskEnv

METHODS = ('v2_legacy', 'v2_raw_aggregate', 'v3_conditioned', 'v2_frozen')
RNG_SEEDS = (31001, 31002, 31003)
BUDGET = 16
PROTO = ROOT / 'experiments/protocol_popcount_tree_v3_v1.json'
SEED = ROOT / 'results/popcount32_tree_arch_seed/results.json'
FREEZE = ROOT / 'experiments/popcount_tree_arch_seed_freeze_v1.json'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save_json(path, data):
    temp = path.with_suffix(path.suffix + '.tmp')
    temp.write_text(json.dumps(data, sort_keys=True, indent=2) + '\n')
    temp.replace(path)


def init_policy(method, seed_rows):
    if method in ('v2_raw_aggregate', 'v3_conditioned'):
        return ConditionedHierarchicalMaskPolicy(bits=31, seed_rows=seed_rows)
    return HierarchicalAutoregressiveMaskPolicy(bits=31, seed_rows=seed_rows)


def score_of(record):
    result = record.get('result')
    return float(result['proxy_reward_v0']) if result and result.get('proxy_reward_v0') is not None else -1000.0


def update_policy(policy, method, mask, reward, pre_seen):
    if method == 'v2_legacy':
        return policy.update(mask=mask, score=reward)
    if method == 'v2_raw_aggregate':
        return policy.update_conditioned(mask=mask, score=reward, seen_masks=set())
    if method == 'v3_conditioned':
        return policy.update_conditioned(mask=mask, score=reward, seen_masks=pre_seen)
    if method == 'v2_frozen':
        return None
    raise ValueError(method)


def sample(policy, rng_seed, seen):
    return policy.sample(rng=random.Random(rng_seed), seen_masks=seen)


def replay(policy, method, rng_seed, seed_masks, records):
    """Reconstruct from source and verify every saved action was reproducible."""
    seen = set(seed_masks)
    for i, record in enumerate(records):
        assert record['query_index'] == i
        mask = int(record['boundary_mask'])
        predicted = sample(policy, rng_seed * 1000 + i, seen)
        if mask != predicted:
            raise RuntimeError(f'resume mismatch at query {i}: saved={mask:#x}, expected={predicted:#x}')
        update_policy(policy, method, mask, score_of(record), seen)
        seen.add(mask)
    return seen


def guard():
    protocol = json.loads(PROTO.read_text())
    freeze = json.loads(FREEZE.read_text())
    seed_rows = json.loads(SEED.read_text())
    if sha(SEED) != freeze['results_sha256'] or sha(SEED) != protocol['seed_results_sha256']:
        raise RuntimeError('Frozen seed measurements differ from preregistration')
    if not freeze['diversity_gate_passed']:
        raise RuntimeError('Physical-diversity gate failed: RL searches prohibited')
    if [int(row['boundary_mask']) for row in seed_rows] != list(PILOT_MASKS):
        raise RuntimeError('Shared seed masks differ or order changed')
    for rel, expected in protocol['source_sha256'].items():
        if sha(ROOT / rel) != expected:
            raise RuntimeError(f'Source differs from preregistration: {rel}')
    if protocol['methods'] != list(METHODS) or protocol['rng_seeds'] != list(RNG_SEEDS) or protocol['budget'] != BUDGET:
        raise RuntimeError('Pre-registered search setup differs')
    return protocol, seed_rows


def initial_snapshot(path, snap):
    if path.exists():
        if json.loads(path.read_text()) != snap:
            raise RuntimeError(f'Saved initial policy differs: {path}')
    else:
        save_json(path, snap)


def run(method, seed):
    if method not in METHODS or seed not in RNG_SEEDS:
        raise ValueError('method or seed not preregistered')
    proto, rows = guard()
    env = StructuralMaskEnv(
        benchmark=NAME, width=32, run_id=f'v3pilot_{method}_seed_{seed}',
        budget=BUDGET, seed_rows=rows,
        render_candidate=write_candidate, evaluate_candidate=EDAMaskEvaluator(NAME),
    )
    expected_meta = {
        'benchmark': NAME, 'method': method, 'rng_seed': seed,
        'protocol_sha256': sha(PROTO), 'seed_results_sha256': sha(SEED),
    }
    meta_file = env.run_dir / 'run_manifest.json'
    if meta_file.exists():
        if json.loads(meta_file.read_text()) != expected_meta:
            raise RuntimeError('Existing run metadata differs; preserve saved results')
    elif env.queries_used > 0:
        raise RuntimeError('Existing query history lacks run manifest; cannot safely resume')
    else:
        save_json(meta_file, expected_meta)

    policy = init_policy(method, rows)
    initial_snapshot(env.run_dir / 'policy_initial.json', policy.snapshot())
    seed_masks = {int(r['boundary_mask']) for r in rows}
    seen = replay(policy, method, seed, seed_masks, env.state['queries'])
    # The environment independently accumulates seed + prior query masks.
    assert seen == env.seen_masks()
    if env.queries_used:
        prior = env.run_dir / f'policy_after_{env.queries_used:02d}.json'
        if prior.exists() and json.loads(prior.read_text()) != policy.snapshot():
            raise RuntimeError('Resumed policy differs from saved checkpoint')

    while not env.done:
        index = env.queries_used
        pre_seen = set(env.seen_masks())
        assert pre_seen == seen
        mask = sample(policy, seed * 1000 + index, pre_seen)
        obs, _, _, _ = env.step(mask)
        record = env.state['queries'][-1]
        assert int(record['boundary_mask']) == mask
        update_policy(policy, method, mask, score_of(record), pre_seen)
        seen.add(mask)
        snap = env.run_dir / f'policy_after_{index+1:02d}.json'
        save_json(snap, policy.snapshot())
        print(f'{NAME} {method} seed={seed} q={index+1:02d}/16 '
              f'mask=0x{mask:08x} K={mask.bit_count()} '
              f'status={record["status"]} score={score_of(record):.6f} '
              f'best={obs["best_so_far"]["proxy_reward_v0"]:.6f}', flush=True)
        if record['status'] == 'evaluator_exception':
            raise RuntimeError(f'EDA exception at query {index+1}; query consumed and saved')

    summary = {
        **expected_meta, 'queries': env.queries_used,
        'initial_reward': max(r['proxy_reward_v0'] for r in rows),
        'best_so_far': env.observation()['best_so_far'],
        'final_policy': policy.snapshot(),
    }
    save_json(env.run_dir / 'summary.json', summary)
    print(f'COMPLETE {NAME} {method} seed={seed} '
          f'best={summary["best_so_far"]["proxy_reward_v0"]:.6f}')


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--method', required=True, choices=METHODS)
    p.add_argument('--seed', required=True, type=int, choices=RNG_SEEDS)
    a = p.parse_args()
    run(a.method, a.seed)
