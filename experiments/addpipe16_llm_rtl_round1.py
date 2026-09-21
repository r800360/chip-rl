from __future__ import annotations

import csv
import json
from pathlib import Path

from chiprl.evaluate import evaluate


ROOT = Path(__file__).resolve().parents[1]

CANDIDATE_DIR = (
    ROOT
    / "rtl"
    / "llm"
    / "addpipe16_round1"
)

OUT = (
    ROOT
    / "results"
    / "addpipe16_llm_rtl"
    / "round1"
)

OLD_DATA = (
    ROOT
    / "results"
    / "addpipe16_all_measured"
    / "results.json"
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


def pareto_front(rows):
    valid = [
        r
        for r in rows
        if (
            r.get("functional")
            and r.get("formal_ok")
            and r.get("place_route_ok")
            and r.get("area") is not None
            and r.get("wns") is not None
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
    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    candidates = sorted(
        CANDIDATE_DIR.glob("*.v")
    )

    results = []

    for i, path in enumerate(candidates, 1):
        rel = path.relative_to(ROOT)

        print()
        print(
            f"=== {i}/{len(candidates)} "
            f"{path.name} ==="
        )

        result = dict(
            evaluate(
                rel,
                benchmark="addpipe16",
            )
        )

        result["proposal_name"] = path.stem
        result["proposal_type"] = "llm_rtl"
        result["proposer"] = "GPT-5.6 Sol"

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

    old_rows = json.loads(
        OLD_DATA.read_text()
    )

    combined = old_rows + results

    old_front = pareto_front(
        old_rows
    )

    combined_front = pareto_front(
        combined
    )

    old_ids = {
        (
            r["area"],
            r["wns"],
            r["power_w"],
        )
        for r in old_front
    }

    new_front_entries = [
        r
        for r in combined_front
        if (
            r["area"],
            r["wns"],
            r["power_w"],
        )
        not in old_ids
    ]

    (OUT / "results.json").write_text(
        json.dumps(
            results,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (OUT / "combined_pareto.json").write_text(
        json.dumps(
            combined_front,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    with (OUT / "results.csv").open(
        "w",
        newline="",
    ) as f:

        writer = csv.writer(f)

        writer.writerow([
            "proposal",
            "functional",
            "formal",
            "routed",
            "cells",
            "area",
            "wns",
            "tns",
            "power_w",
            "reward",
            "runtime_s",
        ])

        for r in results:
            writer.writerow([
                r["proposal_name"],
                r["functional"],
                r["formal_ok"],
                r["place_route_ok"],
                r["cells"],
                r["area"],
                r["wns"],
                r["tns"],
                r["power_w"],
                r["proxy_reward_v0"],
                r["runtime_s"],
            ])

    print()
    print("================================")
    print("LLM RTL ROUND 1 COMPLETE")
    print("================================")

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

    min_power = min(
        results,
        key=lambda r:
            r["power_w"],
    )

    print(
        "best reward:",
        best_reward["proposal_name"],
        best_reward["proxy_reward_v0"],
    )

    print(
        "minimum area:",
        min_area["proposal_name"],
        min_area["area"],
    )

    print(
        "best WNS:",
        best_wns["proposal_name"],
        best_wns["wns"],
    )

    print(
        "minimum power:",
        min_power["proposal_name"],
        min_power["power_w"],
    )

    print()
    print(
        "new entries on combined "
        "observed area/WNS frontier:",
        len(new_front_entries),
    )

    for r in new_front_entries:
        label = (
            r.get("proposal_name")
            or str(r.get("blocks"))
        )

        print(
            f"  {label:<24} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9} "
            f"power={r['power_w']}"
        )

    print()
    print("COMBINED OBSERVED FRONTIER")

    for r in combined_front:
        if "proposal_name" in r:
            label = (
                "LLM:"
                + r["proposal_name"]
            )
        else:
            label = (
                "mask:"
                + f"0x{int(r['boundary_mask']):04x}"
            )

        print(
            f"  {label:<28} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9} "
            f"power={r['power_w']}"
        )

    print()
    print(f"Results: {OUT}")


if __name__ == "__main__":
    main()
