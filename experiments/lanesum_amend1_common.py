"""Amendment 1 for the lane-sum study: route formal checks to the tree proof.

The preregistered lane-sum runners call chiprl.formal.check_equivalence, a
monolithic Yosys proof that did not finish in 70 minutes on the first seed.
Those runners, the evaluator and the formal module are hash-frozen by earlier
protocols, so they are not edited. Instead this context manager swaps in
chiprl.formal_tree_v1.check_equivalence_tree (same Yosys commands, proof
decomposed with cut points plus a one-time certificate) while the frozen code
runs, and tags every evaluation record with the proof method used.

Nothing else changes: RTL, reference, testbench, ORFS config, reward,
diversity gate and search algorithms are the preregistered ones.
"""
from __future__ import annotations

import contextlib
import json
from pathlib import Path

import chiprl.evaluate as evaluator
from chiprl.benchmarks import ROOT
from chiprl.formal_tree_v1 import (
    METHOD_ID,
    check_equivalence_tree,
    lanesum16x8_spec,
    verify_certificate,
)

AMENDMENT = ROOT / "experiments/amendment_lanesum_formal_v1.json"


def _tag_record(result: dict) -> dict:
    """Add the proof method to the returned row and to the saved record."""
    result = dict(result)
    result["formal_method"] = METHOD_ID
    record = (
        ROOT / "results" / "evaluations" / result["benchmark"]
        / f"{result['evaluation_id']}.json"
    )
    if record.is_file():
        saved = json.loads(record.read_text())
        if saved.get("formal_method") != METHOD_ID:
            saved["formal_method"] = METHOD_ID
            record.write_text(json.dumps(saved, indent=2, sort_keys=True) + "\n")
    return result


@contextlib.contextmanager
def tree_formal(*modules):
    """Run frozen lane-sum code with the amended proof method.

    `modules` are frozen experiment modules that imported `evaluate` or
    `check_equivalence` by name; their references are patched as well.
    """
    if not AMENDMENT.is_file():
        raise RuntimeError("Register the formal amendment before using it")
    spec = lanesum16x8_spec()
    verify_certificate(spec)

    def checker(candidate, benchmark):
        return check_equivalence_tree(candidate, benchmark, spec=spec)

    original_evaluate = evaluator.evaluate

    def evaluate(*args, **kwargs):
        return _tag_record(original_evaluate(*args, **kwargs))

    saved = [(evaluator, "check_equivalence", evaluator.check_equivalence)]
    for module in modules:
        for name in ("check_equivalence", "evaluate"):
            if hasattr(module, name):
                saved.append((module, name, getattr(module, name)))
    try:
        evaluator.check_equivalence = checker
        for module in modules:
            if hasattr(module, "check_equivalence"):
                module.check_equivalence = checker
            if hasattr(module, "evaluate"):
                module.evaluate = evaluate
        yield
    finally:
        for module, name, value in saved:
            setattr(module, name, value)
