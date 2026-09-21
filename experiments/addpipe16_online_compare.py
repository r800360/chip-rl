from __future__ import annotations

import json
import random
from pathlib import Path

from chiprl.evaluate import evaluate
from chiprl.generate_addpipe16 import (
    CandidateSpec,
    MASK_BITS,
    MAX_MASK,
    write_candidate,
)


ROOT = Path(__file__).resolve().parents[1]

BUDGET = 16
INITIAL_POPULATION = 4
RESTART_PROBABILITY = 0.15

SEED_RANDOM = 20260921
SEED_EVOLUTION = 20260922

TAG = "addpipe16_online_compare"

GEN_ROOT = ROOT / "rtl" / "generated" / TAG
OUT_ROOT = ROOT / "results" / TAG


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


def result_summary(result):
    return {
        "mask": result["boundary_mask"],
        "blocks": result["blocks"],
        "reward": result["proxy_reward_v0"],
        "area": result["area"],
        "wns": result["wns"],
        "power_w": result["power_w"],
        "cells": result["cells"],
    }


def evaluate_mask(
    algorithm: str,
    step: int,
    mask: int,
):
    spec = CandidateSpec(mask)

    directory = GEN_ROOT / algorithm
    directory.mkdir(parents=True, exist_ok=True)

    path = (
        directory
        / f"{step:03d}_mask_{mask:04x}.v"
    )

    write_candidate(spec, path)

    rel = path.relative_to(ROOT)

    print()
    print(
        f"[{algorithm}] "
        f"{step + 1}/{BUDGET} "
        f"mask=0x{mask:04x} "
        f"blocks={spec.blocks}"
    )

    result = evaluate(
        rel,
        benchmark="addpipe16",
    )

    result["algorithm"] = algorithm
    result["step"] = step
    result["boundary_mask"] = mask
    result["blocks"] = list(spec.blocks)

    print(
        f"  formal={result['formal_ok']} "
        f"route={result['place_route_ok']} "
        f"area={result['area']} "
        f"wns={result['wns']} "
        f"reward={result['proxy_reward_v0']} "
        f"cache={result['cache_hit']}"
    )

    return result


def save_partial(
    algorithm: str,
    results,
):
    OUT_ROOT.mkdir(
        parents=True,
        exist_ok=True,
    )

    path = OUT_ROOT / f"{algorithm}.json"

    path.write_text(
        json.dumps(
            results,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )


def random_search():
    rng = random.Random(SEED_RANDOM)

    masks = rng.sample(
        range(MAX_MASK + 1),
        BUDGET,
    )

    results = []

    for step, mask in enumerate(masks):
        result = evaluate_mask(
            "random",
            step,
            mask,
        )

        results.append(result)
        save_partial("random", results)

    return results


def choose_parent(
    archive,
    rng,
):
    tournament = rng.sample(
        archive,
        min(3, len(archive)),
    )

    return max(
        tournament,
        key=lambda r:
            r["proxy_reward_v0"],
    )


def mutate_mask(
    parent_mask: int,
    unseen: set[int],
    rng,
) -> int:

    # Mostly one local boundary mutation.
    # Occasionally make a somewhat larger move.
    flip_count = rng.choices(
        population=[1, 2, 3],
        weights=[0.70, 0.25, 0.05],
        k=1,
    )[0]

    for _ in range(200):
        bits = rng.sample(
            range(MASK_BITS),
            flip_count,
        )

        child = parent_mask

        for bit in bits:
            child ^= 1 << bit

        if child in unseen:
            return child

    # Extremely unlikely fallback.
    return rng.choice(tuple(unseen))


def evolutionary_search():
    rng = random.Random(SEED_EVOLUTION)

    unseen = set(
        range(MAX_MASK + 1)
    )

    results = []

    initial_masks = rng.sample(
        list(unseen),
        INITIAL_POPULATION,
    )

    for mask in initial_masks:
        unseen.remove(mask)

        result = evaluate_mask(
            "evolution",
            len(results),
            mask,
        )

        results.append(result)
        save_partial("evolution", results)

    while len(results) < BUDGET:
        parent = choose_parent(
            results,
            rng,
        )

        parent_mask = (
            parent["boundary_mask"]
        )

        if rng.random() < RESTART_PROBABILITY:
            child = rng.choice(
                tuple(unseen)
            )

            mutation_kind = "restart"

        else:
            child = mutate_mask(
                parent_mask,
                unseen,
                rng,
            )

            mutation_kind = (
                f"mutate parent="
                f"0x{parent_mask:04x}"
            )

        unseen.remove(child)

        print(
            f"\n  proposal: {mutation_kind} "
            f"-> 0x{child:04x}"
        )

        result = evaluate_mask(
            "evolution",
            len(results),
            child,
        )

        result["proposal"] = (
            mutation_kind
        )

        results.append(result)
        save_partial("evolution", results)

    return results


def print_algorithm_summary(
    name,
    rows,
):
    best_reward = max(
        rows,
        key=lambda r:
            r["proxy_reward_v0"],
    )

    smallest = min(
        rows,
        key=lambda r:
            r["area"],
    )

    fastest = max(
        rows,
        key=lambda r:
            r["wns"],
    )

    frontier = pareto_front(rows)

    print()
    print(f"{name.upper()}")
    print("-" * 72)

    print(
        "best reward :",
        result_summary(best_reward),
    )

    print(
        "min area    :",
        result_summary(smallest),
    )

    print(
        "best WNS    :",
        result_summary(fastest),
    )

    print(
        f"Pareto points: {len(frontier)}"
    )

    for r in frontier:
        print(
            f"  mask=0x{r['boundary_mask']:04x} "
            f"blocks={tuple(r['blocks'])!s:<38} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9} "
            f"reward={r['proxy_reward_v0']}"
        )


def main():
    OUT_ROOT.mkdir(
        parents=True,
        exist_ok=True,
    )

    print(
        f"Search space: "
        f"{MAX_MASK + 1:,} architectures"
    )

    print(
        f"Budget: {BUDGET} evaluations "
        "per algorithm"
    )

    print()
    print("==============================")
    print("ONLINE RANDOM SEARCH")
    print("==============================")

    random_results = random_search()

    print()
    print("==============================")
    print("ONLINE EVOLUTIONARY SEARCH")
    print("==============================")

    evolution_results = (
        evolutionary_search()
    )

    combined = (
        random_results
        + evolution_results
    )

    combined_front = pareto_front(
        combined
    )

    (OUT_ROOT / "combined.json").write_text(
        json.dumps(
            combined,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (OUT_ROOT / "pareto_combined.json").write_text(
        json.dumps(
            combined_front,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    print()
    print("================================")
    print("ONLINE SEARCH COMPARISON")
    print("================================")

    print_algorithm_summary(
        "random",
        random_results,
    )

    print_algorithm_summary(
        "evolution",
        evolution_results,
    )

    print()
    print("COMBINED OBSERVED FRONTIER")
    print("-" * 72)

    for r in combined_front:
        print(
            f"  {r['algorithm']:<10} "
            f"mask=0x{r['boundary_mask']:04x} "
            f"blocks={tuple(r['blocks'])!s:<38} "
            f"area={r['area']:<9} "
            f"WNS={r['wns']:<9}"
        )

    print()
    print(f"Results: {OUT_ROOT}")


if __name__ == "__main__":
    main()
