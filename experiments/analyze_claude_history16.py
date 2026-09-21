from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

STARTING_DATA = (
    ROOT
    / "results"
    / "addpipe16_extended"
    / "results.json"
)

STATE = (
    ROOT
    / "results"
    / "agent_runs"
    / "claude_sonnet5_history16"
    / "state.json"
)

WINNER_REPRO = (
    ROOT
    / "results"
    / "repro"
    / "ripple2_sklansky14"
)

HISTORICAL_REPRO = (
    ROOT
    / "results"
    / "repro"
    / "historical_champion"
)

OUT = (
    ROOT
    / "results"
    / "analysis"
    / "claude_sonnet5_history16"
)


def load_json(path: Path):
    return json.loads(path.read_text())


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


def identity(row):
    evaluation_id = row.get(
        "evaluation_id"
    )

    if evaluation_id:
        return evaluation_id

    return (
        row.get("candidate"),
        row["area"],
        row["wns"],
        row["power_w"],
    )


def label(row):
    if row.get("agent_name"):
        return row["agent_name"]

    if row.get("proposal_name"):
        return row["proposal_name"]

    if row.get("blocks") is not None:
        return str(
            tuple(row["blocks"])
        )

    return row.get(
        "candidate",
        "unknown",
    )


def frontier_ids(rows):
    return {
        identity(r)
        for r in pareto(rows)
    }


def load_repro_dir(path: Path):
    rows = []

    for p in sorted(
        path.glob("run_*.txt")
    ):
        rows.append(
            json.loads(
                p.read_text()
            )
        )

    return rows


def identical_metrics(rows):
    keys = [
        "area",
        "cells",
        "wns",
        "tns",
        "hold_wns",
        "power_w",
        "proxy_reward_v0",
    ]

    if not rows:
        return False

    first = {
        key: rows[0][key]
        for key in keys
    }

    return all(
        {
            key: row[key]
            for key in keys
        }
        == first
        for row in rows[1:]
    )


def compact(row):
    return {
        "label": label(row),
        "candidate": row.get(
            "candidate"
        ),
        "evaluation_id": row.get(
            "evaluation_id"
        ),
        "cells": row["cells"],
        "area": row["area"],
        "wns": row["wns"],
        "power_w": row["power_w"],
        "reward":
            row["proxy_reward_v0"],
    }


