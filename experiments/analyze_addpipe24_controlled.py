from __future__ import annotations

import csv
import json
from itertools import combinations
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

SHARED = (
    ROOT
    / "results"
    / "addpipe24_shared_seed"
    / "results.json"
)

BASE = (
    ROOT
    / "results"
    / "addpipe24_controlled"
)

SOURCES = {
    "random":
        BASE / "random" / "results.json",

    "evolution":
        BASE / "evolution" / "results.json",

    "claude_structural":
        BASE / "claude_structural" / "results.json",
}

OUT = (
    ROOT
    / "results"
    / "analysis"
    / "addpipe24_controlled"
)


def load(path: Path):
    return json.loads(path.read_text())


def mask_of(row):
    return int(row["boundary_mask"])


def mask_text(row):
    return f"0x{mask_of(row):06x}"


def dominates(a, b):
    return (
        a["area"] <= b["area"]
        and a["wns"] >= b["wns"]
        and (
            a["area"] < b["area"]
            or a["wns"] > b["wns"]
        )
    )


def pareto(rows):
    return sorted(
        [
            row
            for row in rows
            if not any(
                dominates(other, row)
                for other in rows
                if other is not row
            )
        ],
        key=lambda r: (
            r["area"],
            -r["wns"],
        ),
    )


def best_reward(rows):
    return max(
        rows,
        key=lambda r:
            r["proxy_reward_v0"],
    )


def block_count(row):
    return len(row["blocks"])


def hamming_distance(a, b):
    return (
        int(a) ^ int(b)
    ).bit_count()


