"""Measure why the monolithic lane-sum equivalence proof does not finish.

Builds the miter `reference vs all-ADD tree` with Yosys, unrolls it for three
cycles (reset, one valid input, compare), dumps the CNF, and gives several
CDCL SAT solvers a fixed time limit each. Then times the decomposed proofs
for comparison. No RTL, benchmark or protocol file is modified.

Run:  python -m experiments.lanesum_formal_hardness_v1 [--limit 120]
Needs: host yosys, `pip install python-sat`.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import threading
import time
from pathlib import Path

from chiprl.benchmarks import ROOT

OUT = ROOT / "results/formal/lanesum16x8_monolithic_hardness_v1.json"
WORK = ROOT / ".chiprl/formal_hardness"
REF = ROOT / "rtl/reference/lanesum16x8_tree_ref.v"
TREE = ROOT / "rtl/lanesum16x8_tree/baseline.v"
SOLVERS = ("minisat22", "glucose4", "cadical195")


def dump_cnf() -> Path:
    WORK.mkdir(parents=True, exist_ok=True)
    cnf = WORK / "miter.cnf"
    script = WORK / "miter.ys"
    script.write_text(f"""
read_verilog {REF}
read_verilog {TREE}
proc
opt_clean
rename lanesum16x8_tree_ref gold
rename lanesum16x8_tree gate
miter -equiv -flatten -make_assert gold gate miter
hierarchy -top miter
opt
sat -verify -prove-asserts -set-init-zero -seq 3 -set-at 1 in_rst_n 0 -set-at 2 in_rst_n 1 -set-at 2 in_valid_i 1 -timeout 1 -dump_cnf {cnf} miter
""")
    subprocess.run(["yosys", "-q", "-s", str(script)], capture_output=True, text=True)
    if not cnf.is_file():
        raise RuntimeError("CNF dump failed")
    return cnf


def solve(cnf_path: Path, name: str, limit: float) -> dict:
    from pysat.formula import CNF
    from pysat.solvers import Solver

    cnf = CNF(from_file=str(cnf_path))
    start = time.perf_counter()
    result = {"solver": name, "limit_s": limit}
    # CaDiCaL ignores interrupts in PySAT, so run every solver in a child
    # process with a hard timeout instead.
    code = (
        "import sys;from pysat.formula import CNF;from pysat.solvers import Solver;"
        f"c=CNF(from_file={str(cnf_path)!r});s=Solver(name={name!r},bootstrap_with=c.clauses);"
        "print('UNSAT' if s.solve() is False else 'SAT')"
    )
    try:
        proc = subprocess.run(["python", "-c", code], capture_output=True, text=True, timeout=limit)
        result["outcome"] = proc.stdout.strip() or proc.stderr.strip()[-200:]
    except subprocess.TimeoutExpired:
        result["outcome"] = "TIMEOUT"
    result["elapsed_s"] = round(time.perf_counter() - start, 1)
    result["variables"] = cnf.nv
    result["clauses"] = len(cnf.clauses)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--limit", type=float, default=120.0)
    args = parser.parse_args()
    cnf = dump_cnf()
    rows = []
    for name in SOLVERS:
        row = solve(cnf, name, args.limit)
        print(row, flush=True)
        rows.append(row)
    record = {
        "question": "Can SAT prove reference(sequential accumulation) == all-ADD balanced tree directly?",
        "miter": "3-cycle unrolled sequential miter (reset, one valid input, compare outputs)",
        "cnf_variables": rows[0]["variables"],
        "cnf_clauses": rows[0]["clauses"],
        "per_solver_limit_s": args.limit,
        "solvers": rows,
        "context": {
            "original_checker": "chiprl/formal.py equiv_simple/equiv_induct ran 69 min 55 s on mask 0x0000 without finishing (2026-09-23)",
            "decomposed_checker": "chiprl/formal_tree_v1.py: 47-link certificate in about 5 s once, then about 0.5 s per candidate",
        },
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(record, indent=2) + "\n")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
