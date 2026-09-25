"""How much does the reward move under edits that cannot change function?

Motivation: re-evaluating 32 frozen designs with one added comment line
changed the result for 3 of them (up to 11 ps of slack, 0.11 reward), and an
agent's "+0.030" adder improvement turned out to be a null edit (moving
`a_i + b_i` into a named wire). The flow is deterministic for identical
bytes but not invariant to formatting, because Yosys derives internal names
from source locations and names affect downstream ordering.

For each design below, five variants that differ only in comments and blank
lines are evaluated uncached next to the original. The spread of each
design's reward is its formatting noise; a claimed improvement is robust only
if every variant of the candidate beats every variant of the reference.

Outputs: results/flow_noise_v1/{runs.json, summary.json}
Run:     python -m experiments.flow_noise_study_v1 --workers 8
"""
from __future__ import annotations

import argparse
import glob
import hashlib
import json
import statistics
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.parallel_eval import evaluate_many

OUT = ROOT / "results" / "flow_noise_v1"
VARIANTS = ROOT / "rtl" / "repro" / "flow_noise_v1"

# (label, benchmark, source RTL, comparison group)
DESIGNS = [
    ("addpipe32 baseline", "addpipe32", "rtl/addpipe32/baseline.v", "adder32"),
    ("addpipe32 Opus Ling adder", "addpipe32", "rtl/showcase/addpipe32_opus5_ling.v", "adder32"),
    ("cmp32 baseline", "cmp32", "rtl/cmp32/baseline.v", "cmp32"),
    ("cmp32 Sonnet nibble tree", "cmp32",
     "rtl/agentic_eval_v1/cmp32__full_tools__claude-sonnet-5__r3/BEST", "cmp32"),
    ("priority32 baseline", "priority32", "rtl/priority32/baseline.v", "priority32"),
    ("priority32 Sonnet folded chain", "priority32",
     "rtl/agentic_eval_v1/priority32__full_tools__claude-sonnet-5__r1/BEST", "priority32"),
    ("popcount32 baseline", "popcount32", "rtl/popcount32/baseline.v", "popcount32"),
    ("popcount32 Sonnet LUT tree", "popcount32",
     "rtl/agentic_eval_v1/popcount32__full_tools__claude-sonnet-5__r3/BEST", "popcount32"),
    ("popcount32_tree best seed (all CLA)", "popcount32_tree",
     "rtl/generated/popcount32_tree_arch_seed/mask_7fffffff.v", "oneflip"),
    ("popcount32_tree one-flip neighbor", "popcount32_tree",
     "rtl/generated/popcount32_tree_oneflip_v1/mask_7ffffffb.v", "oneflip"),
    ("addpipe16 plain adder", "addpipe16", "rtl/addpipe16/baseline.v", "adder16"),
    ("addpipe16 Claude ripple2+Sklansky14", "addpipe16",
     "rtl/agent/claude_sonnet5_history16/attempt_014_addpipe16_ripple2_sklansky14.v", "adder16"),
    ("lanesum all-ADD", "lanesum16x8_tree", "rtl/lanesum16x8_tree/baseline.v", "lanesum"),
    ("lanesum root CLA", "lanesum16x8_tree",
     "rtl/generated/lanesum16x8_tree_arch_seed_v1/mask_4000.v", "lanesum"),
]

EDITS = (
    lambda s: "// variant: one leading comment\n" + s,
    lambda s: "// variant\n// with three\n// leading comment lines\n" + s,
    lambda s: s.rstrip("\n") + "\n// trailing comment\n",
    lambda s: s.replace(");", ");\n\n\n", 1),
    lambda s: s.replace(");", ");\n// comment after the port list\n", 1),
)


def resolve(path: str) -> Path:
    """BEST means the best place_and_route submission of that agent episode."""
    if not path.endswith("/BEST"):
        return ROOT / path
    folder = path[: -len("/BEST")]
    episode = json.loads((ROOT / folder.replace("rtl/", "results/", 1) / "episode.json").read_text())
    best = max((s for s in episode["submissions"] if s["status"] == "OK"), key=lambda s: s["score"])
    return ROOT / best["rtl"]


