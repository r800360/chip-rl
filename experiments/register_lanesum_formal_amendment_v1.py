"""Register formal amendment 1 for the lane-sum study (before any PPA).

Checks the preconditions that make the amendment legitimate, then writes
experiments/amendment_lanesum_formal_v1.json once. Use --verify afterwards.
"""
from __future__ import annotations

import argparse
import hashlib
import json

from chiprl.benchmarks import ROOT
from chiprl.formal_tree_v1 import (
    EQUIV_COMMANDS, METHOD_ID, certificate_path, lanesum16x8_spec, verify_certificate,
)

AMENDMENT = ROOT / "experiments/amendment_lanesum_formal_v1.json"
HARDNESS = ROOT / "results/formal/lanesum16x8_monolithic_hardness_v1.json"
NEW_SOURCES = (
    "chiprl/formal_tree_v1.py",
    "experiments/lanesum_amend1_common.py",
    "experiments/lanesum_pilot_v1_amend1.py",
    "experiments/learned_local_study_v1_amend1.py",
    "experiments/run_learned_local_v1_amend1.sh",
    "experiments/lanesum_formal_hardness_v1.py",
    "tests/test_formal_tree_v1.py",
)
MUST_NOT_EXIST = (
    "results/lanesum16x8_baseline_v1.json",
    "results/lanesum16x8_arch_seed_v1",
    "results/evaluations/lanesum16x8_tree",
    "results/rl_runs/lanesum16x8_tree",
)


def sha(path):
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()


def build(*, before_ppa: bool = True) -> dict:
    import experiments.lanesum_pilot_v1 as pilot

    pilot.verify()  # frozen protocol, sources and RTL unchanged
    for rel in MUST_NOT_EXIST if before_ppa else ():
        if (ROOT / rel).exists():
            raise RuntimeError(f"PPA or search data already exists: {rel}")
    spec = lanesum16x8_spec()
    cert = verify_certificate(spec)
    hardness = json.loads(HARDNESS.read_text())
    return {
        "amendment": "lanesum_formal_v1",
        "applies_to": ["lanesum16x8_architecture_pilot_v1", "lanesum16x8_learned_local_study_v1"],
        "stage": "after HDL simulation of seed 0x0000, before any formal pass or physical measurement",
        "physical_results_observed_before_amendment": False,
        "issue": (
            "chiprl/formal.py ran 69 min 55 s on seed 0x0000 without finishing. "
            "The reference accumulates 16 lanes sequentially and candidates use a balanced tree, "
            "so the circuits share no internal signals and the SAT problem is a re-association proof."
        ),
        "evidence": {
            "cnf_variables": hardness["cnf_variables"],
            "cnf_clauses": hardness["cnf_clauses"],
            "solvers_timed_out_at_s": {
                r["solver"]: r["limit_s"] for r in hardness["solvers"] if r["outcome"] == "TIMEOUT"
            },
            "hardness_record": HARDNESS.relative_to(ROOT).as_posix(),
        },
        "new_method": {
            "id": METHOD_ID,
            "per_candidate": "candidate == all-ADD tree (frozen rtl/lanesum16x8_tree/baseline.v); node names are cut points",
            "one_time": f"reference == all-ADD tree via {cert['link_count']} single-rewrite links, all proven",
            "same_yosys_commands": list(EQUIV_COMMANDS),
            "certificate": certificate_path(spec).relative_to(ROOT).as_posix(),
            "certificate_sha256": sha(certificate_path(spec).relative_to(ROOT)),
            "validation": "tests/test_formal_tree_v1.py: 8/8 seeds proven, 7/7 mutants rejected, corrupted rewrite step rejected",
        },
        "unchanged": [
            "candidate RTL and generator", "behavioral reference", "Verilator testbench",
            "ORFS config and SDC", "proxy_reward_v0", "diversity gate thresholds",
            "search algorithms, budgets and RNG seeds",
        ],
        "limitation": "Sound but incomplete: RTL without the tree's node names falls back to a monolithic proof and times out.",
        "new_source_sha256": {rel: sha(rel) for rel in NEW_SOURCES},
        "frozen_pilot_protocol_sha256": sha("experiments/protocol_lanesum_pilot_v1.json"),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    body = build(before_ppa=not args.verify)
    if args.verify:
        saved = json.loads(AMENDMENT.read_text())
        for rel, digest in saved["new_source_sha256"].items():
            if sha(rel) != digest:
                raise RuntimeError(f"amended source changed after registration: {rel}")
        if saved["new_method"]["certificate_sha256"] != body["new_method"]["certificate_sha256"]:
            raise RuntimeError("certificate changed after registration")
        print("PASS: amendment, certificate and amended sources unchanged")
        return
    if AMENDMENT.exists():
        raise RuntimeError("Amendment already registered; use --verify")
    AMENDMENT.write_text(json.dumps(body, indent=2, sort_keys=True) + "\n")
    print("REGISTERED", AMENDMENT.relative_to(ROOT))


if __name__ == "__main__":
    main()
