from __future__ import annotations

import csv
import json
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

SHARED = (
    ROOT
    / "results"
    / "addpipe24_shared_seed"
    / "results.json"
)

CONTROLLED = {
    "random":
        ROOT
        / "results"
        / "addpipe24_controlled"
        / "random"
        / "results.json",

    "evolution":
        ROOT
        / "results"
        / "addpipe24_controlled"
        / "evolution"
        / "results.json",

    "claude_structural":
        ROOT
        / "results"
        / "addpipe24_controlled"
        / "claude_structural"
        / "results.json",
}

OPEN_STATE = (
    ROOT
    / "results"
    / "agent_runs"
    / "addpipe24"
    / "claude_sonnet5_open16"
    / "state.json"
)

REPRO = {
    "open_winner":
        ROOT
        / "results"
        / "repro"
        / "addpipe24_open_winner",

    "controlled_champion":
        ROOT
        / "results"
        / "repro"
        / "addpipe24_controlled_champion",

    "shared_seed":
        ROOT
        / "results"
        / "repro"
        / "addpipe24_shared_seed",
}

OUT = (
    ROOT
    / "results"
    / "analysis"
    / "addpipe24_final"
)


def load(path: Path):
    return json.loads(
        path.read_text()
    )


def valid(row):
    return (
        row.get("functional")
        and row.get("formal_ok")
        and row.get("place_route_ok")
        and row.get("area") is not None
        and row.get("wns") is not None
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


def rtl_hash(row):
    return (
        row.get(
            "fingerprint",
            {},
        ).get("rtl_sha256")
    )


def row_label(row):
    return (
        row.get("agent_name")
        or row.get("mask")
        or row.get("candidate")
        or "unknown"
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


def load_repro(directory: Path):
    rows = []

    for path in sorted(
        directory.glob(
            "run_*.txt"
        )
    ):
        rows.append(
            load(path)
        )

    if len(rows) != 3:
        raise RuntimeError(
            f"Expected 3 replications in "
            f"{directory}, got {len(rows)}"
        )

    return rows


def repro_signature(row):
    keys = (
        "functional",
        "formal_ok",
        "synthesis_ok",
        "place_route_ok",
        "area",
        "cells",
        "wns",
        "tns",
        "hold_wns",
        "setup_violations",
        "hold_violations",
        "power_w",
        "proxy_reward_v0",
    )

    return tuple(
        row.get(k)
        for k in keys
    )


def repro_summary(rows):
    first = rows[0]

    stable = all(
        repro_signature(r)
        == repro_signature(first)
        for r in rows[1:]
    )

    return {
        "stable":
            stable,

        "runs":
            len(rows),

        "all_uncached":
            all(
                r.get("cache_hit") is False
                for r in rows
            ),

        "all_valid":
            all(
                valid(r)
                for r in rows
            ),

        "evaluation_id":
            first[
                "evaluation_id"
            ],

        "rtl_sha256":
            rtl_hash(first),

        "area":
            first["area"],

        "cells":
            first["cells"],

        "wns":
            first["wns"],

        "hold_wns":
            first["hold_wns"],

        "power_w":
            first["power_w"],

        "reward":
            first[
                "proxy_reward_v0"
            ],
    }


def pct_reduction(old, new):
    return (
        (old - new)
        / old
        * 100.0
    )


def main():
    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    shared = load(
        SHARED
    )

    controlled = {
        name: load(path)
        for name, path
        in CONTROLLED.items()
    }

    open_state = load(
        OPEN_STATE
    )

    open_attempts = (
        open_state[
            "attempts"
        ]
    )

    open_successes = [
        dict(a["result"])
        for a in open_attempts
        if (
            a.get("status")
            == "success"
            and a.get("result")
        )
    ]

    for row in open_successes:
        row["_source"] = (
            "claude_open_rtl"
        )

    for row in shared:
        row["_source"] = (
            "shared_seed"
        )

    for name, rows in (
        controlled.items()
    ):
        for row in rows:
            row["_source"] = name

    shared_best = (
        best_reward(shared)
    )

    controlled_rows = (
        list(shared)
        + controlled[
            "random"
        ]
        + controlled[
            "evolution"
        ]
        + controlled[
            "claude_structural"
        ]
    )

    controlled_best = (
        best_reward(
            controlled_rows
        )
    )

    open_combined = (
        list(shared)
        + open_successes
    )

    open_best = (
        best_reward(
            open_combined
        )
    )

    # --------------------------------------------------------
    # Open-agent attempt trajectory
    # --------------------------------------------------------

    trajectory = []

    current_rows = list(
        shared
    )

    seed_reward = (
        shared_best[
            "proxy_reward_v0"
        ]
    )

    first_open_reward_improvement = (
        None
    )

    for attempt in open_attempts:
        i = (
            attempt[
                "attempt_index"
            ]
            + 1
        )

        result = (
            attempt.get(
                "result"
            )
        )

        before_front = {
            rtl_hash(r)
            or row_label(r)
            for r in pareto(
                current_rows
            )
        }

        if (
            result is not None
            and valid(result)
        ):
            current_rows.append(
                result
            )

        incumbent = (
            best_reward(
                current_rows
            )
        )

        after = pareto(
            current_rows
        )

        after_front = {
            rtl_hash(r)
            or row_label(r)
            for r in after
        }

        if (
            first_open_reward_improvement
            is None
            and incumbent[
                "proxy_reward_v0"
            ] > seed_reward
        ):
            first_open_reward_improvement = i

        trajectory.append({
            "attempt":
                i,

            "name":
                attempt["name"],

            "status":
                attempt["status"],

            "functional":
                (
                    result.get(
                        "functional"
                    )
                    if result
                    else None
                ),

            "formal_ok":
                (
                    result.get(
                        "formal_ok"
                    )
                    if result
                    else None
                ),

            "place_route_ok":
                (
                    result.get(
                        "place_route_ok"
                    )
                    if result
                    else None
                ),

            "area":
                (
                    result.get(
                        "area"
                    )
                    if result
                    else None
                ),

            "wns":
                (
                    result.get(
                        "wns"
                    )
                    if result
                    else None
                ),

            "power_w":
                (
                    result.get(
                        "power_w"
                    )
                    if result
                    else None
                ),

            "reward":
                (
                    result.get(
                        "proxy_reward_v0"
                    )
                    if result
                    else None
                ),

            "incumbent":
                row_label(
                    incumbent
                ),

            "incumbent_reward":
                incumbent[
                    "proxy_reward_v0"
                ],

            "frontier_size":
                len(after),

            "frontier_changed":
                (
                    before_front
                    != after_front
                ),
        })

    # --------------------------------------------------------
    # Deduplicate the complete observed design set by RTL hash.
    # The same generated mask may have been evaluated by both
    # evolution and structural Claude.
    # --------------------------------------------------------

    all_rows = (
        list(shared)
        + controlled[
            "random"
        ]
        + controlled[
            "evolution"
        ]
        + controlled[
            "claude_structural"
        ]
        + open_successes
    )

    grouped = defaultdict(
        list
    )

    for row in all_rows:
        key = (
            rtl_hash(row)
            or (
                row.get(
                    "candidate"
                )
                or (
                    f"{row['_source']}:"
                    f"{row_label(row)}"
                )
            )
        )

        grouped[key].append(
            row
        )

    unique_rows = []

    for key, members in (
        grouped.items()
    ):
        representative = dict(
            members[0]
        )

        representative[
            "discovery_sources"
        ] = sorted({
            r["_source"]
            for r in members
        })

        representative[
            "labels"
        ] = sorted({
            row_label(r)
            for r in members
        })

        representative[
            "_dedup_key"
        ] = key

        unique_rows.append(
            representative
        )

    combined_frontier = (
        pareto(
            unique_rows
        )
    )

    # --------------------------------------------------------
    # Replication validation
    # --------------------------------------------------------

    repro = {
        name:
            repro_summary(
                load_repro(path)
            )
        for name, path
        in REPRO.items()
    }

    seed_rep = (
        repro["shared_seed"]
    )

    open_rep = (
        repro["open_winner"]
    )

    controlled_rep = (
        repro[
            "controlled_champion"
        ]
    )

    versus_seed = {
        "area_reduction_pct":
            pct_reduction(
                seed_rep["area"],
                open_rep["area"],
            ),

        "reported_power_reduction_pct":
            pct_reduction(
                seed_rep["power_w"],
                open_rep["power_w"],
            ),

        "wns_loss_ps":
            (
                seed_rep["wns"]
                - open_rep["wns"]
            )
            * 1000.0,

        "reward_delta":
            (
                open_rep["reward"]
                - seed_rep["reward"]
            ),
    }

    versus_controlled = {
        "area_reduction_pct":
            pct_reduction(
                controlled_rep[
                    "area"
                ],
                open_rep["area"],
            ),

        "reported_power_reduction_pct":
            pct_reduction(
                controlled_rep[
                    "power_w"
                ],
                open_rep["power_w"],
            ),

        "wns_loss_ps":
            (
                controlled_rep[
                    "wns"
                ]
                - open_rep["wns"]
            )
            * 1000.0,

        "reward_delta":
            (
                open_rep["reward"]
                - controlled_rep[
                    "reward"
                ]
            ),
    }

    status_counts = defaultdict(
        int
    )

    for attempt in open_attempts:
        status_counts[
            attempt["status"]
        ] += 1

    summary = {
        "benchmark":
            "addpipe24",

        "shared_seed": {
            "candidate_count":
                len(shared),

            "best_label":
                row_label(
                    shared_best
                ),

            "best_reward":
                shared_best[
                    "proxy_reward_v0"
                ],
        },

        "controlled_search": {
            "query_budget_per_method":
                16,

            "random_final_reward":
                best_reward(
                    list(shared)
                    + controlled[
                        "random"
                    ]
                )[
                    "proxy_reward_v0"
                ],

            "evolution_final_reward":
                best_reward(
                    list(shared)
                    + controlled[
                        "evolution"
                    ]
                )[
                    "proxy_reward_v0"
                ],

            "claude_structural_final_reward":
                best_reward(
                    list(shared)
                    + controlled[
                        "claude_structural"
                    ]
                )[
                    "proxy_reward_v0"
                ],

            "overall_best_label":
                row_label(
                    controlled_best
                ),

            "overall_best_reward":
                controlled_best[
                    "proxy_reward_v0"
                ],
        },

        "open_rtl_search": {
            "proposal_budget":
                16,

            "attempts":
                len(
                    open_attempts
                ),

            "status_counts":
                dict(
                    status_counts
                ),

            "successful_physical_designs":
                len(
                    open_successes
                ),

            "first_reward_improvement_attempt":
                first_open_reward_improvement,

            "best_label":
                row_label(
                    open_best
                ),

            "best_reward":
                open_best[
                    "proxy_reward_v0"
                ],

            "frontier_points_with_shared_seed":
                len(
                    pareto(
                        open_combined
                    )
                ),
        },

        "replication": repro,

        "open_winner_vs_shared_seed":
            versus_seed,

        "open_winner_vs_controlled_champion":
            versus_controlled,

        "all_observed": {
            "raw_candidate_records":
                len(
                    all_rows
                ),

            "unique_rtl_designs":
                len(
                    unique_rows
                ),

            "combined_frontier_points":
                len(
                    combined_frontier
                ),
        },
    }

    (
        OUT
        / "summary.json"
    ).write_text(
        json.dumps(
            summary,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (
        OUT
        / "combined_frontier.json"
    ).write_text(
        json.dumps(
            combined_frontier,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (
        OUT
        / "open_trajectory.json"
    ).write_text(
        json.dumps(
            trajectory,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    with (
        OUT
        / "open_trajectory.csv"
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

    # --------------------------------------------------------
    # Human-readable console summary
    # --------------------------------------------------------

    print(
        "=" * 72
    )
    print(
        "ADDPIPE24 FINAL ANALYSIS"
    )
    print(
        "=" * 72
    )

    print(
        "shared seed best:",
        row_label(
            shared_best
        ),
        shared_best[
            "proxy_reward_v0"
        ],
    )

    print()
    print(
        "CONTROLLED SEARCH"
    )

    for name in (
        "random",
        "evolution",
        "claude_structural",
    ):
        best = best_reward(
            list(shared)
            + controlled[name]
        )

        print(
            f"  {name:<18} "
            f"{row_label(best):<28} "
            f"reward={best['proxy_reward_v0']}"
        )

    print()
    print(
        "OPEN RTL SEARCH"
    )

    print(
        "  attempts:",
        len(open_attempts),
    )

    print(
        "  successes:",
        len(open_successes),
    )

    print(
        "  failures:",
        len(open_attempts)
        - len(open_successes),
    )

    print(
        "  statuses:",
        dict(status_counts),
    )

    print(
        "  first reward improvement:",
        first_open_reward_improvement,
    )

    print(
        "  best:",
        row_label(
            open_best
        ),
        open_best[
            "proxy_reward_v0"
        ],
    )

    print()
    print(
        "REPLICATION"
    )

    for name, r in repro.items():
        print(
            f"  {name:<22} "
            f"stable={r['stable']} "
            f"uncached={r['all_uncached']} "
            f"area={r['area']} "
            f"WNS={r['wns']} "
            f"reward={r['reward']}"
        )

    print()
    print(
        "OPEN WINNER VS SHARED SEED"
    )

    print(
        "  area reduction:",
        f"{versus_seed['area_reduction_pct']:.4f}%",
    )

    print(
        "  reported power reduction:",
        f"{versus_seed['reported_power_reduction_pct']:.4f}%",
    )

    print(
        "  WNS loss:",
        f"{versus_seed['wns_loss_ps']:.3f} ps",
    )

    print(
        "  reward delta:",
        f"{versus_seed['reward_delta']:+.6f}",
    )

    print()
    print(
        "OPEN WINNER VS CONTROLLED CHAMPION"
    )

    print(
        "  area reduction:",
        f"{versus_controlled['area_reduction_pct']:.4f}%",
    )

    print(
        "  reported power reduction:",
        f"{versus_controlled['reported_power_reduction_pct']:.4f}%",
    )

    print(
        "  WNS loss:",
        f"{versus_controlled['wns_loss_ps']:.3f} ps",
    )

    print(
        "  reward delta:",
        f"{versus_controlled['reward_delta']:+.6f}",
    )

    print()
    print(
        "COMBINED UNIQUE OBSERVED FRONTIER"
    )

    for r in combined_frontier:
        sources = ",".join(
            r[
                "discovery_sources"
            ]
        )

        labels = ",".join(
            r["labels"]
        )

        print(
            f"  {labels:<34} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9} "
            f"reward={r['proxy_reward_v0']:<10} "
            f"[{sources}]"
        )

    print()
    print(
        "raw candidate records:",
        len(all_rows),
    )

    print(
        "unique RTL designs:",
        len(unique_rows),
    )

    print(
        "combined frontier points:",
        len(combined_frontier),
    )

    print()
    print(
        f"Output: {OUT}"
    )


if __name__ == "__main__":
    main()
