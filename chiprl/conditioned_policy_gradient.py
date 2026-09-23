"""Exact score of the *unseen-mask* distribution of frozen hierarchical v2.

Pure mathematical helper: it does not update policy parameters, invoke EDA,
write search results, or change frozen experimental implementations.

The v2 sampler rejects previously evaluated masks. For fixed seen set S,
q(m) = p_theta(m) / (1 - sum_{s in S} p_theta(s)), m not in S.

Its score is grad log q(m) = grad log p(m) +
    sum_{s in S} p(s) * grad log p(s) / (1 - P(S)).
The implementation uses the source-frozen policy._trace() as the definition
of the unconstrained ordered-position sampler.
"""
from __future__ import annotations

import math
from collections.abc import Iterable


def _validate_mask(policy, mask: int) -> int:
    mask = int(mask)
    if mask < 0 or mask >= (1 << policy.bits):
        raise ValueError(f"mask outside {policy.bits}-bit action space: {mask}")
    return mask


def log_unconditional_probability(policy, mask: int) -> float:
    """Exact log p_theta(mask) according to frozen v2's trace."""
    trace = policy._trace(_validate_mask(policy, mask))
    logp = math.log(trace["count_probabilities"][trace["count"]])
    for step in trace["position_steps"]:
        logp += math.log(step["probabilities"][step["chosen"]])
    return logp


def unconditional_probability(policy, mask: int) -> float:
    return math.exp(log_unconditional_probability(policy, mask))


def raw_log_score(policy, mask: int) -> tuple[list[float], list[float]]:
    """Gradient of log p_theta(mask) wrt (count_logits, position_logits)."""
    trace = policy._trace(_validate_mask(policy, mask))
    count = [-trace["count_probabilities"][k] for k in range(policy.bits + 1)]
    count[trace["count"]] += 1.0
    position = [0.0] * policy.bits
    for step in trace["position_steps"]:
        for bit, prob in step["probabilities"].items():
            position[bit] -= prob
        position[step["chosen"]] += 1.0
    return count, position


def conditioned_log_probability(policy, mask: int, seen_masks: Iterable[int]) -> float:
    """Returns log probability conditional on a valid unseen proposal."""
    mask = _validate_mask(policy, mask)
    seen = {_validate_mask(policy, x) for x in seen_masks}
    if mask in seen:
        raise ValueError("conditioned probability undefined for excluded mask")
    seen_mass = math.fsum(unconditional_probability(policy, s) for s in seen)
    accept = 1.0 - seen_mass
    if accept <= 1e-12:
        raise ArithmeticError("unseen probability mass too small for this audit")
    return log_unconditional_probability(policy, mask) - math.log(accept)


def conditioned_score(policy, mask: int, seen_masks: Iterable[int]) -> dict:
    """Exact score gradient for rejection-conditioned sampling.

    Cost is O(|seen_masks| * ordered-trace-cost), suitable for the 8-24
    seen masks of our 16-query experiment. Do not use as an enumeration of
    the 2**31 action space.
    """
    mask = _validate_mask(policy, mask)
    seen = {_validate_mask(policy, x) for x in seen_masks}
    if mask in seen:
        raise ValueError("the evaluated action must not be in pre-query seen_masks")

    raw_count, raw_position = raw_log_score(policy, mask)
    seen_count = [0.0] * (policy.bits + 1)
    seen_position = [0.0] * policy.bits
    seen_probs = []
    for s in sorted(seen):
        p = unconditional_probability(policy, s)
        seen_probs.append(p)
        gk, gx = raw_log_score(policy, s)
        for i, gi in enumerate(gk):
            seen_count[i] += p * gi
        for i, gi in enumerate(gx):
            seen_position[i] += p * gi

    seen_mass = math.fsum(seen_probs)
    acceptance = 1.0 - seen_mass
    if acceptance <= 1e-12:
        raise ArithmeticError("unseen probability mass too small for this audit")

    correction_count = [x / acceptance for x in seen_count]
    correction_position = [x / acceptance for x in seen_position]
    return {
        "raw_count": raw_count,
        "raw_position": raw_position,
        "count": [x + y for x, y in zip(raw_count, correction_count)],
        "position": [x + y for x, y in zip(raw_position, correction_position)],
        "correction_count": correction_count,
        "correction_position": correction_position,
        "seen_mass": seen_mass,
        "acceptance": acceptance,
        "log_probability": log_unconditional_probability(policy, mask) - math.log(acceptance),
    }
