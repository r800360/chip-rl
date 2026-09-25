from __future__ import annotations

import json
import random
import statistics
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

DATA = (
    ROOT
    / "results"
    / "design_space_v2"
    / "results.json"
)

OUT = (
    ROOT
    / "results"
    / "search_benchmark_structural"
)

TRIALS = 10000
BASE_SEED = 20260920

BUDGETS = (2, 3, 4, 5, 6, 8, 10, 12)
MAX_BUDGET = max(BUDGETS)


def structural_key(r):
    s = r["search_spec"]
    return (
        s["family"],
        int(s["param"]),
    )


def physical_signature(r):
    return (
        int(r["cells"]),
        round(float(r["area"]), 6),
        round(float(r["wns"]), 6),
        round(float(r["power_w"]), 12),
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


def pareto_front(rows):
    return [
        r
        for r in rows
        if not any(
            dominates(other, r)
            for other in rows
            if other is not r
        )
    ]


def structural_distance(a, b):
    family_a, param_a = a
    family_b, param_b = b

    if family_a == family_b:
        return abs(param_a - param_b)

    # Switching architecture family is a larger mutation.
    return 3 + abs(param_a - param_b)


def random_search(keys, rng):
    order = list(keys)
    rng.shuffle(order)
    return order[:MAX_BUDGET]


def evolutionary_search(keys, by_key, rng):
    unseen = set(keys)
    evaluated = []

    initial_size = min(2, len(keys))

    initial = rng.sample(
        list(unseen),
        initial_size,
    )

    for key in initial:
        evaluated.append(key)
        unseen.remove(key)

    while len(evaluated) < MAX_BUDGET and unseen:
        tournament = rng.sample(
            evaluated,
            min(3, len(evaluated)),
        )

        parent = max(
            tournament,
            key=lambda k:
                by_key[k]["proxy_reward_v0"],
        )

        # Some global exploration is retained.
        if rng.random() < 0.15:
            child = rng.choice(tuple(unseen))
        else:
            distances = {
                k: structural_distance(parent, k)
                for k in unseen
            }

            dmin = min(distances.values())

            neighbors = [
                k
                for k, d in distances.items()
                if d == dmin
            ]

            child = rng.choice(neighbors)

        evaluated.append(child)
        unseen.remove(child)

    return evaluated


def state(history, budget, by_key, optimum, pareto_sigs):
    rows = [
        by_key[k]
        for k in history[:budget]
    ]

    best = max(
        r["proxy_reward_v0"]
        for r in rows
    )

    sigs = {
        physical_signature(r)
        for r in rows
    }

    return {
        "best_reward": best,

        "found_best": float(
            abs(best - optimum) < 1e-12
        ),

        "pareto_coverage":
            len(sigs & pareto_sigs)
            / len(pareto_sigs),

        "unique_hw": len(sigs),
    }


def summarize(samples):
    return {
        "mean_best":
            statistics.mean(
                x["best_reward"]
                for x in samples
            ),

        "p_best":
            statistics.mean(
                x["found_best"]
                for x in samples
            ),

        "pareto":
            statistics.mean(
                x["pareto_coverage"]
                for x in samples
            ),

        "unique_hw":
            statistics.mean(
                x["unique_hw"]
                for x in samples
            ),
    }


def main():
    rows = json.loads(DATA.read_text())

    # Collapse four coding-style variants into one
    # representative structural architecture.
    by_key = {}

    for r in rows:
        key = structural_key(r)
        by_key.setdefault(key, r)

    keys = list(by_key)

    if len(keys) != 12:
        raise RuntimeError(
            f"Expected 12 structures, got {len(keys)}"
        )

    structural_rows = list(by_key.values())

    frontier = pareto_front(structural_rows)

    pareto_sigs = {
        physical_signature(r)
        for r in frontier
    }

    optimum = max(
        r["proxy_reward_v0"]
        for r in structural_rows
    )

    samples = {
        alg: {
            budget: []
            for budget in BUDGETS
        }
        for alg in ("random", "evolution")
    }

    for trial in range(TRIALS):
        seed = BASE_SEED + trial

        histories = {
            "random": random_search(
                keys,
                random.Random(seed),
            ),

            "evolution": evolutionary_search(
                keys,
                by_key,
                random.Random(seed),
            ),
        }

        for alg, history in histories.items():
            for budget in BUDGETS:
                samples[alg][budget].append(
                    state(
                        history,
                        budget,
                        by_key,
                        optimum,
                        pareto_sigs,
                    )
                )

    summaries = []

    print(
        "=========================================================="
    )
    print(
        "STRUCTURE-AWARE SEARCH: 10000 TRIALS"
    )
    print(
        "=========================================================="
    )

    print(
        f"{'algorithm':<11}"
        f"{'budget':>8}"
        f"{'mean best':>13}"
        f"{'P(best)':>11}"
        f"{'Pareto':>11}"
        f"{'unique HW':>12}"
    )

    print("-" * 66)

    for alg in ("random", "evolution"):
        for budget in BUDGETS:
            s = summarize(
                samples[alg][budget]
            )

            row = {
                "algorithm": alg,
                "budget": budget,
                **s,
            }

            summaries.append(row)

            print(
                f"{alg:<11}"
                f"{budget:>8}"
                f"{s['mean_best']:>13.4f}"
                f"{s['p_best']:>11.3f}"
                f"{s['pareto']:>11.3f}"
                f"{s['unique_hw']:>12.2f}"
            )

    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    (OUT / "summary.json").write_text(
        json.dumps(
            summaries,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    print()
    print(
        f"Structural designs: {len(keys)}"
    )
    print(
        f"True Pareto points: {len(frontier)}"
    )
    print(
        f"Global optimum reward: {optimum}"
    )


if __name__ == "__main__":
    main()