def main():
    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    starting_rows = load_json(
        STARTING_DATA
    )

    state = load_json(
        STATE
    )

    attempts = state["attempts"]

    rows = list(starting_rows)

    starting_frontier = pareto(
        rows
    )

    starting_best = max(
        rows,
        key=lambda r:
            r["proxy_reward_v0"],
    )

    incumbent_reward = (
        starting_best[
            "proxy_reward_v0"
        ]
    )

    trajectory = []

    for attempt in attempts:
        result = attempt.get(
            "result"
        )

        before_frontier_ids = (
            frontier_ids(rows)
        )

        before_frontier_size = len(
            before_frontier_ids
        )

        new_scalar_best = False

        if result and valid(result):
            previous_best = (
                incumbent_reward
            )

            rows.append(result)

            if (
                result[
                    "proxy_reward_v0"
                ]
                > previous_best
            ):
                new_scalar_best = True
                incumbent_reward = (
                    result[
                        "proxy_reward_v0"
                    ]
                )

        after_frontier_ids = (
            frontier_ids(rows)
        )

        changed_frontier = (
            before_frontier_ids
            != after_frontier_ids
        )

        entered_frontier = (
            bool(result)
            and identity(result)
            in after_frontier_ids
        )

        trajectory.append({
            "attempt":
                attempt[
                    "attempt_index"
                ] + 1,

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

            "cells":
                (
                    result.get("cells")
                    if result
                    else None
                ),

            "area":
                (
                    result.get("area")
                    if result
                    else None
                ),

            "wns":
                (
                    result.get("wns")
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

            "new_scalar_best":
                new_scalar_best,

            "entered_frontier":
                entered_frontier,

            "changed_frontier":
                changed_frontier,

            "frontier_size_before":
                before_frontier_size,

            "frontier_size_after":
                len(
                    after_frontier_ids
                ),

            "incumbent_reward_after":
                incumbent_reward,
        })

    final_frontier = pareto(
        rows
    )

    final_ids = {
        identity(r)
        for r in final_frontier
    }

    for event, attempt in zip(
        trajectory,
        attempts,
    ):
        result = attempt.get(
            "result"
        )

        event[
            "on_final_frontier"
        ] = (
            bool(result)
            and identity(result)
            in final_ids
        )

    final_best = max(
        rows,
        key=lambda r:
            r["proxy_reward_v0"],
    )

    winner_repro = load_repro_dir(
        WINNER_REPRO
    )

    historical_repro = (
        load_repro_dir(
            HISTORICAL_REPRO
        )
    )

    winner_metric_stable = (
        identical_metrics(
            winner_repro
        )
    )

    historical_metric_stable = (
        identical_metrics(
            historical_repro
        )
    )

    winner = winner_repro[0]
    historical = (
        historical_repro[0]
    )

    area_reduction_pct = (
        100.0
        * (
            historical["area"]
            - winner["area"]
        )
        / historical["area"]
    )

    power_reduction_pct = (
        100.0
        * (
            historical["power_w"]
            - winner["power_w"]
        )
        / historical["power_w"]
    )

    wns_loss_ps = (
        1000.0
        * (
            historical["wns"]
            - winner["wns"]
        )
    )

    reward_delta = (
        winner["proxy_reward_v0"]
        - historical[
            "proxy_reward_v0"
        ]
    )

    changed_attempts = [
        e["attempt"]
        for e in trajectory
        if e["changed_frontier"]
    ]

    final_agent_members = [
        e["name"]
        for e in trajectory
        if e["on_final_frontier"]
    ]

    pass_counts = {
        "attempts": len(attempts),

        "functional": sum(
            bool(e["functional"])
            for e in trajectory
        ),

        "formal": sum(
            bool(e["formal_ok"])
            for e in trajectory
        ),

        "place_route": sum(
            bool(
                e["place_route_ok"]
            )
            for e in trajectory
        ),
    }

    summary = {
        "run_id":
            state["run_id"],

        "budget":
            state["budget"],

        "starting_candidate_records":
            len(starting_rows),

        "starting_frontier_points":
            len(starting_frontier),

        "final_candidate_records":
            len(rows),

        "final_frontier_points":
            len(final_frontier),

        "pass_counts":
            pass_counts,

        "frontier_changing_attempts":
            changed_attempts,

        "final_agent_frontier_members":
            final_agent_members,

        "starting_best":
            compact(
                starting_best
            ),

        "final_best":
            compact(
                final_best
            ),

        "replication": {
            "winner_runs":
                len(winner_repro),

            "historical_runs":
                len(
                    historical_repro
                ),

            "winner_metrics_identical":
                winner_metric_stable,

            "historical_metrics_identical":
                historical_metric_stable,

            "area_reduction_pct":
                area_reduction_pct,

            "power_reduction_pct":
                power_reduction_pct,

            "wns_loss_ps":
                wns_loss_ps,

            "reward_delta":
                reward_delta,
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
        / "final_frontier.json"
    ).write_text(
        json.dumps(
            [
                compact(r)
                for r in final_frontier
            ],
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

    print()
    print(
        "===================================="
    )
    print(
        "CLAUDE SONNET 5 HISTORY16 ANALYSIS"
    )
    print(
        "===================================="
    )

    print(
        "starting candidates:",
        len(starting_rows),
    )

    print(
        "starting frontier:",
        len(starting_frontier),
    )

    print(
        "attempts:",
        len(attempts),
    )

    print(
        "functional pass:",
        pass_counts["functional"],
    )

    print(
        "formal pass:",
        pass_counts["formal"],
    )

    print(
        "P&R pass:",
        pass_counts["place_route"],
    )

    print(
        "frontier-changing attempts:",
        changed_attempts,
    )

    print(
        "final agent frontier members:",
        len(final_agent_members),
    )

    for name in final_agent_members:
        print(
            "  ",
            name,
        )

    print()
    print(
        "starting best reward:",
        starting_best[
            "proxy_reward_v0"
        ],
        label(starting_best),
    )

    print(
        "final best reward:",
        final_best[
            "proxy_reward_v0"
        ],
        label(final_best),
    )

    print()
    print(
        "winner replication stable:",
        winner_metric_stable,
    )

    print(
        "historical replication stable:",
        historical_metric_stable,
    )

    print(
        "area reduction:",
        f"{area_reduction_pct:.4f}%",
    )

    print(
        "reported power reduction:",
        f"{power_reduction_pct:.4f}%",
    )

    print(
        "WNS loss:",
        f"{wns_loss_ps:.3f} ps",
    )

    print(
        "reward improvement:",
        f"{reward_delta:.6f}",
    )

    print()
    print(
        "FINAL OBSERVED FRONTIER"
    )

    for r in final_frontier:
        source = (
            "agent"
            if r.get(
                "agent_name"
            )
            else "starting"
        )

        print(
            f"  {label(r):<30} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9} "
            f"reward="
            f"{r['proxy_reward_v0']:<10} "
            f"{source}"
        )

    print()
    print(
        f"Output: {OUT}"
    )


if __name__ == "__main__":
    main()
