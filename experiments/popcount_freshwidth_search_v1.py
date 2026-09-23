"""Frozen four-method, two-width, three-seed popcount-tree search experiment.

Additive runner: changes no historical source. No cross-method information sharing:
only the eight preregistered physical seed rows are common to all runs.
Updates in the learning hybrid occur only on GLOBAL policy-sampled actions.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import random
from pathlib import Path

from chiprl.conditioned_autoregressive_policy import ConditionedHierarchicalMaskPolicy
from chiprl.benchmarks import ROOT
from chiprl.evaluate import evaluate
from chiprl.rl_env import StructuralMaskEnv, is_valid_result
from chiprl.popcount_tree_widths_v1 import FRESH_WIDTHS, benchmark, name, write_candidate

METHODS = (
    "v3_global", "uniform_local", "v3_hybrid", "frozen_hybrid",
)
RNG_SEEDS = (32001, 32002, 32003)
BUDGET = 16
PROTOCOL = ROOT / "experiments/protocol_popcount_freshwidth_search_v1.json"
PILOT = ROOT / "experiments/protocol_popcount_tree_freshwidth_pilot_v1.json"
FREEZE = ROOT / "experiments/popcount_freshwidth_seed_freeze_v1.json"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save_json(path: Path, obj) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(obj, indent=2, sort_keys=True) + "\n")
    temp.replace(path)


def seed_path(width: int) -> Path:
    return ROOT / f"results/{name(width)}_arch_seed_v1/results.json"


def read_inputs(width: int):
    """Read and verify immutable experiment inputs; no EDA and no writes."""
    if width not in FRESH_WIDTHS:
        raise ValueError(width)
    protocol = json.loads(PROTOCOL.read_text())
    freeze = json.loads(FREEZE.read_text())
    if protocol["pilot_protocol_sha256"] != sha(PILOT):
        raise RuntimeError("Original physical-diversity pilot protocol changed")
    if protocol["seed_freeze_sha256"] != sha(FREEZE):
        raise RuntimeError("Seed-freeze manifest changed")
    if not all(freeze["widths"][name(w)]["gate_passed"] for w in FRESH_WIDTHS):
        raise RuntimeError("A frozen width failed its diversity gate")
    if (protocol["methods"] != list(METHODS)
        or protocol["rng_seeds"] != list(RNG_SEEDS)
        or protocol["budget_per_run"] != BUDGET
        or protocol["widths"] != list(FRESH_WIDTHS)):
        raise RuntimeError("Preregistered methods/seeds/budgets changed")
    for rel, expected in protocol["source_sha256"].items():
        if sha(ROOT / rel) != expected:
            raise RuntimeError(f"Search source differs from preregistration: {rel}")
    for w in FRESH_WIDTHS:
        nm = name(w)
        rowfile = seed_path(w)
        rows = json.loads(rowfile.read_text())
        if sha(rowfile) != freeze["widths"][nm]["results_sha256"]:
            raise RuntimeError(f"Frozen seed results changed for {nm}")
        if len(rows) != 8 or not all(is_valid_result(row) for row in rows):
            raise RuntimeError(f"Expected exactly eight valid seed records: {nm}")
    return protocol, json.loads(seed_path(width).read_text())


def init_policy(width: int, seed_rows):
    return ConditionedHierarchicalMaskPolicy(bits=width - 1, seed_rows=seed_rows)


def action_source(method: str, index: int) -> str:
    if method == "v3_global":
        return "global"
    if method == "uniform_local":
        return "local"
    if method in ("v3_hybrid", "frozen_hybrid"):
        return "local" if index % 2 == 0 else "global"
    raise ValueError(method)


def rng_for(seed: int, index: int, source: str) -> random.Random:
    # disjoint within every 16-query trajectory; common random numbers are
    # intentionally reused across methods for matched comparisons.
    channel = {"local": 1, "global": 2}[source]
    return random.Random(seed * 1000 + index * 4 + channel)


def local_proposal(rows, seen: set[int], bits: int, rng: random.Random):
    """Explore the strongest incumbent first, falling back to archived designs.

    This fallback is needed for 15-bit spaces: the best seed has at most 15
    distinct one-flip neighbors, but each trajectory has 16 queries.
    """
    ranked = sorted(
        (r for r in rows if is_valid_result(r)),
        key=lambda r: (-float(r["proxy_reward_v0"]), float(r["area"]), int(r["boundary_mask"])),
    )
    for parent in ranked:
        p = int(parent["boundary_mask"])
        candidates = [
            p ^ (1 << bit) for bit in range(bits)
            if (p ^ (1 << bit)) not in seen
        ]
        if candidates:
            return candidates[rng.randrange(len(candidates))], p
    raise RuntimeError("No unseen one-flip neighbor in the run's own archive; stop")


def propose(method: str, index: int, policy, archive, seen, seed):
    source = action_source(method, index)
    rng = rng_for(seed, index, source)
    if source == "global":
        return policy.sample(rng=rng, seen_masks=seen), source, None
    mask, parent = local_proposal(archive, seen, policy.bits, rng)
    return mask, source, parent


def score_of(record):
    r = record.get("result")
    return float(r["proxy_reward_v0"]) if r and r.get("proxy_reward_v0") is not None else -1000.0


def learn(method, source, policy, mask, score, pre_seen):
    if source == "global" and method in ("v3_global", "v3_hybrid"):
        return policy.update_conditioned(mask=mask, score=score, seen_masks=pre_seen)
    return None


def replay(method, seed, policy, seed_rows, queries, *, check_actions=True):
    """Rebuild state with only each method's previous results; no future leakage."""
    archive = [dict(r) for r in seed_rows]
    seen = {int(r["boundary_mask"]) for r in seed_rows}
    for i, record in enumerate(queries):
        if record["query_index"] != i:
            raise RuntimeError(f"Non-contiguous query history at {i}")
        predicted, source, parent = propose(method, i, policy, archive, seen, seed)
        mask = int(record["boundary_mask"])
        if check_actions and predicted != mask:
            raise RuntimeError(f"Replay mismatch at query {i}: {predicted:#x} != {mask:#x}")
        if record.get("proposal_source", source) != source:
            raise RuntimeError(f"Source mismatch at {i}")
        if record.get("parent_mask", parent) != parent:
            raise RuntimeError(f"Local parent mismatch at {i}")
        learn(method, source, policy, mask, score_of(record), set(seen))
        seen.add(mask)
        if record.get("result") and is_valid_result(record["result"]):
            archive.append({**record["result"], "boundary_mask": mask})
    return seen, archive


