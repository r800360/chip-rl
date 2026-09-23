"""Read-only audit of the preregistered 16/64-bit 384-query chip-rl experiment.

Run from the repository root:
    python -m experiments.package_popcount_freshwidth_search_v1

No EDA, no new proposals, no policy-source changes. Outputs only under
results/popcount_freshwidth_search_v1/audit/.
"""
from __future__ import annotations

import csv
import hashlib
import json
import math
import subprocess
import zipfile
from collections import defaultdict
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.rl_env import is_valid_result
from chiprl.popcount_tree_widths_v1 import name
from experiments.preregister_popcount_freshwidth_search_v1 import verify
from experiments.popcount_freshwidth_search_v1 import (
    BUDGET, METHODS, RNG_SEEDS, FREEZE, PROTOCOL, PILOT,
    init_policy, learn, propose, read_inputs, score_of, seed_path,
)

WIDTHS = (16, 64)
OUT = ROOT / "results/popcount_freshwidth_search_v1/audit"
FP_KEYS = (
    "schema_version", "benchmark", "top_module", "testbench_sha256",
    "reference_rtl_sha256", "orfs_config_sha256", "sdc_sha256",
    "formal_seq", "or_image_id", "orfs_git_commit", "verilator",
)


def read_json(path: Path):
    if not path.is_file():
        raise FileNotFoundError(path)
    return json.loads(path.read_text())


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def safe_file(path: Path) -> Path:
    path = path.resolve()
    require(path.is_file(), f"Missing input: {path}")
    require(path.is_relative_to(ROOT.resolve()), f"Path outside repository: {path}")
    return path


def add_file(files: set[Path], path: Path):
    files.add(safe_file(path))


def to_csv(path: Path, rows: list[dict], fields: list[str]):
    with path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)


