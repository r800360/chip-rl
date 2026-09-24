"""Summarize the agentic RTL eval (results/agentic_eval_v1) into tables."""
from __future__ import annotations

import csv
import glob
import json
import statistics
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNS = ROOT / "results" / "agentic_eval_v1"
OUT = ROOT / "results" / "analysis" / "agentic_eval_v1"
MODELS = ["claude-haiku-4-5", "claude-sonnet-5", "claude-opus-5"]
TASKS = ["addpipe32", "cmp32", "priority32", "popcount32"]
CONDITIONS = ["full_tools", "pnr_only"]
EPS = 1e-9


def load() -> list[dict]:
    rows = []
    for path in sorted(glob.glob(str(RUNS / "*" / "episode.json"))):
        e = json.loads(Path(path).read_text())
        subs = e["submissions"]
        failed_verification = sum(s["status"] in ("SIMULATION_FAILED", "FORMAL_FAILED", "REJECTED")
                                  for s in subs)
        delta = e["best_minus_baseline"]
        rows.append({
            "episode_id": e["episode_id"], "model": e["model"], "task": e["task"],
            "condition": e["condition"], "rep": e["rep"],
            "best_score": e["best_score"], "delta": delta,
            "improved": delta is not None and delta > EPS,
            "gap_to_best_known": None if e["best_score"] is None
            else round(e["best_known_score"] - e["best_score"], 6),
            "headroom": round(e["best_known_score"] - e["baseline_score"], 6),
            "submissions": len(subs), "valid_submissions": e["valid_submissions"],
            "failed_verification_submissions": failed_verification,
            "tool_calls": len(e["calls"]),
            "simulate_calls": e["tool_counts"].get("simulate", 0),
            "formal_calls": e["tool_counts"].get("prove_equivalence", 0),
            "estimate_calls": e["tool_counts"].get("estimate_ppa", 0),
            "finished_by_agent": e["finished_by_agent"],
            "cost_usd": e["cost_usd"], "wall_s": e["wall_s"],
            "output_tokens": e["usage"].get("output_tokens", 0),
        })
    return rows


def summarize(rows: list[dict]) -> dict:
    groups = defaultdict(list)
    for r in rows:
        groups[(r["model"], r["condition"])].append(r)
    table = []
    for model in MODELS:
        for cond in CONDITIONS:
            g = groups.get((model, cond), [])
            if not g:
                continue
            deltas = [r["delta"] if r["delta"] is not None else 0.0 for r in g]
            subs = sum(r["submissions"] for r in g)
            table.append({
                "model": model, "condition": cond, "episodes": len(g),
                "improved": sum(r["improved"] for r in g),
                "mean_delta": round(statistics.mean(deltas), 4),
                "max_delta": round(max(deltas), 4),
                "submissions": subs,
                "failed_verification_submissions": sum(r["failed_verification_submissions"] for r in g),
                "failed_share": round(sum(r["failed_verification_submissions"] for r in g) / max(subs, 1), 3),
                "mean_tool_calls": round(statistics.mean(r["tool_calls"] for r in g), 1),
                "mean_cost_usd": round(statistics.mean(r["cost_usd"] for r in g), 3),
                "total_cost_usd": round(sum(r["cost_usd"] for r in g), 2),
                "mean_wall_min": round(statistics.mean(r["wall_s"] for r in g) / 60, 1),
                "finished_early": sum(r["finished_by_agent"] for r in g),
            })
    per_task = []
    for task in TASKS:
        for model in MODELS:
            for cond in CONDITIONS:
                g = [r for r in rows if (r["task"], r["model"], r["condition"]) == (task, model, cond)]
                if g:
                    per_task.append({
                        "task": task, "model": model, "condition": cond, "episodes": len(g),
                        "deltas": [r["delta"] for r in g],
                        "improved": sum(r["improved"] for r in g),
                        "headroom_to_best_known": g[0]["headroom"],
                    })
    paired = []
    by_key = {(r["model"], r["task"], r["rep"], r["condition"]): r for r in rows}
    for (model, task, rep, cond), r in by_key.items():
        if cond != "full_tools":
            continue
        other = by_key.get((model, task, rep, "pnr_only"))
        if other:
            a = r["delta"] if r["delta"] is not None else 0.0
            b = other["delta"] if other["delta"] is not None else 0.0
            paired.append({"model": model, "task": task, "rep": rep, "full_minus_pnr_only": round(a - b, 6)})
    best_per_task = {}
    for task in TASKS:
        g = [r for r in rows if r["task"] == task and r["best_score"] is not None]
        if g:
            b = max(g, key=lambda r: r["best_score"])
            best_per_task[task] = {"episode": b["episode_id"], "best_score": b["best_score"],
                                   "delta": b["delta"], "gap_to_best_known": b["gap_to_best_known"],
                                   "headroom": b["headroom"]}
    signs = [p["full_minus_pnr_only"] for p in paired]
    return {
        "episodes": len(rows),
        "total_cost_usd": round(sum(r["cost_usd"] for r in rows), 2),
        "by_model_condition": table,
        "by_task": per_task,
        "paired_full_minus_pnr_only": {
            "pairs": len(signs),
            "positive": sum(s > EPS for s in signs), "negative": sum(s < -EPS for s in signs),
            "zero": sum(abs(s) <= EPS for s in signs),
            "mean": round(statistics.mean(signs), 5) if signs else None,
        },
        "best_per_task": best_per_task,
    }


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = load()
    with (OUT / "episodes.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    summary = summarize(rows)
    (OUT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps({k: v for k, v in summary.items() if k != "by_task"}, indent=1))


if __name__ == "__main__":
    main()
