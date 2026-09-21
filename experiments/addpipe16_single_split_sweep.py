from __future__ import annotations

import csv
import json
from pathlib import Path

from chiprl.evaluate import evaluate
from chiprl.generate_addpipe16 import (
    CandidateSpec,
    write_candidate,
)


ROOT = Path(__file__).resolve().parents[1]

TAG = "addpipe16_single_split"
GEN_DIR = ROOT / "rtl" / "generated" / TAG
OUT_DIR = ROOT / "results" / TAG


def dominates(a, b):
    return (
        a["area"] <= b["area"]
        and a["wns"] >= b["wns"]
        and (
            a["area"] < b["area"]
            or a["wns"] > b["wns"]
        )
    )


def pareto_front(rows):
    valid = [
        r for r in rows
        if (
            r["functional"]
            and r["formal_ok"]
            and r["place_route_ok"]
        )
    ]

    return sorted(
        [
            r for r in valid
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
    GEN_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    OUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    results = []

    # split=0 means no boundary: (16,)
    # split=k means: (k, 16-k)
    for split in range(16):

        if split == 0:
            mask = 0
        else:
            mask = 1 << (split - 1)

        spec = CandidateSpec(mask)

        path = (
            GEN_DIR
            / f"split_{split:02d}.v"
        )

        write_candidate(spec, path)

        print()
        print(
            f"=== split={split:2d} "
            f"mask=0x{mask:04x} "
            f"blocks={spec.blocks} ==="
        )

        result = dict(
            evaluate(
                path.relative_to(ROOT),
                benchmark="addpipe16",
            )
        )

        result["split"] = split
        result["boundary_mask"] = mask
        result["blocks"] = list(spec.blocks)

        results.append(result)

        print(
            f"cache={result['cache_hit']} "
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

    with (OUT_DIR / "results.csv").open(
        "w",
        newline="",
    ) as f:

        writer = csv.writer(f)

        writer.writerow([
            "split",
            "mask",
            "blocks",
            "cells",
            "area",
            "wns",
            "tns",
            "power_w",
            "reward",
            "cache_hit",
        ])

        for r in results:
            writer.writerow([
                r["split"],
                f"0x{r['boundary_mask']:04x}",
                "-".join(
                    map(str, r["blocks"])
                ),
                r["cells"],
                r["area"],
                r["wns"],
                r["tns"],
                r["power_w"],
                r["proxy_reward_v0"],
                r["cache_hit"],
            ])

    best_reward = max(
        results,
        key=lambda r:
            r["proxy_reward_v0"],
    )

    min_area = min(
        results,
        key=lambda r:
            r["area"],
    )

    best_wns = max(
        results,
        key=lambda r:
            r["wns"],
    )

    print()
    print("================================")
    print("SINGLE-SPLIT SWEEP COMPLETE")
    print("================================")

    print(
        "best reward:",
        best_reward["blocks"],
        "area=",
        best_reward["area"],
        "WNS=",
        best_reward["wns"],
        "reward=",
        best_reward["proxy_reward_v0"],
    )

    print(
        "minimum area:",
        min_area["blocks"],
        "area=",
        min_area["area"],
        "WNS=",
        min_area["wns"],
    )

    print(
        "best WNS:",
        best_wns["blocks"],
        "area=",
        best_wns["area"],
        "WNS=",
        best_wns["wns"],
    )

    print()
    print("Pareto frontier:")

    for r in frontier:
        print(
            f"  split={r['split']:2d} "
            f"blocks={tuple(r['blocks'])!s:<10} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9} "
            f"power={r['power_w']} "
            f"reward={r['proxy_reward_v0']}"
        )


if __name__ == "__main__":
    main()
