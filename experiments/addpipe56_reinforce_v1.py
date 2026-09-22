from __future__ import annotations

import json
import math
import random
import statistics
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.generate_addpipe56 import (
    write_candidate,
)
from chiprl.rl_env import (
    EDAMaskEvaluator,
    StructuralMaskEnv,
)


WIDTH = 56
BITS = 55
BUDGET = 16

POLICY_SEED = 20260921

TEMPERATURE = 0.5
PRIOR = 0.05

P_MIN = 0.02
P_MAX = 0.98

LEARNING_RATE = 0.35
ADV_CLIP = 3.0

EMA_RATE = 0.20
SCALE_FLOOR = 0.25

FAIL_SCORE = -1000.0

RUN_ID = "reinforce_v1"

SHARED = (
    ROOT
    / "results"
    / "addpipe56_shared_seed"
    / "results.json"
)


def sigmoid(x):
    if x >= 0:
        z = math.exp(-x)
        return 1.0 / (1.0 + z)

    z = math.exp(x)
    return z / (1.0 + z)


def logit(p):
    return math.log(
        p / (1.0 - p)
    )


LOGIT_MIN = logit(P_MIN)
LOGIT_MAX = logit(P_MAX)


def clip(x, lo, hi):
    return max(
        lo,
        min(
            hi,
            x,
        ),
    )


def score_of_record(record):
    result = record.get(
        "result"
    )

    if not result:
        return FAIL_SCORE

    score = result.get(
        "proxy_reward_v0"
    )

    if score is None:
        return FAIL_SCORE

    return float(score)


def initialize(seed_rows):
    rewards = [
        float(
            r["proxy_reward_v0"]
        )
        for r in seed_rows
    ]

    max_reward = max(rewards)

    raw_weights = [
        math.exp(
            (r - max_reward)
            / TEMPERATURE
        )
        for r in rewards
    ]

    total = sum(
        raw_weights
    )

    weights = [
        x / total
        for x in raw_weights
    ]

    logits = []

    for bit in range(
        BITS
    ):
        weighted_ones = sum(
            w
            * (
                (
                    int(
                        row[
                            "boundary_mask"
                        ]
                    )
                    >> bit
                )
                & 1
            )
            for w, row
            in zip(
                weights,
                seed_rows,
            )
        )

        p = (
            PRIOR
            + weighted_ones
        ) / (
            2.0 * PRIOR
            + 1.0
        )

        p = clip(
            p,
            P_MIN,
            P_MAX,
        )

        logits.append(
            logit(p)
        )

    baseline = statistics.mean(
        rewards
    )

    scale = max(
        statistics.pstdev(
            rewards
        ),
        SCALE_FLOOR,
    )

    return (
        logits,
        baseline,
        scale,
    )


def update_policy(
    logits,
    baseline,
    scale,
    mask,
    score,
):
    probs = [
        sigmoid(x)
        for x in logits
    ]

    advantage = clip(
        (
            score
            - baseline
        )
        / max(
            scale,
            SCALE_FLOOR,
        ),
        -ADV_CLIP,
        ADV_CLIP,
    )

    for bit in range(
        BITS
    ):
        action = (
            mask >> bit
        ) & 1

        gradient = (
            action
            - probs[bit]
        )

        logits[bit] = clip(
            logits[bit]
            + LEARNING_RATE
            * advantage
            * gradient,
            LOGIT_MIN,
            LOGIT_MAX,
        )

    old_baseline = baseline

    baseline = (
        (1.0 - EMA_RATE)
        * baseline
        + EMA_RATE
        * score
    )

    deviation = max(
        abs(
            score
            - old_baseline
        ),
        SCALE_FLOOR,
    )

    scale = (
        (1.0 - EMA_RATE)
        * scale
        + EMA_RATE
        * deviation
    )

    return (
        baseline,
        scale,
        advantage,
    )


def sample_mask(
    logits,
    query_index,
    seen,
):
    rng = random.Random(
        POLICY_SEED
        + query_index
    )

    probs = [
        sigmoid(x)
        for x in logits
    ]

    for _ in range(
        100000
    ):
        mask = 0

        for bit, p in enumerate(
            probs
        ):
            if rng.random() < p:
                mask |= (
                    1 << bit
                )

        if mask not in seen:
            return mask

    raise RuntimeError(
        "Could not sample an unseen mask"
    )


