"""Zero-EDA smoke for all four sampling/update variants. Never writes results."""
from __future__ import annotations
import random

from chiprl.circuit_family_generators import BITS, mask_from_blocks, MAX_MASK
from chiprl.autoregressive_policy import HierarchicalAutoregressiveMaskPolicy
from experiments import addpipe36_reinforce_v1 as v1
from experiments.crossfamily_runner import guard_frozen_sources, choose_count_matched


def main():
    guard_frozen_sources()
    family = [(32,), (8,24), (16,16), (24,8), (8,8,8,8),
              (4,)*8, (2,)*16, (1,)*32]
    masks = [mask_from_blocks(b) for b in family]
    rows = [{'boundary_mask': m, 'proxy_reward_v0': 75.0 - .25*i}
            for i,m in enumerate(masks)]
    assert len(set(masks)) == 8
    seed = 20260923

    v1.BITS = BITS
    v1.POLICY_SEED = seed
    logits, baseline, scale = v1.initialize(rows)
    learn = HierarchicalAutoregressiveMaskPolicy(bits=BITS, seed_rows=rows)
    frozen = HierarchicalAutoregressiveMaskPolicy(bits=BITS, seed_rows=rows)
    matched = HierarchicalAutoregressiveMaskPolicy(bits=BITS, seed_rows=rows)
    assert learn.snapshot() == frozen.snapshot() == matched.snapshot()
    seen = {m: set(masks) for m in ('v1','v2','frozen','matched')}
    for index in range(16):
        a = v1.sample_mask(logits,index,seen['v1'])
        b = learn.sample(rng=random.Random(seed+index),seen_masks=seen['v2'])
        c = frozen.sample(rng=random.Random(seed+index),seen_masks=seen['frozen'])
        d = choose_count_matched(matched,random.Random(seed+index),seen['matched'])
        assert 0 <= a <= MAX_MASK and a not in seen['v1']
        assert 0 <= b <= MAX_MASK and b not in seen['v2']
        assert 0 <= c <= MAX_MASK and c not in seen['frozen']
        assert 0 <= d <= MAX_MASK and d not in seen['matched']
        if index == 0:
            assert b == c, 'first v2 learned and frozen actions must be identical'
        for name, mask in [('v1',a),('v2',b),('frozen',c),('matched',d)]:
            seen[name].add(mask)
        score = 75.0 - 0.01*(index+1)
        baseline,scale,_ = v1.update_policy(logits,baseline,scale,a,score)
        learn.update(mask=b,score=score)
    assert len(seen['v1']) == len(seen['v2']) == len(seen['frozen']) == len(seen['matched']) == 24
    assert learn.snapshot() != frozen.snapshot()
    assert frozen.snapshot() == matched.snapshot()
    print('PASS: 4 methods x 16 distinct synthetic proposals, no EDA, no saved result files')


if __name__ == '__main__':
    main()
