from __future__ import annotations

import csv
import json
from itertools import combinations
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

SHARED = (
    ROOT
    / "results"
    / "addpipe32_shared_seed"
    / "results.json"
)

CONTROLLED = {
    "random":
        ROOT
        / "results"
        / "addpipe32_controlled"
        / "random"
        / "results.json",

    "evolution":
        ROOT
        / "results"
        / "addpipe32_controlled"
        / "evolution"
        / "results.json",

    "claude_structural":
        ROOT
        / "results"
        / "addpipe32_controlled"
        / "claude_structural"
        / "results.json",
}

REINFORCE_STATE = (
    ROOT
    / "results"
    / "rl_runs"
    / "addpipe32"
    / "reinforce_v1"
    / "state.json"
)

REINFORCE_INITIAL_POLICY = (
    ROOT
    / "results"
    / "rl_runs"
    / "addpipe32"
    / "reinforce_v1"
    / "policy_current.json"
)

REINFORCE_FINAL_POLICY = (
    ROOT
    / "results"
    / "rl_runs"
    / "addpipe32"
    / "reinforce_v1"
    / "policy_after_16.json"
)

OUT = (
    ROOT
    / "results"
    / "analysis"
    / "addpipe32_controlled"
)


def load(path: Path):
    return json.loads(
        path.read_text()
    )


def valid(row):
    return bool(
        row.get("functional")
        and row.get("formal_ok")
        and row.get("place_route_ok")
        and row.get("area") is not None
        and row.get("wns") is not None
        and row.get("proxy_reward_v0") is not None
    )


def mask_of(row):
    return int(
        row["boundary_mask"]
    )


def mask_text(row):
    return f"0x{mask_of(row):08x}"


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
    rows = [
        r
        for r in rows
        if valid(r)
    ]

    return sorted(
        [
            r
            for r in rows
            if not any(
                dominates(other, r)
                for other in rows
                if other is not r
            )
        ],
        key=lambda r: (
            r["area"],
            -r["wns"],
        ),
    )


def best_reward(rows):
    return max(
        (
            r
            for r in rows
            if valid(r)
        ),
        key=lambda r:
            r["proxy_reward_v0"],
    )


def boundary_count(row):
    return mask_of(row).bit_count()


def normalize_reinforce(state):
    rows = []

    for query in state[
        "queries"
    ]:
        result = query.get(
            "result"
        )

        if not result:
            continue

        row = dict(result)

        row[
            "boundary_mask"
        ] = int(
            query[
                "boundary_mask"
            ]
        )

        row["mask"] = (
            f"0x{row['boundary_mask']:08x}"
        )

        row["query_index"] = int(
            query[
                "query_index"
            ]
        )

        row["algorithm"] = (
            "reinforce"
        )

        row[
            "query_status"
        ] = query[
            "status"
        ]

        rows.append(
            row
        )

    return rows


def analyze_algorithm(
    name,
    shared,
    queries,
):
    seed_best = best_reward(
        shared
    )

    seed_reward = seed_best[
        "proxy_reward_v0"
    ]

    current = list(
        shared
    )

    first_improvement = None
    trajectory = []

    for i, query in enumerate(
        queries,
        start=1,
    ):
        before = {
            mask_of(r)
            for r in pareto(
                current
            )
        }

        if valid(query):
            current.append(
                query
            )

        incumbent = (
            best_reward(
                current
            )
        )

        after_front = pareto(
            current
        )

        after = {
            mask_of(r)
            for r in after_front
        }

        if (
            first_improvement
            is None
            and incumbent[
                "proxy_reward_v0"
            ] > seed_reward
        ):
            first_improvement = i

        trajectory.append({
            "algorithm":
                name,

            "budget":
                i,

            "query_mask":
                mask_text(
                    query
                ),

            "query_boundaries":
                boundary_count(
                    query
                ),

            "query_area":
                query.get(
                    "area"
                ),

            "query_wns":
                query.get(
                    "wns"
                ),

            "query_reward":
                query.get(
                    "proxy_reward_v0"
                ),

            "incumbent_mask":
                mask_text(
                    incumbent
                ),

            "incumbent_reward":
                incumbent[
                    "proxy_reward_v0"
                ],

            "improvement_over_seed":
                incumbent[
                    "proxy_reward_v0"
                ]
                - seed_reward,

            "frontier_size":
                len(
                    after_front
                ),

            "query_on_frontier":
                (
                    mask_of(query)
                    in after
                ),

            "frontier_changed":
                before != after,
        })

    final_frontier = pareto(
        current
    )

    final_best = best_reward(
        current
    )

    query_masks = {
        mask_of(r)
        for r in queries
    }

    seed_masks = {
        mask_of(r)
        for r in shared
    }

    new_frontier = [
        r
        for r in final_frontier
        if mask_of(r)
        not in seed_masks
    ]

    query_rewards = [
        float(
            r[
                "proxy_reward_v0"
            ]
        )
        for r in queries
        if valid(r)
    ]

    return {
        "summary": {
            "algorithm":
                name,

            "queries":
                len(
                    queries
                ),

            "unique_query_masks":
                len(
                    query_masks
                ),

            "first_seed_improvement_query":
                first_improvement,

            "final_incumbent_mask":
                mask_text(
                    final_best
                ),

            "final_incumbent_reward":
                final_best[
                    "proxy_reward_v0"
                ],

            "reward_improvement_over_seed":
                final_best[
                    "proxy_reward_v0"
                ]
                - seed_reward,

            "combined_frontier_points":
                len(
                    final_frontier
                ),

            "new_final_frontier_members":
                [
                    {
                        "mask":
                            mask_text(r),

                        "area":
                            r["area"],

                        "wns":
                            r["wns"],

                        "reward":
                            r[
                                "proxy_reward_v0"
                            ],

                        "boundaries":
                            boundary_count(
                                r
                            ),
                    }
                    for r
                    in new_frontier
                ],

            "mean_query_boundaries":
                (
                    sum(
                        boundary_count(r)
                        for r in queries
                    )
                    / len(queries)
                ),

            "minimum_query_boundaries":
                min(
                    boundary_count(r)
                    for r in queries
                ),

            "maximum_query_boundaries":
                max(
                    boundary_count(r)
                    for r in queries
                ),

            "best_new_query_reward":
                max(
                    query_rewards
                ),
        },

        "trajectory":
            trajectory,

        "final_frontier":
            final_frontier,
    }


