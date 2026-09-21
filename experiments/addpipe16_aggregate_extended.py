from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

OUT = (
    ROOT
    / "results"
    / "addpipe16_extended"
)

SOURCES = [
    (
        "structural",
        ROOT
        / "results"
        / "addpipe16_all_measured"
        / "results.json",
    ),
    (
        "llm_rtl_round1",
        ROOT
        / "results"
        / "addpipe16_llm_rtl"
        / "round1"
        / "results.json",
    ),
    (
        "llm_rtl_round2",
        ROOT
        / "results"
        / "addpipe16_llm_rtl"
        / "round2"
        / "results.json",
    ),
    (
        "llm_rtl_round3",
        ROOT
        / "results"
        / "addpipe16_llm_rtl"
        / "round3"
        / "results.json",
    ),
    (
        "llm_rtl_round4",
        ROOT
        / "results"
        / "addpipe16_llm_rtl"
        / "round4"
        / "results.json",
    ),
]


def load(path: Path):
    if not path.is_file():
        raise FileNotFoundError(path)

    value = json.loads(path.read_text())

    if not isinstance(value, list):
        raise RuntimeError(
            f"{path} is not a JSON list"
        )

    return value


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


def label(row):
    if "proposal_name" in row:
        return row["proposal_name"]

    if "blocks" in row:
        return str(
            tuple(row["blocks"])
        )

    return row["candidate"]


def main():
    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    rows = []
    source_counts = {}

    for source, path in SOURCES:
        source_rows = load(path)

        source_counts[source] = len(
            source_rows
        )

        for original in source_rows:
            row = dict(original)
            row["aggregate_source"] = source
            rows.append(row)

    if not all(
        r["functional"]
        and r["formal_ok"]
        and r["place_route_ok"]
        for r in rows
    ):
        raise RuntimeError(
            "Extended dataset contains "
            "an invalid candidate."
        )

    frontier = pareto_front(rows)

    best_reward = max(
        rows,
        key=lambda r:
            r["proxy_reward_v0"],
    )

    min_area = min(
        rows,
        key=lambda r:
            r["area"],
    )

    best_wns = max(
        rows,
        key=lambda r:
            r["wns"],
    )

    min_power = min(
        rows,
        key=lambda r:
            r["power_w"],
    )

    (OUT / "results.json").write_text(
        json.dumps(
            rows,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (OUT / "pareto.json").write_text(
        json.dumps(
            frontier,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    summary = {
        "candidate_records": len(rows),
        "all_valid": True,
        "pareto_points": len(frontier),

        "best_reward": {
            "label": label(best_reward),
            "area": best_reward["area"],
            "wns": best_reward["wns"],
            "power_w": best_reward["power_w"],
            "reward":
                best_reward["proxy_reward_v0"],
        },

        "minimum_area": {
            "label": label(min_area),
            "area": min_area["area"],
            "wns": min_area["wns"],
            "power_w": min_area["power_w"],
        },

        "best_wns": {
            "label": label(best_wns),
            "area": best_wns["area"],
            "wns": best_wns["wns"],
        },

        "minimum_power": {
            "label": label(min_power),
            "area": min_power["area"],
            "wns": min_power["wns"],
            "power_w": min_power["power_w"],
        },

        "source_counts": source_counts,
    }

    (OUT / "summary.json").write_text(
        json.dumps(
            summary,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    print()
    print("====================================")
    print("EXTENDED ADDPIPE16 DATASET")
    print("====================================")

    print(
        "candidate records:",
        len(rows),
    )

    print(
        "all valid:",
        summary["all_valid"],
    )

    print(
        "Pareto points:",
        len(frontier),
    )

    print()
    print("Sources:")

    for source, count in source_counts.items():
        print(
            f"  {source:<20} {count}"
        )

    print()
    print("OBSERVED AREA/WNS FRONTIER")

    for r in frontier:
        print(
            f"  {label(r):<24} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9} "
            f"power={r['power_w']:<12} "
            f"source={r['aggregate_source']}"
        )

    print()
    print(
        "Best scalar reward:",
        label(best_reward),
        best_reward["proxy_reward_v0"],
    )

    print(
        "Minimum area:",
        label(min_area),
        min_area["area"],
    )

    print(
        "Minimum reported power:",
        label(min_power),
        min_power["power_w"],
    )

    print(
        "Best WNS:",
        label(best_wns),
        best_wns["wns"],
    )

    print()
    print(f"Output: {OUT}")


if __name__ == "__main__":
    main()
