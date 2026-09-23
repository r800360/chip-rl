"""Opt-in corrected v3 prototype: source-frozen v2 + conditioned log score.

This file intentionally does NOT replace chiprl/autoregressive_policy.py.
It must get separate method IDs and a future preregistered EDA study; do not
use it to reinterpret the completed historical v2 results.
"""
from __future__ import annotations

from chiprl.autoregressive_policy import HierarchicalAutoregressiveMaskPolicy, _clip
from chiprl.conditioned_policy_gradient import conditioned_score


class ConditionedHierarchicalMaskPolicy(HierarchicalAutoregressiveMaskPolicy):
    def update_conditioned(self, *, mask: int, score: float, seen_masks) -> float:
        """Apply REINFORCE using the pre-query unseen-mask distribution.

        `seen_masks` MUST be the seen set *before* recording the sampled mask.
        Do not pass env.seen_masks() after env.step(mask) without subtracting
        this newly evaluated mask.
        """
        gradient = conditioned_score(self, mask=mask, seen_masks=seen_masks)
        score = float(score)
        old_baseline = self.baseline
        advantage = _clip(
            (score - old_baseline) / max(self.scale, self.minimum_scale),
            -self.advantage_clip, self.advantage_clip,
        )
        for i, partial in enumerate(gradient["count"]):
            self.count_logits[i] = _clip(
                self.count_logits[i] + self.count_learning_rate * advantage * partial,
                -self.logit_clip, self.logit_clip,
            )
        for i, partial in enumerate(gradient["position"]):
            self.position_logits[i] = _clip(
                self.position_logits[i] + self.position_learning_rate * advantage * partial,
                -self.logit_clip, self.logit_clip,
            )
        self.baseline = (1.0 - self.ema_rate) * self.baseline + self.ema_rate * score
        deviation = max(abs(score - old_baseline), self.minimum_scale)
        self.scale = (1.0 - self.ema_rate) * self.scale + self.ema_rate * deviation
        return advantage
