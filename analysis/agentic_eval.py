"""Summarize the agentic RTL eval (results/agentic_eval_v1) into tables.

Primary outcome (preregistered): best verified score minus baseline per episode.

Post-hoc refinement: a submission whose synthesized netlist is identical to
the baseline's (same cell count, cell area and floorplan-stage slack) is a
null edit, yet placement and routing can still move its score by a few ps
of slack (results/flow_noise_v1). The band of scores that null edits reach
is the eval's noise floor, and the "material" outcome treats any best score
inside that band as a tie with the baseline.

Interface check: every task is a registered block, but the checkers only
prove cycle equivalence. A submission whose y_o bits are not all driven
directly by flip-flops in the synthesized netlist has moved logic past the
output register; it is flagged, and the best registered-output score is
reported next to the preregistered one.
"""
from __future__ import annotations

import csv
import glob
import json
import re
import statistics
from collections import defaultdict
from functools import cache
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNS = ROOT / "results" / "agentic_eval_v1"
OUT = ROOT / "results" / "analysis" / "agentic_eval_v1"
LOGS = ROOT / "logs" / "nangate45"
MODELS = ["claude-haiku-4-5", "claude-sonnet-5", "claude-opus-5"]
TASKS = ["addpipe32", "cmp32", "priority32", "popcount32"]
CONDITIONS = ["full_tools", "pnr_only"]
EPS = 1e-9


# ORFS logs are not committed, so signatures read from them are saved here.
SIGNATURES = OUT / "netlist_signatures.json"
_signatures = json.loads(SIGNATURES.read_text()) if SIGNATURES.is_file() else {}


OUTPUT_WIDTH = {"addpipe32": 32, "cmp32": 1, "priority32": 6, "popcount32": 6}
RESULTS_ORFS = ROOT / "results" / "nangate45"
_registered = json.loads((OUT / "outputs_registered.json").read_text()) \
    if (OUT / "outputs_registered.json").is_file() else {}


def outputs_registered(task: str, evaluation_id: str) -> bool:
    """True if every y_o bit is the Q pin of a flip-flop in the synthesized netlist."""
    key = f"{task}/{evaluation_id}"
    if key not in _registered:
        netlist = (RESULTS_ORFS / task / f"eval_{evaluation_id}" / "1_2_yosys.v").read_text()
        driven = set(re.findall(r"\.Q\(y_o(?:\[(\d+)\])?\)", netlist))
        _registered[key] = len(driven) == OUTPUT_WIDTH[task]
    return _registered[key]


def netlist_signature(task: str, evaluation_id: str) -> tuple:
    """Synthesis cell count and area plus floorplan-stage slack of one ORFS run."""
    key = f"{task}/{evaluation_id}"
    if key not in _signatures:
        run = LOGS / task / f"eval_{evaluation_id}"
        synth = json.loads((run / "1_synth.json").read_text())
        floorplan = json.loads((run / "2_1_floorplan.json").read_text())
        _signatures[key] = [synth["synth__design__instance__count__stdcell"],
                            synth["synth__design__instance__area__stdcell"],
                            floorplan["floorplan__timing__setup__ws"]]
    return tuple(_signatures[key])


@cache
def baseline_signature(task: str) -> tuple:
    from chiprl.agentic_env import TASKS as ENV_TASKS
    return netlist_signature(task, ENV_TASKS[task].baseline_result()["evaluation_id"])


def is_null_edit(task: str, submission: dict) -> bool:
    return netlist_signature(task, submission["evaluation_id"]) == baseline_signature(task)


def episodes() -> list[dict]:
    return [json.loads(Path(p).read_text()) for p in sorted(glob.glob(str(RUNS / "*" / "episode.json")))]


def noise_band(eps: list[dict]) -> tuple[float, float]:
    """Lowest and highest score change reached by any null edit."""
    deltas = [s["score_minus_baseline"] for e in eps for s in e["submissions"]
              if s["status"] == "OK" and is_null_edit(e["task"], s)]
    return min(deltas + [0.0]), max(deltas + [0.0])


