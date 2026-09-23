# Zero-EDA audit: rejection-conditioned v2 gradient

Additive files only. Do not modify `chiprl/autoregressive_policy.py`, which is
source-hash-frozen by the completed cross-family study. Do not change any
saved state, protocol or measured result. The new `chiprl/conditioned_policy_gradient.py`
module is a mathematical reference implementation, **not** yet a new training policy.

## Run

From the existing `~/fpga/chip-rl` repository with its virtualenv activated:

```bash
python -m py_compile chiprl/conditioned_policy_gradient.py experiments/audit_conditioned_policy_gradient_v1.py
python -m experiments.audit_conditioned_policy_gradient_v1
cat results/conditioned_gradient_audit_v1.json
```

This executes zero physical-design queries. It checks exact normalization of
the source-frozen count+ordered-position policy at 3, 4 and 5 mask bits; compares
analytic conditioned score gradients against central finite differences for
all logits of two unseen masks; checks that conditional expected score is zero;
compares the exact policy-gradient of a fixed synthetic reward objective to
finite differences; verifies that the original frozen `policy.update()` applies
the *unconditioned* score; and runs a fixed-seed 12,000-sample rejection-sampler
frequency check. It then diagnoses how much prior probability is rejected by the
8 measured seed masks of each real 31-bit benchmark and, where the files exist,
the post-query-16 policies from the completed cross-family runs.

The conditional score is

`grad(log(q_theta(m))) = grad(log(p_theta(m))) + sum(p_theta(s)*grad(log(p_theta(s))) for s in seen)/(1 - P_theta(seen))`

where `q_theta` is the original policy conditioned on proposing an unseen mask.
**Use the pre-query seen set** when implementing a corrected update; calling it
after the environment records the new mask without removing that mask will be
incorrect.

The audit is not an RL performance comparison; it establishes a mathematical
mismatch and a validated reference derivative. Because the historical v2
implementation is frozen, any future corrected v3 should use separate source,
run identifiers and a preregistered evaluation protocol.

## Separate corrected-v3 prototype

The package additionally contains `chiprl/conditioned_autoregressive_policy.py`
and `experiments/smoke_conditioned_v3.py`. The new subclass has an explicit
`update_conditioned(mask=..., score=..., seen_masks=pre_query_seen)` method.
It retains all frozen v2 initialization, sampling, clipping and moving-baseline
settings and changes **only** the log-score gradient used to update count and
position logits. It is not wired into any historical runner.

```bash
python -m experiments.smoke_conditioned_v3
```

Tests include: with an empty seen set, v3 matches the original v2 update;
when only one unseen action remains, the true conditional score is zero;
the method refuses a post-query seen set containing the action; and the
corrected logit update is verified against the analytical gradient on all
three archived measured corpora. This tests mathematical correctness, **not**
physical-design improvement. Do not launch new EDA comparisons until a new
protocol is frozen with separate v3 method IDs and fresh benchmarks.

`results/conditioned_gradient_audit_reference.json` is a reference output generated
against the attached, hash-verified historical cross-family archive. Your local
execution writes `results/conditioned_gradient_audit_v1.json` separately.
