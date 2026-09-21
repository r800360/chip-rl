from __future__ import annotations

import csv
import json
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

OUT = ROOT / "results" / "addpipe16_all_measured"

SOURCES = [
    (
        "random_pilot",
        ROOT
        / "results"
        / "addpipe16_random_pilot"
        / "results.json",
    ),
    (
        "online_random",
        ROOT
        / "results"
        / "addpipe16_online_compare"
        / "random.json",
    ),
    (
        "online_evolution",
        ROOT
        / "results"
        / "addpipe16_online_compare"
        / "evolution.json",
    ),
    (
        "single_split",
        ROOT
        / "results"
        / "addpipe16_single_split"
        / "results.json",
    ),
    (
        "model_guided",
        ROOT
        / "results"
        / "addpipe16_model_guided"
        / "history.json",
    ),
]

SEARCH_SPACE_SIZE = 32768


def load(path: Path):
    if not path.is_file():
        raise FileNotFoundError(path)

    value = json.loads(path.read_text())

    if not isinstance(value, list):
        raise TypeError(
            f"{path} does not contain a JSON list"
        )

    return value


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


def metric_signature(row):
    return (
        row["cells"],
        row["area"],
        row["wns"],
        row["tns"],
        row["power_w"],
    )


def same_metrics(a, b):
    sa = metric_signature(a)
    sb = metric_signature(b)

    for x, y in zip(sa, sb):
        if x is None or y is None:
            if x != y:
                return False
            continue

        if abs(float(x) - float(y)) > 1e-9:
            return False

    return True