def load(band: tuple[float, float]) -> list[dict]:
    lo, hi = band
    rows = []
    for e in episodes():
        subs = e["submissions"]
        ok = [s for s in subs if s["status"] == "OK"]
        failed_verification = sum(s["status"] in ("SIMULATION_FAILED", "FORMAL_FAILED", "REJECTED")
                                  for s in subs)
        null = [s for s in ok if is_null_edit(e["task"], s)]
        delta = e["best_minus_baseline"]
        material = None if delta is None else (0.0 if lo - EPS <= delta <= hi + EPS else delta)
        best = max(ok, key=lambda s: s["score"]) if ok else None
        registered = [s for s in ok if outputs_registered(e["task"], s["evaluation_id"])]
        rows.append({
            "episode_id": e["episode_id"], "model": e["model"], "task": e["task"],
            "condition": e["condition"], "rep": e["rep"],
            "best_score": e["best_score"], "delta": delta,
            "improved": delta is not None and delta > EPS,
            "best_is_null_edit": best is not None and best in null,
            "material_delta": material,
            "improved_material": material is not None and material > EPS,
            "null_edit_submissions": len(null),
            "best_output_registered": best is None or outputs_registered(e["task"], best["evaluation_id"]),
            "best_registered_delta": max((s["score_minus_baseline"] for s in registered), default=None),
            "unregistered_output_submissions": len(ok) - len(registered),
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


def _zero(x):
    return 0.0 if x is None else x


def paired(rows: list[dict], key: str, models=MODELS) -> dict:
    by_key = {(r["model"], r["task"], r["rep"], r["condition"]): r for r in rows}
    diffs = []
    for (model, task, rep, cond), r in sorted(by_key.items()):
        other = by_key.get((model, task, rep, "pnr_only"))
        if cond == "full_tools" and other and model in models:
            diffs.append(_zero(r[key]) - _zero(other[key]))
    return {
        "pairs": len(diffs),
        "positive": sum(d > EPS for d in diffs), "negative": sum(d < -EPS for d in diffs),
        "zero": sum(abs(d) <= EPS for d in diffs),
        "mean": round(statistics.mean(diffs), 5) if diffs else None,
    }


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
            deltas = [_zero(r["delta"]) for r in g]
            material = [_zero(r["material_delta"]) for r in g]
            subs = sum(r["submissions"] for r in g)
            table.append({
                "model": model, "condition": cond, "episodes": len(g),
                "improved": sum(r["improved"] for r in g),
                "improved_material": sum(r["improved_material"] for r in g),
                "mean_delta": round(statistics.mean(deltas), 4),
                "mean_material_delta": round(statistics.mean(material), 4),
                "max_delta": round(max(deltas), 4),
                "submissions": subs,
                "null_edit_submissions": sum(r["null_edit_submissions"] for r in g),
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
                        "material_deltas": [r["material_delta"] for r in g],
                        "improved": sum(r["improved"] for r in g),
                        "improved_material": sum(r["improved_material"] for r in g),
                        "headroom_to_best_known": g[0]["headroom"],
                    })
    best_per_task = {}
    for task in TASKS:
        g = [r for r in rows if r["task"] == task and r["best_score"] is not None]
        if g:
            b = max(g, key=lambda r: r["best_score"])
            best_per_task[task] = {"episode": b["episode_id"], "best_score": b["best_score"],
                                   "delta": b["delta"], "gap_to_best_known": b["gap_to_best_known"],
                                   "headroom": b["headroom"], "null_edit": b["best_is_null_edit"]}
    by_cond = {}
    for cond in CONDITIONS:
        g = [r for r in rows if r["condition"] == cond]
        by_cond[cond] = {
            "episodes": len(g),
            "improved": sum(r["improved"] for r in g),
            "improved_material": sum(r["improved_material"] for r in g),
            "mean_delta": round(statistics.mean(_zero(r["delta"]) for r in g), 4) if g else None,
            "mean_material_delta": round(statistics.mean(_zero(r["material_delta"]) for r in g), 4)
            if g else None,
        }
    by_model = {}
    for model in MODELS:
        g = [r for r in rows if r["model"] == model]
        if g:
            by_model[model] = {
                "episodes": len(g), "improved": sum(r["improved"] for r in g),
                "improved_material": sum(r["improved_material"] for r in g),
                "mean_material_delta": round(statistics.mean(_zero(r["material_delta"]) for r in g), 4),
                "total_cost_usd": round(sum(r["cost_usd"] for r in g), 2),
                "paired_material": paired(rows, "material_delta", [model]),
            }
    return {
        "episodes": len(rows),
        "total_cost_usd": round(sum(r["cost_usd"] for r in rows), 2),
        "by_condition": by_cond,
        "by_model": by_model,
        "by_model_condition": table,
        "by_task": per_task,
        "paired_full_minus_pnr_only": paired(rows, "delta"),
        "paired_full_minus_pnr_only_material": paired(rows, "material_delta"),
        "best_per_task": best_per_task,
        "episodes_whose_best_is_a_null_edit": sum(r["best_is_null_edit"] and r["improved"] for r in rows),
        "unregistered_output_episodes": [
            {"episode": r["episode_id"], "delta": r["delta"], "best_registered_delta": r["best_registered_delta"],
             "unregistered_submissions": r["unregistered_output_submissions"]}
            for r in rows if r["unregistered_output_submissions"]],
        "best_registered_per_task": {
            task: max(((r["best_registered_delta"], r["episode_id"]) for r in rows
                       if r["task"] == task and r["best_registered_delta"] is not None), default=None)
            for task in TASKS},
        "null_edit_submissions": sum(r["null_edit_submissions"] for r in rows),
    }


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    band = noise_band(episodes())
    rows = load(band)
    with (OUT / "episodes.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    summary = {"null_edit_noise_band": [round(band[0], 6), round(band[1], 6)]} | summarize(rows)
    SIGNATURES.write_text("{\n" + ",\n".join(f"{json.dumps(k)}: {json.dumps(v)}"
                                             for k, v in sorted(_signatures.items())) + "\n}\n")
    (OUT / "outputs_registered.json").write_text(json.dumps(dict(sorted(_registered.items())), indent=0) + "\n")
    (OUT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps({k: v for k, v in summary.items() if k not in ("by_task", "by_model_condition")}, indent=1))


if __name__ == "__main__":
    main()
