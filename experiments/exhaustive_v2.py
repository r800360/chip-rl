from __future__ import annotations

import csv
import json
from dataclasses import asdict
from pathlib import Path

from chiprl.evaluate import evaluate
from chiprl.generate_v2 import all_specs, write_candidate


ROOT = Path(__file__).resolve().parents[1]

TAG = "exhaustive_v2"
GENERATED = ROOT / "rtl" / "generated" / TAG
OUT = ROOT / "results" / "design_space_v2"


def physical_signature(r):
    if not (
        r["functional"]
        and r["place_route_ok"]
        and r["area"] is not None
        and r["wns"] is not None
    ):
        return None

    return (
        int(r["cells"]),
        round(float(r["area"]), 6),
        round(float(r["wns"]), 6),
        round(float(r["power_w"]), 12)
        if r["power_w"] is not None
        else None,
    )


def dominates(a, b):
    return (
        a["area"] <= b["area"]
        and a["wns"] >= b["wns"]
        and (
            a["area"] < b["area"]
            or a["wns"] > b["wns"]
        )
    )


def unique_physical_results(results):
    unique = {}

    for r in results:
        sig = physical_signature(r)

        if sig is None:
            continue

        unique.setdefault(sig, r)

    return list(unique.values())


def pareto_front(results):
    valid = unique_physical_results(results)

    front = []

    for r in valid:
        if not any(
            dominates(other, r)
            for other in valid
            if other is not r
        ):
            front.append(r)

    return sorted(
        front,
        key=lambda r: (
            r["area"],
            -r["wns"],
        ),
    )


def main():
    GENERATED.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)

    specs = all_specs()
    results = []

    print(f"Evaluating complete space: {len(specs)} candidates")

    for i, spec in enumerate(specs):
        filename = (
            f"{spec.family}_p{spec.param}_"
            f"{spec.hold_style}.v"
        )

        path = GENERATED / filename
        write_candidate(spec, path)

        rel = path.relative_to(ROOT)

        print(
            f"\n=== {i + 1}/{len(specs)} "
            f"{spec.family} p={spec.param} "
            f"{spec.hold_style} ==="
        )

        result = evaluate(rel)
        result["search_spec"] = asdict(spec)

        results.append(result)

        print(
            f"cache={result['cache_hit']} "
            f"area={result['area']} "
            f"wns={result['wns']} "
            f"cells={result['cells']} "
            f"reward={result['proxy_reward_v0']}"
        )

    unique = unique_physical_results(results)
    frontier = pareto_front(results)

    (OUT / "results.json").write_text(
        json.dumps(results, indent=2, sort_keys=True) + "\n"
    )

    (OUT / "pareto.json").write_text(
        json.dumps(frontier, indent=2, sort_keys=True) + "\n"
    )

    with (OUT / "results.csv").open("w", newline="") as f:
        writer = csv.writer(f)

        writer.writerow([
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
            "reward",
            "cache_hit",
        ])

        for r in results:
            s = r["search_spec"]

            writer.writerow([
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
                r["proxy_reward_v0"],
                r["cache_hit"],
            ])

    # Check whether coding style changes physical results.
    by_structure = {}

    for r in results:
        s = r["search_spec"]
        key = (s["family"], s["param"])

        by_structure.setdefault(key, []).append(
            physical_signature(r)
        )

    style_sensitive = {
        key: values
        for key, values in by_structure.items()
        if len(set(values)) > 1
    }

    print("\n================================")
    print("COMPLETE DESIGN SPACE")
    print("================================")
    print(f"RTL candidates:        {len(results)}")
    print(f"Physical signatures:   {len(unique)}")
    print(f"Pareto points:         {len(frontier)}")
    print(
        "Style-sensitive structures: "
        f"{len(style_sensitive)}"
    )

    print("\nUnique physical Pareto frontier:")

    for r in frontier:
        s = r["search_spec"]

        print(
            f"  {s['family']:<13} "
            f"p={s['param']:<2} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9} "
            f"cells={r['cells']:<4} "
            f"power={r['power_w']}"
        )

    if style_sensitive:
        print("\nHold-style differences detected:")

        for key in style_sensitive:
            print(" ", key)

    else:
        print(
            "\nAll hold-style variants collapsed "
            "to identical physical metrics."
        )


if __name__ == "__main__":
    main()
