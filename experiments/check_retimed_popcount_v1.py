"""Double-check the one agent design whose output is not a flip-flop.

Opus 5 retimed the popcount across the output register (13 registered bits
of partial sums, count finished combinationally). Its state encoding differs
from the reference, so the evaluator's inductive proof is backed up here by
checker v2 and by a bounded miter from reset (no mismatch allowed within
16 cycles for any input sequence).

Output: results/analysis/agentic_eval_v1/retimed_popcount_check.json
Run:    python -m experiments.check_retimed_popcount_v1
"""
from __future__ import annotations

import json

from chiprl.benchmarks import BENCHMARKS, ROOT
from chiprl.formal_v2 import WORK, _parse_trace, cex_script, check, run_yosys_batch

CANDIDATE = "rtl/agentic_eval_v1/popcount32__full_tools__claude-opus-5__r2/call27_place_and_route_8197ded8a7ac.v"
OUT = ROOT / "results/analysis/agentic_eval_v1/retimed_popcount_check.json"


def main():
    bench = BENCHMARKS["popcount32"]
    candidate = ROOT / CANDIDATE
    result = {"candidate": CANDIDATE, "checker_v2": check(candidate, bench, counterexample=False)}
    WORK.mkdir(parents=True, exist_ok=True)
    for depth in (8, 16):
        script = WORK / f"retimed_popcount_bmc_{depth}.ys"
        script.write_text(cex_script(bench.reference, bench.reference_top, candidate, bench.top_module, depth))
        run = run_yosys_batch([script], timeout_s=600)[0]
        log = script.with_suffix(".log").read_text()
        result[f"bounded_{depth}_cycles"] = {
            "mismatch_trace": _parse_trace(log), "passed": "SUCCESS" in log and not _parse_trace(log),
            "timed_out": run["timed_out"]}
    OUT.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