def main():
    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    shared = load(
        SHARED
    )

    runs = {
        name: load(path)
        for name, path
        in CONTROLLED.items()
    }

    reinforce_state = load(
        REINFORCE_STATE
    )

    runs[
        "reinforce"
    ] = normalize_reinforce(
        reinforce_state
    )

    if len(shared) != 8:
        raise RuntimeError(
            "Expected 8 shared seeds"
        )

    for name, rows in (
        runs.items()
    ):
        if len(rows) != 16:
            raise RuntimeError(
                f"{name}: expected "
                f"16 queries, got {len(rows)}"
            )

    seed_best = best_reward(
        shared
    )

    analyses = {
        name:
            analyze_algorithm(
                name,
                shared,
                rows,
            )
        for name, rows
        in runs.items()
    }

    # --------------------------------------------------
    # Cross-method overlap
    # --------------------------------------------------

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
            a_masks
            & b_masks
        )

        overlap[
            f"{a}__{b}"
        ] = [
            f"0x{x:08x}"
            for x in common
        ]

    # --------------------------------------------------
    # Union frontier across all structural experiments
    # --------------------------------------------------

    by_mask = {}

    discovery = {}

    for row in shared:
        m = mask_of(row)

        by_mask.setdefault(
            m,
            row,
        )

        discovery.setdefault(
            m,
            set(),
        ).add(
            "shared_seed"
        )

    for name, rows in (
        runs.items()
    ):
        for row in rows:
            m = mask_of(row)

            by_mask.setdefault(
                m,
                row,
            )

            discovery.setdefault(
                m,
                set(),
            ).add(
                name
            )

    union_frontier = pareto(
        list(
            by_mask.values()
        )
    )

    union_frontier_json = []

    for row in union_frontier:
        m = mask_of(row)

        union_frontier_json.append({
            "mask":
                f"0x{m:08x}",

            "boundaries":
                m.bit_count(),

            "area":
                row["area"],

            "wns":
                row["wns"],

            "reward":
                row[
                    "proxy_reward_v0"
                ],

            "discovered_by":
                sorted(
                    discovery[m]
                ),
        })

    # --------------------------------------------------
    # REINFORCE policy movement
    # --------------------------------------------------

    policy_analysis = None

    if (
        REINFORCE_INITIAL_POLICY.is_file()
        and REINFORCE_FINAL_POLICY.is_file()
    ):
        initial = load(
            REINFORCE_INITIAL_POLICY
        )

        final = load(
            REINFORCE_FINAL_POLICY
        )

        p0 = initial[
            "probabilities"
        ]

        p1 = final[
            "probabilities"
        ]

        changes = [
            {
                "bit":
                    bit,

                "initial_probability":
                    p0[bit],

                "final_probability":
                    p1[bit],

                "delta":
                    p1[bit]
                    - p0[bit],
            }
            for bit in range(
                len(p0)
            )
        ]

        policy_analysis = {
            "initial_expected_boundaries":
                initial[
                    "expected_boundaries"
                ],

            "final_expected_boundaries":
                final[
                    "expected_boundaries"
                ],

            "largest_probability_increases":
                sorted(
                    changes,
                    key=lambda x:
                        -x["delta"],
                )[:8],

            "largest_probability_decreases":
                sorted(
                    changes,
                    key=lambda x:
                        x["delta"],
                )[:8],

            "final_highest_probability_bits":
                sorted(
                    [
                        {
                            "bit": i,
                            "probability": p,
                        }
                        for i, p
                        in enumerate(p1)
                    ],
                    key=lambda x:
                        -x[
                            "probability"
                        ],
                )[:10],
        }

    summaries = {
        name:
            data["summary"]
        for name, data
        in analyses.items()
    }

    trajectory = []

    for data in (
        analyses.values()
    ):
        trajectory.extend(
            data[
                "trajectory"
            ]
        )

    result = {
        "benchmark":
            "addpipe32",

        "shared_seed": {
            "count":
                len(shared),

            "frontier_points":
                len(
                    pareto(
                        shared
                    )
                ),

            "best_mask":
                mask_text(
                    seed_best
                ),

            "best_reward":
                seed_best[
                    "proxy_reward_v0"
                ],

            "best_area":
                seed_best[
                    "area"
                ],

            "best_wns":
                seed_best[
                    "wns"
                ],
        },

        "algorithms":
            summaries,

        "pairwise_query_overlap":
            overlap,

        "reinforce_policy":
            policy_analysis,

        "unique_observed_masks":
            len(
                by_mask
            ),

        "union_frontier_points":
            len(
                union_frontier
            ),

        "union_frontier":
            union_frontier_json,
    }

    (
        OUT
        / "summary.json"
    ).write_text(
        json.dumps(
            result,
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
            trajectory,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (
        OUT
        / "union_frontier.json"
    ).write_text(
        json.dumps(
            union_frontier_json,
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
                trajectory[0].keys()
            ),
        )

        writer.writeheader()
        writer.writerows(
            trajectory
        )

    print(
        "=" * 72
    )

    print(
        "ADDPIPE32 CONTROLLED + RL ANALYSIS"
    )

    print(
        "=" * 72
    )

    print(
        "shared best:",
        mask_text(
            seed_best
        ),
        seed_best[
            "proxy_reward_v0"
        ],
    )

    print(
        "shared frontier:",
        len(
            pareto(
                shared
            )
        ),
    )

    print()
    print(
        "FINAL SUMMARY"
    )

    print(
        "-" * 72
    )

    order = (
        "random",
        "evolution",
        "reinforce",
        "claude_structural",
    )

    for name in order:
        s = summaries[
            name
        ]

        first = s[
            "first_seed_improvement_query"
        ]

        first_text = (
            "-"
            if first is None
            else str(first)
        )

        print(
            f"{name:<20} "
            f"best="
            f"{s['final_incumbent_reward']:.6f} "
            f"mask="
            f"{s['final_incumbent_mask']} "
            f"first_improve="
            f"{first_text:>2} "
            f"frontier="
            f"{s['combined_frontier_points']} "
            f"mean_boundaries="
            f"{s['mean_query_boundaries']:.2f}"
        )

    print()
    print(
        "PAIRWISE QUERY OVERLAP"
    )

    print(
        "-" * 72
    )

    for pair, masks in (
        overlap.items()
    ):
        print(
            f"{pair:<42} "
            f"{len(masks):2d} "
            f"{masks}"
        )

    if policy_analysis:
        print()
        print(
            "REINFORCE POLICY"
        )

        print(
            "-" * 72
        )

        print(
            "expected boundaries:",
            f"{policy_analysis['initial_expected_boundaries']:.4f}",
            "->",
            f"{policy_analysis['final_expected_boundaries']:.4f}",
        )

        print(
            "largest increases:"
        )

        for row in policy_analysis[
            "largest_probability_increases"
        ][:5]:
            print(
                f"  bit {row['bit']:2d}: "
                f"{row['initial_probability']:.4f}"
                f" -> "
                f"{row['final_probability']:.4f} "
                f"({row['delta']:+.4f})"
            )

    print()
    print(
        "UNION OBSERVED FRONTIER"
    )

    print(
        "-" * 72
    )

    for row in union_frontier_json:
        print(
            f"  {row['mask']} "
            f"boundaries={row['boundaries']:<2} "
            f"area={row['area']:<9} "
            f"WNS={row['wns']:<9} "
            f"reward={row['reward']:<10} "
            f"{row['discovered_by']}"
        )

    print()
    print(
        "unique observed masks:",
        len(
            by_mask
        ),
    )

    print(
        "union frontier points:",
        len(
            union_frontier
        ),
    )

    print()
    print(
        f"Output: {OUT}"
    )


if __name__ == "__main__":
    main()
