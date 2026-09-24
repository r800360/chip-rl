"""Soundness and completeness checks for the decomposed tree proof.

These tests run Yosys inside the frozen ORFS container (about 1 s each).
Every mutant is a real bug a generator or an LLM could produce. The checker
must reject all of them, and it must accept all eight preregistered seeds.

Run:  pytest -q tests/test_formal_tree_v1.py
"""
from __future__ import annotations

import shutil
from pathlib import Path

import pytest

from chiprl.benchmarks import ROOT
from chiprl.formal_tree_v1 import (
    check_equivalence_tree,
    lanesum16x8_spec,
    render_tree,
    rewrite_schedule,
    verify_certificate,
)
from chiprl.lane_sum_tree_v1 import PILOT_MASKS, benchmark

SEEDS = ROOT / "rtl/generated/lanesum16x8_tree_arch_seed_v1"
MUTANTS = ROOT / ".chiprl/formal_tree/mutants"

pytestmark = pytest.mark.skipif(
    shutil.which("docker") is None, reason="needs the ORFS Docker image"
)


def write_mutant(name: str, source: str, old: str, new: str) -> Path:
    text = (SEEDS / source).read_text()
    assert text.count(old) >= 1, f"mutation site missing: {old!r}"
    MUTANTS.mkdir(parents=True, exist_ok=True)
    path = MUTANTS / f"{name}.v"
    path.write_text(text.replace(old, new, 1))
    return path


def test_certificate_is_valid():
    cert = verify_certificate(lanesum16x8_spec())
    assert cert["all_links_proven"] and cert["link_count"] == 47


@pytest.mark.parametrize("mask", PILOT_MASKS)
def test_all_preregistered_seeds_prove(mask):
    result = check_equivalence_tree(SEEDS / f"mask_{mask:04x}.v", benchmark())
    assert result["formal_ok"], result["formal_output"]


MUTATIONS = {
    # CLA carry chain drops one generate term (classic hand-written CLA bug).
    "cla_missing_generate_term": (
        "mask_7fff.v",
        "assign n_0_0[3] = p_0_3 ^ ((g_0_2) | (g_0_1 & p_0_2) | (g_0_0 & p_0_1 & p_0_2));",
        "assign n_0_0[3] = p_0_3 ^ ((g_0_2) | (g_0_1 & p_0_2));",
    ),
    # Propagate computed with OR instead of XOR.
    "propagate_or_instead_of_xor": (
        "mask_7fff.v",
        "wire p_0_2 = leaf_0[2] ^ leaf_1[2];",
        "wire p_0_2 = leaf_0[2] | leaf_1[2];",
    ),
    # Wrong lane wiring: lane 0 reads lane 1's byte.
    "wrong_lane_slice": (
        "mask_5555.v",
        "wire [7:0] leaf_0 = a_i[7:0];",
        "wire [7:0] leaf_0 = a_i[15:8];",
    ),
    # Root carry-out dropped: result silently truncated to 11 bits.
    "root_carry_dropped": (
        "mask_7fff.v",
        "assign n_3_0[11] = (g_14_10)",
        "assign n_3_0[11] = 1'b0 & (g_14_10)",
    ),
    # The reward hack found by random search on day one: output not held
    # when valid_i is low (saves an enable mux, violates the protocol).
    "output_hold_removed": (
        "mask_7fff.v",
        "    if (valid_i)\n      y_o <= n_3_0;",
        "    y_o <= n_3_0;",
    ),
    # Wrong reset value.
    "wrong_reset_value": (
        "mask_7fff.v",
        "    y_o <= 12'd0;",
        "    y_o <= 12'd1;",
    ),
    # valid_o no longer tracks valid_i.
    "valid_stuck_high": (
        "mask_5555.v",
        "    valid_o <= valid_i;",
        "    valid_o <= 1'b1;",
    ),
}


@pytest.mark.parametrize("name", sorted(MUTATIONS))
def test_mutants_are_rejected(name):
    source, old, new = MUTATIONS[name]
    path = write_mutant(name, source, old, new)
    result = check_equivalence_tree(path, benchmark(), timeout_s=120)
    assert not result["formal_ok"], f"{name} was wrongly proven equivalent"
    assert not result["formal_timed_out"], f"{name} should fail fast, not time out"


def test_broken_rewrite_step_is_rejected(tmp_path):
    """A wrong intermediate design must break the certificate chain."""
    from chiprl.formal_tree_v1 import equiv_script, run_yosys_batch

    spec = lanesum16x8_spec()
    steps = rewrite_schedule(spec)
    good = render_tree(spec, steps[10][1])
    # Corrupt the step by replacing one addition with a subtraction.
    bad = good.replace(" + ", " - ", 1)
    work = ROOT / ".chiprl/formal_tree/mutants"
    work.mkdir(parents=True, exist_ok=True)
    gold, gate = work / "chain_step_good.v", work / "chain_step_bad.v"
    prev = work / "chain_step_prev.v"
    prev.write_text(render_tree(spec, steps[9][1]))
    gold.write_text(good)
    gate.write_text(bad)
    script = work / "chain_step_bad.ys"
    script.write_text(equiv_script(prev, spec.top_module, gate, spec.top_module))
    outcome = run_yosys_batch([script], timeout_s=120)[0]
    assert not outcome["proven"]


def test_arbitrary_rtl_is_not_falsely_proven():
    """Without shared node names the proof is monolithic: it may time out,
    but it must never report success for a design it could not prove."""
    spec = lanesum16x8_spec()
    MUTANTS.mkdir(parents=True, exist_ok=True)
    renamed = MUTANTS / "reference_as_candidate.v"
    renamed.write_text(spec.reference.read_text().replace(
        f"module {spec.top_module}_ref", f"module {spec.top_module}"))
    result = check_equivalence_tree(renamed, benchmark(), timeout_s=15)
    # The reference is truly equivalent, but it shares no cut points with T0,
    # so the checker is expected to time out rather than prove it.
    assert result["formal_timed_out"] or result["formal_ok"]
    if result["formal_timed_out"]:
        assert not result["formal_ok"]
