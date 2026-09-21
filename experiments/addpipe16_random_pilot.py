from __future__ import annotations

import csv
import json
import random
from pathlib import Path

from chiprl.evaluate import evaluate
from chiprl.generate_addpipe16 import (
    CandidateSpec,
    MAX_MASK,
    mask_from_blocks,
    write_candidate,
)


ROOT = Path(__file__).resolve().parents[1]

SEED = 20260920
N = 16

TAG = "addpipe16_random_pilot"

GEN_DIR = (
    ROOT
    / "rtl"
    / "generated"
    / TAG
)

OUT_DIR = (
    ROOT
    / "results"
    / TAG
)


def dominates(a, b):
    return (
        a["area"] <= b["area"]
        and a["wns"] >= b["wns"]
        and (
            a["area"] < b["area"]
            or
            a["wns"] > b["wns"]
        )
    )


def pareto_front(rows):
    valid = [
        r
        for r in rows
        if (
            r["functional"]
            and r["formal_ok"]
            and r["place_route_ok"]
            and r["area"] is not None
            and r["wns"] is not None
        )
    ]

    return sorted(
        [
            r
            for r in valid
            if not any(
                dominates(other, r)
                for other in valid
                if other is not r
            )
        ],
        key=lambda r: (
            r["area"],
            -r["wns"],
        ),
    )


def main():
    rng = random.Random(SEED)

    anchor_blocks = [
        (16,),
        (8, 8),
        (4, 4, 4, 4),
        (2, 2, 2, 2, 2, 2, 2, 2),
        (1,) * 16,
        (3, 5, 2, 6),
    ]

    masks = {
        mask_from_blocks(blocks)
        for blocks in anchor_blocks
    }

    while len(masks) < N:
        masks.add(
            rng.randint(0, MAX_MASK)
        )

    masks = list(masks)

    # Deterministic order.
    rng.shuffle(masks)

    GEN_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    OUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    results = []

    print(
        f"Search space: {MAX_MASK + 1:,} "
        "possible partitions"
    )

    print(
        f"Pilot budget: {len(masks)} "
        "physical evaluations"
    )

    for i, mask in enumerate(masks):
        spec = CandidateSpec(mask)

        path = (
            GEN_DIR
            / f"candidate_{i:03d}.v"
        )

        write_candidate(
            spec,
            path,
        )

        rel = path.relative_to(ROOT)

        print()
        print(
            f"=== {i + 1}/{len(masks)} "
            f"mask=0x{mask:04x} "
            f"blocks={spec.blocks} ==="
        )

        result = evaluate(
            rel,
            benchmark="addpipe16",
        )

        result["boundary_mask"] = mask
        result["blocks"] = list(spec.blocks)

        results.append(result)

        print(
            f"functional={result['functional']} "
            f"formal={result['formal_ok']} "
            f"route={result['place_route_ok']} "
            f"cells={result['cells']} "
            f"area={result['area']} "
            f"wns={result['wns']} "
            f"power={result['power_w']} "
            f"reward={result['proxy_reward_v0']}"
        )

    frontier = pareto_front(results)

    (OUT_DIR / "results.json").write_text(
        json.dumps(
            results,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (OUT_DIR / "pareto.json").write_text(
        json.dumps(
            frontier,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    with (
        OUT_DIR / "results.csv"
    ).open("w", newline="") as f:

        writer = csv.writer(f)

        writer.writerow([
            "mask",
            "blocks",
            "functional",
            "formal",
            "routed",
            "cells",
            "area",
            "wns",
            "tns",
            "power_w",
            "runtime_s",
            "reward",
        ])

        for r in results:
            writer.writerow([
                f"0x{r['boundary_mask']:04x}",
                "-".join(
                    map(str, r["blocks"])
                ),
                r["functional"],
                r["formal_ok"],
                r["place_route_ok"],
                r["cells"],
                r["area"],
                r["wns"],
                r["tns"],
                r["power_w"],
                r["runtime_s"],
                r["proxy_reward_v0"],
            ])

    print()
    print("==============================")
    print("ADDPIPE16 RANDOM PILOT COMPLETE")
    print("==============================")

    print(
        f"evaluated: {len(results)}"
    )

    print(
        "formal passes: "
        f"{sum(r['formal_ok'] for r in results)}"
    )

    print(
        "routed: "
        f"{sum(r['place_route_ok'] for r in results)}"
    )

    print(
        f"pareto points: {len(frontier)}"
    )

    print("\nPareto frontier:")

    for r in frontier:
        print(
            f"  mask=0x{r['boundary_mask']:04x} "
            f"blocks={tuple(r['blocks'])!s:<35} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9} "
            f"power={r['power_w']} "
            f"reward={r['proxy_reward_v0']}"
        )

    print()
    print(f"Results: {OUT_DIR}")


if __name__ == "__main__":
    main()