def audit_one(width, method, seed, seed_rows, proto, files):
    nm = name(width)
    run_id = f"freshwidth_search_v1_{method}_seed_{seed}"
    run_dir = ROOT / "results/rl_runs" / nm / run_id
    state = read_json(run_dir / "state.json")
    meta = read_json(run_dir / "run_manifest.json")
    run_summary = read_json(run_dir / "summary.json")
    initial = read_json(run_dir / "policy_initial.json")

    require(meta == {
        "experiment": "popcount_freshwidth_search_v1",
        "benchmark": nm,
        "method": method,
        "rng_seed": seed,
        "protocol_sha256": sha(PROTOCOL),
        "seed_results_sha256": sha(seed_path(width)),
    }, f"Run manifest mismatch: {run_id}")
    for key, expected in (("benchmark", nm), ("width", width),
                          ("budget", BUDGET), ("mask_bits", width-1),
                          ("run_id", run_id)):
        require(state.get(key) == expected, f"{run_id}: state {key} mismatch")
    queries = state["queries"]
    require(len(queries) == BUDGET, f"{run_id}: incomplete {len(queries)}/{BUDGET}")
    require(run_summary["queries"] == BUDGET, f"{run_id}: incomplete summary")

    policy = init_policy(width, seed_rows)
    require(initial == policy.snapshot(), f"{run_id}: initial policy mismatch")
    seen = {int(r["boundary_mask"]) for r in seed_rows}
    archive = [dict(r) for r in seed_rows]
    incumbent = max(seed_rows, key=lambda r: r["proxy_reward_v0"])
    seed_reward = incumbent["proxy_reward_v0"]
    incumbent_reward = seed_reward
    first_improvement = None
    cached = 0
    query_out = []
    fp_seed = seed_rows[0]["fingerprint"]
    expected_sources = (16, 0) if method == "v3_global" else (
        (0, 16) if method == "uniform_local" else (8, 8))
    actual_global = actual_local = 0

    for i, q in enumerate(queries):
        ctx = f"{nm}/{method}/{seed}/query_{i+1}"
        mask = int(q["boundary_mask"])
        require(q["query_index"] == i, f"{ctx}: noncontiguous query index")
        require(mask not in seen and 0 <= mask < (1 << (width-1)), f"{ctx}: duplicate or out-of-range mask")
        require(int(q["mask"], 0) == mask, f"{ctx}: formatted mask mismatch")
        predicted, src, parent = propose(method, i, policy, archive, seen, seed)
        require(mask == predicted, f"{ctx}: policy replay mismatch {mask:#x} != {predicted:#x}")
        require(q.get("proposal_source") == src, f"{ctx}: proposal source mismatch")
        require(q.get("parent_mask") == parent, f"{ctx}: local parent mismatch")
        if src == "local":
            require((parent ^ mask).bit_count() == 1, f"{ctx}: local action is not one-flip")
        else:
            require(parent is None, f"{ctx}: global action has a local parent")
        actual_global += (src == "global")
        actual_local += (src == "local")

        r = q.get("result")
        require(q["status"] == "success" and r is not None and is_valid_result(r)
                and r.get("synthesis_ok") is True, f"{ctx}: unsuccessful query")
        for key in FP_KEYS:
            require(r["fingerprint"].get(key) == fp_seed.get(key),
                    f"{ctx}: evaluator fingerprint mismatch {key}")
        require(r["benchmark"] == nm, f"{ctx}: wrong benchmark")
        require(isinstance(r.get("cache_hit"), bool), f"{ctx}: cache flag missing")
        reward = float(r["proxy_reward_v0"])
        expected_reward = -0.001 * float(r["area"]) + 10 * float(r["wns"])
        require(abs(reward - expected_reward) < 1e-5,
                f"{ctx}: proxy reward mismatch {reward} != {expected_reward}")
        cached += int(r["cache_hit"])

        # The evaluator may return the source candidate path for a cache hit;
        # also archive this run's generated RTL using the known env naming.
        own_rtl = ROOT / "rtl/rl" / nm / run_id / f"query_{i:03d}_{mask:0{(width-1+3)//4}x}.v"
        add_file(files, own_rtl)
        require(sha(own_rtl) == r["fingerprint"]["rtl_sha256"], f"{ctx}: generated RTL fingerprint mismatch")
        returned = ROOT / r["candidate"]
        if returned.is_file():
            require(sha(returned) == r["fingerprint"]["rtl_sha256"], f"{ctx}: returned RTL hash mismatch")
            add_file(files, returned)
        metric = ROOT / "results/evaluations" / nm / f"{r['evaluation_id']}.metrics.json"
        if metric.is_file():
            add_file(files, metric)

        pre_seen = set(seen)
        learn(method, src, policy, mask, score_of(q), pre_seen)
        seen.add(mask)
        archive.append({**r, "boundary_mask": mask})
        checkpoint = read_json(run_dir / f"policy_after_{i+1:02d}.json")
        require(checkpoint == policy.snapshot(), f"{ctx}: saved policy checkpoint/replay mismatch")
        if method in ("uniform_local", "frozen_hybrid"):
            require(checkpoint == initial, f"{ctx}: supposedly frozen policy changed")
        incumbent_reward = max(incumbent_reward, reward)
        if first_improvement is None and incumbent_reward > seed_reward + 1e-9:
            first_improvement = i + 1
        query_out.append({
            "width": width, "benchmark": nm, "method": method, "seed": seed,
            "query": i+1, "source": src, "parent_mask": "" if parent is None else hex(parent),
            "mask": hex(mask), "K": mask.bit_count(), "reward": reward,
            "incumbent": incumbent_reward, "seed_reward": seed_reward,
            "area": r["area"], "wns": r["wns"], "power_w": r.get("power_w"),
            "cached": int(r["cache_hit"]), "evaluation_id": r["evaluation_id"],
        })

    require((actual_global, actual_local) == expected_sources,
            f"{run_id}: incorrect fixed source allocation")
    require(run_summary["global_queries"] == actual_global
            and run_summary["local_queries"] == actual_local,
            f"{run_id}: summary source counts mismatch")
    require(run_summary["final_policy"] == policy.snapshot(),
            f"{run_id}: final policy mismatch")
    require(abs(run_summary["best_so_far"]["proxy_reward_v0"]-incumbent_reward)<1e-9,
            f"{run_id}: incumbent summary mismatch")
    require(abs(run_summary["initial_reward"]-seed_reward)<1e-9,
            f"{run_id}: initial reward mismatch")

    # Only input files and previously written run records enter this ZIP.
    for p in run_dir.glob("*.json"):
        add_file(files, p)
    for p in (run_dir / "state.json", run_dir / "summary.json"):
        add_file(files, p)
    return {
        "width": width, "benchmark": nm, "method": method, "seed": seed,
        "queries": len(queries), "valid_queries": len(queries), "cache_hits": cached,
        "fresh_physical": len(queries)-cached, "global_queries": actual_global,
        "local_queries": actual_local, "first_improvement": first_improvement,
        "seed_reward": seed_reward, "final_reward": incumbent_reward,
        "reward_gain": incumbent_reward-seed_reward,
        "best_observed_mask": hex(max(archive, key=lambda x: x["proxy_reward_v0"])["boundary_mask"]),
    }, query_out


