from __future__ import annotations

import json
import shutil
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.generate_addpipe24 import (
    write_candidate,
)
from chiprl.rl_env import (
    InvalidAction,
    LookupMaskEvaluator,
    StructuralMaskEnv,
)


SHARED = (
    ROOT
    / "results"
    / "addpipe24_shared_seed"
    / "results.json"
)

CONTROLLED = [
    ROOT
    / "results"
    / "addpipe24_controlled"
    / "random"
    / "results.json",

    ROOT
    / "results"
    / "addpipe24_controlled"
    / "evolution"
    / "results.json",

    ROOT
    / "results"
    / "addpipe24_controlled"
    / "claude_structural"
    / "results.json",
]

RUN_ID = "lookup_smoke"


def load(path: Path):
    return json.loads(
        path.read_text()
    )


def main():
    shared = load(
        SHARED
    )

    measured = list(
        shared
    )

    for path in CONTROLLED:
        measured.extend(
            load(path)
        )

    # Deduplicate masks. Their physical measurements are
    # deterministic under this fixed flow.
    by_mask = {}

    for row in measured:
        by_mask.setdefault(
            int(
                row[
                    "boundary_mask"
                ]
            ),
            row,
        )

    run_dir = (
        ROOT
        / "results"
        / "rl_runs"
        / "addpipe24"
        / RUN_ID
    )

    rtl_dir = (
        ROOT
        / "rtl"
        / "rl"
        / "addpipe24"
        / RUN_ID
    )

    shutil.rmtree(
        run_dir,
        ignore_errors=True,
    )

    shutil.rmtree(
        rtl_dir,
        ignore_errors=True,
    )

    env = StructuralMaskEnv(
        benchmark="addpipe24",
        width=24,
        run_id=RUN_ID,
        budget=2,
        seed_rows=shared,
        render_candidate=write_candidate,
        evaluate_candidate=(
            LookupMaskEvaluator(
                by_mask.values()
            )
        ),
    )

    obs = env.observation()

    print(
        "initial queries:",
        obs["queries_used"],
    )

    print(
        "initial best:",
        obs[
            "best_so_far"
        ][
            "mask"
        ],
        obs[
            "best_so_far"
        ][
            "proxy_reward_v0"
        ],
    )

    _, reward1, done1, info1 = (
        env.step(
            0x100000
        )
    )

    print()
    print(
        "step 1:",
        info1,
    )

    _, reward2, done2, info2 = (
        env.step(
            0x108000
        )
    )

    print()
    print(
        "step 2:",
        info2,
    )

    duplicate_rejected = False

    try:
        env.step(
            0x100000
        )

    except (
        InvalidAction,
        RuntimeError,
    ) as exc:
        duplicate_rejected = True

        print()
        print(
            "duplicate rejected:",
            type(exc).__name__,
            str(exc),
        )

    final = env.observation()

    print()
    print(
        "final queries:",
        final[
            "queries_used"
        ],
    )

    print(
        "final best:",
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
            final[
                "frontier"
            ]
        ),
    )

    assert (
        obs[
            "best_so_far"
        ][
            "proxy_reward_v0"
        ]
        == 74.655664
    )

    assert abs(
        reward1
        - (
            74.69239
            - 74.655664
        )
    ) < 1e-12

    assert reward2 == 0.0
    assert done1 is False
    assert done2 is True
    assert duplicate_rejected
    assert env.queries_used == 2

    print()
    print(
        "PASS: RL environment semantics verified "
        "without new EDA evaluations."
    )


if __name__ == "__main__":
    main()
