from __future__ import annotations

import csv
import json
import random
from dataclasses import asdict
from pathlib import Path

from chiprl.evaluate import evaluate
from chiprl.generate_v2 import (
    all_specs,
    write_candidate,
)


ROOT = Path(__file__).resolve().parents[1]

SEED = 20260920
NUM_SAMPLES = 30


def dominates(a, b):
    return (
        a["area"] <= b["area"]
        and
        a["wns"] >= b["wns"]
        and
        (
            a["area"] < b["area"]
            or
            a["wns"] > b["wns"]
        )
    )


def pareto_front(results):
    valid = [
        r
        for r in results
        if (
            r["functional"]
            and
            r["place_route_ok"]
            and
            r["area"] is not None
            and
            r["wns"] is not None
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


def ppa_signature(r):
    if (
        r["area"] is None
        or r["wns"] is None
    ):
        return None

    return (
        r["cells"],
        round(float(r["area"]), 6),
        round(float(r["wns"]), 6),
        round(float(r["power_w"] or 0), 12),
    )


def main():
    rng = random.Random(SEED)

    specs = all_specs()

    print(
        f"Design space: {len(specs)} legal candidates"
    )

    rng.shuffle(specs)
    specs = specs[:NUM_SAMPLES]

    tag = "strict_v2_20260920"

    generated_dir = (
        ROOT
        / "rtl"
        / "generated"
        / tag
    )

    generated_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    results = []

    for i, spec in enumerate(specs):
        path = (
            generated_dir
            / f"candidate_{i:03d}.v"
        )

        write_candidate(spec, path)

        rel = path.relative_to(ROOT)

        print()
        print(
            f"=== {i + 1}/{len(specs)} "
            f"{rel} ==="
        )

        print(json.dumps(asdict(spec)))

        result = evaluate(rel)

        result["search_spec"] = asdict(spec)

        results.append(result)

        print(
            f"functional={result['functional']} "
            f"route={result['place_route_ok']} "
            f"cells={result['cells']} "
            f"area={result['area']} "
            f"wns={result['wns']} "
            f"power={result['power_w']} "
            f"reward={result['proxy_reward_v0']}"
        )

    out_dir = (
        ROOT
        / "results"
        / "random_search"
        / tag
    )

    out_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    (out_dir / "results.json").write_text(
        json.dumps(
            results,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    with (
        out_dir / "results.csv"
    ).open("w", newline="") as f:
        writer = csv.writer(f)

        writer.writerow(
            [
                "candidate",
                "family",
                "param",
                "hold_style",
                "functional",
                "routed",
                "cells",
                "area",
                "wns",
                "tns",
                "power_w",
                "runtime_s",
                "proxy_reward_v0",
            ]
        )

        for r in results:
            s = r["search_spec"]

            writer.writerow(
                [
                    r["candidate"],
                    s["family"],
                    s["param"],
                    s["hold_style"],
                    r["functional"],
                    r["place_route_ok"],
                    r["cells"],
                    r["area"],
                    r["wns"],
                    r["tns"],
                    r["power_w"],
                    r["runtime_s"],
                    r["proxy_reward_v0"],
                ]
            )

    frontier = pareto_front(results)

    (out_dir / "pareto.json").write_text(
        json.dumps(
            frontier,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    signatures = {}

    for r in results:
        sig = ppa_signature(r)

        if sig is None:
            continue

        signatures.setdefault(
            sig,
            []
        ).append(r)

    print()
    print("==============================")
    print("RANDOM SEARCH V2 COMPLETE")
    print("==============================")

    print(
        f"sampled: {len(results)} / "
        f"{len(all_specs())}"
    )

    print(
        "functional: "
        f"{sum(r['functional'] for r in results)}"
    )

    print(
        "routed: "
        f"{sum(r['place_route_ok'] for r in results)}"
    )

    print(
        f"unique PPA signatures: "
        f"{len(signatures)}"
    )

    print(
        f"pareto points: "
        f"{len(frontier)}"
    )

    print("\nPareto frontier:")

    for r in frontier:
        s = r["search_spec"]

        print(
            f"  {s['family']:<13} "
            f"p={s['param']:<2} "
            f"{s['hold_style']:<14} "
            f"cells={r['cells']:<4} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9} "
            f"power={r['power_w']}"
        )

    print(
        f"\nResults: {out_dir}"
    )


if __name__ == "__main__":
    main()
