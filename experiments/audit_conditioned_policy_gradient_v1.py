"""Zero-EDA audit of frozen v2's rejection-conditioned policy gradient.

Run: python -m experiments.audit_conditioned_policy_gradient_v1
Optional: python -m experiments.audit_conditioned_policy_gradient_v1 --output results/conditioned_gradient_audit_v1.json

Requires the existing unmodified chiprl/autoregressive_policy.py, frozen
protocol, and measured shared seeds. Never starts a search or calls EDA.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
import random
from collections import Counter
from pathlib import Path

from chiprl.autoregressive_policy import HierarchicalAutoregressiveMaskPolicy
from chiprl.conditioned_policy_gradient import (
    conditioned_log_probability,
    conditioned_score,
    log_unconditional_probability,
    raw_log_score,
    unconditional_probability,
)

ROOT = Path(__file__).resolve().parents[1]


def require_close(value: float, expected: float, tol: float, description: str) -> None:
    if not math.isclose(value, expected, abs_tol=tol, rel_tol=0):
        raise AssertionError(f"{description}: got {value:.12g}, expected {expected:.12g} (tol {tol})")


def synthetic(bits: int) -> HierarchicalAutoregressiveMaskPolicy:
    rows = [
        {"boundary_mask": 0, "proxy_reward_v0": 0.0},
        {"boundary_mask": 3, "proxy_reward_v0": 1.0},
        {"boundary_mask": (1 << bits) - 1, "proxy_reward_v0": 0.3},
    ]
    return HierarchicalAutoregressiveMaskPolicy(
        bits=bits, seed_rows=rows, temperature=1.0,
        count_prior=0.8, position_prior=0.13,
        logit_clip=100.0, count_learning_rate=0.1,
        position_learning_rate=0.1, minimum_scale=1.0,
    )


def seen_masks(bits: int) -> set[int]:
    return {0, 3, (1 << bits) - 1, 1 << (bits - 1)}


def conditional_mass(policy, seen: set[int]) -> float:
    return 1.0 - math.fsum(unconditional_probability(policy, x) for x in seen)


def finite_difference(policy, attr: str, i: int, fn, epsilon: float = 1e-6) -> float:
    logits = getattr(policy, attr)
    old = logits[i]
    try:
        logits[i] = old + epsilon
        plus = fn()
        logits[i] = old - epsilon
        minus = fn()
    finally:
        logits[i] = old
    return (plus - minus) / (2.0 * epsilon)


def synthetic_audit(bits: int) -> dict:
    policy = synthetic(bits)
    seen = seen_masks(bits)
    masks = range(1 << bits)
    all_mass = math.fsum(unconditional_probability(policy, m) for m in masks)
    require_close(all_mass, 1.0, 1e-12, f"bits{bits}: p sums to one")
    z = conditional_mass(policy, seen)
    assert 0.01 < z < 0.99, (bits, z)
    conditioned = {m: math.exp(conditioned_log_probability(policy, m, seen))
                   for m in masks if m not in seen}
    require_close(math.fsum(conditioned.values()), 1.0, 1e-12,
                  f"bits{bits}: q sums to one")
    # Independently finite-difference log q for EVERY parameter of two unseen masks.
    examples = [m for m in conditioned if m not in seen][:2]
    max_fd_error = 0.0
    for m in examples:
        grad = conditioned_score(policy, m, seen)
        for attr, key in (("count_logits", "count"), ("position_logits", "position")):
            for i, true in enumerate(grad[key]):
                numeric = finite_difference(
                    policy, attr, i,
                    lambda m=m: conditioned_log_probability(policy, m, seen),
                )
                error = abs(true - numeric)
                max_fd_error = max(max_fd_error, error)
                require_close(true, numeric, 3e-7,
                              f"bits{bits}, mask{m}, {attr}[{i}]")

    # The conditioned score has zero expectation under the conditioned distribution.
    # In contrast, the frozen implementation's uncorrected score usually does not.
    expected_corrected = [0.0] * (2 * bits + 1)
    expected_uncorrected = [0.0] * (2 * bits + 1)
    for m, q in conditioned.items():
        g = conditioned_score(policy, m, seen)
        corrected = g["count"] + g["position"]
        old = g["raw_count"] + g["raw_position"]
        for j in range(len(corrected)):
            expected_corrected[j] += q * corrected[j]
            expected_uncorrected[j] += q * old[j]
    max_corrected_bias = max(map(abs, expected_corrected))
    raw_bias_norm = math.sqrt(math.fsum(x*x for x in expected_uncorrected))
    assert max_corrected_bias < 3e-12, (bits, max_corrected_bias)
    assert raw_bias_norm > 1e-3, (bits, raw_bias_norm)

    # Independent finite-difference check of an artificial objective, not EDA.
    # This test includes a mask-dependent reward to test the full policy gradient.
    def reward(mask: int) -> float:
        return 0.25 * mask.bit_count() + 0.07 * (mask % 3) - 0.13 * bool(mask & 1)
    def objective() -> float:
        z_here = conditional_mass(policy, seen)
        return math.fsum(
            unconditional_probability(policy, m) * reward(m) / z_here
            for m in masks if m not in seen
        )
    max_objective_error = 0.0
    raw_objective_error = 0.0
    for attr, key, offset in (("count_logits", "count", 0),
                              ("position_logits", "position", bits+1)):
        for i in range(len(getattr(policy, attr))):
            analytic = math.fsum(
                conditioned[m] * reward(m) * conditioned_score(policy, m, seen)[key][i]
                for m in conditioned
            )
            raw = math.fsum(
                conditioned[m] * reward(m) * raw_log_score(policy, m)[0 if key == "count" else 1][i]
                for m in conditioned
            )
            numeric = finite_difference(policy, attr, i, objective)
            max_objective_error = max(max_objective_error, abs(analytic-numeric))
            raw_objective_error = max(raw_objective_error, abs(raw-numeric))
            require_close(analytic, numeric, 3e-7,
                          f"bits{bits}, reward objective {attr}[{i}]")
    assert raw_objective_error > 1e-3, (bits, raw_objective_error)

    # Confirm frozen update() actually implements the UNCONDITIONED score.
    # No files or production policy implementations are modified.
    m = examples[0]
    clone = copy.deepcopy(policy)
    clone.baseline = 0.0
    clone.scale = 1.0
    before_c = clone.count_logits[:]
    before_p = clone.position_logits[:]
    advantage = clone.update(mask=m, score=1.0)
    require_close(advantage, 1.0, 1e-12, "test advantage")
    gk, gp = raw_log_score(policy, m)
    for i, (before, after) in enumerate(zip(before_c, clone.count_logits)):
        require_close((after-before)/clone.count_learning_rate, gk[i], 1e-11,
                      f"bits{bits}, frozen count update {i}")
    for i, (before, after) in enumerate(zip(before_p, clone.position_logits)):
        require_close((after-before)/clone.position_learning_rate, gp[i], 1e-11,
                      f"bits{bits}, frozen position update {i}")

    return {
        "bits": bits,
        "mask_space": 1 << bits,
        "seen_count": len(seen),
        "acceptance": z,
        "max_finite_difference_logscore_error": max_fd_error,
        "expected_corrected_score_max_abs": max_corrected_bias,
        "expected_raw_score_l2": raw_bias_norm,
        "max_finite_difference_reward_error": max_objective_error,
        "max_uncorrected_reward_error": raw_objective_error,
    }


def monte_carlo_audit(bits: int = 4, draws: int = 12000) -> dict:
    policy = synthetic(bits)
    seen = seen_masks(bits)
    z = conditional_mass(policy, seen)
    expectation = {
        m: unconditional_probability(policy, m) / z
        for m in range(1 << bits) if m not in seen
    }
    rng = random.Random(20260923)
    observed = Counter(policy.sample(rng=rng, seen_masks=seen) for _ in range(draws))
    error = max(abs(observed[m] / draws - probability)
                for m, probability in expectation.items())
    assert not set(observed).intersection(seen)
    assert error < 0.02, error
    return {"draws": draws, "max_frequency_error": error}


def real_corpus_audit() -> dict:
    protocol_path = ROOT / "experiments" / "protocol_crossfamily_v1.json"
    if not protocol_path.is_file():
        raise FileNotFoundError(f"Frozen study protocol missing: {protocol_path}")
    protocol = json.loads(protocol_path.read_text())
    policy_path = ROOT / "chiprl" / "autoregressive_policy.py"
    expected = protocol["frozen_source_sha256"]["chiprl/autoregressive_policy.py"]
    observed = hashlib.sha256(policy_path.read_bytes()).hexdigest()
    assert observed == expected, (
        "Frozen source hash differs; audit against the completed study requires the original version",
        expected, observed,
    )
    out = {}
    for name in ("cmp32", "popcount32", "priority32"):
        rows_path = ROOT / "results" / f"{name}_shared_seed" / "results.json"
        rows = json.loads(rows_path.read_text())
        assert len(rows) == 8
        bits = 31
        seeds = [int(r["boundary_mask"]) for r in rows]
        policy = HierarchicalAutoregressiveMaskPolicy(bits=bits, seed_rows=rows)
        acceptance = conditional_mass(policy, set(seeds))
        rng = random.Random(20260923)
        proposed = policy.sample(rng=rng, seen_masks=seeds)
        diagnostics = conditioned_score(policy, proposed, seeds)
        correction_l2 = math.sqrt(math.fsum(
            x*x for x in diagnostics["correction_count"] + diagnostics["correction_position"]
        ))
        initial = {
            "seen_count": len(set(seeds)),
            "seen_mass": 1.0 - acceptance,
            "acceptance": acceptance,
            "expected_attempts_unbounded": 1.0 / acceptance,
            "example_proposal_mask": f"0x{proposed:08x}",
            "example_proposal_boundaries": proposed.bit_count(),
            "example_proposal_score_correction_l2": correction_l2,
        }
        after = {}
        for seed in (20260923, 20260924, 20260925):
            directory = ROOT / "results" / "rl_runs" / name / f"v2_learn_seed_{seed}"
            state_path = directory / "state.json"
            snapshot_path = directory / "policy_after_16.json"
            if not state_path.is_file() or not snapshot_path.is_file():
                continue
            state = json.loads(state_path.read_text())
            snap = json.loads(snapshot_path.read_text())
            assert len(state["queries"]) == 16
            last_policy = HierarchicalAutoregressiveMaskPolicy(bits=bits, seed_rows=rows)
            last_policy.count_logits = list(snap["count_logits"])
            last_policy.position_logits = list(snap["position_logits"])
            last_seen = set(seeds) | {int(q["boundary_mask"]) for q in state["queries"]}
            z_last = conditional_mass(last_policy, last_seen)
            after[str(seed)] = {
                "seen_count": len(last_seen),
                "seen_mass": 1.0 - z_last,
                "acceptance": z_last,
                "expected_attempts_unbounded": 1.0 / z_last,
            }
        out[name] = {"initial": initial, "after_16": after}
    return {"frozen_policy_sha256": observed, "families": out}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("results/conditioned_gradient_audit_v1.json"))
    args = parser.parse_args()
    print("FROZEN V2: ZERO-EDA REJECTION-CONDITIONED GRADIENT AUDIT")
    synthetic_results = []
    for bits in (3, 4, 5):
        r = synthetic_audit(bits)
        synthetic_results.append(r)
        print(f"PASS exact bits={bits}: Z={r['acceptance']:.6f} "
              f"uncorrected-score-bias-L2={r['expected_raw_score_l2']:.6f} "
              f"max-finite-diff-error={r['max_finite_difference_logscore_error']:.2e}")
    mc = monte_carlo_audit()
    print(f"PASS rejection-sampling Monte Carlo: {mc['draws']} draws; "
          f"max-frequency-error={mc['max_frequency_error']:.4f}")
    corpora = real_corpus_audit()
    for name, data in corpora["families"].items():
        x = data["initial"]
        print(f"{name}: initially seen mass={x['seen_mass']:.6f}; "
              f"acceptance={x['acceptance']:.6f}; "
              f"expected draws/proposal={x['expected_attempts_unbounded']:.2f}; "
              f"score correction L2(example)={x['example_proposal_score_correction_l2']:.4f}")
        for seed, y in data["after_16"].items():
            print(f"  after16 seed={seed}: seen mass={y['seen_mass']:.6f}; "
                  f"acceptance={y['acceptance']:.6f}")
    result = {
        "audit_version": 1,
        "scope": "correctness and analytical bias only; not evidence of improved physical reward",
        "frozen_source_sha256": corpora["frozen_policy_sha256"],
        "synthetic_exact_tests": synthetic_results,
        "sampling_test": mc,
        "historical_corpus_diagnostics": corpora["families"],
        "passes": {"normalization": True, "conditional_finite_difference": True,
                   "expected_score_zero": True, "reward_objective_gradient": True,
                   "frozen_update_matches_unconditioned_score": True,
                   "rejection_sampler_matches_conditional_distribution": True,
                   "historical_source_hash": True},
    }
    path = args.output if args.output.is_absolute() else ROOT / args.output
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print("PASS: exact gradient reference and historical v2 discrepancy established")
    print("Audit record:", path)


if __name__ == "__main__":
    main()
