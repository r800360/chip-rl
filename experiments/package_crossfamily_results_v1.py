"""Read-only audit, paired summary, and compact archive of cross-family study.

Place at experiments/package_crossfamily_results_v1.py in chip-rl, then run:
    python -m experiments.package_crossfamily_results_v1
No EDA, no policy sampling, and no mutation of measured source records.
"""
from __future__ import annotations

import csv
import hashlib
import json
import statistics
import subprocess
import zipfile
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results/crossfamily_policy_causality_v1"
FAMILIES = ("cmp32", "popcount32", "priority32")
METHODS = ("v1_learn", "v2_learn", "v2_frozen", "count_matched_uniform")
RNG_SEEDS = (20260923, 20260924, 20260925)
BUDGET = 16
FINGERPRINT_KEYS = (
    "schema_version", "benchmark", "top_module", "testbench_sha256",
    "reference_rtl_sha256", "orfs_config_sha256", "sdc_sha256",
    "formal_seq", "or_image_id", "orfs_git_commit", "verilator",
)


def require(condition, description):
    if not condition:
        raise RuntimeError(description)


def load(path):
    require(path.is_file(), f"missing: {path}")
    return json.loads(path.read_text())


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def valid(row):
    return bool(row and row.get("functional") is True
                and row.get("formal_ok") is True
                and row.get("synthesis_ok") is True
                and row.get("place_route_ok") is True
                and all(row.get(k) is not None for k in
                        ("area", "wns", "proxy_reward_v0")))


def compare_fingerprint(row, reference, context):
    fingerprint = row.get("fingerprint")
    require(isinstance(fingerprint, dict), f"{context}: no fingerprint")
    for key in FINGERPRINT_KEYS:
        require(fingerprint.get(key) == reference.get(key),
                f"{context}: fingerprint mismatch {key}")


def write_csv(path, rows, fields):
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def dominates(a, b):
    return (a["area"] <= b["area"] and a["wns"] >= b["wns"]
            and (a["area"] < b["area"] or a["wns"] > b["wns"]))


