"""Where does evaluation time go, and how far does parallelism scale it?

32 designs with frozen results (8 seeds each from cmp32, priority32,
addpipe32 and popcount32_tree) are copied with one added comment line (new
RTL hash, so no frozen record is touched) and evaluated uncached with 1, 2,
4, 8 and 16 worker processes. For every run the metrics are compared with the
frozen originals, so any nondeterminism from parallel execution would show.

Outputs: results/eda_latency_v1/{runs.json, summary.json}
Run:     python -m experiments.eda_latency_study_v1 [--workers 1 2 4 8 16]
"""
from __future__ import annotations

import argparse
import json
import os
import statistics
import time
from pathlib import Path

from analysis.multifidelity import STAGES, elapsed_seconds
from chiprl.benchmarks import ROOT
from chiprl.parallel_eval import evaluate_many

OUT = ROOT / "results" / "eda_latency_v1"
COPIES = ROOT / "rtl" / "repro" / "latency_study_v1"
SEED_SETS = {
    "cmp32": "results/cmp32_shared_seed/results.json",
    "priority32": "results/priority32_shared_seed/results.json",
    "addpipe32": "results/addpipe32_shared_seed/results.json",
    "popcount32_tree": "results/popcount32_tree_arch_seed/results.json",
}
METRICS = ("functional", "formal_ok", "place_route_ok", "area", "wns", "cells", "power_w",
           "proxy_reward_v0")


def designs() -> list[dict]:
    out = []
    for bench, rel in SEED_SETS.items():
        rows = json.loads((ROOT / rel).read_text())
        for row in rows:
            src = ROOT / row["candidate"]
            dst = COPIES / bench / src.name
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_text(f"// latency study copy of {row['candidate']}\n" + src.read_text())
            out.append({"benchmark": bench, "candidate": dst.relative_to(ROOT).as_posix(),
                        "frozen": {k: row[k] for k in METRICS}})
    return out


def stage_times(result: dict) -> dict:
    top = result["fingerprint"]["top_module"]
    logs = ROOT / "logs" / "nangate45" / top / f"eval_{result['evaluation_id']}"
    times = {}
    for label, _, _, _, names in STAGES:
        times[label] = round(sum(elapsed_seconds(logs / f"{n}.log") for n in names), 3)
    return times


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workers", type=int, nargs="+", default=[1, 2, 4, 8, 16])
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    items = designs()
    jobs = [(d["candidate"], d["benchmark"]) for d in items]
    runs_path = OUT / "runs.json"
    runs = json.loads(runs_path.read_text()) if runs_path.is_file() else {}
    for workers in args.workers:
        if str(workers) in runs:
            continue
        start = time.time()
        results = evaluate_many(jobs, workers=workers, cache=False, clean=True)
        wall = time.time() - start
        rows = []
        for d, r in zip(items, results):
            rows.append({
                "benchmark": d["benchmark"], "candidate": d["candidate"],
                "identical_to_frozen": all(r[k] == d["frozen"][k] for k in METRICS),
                "runtime_s": r["runtime_s"], "verilator_s": r["verilator_runtime_s"],
                "formal_s": r["formal_runtime_s"], "orfs_s": r["orfs_runtime_s"],
                "stage_s": stage_times(r), "cache_hit": r["cache_hit"],
            })
        runs[str(workers)] = {"workers": workers, "wall_s": round(wall, 2), "designs": len(rows),
                              "designs_per_hour": round(3600 * len(rows) / wall, 1), "rows": rows}
        runs_path.write_text(json.dumps(runs, indent=1) + "\n")
        print(f"workers={workers}: {len(rows)} designs in {wall:.0f} s "
              f"({3600 * len(rows) / wall:.0f}/h), identical={sum(r['identical_to_frozen'] for r in rows)}",
              flush=True)

    one = runs["1"]["rows"]
    tool = [sum(r["stage_s"].values()) for r in one]
    summary = {
        "designs": len(one),
        "cpu_count": os.cpu_count(),
        "all_runs_identical_to_frozen": all(r["identical_to_frozen"] for w in runs.values() for r in w["rows"]),
        "median_seconds_single_worker": {
            "total": statistics.median(r["runtime_s"] for r in one),
            "verilator_build_and_sim": statistics.median(r["verilator_s"] for r in one),
            "formal_equivalence": statistics.median(r["formal_s"] for r in one),
            "orfs_wall": statistics.median(r["orfs_s"] for r in one),
            "orfs_tool_time_in_logs": statistics.median(tool),
            "orfs_overhead": statistics.median(r["orfs_s"] - t for r, t in zip(one, tool)),
            **{f"stage_{k}": statistics.median(r["stage_s"][k] for r in one) for k in one[0]["stage_s"]},
        },
        "throughput": {w: {"wall_s": v["wall_s"], "designs_per_hour": v["designs_per_hour"],
                           "speedup": round(runs["1"]["wall_s"] / v["wall_s"], 2)}
                       for w, v in sorted(runs.items(), key=lambda kv: int(kv[0]))},
    }
    (OUT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