def main():
    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    records = []
    source_stats = []

    # First occurrence of each physical architecture mask.
    unique = {}

    # Every source in which the architecture appeared.
    appearances = defaultdict(list)

    chronology = []

    global_index = 0

    for source_name, path in SOURCES:
        rows = load(path)

        new_masks = 0

        for source_index, row in enumerate(rows):
            if "boundary_mask" not in row:
                raise RuntimeError(
                    f"No boundary_mask in "
                    f"{source_name}[{source_index}]"
                )

            mask = int(row["boundary_mask"])

            appearances[mask].append({
                "source": source_name,
                "source_index": source_index,
            })

            if mask in unique:
                if not same_metrics(
                    unique[mask],
                    row,
                ):
                    raise RuntimeError(
                        "Repeated mask has different "
                        "physical metrics: "
                        f"0x{mask:04x}"
                    )

                continue

            new_masks += 1

            item = dict(row)

            item["first_source"] = source_name
            item["first_source_index"] = (
                source_index
            )
            item["discovery_index"] = (
                global_index
            )

            unique[mask] = item

            before = {
                r["boundary_mask"]
                for r in pareto_front(
                    list(unique.values())[:-1]
                )
            }

            after_front = pareto_front(
                list(unique.values())
            )

            after = {
                r["boundary_mask"]
                for r in after_front
            }

            changed_frontier = (
                before != after
            )

            chronology.append({
                "discovery_index":
                    global_index,

                "source":
                    source_name,

                "source_index":
                    source_index,

                "boundary_mask":
                    mask,

                "mask":
                    f"0x{mask:04x}",

                "blocks":
                    row["blocks"],

                "area":
                    row["area"],

                "wns":
                    row["wns"],

                "power_w":
                    row["power_w"],

                "reward":
                    row["proxy_reward_v0"],

                "changed_observed_frontier":
                    changed_frontier,
            })

            global_index += 1

        source_stats.append({
            "source": source_name,
            "records": len(rows),
            "new_unique_masks": new_masks,
        })

    rows = list(unique.values())

    # Attach all experiment appearances.
    for row in rows:
        mask = int(row["boundary_mask"])
        row["appearances"] = appearances[mask]

    frontier = pareto_front(rows)

    final_frontier_masks = {
        int(r["boundary_mask"])
        for r in frontier
    }

    for event in chronology:
        event["on_final_frontier"] = (
            event["boundary_mask"]
            in final_frontier_masks
        )

    all_valid = all(
        r["functional"]
        and r["formal_ok"]
        and r["place_route_ok"]
        for r in rows
    )

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

    summary = {
        "search_space_size":
            SEARCH_SPACE_SIZE,

        "total_evaluation_records":
            sum(
                s["records"]
                for s in source_stats
            ),

        "unique_masks_measured":
            len(rows),

        "coverage_fraction":
            len(rows)
            / SEARCH_SPACE_SIZE,

        "coverage_percent":
            100.0
            * len(rows)
            / SEARCH_SPACE_SIZE,

        "all_unique_designs_valid":
            all_valid,

        "observed_pareto_points":
            len(frontier),

        "best_reward": {
            "mask":
                f"0x{best_reward['boundary_mask']:04x}",
            "blocks":
                best_reward["blocks"],
            "reward":
                best_reward["proxy_reward_v0"],
            "area":
                best_reward["area"],
            "wns":
                best_reward["wns"],
        },

        "minimum_area": {
            "mask":
                f"0x{min_area['boundary_mask']:04x}",
            "blocks":
                min_area["blocks"],
            "area":
                min_area["area"],
            "wns":
                min_area["wns"],
        },

        "best_wns": {
            "mask":
                f"0x{best_wns['boundary_mask']:04x}",
            "blocks":
                best_wns["blocks"],
            "area":
                best_wns["area"],
            "wns":
                best_wns["wns"],
        },

        "minimum_reported_power": {
            "mask":
                f"0x{min_power['boundary_mask']:04x}",
            "blocks":
                min_power["blocks"],
            "power_w":
                min_power["power_w"],
            "area":
                min_power["area"],
            "wns":
                min_power["wns"],
        },

        "sources":
            source_stats,
    }

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

    (OUT / "chronology.json").write_text(
        json.dumps(
            chronology,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (OUT / "summary.json").write_text(
        json.dumps(
            summary,
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
            "mask",
            "blocks",
            "first_source",
            "cells",
            "area",
            "wns",
            "tns",
            "power_w",
            "reward",
        ])

        for r in sorted(
            rows,
            key=lambda x:
                int(x["boundary_mask"]),
        ):
            writer.writerow([
                f"0x{r['boundary_mask']:04x}",
                "-".join(
                    map(str, r["blocks"])
                ),
                r["first_source"],
                r["cells"],
                r["area"],
                r["wns"],
                r["tns"],
                r["power_w"],
                r["proxy_reward_v0"],
            ])

    print()
    print("====================================")
    print("ADDPIPE16 MEASURED DATASET")
    print("====================================")

    print(
        "evaluation records: ",
        summary[
            "total_evaluation_records"
        ],
    )

    print(
        "unique architectures:",
        len(rows),
    )

    print(
        "search-space coverage:",
        f"{summary['coverage_percent']:.4f}%",
    )

    print(
        "all valid:",
        all_valid,
    )

    print(
        "observed Pareto points:",
        len(frontier),
    )

    print()
    print("Source contributions:")

    for s in source_stats:
        print(
            f"  {s['source']:<20} "
            f"records={s['records']:<3} "
            f"new={s['new_unique_masks']}"
        )

    print()
    print("FINAL OBSERVED AREA/WNS FRONTIER")

    for r in frontier:
        print(
            f"  mask=0x{r['boundary_mask']:04x} "
            f"blocks={tuple(r['blocks'])!s:<14} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9} "
            f"power={r['power_w']:<12} "
            f"source={r['first_source']}"
        )

    print()
    print(
        "Best reward:",
        f"0x{best_reward['boundary_mask']:04x}",
        tuple(best_reward["blocks"]),
        best_reward["proxy_reward_v0"],
    )

    print(
        "Minimum area:",
        f"0x{min_area['boundary_mask']:04x}",
        tuple(min_area["blocks"]),
        min_area["area"],
    )

    print(
        "Best WNS:",
        f"0x{best_wns['boundary_mask']:04x}",
        tuple(best_wns["blocks"]),
        best_wns["wns"],
    )

    print()
    print(f"Output: {OUT}")


if __name__ == "__main__":
    main()
