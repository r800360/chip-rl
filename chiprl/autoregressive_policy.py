from __future__ import annotations

import math
import random
import statistics
from typing import Any


def _clip(x, lo, hi):
    return max(
        lo,
        min(hi, x),
    )


def _softmax(
    logits,
    valid=None,
):
    if valid is None:
        valid = range(
            len(logits)
        )

    valid = list(valid)

    if not valid:
        raise ValueError(
            "empty categorical support"
        )

    m = max(
        logits[i]
        for i in valid
    )

    exps = {
        i: math.exp(
            logits[i] - m
        )
        for i in valid
    }

    total = sum(
        exps.values()
    )

    return {
        i: exps[i] / total
        for i in valid
    }


def _sample_categorical(
    probabilities,
    rng: random.Random,
):
    x = rng.random()
    cumulative = 0.0

    items = sorted(
        probabilities.items()
    )

    for value, p in items:
        cumulative += p

        if x <= cumulative:
            return value

    return items[-1][0]


def mask_positions(
    mask: int,
    bits: int,
):
    return [
        bit
        for bit in range(bits)
        if mask & (1 << bit)
    ]


class HierarchicalAutoregressiveMaskPolicy:
    """
    Hierarchical autoregressive policy over all boundary
    masks.

    1. Sample global boundary count K.
    2. Sample K boundary positions in increasing order,
       with each position conditioned on earlier positions.

    Every subset of boundary positions has exactly one
    representation, so the policy spans the entire 2^bits
    mask space.
    """

    def __init__(
        self,
        *,
        bits: int,
        seed_rows,
        temperature: float = 0.5,
        count_prior: float = 0.02,
        position_prior: float = 0.02,
        count_learning_rate: float = 0.30,
        position_learning_rate: float = 0.20,
        ema_rate: float = 0.20,
        minimum_scale: float = 0.25,
        advantage_clip: float = 3.0,
        logit_clip: float = 8.0,
    ):
        self.bits = int(bits)

        if self.bits <= 0:
            raise ValueError(
                "bits must be positive"
            )

        self.temperature = float(
            temperature
        )

        self.count_learning_rate = float(
            count_learning_rate
        )

        self.position_learning_rate = float(
            position_learning_rate
        )

        self.ema_rate = float(
            ema_rate
        )

        self.minimum_scale = float(
            minimum_scale
        )

        self.advantage_clip = float(
            advantage_clip
        )

        self.logit_clip = float(
            logit_clip
        )

        rows = [
            dict(r)
            for r in seed_rows
        ]

        if not rows:
            raise ValueError(
                "seed_rows cannot be empty"
            )

        rewards = [
            float(
                r["proxy_reward_v0"]
            )
            for r in rows
        ]

        best = max(
            rewards
        )

        raw_weights = [
            math.exp(
                (r - best)
                / self.temperature
            )
            for r in rewards
        ]

        total_weight = sum(
            raw_weights
        )

        weights = [
            w / total_weight
            for w in raw_weights
        ]

        # count_prior is TOTAL symmetric pseudocount mass
        # across the complete support K = 0..bits.  It is
        # deliberately not a per-category pseudocount:
        # otherwise the total prior mass would grow with
        # design width and strongly bias wider benchmarks
        # toward large boundary counts.
        count_prior_total = float(
            count_prior
        )

        count_mass = [
            count_prior_total
            / (self.bits + 1)
            for _ in range(
                self.bits + 1
            )
        ]

        position_mass = [
            float(position_prior)
            for _ in range(
                self.bits
            )
        ]

        for weight, row in zip(
            weights,
            rows,
        ):
            mask = int(
                row[
                    "boundary_mask"
                ]
            )

            positions = (
                mask_positions(
                    mask,
                    self.bits,
                )
            )

            k = len(
                positions
            )

            count_mass[k] += (
                weight
            )

            if k:
                per_position = (
                    weight / k
                )

                for bit in positions:
                    position_mass[
                        bit
                    ] += per_position

        self.count_logits = [
            math.log(x)
            for x in count_mass
        ]

        self.position_logits = [
            math.log(x)
            for x in position_mass
        ]

        self.baseline = (
            statistics.mean(
                rewards
            )
        )

        self.scale = max(
            statistics.pstdev(
                rewards
            ),
            self.minimum_scale,
        )

    def count_probabilities(
        self,
    ):
        return _softmax(
            self.count_logits
        )

    def position_preferences(
        self,
    ):
        return _softmax(
            self.position_logits
        )

    def _trace(
        self,
        mask: int,
    ):
        positions = (
            mask_positions(
                mask,
                self.bits,
            )
        )

        k = len(
            positions
        )

        count_probs = (
            self.count_probabilities()
        )

        position_steps = []

        last = -1

        for step, chosen in enumerate(
            positions
        ):
            remaining_after = (
                k - step - 1
            )

            upper_exclusive = (
                self.bits
                - remaining_after
            )

            valid = range(
                last + 1,
                upper_exclusive,
            )

            probs = _softmax(
                self.position_logits,
                valid,
            )

            if chosen not in probs:
                raise ValueError(
                    "mask cannot be represented "
                    "by ordered-position trace"
                )

            position_steps.append({
                "chosen": chosen,
                "probabilities": probs,
            })

            last = chosen

        return {
            "count":
                k,

            "count_probabilities":
                count_probs,

            "position_steps":
                position_steps,
        }

    def sample(
        self,
        *,
        rng: random.Random,
        seen_masks=None,
        max_attempts: int = 100000,
    ):
        seen = (
            set()
            if seen_masks is None
            else set(seen_masks)
        )

        for _ in range(
            max_attempts
        ):
            count_probs = (
                self.count_probabilities()
            )

            k = _sample_categorical(
                count_probs,
                rng,
            )

            positions = []
            last = -1

            for step in range(k):
                remaining_after = (
                    k - step - 1
                )

                upper_exclusive = (
                    self.bits
                    - remaining_after
                )

                valid = range(
                    last + 1,
                    upper_exclusive,
                )

                probs = _softmax(
                    self.position_logits,
                    valid,
                )

                chosen = (
                    _sample_categorical(
                        probs,
                        rng,
                    )
                )

                positions.append(
                    chosen
                )

                last = chosen

            mask = 0

            for bit in positions:
                mask |= (
                    1 << bit
                )

            if mask not in seen:
                return mask

        raise RuntimeError(
            "Could not sample an unseen mask"
        )

    def update(
        self,
        *,
        mask: int,
        score: float,
    ):
        score = float(
            score
        )

        trace = self._trace(
            mask
        )

        old_baseline = (
            self.baseline
        )

        advantage = _clip(
            (
                score
                - old_baseline
            )
            / max(
                self.scale,
                self.minimum_scale,
            ),
            -self.advantage_clip,
            self.advantage_clip,
        )

        chosen_k = (
            trace["count"]
        )

        count_probs = (
            trace[
                "count_probabilities"
            ]
        )

        for k, p in (
            count_probs.items()
        ):
            gradient = (
                (1.0 if k == chosen_k else 0.0)
                - p
            )

            self.count_logits[k] = (
                _clip(
                    self.count_logits[k]
                    + self.count_learning_rate
                    * advantage
                    * gradient,
                    -self.logit_clip,
                    self.logit_clip,
                )
            )

        for step in trace[
            "position_steps"
        ]:
            chosen = step[
                "chosen"
            ]

            for bit, p in step[
                "probabilities"
            ].items():
                gradient = (
                    (
                        1.0
                        if bit == chosen
                        else 0.0
                    )
                    - p
                )

                self.position_logits[
                    bit
                ] = _clip(
                    self.position_logits[
                        bit
                    ]
                    + self.position_learning_rate
                    * advantage
                    * gradient,
                    -self.logit_clip,
                    self.logit_clip,
                )

        self.baseline = (
            (1.0 - self.ema_rate)
            * self.baseline
            + self.ema_rate
            * score
        )

        deviation = max(
            abs(
                score
                - old_baseline
            ),
            self.minimum_scale,
        )

        self.scale = (
            (1.0 - self.ema_rate)
            * self.scale
            + self.ema_rate
            * deviation
        )

        return advantage

    def snapshot(
        self,
    ) -> dict[str, Any]:
        count_probs = (
            self.count_probabilities()
        )

        position_probs = (
            self.position_preferences()
        )

        return {
            "bits":
                self.bits,

            "baseline":
                self.baseline,

            "scale":
                self.scale,

            "count_logits":
                list(
                    self.count_logits
                ),

            "count_probabilities": [
                count_probs[k]
                for k in range(
                    self.bits + 1
                )
            ],

            "expected_boundary_count":
                sum(
                    k * p
                    for k, p
                    in count_probs.items()
                ),

            "position_logits":
                list(
                    self.position_logits
                ),

            "position_preferences": [
                position_probs[k]
                for k in range(
                    self.bits
                )
            ],
        }
