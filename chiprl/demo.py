"""One-minute live demo of the environment, suitable for a screen share.

    python -m chiprl.demo            # uses cached physical results (fast)
    python -m chiprl.demo --fresh    # re-runs place-and-route (about 30 s more)

Steps: show a Claude-written priority encoder, simulate it, prove it
equivalent to the reference, prove that a buggy variant is not (with a
counterexample), estimate its PPA at the floorplan stage, then report the
verified post-route score against the baseline.
"""
from __future__ import annotations

import argparse
import contextlib
import io
import json
import time
from pathlib import Path

from chiprl.agentic_env import TASKS, run_estimate, run_simulation
from chiprl.benchmarks import ROOT
from chiprl.evaluate import evaluate
from chiprl.formal_v2 import check

EPISODE = ROOT / "results/agentic_eval_v1/priority32__full_tools__claude-sonnet-5__r1/episode.json"
BUGGY = ROOT / ".chiprl/demo/priority32_missing_hold.v"


def step(title: str) -> None:
    print(f"\n== {title}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fresh", action="store_true", help="re-run place-and-route uncached")
    args = parser.parse_args()
    task = TASKS["priority32"]
    bench = task.benchmark
    episode = json.loads(EPISODE.read_text())
    best = ROOT / max((s for s in episode["submissions"] if s["status"] == "OK"),
                      key=lambda s: s["score"])["rtl"]
    start = time.perf_counter()

    step("1. Candidate RTL (written by Claude Sonnet 5, folds the found flag into the index chain)")
    text = best.read_text()
    print("\n".join(text.splitlines()[9:14]) + "\n    ...")

    step("2. Simulation: 10,000 random transactions + protocol checks (Verilator)")
    sim = run_simulation(best, task)
    print(f"   {sim['status']} in {sim['runtime_s']} s")

    step("3. Formal: sequential equivalence with the reference (Yosys)")
    proof = check(best, bench)
    print(f"   {proof['status']} in {proof['runtime_s']} s")

    step("4. A buggy variant: y_o no longer holds when valid_i is low")
    BUGGY.parent.mkdir(parents=True, exist_ok=True)
    BUGGY.write_text(text.replace("if (valid_i)\n            y_o <= chosen_0;", "y_o <= chosen_0;"))
    bad = check(BUGGY, bench)
    print(f"   {bad['status']}; counterexample (cycle 1 is reset):")
    trace = {}
    for r in bad.get("counterexample", []):
        trace.setdefault(r["step"], {})[r["signal"]] = r["hex"]
    for cycle in sorted(trace)[1:]:
        t = trace[cycle]
        print(f"     cycle {cycle}: valid_i={t.get('in_valid_i')} a_i=0x{t.get('in_a_i')}  "
              f"reference y_o=0x{t.get('gold.y_o')}  candidate y_o=0x{t.get('gate.y_o')}")

    step("5. Cheap estimate: synthesis + floorplan static timing")
    est = run_estimate(best, task)
    print(f"   area {est['estimated_area_um2']} um^2, WNS {est['estimated_wns_ns']} ns "
          f"({est['runtime_s']} s)")

    step("6. Verified post-route score (OpenROAD, Nangate45)")
    with contextlib.redirect_stdout(io.StringIO()):
        r = evaluate(best.relative_to(ROOT), benchmark=bench, cache=not args.fresh, clean=args.fresh)
    base = task.baseline_result()
    print(f"   area {r['area']} um^2, WNS {r['wns']} ns, reward {r['proxy_reward_v0']}"
          f"  (baseline {base['proxy_reward_v0']}, delta {r['proxy_reward_v0'] - base['proxy_reward_v0']:+.3f})"
          f"{'  [cached]' if r['cache_hit'] else ''}")
    print(f"\nDone in {time.perf_counter() - start:.0f} s.")


if __name__ == "__main__":
    main()
