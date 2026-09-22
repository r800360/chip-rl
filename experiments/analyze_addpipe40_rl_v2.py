from __future__ import annotations

import csv
import json
from itertools import combinations
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

SHARED = (
    ROOT
    / "results"
    / "addpipe40_shared_seed"
    / "results.json"
)

CONTROLLED = {
    "random":
        ROOT
        / "results"
        / "addpipe40_controlled"
        / "random"
        / "results.json",

    "evolution":
        ROOT
        / "results"
        / "addpipe40_controlled"
        / "evolution"
        / "results.json",

    "claude_structural":
        ROOT
        / "results"
        / "addpipe40_controlled"
        / "claude_structural"
        / "results.json",
}

RL_STATES = {
    "reinforce_v1":
        ROOT
        / "results"
        / "rl_runs"
        / "addpipe40"
        / "reinforce_v1"
        / "state.json",

    "reinforce_v2":
        ROOT
        / "results"
        / "rl_runs"
        / "addpipe40"
        / "autoregressive_v2"
        / "state.json",
}

POLICIES = {
    "reinforce_v1": {
        "initial":
            ROOT
            / "results"
            / "rl_runs"
            / "addpipe40"
            / "reinforce_v1"
            / "policy_current.json",

        "final":
            ROOT
            / "results"
            / "rl_runs"
            / "addpipe40"
            / "reinforce_v1"
            / "policy_after_16.json",
    },

    "reinforce_v2": {
        "initial":
            ROOT
            / "results"
            / "rl_runs"
            / "addpipe40"
            / "autoregressive_v2"
            / "policy_initial.json",

        "final":
            ROOT
            / "results"
            / "rl_runs"
            / "addpipe40"
            / "autoregressive_v2"
            / "policy_after_16.json",
    },
}

OUT = (
    ROOT
    / "results"
    / "analysis"
    / "addpipe40_rl_v2"
)