def write_policy_snapshot(
    env,
    logits,
    baseline,
    scale,
    label,
):
    probs = [
        sigmoid(x)
        for x in logits
    ]

    path = (
        env.run_dir
        / f"policy_{label}.json"
    )

    path.write_text(
        json.dumps(
            {
                "policy_seed":
                    POLICY_SEED,

                "logits":
                    logits,

                "probabilities":
                    probs,

                "expected_boundaries":
                    sum(probs),

                "baseline":
                    baseline,

                "scale":
                    scale,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )


def main():
    seed_rows = json.loads(
        SHARED.read_text()
    )

    if len(seed_rows) != 8:
        raise RuntimeError(
            "Expected exactly 8 shared seeds"
        )

    env = StructuralMaskEnv(
        benchmark="addpipe56",
        width=WIDTH,
        run_id=RUN_ID,
        budget=BUDGET,
        seed_rows=seed_rows,
        render_candidate=write_candidate,
        evaluate_candidate=(
            EDAMaskEvaluator(
                "addpipe56"
            )
        ),
    )

    (
        logits,
        baseline,
        scale,
    ) = initialize(
        seed_rows
    )

    # Reconstruct policy deterministically when resuming.
    for record in env.state[
        "queries"
    ]:
        score = score_of_record(
            record
        )

        (
            baseline,
            scale,
            _,
        ) = update_policy(
            logits,
            baseline,
            scale,
            int(
                record[
                    "boundary_mask"
                ]
            ),
            score,
        )

    write_policy_snapshot(
        env,
        logits,
        baseline,
        scale,
        "current",
    )

    while not env.done:
        query_index = (
            env.queries_used
        )

        mask = sample_mask(
            logits,
            query_index,
            env.seen_masks(),
        )

        probs = [
            sigmoid(x)
            for x in logits
        ]

        print()
        print("=" * 72)

        print(
            f"REINFORCE QUERY "
            f"{query_index + 1}/{BUDGET}"
        )

        print(
            f"mask=0x{mask:014x}"
        )

        print(
            "expected boundaries:",
            f"{sum(probs):.3f}",
        )

        print("=" * 72)

        (
            observation,
            env_reward,
            done,
            info,
        ) = env.step(
            mask
        )

        record = (
            env.state[
                "queries"
            ][-1]
        )

        score = score_of_record(
            record
        )

        (
            baseline,
            scale,
            advantage,
        ) = update_policy(
            logits,
            baseline,
            scale,
            mask,
            score,
        )

        result = record.get(
            "result"
        )

        if result:
            print(
                "status=",
                record["status"],
                "area=",
                result.get("area"),
                "WNS=",
                result.get("wns"),
                "score=",
                result.get(
                    "proxy_reward_v0"
                ),
            )
        else:
            print(
                "status=",
                record["status"],
                "score=",
                score,
            )

        print(
            "advantage=",
            f"{advantage:.6f}",
            "env_reward=",
            f"{env_reward:.6f}",
        )

        print(
            "incumbent=",
            observation[
                "best_so_far"
            ][
                "mask"
            ],
            observation[
                "best_so_far"
            ][
                "proxy_reward_v0"
            ],
        )

        write_policy_snapshot(
            env,
            logits,
            baseline,
            scale,
            f"after_{query_index + 1:02d}",
        )

    final = env.observation()

    summary = {
        "algorithm":
            "reinforce_structural",

        "query_count":
            env.queries_used,

        "best_so_far":
            final[
                "best_so_far"
            ],

        "frontier_count":
            len(
                final["frontier"]
            ),

        "final_expected_boundaries":
            sum(
                sigmoid(x)
                for x in logits
            ),
    }

    (
        env.run_dir
        / "summary.json"
    ).write_text(
        json.dumps(
            summary,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    print()
    print("=" * 72)
    print(
        "REINFORCE COMPLETE"
    )
    print("=" * 72)

    print(
        "queries:",
        env.queries_used,
    )

    print(
        "best:",
        final[
            "best_so_far"
        ][
            "mask"
        ],
        final[
            "best_so_far"
        ][
            "proxy_reward_v0"
        ],
    )

    print(
        "frontier points:",
        len(
            final["frontier"]
        ),
    )


if __name__ == "__main__":
    main()