def run(width: int, method: str, seed: int):
    if width not in FRESH_WIDTHS or method not in METHODS or seed not in RNG_SEEDS:
        raise ValueError("Run not preregistered")
    protocol, seeds = read_inputs(width)
    nm = name(width)
    bench = benchmark(width)

    def render_mask(mask, path):
        return write_candidate(width, mask, path)

    def evaluate_mask(mask, path):
        # Fresh-width Benchmark object avoids modifying the historical registry.
        return evaluate(path, benchmark=bench, cache=True, clean=False)

    env = StructuralMaskEnv(
        benchmark=nm, width=width,
        run_id=f"freshwidth_search_v1_{method}_seed_{seed}",
        budget=BUDGET, seed_rows=seeds,
        render_candidate=render_mask, evaluate_candidate=evaluate_mask,
    )
    metadata = {
        "experiment": "popcount_freshwidth_search_v1", "benchmark": nm,
        "method": method, "rng_seed": seed,
        "protocol_sha256": sha(PROTOCOL),
        "seed_results_sha256": sha(seed_path(width)),
    }
    metafile = env.run_dir / "run_manifest.json"
    if metafile.exists():
        if json.loads(metafile.read_text()) != metadata:
            raise RuntimeError("Existing run manifest changed")
    elif env.queries_used:
        raise RuntimeError("Existing query history has no manifest; preserve it")
    else:
        save_json(metafile, metadata)

    policy = init_policy(width, seeds)
    initfile = env.run_dir / "policy_initial.json"
    if initfile.exists():
        if json.loads(initfile.read_text()) != policy.snapshot():
            raise RuntimeError("Initial policy snapshot mismatch")
    else:
        save_json(initfile, policy.snapshot())

    seen, archive = replay(method, seed, policy, seeds, env.state["queries"])
    if seen != env.seen_masks():
        raise RuntimeError("Environment seen set differs from replay")
    if env.queries_used:
        prior = env.run_dir / f"policy_after_{env.queries_used:02d}.json"
        if prior.exists() and json.loads(prior.read_text()) != policy.snapshot():
            raise RuntimeError("Saved policy checkpoint differs from replay")

    while not env.done:
        i = env.queries_used
        pre_seen = set(seen)
        mask, source, parent = propose(method, i, policy, archive, seen, seed)
        obs, _, _, _ = env.step(mask)
        record = env.state["queries"][-1]
        record.update(proposal_source=source, parent_mask=parent)
        env._save()  # record action metadata after the evaluator's durable record
        learn(method, source, policy, mask, score_of(record), pre_seen)
        seen.add(mask)
        if record.get("result") and is_valid_result(record["result"]):
            archive.append({**record["result"], "boundary_mask": mask})
        save_json(env.run_dir / f"policy_after_{i+1:02d}.json", policy.snapshot())
        print(f"{nm} {method} seed={seed} q={i+1:02d}/{BUDGET} "
              f"source={source} mask={mask:#x} K={mask.bit_count()} "
              f"status={record['status']} score={score_of(record):.6f} "
              f"best={obs['best_so_far']['proxy_reward_v0']:.6f}", flush=True)
        if record["status"] == "evaluator_exception":
            raise RuntimeError(f"EDA exception at query {i+1}; record preserved")

    save_json(env.run_dir / "summary.json", {
        **metadata, "queries": env.queries_used,
        "initial_reward": max(r["proxy_reward_v0"] for r in seeds),
        "best_so_far": env.observation()["best_so_far"],
        "final_policy": policy.snapshot(),
        "global_queries": sum(q["proposal_source"] == "global" for q in env.state["queries"]),
        "local_queries": sum(q["proposal_source"] == "local" for q in env.state["queries"]),
    })
    print(f"COMPLETE {nm} {method} seed={seed}", flush=True)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--width", type=int, choices=FRESH_WIDTHS, required=True)
    p.add_argument("--method", choices=METHODS, required=True)
    p.add_argument("--seed", choices=RNG_SEEDS, type=int, required=True)
    args = p.parse_args()
    run(args.width, args.method, args.seed)


if __name__ == "__main__":
    main()