def load(path):
    return json.loads(
        Path(path).read_text()
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
    return f"0x{mask_of(row):010x}"


def boundaries(row):
    return mask_of(row).bit_count()


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


def best(rows):
    return max(
        (
            r
            for r in rows
            if valid(r)
        ),
        key=lambda r:
            r["proxy_reward_v0"],
    )


def normalize_rl(path):
    state = load(path)

    rows = []

    for q in state["queries"]:
        r = q.get("result")

        if r is None:
            continue

        row = dict(r)

        row["boundary_mask"] = int(
            q["boundary_mask"]
        )

        row["mask"] = q["mask"]
        row["query_index"] = int(
            q["query_index"]
        )

        rows.append(row)

    return rows


def analyze(name, seeds, queries):
    seed_best = best(seeds)

    seed_reward = float(
        seed_best["proxy_reward_v0"]
    )

    archive = list(seeds)

    trajectory = []
    first_improvement = None

    for i, row in enumerate(
        queries,
        start=1,
    ):
        before = {
            mask_of(r)
            for r in pareto(archive)
        }

        if valid(row):
            archive.append(row)

        incumbent = best(archive)

        after_front = pareto(
            archive
        )

        after = {
            mask_of(r)
            for r in after_front
        }

        if (
            first_improvement is None
            and incumbent[
                "proxy_reward_v0"
            ] > seed_reward
        ):
            first_improvement = i

        trajectory.append({
            "algorithm":
                name,

            "query":
                i,

            "query_mask":
                mask_text(row),

            "query_boundaries":
                boundaries(row),

            "query_area":
                row.get("area"),

            "query_wns":
                row.get("wns"),

            "query_reward":
                row.get(
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

            "frontier_changed":
                before != after,

            "query_on_frontier":
                mask_of(row) in after,
        })

    final_best = best(archive)
    final_front = pareto(
        archive
    )

    seed_masks = {
        mask_of(r)
        for r in seeds
    }

    new_front = [
        r
        for r in final_front
        if mask_of(r)
        not in seed_masks
    ]

    return {
        "summary": {
            "algorithm":
                name,

            "queries":
                len(queries),

            "first_improvement":
                first_improvement,

            "final_best_mask":
                mask_text(
                    final_best
                ),

            "final_best_reward":
                final_best[
                    "proxy_reward_v0"
                ],

            "reward_delta":
                final_best[
                    "proxy_reward_v0"
                ]
                - seed_reward,

            "mean_boundaries":
                sum(
                    boundaries(r)
                    for r in queries
                )
                / len(queries),

            "min_boundaries":
                min(
                    boundaries(r)
                    for r in queries
                ),

            "max_boundaries":
                max(
                    boundaries(r)
                    for r in queries
                ),

            "frontier_points":
                len(
                    final_front
                ),

            "new_frontier_members": [
                {
                    "mask":
                        mask_text(r),

                    "boundaries":
                        boundaries(r),

                    "area":
                        r["area"],

                    "wns":
                        r["wns"],

                    "reward":
                        r[
                            "proxy_reward_v0"
                        ],
                }
                for r in new_front
            ],
        },

        "trajectory":
            trajectory,
    }


def policy_summary():
    out = {}

    for name, paths in (
        POLICIES.items()
    ):
        if not (
            paths["initial"].is_file()
            and paths["final"].is_file()
        ):
            continue

        initial = load(
            paths["initial"]
        )

        final = load(
            paths["final"]
        )

        if name == "reinforce_v1":
            out[name] = {
                "initial_expected_boundaries":
                    initial[
                        "expected_boundaries"
                    ],

                "final_expected_boundaries":
                    final[
                        "expected_boundaries"
                    ],
            }

        else:
            out[name] = {
                "initial_expected_boundaries":
                    initial[
                        "expected_boundary_count"
                    ],

                "final_expected_boundaries":
                    final[
                        "expected_boundary_count"
                    ],

                "initial_count_probabilities":
                    initial[
                        "count_probabilities"
                    ],

                "final_count_probabilities":
                    final[
                        "count_probabilities"
                    ],
            }

    return out


def main():
    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    seeds = load(
        SHARED
    )

    if len(seeds) != 8:
        raise RuntimeError(
            "Expected eight shared seeds"
        )

    runs = {
        name: load(path)
        for name, path
        in CONTROLLED.items()
    }

    for name, path in (
        RL_STATES.items()
    ):
        runs[name] = (
            normalize_rl(path)
        )

    for name, rows in (
        runs.items()
    ):
        if len(rows) != 16:
            raise RuntimeError(
                f"{name}: expected 16 "
                f"queries, got {len(rows)}"
            )

    analyses = {
        name: analyze(
            name,
            seeds,
            rows,
        )
        for name, rows
        in runs.items()
    }

    # ----------------------------------------------
    # Pairwise mask overlap.
    # ----------------------------------------------

    overlap = {}

    for a, b in combinations(
        runs,
        2,
    ):
        common = sorted(
            {
                mask_of(r)
                for r in runs[a]
            }
            &
            {
                mask_of(r)
                for r in runs[b]
            }
        )

        overlap[
            f"{a}__{b}"
        ] = [
            f"0x{x:010x}"
            for x in common
        ]

    # ----------------------------------------------
    # Deduplicated union frontier.
    # ----------------------------------------------

    by_mask = {}
    discovery = {}

    for row in seeds:
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
            ).add(name)

    union = pareto(
        list(
            by_mask.values()
        )
    )

    union_json = []

    for row in union:
        m = mask_of(row)

        union_json.append({
            "mask":
                f"0x{m:010x}",

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

    trajectories = []

    for analysis in (
        analyses.values()
    ):
        trajectories.extend(
            analysis[
                "trajectory"
            ]
        )

    result = {
        "benchmark":
            "addpipe40",

        "shared_seed": {
            "best_mask":
                mask_text(
                    best(seeds)
                ),

            "best_reward":
                best(seeds)[
                    "proxy_reward_v0"
                ],

            "frontier_points":
                len(
                    pareto(seeds)
                ),
        },

        "algorithms": {
            name:
                a["summary"]
            for name, a
            in analyses.items()
        },

        "pairwise_overlap":
            overlap,

        "policies":
            policy_summary(),

        "unique_observed_masks":
            len(by_mask),

        "union_frontier":
            union_json,
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
            trajectories,
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
            union_json,
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
                trajectories[0].keys()
            ),
        )

        writer.writeheader()
        writer.writerows(
            trajectories
        )

    print("=" * 78)
    print(
        "ADDPIPE40 FIVE-WAY CONTROLLED ANALYSIS"
    )
    print("=" * 78)

    seed = best(seeds)

    print(
        "seed:",
        mask_text(seed),
        seed["proxy_reward_v0"],
    )

    print()

    order = (
        "random",
        "evolution",
        "reinforce_v1",
        "reinforce_v2",
        "claude_structural",
    )

    for name in order:
        s = analyses[
            name
        ][
            "summary"
        ]

        first = (
            "-"
            if s[
                "first_improvement"
            ] is None
            else str(
                s[
                    "first_improvement"
                ]
            )
        )

        print(
            f"{name:<20} "
            f"best={s['final_best_reward']:.6f} "
            f"mask={s['final_best_mask']} "
            f"first={first:>2} "
            f"delta={s['reward_delta']:+.6f} "
            f"meanK={s['mean_boundaries']:.2f} "
            f"frontier={s['frontier_points']}"
        )

    print()
    print(
        "PAIRWISE OVERLAP"
    )
    print("-" * 78)

    for pair, masks in (
        overlap.items()
    ):
        if masks:
            print(
                f"{pair:<44} "
                f"{masks}"
            )

    print()
    print(
        "POLICY EXPECTED BOUNDARIES"
    )
    print("-" * 78)

    for name, p in (
        policy_summary().items()
    ):
        print(
            f"{name:<20} "
            f"{p['initial_expected_boundaries']:.4f}"
            f" -> "
            f"{p['final_expected_boundaries']:.4f}"
        )

    print()
    print(
        "UNION FRONTIER"
    )
    print("-" * 78)

    for row in union_json:
        print(
            f"{row['mask']} "
            f"K={row['boundaries']:<2} "
            f"area={row['area']:<9} "
            f"WNS={row['wns']:<9} "
            f"reward={row['reward']:<10} "
            f"{row['discovered_by']}"
        )

    print()
    print(
        "unique masks:",
        len(by_mask),
    )

    print(
        "union frontier:",
        len(union_json),
    )

    print()
    print(
        "Output:",
        OUT,
    )


if __name__ == "__main__":
    main()
