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

    # The frozen addpipe32 seed evidence strongly favors
    # sparse masks.  This regression check ensures that the
    # count pseudocount is total prior mass rather than a
    # per-K prior whose total grows with benchmark width.
    assert (
        initial[
            "expected_boundary_count"
        ]
        < 2.0
    )

    assert (
        sum(
            initial[
                "count_probabilities"
            ][:2]
        )
        > 0.90
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

    frozen_count_logits = list(
        before["count_logits"]
    )

    frozen_position_logits = list(
        before["position_logits"]
    )

    advantage = policy.update(
        mask=0x24000000,
        score=73.747818,
    )

    after = (
        policy.snapshot()
    )

    # The policy itself must update.
    assert (
        frozen_count_logits
        != after["count_logits"]
    )

    assert (
        frozen_position_logits
        != after[
            "position_logits"
        ]
    )

    # And the previously returned snapshot must remain an
    # immutable historical value rather than aliasing the
    # policy's live lists.
    assert (
        before["count_logits"]
        == frozen_count_logits
    )

    assert (
        before["position_logits"]
        == frozen_position_logits
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
