from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from chiprl.evaluate import evaluate
from chiprl.generate_addpipe36 import (
    MAX_MASK,
    blocks_from_mask,
    write_candidate,
)


ROOT = Path(__file__).resolve().parents[1]

SHARED = (
    ROOT
    / "results"
    / "addpipe36_shared_seed"
    / "results.json"
)

OUT = (
    ROOT
    / "results"
    / "addpipe36_controlled"
    / "claude_structural"
)

RTL_DIR = (
    ROOT
    / "rtl"
    / "generated"
    / "addpipe36_controlled"
    / "claude_structural"
)

ADAPTER = (
    ROOT
    / "adapters"
    / "claude_addpipe36_structural.py"
)

BUDGET = 16


def pareto(rows):
    def dominates(a, b):
        return (
            a["area"] <= b["area"]
            and a["wns"] >= b["wns"]
            and (
                a["area"] < b["area"]
                or a["wns"] > b["wns"]
            )
        )

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


def compact(row):
    return {
        "mask":
            row.get(
                "mask",
                f"0x{int(row['boundary_mask']):09x}",
            ),

        "blocks":
            row["blocks"],

        "area":
            row["area"],

        "wns":
            row["wns"],

        "power_w":
            row["power_w"],

        "proxy_reward_v0":
            row[
                "proxy_reward_v0"
            ],
    }


def main():
    if (
        OUT
        / "results.json"
    ).exists():
        raise SystemExit(
            "Claude structural run already complete; "
            "refusing to overwrite."
        )

    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    RTL_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    shared = json.loads(
        SHARED.read_text()
    )

    results = []

    seen = {
        int(r["boundary_mask"])
        for r in shared
    }

    rejected_proposals = []

    for query_index in range(
        BUDGET
    ):
        while True:
            combined = (
                shared
                + results
            )

            frontier = pareto(
                combined
            )

            observation = {
                "benchmark":
                    "addpipe36",

                "query_number":
                    query_index + 1,

                "query_budget":
                    BUDGET,

                "action_space": {
                    "type":
                        "35-bit boundary mask",

                    "minimum":
                        "0x000000",

                    "maximum":
                        "0x7ffffffff",

                    "size":
                        MAX_MASK + 1,

                    "interpretation":
                        (
                            "bit i = 1 inserts a block "
                            "boundary after datapath bit i"
                        ),
                },

                "objective":
                    (
                        "proxy_reward_v0 = "
                        "-0.001 * area + 10 * WNS"
                    ),

                "shared_seed_measurements": [
                    compact(r)
                    for r in shared
                ],

                "own_previous_queries": [
                    compact(r)
                    for r in results
                ],

                "current_frontier": [
                    compact(r)
                    for r in frontier
                ],

                "already_measured_masks": [
                    f"0x{x:09x}"
                    for x in sorted(
                        seen
                    )
                ],
            }

            obs_path = (
                OUT
                / (
                    f"observation_"
                    f"{query_index:02d}.json"
                )
            )

            obs_path.write_text(
                json.dumps(
                    observation,
                    indent=2,
                    sort_keys=True,
                )
                + "\n"
            )

            proc = subprocess.run(
                [
                    sys.executable,
                    str(ADAPTER),
                ],
                input=json.dumps(
                    observation
                ),
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                cwd=ROOT,
            )

            if proc.returncode != 0:
                raise RuntimeError(
                    "Claude adapter failed:\n"
                    + proc.stderr
                )

            proposal = json.loads(
                proc.stdout
            )

            mask = int(
                proposal["mask"],
                0,
            )

            if (
                mask < 0
                or mask > MAX_MASK
                or mask in seen
            ):
                rejected_proposals.append({
                    "query_index":
                        query_index,

                    "proposal":
                        proposal,

                    "reason":
                        "invalid_or_duplicate_mask",
                })

                (
                    OUT
                    / "rejected_proposals.json"
                ).write_text(
                    json.dumps(
                        rejected_proposals,
                        indent=2,
                        sort_keys=True,
                    )
                    + "\n"
                )

                continue

            break

        seen.add(mask)

        blocks = blocks_from_mask(
            mask
        )

        candidate = (
            RTL_DIR
            / (
                f"query_{query_index:02d}_"
                f"{mask:09x}.v"
            )
        )

        write_candidate(
            mask,
            candidate,
        )

        print()
        print("=" * 72)
        print(
            f"CLAUDE STRUCTURAL QUERY "
            f"{query_index + 1}/{BUDGET}"
        )
        print(
            f"mask=0x{mask:09x} "
            f"blocks={blocks}"
        )
        print(
            "rationale:",
            proposal["rationale"],
        )
        print("=" * 72)

        result = dict(
            evaluate(
                candidate.relative_to(
                    ROOT
                ),
                benchmark="addpipe36",
            )
        )

        result[
            "algorithm"
        ] = "claude_structural"

        result[
            "query_index"
        ] = query_index

        result[
            "boundary_mask"
        ] = mask

        result[
            "mask"
        ] = f"0x{mask:09x}"

        result[
            "blocks"
        ] = list(blocks)

        result[
            "rationale"
        ] = proposal[
            "rationale"
        ]

        results.append(
            result
        )

        if not (
            result["functional"]
            and result["formal_ok"]
            and result["place_route_ok"]
        ):
            raise RuntimeError(
                f"Claude structural query "
                f"{query_index} failed evaluator"
            )

        (
            OUT
            / "partial_results.json"
        ).write_text(
            json.dumps(
                results,
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )

        combined = (
            shared
            + results
        )

        best = max(
            combined,
            key=lambda r:
                r["proxy_reward_v0"],
        )

        print(
            f"cells={result['cells']} "
            f"area={result['area']} "
            f"WNS={result['wns']} "
            f"power={result['power_w']} "
            f"reward={result['proxy_reward_v0']}"
        )

        print(
            "incumbent:",
            best.get(
                "mask",
                f"0x{int(best['boundary_mask']):09x}",
            ),
            best["proxy_reward_v0"],
        )

    combined = (
        shared
        + results
    )

    frontier = pareto(
        combined
    )

    best = max(
        combined,
        key=lambda r:
            r["proxy_reward_v0"],
    )

    (
        OUT
        / "results.json"
    ).write_text(
        json.dumps(
            results,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (
        OUT
        / "frontier.json"
    ).write_text(
        json.dumps(
            frontier,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (
        OUT
        / "summary.json"
    ).write_text(
        json.dumps({
            "algorithm":
                "claude_structural",

            "new_query_count":
                len(results),

            "rejected_model_proposals":
                len(
                    rejected_proposals
                ),

            "best_mask":
                best.get(
                    "mask",
                    f"0x{int(best['boundary_mask']):09x}",
                ),

            "best_blocks":
                best["blocks"],

            "best_reward":
                best[
                    "proxy_reward_v0"
                ],

            "combined_frontier_count":
                len(frontier),
        },
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    partial = (
        OUT
        / "partial_results.json"
    )

    if partial.exists():
        partial.unlink()

    print()
    print("=" * 72)
    print(
        "CLAUDE STRUCTURAL COMPLETE"
    )
    print("=" * 72)

    print(
        "new EDA queries:",
        len(results),
    )

    print(
        "rejected model proposals:",
        len(
            rejected_proposals
        ),
    )

    print(
        "best:",
        best.get(
            "mask",
            f"0x{int(best['boundary_mask']):09x}",
        ),
        tuple(
            best["blocks"]
        ),
        best[
            "proxy_reward_v0"
        ],
    )

    print(
        "combined frontier points:",
        len(frontier),
    )


if __name__ == "__main__":
    main()
