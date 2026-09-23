"""Read-only audit and reproducibility bundle for the frozen 192-query popcount-tree v3 pilot.

Run from the chip-rl repository root:
  cp ~/Downloads/package_popcount_tree_v3_v1.py experiments/
  python -m experiments.package_popcount_tree_v3_v1

No EDA calls, source edits, or changes to saved experiment data.
"""
from __future__ import annotations

import csv
import hashlib
import json
import math
import statistics
import subprocess
import zipfile
from collections import defaultdict
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.popcount_tree_generator import PILOT_MASKS
from experiments.run_popcount_tree_v3_v1 import (
    BUDGET, FREEZE, METHODS, PROTO, RNG_SEEDS, SEED,
    guard, init_policy, sample, score_of, update_policy,
)

OUT = ROOT / "results/popcount_tree_v3_pilot_v1/audit"
ARCHIVE = ROOT / "results/popcount_tree_v3_pilot_v1/popcount_tree_v3_results_bundle.zip"
FP_KEYS = (
    "schema_version", "benchmark", "top_module", "testbench_sha256",
    "reference_rtl_sha256", "orfs_config_sha256", "sdc_sha256",
    "formal_seq", "or_image_id", "orfs_git_commit", "verilator",
)


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def load(path):
    require(path.is_file(), f"Missing required file: {path}")
    return json.loads(path.read_text())


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def valid(row):
    return row is not None and all(row.get(k) is True for k in
        ("functional", "formal_ok", "synthesis_ok", "place_route_ok")) and all(
        isinstance(row.get(k), (float, int)) and math.isfinite(row[k]) for k in
        ("area", "wns", "proxy_reward_v0")
    )


def write_csv(path, rows):
    if not rows:
        raise RuntimeError(f"No rows for {path}")
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def dominates(a, b):
    return (a["area"] <= b["area"] and a["wns"] >= b["wns"] and
            (a["area"] < b["area"] or a["wns"] > b["wns"]))


