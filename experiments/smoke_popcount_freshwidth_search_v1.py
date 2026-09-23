"""Zero-EDA smoke: test all 24 trajectories with saved seeds and synthetic rewards.

This is not scientific data; generates no measured-results files.
"""
from __future__ import annotations

from experiments.popcount_freshwidth_search_v1 import (
    METHODS, RNG_SEEDS, BUDGET, action_source, init_policy, learn,
    propose, read_inputs, replay, score_of,
)
from chiprl.popcount_tree_widths_v1 import FRESH_WIDTHS, name
from chiprl.rl_env import is_valid_result


def synthetic_result(seed_reward: float, mask: int, index: int):
    # Deliberately not connected to EDA; exercises updates and archive ordering.
    reward = seed_reward + 0.015 * ((mask.bit_count() + index) % 11 - 5)
    return dict(proxy_reward_v0=reward, functional=True, formal_ok=True,
                synthesis_ok=True, place_route_ok=True,
                area=250.0 + mask.bit_count(), wns=7.0, power_w=0.0)


def main():
    for width in FRESH_WIDTHS:
        proto, seeds = read_inputs(width)
        best_seed = max(float(x['proxy_reward_v0']) for x in seeds)
        initial = init_policy(width, seeds).snapshot()
        assert all(init_policy(width, seeds).snapshot() == initial for _ in METHODS)
        first_two = {}
        for method in METHODS:
            for seed in RNG_SEEDS:
                policy = init_policy(width, seeds)
                archive = [dict(r) for r in seeds]
                seen = {int(r['boundary_mask']) for r in seeds}
                records = []
                first = []
                for i in range(BUDGET):
                    pre_seen = set(seen)
                    mask, source, parent = propose(method, i, policy, archive, seen, seed)
                    assert mask not in seen and 0 <= mask < 1 << (width - 1)
                    if i < 2:
                        first.append(mask)
                    result = synthetic_result(best_seed, mask, i)
                    record = dict(query_index=i, boundary_mask=mask, proposal_source=source,
                                  parent_mask=parent, status='success', result=result)
                    records.append(record)
                    learn(method, source, policy, mask, score_of(record), pre_seen)
                    seen.add(mask)
                    if is_valid_result(result):
                        archive.append({**result, 'boundary_mask': mask})
                end_snap = policy.snapshot()
                reproduced = init_policy(width, seeds)
                replayed, _ = replay(method, seed, reproduced, seeds, records)
                assert replayed == seen and reproduced.snapshot() == end_snap
                if method in ('uniform_local', 'frozen_hybrid'):
                    assert end_snap == initial
                assert len(records) == len({r['boundary_mask'] for r in records}) == BUDGET
                first_two[method, seed] = first
                print(f'PASS {name(width)} {method:16} RNG={seed}: 16 distinct proposals, exact replay')
        # Both hybrid policies must agree before the learning hybrid's first update.
        for seed in RNG_SEEDS:
            assert first_two['v3_hybrid', seed] == first_two['frozen_hybrid', seed]
        print(f'PASS {name(width)}: hybrids share pre-update actions; 12 synthetic trajectories')
    print('PASS: 24 deterministic zero-EDA trajectories; all methods; all RNG seeds')

if __name__ == '__main__':
    main()
