from __future__ import annotations

import csv
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
    / "search_benchmark"
)

TRIALS = 1000
BASE_SEED = 20260920

BUDGETS = (
    4,
    6,
    8,
    10,
    12,
    16,
    20,
)

MAX_BUDGET = max(BUDGETS)


def candidate_key(r):
    s = r["search_spec"]

    return (
        s["family"],
        int(s["param"]),
        s["hold_style"],
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


def unique_physical(rows):
    unique = {}

    for r in rows:
        unique.setdefault(
            physical_signature(r),
            r,
        )

    return list(unique.values())


def pareto_front(rows):
    unique = unique_physical(rows)

    return [
        r
        for r in unique
        if not any(
            dominates(other, r)
            for other in unique
            if other is not r
        )
    ]


def genome_distance(a, b):
    """
    Small distance means a relatively local RTL mutation.

    Hold-style changes and adjacent parameter changes have
    distance 1. Family changes are more disruptive.
    """
    family_a, param_a, style_a = a
    family_b, param_b, style_b = b

    distance = 0

    if family_a != family_b:
        distance += 2

    distance += abs(param_a - param_b)

    if style_a != style_b:
        distance += 1

    return distance


def random_search(keys, rng):
    order = list(keys)
    rng.shuffle(order)

    return order[:MAX_BUDGET]


def evolutionary_search(keys, by_key, rng):
    """
    Simple elitist evolutionary baseline.

    1. Begin with four random individuals.
    2. Select parents by tournament on proxy_reward_v0.
    3. Usually mutate locally in genotype space.
    4. Occasionally make a random exploratory jump.
    5. Never evaluate the exact same genotype twice.

    Importantly, this algorithm does NOT know that hold_style
    is physically neutral.
    """
    unseen = set(keys)
    evaluated = []

    initial_size = min(4, MAX_BUDGET)

    for key in rng.sample(
        list(unseen),
        initial_size,
    ):
        evaluated.append(key)
        unseen.remove(key)

    while (
        len(evaluated) < MAX_BUDGET
        and unseen
    ):
        tournament_size = min(
            3,
            len(evaluated),
        )

        tournament = rng.sample(
            evaluated,
            tournament_size,
        )

        parent = max(
            tournament,
            key=lambda k:
                by_key[k]["proxy_reward_v0"],
        )

        # Random restart / exploration.
        if rng.random() < 0.15:
            child = rng.choice(
                tuple(unseen)
            )

        else:
            distances = {
                candidate:
                    genome_distance(
                        parent,
                        candidate,
                    )
                for candidate in unseen
            }

            minimum = min(
                distances.values()
            )

            local_candidates = [
                candidate
                for candidate, distance
                in distances.items()
                if distance == minimum
            ]

            child = rng.choice(
                local_candidates
            )

        evaluated.append(child)
        unseen.remove(child)

    return evaluated


def state_at_budget(
    history,
    budget,
    by_key,
    best_reward,
    pareto_signatures,
):
    rows = [
        by_key[k]
        for k in history[:budget]
    ]

    rewards = [
        float(r["proxy_reward_v0"])
        for r in rows
    ]

    signatures = {
        physical_signature(r)
        for r in rows
    }

    pareto_found = (
        signatures
        & pareto_signatures
    )

    found_global_best = any(
        abs(
            float(r["proxy_reward_v0"])
            - best_reward
        ) < 1e-12
        for r in rows
    )

    return {
        "best_reward": max(rewards),
        "found_global_best": (
            1.0
            if found_global_best
            else 0.0
        ),
        "pareto_coverage": (
            len(pareto_found)
            / len(pareto_signatures)
        ),
        "unique_physical": len(signatures),
    }


def summarize(samples):
    return {
        "mean_best_reward":
            statistics.mean(
                x["best_reward"]
                for x in samples
            ),

        "median_best_reward":
            statistics.median(
                x["best_reward"]
                for x in samples
            ),

        "p_global_best":
            statistics.mean(
                x["found_global_best"]
                for x in samples
            ),

        "mean_pareto_coverage":
            statistics.mean(
                x["pareto_coverage"]
                for x in samples
            ),

        "mean_unique_physical":
            statistics.mean(
                x["unique_physical"]
                for x in samples
            ),
    }


def main():
    rows = json.loads(
        DATA.read_text()
    )

    if len(rows) != 48:
        raise RuntimeError(
            f"Expected 48 rows, got {len(rows)}"
        )

    if not all(
        r["functional"]
        and r["place_route_ok"]
        for r in rows
    ):
        raise RuntimeError(
            "Design space contains invalid runs"
        )

    by_key = {
        candidate_key(r): r
        for r in rows
    }

    keys = list(by_key)

    if len(keys) != 48:
        raise RuntimeError(
            "Candidate keys are not unique"
        )

    physical = unique_physical(rows)
    global_front = pareto_front(rows)

    pareto_signatures = {
        physical_signature(r)
        for r in global_front
    }

    best_reward = max(
        float(r["proxy_reward_v0"])
        for r in rows
    )

    best_candidates = [
        r
        for r in rows
        if abs(
            float(r["proxy_reward_v0"])
            - best_reward
        ) < 1e-12
    ]

    print(
        f"RTL candidates: "
        f"{len(rows)}"
    )

    print(
        f"Unique physical designs: "
        f"{len(physical)}"
    )

    print(
        f"Ground-truth Pareto points: "
        f"{len(global_front)}"
    )

    print(
        f"Global best reward: "
        f"{best_reward}"
    )

    print(
        f"Equivalent global-best RTLs: "
        f"{len(best_candidates)}"
    )

    all_samples = {
        algorithm: {
            budget: []
            for budget in BUDGETS
        }
        for algorithm in (
            "random",
            "evolution",
        )
    }

    for trial in range(TRIALS):
        seed = BASE_SEED + trial

        random_history = random_search(
            keys,
            random.Random(seed),
        )

        evolution_history = (
            evolutionary_search(
                keys,
                by_key,
                random.Random(seed),
            )
        )

        for budget in BUDGETS:
            all_samples[
                "random"
            ][budget].append(
                state_at_budget(
                    random_history,
                    budget,
                    by_key,
                    best_reward,
                    pareto_signatures,
                )
            )

            all_samples[
                "evolution"
            ][budget].append(
                state_at_budget(
                    evolution_history,
                    budget,
                    by_key,
                    best_reward,
                    pareto_signatures,
                )
            )

    summaries = []

    for algorithm in (
        "random",
        "evolution",
    ):
        for budget in BUDGETS:
            summary = summarize(
                all_samples[
                    algorithm
                ][budget]
            )

            summaries.append({
                "algorithm": algorithm,
                "budget": budget,
                **summary,
            })

    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    json_path = (
        OUT
        / "summary.json"
    )

    json_path.write_text(
        json.dumps(
            summaries,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    csv_path = (
        OUT
        / "summary.csv"
    )

    with csv_path.open(
        "w",
        newline="",
    ) as f:
        writer = csv.writer(f)

        writer.writerow([
            "algorithm",
            "budget",
            "mean_best_reward",
            "median_best_reward",
            "p_global_best",
            "mean_pareto_coverage",
            "mean_unique_physical",
        ])

        for row in summaries:
            writer.writerow([
                row["algorithm"],
                row["budget"],
                row["mean_best_reward"],
                row["median_best_reward"],
                row["p_global_best"],
                row["mean_pareto_coverage"],
                row["mean_unique_physical"],
            ])

    print()
    print(
        "==============================================================="
    )
    print(
        "SEARCH BENCHMARK — 1000 REPEATED TRIALS"
    )
    print(
        "==============================================================="
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

    for row in summaries:
        print(
            f"{row['algorithm']:<11}"
            f"{row['budget']:>8}"
            f"{row['mean_best_reward']:>13.4f}"
            f"{row['p_global_best']:>11.3f}"
            f"{row['mean_pareto_coverage']:>11.3f}"
            f"{row['mean_unique_physical']:>12.2f}"
        )

    print()
    print(
        "P(best) = probability of discovering "
        "the global proxy-reward optimum."
    )

    print(
        "Pareto = fraction of the 3 true physical "
        "Pareto points discovered."
    )

    print(
        "unique HW = mean number of distinct physical "
        "implementations actually observed."
    )

    print()
    print(f"CSV:  {csv_path}")
    print(f"JSON: {json_path}")


if __name__ == "__main__":
    main()