def main():
    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    shared = load(SHARED)

    runs = {
        name: load(path)
        for name, path in SOURCES.items()
    }

    shared_best = best_reward(shared)
    shared_reward = (
        shared_best["proxy_reward_v0"]
    )

    print()
    print("=" * 72)
    print("ADDPIPE24 CONTROLLED SEARCH ANALYSIS")
    print("=" * 72)

    print(
        "shared candidates:",
        len(shared),
    )

    print(
        "shared best:",
        mask_text(shared_best),
        tuple(shared_best["blocks"]),
        shared_reward,
    )

    print(
        "shared frontier points:",
        len(pareto(shared)),
    )

    print()

    trajectory_rows = []
    summaries = {}

    for name, queries in runs.items():
        combined = list(shared)

        first_improvement = None
        incumbent = shared_best

        frontier_new_masks = set()

        for i, query in enumerate(
            queries,
            start=1,
        ):
            before_ids = {
                mask_of(r)
                for r in pareto(combined)
            }

            combined.append(query)

            incumbent = best_reward(
                combined
            )

            after_front = pareto(
                combined
            )

            after_ids = {
                mask_of(r)
                for r in after_front
            }

            if (
                first_improvement is None
                and incumbent[
                    "proxy_reward_v0"
                ] > shared_reward
            ):
                first_improvement = i

            if mask_of(query) in after_ids:
                frontier_new_masks.add(
                    mask_of(query)
                )

            trajectory_rows.append({
                "algorithm": name,
                "budget": i,
                "query_mask":
                    mask_text(query),
                "query_blocks":
                    str(
                        tuple(
                            query["blocks"]
                        )
                    ),
                "query_reward":
                    query[
                        "proxy_reward_v0"
                    ],
                "incumbent_mask":
                    mask_text(incumbent),
                "incumbent_reward":
                    incumbent[
                        "proxy_reward_v0"
                    ],
                "improvement_over_seed":
                    incumbent[
                        "proxy_reward_v0"
                    ] - shared_reward,
                "frontier_size":
                    len(after_front),
                "query_on_frontier":
                    mask_of(query)
                    in after_ids,
                "frontier_changed":
                    before_ids != after_ids,
            })

        final_front = pareto(
            combined
        )

        new_best = max(
            queries,
            key=lambda r:
                r["proxy_reward_v0"],
        )

        masks = {
            mask_of(r)
            for r in queries
        }

        summaries[name] = {
            "new_queries":
                len(queries),

            "unique_masks":
                len(masks),

            "first_seed_improvement_query":
                first_improvement,

            "best_new_mask":
                mask_text(new_best),

            "best_new_blocks":
                new_best["blocks"],

            "best_new_reward":
                new_best[
                    "proxy_reward_v0"
                ],

            "final_incumbent_mask":
                mask_text(
                    best_reward(
                        combined
                    )
                ),

            "final_incumbent_reward":
                best_reward(
                    combined
                )[
                    "proxy_reward_v0"
                ],

            "reward_improvement_over_seed":
                best_reward(
                    combined
                )[
                    "proxy_reward_v0"
                ] - shared_reward,

            "combined_frontier_points":
                len(final_front),

            "new_final_frontier_members":
                [
                    {
                        "mask": mask_text(r),
                        "blocks": r["blocks"],
                        "area": r["area"],
                        "wns": r["wns"],
                        "reward":
                            r[
                                "proxy_reward_v0"
                            ],
                    }
                    for r in final_front
                    if mask_of(r)
                    not in {
                        mask_of(x)
                        for x in shared
                    }
                ],

            "mean_block_count":
                sum(
                    block_count(r)
                    for r in queries
                )
                / len(queries),

            "min_block_count":
                min(
                    block_count(r)
                    for r in queries
                ),

            "max_block_count":
                max(
                    block_count(r)
                    for r in queries
                ),
        }

    overlap = {}

    for a, b in combinations(
        runs.keys(),
        2,
    ):
        a_masks = {
            mask_of(r)
            for r in runs[a]
        }

        b_masks = {
            mask_of(r)
            for r in runs[b]
        }

        common = sorted(
            a_masks & b_masks
        )

        overlap[f"{a}__{b}"] = [
            f"0x{x:06x}"
            for x in common
        ]

    print("FINAL SUMMARY")
    print("-" * 72)

    for name, s in summaries.items():
        first = (
            s[
                "first_seed_improvement_query"
            ]
        )

        print(
            f"{name:<20} "
            f"best="
            f"{s['final_incumbent_reward']:.6f} "
            f"mask="
            f"{s['final_incumbent_mask']} "
            f"first_improve="
            f"{first if first is not None else '-':>2} "
            f"frontier="
            f"{s['combined_frontier_points']}"
        )

    print()
    print("PAIRWISE QUERY OVERLAP")
    print("-" * 72)

    for pair, masks in overlap.items():
        print(
            f"{pair:<38} "
            f"{len(masks)} "
            f"{masks}"
        )

    print()
    print("FINAL FRONTIER MEMBERS BY METHOD")
    print("-" * 72)

    for name, s in summaries.items():
        print()
        print(name)

        for r in s[
            "new_final_frontier_members"
        ]:
            print(
                f"  {r['mask']} "
                f"{tuple(r['blocks'])!s:<20} "
                f"area={r['area']:<9} "
                f"WNS={r['wns']:<9} "
                f"reward={r['reward']}"
            )

    output = {
        "shared_best": {
            "mask":
                mask_text(
                    shared_best
                ),
            "blocks":
                shared_best[
                    "blocks"
                ],
            "reward":
                shared_reward,
        },
        "algorithms":
            summaries,
        "pairwise_overlap":
            overlap,
    }

    (
        OUT
        / "summary.json"
    ).write_text(
        json.dumps(
            output,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (
        OUT
        / "trajectory.json"
    ).write_text(
        json.dumps(
            trajectory_rows,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    with (
        OUT
        / "trajectory.csv"
    ).open(
        "w",
        newline="",
    ) as f:
        writer = csv.DictWriter(
            f,
            fieldnames=list(
                trajectory_rows[0].keys()
            ),
        )

        writer.writeheader()
        writer.writerows(
            trajectory_rows
        )

    print()
    print(
        f"Output: {OUT}"
    )


if __name__ == "__main__":
    main()
