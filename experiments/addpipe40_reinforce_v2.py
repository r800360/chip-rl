from __future__ import annotations

import json
import random

from chiprl.benchmarks import ROOT
from chiprl.autoregressive_policy import (
    HierarchicalAutoregressiveMaskPolicy,
)
from chiprl.generate_addpipe40 import (
    write_candidate,
)
from chiprl.rl_env import (
    EDAMaskEvaluator,
    StructuralMaskEnv,
)


WIDTH = 40
BITS = 39
BUDGET = 16

POLICY_SEED = 20260921
RUN_ID = "autoregressive_v2"

FAIL_SCORE = -1000.0

SHARED = (
    ROOT
    / "results"
    / "addpipe40_shared_seed"
    / "results.json"
)


def score_of(record):
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


def write_snapshot(
    env,
    policy,
    label,
):
    (
        env.run_dir
        / f"policy_{label}.json"
    ).write_text(
        json.dumps(
            policy.snapshot(),
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )


def main():
    seeds = json.loads(
        SHARED.read_text()
    )

    if len(seeds) != 8:
        raise RuntimeError(
            "Expected exactly 8 shared seeds"
        )

    env = StructuralMaskEnv(
        benchmark="addpipe40",
        width=WIDTH,
        run_id=RUN_ID,
        budget=BUDGET,
        seed_rows=seeds,
        render_candidate=write_candidate,
        evaluate_candidate=(
            EDAMaskEvaluator(
                "addpipe40"
            )
        ),
    )

    policy = (
        HierarchicalAutoregressiveMaskPolicy(
            bits=BITS,
            seed_rows=seeds,
        )
    )

    # Deterministic replay makes interruption/resume safe.
    for record in env.state[
        "queries"
    ]:
        policy.update(
            mask=int(
                record[
                    "boundary_mask"
                ]
            ),
            score=score_of(
                record
            ),
        )

    if env.queries_used == 0:
        write_snapshot(
            env,
            policy,
            "initial",
        )

    while not env.done:
        query_index = (
            env.queries_used
        )

        rng = random.Random(
            POLICY_SEED
            + query_index
        )

        mask = policy.sample(
            rng=rng,
            seen_masks=(
                env.seen_masks()
            ),
        )

        snap = (
            policy.snapshot()
        )

        print()
        print("=" * 72)

        print(
            f"AUTOREGRESSIVE REINFORCE "
            f"QUERY {query_index + 1}/{BUDGET}"
        )

        print(
            f"mask=0x{mask:010x}"
        )

        print(
            "boundaries:",
            mask.bit_count(),
        )

        print(
            "expected boundaries:",
            f"{snap['expected_boundary_count']:.4f}",
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

        score = score_of(
            record
        )

        advantage = (
            policy.update(
                mask=mask,
                score=score,
            )
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

        write_snapshot(
            env,
            policy,
            f"after_{query_index + 1:02d}",
        )

    final = env.observation()

    (
        env.run_dir
        / "summary.json"
    ).write_text(
        json.dumps(
            {
                "algorithm":
                    "reinforce_autoregressive_v2",

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

                "final_policy":
                    policy.snapshot(),
            },
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    print()
    print("=" * 72)
    print(
        "AUTOREGRESSIVE REINFORCE COMPLETE"
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