def main():
    protocol_path = ROOT / "experiments/protocol_crossfamily_v1.json"
    protocol = load(protocol_path)
    require(protocol["families"] == list(FAMILIES), "unexpected protocol families")
    require(protocol["search_methods"] == list(METHODS), "unexpected protocol methods")
    require(protocol["search_policy_seeds"] == list(RNG_SEEDS), "unexpected run RNG seeds")
    require(protocol["budget_per_run"] == BUDGET, "unexpected budget")
    proto_sha = sha(protocol_path)

    freeze = load(ROOT / "experiments/crossfamily_shared_seed_freeze_v1.json")
    require(freeze["protocol_sha256"] == proto_sha,
            "protocol differs from pre-search shared seed freeze")
    for name, digest in protocol["frozen_source_sha256"].items():
        require(sha(ROOT / name) == digest, f"frozen policy/environment changed: {name}")

    amendment_path = ROOT / "experiments/crossfamily_rng_amendment_v1.json"
    amendment = load(amendment_path)
    require(amendment["original_protocol_sha256"] == proto_sha,
            "RNG amendment refers to different protocol")
    require(sha(ROOT / "experiments/crossfamily_runner.py") ==
            amendment["corrected_runner_sha256"],
            "runner differs from frozen amended RNG version")

    seed_results = {}
    seed_rewards = {}
    reference_fps = {}
    files = {protocol_path, amendment_path,
             ROOT / "experiments/crossfamily_shared_seed_freeze_v1.json"}
    run_rows = []
    query_rows = []
    frontier_rows = []
    run_summaries = {}
    observations = defaultdict(dict)
    total_valid = 0
    total_cache_hit = 0
    missing_cache_field = 0

    for family in FAMILIES:
        seed_dir = ROOT / "results" / f"{family}_shared_seed"
        seeds_path = seed_dir / "results.json"
        rows = load(seeds_path)
        require(len(rows) == 8, f"{family}: expected eight seeds")
        expected_masks = [int(mask, 0) for mask in protocol["shared_seed_masks"]]
        require([int(x["boundary_mask"]) for x in rows] == expected_masks,
                f"{family}: shared seed masks differ from protocol")
        require(all(valid(x) for x in rows), f"{family}: invalid seed")
        require(all(x.get("protocol_sha256") == proto_sha for x in rows),
                f"{family}: seed protocol hash mismatch")
        require(sha(seeds_path) == freeze["families"][family]["results_sha256"],
                f"{family}: shared seeds changed after freeze")
        fp = rows[0]["fingerprint"]
        for idx, row in enumerate(rows):
            compare_fingerprint(row, fp, f"{family} seed {idx + 1}")
        seed_results[family] = rows
        seed_rewards[family] = max(float(r["proxy_reward_v0"]) for r in rows)
        reference_fps[family] = fp
        for p in seed_dir.glob("*.json"):
            files.add(p)
        for p in (ROOT / "rtl/generated" / f"{family}_shared_seed").glob("*.v"):
            files.add(p)
        for row in rows:
            observations[family][int(row["boundary_mask"])] = {
                "row": row, "methods": {"shared_seed"}
            }

    print("=" * 91)
    print("CROSS-FAMILY SEARCH AUDIT (no EDA)")
    print("=" * 91)
    for family in FAMILIES:
        print(f"\n{family}  seed incumbent={seed_rewards[family]:.6f}")
        for rng_seed in RNG_SEEDS:
            initial_v2 = None
            for method in METHODS:
                runid = f"{method}_seed_{rng_seed}"
                run_dir = ROOT / "results/rl_runs" / family / runid
                state = load(run_dir / "state.json")
                summary = load(run_dir / "summary.json")
                require(state.get("benchmark") == family and state.get("width") == 32
                        and state.get("mask_bits") == 31 and state.get("budget") == BUDGET
                        and state.get("run_id") == runid,
                        f"{family}/{runid}: run metadata mismatch")
                queries = state["queries"]
                require(len(queries) == BUDGET,
                        f"{family}/{runid}: expected 16 queries, got {len(queries)}")
                require(summary.get("benchmark") == family
                        and summary.get("method") == method
                        and summary.get("policy_seed") == rng_seed
                        and summary.get("queries") == BUDGET,
                        f"{family}/{runid}: summary metadata mismatch")
                initial = load(run_dir / "policy_initial.json")
                final = load(run_dir / "policy_after_16.json")
                for i in range(1, BUDGET + 1):
                    require((run_dir / f"policy_after_{i:02d}.json").is_file(),
                            f"{family}/{runid}: missing policy snapshot after {i}")
                if method in ("v2_learn", "v2_frozen", "count_matched_uniform"):
                    if initial_v2 is None:
                        initial_v2 = initial
                    else:
                        require(initial == initial_v2,
                                f"{family}/{runid}: v2 initialization mismatch")
                if method in ("v2_frozen", "count_matched_uniform"):
                    require(initial == final,
                            f"{family}/{runid}: no-learning policy changed")

                seen = {int(row["boundary_mask"]) for row in seed_results[family]}
                incumbent = seed_rewards[family]
                first = None
                valid_count = 0
                cache_hits = 0
                mean_k = 0
                for idx, query in enumerate(queries):
                    mask = int(query["boundary_mask"])
                    require(query["query_index"] == idx and 0 <= mask < (1 << 31),
                            f"{family}/{runid}: invalid index or mask at query {idx + 1}")
                    require(mask not in seen,
                            f"{family}/{runid}: repeated query or shared-seed mask {mask:#x}")
                    seen.add(mask)
                    mean_k += mask.bit_count()
                    result = query.get("result")
                    is_ok = valid(result)
                    status = query["status"]
                    require(status in ("success", "evaluation_failed", "evaluator_exception"),
                            f"{family}/{runid}: unknown query status {status}")
                    require(is_ok == (status == "success"),
                            f"{family}/{runid}: status and physical result disagree at {idx + 1}")
                    require(status != "evaluator_exception",
                            f"{family}/{runid}: infrastructure exception at query {idx + 1}")
                    score = -1000.0
                    if result is not None:
                        compare_fingerprint(result, reference_fps[family],
                                            f"{family}/{runid} query {idx + 1}")
                        score = float(result["proxy_reward_v0"]) if result.get("proxy_reward_v0") is not None else -1000.0
                        if result.get("cache_hit") is True:
                            cache_hits += 1
                            total_cache_hit += 1
                        elif result.get("cache_hit") is None:
                            missing_cache_field += 1
                    if is_ok:
                        valid_count += 1
                        total_valid += 1
                        incumbent = max(incumbent, score)
                        entry = observations[family].setdefault(mask, {
                            "row": result, "methods": set()
                        })
                        entry["methods"].add(method)
                    if first is None and incumbent > seed_rewards[family] + 1e-9:
                        first = idx + 1
                    query_rows.append({
                        "benchmark": family, "rng_seed": rng_seed, "method": method,
                        "query": idx + 1, "mask": f"0x{mask:08x}",
                        "boundary_count": mask.bit_count(), "status": status,
                        "valid": is_ok, "cache_hit": result.get("cache_hit") if result else None,
                        "area": result.get("area") if result else None,
                        "wns": result.get("wns") if result else None,
                        "score": score, "incumbent_reward": incumbent,
                        "improvement_over_seed": incumbent - seed_rewards[family],
                    })
                require(abs(float(summary["seed_reward"]) - seed_rewards[family]) < 1e-8,
                        f"{family}/{runid}: seed reward mismatch")
                require(abs(float(summary["best_so_far"]["proxy_reward_v0"]) - incumbent) < 1e-8,
                        f"{family}/{runid}: final summary score mismatch")
                run_row = {
                    "benchmark": family, "rng_seed": rng_seed, "method": method,
                    "queries": BUDGET, "valid_queries": valid_count,
                    "cache_hits": cache_hits, "first_improvement": first,
                    "first_improvement_censored17": first if first else 17,
                    "mean_boundaries": mean_k / BUDGET,
                    "seed_reward": seed_rewards[family], "final_reward": incumbent,
                    "final_improvement": incumbent - seed_rewards[family],
                    "best_mask": summary["best_so_far"]["mask"],
                }
                run_rows.append(run_row)
                run_summaries[(family, rng_seed, method)] = run_row
                for p in run_dir.glob("*.json"):
                    files.add(p)
                for p in (ROOT / "rtl/rl" / family / runid).glob("*.v"):
                    files.add(p)
                print(f"  {rng_seed} {method:<22} {valid_count:2d}/16 "
                      f"first={str(first or '-'):>2} "
                      f"gain={run_row['final_improvement']:+.6f} "
                      f"meanK={run_row['mean_boundaries']:.2f} "
                      f"cached={cache_hits}")

    require(len(run_rows) == 36 and len(query_rows) == 576,
            "unexpected total completed runs or query count")
    paired_rows = []
    comparisons = (
        ("v2_learn", "v2_frozen"),
        ("v2_frozen", "count_matched_uniform"),
        ("v2_learn", "v1_learn"),
    )
    for family in FAMILIES:
        for rng_seed in RNG_SEEDS:
            for a, b in comparisons:
                r1 = run_summaries[(family, rng_seed, a)]
                r2 = run_summaries[(family, rng_seed, b)]
                paired_rows.append({
                    "benchmark": family, "rng_seed": rng_seed,
                    "method_a": a, "method_b": b,
                    "delta_a_minus_b": r1["final_improvement"] - r2["final_improvement"],
                    "first_a_censored17": r1["first_improvement_censored17"],
                    "first_b_censored17": r2["first_improvement_censored17"],
                })
    for family in FAMILIES:
        # Evaluator results from generated candidates do not carry
        # boundary_mask; use the mask-keyed observation archive.
        frontier_masks = set()
        for mask, entry in observations[family].items():
            row = entry["row"]
            if not any(dominates(other["row"], row)
                       for other_mask, other in observations[family].items()
                       if other_mask != mask):
                frontier_masks.add(mask)
        for mask in sorted(frontier_masks,
                           key=lambda m: observations[family][m]["row"]["area"]):
            entry = observations[family][mask]
            row = entry["row"]
            frontier_rows.append({
                "benchmark": family, "mask": f"0x{mask:08x}",
                "boundaries": mask.bit_count(), "area": row["area"],
                "wns": row["wns"], "reward": row["proxy_reward_v0"],
                "discovered_by": ";".join(sorted(entry["methods"])),
            })

    OUT.mkdir(parents=True, exist_ok=True)
    write_csv(OUT / "run_summary.csv", run_rows, list(run_rows[0]))
    write_csv(OUT / "query_trajectories.csv", query_rows, list(query_rows[0]))
    write_csv(OUT / "paired_comparisons.csv", paired_rows, list(paired_rows[0]))
    write_csv(OUT / "observed_frontiers.csv", frontier_rows, list(frontier_rows[0]))
    archive_summary = {
        "experiment": "crossfamily_policy_causality_v1",
        "source_commit": subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
        ).strip(),
        "protocol_sha256": proto_sha,
        "runs": 36, "logical_queries": 576,
        "valid_queries": total_valid,
        "invalid_queries": 576 - total_valid,
        "cache_hits": total_cache_hit,
        "cache_hit_field_missing": missing_cache_field,
        "shared_seed_scores": seed_rewards,
        "run_summaries": run_rows,
        "paired_comparisons": paired_rows,
        "unique_observed_masks": {family: len(observations[family])
                                  for family in FAMILIES},
    }
    summary_path = OUT / "compact_summary.json"
    summary_path.write_text(json.dumps(archive_summary, indent=2,
                                       sort_keys=True) + "\n")

    files.update((OUT / x for x in (
        "run_summary.csv", "query_trajectories.csv", "paired_comparisons.csv",
        "observed_frontiers.csv", "compact_summary.json"
    )))
    files.update((ROOT / p for p in (
        "experiments/bootstrap_crossfamily_v1.py",
        "experiments/crossfamily_runner.py",
        "experiments/crossfamily_shared_seeds.py",
        "experiments/run_crossfamily_v1.sh",
        "experiments/README_crossfamily_v1.md",
        "experiments/smoke_crossfamily_policy_v1.py",
        "chiprl/autoregressive_policy.py", "chiprl/rl_env.py",
        "chiprl/circuit_family_generators.py", "chiprl/evaluate.py",
        "chiprl/formal.py", "chiprl/benchmarks.py",
        "experiments/addpipe36_reinforce_v1.py",
        "experiments/multiwidth_final_freeze_v1.json",
    )))
    for family in FAMILIES:
        files.update((ROOT / p for p in (
            f"rtl/reference/{family}_ref.v", f"sim/tb_{family}.sv",
            f"rtl/{family}/baseline.v", f"orfs/{family}/config.mk",
            f"orfs/{family}/constraint.sdc",
        )))
    files = sorted(files)
    require(all(p.is_file() for p in files),
            "required source/result artifact missing during packaging")
    manifest = {str(p.relative_to(ROOT)): {"sha256": sha(p), "bytes": p.stat().st_size}
                for p in files}
    manifest_path = OUT / "file_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2,
                                        sort_keys=True) + "\n")
    files.append(manifest_path)
    archive = OUT / "crossfamily_results_bundle.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED,
                         compresslevel=8) as z:
        for p in files:
            z.write(p, p.relative_to(ROOT))
    with zipfile.ZipFile(archive) as z:
        require(z.testzip() is None, "archive CRC validation failed")
    print("\n" + "=" * 91)
    print(f"PASS: {len(run_rows)} runs, 576 unique-within-run logical queries; "
          f"{total_valid} valid, {576-total_valid} invalid; "
          f"{total_cache_hit} physical cache hits")
    for a, b in comparisons:
        values = [x["delta_a_minus_b"] for x in paired_rows
                  if x["method_a"] == a and x["method_b"] == b]
        print(f"{a} - {b}: median={statistics.median(values):+.6f} "
              f"positive={sum(x>1e-9 for x in values)}/9 "
              f"ties={sum(abs(x)<=1e-9 for x in values)}/9 "
              f"negative={sum(x<-1e-9 for x in values)}/9")
    print("Summary:", summary_path)
    print("Archive:", archive)
    print("Archive bytes:", archive.stat().st_size)
    print("Archive SHA256:", sha(archive))


if __name__ == "__main__":
    main()