def frozen_record(bench: str, src: Path) -> dict:
    digest = hashlib.sha256(src.read_bytes()).hexdigest()
    for p in glob.glob(str(ROOT / "results/evaluations" / bench / "*.json")):
        if p.endswith(".metrics.json"):
            continue
        r = json.loads(Path(p).read_text())
        if r["fingerprint"]["rtl_sha256"] == digest and r.get("place_route_ok"):
            return r
    raise RuntimeError(f"no frozen record for {src}")


def benchmark_name(bench: str) -> str:
    return bench


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workers", type=int, default=8)
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    jobs, meta = [], []
    for label, bench, path, group in DESIGNS:
        src = resolve(path)
        text = src.read_text()
        base = frozen_record(bench, src)
        slug = label.lower().replace(" ", "_").replace("+", "p").replace("(", "").replace(")", "")
        for k, edit in enumerate(EDITS, start=1):
            variant = VARIANTS / slug / f"v{k}.v"
            variant.parent.mkdir(parents=True, exist_ok=True)
            body = edit(text)
            assert body != text
            variant.write_text(body)
            jobs.append((variant.relative_to(ROOT).as_posix(), bench))
            meta.append((label, group, k))
        meta_base = {"label": label, "benchmark": bench, "group": group, "source": src.relative_to(ROOT).as_posix(),
                     "original": {"area": base["area"], "wns": base["wns"], "reward": base["proxy_reward_v0"]}}
        (OUT / f"{slug}.meta.json").write_text(json.dumps(meta_base, indent=1) + "\n")

    results = evaluate_many(jobs, workers=args.workers, cache=True)
    runs = {}
    for (label, group, k), (cand, bench), r in zip(meta, jobs, results):
        ok = r["functional"] and r["formal_ok"] and r["place_route_ok"]
        runs.setdefault(label, {"group": group, "benchmark": bench, "variants": []})["variants"].append({
            "variant": k, "candidate": cand, "valid": ok, "area": r["area"], "wns": r["wns"],
            "reward": r["proxy_reward_v0"], "evaluation_id": r["evaluation_id"]})
    for label, bench, path, group in DESIGNS:
        src = resolve(path)
        base = frozen_record(bench, src)
        runs[label]["original"] = {"area": base["area"], "wns": base["wns"], "reward": base["proxy_reward_v0"],
                                   "source": src.relative_to(ROOT).as_posix()}
    (OUT / "runs.json").write_text(json.dumps(runs, indent=1) + "\n")

    summary = {"designs": {}, "comparisons": {}}
    for label, d in runs.items():
        rewards = [d["original"]["reward"]] + [v["reward"] for v in d["variants"] if v["valid"]]
        summary["designs"][label] = {
            "n": len(rewards), "mean": round(statistics.mean(rewards), 6),
            "std": round(statistics.pstdev(rewards), 6),
            "min": min(rewards), "max": max(rewards), "spread": round(max(rewards) - min(rewards), 6),
            "all_valid": all(v["valid"] for v in d["variants"]),
        }
    groups = {}
    for label, d in runs.items():
        groups.setdefault(d["group"], []).append(label)
    for group, labels in groups.items():
        if len(labels) != 2:
            continue
        ref, cand = labels
        a, b = summary["designs"][ref], summary["designs"][cand]
        summary["comparisons"][group] = {
            "reference": ref, "candidate": cand,
            "mean_difference": round(b["mean"] - a["mean"], 6),
            "robust": b["min"] > a["max"] or b["max"] < a["min"],
            "direction": "better" if b["mean"] > a["mean"] else "worse",
        }
    spreads = [v["spread"] for v in summary["designs"].values()]
    summary["median_spread"] = round(statistics.median(spreads), 6)
    summary["max_spread"] = round(max(spreads), 6)
    summary["designs_with_any_change"] = sum(s > 0 for s in spreads)
    (OUT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
