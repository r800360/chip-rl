"""Zero-EDA uniqueness, cross-method initialization and deterministic resume test."""
from __future__ import annotations

import json
import random
from pathlib import Path

from experiments.run_popcount_tree_v3_v1 import (
    METHODS, RNG_SEEDS, BUDGET, init_policy, sample, replay, update_policy,
)
from chiprl.benchmarks import ROOT


def main():
    # Use the independently measured ORIGINAL popcount seeds so the v3
    # runner can be checked before any new PPA pilot or seed measurements.
    original = ROOT / 'results/popcount32_shared_seed/results.json'
    if not original.is_file():
        raise FileNotFoundError('Original measured popcount32 seed file required for smoke')
    rows = json.loads(original.read_text())
    seed_masks = {int(r['boundary_mask']) for r in rows}
    initial = init_policy(METHODS[0], rows).snapshot()
    assert all(init_policy(method, rows).snapshot() == initial for method in METHODS)
    for seed in RNG_SEEDS:
        first_masks = set()
        for method in METHODS:
            policy = init_policy(method, rows)
            seen = set(seed_masks)
            records = []
            snapshots = []
            for i in range(BUDGET):
                mask = sample(policy, seed * 1000 + i, seen)
                assert mask not in seen
                if i == 0:
                    first_masks.add(mask)
                # Synthetic deterministic toy score, NOT EDA or physical PPA.
                score = 69.0 + (mask.bit_count() % 7) / 7.0
                record = {'query_index': i, 'boundary_mask': mask,
                          'result': {'proxy_reward_v0': score}, 'status': 'synthetic'}
                records.append(record)
                update_policy(policy, method, mask, score, seen)
                seen.add(mask)
                snapshots.append(policy.snapshot())
            fresh = init_policy(method, rows)
            assert replay(fresh, method, seed, seed_masks, records) == seen
            assert fresh.snapshot() == snapshots[-1], (method, seed)
            if method == 'v2_frozen':
                assert fresh.snapshot() == initial
            print(f'PASS: {method} seed={seed}, 16 unique masks, deterministic replay')
        assert len(first_masks) == 1, 'Matched seed must give identical first candidate'
    print('PASS: 12 synthetic trial histories; no EDA and no production result files')


if __name__ == '__main__':
    main()
