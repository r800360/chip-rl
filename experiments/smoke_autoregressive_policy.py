from __future__ import annotations

import json
import random

from chiprl.benchmarks import ROOT
from chiprl.autoregressive_policy import (
    HierarchicalAutoregressiveMaskPolicy,
)


def main():
    rows = json.loads(
        (
            ROOT
            / "results"
            / "addpipe32_shared_seed"
            / "results.json"
        ).read_text()
    )

    policy = (
        HierarchicalAutoregressiveMaskPolicy(
            bits=31,
            seed_rows=rows,
        )
    )

    initial = (
        policy.snapshot()
    )

    print(
        "expected boundaries:",
        initial[
            "expected_boundary_count"
        ],
    )

    print(
        "top count probabilities:"
    )

    for k, p in sorted(
        enumerate(
            initial[
                "count_probabilities"
            ]
        ),
        key=lambda x:
            -x[1],
    )[:6]:
        print(
            f"  K={k:2d}: {p:.6f}"
        )

    rng1 = random.Random(
        20260921
    )

    rng2 = random.Random(
        20260921
    )

    m1 = policy.sample(
        rng=rng1,
        seen_masks={
            int(
                r["boundary_mask"]
            )
            for r in rows
        },
    )

    m2 = policy.sample(
        rng=rng2,
        seen_masks={
            int(
                r["boundary_mask"]
            )
            for r in rows
        },
    )

    assert m1 == m2

    print(
        "deterministic sample:",
        f"0x{m1:08x}",
        "boundaries=",
        m1.bit_count(),
    )

    before = (
        policy.snapshot()
    )

    advantage = policy.update(
        mask=0x24000000,
        score=73.747818,
    )

    after = (
        policy.snapshot()
    )

    assert (
        before["count_logits"]
        != after["count_logits"]
    )

    assert (
        before["position_logits"]
        != after[
            "position_logits"
        ]
    )

    print(
        "update advantage:",
        advantage,
    )

    print(
        "expected boundaries after update:",
        after[
            "expected_boundary_count"
        ],
    )

    print(
        "PASS: autoregressive policy "
        "sampling/update semantics verified "
        "with zero new EDA evaluations."
    )


if __name__ == "__main__":
    main()
