"""Equivalence checker v2: fixes found by the agentic eval, plus counterexamples.

chiprl/formal.py (v1) stays frozen because completed studies are hashed
against it. The agentic eval found two completeness gaps in v1, both false
rejections of correct designs:

* Yosys 0.68's `proc` turns `case` lookup tables into ROMs (`proc_rom`), and
  `equiv_make` cannot analyze memories. v2 runs `proc -norom`.
* v1 never flattens, so any submodule instance is a black box. v2 flattens.

v2 also classifies failures and, when a proof fails, runs a bounded model
check on a miter to return a concrete counterexample (the input sequence that
makes the outputs differ after reset). That is the feedback an agent needs.

Same equivalence core as v1: equiv_make, equiv_simple -seq 4,
equiv_induct -seq 4, equiv_status -assert.
"""
from __future__ import annotations

import hashlib
import re
import time
from pathlib import Path
from typing import Any

from chiprl.benchmarks import ROOT, Benchmark
from chiprl.formal_tree_v1 import _container, run_yosys_batch

METHOD_ID = "equiv_v2"
WORK = ROOT / ".chiprl" / "formal_v2"


def _prepare(gold: Path, gold_top: str, gate: Path, gate_top: str) -> list[str]:
    return [
        f"read_verilog -formal {_container(gold)}",
        f"hierarchy -top {gold_top}",
        "proc -norom", "flatten", "opt_clean",
        f"rename {gold_top} chiprl_gold",
        "design -stash gold_design",
        f"read_verilog -formal {_container(gate)}",
        f"hierarchy -top {gate_top}",
        "proc -norom", "flatten", "opt_clean",
        f"rename {gate_top} chiprl_gate",
        "design -copy-from gold_design chiprl_gold",
    ]


def equiv_script(gold, gold_top, gate, gate_top) -> str:
    return "\n".join(_prepare(gold, gold_top, gate, gate_top) + [
        "opt",
        "equiv_make chiprl_gold chiprl_gate equiv",
        "hierarchy -top equiv",
        "equiv_simple -seq 4",
        "equiv_induct -seq 4",
        "equiv_status -assert",
    ]) + "\n"


def cex_script(gold, gold_top, gate, gate_top, depth: int) -> str:
    """Bounded check from reset: step 1 holds rst_n low, later steps are free."""
    return "\n".join(_prepare(gold, gold_top, gate, gate_top) + [
        "miter -equiv -flatten -make_assert chiprl_gold chiprl_gate miter",
        "hierarchy -top miter",
        f"sat -verify -prove-asserts -prove-skip 1 -seq {depth} -set-at 1 in_rst_n 0 "
        "-show-inputs -show-regs -timeout 60 miter",
    ]) + "\n"


def _parse_trace(log: str) -> list[dict[str, str]]:
    """Pull the counterexample table printed by `sat -show-inputs -show-regs`."""
    rows = []
    for line in log.splitlines():
        m = re.match(r"\s*(\d+)\s+\\(\S+)\s+(-?\d+|-)\s+([0-9a-fx-]+)\s+([01x-]+)\s*$", line)
        if m and (m.group(2).startswith(("in_", "gold.", "gate.")) or m.group(2) == "trigger"):
            rows.append({"step": int(m.group(1)), "signal": m.group(2), "hex": m.group(4)})
    return rows


def check(candidate: str | Path, benchmark: Benchmark, *, timeout_s: int = 180,
          counterexample: bool = True, depth: int = 4) -> dict[str, Any]:
    candidate = Path(candidate)
    candidate = candidate if candidate.is_absolute() else ROOT / candidate
    digest = hashlib.sha256(candidate.read_bytes() + benchmark.reference.read_bytes()
                            + METHOD_ID.encode()).hexdigest()[:16]
    WORK.mkdir(parents=True, exist_ok=True)
    start = time.perf_counter()
    script = WORK / f"{benchmark.name}_{digest}.ys"
    script.write_text(equiv_script(benchmark.reference, benchmark.reference_top,
                                   candidate, benchmark.top_module))
    out = run_yosys_batch([script], timeout_s=timeout_s)[0]
    log = script.with_suffix(".log").read_text() if script.with_suffix(".log").is_file() else ""
    result: dict[str, Any] = {"formal_method": METHOD_ID}
    if out["proven"]:
        result["status"] = "PROVEN"
    elif out["timed_out"]:
        result["status"] = "TIMEOUT"
    else:
        errors = [l[l.index("ERROR"):] for l in log.splitlines()
                  if "ERROR" in l and "unproven $equiv" not in l]
        result["status"] = "UNSUPPORTED" if errors else "NOT_PROVEN"
        if errors:
            result["errors"] = errors[:3]
        result["unproven_signals"] = [l.strip() for l in log.splitlines() if "Unproven $equiv" in l][:8]
        if counterexample:
            cex = WORK / f"{benchmark.name}_{digest}_cex.ys"
            cex.write_text(cex_script(benchmark.reference, benchmark.reference_top,
                                      candidate, benchmark.top_module, depth))
            cex_out = run_yosys_batch([cex], timeout_s=timeout_s)[0]
            cex_log = cex.with_suffix(".log").read_text() if cex.with_suffix(".log").is_file() else ""
            trace = _parse_trace(cex_log)
            if trace:
                result["status"] = "NOT_EQUIVALENT"
                result["counterexample"] = trace
            elif "SUCCESS" in cex_log:
                result["bounded_check"] = f"no mismatch within {depth} cycles after reset"
    result["runtime_s"] = round(time.perf_counter() - start, 2)
    return result
