from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

from chiprl.evaluate import evaluate
from chiprl.generate_addpipe24 import (
    MAX_MASK,
    blocks_from_mask,
    write_candidate,
)


ROOT = Path(__file__).resolve().parents[1]

SHARED = (
    ROOT
    / "results"
    / "addpipe24_shared_seed"
    / "results.json"
)

RESULT_ROOT = (
    ROOT
    / "results"
    / "addpipe24_controlled"
)

RTL_ROOT = (
    ROOT
    / "rtl"
    / "generated"
    / "addpipe24_controlled"
)

BUDGET = 16
RNG_SEED = 20260921


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


def choose_random(
    rng,
    seen,
):
    while True:
        mask = rng.randrange(
            MAX_MASK + 1
        )

        if mask not in seen:
            return mask


def weighted_mutation_count(
    rng,
):
    x = rng.random()

    if x < 0.70:
        return 1

    if x < 0.95:
        return 2

    return 3


def choose_evolution(
    rng,
    seen,
    archive,
):
    while True:
        # Frozen protocol:
        # 15% global random restart.
        if rng.random() < 0.15:
            mask = rng.randrange(
                MAX_MASK + 1
            )

            if mask not in seen:
                return mask

            continue

        competitors = rng.sample(
            archive,
            k=min(
                3,
                len(archive),
            ),
        )

        parent = max(
            competitors,
            key=lambda r:
                r["proxy_reward_v0"],
        )

        parent_mask = int(
            parent["boundary_mask"]
        )

        flips = weighted_mutation_count(
            rng
        )

        bits = rng.sample(
            range(23),
            k=flips,
        )

        child = parent_mask

        for bit in bits:
            child ^= (
                1 << bit
            )

        if child not in seen:
            return child


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--algorithm",
        required=True,
        choices=(
            "random",
            "evolution",
        ),
    )

    args = parser.parse_args()

    algorithm = args.algorithm

    out = (
        RESULT_ROOT
        / algorithm
    )

    rtl_dir = (
        RTL_ROOT
        / algorithm
    )

    if (
        out
        / "results.json"
    ).exists():
        raise SystemExit(
            f"{algorithm} results already complete; "
            "refusing to overwrite."
        )

    out.mkdir(
        parents=True,
        exist_ok=True,
    )

    rtl_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    shared = json.loads(
        SHARED.read_text()
    )

    seed_masks = {
        int(r["boundary_mask"])
        for r in shared
    }

    seen = set(seed_masks)

    # Evolution sees exactly the shared seed measurements
    # plus its own subsequent results.
    archive = [
        dict(r)
        for r in shared
    ]

    rng = random.Random(
        RNG_SEED
    )

    results = []

    for query_index in range(
        BUDGET
    ):
        if algorithm == "random":
            mask = choose_random(
                rng,
                seen,
            )

        else:
            mask = choose_evolution(
                rng,
                seen,
                archive,
            )

        seen.add(mask)

        blocks = blocks_from_mask(
            mask
        )

        candidate = (
            rtl_dir
            / (
                f"query_{query_index:02d}_"
                f"{mask:06x}.v"
            )
        )

        write_candidate(
            mask,
            candidate,
        )

        print()
        print("=" * 72)
        print(
            f"{algorithm.upper()} "
            f"QUERY {query_index + 1}/{BUDGET}"
        )
        print(
            f"mask=0x{mask:06x} "
            f"blocks={blocks}"
        )
        print("=" * 72)

        result = dict(
            evaluate(
                candidate.relative_to(
                    ROOT
                ),
                benchmark="addpipe24",
            )
        )

        result[
            "algorithm"
        ] = algorithm

        result[
            "query_index"
        ] = query_index

        result[
            "boundary_mask"
        ] = mask

        result[
            "mask"
        ] = f"0x{mask:06x}"

        result[
            "blocks"
        ] = list(blocks)

        results.append(
            result
        )

        if not (
            result["functional"]
            and result["formal_ok"]
            and result["place_route_ok"]
        ):
            raise RuntimeError(
                f"{algorithm} query "
                f"{query_index} failed evaluator"
            )

        archive.append(
            result
        )

        (
            out
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
                f"0x{int(best['boundary_mask']):06x}",
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

    summary = {
        "algorithm":
            algorithm,

        "rng_seed":
            RNG_SEED,

        "shared_seed_count":
            len(shared),

        "new_query_count":
            len(results),

        "all_queries_valid":
            all(
                r["functional"]
                and r["formal_ok"]
                and r["place_route_ok"]
                for r in results
            ),

        "best_reward":
            best[
                "proxy_reward_v0"
            ],

        "best_mask":
            best.get(
                "mask",
                f"0x{int(best['boundary_mask']):06x}",
            ),

        "best_blocks":
            best["blocks"],

        "combined_frontier_count":
            len(frontier),
    }

    (
        out
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
        out
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
        out
        / "summary.json"
    ).write_text(
        json.dumps(
            summary,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    partial = (
        out
        / "partial_results.json"
    )

    if partial.exists():
        partial.unlink()

    print()
    print("=" * 72)
    print(
        f"{algorithm.upper()} COMPLETE"
    )
    print("=" * 72)

    print(
        "new queries:",
        len(results),
    )

    print(
        "best mask:",
        summary["best_mask"],
        tuple(
            summary["best_blocks"]
        ),
    )

    print(
        "best reward:",
        summary["best_reward"],
    )

    print(
        "combined frontier points:",
        len(frontier),
    )

    print(
        f"Output: {out}"
    )


if __name__ == "__main__":
    main()