def main():
    # This verifies all preregistered source hashes and physical seed fingerprints.
    verify()
    files: set[Path] = set()
    for p in (PROTOCOL, PILOT, FREEZE,
              ROOT / "experiments/popcount_tree_freshwidth_pilot_v1.py",
              ROOT / "experiments/preregister_popcount_freshwidth_search_v1.py",
              ROOT / "experiments/popcount_freshwidth_search_v1.py",
              ROOT / "experiments/run_popcount_freshwidth_search_v1.sh",
              ROOT / "experiments/smoke_popcount_freshwidth_search_v1.py"):
        add_file(files, p)
    for p in (ROOT / "chiprl").glob("*.py"):
        add_file(files, p)
    for width in WIDTHS:
        nm = name(width)
        for p in (ROOT / "rtl/reference" / f"{nm}_ref.v",
                  ROOT / "rtl" / nm / "baseline.v",
                  ROOT / "sim" / f"tb_{nm}.sv",
                  ROOT / "orfs" / nm / "config.mk",
                  ROOT / "orfs" / nm / "constraint.sdc",
                  ROOT / "results/popcount_freshwidth_baseline_v1" / f"{nm}.json"):
            add_file(files, p)
        for suffix in ("results", "frontier", "summary"):
            add_file(files, ROOT / "results" / f"{nm}_arch_seed_v1" / f"{suffix}.json")
        for p in (ROOT / "rtl/generated" / f"{nm}_arch_seed_v1").glob("*.v"):
            add_file(files, p)

    runs, queries = [], []
    for width in WIDTHS:
        _, seed_rows = read_inputs(width)
        for method in METHODS:
            for seed in RNG_SEEDS:
                row, qrows = audit_one(width, method, seed, seed_rows, None, files)
                runs.append(row)
                queries.extend(qrows)
                first = '-' if row["first_improvement"] is None else row["first_improvement"]
                print(f"{row['benchmark']:17} {method:14} {seed} "
                      f"gain={row['reward_gain']:+.6f} first={str(first):>2} "
                      f"cached={row['cache_hits']:2d}/16")
    require(len(runs) == 24 and len(queries) == 384, "Wrong run/query totals")

    by = {(r["width"],r["seed"],r["method"]):r for r in runs}
    pairs = []
    for width in WIDTHS:
        for seed in RNG_SEEDS:
            v3h = by[(width,seed,"v3_hybrid")]["reward_gain"]
            frz = by[(width,seed,"frozen_hybrid")]["reward_gain"]
            glb = by[(width,seed,"v3_global")]["reward_gain"]
            loc = by[(width,seed,"uniform_local")]["reward_gain"]
            pairs.append({"width":width,"seed":seed,
                          "v3_hybrid_gain":v3h,"frozen_hybrid_gain":frz,
                          "hybrid_learning_effect":v3h-frz,
                          "v3_global_gain":glb,"uniform_local_gain":loc,
                          "global_minus_local":glb-loc})

    all_unique = defaultdict(dict)
    for width in WIDTHS:
        _, sr = read_inputs(width)
        for s in sr:
            all_unique[width][int(s["boundary_mask"])] = {
                **s, "source_methods": {"seed"}}
    for r in queries:
        width, mask = r["width"], int(r["mask"],0)
        existing = all_unique[width].get(mask)
        if existing is not None:
            require(abs(existing["area"] - r["area"]) < 1e-8
                    and abs(existing["wns"] - r["wns"]) < 1e-8,
                    f"Cross-run physical discrepancy: width={width} mask={mask:#x}")
            existing["source_methods"].add(r["method"])
        else:
            all_unique[width][mask] = {
                "area":r["area"],"wns":r["wns"],"proxy_reward_v0":r["reward"],
                "source_methods":{r["method"]}}
    frontier = []
    for width, masks in all_unique.items():
        for mask, a in masks.items():
            if not any((b["area"] <= a["area"] and b["wns"] >= a["wns"]
                       and (b["area"] < a["area"] or b["wns"] > a["wns"]))
                       for om, b in masks.items() if om != mask):
                frontier.append({"width":width,"mask":hex(mask),
                                 "area":a["area"],"wns":a["wns"],
                                 "reward":a["proxy_reward_v0"],
                                 "source_methods":";".join(sorted(a["source_methods"]))})

    OUT.mkdir(parents=True, exist_ok=True)
    run_fields = list(runs[0])
    q_fields = list(queries[0])
    pair_fields = list(pairs[0])
    to_csv(OUT / "run_summary.csv", runs, run_fields)
    to_csv(OUT / "query_trajectories.csv", queries, q_fields)
    to_csv(OUT / "paired_effects.csv", pairs, pair_fields)
    to_csv(OUT / "pooled_physical_frontier.csv", frontier,
           ["width","mask","area","wns","reward","source_methods"])
    manifest = {
        "experiment":"popcount_freshwidth_global_local_v1",
        "source_commit_at_audit": subprocess.check_output(["git","rev-parse","HEAD"],cwd=ROOT,text=True).strip(),
        "protocol_sha256":sha(PROTOCOL), "seed_freeze_sha256":sha(FREEZE),
        "completed_runs":len(runs), "valid_queries":len(queries),
        "cache_hits":sum(r["cache_hits"] for r in runs),
        "fresh_physical":sum(r["fresh_physical"] for r in runs),
        "runs":runs,"paired_results":pairs,
        "unique_masks_by_width":{str(w):len(v) for w,v in all_unique.items()},
        "frontier_points_by_width":{str(w):sum(f["width"]==w for f in frontier) for w in WIDTHS},
    }
    summary = OUT / "compact_summary.json"
    summary.write_text(json.dumps(manifest,indent=2,sort_keys=True)+"\n")
    for p in (ROOT / "experiments/package_popcount_freshwidth_search_v1.py",
              OUT / "run_summary.csv", OUT / "query_trajectories.csv",
              OUT / "paired_effects.csv", OUT / "pooled_physical_frontier.csv",
              summary):
        add_file(files,p)
    hashes = {str(p.relative_to(ROOT)):{"sha256":sha(p),"bytes":p.stat().st_size}
              for p in sorted(files)}
    (OUT / "file_manifest.json").write_text(
        json.dumps({"experiment":manifest["experiment"],"files":hashes},indent=2,sort_keys=True)+"\n")
    zipfile_path = OUT / "popcount_freshwidth_search_results_bundle.zip"
    with zipfile.ZipFile(zipfile_path,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=8) as z:
        for p in sorted(files | {OUT / "file_manifest.json"}):
            z.write(p,str(p.relative_to(ROOT)))
    with zipfile.ZipFile(zipfile_path) as z:
        require(z.testzip() is None, "ZIP integrity check failed")
    print("="*89)
    print(f"PASS: {len(runs)}/24 runs, {len(queries)}/384 valid queries; "
          f"cache hits={manifest['cache_hits']}, fresh={manifest['fresh_physical']}")
    for p in pairs:
        print(f"width={p['width']} seed={p['seed']} "
              f"hybrid−frozen={p['hybrid_learning_effect']:+.6f} "
              f"global−local={p['global_minus_local']:+.6f}")
    print("Summary:",summary)
    print("Archive:",zipfile_path)
    print("Archive bytes:",zipfile_path.stat().st_size)
    print("Archive SHA256:",sha(zipfile_path))


if __name__=="__main__":
    main()
