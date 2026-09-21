from __future__ import annotations

import csv
import json
import random
from dataclasses import asdict
from pathlib import Path

from chiprl.evaluate import evaluate
from chiprl.generate import (
    CandidateSpec,
    GENERATORS,
    write_candidate,
)


ROOT = Path(__file__).resolve().parents[1]

SEED = 20260920
NUM_SAMPLES = 10


def dominates(a, b):
    """
    Pareto dominance:
      smaller area is better
      larger WNS is better
    """
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

    frontier = []

    for r in valid:
        if not any(
            dominates(other, r)
            for other in valid
            if other is not r
        ):
            frontier.append(r)

    return sorted(
        frontier,
        key=lambda r: (
            r["area"],
            -r["wns"],
        ),
    )


def main():
    rng = random.Random(SEED)

    specs = [
        CandidateSpec(
            architecture=architecture,
            gated_output=gated,
        )
        for architecture in GENERATORS
        for gated in (True, False)
    ]

    rng.shuffle(specs)

    specs = specs[:NUM_SAMPLES]

    generated_dir = (
        ROOT
        / "rtl"
        / "generated"
        / f"random_{SEED}"
    )

    generated_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    results = []

    for index, spec in enumerate(specs):
        path = (
            generated_dir
            / f"candidate_{index:03d}.v"
        )

        write_candidate(
            spec,
            path,
        )

        rel = path.relative_to(ROOT)

        print()
        print(
            f"=== {index + 1}/{len(specs)} "
            f"{rel} ==="
        )

        print(
            json.dumps(
                asdict(spec),
                indent=2,
            )
        )

        result = evaluate(
            rel,
            cache=True,
            clean=False,
        )

        result["search_spec"] = asdict(
            spec
        )

        results.append(result)

        print(
            f"functional="
            f"{result['functional']} "
            f"route="
            f"{result['place_route_ok']} "
            f"area="
            f"{result['area']} "
            f"wns="
            f"{result['wns']} "
            f"reward="
            f"{result['proxy_reward_v0']}"
        )

    out_dir = (
        ROOT
        / "results"
        / "random_search"
        / str(SEED)
    )

    out_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    json_path = (
        out_dir
        / "results.json"
    )

    json_path.write_text(
        json.dumps(
            results,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    csv_path = (
        out_dir
        / "results.csv"
    )

    with csv_path.open(
        "w",
        newline="",
    ) as f:
        writer = csv.writer(f)

        writer.writerow(
            [
                "candidate",
                "architecture",
                "gated_output",
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
                    s["architecture"],
                    s["gated_output"],
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

    frontier_path = (
        out_dir
        / "pareto.json"
    )

    frontier_path.write_text(
        json.dumps(
            frontier,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    print("\n==============================")
    print("SEARCH COMPLETE")
    print("==============================")

    print(
        f"evaluated: {len(results)}"
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
        f"pareto points: {len(frontier)}"
    )

    print("\nPareto frontier:")

    for r in frontier:
        spec = r["search_spec"]

        print(
            f"  {spec['architecture']:<14} "
            f"gated={str(spec['gated_output']):<5} "
            f"area={r['area']:<10} "
            f"WNS={r['wns']:<10} "
            f"reward={r['proxy_reward_v0']}"
        )

    print()
    print(f"JSON: {json_path}")
    print(f"CSV:  {csv_path}")
    print(f"Pareto: {frontier_path}")


if __name__ == "__main__":
    main()
