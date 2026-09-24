"""Compute every headline number once, from frozen result files.

Writes results/analysis/project_numbers.json. Documentation and the project
page quote these values, so they cannot drift from the data.
"""
from __future__ import annotations

import csv
import glob
import json
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(rel):
    return json.loads((ROOT / rel).read_text())


def routed_designs() -> int:
    n = 0
    for path in glob.glob(str(ROOT / "results/evaluations/**/*.json"), recursive=True):
        if path.endswith(".metrics.json"):
            continue
        r = json.loads(Path(path).read_text())
        if r.get("place_route_ok") and not r.get("candidate", "").startswith("rtl/repro/"):
            n += 1
    return n


def rl_pairs():
    signs = []
    for r in csv.DictReader(open(ROOT / "results/crossfamily_policy_causality_v1/paired_comparisons.csv")):
        if r["method_a"] == "v2_learn" and r["method_b"] == "v2_frozen":
            signs.append(float(r["delta_a_minus_b"]))
    for r in csv.DictReader(open(ROOT / "results/popcount_tree_v3_pilot_v1/audit/paired_effects.csv")):
        if r["method_a"] == "v3_conditioned" and r["method_b"] == "v2_frozen":
            signs.append(float(r["final_reward_delta_a_minus_b"]))
    for r in csv.DictReader(open(ROOT / "results/popcount_freshwidth_search_v1/audit/paired_effects.csv")):
        signs.append(float(r["hybrid_learning_effect"]))
    for r in csv.DictReader(open(ROOT / "results/learned_local_study_v1_audit/paired.csv")):
        signs.append(float(r["learned_local_minus_uniform"]))
        signs.append(float(r["learned_hybrid_minus_frozen"]))
    pos = sum(s > 1e-9 for s in signs)
    neg = sum(s < -1e-9 for s in signs)
    return len(signs), f"{pos} better, {neg} worse, {len(signs) - pos - neg} tied"


def main():
    out = {"routed_designs": routed_designs()}

    cert = load("results/formal/lanesum16x8_tree_reassociation_certificate_v1.json")
    per = [json.loads(Path(p).read_text())["formal_runtime_s"]
           for p in glob.glob(str(ROOT / "results/evaluations/lanesum16x8_tree/*.json"))
           if not p.endswith(".metrics.json")]
    out["formal_per_candidate_s"] = round(statistics.median(per), 2)
    out["formal_cert_s"] = round(cert["total_wall_s"], 1)
    out["formal_speedup"] = f"{(69 * 60 + 55) / statistics.median(per):,.0f}x faster"

    mf = load("results/analysis/multifidelity_v1/summary.json")
    fp = mf["per_stage"]["floorplan"]
    out.update({
        "mf_designs": mf["routed_designs"], "mf_benchmarks": fp["benchmarks"],
        "mf_floorplan_rho": f"{fp['median_spearman']:.2f}",
        "mf_floorplan_time": f"{100 * fp['median_time_fraction_of_flow']:.0f}%",
        "mf_synth_rho": f"{mf['per_stage']['synth']['median_spearman']:.2f}",
        "mf_kept": fp["true_best_kept_at_25pct"] + " benchmarks",
    })
    fid = list(csv.DictReader(open(ROOT / "results/analysis/multifidelity_v1/fidelity.csv")))
    fp_rows = [r for r in fid if r["stage"] == "floorplan"]
    out["mf_top1"] = f"{sum(r['top1_is_true_best'] == 'True' for r in fp_rows)} of {len(fp_rows)}"
    out["mf_table"] = [
        (stage, f"{100 * v['median_time_fraction_of_flow']:.0f}%", f"{v['median_spearman']:.2f}",
         v["true_best_kept_at_25pct"])
        for stage, v in mf["per_stage"].items()
    ]

    pairs, signs = rl_pairs()
    out["rl_pairs"], out["rl_signs"] = pairs, signs

    lat_path = ROOT / "results/eda_latency_v1/summary.json"
    if lat_path.is_file():
        lat = load("results/eda_latency_v1/summary.json")
        med = lat["median_seconds_single_worker"]
        thr = lat["throughput"]
        best = max(thr, key=lambda w: thr[w]["designs_per_hour"])
        out.update({
            "latency_total_s": round(med["total"], 1),
            "latency_verilator_s": round(med["verilator_build_and_sim"], 1),
            "latency_formal_s": round(med["formal_equivalence"], 2),
            "latency_orfs_s": round(med["orfs_wall"], 1),
            "latency_tool_s": round(med["orfs_tool_time_in_logs"], 1),
            "latency_overhead_s": round(med["orfs_overhead"], 1),
            "cpus": lat["cpu_count"], "best_workers": int(best),
            "best_rate": round(thr[best]["designs_per_hour"]),
            "single_rate": round(thr["1"]["designs_per_hour"]),
            "best_speedup": thr[best]["speedup"],
            "latency_identical": lat["all_runs_identical_to_frozen"],
            "throughput": thr,
        })

    ag_path = ROOT / "results/analysis/agentic_eval_v1/summary.json"
    if ag_path.is_file():
        ag = load("results/analysis/agentic_eval_v1/summary.json")
        out["agent_episodes"] = ag["episodes"]
        out["agent_cost"] = f"{ag['total_cost_usd']:.2f}"
        out["agent_improved"] = f"{sum(t['improved'] for t in ag['by_model_condition'])}/{ag['episodes']}"
        out["agent_by_model_condition"] = ag["by_model_condition"]
        out["agent_paired"] = ag["paired_full_minus_pnr_only"]
        out["agent_best_per_task"] = ag["best_per_task"]

    (ROOT / "results/analysis").mkdir(parents=True, exist_ok=True)
    (ROOT / "results/analysis/project_numbers.json").write_text(json.dumps(out, indent=2) + "\n")
    print(json.dumps({k: v for k, v in out.items() if k not in ("mf_table", "throughput", "agent_by_model_condition", "agent_best_per_task")}, indent=1))


if __name__ == "__main__":
    main()
