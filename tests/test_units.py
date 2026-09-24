"""Fast unit tests (no Docker, no EDA)."""
from __future__ import annotations

import pytest

from chiprl.agentic_env import TASKS, check_source, tool_definitions
from chiprl.formal_tree_v1 import (
    balanced, chain, exact_width, leaf_mask, lanesum16x8_spec, render_tree, rewrite_schedule,
)


# -- candidate hygiene ------------------------------------------------------

@pytest.fixture
def cmp32():
    task = TASKS["cmp32"]
    return task, task.baseline_rtl.read_text()


def test_baseline_is_accepted(cmp32):
    task, src = cmp32
    assert check_source(src, task) is None


@pytest.mark.parametrize("edit, reason", [
    (lambda s: s.replace("always", "initial begin end\nalways", 1), "initial"),
    (lambda s: s.replace("endmodule", "always @(posedge clk) $display(\"x\");\nendmodule"), "system"),
    (lambda s: "`define W 32\n" + s, "directive"),
    (lambda s: s + "\nmodule helper(input a, output b); assign b = a; endmodule\n", "one module"),
    (lambda s: s.replace("module cmp32", "module cmp32_ref"), "one module"),
])
def test_hygiene_rejections(cmp32, edit, reason):
    task, src = cmp32
    assert check_source(edit(src), task) is not None


def test_comments_are_ignored(cmp32):
    task, src = cmp32
    assert check_source("// initial $display is only a comment\n" + src, task) is None


def test_tool_conditions():
    full = {t["name"] for t in tool_definitions("full_tools")}
    pnr = {t["name"] for t in tool_definitions("pnr_only")}
    assert full == {"simulate", "prove_equivalence", "estimate_ppa", "place_and_route", "finish"}
    assert pnr == {"place_and_route", "finish"}


# -- proof rewrite schedule ---------------------------------------------------

def _internal(tree, acc):
    if isinstance(tree, int):
        return acc
    acc.add(leaf_mask(tree))
    _internal(tree[0], acc)
    _internal(tree[1], acc)
    return acc


def test_schedule_endpoints_and_locality():
    spec = lanesum16x8_spec()
    steps = rewrite_schedule(spec)
    assert steps[0][1] == chain(spec.reference_order)
    assert steps[-1][1] == balanced(spec.tree_order)
    assert len(steps) == 46
    for (_, a), (_, b) in zip(steps, steps[1:]):
        assert len(_internal(a, set()) ^ _internal(b, set())) <= 2  # one node swapped out, one in


def test_widths_are_exact():
    spec = lanesum16x8_spec()
    assert exact_width(spec, balanced(spec.tree_order)) == 12   # 16 * 255 = 4080 < 4096
    assert exact_width(spec, (0, 1)) == 9                          # 2 * 255 = 510
    text = render_tree(spec, balanced(spec.tree_order))
    assert "wire [11:0] s_ffff" in text and text.count("module ") == 1
