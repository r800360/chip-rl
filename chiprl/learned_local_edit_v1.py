"""Exact conditional policy gradient over *eligible* one-flip node edits.

This is an additive prototype, not a modification of frozen v3 or popcount
experiments. Parameters are initialized to ZERO so a frozen copy is exactly
uniform over eligible edits. Only a method's own valid archive and current
parent are observable; candidate-set conditioning is exact, not rejection-
normalized approximations. Structural features are width-normalized and are
intended to transfer from popcount trees to a multi-lane addition tree.
"""
from __future__ import annotations

import math
import random

FEATURE_NAMES = (
    'node_is_cla', 'level_normalized', 'level_squared', 'is_root',
    'position_normalized', 'edge_proximity', 'sibling_is_cla',
    'level_cla_fraction_centered', 'cla_times_level',
    'cla_times_level_density',
)
LEARNING_RATE = 0.15
REWARD_SCALE = 0.10
ADVANTAGE_CLIP = 3.0
PARAMETER_CLIP = 3.0


def layout(leaves: int) -> tuple[tuple[int, int, int, int], ...]:
    """For node bit: (level, position, count-in-level, bit offset)."""
    if leaves < 4 or leaves & (leaves-1):
        raise ValueError('Tree leaves must be a power of two >= 4')
    result = []
    offset = 0
    level = 0
    n = leaves // 2
    while n:
        for pos in range(n):
            result.append((level, pos, n, offset))
        offset += n
        n //= 2
        level += 1
    assert offset == leaves - 1
    return tuple(result)


def features(parent: int, bit: int, leaves: int) -> tuple[float, ...]:
    nodes = layout(leaves)
    if parent < 0 or parent >= (1 << len(nodes)) or not 0 <= bit < len(nodes):
        raise ValueError('Invalid parent mask or bit')
    level, position, level_count, level_offset = nodes[bit]
    levels = leaves.bit_length() - 1
    norm_level = level / (levels - 1)
    norm_pos = position / (level_count-1) if level_count > 1 else 0.5
    sign = 1.0 if parent & (1 << bit) else -1.0
    sibling = position ^ 1
    sibling_bit = level_offset + sibling
    sibling_sign = (1.0 if parent & (1 << sibling_bit) else -1.0) if sibling < level_count else 0.0
    level_density = sum(bool(parent & (1 << j)) for j in range(level_offset, level_offset+level_count)) / level_count
    return (
        sign,
        norm_level,
        norm_level * norm_level,
        1.0 if level_count == 1 else 0.0,
        norm_pos * 2 - 1,
        abs(norm_pos - 0.5) * 2,
        sibling_sign,
        level_density * 2 - 1,
        sign * norm_level,
        sign * (level_density * 2 - 1),
    )


class ConditionalLocalEditPolicy:
    def __init__(self, *, leaves: int, learning_rate: float=LEARNING_RATE):
        self.leaves = int(leaves)
        self.nodes = layout(self.leaves)
        self.learning_rate = float(learning_rate)
        self.theta = [0.0] * len(FEATURE_NAMES)
        self.updates = 0

    def eligible(self, parent: int, seen_masks: set[int]) -> tuple[int, ...]:
        return tuple(j for j in range(len(self.nodes)) if (parent ^ (1 << j)) not in seen_masks)

    def probabilities(self, parent: int, eligible_bits) -> dict[int, float]:
        eligible_bits = tuple(eligible_bits)
        if not eligible_bits or len(set(eligible_bits)) != len(eligible_bits):
            raise ValueError('Nonempty unique eligible-bit set required')
        if any(not 0 <= j < len(self.nodes) for j in eligible_bits):
            raise ValueError('Invalid candidate bit')
        logits = {j: sum(w * x for w, x in zip(self.theta, features(parent, j, self.leaves)))
                  for j in eligible_bits}
        peak = max(logits.values())
        exp = {j: math.exp(z - peak) for j, z in logits.items()}
        den = math.fsum(exp.values())
        return {j: exp[j] / den for j in eligible_bits}

    def sample(self, parent: int, eligible_bits, rng: random.Random) -> int:
        probabilities = self.probabilities(parent, eligible_bits)
        u = rng.random()
        cumulative = 0.0
        for bit, p in sorted(probabilities.items()):
            cumulative += p
            if u <= cumulative:
                return bit
        return max(probabilities)

    def log_grad(self, parent: int, chosen_bit: int, eligible_bits) -> tuple[float, ...]:
        p = self.probabilities(parent, eligible_bits)
        if chosen_bit not in p:
            raise ValueError('Chosen edit was not eligible for the actual sampling event')
        fx = features(parent, chosen_bit, self.leaves)
        expectation = tuple(math.fsum(p[bit] * features(parent, bit, self.leaves)[j] for bit in p)
                            for j in range(len(FEATURE_NAMES)))
        return tuple(x - e for x, e in zip(fx, expectation))

    def update(self, *, parent: int, chosen_bit: int, eligible_bits,
               score: float, parent_score: float) -> float:
        # The advantage is the measured reward of the chosen edit relative to
        # its pre-query parent, NOT the post-query incumbent. Fixed scale/clip.
        advantage = max(-ADVANTAGE_CLIP,
                        min(ADVANTAGE_CLIP, (score - parent_score) / REWARD_SCALE))
        gradient = self.log_grad(parent, chosen_bit, eligible_bits)
        self.theta = [max(-PARAMETER_CLIP, min(PARAMETER_CLIP,
                      w + self.learning_rate * advantage * g))
                      for w, g in zip(self.theta, gradient)]
        self.updates += 1
        return advantage

    def snapshot(self) -> dict:
        return {'leaves':self.leaves, 'features':list(FEATURE_NAMES),
                'learning_rate': self.learning_rate,
                'theta':list(self.theta), 'updates':self.updates}
