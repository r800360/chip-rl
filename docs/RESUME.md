# Resume material

Written for the Anthropic Research Engineer, Chip Design RL role, whose posting asks for RL environments and evaluations for agentic RTL generation, formal verification and physical design, plus work on EDA-tool latency and proxy rewards. Every number below is backed by a file in this repository.

## Project entry (full version)

**Chip-RL: Verified RL Environment for RTL Optimization** | Verilog, Yosys, OpenROAD, Verilator, Python, Claude API | Sept 2026

- Built an RL environment for hardware design that gates every reward on Verilator simulation and Yosys sequential formal equivalence before a full OpenROAD RTL-to-GDS flow (Nangate45); fingerprinted, cached and bit-reproducible, it scored 1,752 routed designs across 15 benchmarks in 20+ preregistered experiments.
- Caught and closed a reward hack in which spec-violating adders scored 10 to 15% better by dropping output-hold logic, then broke a formal-verification scaling wall: decomposed a 16-lane adder-tree equivalence proof into cut-point proofs plus a 47-step machine-checked rewrite certificate, cutting proof time from over 70 minutes (unsolved by MiniSat, Glucose and CaDiCaL) to 0.38 s per design, with mutation tests confirming soundness.
- Measured proxy rewards for EDA latency: across 1,752 routed designs, a floorplan-stage timing proxy ranks designs with median Spearman 0.97 against post-route results at 15% of tool time; screening after global placement kept the best design in all 15 benchmarks at 2.2x fewer tool-seconds. Profiled one verified evaluation (23 s, 36% fixed overhead) and scaled throughput 4.6x to 691 designs per hour.
- Built a tool-using agent environment (simulate, prove equivalence, estimate PPA, budgeted place-and-route) and evaluated Claude Haiku 4.5, Sonnet 5 and Opus 5 over 72 preregistered episodes: cheap tools lifted the share of episodes beating a measured noise floor from 9/36 to 15/36, agents wrote popcount trees up to +2.02 where a 192-query structural search had stalled, and I caught agents harvesting placement noise and Opus exploiting an unenforced registered-output rule.
- Ran controlled RL studies with frozen-policy and sampling controls (1,400+ physical queries): showed apparent REINFORCE gains came from policy representation rather than learning, derived and numerically verified (to 4.5e-10) an unbiased policy gradient under rejection sampling, and traced failures to search coverage with exhaustive neighborhood sweeps.

## Short version (3 bullets)

- Built a formally verified RL environment for RTL optimization (Verilator, Yosys equivalence, OpenROAD RTL-to-GDS) and ran 20+ preregistered RL and Claude-agent experiments on 1,752 routed designs.
- Closed a reward hack with formal gating, cut a non-terminating adder-tree equivalence proof to 0.38 s per design, and showed a floorplan-stage proxy predicts post-route scores (Spearman 0.97) at 15% of tool time.
- Showed apparent RL gains disappeared under frozen-policy controls, and caught Claude agents harvesting placement noise and exploiting an unenforced registered-output rule.

## One line

Built a formally verified, physically evaluated RL environment for RTL optimization (Yosys, OpenROAD) and used it to study reward hacking, proxy rewards, EDA latency, policy-gradient learners and Claude agents across 1,752 routed designs.

## Skills this project demonstrates

| Area | Evidence |
|---|---|
| RTL design | Carry-select, parallel-prefix and carry-lookahead adders, reduction trees, comparators, priority encoders, popcount; cycle-accurate valid/hold protocol ([RTL_GALLERY.md](RTL_GALLERY.md)) |
| Design verification | Constrained-random and exhaustive testbenches, sequential equivalence checking, proof decomposition with cut points, mutation testing of the checker |
| Physical design | OpenROAD flow end to end (synthesis, floorplan, placement, CTS, routing, STA), reading timing reports, fixed-floorplan PPA comparison, layout rendering |
| RL and evaluation | Environment design, REINFORCE variants, exact gradient derivation, frozen controls, preregistration, replay audits |
| Agentic systems | Tool-use loop with budgets and costs, prompt caching, transcript logging, model comparison |
| Infrastructure | Content-addressed caching, deterministic Docker flows, parallel evaluation with locks, multi-fidelity screening |

## Framing tips

- Lead with the environment and the reward integrity story; that is the job.
- Say "formally verified" only about equivalence to a reference: the tools prove functional equivalence, not timing signoff.
- Present the RL findings as careful science: the controls are the achievement, not a failure.
- Be exact about scale: open 45 nm library, small blocks, no tapeout.