def main():
    protocol, seeds = guard()  # Checks seed freeze and every protocol-listed source hash.
    freeze = load(FREEZE)
    require(freeze["diversity_gate_passed"], "Original gate did not pass")
    require(len(seeds) == 8 and [int(r["boundary_mask"]) for r in seeds]
            == list(PILOT_MASKS), "Shared seeds differ from freeze")
    require(all(valid(r) for r in seeds), "Invalid shared seed")
    require(all(r["cache_hit"] is False for r in seeds), "Pilot seed was cached")
    reference_fp = seeds[0]["fingerprint"]
    for row in seeds:
        require(all(row["fingerprint"].get(k) == reference_fp.get(k) for k in FP_KEYS),
                "Seed fingerprint mismatch")
    incumbent = max(float(r["proxy_reward_v0"]) for r in seeds)
    require(abs(float(protocol["logical_queries"]) - 192) < 0.1,
            "Unexpected preregistered query total")
    require(tuple(METHODS) == ("v2_legacy", "v2_raw_aggregate", "v3_conditioned", "v2_frozen"),
            "Unexpected method identifiers")

    files = {PROTO, FREEZE, SEED,
             ROOT / "experiments/protocol_popcount_tree_arch_pilot_v1.json",
             ROOT / "results/popcount32_tree_arch_seed/summary.json",
             ROOT / "results/popcount32_tree_arch_seed/frontier.json",
             ROOT / "experiments/run_popcount_tree_v3_v1.sh"}
    for rel in protocol["source_sha256"]:
        files.add(ROOT / rel)
    files.add(ROOT / "experiments/package_popcount_tree_v3_v1.py")
    for rel in (
        "experiments/audit_conditioned_policy_gradient_v1.py",
        "experiments/smoke_conditioned_v3.py",
        "experiments/smoke_popcount_tree_v3_v1.py",
        "experiments/README_popcount_tree_v3_next_stage.md",
        "experiments/amendment_popcount_tree_eval_cli_v1.json",
    ):
        p = ROOT / rel
        if p.exists():
            files.add(p)
    for p in (ROOT / "rtl/generated/popcount32_tree_arch_seed").glob("*.v"):
        files.add(p)
    audit_result = ROOT / "results/conditioned_gradient_audit_v1.json"
    if audit_result.exists():
        files.add(audit_result)

    run_rows, query_rows, paired_rows, policy_rows = [], [], [], []
    observations = {}
    for row in seeds:
        observations[int(row["boundary_mask"])] = {
            "mask": f"0x{int(row['boundary_mask']):08x}", "area": row["area"],
            "wns": row["wns"], "reward": row["proxy_reward_v0"], "methods": {"shared_seed"},
        }
    seed_masks = {int(row["boundary_mask"]) for row in seeds}
    by_run = {}
    initial_snapshots = {}
    cache_hits = 0

    print("=" * 89)
    print("POPCount32_TREE: FROZEN V3 PILOT AUDIT (NO EDA)")
    print("=" * 89)
    print(f"Shared incumbent: 0x{max(seeds, key=lambda r:r['proxy_reward_v0'])['boundary_mask']:08x} "
          f"reward={incumbent:.6f}")

    for rng_seed in RNG_SEEDS:
        for method in METHODS:
            run_id = f"v3pilot_{method}_seed_{rng_seed}"
            rd = ROOT / "results/rl_runs/popcount32_tree" / run_id
            manifest = load(rd / "run_manifest.json")
            require(manifest == {
                "benchmark": "popcount32_tree", "method": method, "rng_seed": rng_seed,
                "protocol_sha256": sha(PROTO), "seed_results_sha256": sha(SEED),
            }, f"{run_id}: run manifest mismatch")
            state = load(rd / "state.json")
            summary = load(rd / "summary.json")
            require(all((state.get(k) == v) for k, v in (
                ("benchmark", "popcount32_tree"), ("width", 32), ("mask_bits", 31),
                ("budget", BUDGET), ("run_id", run_id))), f"{run_id}: state metadata mismatch")
            queries = state["queries"]
            require(len(queries) == BUDGET, f"{run_id}: incomplete trajectory {len(queries)}")
            require(summary.get("queries") == BUDGET and summary.get("method") == method
                    and summary.get("rng_seed") == rng_seed, f"{run_id}: summary mismatch")
            require(abs(float(summary["initial_reward"]) - incumbent) < 1e-8,
                    f"{run_id}: seed score mismatch")

            policy = init_policy(method, seeds)
            initial = policy.snapshot()
            require(load(rd / "policy_initial.json") == initial,
                    f"{run_id}: policy initialization mismatch")
            if rng_seed not in initial_snapshots:
                initial_snapshots[rng_seed] = initial
            else:
                require(initial == initial_snapshots[rng_seed],
                        f"{run_id}: methods did not share the same initial policy")
            seen = set(seed_masks)
            best = incumbent
            first = None
            best_mask = max(seeds, key=lambda r: r["proxy_reward_v0"])["boundary_mask"]
            mean_k = 0
            run_hits = 0
            for i, q in enumerate(queries):
                m = int(q["boundary_mask"])
                require(q["query_index"] == i and 0 <= m < (1 << 31),
                        f"{run_id} query {i+1}: bad index/mask")
                require(m not in seen, f"{run_id} query {i+1}: repeated seed/query mask")
                predicted = sample(policy, rng_seed * 1000 + i, seen)
                require(predicted == m, f"{run_id} query {i+1}: deterministic replay mismatch")
                r = q.get("result")
                require(q["status"] == "success" and valid(r),
                        f"{run_id} query {i+1}: invalid or unsuccessful result")
                require(r["cache_hit"] in (True, False),
                        f"{run_id} query {i+1}: missing cache flag")
                require(all(r["fingerprint"].get(k) == reference_fp.get(k)
                            for k in FP_KEYS), f"{run_id} query {i+1}: evaluator fingerprint mismatch")
                candidate = ROOT / "rtl/rl/popcount32_tree" / run_id / f"query_{i:03d}_{m:08x}.v"
                require(candidate.is_file() and sha(candidate) == r["fingerprint"]["rtl_sha256"],
                        f"{run_id} query {i+1}: candidate RTL hash mismatch")
                # Frozen objective is exactly -0.001 area + 10 WNS.
                score = float(r["proxy_reward_v0"])
                require(abs(score - (-0.001*r["area"] + 10*r["wns"])) < 1e-5,
                        f"{run_id} query {i+1}: objective mismatch")
                update_policy(policy, method, m, score_of(q), seen)
                seen.add(m)
                snap = policy.snapshot()
                require(snap == load(rd / f"policy_after_{i+1:02d}.json"),
                        f"{run_id} query {i+1}: policy snapshot/replay mismatch")
                if method == "v2_frozen":
                    require(snap == initial, f"{run_id} query {i+1}: frozen policy changed")
                k = m.bit_count()
                mean_k += k
                run_hits += int(r["cache_hit"])
                cache_hits += int(r["cache_hit"])
                if score > best + 1e-9:
                    best, best_mask = score, m
                    if first is None:
                        first = i+1
                obs = observations.setdefault(m, {
                    "mask": f"0x{m:08x}", "area": r["area"], "wns": r["wns"],
                    "reward": score, "methods": set(),
                })
                require(abs(obs["area"] - r["area"]) < 1e-5 and
                        abs(obs["wns"] - r["wns"]) < 1e-5,
                        f"Cross-run physical results differ for mask 0x{m:08x}")
                obs["methods"].add(method)
                query_rows.append({
                    "seed": rng_seed, "method": method, "query": i+1,
                    "mask": f"0x{m:08x}", "K": k, "status": q["status"],
                    "cache_hit": r["cache_hit"], "area": r["area"], "wns": r["wns"],
                    "score": score, "best_so_far": best, "seed_relative_gain": best-incumbent,
                })
                files.update((rd / f"policy_after_{i+1:02d}.json", candidate))
                policy_rows.append({
                    "seed": rng_seed, "method": method, "query": i+1,
                    "baseline": snap.get("baseline"), "scale": snap.get("scale"),
                    "expected_K": sum(k*p for k,p in policy.count_probabilities().items()),
                })
            require(summary["final_policy"] == policy.snapshot(),
                    f"{run_id}: final summary policy differs from replay")
            require(abs(float(summary["best_so_far"]["proxy_reward_v0"]) - best) < 1e-8,
                    f"{run_id}: summary incumbent mismatch")
            run_row = {
                "seed": rng_seed, "method": method, "queries": len(queries),
                "valid_queries": len(queries), "cache_hits": run_hits,
                "mean_K": mean_k/BUDGET, "best_candidate_reward": max(
                    float(q["result"]["proxy_reward_v0"]) for q in queries),
                "seed_reward": incumbent, "final_reward": best,
                "gain": best - incumbent, "first_improvement_query": first,
                "best_mask": f"0x{best_mask:08x}",
            }
            run_rows.append(run_row)
            by_run[rng_seed, method] = run_row
            files.update((rd / "state.json", rd / "summary.json", rd / "run_manifest.json",
                          rd / "policy_initial.json"))
            print(f"{rng_seed} {method:<19} 16/16 gain={best-incumbent:+.6f} "
                  f"best_candidate={run_row['best_candidate_reward']:.6f} "
                  f"meanK={run_row['mean_K']:.2f} cached={run_hits}")

    require(len(run_rows) == 12 and len(query_rows) == 192,
            "Incomplete or duplicated trial records")
    for rng_seed in RNG_SEEDS:
        for a,b in (("v3_conditioned", "v2_raw_aggregate"),
                    ("v3_conditioned", "v2_frozen"),
                    ("v3_conditioned", "v2_legacy")):
            x,y = by_run[rng_seed,a], by_run[rng_seed,b]
            paired_rows.append({
                "seed": rng_seed, "method_a": a, "method_b": b,
                "final_reward_delta_a_minus_b": x["gain"] - y["gain"],
                "best_proposed_reward_delta_a_minus_b":
                    x["best_candidate_reward"] - y["best_candidate_reward"],
                "mean_K_delta_a_minus_b": x["mean_K"] - y["mean_K"],
            })
    frontier = [x for x in observations.values()
                if not any(dominates(y,x) for y in observations.values() if y is not x)]
    frontier.sort(key=lambda x: (x["area"], -x["wns"]))
    frontier_rows = [{**x, "methods": ";".join(sorted(x["methods"]))} for x in frontier]
    OUT.mkdir(parents=True, exist_ok=True)
    write_csv(OUT / "run_summary.csv", run_rows)
    write_csv(OUT / "query_trajectories.csv", query_rows)
    write_csv(OUT / "paired_effects.csv", paired_rows)
    write_csv(OUT / "policy_evolution.csv", policy_rows)
    write_csv(OUT / "pooled_physical_frontier.csv", frontier_rows)
    meta = {
        "experiment": protocol["experiment"], "protocol_sha256": sha(PROTO),
        "seed_corpus_sha256": sha(SEED), "methods": list(METHODS),
        "rng_seeds": list(RNG_SEEDS), "queries": len(query_rows),
        "valid_queries": len(query_rows), "physical_cache_hits": cache_hits,
        "physical_cache_misses": len(query_rows)-cache_hits,
        "shared_seed_reward": incumbent,
        "max_new_candidate_reward": max(x["best_candidate_reward"] for x in run_rows),
        "pooled_distinct_masks_including_seeds": len(observations),
        "pooled_frontier_size": len(frontier),
        "run_summary": run_rows,
        "paired_effects": paired_rows,
    }
    compact = OUT / "compact_summary.json"
    compact.write_text(json.dumps(meta,indent=2,sort_keys=True) + "\n")
    files.update((compact, *(OUT / name for name in (
        "run_summary.csv", "query_trajectories.csv", "paired_effects.csv",
        "policy_evolution.csv", "pooled_physical_frontier.csv"))))
    # Include prior validated gradient evidence if present, but never synthesize it.
    files = sorted(files)
    for p in files:
        require(p.is_file(), f"Missing reproducibility artifact: {p}")
    manifest = OUT / "file_manifest.json"
    manifest.write_text(json.dumps({str(p.relative_to(ROOT)):
            {"sha256":sha(p), "bytes":p.stat().st_size} for p in files},
            indent=2,sort_keys=True) + "\n")
    ARCHIVE.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(ARCHIVE, "w", compression=zipfile.ZIP_DEFLATED,
                         compresslevel=9) as z:
        for p in (manifest, *files):
            z.write(p, p.relative_to(ROOT))
    with zipfile.ZipFile(ARCHIVE) as z:
        require(z.testzip() is None, "Archive integrity failed")
    print("="*89)
    print(f"PASS: 12 replayed trajectories; 192 valid queries; "
          f"cache hits={cache_hits}, misses={192-cache_hits}")
    print(f"Seed incumbent={incumbent:.6f}; "
          f"best new candidate={meta['max_new_candidate_reward']:.6f}")
    print(f"Pooled unique masks (including seeds)={len(observations)}, "
          f"frontier points={len(frontier)}")
    print("Archive:",ARCHIVE)
    print("Archive bytes:",ARCHIVE.stat().st_size)
    print("Archive SHA256:",sha(ARCHIVE))


if __name__ == "__main__":
    main()
