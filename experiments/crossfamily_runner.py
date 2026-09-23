"""Four frozen-policy variants on new 32-bit non-adder mask benchmarks.

Run: python -m experiments.crossfamily_runner --benchmark cmp32 --method v2_learn --seed 20260923
Requires eight measured and frozen shared seeds for each benchmark.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import random
from functools import partial

from chiprl.benchmarks import ROOT
from chiprl.autoregressive_policy import HierarchicalAutoregressiveMaskPolicy
from chiprl.circuit_family_generators import FAMILIES, BITS, write_candidate
from chiprl.rl_env import EDAMaskEvaluator, StructuralMaskEnv

METHODS = ('v1_learn', 'v2_learn', 'v2_frozen', 'count_matched_uniform')
SEEDS = (20260923, 20260924, 20260925)
BUDGET = 16
SOURCE_HASHES = {
    'experiments/addpipe36_reinforce_v1.py': '4b082c3ba6ac950bc8f6328b9672d357bd34139820b1c5e97ad115ef17caaba1',
    'chiprl/autoregressive_policy.py': '8441ee22e82388f4f7ccf2fbf1c9abcb917be32f8cbe2012c7ffec37b9449e95',
    'chiprl/rl_env.py': '0573cd00111e4b24c751647f2f80f05aaabbff1425817f3684c991399339cdea',
}


def guard_frozen_sources():
    for name, digest in SOURCE_HASHES.items():
        p = ROOT / name
        actual = hashlib.sha256(p.read_bytes()).hexdigest()
        if actual != digest:
            raise RuntimeError(
                f'frozen source changed: {name}\nexpected {digest}\nactual   {actual}'
            )


def score_of(record):
    r = record.get('result')
    if not r or r.get('proxy_reward_v0') is None:
        return -1000.0
    return float(r['proxy_reward_v0'])


def choose_count_matched(policy, rng, seen):
    """Same frozen v2 K prior; uniform positions conditional on K.

    This controls for sparsity preference while removing seed-informed
    positional preferences and online updates. It is not the original
    v2 ordered-position sampler (that is v2_frozen).
    """
    probs = policy.snapshot()['count_probabilities']
    for _ in range(100000):
        u, acc, k = rng.random(), 0.0, len(probs) - 1
        for i, p in enumerate(probs):
            acc += p
            if u <= acc:
                k = i
                break
        mask = 0
        for j in rng.sample(range(BITS), k):
            mask |= 1 << j
        if mask not in seen:
            return mask
    raise RuntimeError('no unique count-matched sample after 100000 draws')


def snapshot(env, label, method, policy, v1_state=None):
    if method == 'v1_learn':
        v1, logits, baseline, scale = v1_state
        obj = {
            'logits': list(logits),
            'probabilities': [v1.sigmoid(x) for x in logits],
            'expected_boundaries': sum(v1.sigmoid(x) for x in logits),
            'baseline': baseline,
            'scale': scale,
        }
    else:
        obj = policy.snapshot()
    (env.run_dir / f'policy_{label}.json').write_text(
        json.dumps(obj, indent=2, sort_keys=True) + '\n'
    )


def run(benchmark, method, seed):
    guard_frozen_sources()
    if benchmark not in FAMILIES or method not in METHODS or seed not in SEEDS:
        raise ValueError('benchmark, method, or policy seed not preregistered')
    seeds_path = ROOT / 'results' / f'{benchmark}_shared_seed' / 'results.json'
    if not seeds_path.exists():
        raise RuntimeError('measure and freeze the eight shared seeds first')
    seeds = json.loads(seeds_path.read_text())
    protocol = json.loads((ROOT / 'experiments' / 'protocol_crossfamily_v1.json').read_text())
    expected_masks = [int(x, 0) for x in protocol['shared_seed_masks']]
    assert len(seeds) == 8
    assert [int(x['boundary_mask']) for x in seeds] == expected_masks
    assert all(x.get('functional') and x.get('formal_ok') and x.get('place_route_ok') for x in seeds)

    env = StructuralMaskEnv(
        benchmark=benchmark,
        width=32,
        run_id=f'{method}_seed_{seed}',
        budget=BUDGET,
        seed_rows=seeds,
        render_candidate=partial(write_candidate, benchmark),
        evaluate_candidate=EDAMaskEvaluator(benchmark),
    )

    v1_state = None
    if method == 'v1_learn':
        # Call the untouched, hash-verified original algorithm. Only the
        # dimension and RNG seed are parameterized for a new benchmark.
        from experiments import addpipe36_reinforce_v1 as v1
        v1.BITS = BITS
        v1.POLICY_SEED = seed * 1000
        logits, baseline, scale = v1.initialize(seeds)
        for record in env.state['queries']:
            baseline, scale, _ = v1.update_policy(
                logits, baseline, scale,
                int(record['boundary_mask']), score_of(record),
            )
        v1_state = (v1, logits, baseline, scale)
        policy = None
    else:
        policy = HierarchicalAutoregressiveMaskPolicy(bits=BITS, seed_rows=seeds)
        if method == 'v2_learn':
            for record in env.state['queries']:
                policy.update(mask=int(record['boundary_mask']), score=score_of(record))

    if env.queries_used == 0:
        snapshot(env, 'initial', method, policy, v1_state)

    while not env.done:
        index = env.queries_used
        rng = random.Random(seed * 1000 + index)
        if method == 'v1_learn':
            mask = v1.sample_mask(logits, index, env.seen_masks())
        elif method == 'count_matched_uniform':
            mask = choose_count_matched(policy, rng, env.seen_masks())
        else:
            mask = policy.sample(rng=rng, seen_masks=env.seen_masks())

        obs, reward, _, info = env.step(mask)
        record = env.state['queries'][-1]
        advantage = None
        if method == 'v1_learn':
            baseline, scale, advantage = v1.update_policy(
                logits, baseline, scale, mask, score_of(record)
            )
            v1_state = (v1, logits, baseline, scale)
        elif method == 'v2_learn':
            advantage = policy.update(mask=mask, score=score_of(record))

        snapshot(env, f'after_{index+1:02d}', method, policy, v1_state)
        print(
            f'{benchmark} {method} seed={seed} q={index+1:02d}/{BUDGET} '
            f'mask=0x{mask:08x} K={mask.bit_count()} '
            f'status={record["status"]} score={score_of(record):.6f} '
            f'best={obs["best_so_far"]["proxy_reward_v0"]:.6f}',
            flush=True,
        )
        if record['status'] == 'evaluator_exception':
            raise RuntimeError(
                f'EDA infrastructure exception at query {index+1}; '
                f'results saved and query consumed: {record["error"]}'
            )

    final = env.observation()
    summary = {
        'benchmark': benchmark,
        'method': method,
        'policy_seed': seed,
        'queries': env.queries_used,
        'seed_reward': max(r['proxy_reward_v0'] for r in seeds),
        'best_so_far': final['best_so_far'],
        'final_policy': (v1_state and {
            'logits': list(logits), 'baseline': baseline, 'scale': scale,
        }) if method == 'v1_learn' else policy.snapshot(),
    }
    (env.run_dir / 'summary.json').write_text(
        json.dumps(summary, indent=2, sort_keys=True) + '\n'
    )
    print('COMPLETE', benchmark, method, seed, 'best', final['best_so_far']['proxy_reward_v0'])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--benchmark', required=True, choices=FAMILIES)
    parser.add_argument('--method', required=True, choices=METHODS)
    parser.add_argument('--seed', required=True, type=int, choices=SEEDS)
    args = parser.parse_args()
    run(args.benchmark, args.method, args.seed)


if __name__ == '__main__':
    main()
