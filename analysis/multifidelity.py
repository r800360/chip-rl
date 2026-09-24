"""How well do early-stage EDA metrics predict the final routed reward?

Zero-EDA analysis. For every ORFS run already on disk it reads the metrics
that OpenROAD-flow-scripts wrote after each stage (synthesis, floorplan,
global placement, detailed placement, CTS, global route, final) plus the
per-stage wall time, and asks: if an agent scored candidates with the
stage-k proxy `-0.001 * area_k + 10 * WNS_k` instead of running the whole
flow, how faithful would that proxy be and how much time would it save?

Outputs (results/analysis/multifidelity_v1/):
  runs.csv           one row per routed design: stage metrics and stage times
  fidelity.csv       per benchmark and stage: Spearman rho, Kendall tau,
                     top-1 agreement, top-5 recall at 25% screening
  summary.json       pooled medians and time fractions
"""
from __future__ import annotations

import csv
import json
import math
import re
import statistics
from collections import defaultdict
from pathlib import Path

from scipy.stats import kendalltau, spearmanr

ROOT = Path(__file__).resolve().parents[1]
LOGS = ROOT / "logs" / "nangate45"
OUT = ROOT / "results" / "analysis" / "multifidelity_v1"

# (stage label, metrics json, WNS key, area key, logs whose time is "spent" by then)
STAGES = (
    ("synth", "1_synth.json", None, "synth__design__instance__area__stdcell",
     ("1_1_yosys_canonicalize", "1_2_yosys", "1_synth")),
    ("floorplan", "2_1_floorplan.json", "floorplan__timing__setup__ws",
     "floorplan__design__instance__area__stdcell",
     ("2_1_floorplan", "2_2_floorplan_macro", "2_3_floorplan_tapcell", "2_4_floorplan_pdn")),
    ("global_place", "3_3_place_gp.json", "globalplace__timing__setup__ws",
     "globalplace__design__instance__area__stdcell",
     ("3_1_place_gp_skip_io", "3_2_place_iop", "3_3_place_gp")),
    ("detailed_place", "3_5_place_dp.json", "detailedplace__timing__setup__ws",
     "detailedplace__design__instance__area__stdcell", ("3_4_place_resized", "3_5_place_dp")),
    ("cts", "4_1_cts.json", "cts__timing__setup__ws", "cts__design__instance__area__stdcell",
     ("4_1_cts",)),
    ("global_route", "5_1_grt.json", "globalroute__timing__setup__ws",
     "globalroute__design__instance__area__stdcell", ("5_1_grt",)),
    ("final", "6_report.json", "finish__timing__setup__ws", "finish__design__instance__area",
     ("5_2_route", "5_3_fillcell", "6_1_fill", "6_1_merge", "6_report")),
)
BENCHMARK_OF_DIR = {"addpipe": "addpipe8"}
ELAPSED = re.compile(r"^Elapsed time: (?:(\d+):)?(\d+):(\d+(?:\.\d+)?)")


def load(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return {}


def elapsed_seconds(log: Path) -> float:
    if not log.is_file():
        return 0.0
    total = 0.0
    for line in log.read_text(errors="replace").splitlines():
        m = ELAPSED.match(line)
        if m:
            h, mnt, s = m.groups()
            total = (int(h) * 3600 if h else 0) + int(mnt) * 60 + float(s)
    return total


def proxy(area, wns):
    return -0.001 * area + 10.0 * wns


def collect() -> list[dict]:
    rows = []
    for bench_dir in sorted(LOGS.iterdir()):
        benchmark = BENCHMARK_OF_DIR.get(bench_dir.name, bench_dir.name)
        for run in sorted(bench_dir.glob("eval_*")):
            final = load(run / "6_report.json")
            if "finish__timing__setup__ws" not in final:
                continue
            row = {"benchmark": benchmark, "evaluation_id": run.name[5:]}
            ok = True
            elapsed = 0.0
            for label, fname, wns_key, area_key, logs in STAGES:
                m = load(run / fname)
                area = m.get(area_key)
                wns = m.get(wns_key) if wns_key else None
                if area is None or (wns_key and wns is None):
                    ok = False
                    break
                elapsed += sum(elapsed_seconds(run / f"{name}.log") for name in logs)
                row[f"{label}_area"] = float(area)
                row[f"{label}_wns"] = None if wns is None else float(wns)
                row[f"{label}_cum_s"] = round(elapsed, 3)
            if ok:
                row["final_reward"] = round(proxy(row["final_area"], row["final_wns"]), 6)
                rows.append(row)
    return rows


def stage_score(row: dict, label: str) -> float:
    if label == "synth":
        return -row["synth_area"]  # synthesis gives area only
    return proxy(row[f"{label}_area"], row[f"{label}_wns"])


def fidelity(rows: list[dict]) -> list[dict]:
    by_bench = defaultdict(list)
    for r in rows:
        by_bench[r["benchmark"]].append(r)
    out = []
    for bench, group in sorted(by_bench.items()):
        # Deduplicate identical physical outcomes (different RTL, same result).
        truth = [r["final_reward"] for r in group]
        n = len(group)
        if n < 10 or len({round(t, 6) for t in truth}) < 5:
            continue
        best_true = max(truth)
        top5 = sorted(range(n), key=lambda i: -truth[i])[:5]
        for label, *_ in STAGES[:-1]:
            scores = [stage_score(r, label) for r in group]
            rho = spearmanr(scores, truth).statistic
            tau = kendalltau(scores, truth).statistic
            order = sorted(range(n), key=lambda i: -scores[i])
            keep = order[: max(1, math.ceil(0.25 * n))]
            out.append({
                "benchmark": bench,
                "stage": label,
                "designs": n,
                "spearman_rho": round(float(rho), 4),
                "kendall_tau": round(float(tau), 4),
                "top1_is_true_best": truth[order[0]] == best_true,
                "true_best_kept_at_25pct": any(truth[i] == best_true for i in keep),
                "top5_recall_at_25pct": round(len(set(keep) & set(top5)) / 5, 3),
                "median_cum_time_frac": round(statistics.median(
                    r[f"{label}_cum_s"] / r["final_cum_s"] for r in group), 4),
            })
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = collect()
    with (OUT / "runs.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    fid = fidelity(rows)
    with (OUT / "fidelity.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(fid[0]))
        w.writeheader()
        w.writerows(fid)
    summary = {"routed_designs": len(rows),
               "benchmarks": sorted({r["benchmark"] for r in rows}),
               "per_stage": {}}
    for label, *_ in STAGES[:-1]:
        sub = [x for x in fid if x["stage"] == label]
        summary["per_stage"][label] = {
            "benchmarks": len(sub),
            "median_spearman": round(statistics.median(x["spearman_rho"] for x in sub), 4),
            "min_spearman": round(min(x["spearman_rho"] for x in sub), 4),
            "true_best_kept_at_25pct": f"{sum(x['true_best_kept_at_25pct'] for x in sub)}/{len(sub)}",
            "median_top5_recall_at_25pct": statistics.median(x["top5_recall_at_25pct"] for x in sub),
            "median_time_fraction_of_flow": statistics.median(x["median_cum_time_frac"] for x in sub),
        }
    summary["median_flow_tool_seconds"] = statistics.median(r["final_cum_s"] for r in rows)
    (OUT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
