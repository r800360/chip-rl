"""Equivalence checker v2: the gaps found by the agentic eval, closed.

Runs Yosys in the ORFS container (under a second per case).
"""
from __future__ import annotations

import shutil

import pytest

from chiprl.benchmarks import ROOT, get_benchmark
from chiprl.formal import check_equivalence as check_v1
from chiprl.formal_v2 import check

pytestmark = pytest.mark.skipif(shutil.which("docker") is None, reason="needs the ORFS image")

AGENT = ROOT / "rtl/agentic_eval_v1"
LUT_POPCOUNT = AGENT / "popcount32__full_tools__claude-sonnet-5__r3/call07_prove_equivalence_93087ab3842e.v"
NO_RESET_ADDER = AGENT / "addpipe32__full_tools__claude-haiku-4-5__r3/call04_prove_equivalence_810924de1f0b.v"
ASYNC_RESET_CMP = AGENT / "cmp32__full_tools__claude-haiku-4-5__r2/call09_prove_equivalence_3072710dfc8c.v"
HIERARCHICAL_CMP = ROOT / "tests/fixtures/cmp32_hierarchical.v"


def test_baseline_proven():
    assert check(ROOT / "rtl/cmp32/baseline.v", get_benchmark("cmp32"))["status"] == "PROVEN"


def test_case_lookup_table_now_proven():
    # v1 rejects it: Yosys proc turns the case table into ROMs equiv_make cannot read.
    assert not check_v1(LUT_POPCOUNT, get_benchmark("popcount32"))["formal_ok"]
    assert check(LUT_POPCOUNT, get_benchmark("popcount32"))["status"] == "PROVEN"


def test_hierarchical_design_now_proven():
    assert not check_v1(HIERARCHICAL_CMP, get_benchmark("cmp32"))["formal_ok"]
    assert check(HIERARCHICAL_CMP, get_benchmark("cmp32"))["status"] == "PROVEN"


def test_missing_reset_gets_counterexample():
    # Passed 10,000 simulated transactions because Verilator zero-initializes registers.
    r = check(NO_RESET_ADDER, get_benchmark("addpipe32"))
    assert r["status"] == "NOT_EQUIVALENT"
    after_reset = {row["signal"]: row["hex"] for row in r["counterexample"] if row["step"] == 2}
    assert after_reset["gold.y_o"] != after_reset["gate.y_o"]


def test_async_reset_is_rejected():
    assert check(ASYNC_RESET_CMP, get_benchmark("cmp32"))["status"] in ("UNSUPPORTED", "NOT_EQUIVALENT")
