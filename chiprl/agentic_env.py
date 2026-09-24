"""Tool-using RTL optimization environment for LLM agents.

An episode gives the agent one hardware task: a reference Verilog module,
its cycle-level protocol, and a physical-design objective. The agent works
through tools that mirror a real engineer's loop, each with a different cost:

    simulate           Verilator build + 10,000-transaction protocol test   ~4 s
    prove_equivalence  Yosys sequential equivalence against the reference   ~1 s
    estimate_ppa       Yosys/ABC synthesis + floorplan static timing        ~6 s
    place_and_route    full verified RTL-to-GDS evaluation (budgeted)      ~25 s
    finish             end the episode

Only `place_and_route` produces reward, and it re-runs simulation and formal
equivalence first, so an unverified design cannot score. Every submission
consumes budget, including failures. Episode reward is the best verified
`proxy_reward_v0 = 10*WNS - 0.001*area` among submissions minus the frozen
baseline's reward.

Physical results come from the frozen evaluator (chiprl.evaluate.evaluate),
so they are bit-identical to every other experiment in this repository.
"""
from __future__ import annotations

import fcntl
import glob
import hashlib
import json
import os
import re
import subprocess
import time
from contextlib import contextmanager
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from chiprl.benchmarks import ROOT, Benchmark, get_benchmark
from chiprl.evaluate import DOCKER_SHELL, evaluate
from chiprl.formal_tree_v1 import equiv_script, run_yosys_batch

WORK = ROOT / ".chiprl" / "agentic"
LOCKS = ROOT / ".chiprl" / "locks"
FORMAL_TIMEOUT_S = 180
ESTIMATE_TIMEOUT_S = 300


# ---------------------------------------------------------------------------
# Tasks
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class Task:
    name: str
    summary: str

    @property
    def benchmark(self) -> Benchmark:
        return get_benchmark(self.name)

    @property
    def baseline_rtl(self) -> Path:
        return ROOT / "rtl" / self.name / "baseline.v"

    def records(self) -> list[dict]:
        out = []
        for path in glob.glob(str(ROOT / "results/evaluations" / self.name / "*.json")):
            if not path.endswith(".metrics.json"):
                out.append(json.loads(Path(path).read_text()))
        return out

    def baseline_result(self) -> dict:
        digest = hashlib.sha256(self.baseline_rtl.read_bytes()).hexdigest()
        for row in self.records():
            if row["fingerprint"]["rtl_sha256"] == digest and row.get("place_route_ok"):
                return row
        raise RuntimeError(f"no frozen physical result for {self.baseline_rtl}")

    def best_known(self) -> dict:
        """Best design found by any earlier search (hidden from the agent)."""
        valid = [r for r in self.records()
                 if r.get("functional") and r.get("formal_ok") and r.get("place_route_ok")
                 and "agentic_eval" not in r.get("candidate", "")]
        return max(valid, key=lambda r: r["proxy_reward_v0"])


TASKS = {
    "addpipe32": Task("addpipe32", "32-bit registered adder: y = a + b (mod 2^32)"),
    "cmp32": Task("cmp32", "32-bit registered unsigned comparator: y = (a < b)"),
    "priority32": Task("priority32",
                       "32-bit registered priority encoder: index of the highest set bit of a, plus a found flag"),
    "popcount32": Task("popcount32", "32-bit registered population count of a"),
}


# ---------------------------------------------------------------------------
# Candidate hygiene
# ---------------------------------------------------------------------------

FORBIDDEN = (
    (r"\binitial\b", "initial blocks are not allowed"),
    (r"\$(?!signed\b|unsigned\b|clog2\b)[a-z_]+", "system tasks/functions are not allowed"),
    (r"`\s*(include|define|ifdef|ifndef|timescale)\b", "compiler directives are not allowed"),
    (r"\b(force|release|bind|import|program|class)\b", "construct not allowed"),
)


def check_source(rtl: str, task: Task) -> str | None:
    """Return a rejection reason, or None if the source is acceptable."""
    if len(rtl) > 200_000:
        return "source too large"
    code = re.sub(r"//[^\n]*|/\*.*?\*/", "", rtl, flags=re.S)
    for pattern, reason in FORBIDDEN:
        if re.search(pattern, code):
            return reason
    modules = re.findall(r"\bmodule\s+([A-Za-z_][A-Za-z0-9_$]*)", code)
    top = task.benchmark.top_module
    # The frozen equivalence checker compares flat modules (no `flatten`),
    # so a correct design with submodules would fail formal. Require one module.
    if modules != [top]:
        return f"source must contain exactly one module, named {top} (no helper modules)"
    return None


# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

@contextmanager
def design_lock(bench: str, digest: str):
    """Serialize work on the same design across concurrent episodes."""
    LOCKS.mkdir(parents=True, exist_ok=True)
    with open(LOCKS / f"{bench}_{digest[:16]}.lock", "w") as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


def _abs(path: Path) -> Path:
    path = Path(path)
    return path if path.is_absolute() else ROOT / path


def _tail(text: str, lines: int = 25) -> str:
    return "\n".join(text.splitlines()[-lines:])


def run_simulation(path: Path, task: Task) -> dict:
    """Exactly the evaluator's Verilator command and pass criterion."""
    path = _abs(path)
    bench = task.benchmark
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    build = WORK / "verilator" / f"{bench.name}_{digest[:16]}"
    start = time.perf_counter()
    build.mkdir(parents=True, exist_ok=True)
    compile_ = subprocess.run(
        ["verilator", "--binary", "--timing", "-Wall", "-Wno-fatal", "--Mdir", str(build),
         str(path), str(bench.testbench), "--top-module", "tb"],
        cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    if compile_.returncode != 0:
        errors = [l for l in compile_.stdout.splitlines() if "%Error" in l]
        return {"status": "COMPILE_ERROR", "errors": errors[:12] or [_tail(compile_.stdout)],
                "runtime_s": round(time.perf_counter() - start, 2)}
    sim = subprocess.run([str(build / "Vtb")], cwd=ROOT, text=True,
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=300)
    passed = sim.returncode == 0 and bench.pass_marker in sim.stdout
    warnings = [l for l in compile_.stdout.splitlines() if "%Warning" in l][:8]
    return {"status": "PASS" if passed else "TEST_FAILED",
            "output": "" if passed else _tail(sim.stdout, 12),
            "lint_warnings": warnings,
            "runtime_s": round(time.perf_counter() - start, 2)}


def run_formal(path: Path, task: Task, timeout_s: int = FORMAL_TIMEOUT_S) -> dict:
    """Same Yosys equivalence commands as chiprl.formal, with a timeout."""
    path = _abs(path)
    bench = task.benchmark
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    work = WORK / "formal"
    work.mkdir(parents=True, exist_ok=True)
    script = work / f"{bench.name}_{digest[:16]}.ys"
    script.write_text(equiv_script(bench.reference, bench.reference_top, path, bench.top_module))
    start = time.perf_counter()
    outcome = run_yosys_batch([script], timeout_s=timeout_s)[0]
    log = script.with_suffix(".log")
    text = log.read_text() if log.is_file() else ""
    unproven = [l.strip() for l in text.splitlines() if "Unproven $equiv" in l][:12]
    status = "PROVEN" if outcome["proven"] else ("TIMEOUT" if outcome["timed_out"] else "NOT_PROVEN")
    result = {"status": status, "runtime_s": round(time.perf_counter() - start, 2)}
    if status != "PROVEN":
        result["unproven_signals"] = unproven
        errors = [l for l in text.splitlines() if l.startswith("ERROR")]
        if errors:
            result["errors"] = errors[:5]
    return result


def run_estimate(path: Path, task: Task) -> dict:
    """Synthesis + floorplan only: pre-placement area and static timing."""
    path = _abs(path)
    bench = task.benchmark
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    variant = f"est_{digest[:16]}"
    metrics = ROOT / "logs" / bench.platform / bench.top_module / variant / "2_1_floorplan.json"
    start = time.perf_counter()
    if not metrics.is_file():
        env = os.environ.copy()
        env.setdefault("OR_IMAGE", "openroad/orfs:local")
        proc = subprocess.run(
            [str(DOCKER_SHELL), "make", f"DESIGN_CONFIG={bench.orfs_config_container}",
             f"VERILOG_FILES=/work/{path.relative_to(ROOT).as_posix()}",
             f"FLOW_VARIANT={variant}", "floorplan"],
            cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            timeout=ESTIMATE_TIMEOUT_S,
        )
        if not metrics.is_file():
            return {"status": "FLOW_ERROR", "output": _tail(proc.stdout, 15),
                    "runtime_s": round(time.perf_counter() - start, 2)}
    m = json.loads(metrics.read_text())
    area = float(m["floorplan__design__instance__area__stdcell"])
    wns = float(m["floorplan__timing__setup__ws"])
    return {"status": "OK", "estimated_area_um2": area, "estimated_wns_ns": wns,
            "estimated_reward": round(10 * wns - 0.001 * area, 6),
            "note": "Pre-placement estimate (no placement, buffering or routing).",
            "runtime_s": round(time.perf_counter() - start, 2)}


# ---------------------------------------------------------------------------
# Episode
# ---------------------------------------------------------------------------

TOOL_SPECS = {
    "simulate": {
        "description": (
            "Compile the design with Verilator and run the benchmark testbench: reset checks, "
            "edge cases, 10,000 random valid transactions each followed by an invalid cycle "
            "with changed inputs (the output must hold), and back-to-back transactions. "
            "Returns PASS, TEST_FAILED with the first mismatch, or COMPILE_ERROR. About 4 s."),
    },
    "prove_equivalence": {
        "description": (
            "Prove sequential equivalence with the reference using Yosys "
            "(equiv_make, equiv_simple -seq 4, equiv_induct -seq 4). Returns PROVEN, or "
            "NOT_PROVEN with the unproven signals, or TIMEOUT. About 1 s."),
    },
    "estimate_ppa": {
        "description": (
            "Cheap physical estimate: Yosys/ABC synthesis to Nangate45 and floorplan-stage "
            "static timing, before placement and routing. Returns estimated area (um^2), "
            "worst setup slack (ns) and estimated reward. Does not check correctness. About 6 s."),
    },
    "place_and_route": {
        "description": (
            "Full scored evaluation: simulation, formal equivalence, then OpenROAD "
            "floorplan, placement, clock tree synthesis, routing and signoff metrics. "
            "Returns final area, WNS and reward. Uses one unit of the limited budget "
            "even if the design fails a check. About 25 s."),
    },
}


def tool_definitions(condition: str) -> list[dict]:
    names = ["place_and_route"] if condition == "pnr_only" else list(TOOL_SPECS)
    tools = []
    for name in names:
        tools.append({
            "name": name,
            "description": TOOL_SPECS[name]["description"],
            "input_schema": {
                "type": "object",
                "properties": {"rtl": {"type": "string",
                                       "description": "Complete Verilog source of the design."}},
                "required": ["rtl"],
                "additionalProperties": False,
            },
        })
    tools.append({
        "name": "finish",
        "description": "End the episode. The best verified place_and_route result is your score.",
        "input_schema": {
            "type": "object",
            "properties": {"summary": {"type": "string", "description": "One-paragraph summary."}},
            "required": ["summary"],
            "additionalProperties": False,
        },
    })
    return tools


@dataclass
class Episode:
    task: Task
    episode_id: str
    condition: str = "full_tools"          # or "pnr_only"
    pnr_budget: int = 4
    max_tool_calls: int = 30
    calls: list = field(default_factory=list)
    submissions: list = field(default_factory=list)
    finished: bool = False
    finish_summary: str = ""

    def __post_init__(self):
        self.rtl_dir = ROOT / "rtl" / "agentic_eval_v1" / self.episode_id
        self.rtl_dir.mkdir(parents=True, exist_ok=True)
        self.baseline = self.task.baseline_result()

    # -- prompt -------------------------------------------------------------
    def task_prompt(self) -> str:
        b = self.baseline
        tools = ("simulate, prove_equivalence, estimate_ppa, place_and_route, finish"
                 if self.condition == "full_tools" else "place_and_route, finish")
        return f"""## Task
Improve the post-route quality of `{self.task.benchmark.top_module}` ({self.task.summary}) without changing its behavior.

## Specification (current RTL, also the equivalence reference)
```verilog
{self.task.baseline_rtl.read_text().strip()}
```
Your design must be cycle-for-cycle equivalent to this module from reset: same ports, synchronous active-low reset, `valid_o` follows `valid_i` one cycle later, and `y_o` updates only on valid cycles and holds otherwise.

## Flow and objective
Yosys/ABC synthesis to the Nangate45 library, then OpenROAD placement, clock tree synthesis and routing with a 10 ns clock and a fixed floorplan. Score = 10 * WNS_ns - 0.001 * area_um2, where WNS is the worst setup slack after routing and area is total standard-cell area. Higher is better.

This RTL measured: area {b['area']} um^2, WNS {b['wns']} ns, score {b['proxy_reward_v0']}.{self._estimate_note()}

## Rules
- One module of synthesizable Verilog-2005 (no helper modules or instances; the equivalence checker compares flat modules). The module name and ports must not change.
- No initial blocks, system tasks, compiler directives or technology cells.
- place_and_route budget: {self.pnr_budget} submissions. Every submission counts, including failed ones.
- At most {self.max_tool_calls} tool calls in total.

Tools available: {tools}. Your score is the best verified place_and_route score. Call finish when you are done."""

    def _estimate_note(self) -> str:
        if self.condition != "full_tools":
            return ""
        e = run_estimate(self.task.baseline_rtl, self.task)
        return (f"\nestimate_ppa on this RTL returns area {e['estimated_area_um2']} um^2, "
                f"WNS {e['estimated_wns_ns']} ns, estimated score {e['estimated_reward']} "
                "(estimates omit tap cells, buffering and wiring, so compare estimates with estimates).")

    # -- tools ---------------------------------------------------------------
    def _write(self, rtl: str, tool: str) -> Path:
        digest = hashlib.sha256(rtl.encode()).hexdigest()[:12]
        path = self.rtl_dir / f"call{len(self.calls):02d}_{tool}_{digest}.v"
        path.write_text(rtl)
        return path

    def execute(self, name: str, args: dict) -> tuple[dict, bool]:
        """Run one tool call. Returns (result, is_error)."""
        start = time.perf_counter()
        record = {"index": len(self.calls), "tool": name}
        if len(self.calls) >= self.max_tool_calls:
            result, error = {"status": "TOOL_CALL_LIMIT", "message": "No tool calls left."}, True
            self.finished = True
        elif name == "finish":
            self.finished = True
            self.finish_summary = str(args.get("summary", ""))[:4000]
            result, error = {"status": "FINISHED", **self.score()}, False
        elif name not in {t["name"] for t in tool_definitions(self.condition)}:
            result, error = {"status": "UNKNOWN_TOOL"}, True
        else:
            rtl = args.get("rtl")
            if not isinstance(rtl, str) or not rtl.strip():
                result, error = {"status": "BAD_INPUT", "message": "rtl must be a non-empty string"}, True
            else:
                path = self._write(rtl, name)
                record["rtl"] = path.relative_to(ROOT).as_posix()
                record["rtl_sha256"] = hashlib.sha256(rtl.encode()).hexdigest()
                problem = check_source(rtl, self.task)
                if name == "place_and_route":
                    result, error = self._place_and_route(path, problem), False
                elif problem:
                    result, error = {"status": "REJECTED", "reason": problem}, True
                else:
                    with design_lock(self.task.name, record["rtl_sha256"]):
                        if name == "simulate":
                            result = run_simulation(path, self.task)
                        elif name == "prove_equivalence":
                            result = run_formal(path, self.task)
                        else:
                            result = run_estimate(path, self.task)
                    error = False
        record.update(result=result, wall_s=round(time.perf_counter() - start, 2))
        self.calls.append(record)
        return result, error

    def _place_and_route(self, path: Path, problem: str | None) -> dict:
        if len(self.submissions) >= self.pnr_budget:
            return {"status": "BUDGET_EXHAUSTED", "message": "No place_and_route submissions left."}
        index = len(self.submissions) + 1
        base = {"submission": index, "remaining": self.pnr_budget - index}
        if problem:
            outcome = {**base, "status": "REJECTED", "reason": problem}
        else:
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            with design_lock(self.task.name, digest):
                sim = run_simulation(path, self.task)
                if sim["status"] != "PASS":
                    outcome = {**base, "status": "SIMULATION_FAILED", "simulation": sim}
                else:
                    formal = run_formal(path, self.task)
                    if formal["status"] != "PROVEN":
                        outcome = {**base, "status": "FORMAL_FAILED", "formal": formal}
                    else:
                        r = evaluate(path.relative_to(ROOT), benchmark=self.task.benchmark, cache=True)
                        if r["functional"] and r["formal_ok"] and r["place_route_ok"]:
                            outcome = {**base, "status": "OK", "area_um2": r["area"], "wns_ns": r["wns"],
                                       "cells": r["cells"], "power_w": r["power_w"],
                                       "score": r["proxy_reward_v0"],
                                       "score_minus_baseline": round(
                                           r["proxy_reward_v0"] - self.baseline["proxy_reward_v0"], 6),
                                       "evaluation_id": r["evaluation_id"], "cache_hit": r["cache_hit"]}
                        else:
                            outcome = {**base, "status": "FLOW_FAILED",
                                       "evaluation_id": r["evaluation_id"]}
        self.submissions.append({"rtl": path.relative_to(ROOT).as_posix(), **outcome})
        if len(self.submissions) >= self.pnr_budget:
            outcome["note"] = "Budget exhausted; the episode will end."
            self.finished = True
        return outcome

    def score(self) -> dict:
        ok = [s for s in self.submissions if s["status"] == "OK"]
        best = max(ok, key=lambda s: s["score"]) if ok else None
        return {
            "best_score": best["score"] if best else None,
            "best_minus_baseline": best["score_minus_baseline"] if best else None,
            "valid_submissions": len(ok),
            "submissions": len(self.submissions),
        }
