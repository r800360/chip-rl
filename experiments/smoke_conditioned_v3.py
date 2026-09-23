"""Zero-EDA tests of the opt-in corrected v3 update.

Run: python -m experiments.smoke_conditioned_v3
"""
from __future__ import annotations

import copy
import json
import math
import random
from pathlib import Path

from chiprl.autoregressive_policy import HierarchicalAutoregressiveMaskPolicy
from chiprl.conditioned_autoregressive_policy import ConditionedHierarchicalMaskPolicy
from chiprl.conditioned_policy_gradient import conditioned_score

ROOT = Path(__file__).resolve().parents[1]


def near(a, b, label, tol=5e-11):
    if abs(a-b) > tol:
        raise AssertionError(f"{label}: {a} vs {b}")


def test_no_seen_matches_frozen():
    rows = [{"boundary_mask": mask, "proxy_reward_v0": reward}
            for mask, reward in ((0,0.0), (3,1.0), (15,0.3))]
    old = HierarchicalAutoregressiveMaskPolicy(bits=4, seed_rows=rows,
        count_prior=.8, position_prior=.13, temperature=1.0, logit_clip=100)
    new = ConditionedHierarchicalMaskPolicy(bits=4, seed_rows=rows,
        count_prior=.8, position_prior=.13, temperature=1.0, logit_clip=100)
    mask, score = 6, 1.5
    a = old.update(mask=mask, score=score)
    b = new.update_conditioned(mask=mask, score=score, seen_masks=set())
    near(a,b,"advantage")
    for k, (x,y) in enumerate(zip(old.count_logits, new.count_logits)):
        near(x,y,f"count {k}")
    for k, (x,y) in enumerate(zip(old.position_logits, new.position_logits)):
        near(x,y,f"position {k}")
    near(old.baseline, new.baseline, "baseline")
    near(old.scale, new.scale, "scale")
    print("PASS: empty seen set reproduces frozen v2 update")


def test_full_conditioning_zero_gradient():
    rows = [{"boundary_mask": mask, "proxy_reward_v0": reward}
            for mask, reward in ((0,0.0), (3,1.0), (7,0.3))]
    new = ConditionedHierarchicalMaskPolicy(bits=3, seed_rows=rows,
        count_prior=.8, position_prior=.13, temperature=1.0, logit_clip=100)
    target = 2
    seen = set(range(1 << new.bits)) - {target}
    gradient = conditioned_score(new, target, seen)
    assert max(abs(x) for x in gradient["count"] + gradient["position"]) < 1e-11
    old_c = new.count_logits[:]
    old_p = new.position_logits[:]
    new.update_conditioned(mask=target, score=2.0, seen_masks=seen)
    assert max(abs(x-y) for x,y in zip(old_c, new.count_logits)) < 1e-11
    assert max(abs(x-y) for x,y in zip(old_p, new.position_logits)) < 1e-11
    try:
        new.update_conditioned(mask=target, score=2.0, seen_masks=seen | {target})
    except ValueError:
        pass
    else:
        raise AssertionError("post-query seen set erroneously accepted")
    print("PASS: deterministic unseen mask has zero log-score; post-query set rejected")


def test_real_initial_policies():
    for benchmark in ("cmp32", "popcount32", "priority32"):
        seeds = json.loads((ROOT / "results" / f"{benchmark}_shared_seed" / "results.json").read_text())
        prior_seen = {int(x["boundary_mask"]) for x in seeds}
        p = ConditionedHierarchicalMaskPolicy(bits=31, seed_rows=seeds)
        m = p.sample(rng=random.Random(20260923), seen_masks=prior_seen)
        g = conditioned_score(p,m,prior_seen)
        assert g["acceptance"] > 0
        old_c, old_p = p.count_logits[:], p.position_logits[:]
        score = p.baseline + max(p.scale,p.minimum_scale) * .4
        advantage = p.update_conditioned(mask=m,score=score,seen_masks=prior_seen)
        near(advantage,.4,benchmark+" advantage")
        for i in range(32):
            expected = max(-p.logit_clip, min(p.logit_clip,
                old_c[i]+p.count_learning_rate*.4*g["count"][i]))
            near(p.count_logits[i],expected,benchmark+f" count[{i}]")
        for i in range(31):
            expected = max(-p.logit_clip, min(p.logit_clip,
                old_p[i]+p.position_learning_rate*.4*g["position"][i]))
            near(p.position_logits[i],expected,benchmark+f" pos[{i}]")
        print("PASS:",benchmark,"corrected update on measured seed corpus, no EDA")


def main():
    test_no_seen_matches_frozen()
    test_full_conditioning_zero_gradient()
    test_real_initial_policies()
    print("PASS: corrected v3 prototype smoke tests")


if __name__ == "__main__":
    main()
