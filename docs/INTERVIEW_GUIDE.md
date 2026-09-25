# Interview guide

Everything needed to present Chip-RL and defend it under deep questioning. Numbers are from the frozen records in this repository.

## 1. Pitches

**30 seconds.**
I built an RL environment for hardware design where no design is scored until it is verified: every candidate RTL design is simulated, formally proven equivalent to a reference, then taken through a full open-source RTL-to-GDS flow, and only then scored on post-route area and timing. I used it to run preregistered experiments with RL policies and Claude agents on about 1,800 routed designs. The most useful findings were about the environment itself: a reward hack on day one, a formal-verification scaling wall that I fixed with a decomposed proof (from over 70 minutes to 0.4 seconds per design), a cheap floorplan-stage proxy that ranks designs almost as well as full place-and-route at 15% of the tool time, and Claude agents that exposed two more holes: small "improvements" that were placement noise on an unchanged netlist, and a spec loophole that Opus exploited by retiming logic past the output register.

**2 minutes.** Use this order: problem, system, three findings, what is next.
1. *Problem.* Training models to design chips needs environments whose rewards are verifiable and whose EDA cost is manageable. Two things break that: rewards that can be hacked, and tool latency.
2. *System.* `evaluate()` runs Verilator, then Yosys sequential equivalence, then OpenROAD on Nangate45, and returns a fingerprinted, cached, bit-reproducible reward. On top of it: a query-budgeted RL environment, REINFORCE policies, and a tool-using agent environment for Claude.
3. *Finding one: verification is the reward.* Random search found designs that dropped the output-hold logic and scored higher. Formal equivalence makes that class of hack unscorable. When the monolithic proof stopped scaling on a 16-lane adder tree, I decomposed it into cut-point proofs plus a 47-step rewrite certificate: 70+ minutes became 0.38 s per candidate, with mutation tests showing it still rejects real bugs.
4. *Finding two: be skeptical of RL gains.* A hierarchical REINFORCE policy improved all three fresh adder widths, but matched frozen-policy controls showed the gain came from the policy's initialization and sampling shape, not from learning. I also found and fixed a gradient bias from rejection sampling (verified to 4.5e-10) and showed the real bottleneck was search coverage near the incumbent.
5. *Finding three: most of the flow is not needed to rank designs.* Across 1,752 routed designs in 15 benchmarks, a floorplan-stage timing estimate ranks designs with median Spearman 0.97. It still missed the most novel design, which a global-placement screen kept.
6. *Next.* In a tool-using agent eval (72 episodes, three Claude models), cheap verification and estimate tools raised the share of episodes that beat the baseline by more than the noise floor from 9 of 36 to 15 of 36, agents escaped a degenerate design grammar (popcount trees up to +2.020), and the eval exposed both a false-rejection bug in my formal checker and a placement noise floor that the agents were harvesting without knowing it. The natural next steps are multi-fidelity rewards inside the agent loop, harder tasks where formal needs datapath reasoning, and turning the environment into a training task suite.

**5-minute walkthrough.** Show, in order: `docs/figures/pipeline.png` (system), `reward_hacking_loose_spec.png` (why formal), `formal_scaling.png` (the verification fix), `rl_learning_vs_frozen.png` and `rl_search_coverage.png` (what RL did and did not do), `multifidelity_proxy.png` (latency lever), then the agent results. For a live version, run `python -m chiprl.demo`: a Claude-written priority encoder is simulated, proven equivalent, a buggy variant gets a counterexample trace, and the verified score comes back, in about a minute.

## 2. Numbers to remember

| Fact | Value |
|---|---|
| Designs taken RTL to GDS | 1,752 across 15 benchmark families and widths |
| Evaluation time per design | 23 s median: 4.2 s Verilator build and sim, 0.23 s formal, 18.7 s OpenROAD (8.3 s of it fixed overhead) |
| Reward | `10 * WNS_ns - 0.001 * area_um2`; 1 ps of slack = 10 um^2 of area |
| Clock, library | 10 ns, Nangate45 (open 45 nm), fixed floorplan per benchmark |
| Day-one reward hack | 5 of 10 random 8-bit designs violated the spec; each beat its correct twin (10 to 15% less area) |
| Lane-sum formal | monolithic: killed at 70 min; MiniSat, Glucose, CaDiCaL: no result in 120 s on a 12,347-variable CNF |
| Decomposed formal | 0.38 s per candidate + 5.0 s one-time certificate (47 links); 7/7 mutants rejected |
| Floorplan proxy | median Spearman 0.97 vs final score at 15% of flow time; true best kept in 14/15 benchmarks at 25% screening (global placement: 15/15) |
| Synthesis-area proxy | median Spearman 0.00 (useless for this timing-weighted reward) |
| v2 vs v1 on fresh adder widths | v2 improved 3/3, v1 0/3 (Claude structural 3/3 with larger gains) |
| Learning vs frozen (cross-family, 9 pairs) | 2 better, 2 worse, 5 tied, median 0 |
| Learning vs frozen (fresh widths, 6 pairs) | 6 tied; identical incumbent trajectories even though 21/96 actions differed |
| Gradient bias | 41 to 50% of initial probability on already-evaluated masks; corrected score mean 1e-16 vs 0.39 to 0.54 uncorrected |
| Missed neighbor | 192 RL proposals all 8+ flips from the best seed; the one-flip sweep found +0.0109 (replicated 3/3, holds in all 6 formats) |
| Claude autonomous adder | 16/16 valid; best: -12.6% area, -12.9% power, -4 ps slack vs prior champion |
| Lane-sum learned local edits | 0/15 runs beat the all-ADD seed; all 15 one-edit neighbors worse; learning effect 0 in 6/6 pairs |
| Agent eval | 72 episodes, 3 models, $65.54; beat the noise floor: 15 of 36 with all tools vs 9 of 36 with place-and-route only; best gains: comparator +0.281, priority +0.431, popcount +2.020; adder gains were null edits, and the Ling adder (+0.169) came from outside the grid |
| Throughput | 150 designs/h on one worker, 691/h with 16 workers on 22 threads (4.6x); 23.3 s median per evaluation, 36% fixed overhead |
| Noise floor | comment-only edits: 13 of 14 designs bit-identical, max spread 0.113, every ranking held; null edits with an identical netlist: -0.087 to +0.030 |

## 3. Deep-dive questions and answers

### Environment and reward

**Why this reward, and what is wrong with it?**
It is a simple scalarization of the two metrics the flow reports reliably: setup slack and standard-cell area. The weight makes 1 ps worth 10 um^2, so it is timing-dominated. Weaknesses: it is a proxy (no power model, fixed 10 ns clock so slack mostly reflects the input-to-register path under a 2 ns input delay budget, and small absolute differences); `fmax` from the flow is not validated so it is recorded but never optimized; and a scalar hides trade-offs, which is why every study also reports the area/WNS Pareto frontier.

**Why is WNS positive (about 7 ns)?**
The designs are small and the clock is 10 ns. The critical path runs from an input pin to the `y_o` register: 2 ns of input delay budget plus 0.07 ns clock latency, then the logic itself, which is only about 0.3 to 1.1 ns (1.07 ns for the lane-sum baseline, whose final report shows arrival 3.14 ns and slack 6.89 ns). So the reward measures how much slack a design leaves, which tracks logic depth.

**How do you stop an agent from gaming the reward?**
Layers: the testbench checks protocol details (hold on invalid cycles, reset, back-to-back); sequential equivalence against an independent reference rejects any functional difference at all; candidate hygiene rejects initial blocks, system tasks, directives and extra modules; the physical flow, floorplan and constraints are fixed so the agent can only change RTL; results are fingerprinted so a cached score cannot be reused for a different flow. In the agent environment `place_and_route` re-runs simulation and formal itself, so skipping the cheap checks cannot help. Two gaps got through anyway, and both are measured: interface rules that equivalence cannot see (an agent retimed logic past the output register) and placement noise on unchanged netlists. The fixes are a structural netlist check and a tie band at the noise floor.

**Why a fixed floorplan?**
So that only the RTL changes between candidates. With utilization-driven sizing, the die would change per design and area and wirelength comparisons would mix two effects. The cost: utilization is low (about 5%), so wires are short and the result is optimistic about routing congestion.

**How do you know results are reproducible?**
Evaluation IDs hash the RTL, testbench, reference, flow config, constraints, Docker image ID, ORFS commit and Verilator version. `SYNTH_REPEATABLE_BUILD=1` and a pinned container make the flow deterministic. Evidence: 3 uncached repeats of two designs were identical, and 32 designs re-run with 1, 2, 4, 8 and 16 parallel workers gave identical results for identical files. Deterministic is not the same as robust, though: the flow is not invariant to formatting, which I measured separately (next question). What is not tested: placement-seed variation, other tool versions and other PDKs.

**How much of a score is formatting?**
The flow is deterministic for identical files but not for reformatted ones: Yosys names internal objects after source lines, and the names set the order in which technology mapping and placement visit them. I re-evaluated 14 designs with 5 variants each that differ only in comments and blank lines. 13 were bit-identical in every variant; the all-CLA popcount tree moved in 4 of 5, by up to 0.113 (11 ps), and the one variant that shifts no line numbers (a trailing comment) synthesized to a byte-identical netlist, while the shifted ones gave the same 141 cells with swapped gate inputs and one gate resized, which supports the naming explanation. Every claimed ranking held in every format, even a +0.006 gain. Agents found a bigger version of this: null edits such as moving `a_i + b_i` into a named wire give the identical synthesized netlist (425 cells, same area), yet placement moved the score by -0.087 to +0.030. The eval analysis counts scores inside that band as ties.

**Logical queries vs physical evaluations?**
A logical query is one proposal charged to a method's budget. A physical evaluation is an actual EDA run. The cache lets two methods that propose the same design share one EDA run, so query budgets stay equal across methods while compute is saved. Cache hits are always reported separately.

### Formal verification

**What does the Yosys flow actually prove?**
`equiv_make` builds a combined module and inserts an `$equiv` cell for every pair of same-named signals, including outputs and registers. `equiv_simple` tries to prove each `$equiv` with SAT over its input cone, treating other `$equiv` cells as already-established equalities (cut points). `equiv_induct -seq 4` proves the rest by temporal induction. `equiv_status -assert` fails unless every cell is proven. Yosys documents the guarantee precisely: two designs that agree on all matched signals for 4 consecutive cycles never diverge afterward. The base case comes from the designs resetting their registers to the same values, which the testbench checks directly. So the claim is equivalence from reset, not from arbitrary states, and simulation is part of the argument rather than a separate check.

**Is proving with cut points sound?**
Yes, provided every cut point is itself proven. In a combinational cone the cut points form a DAG from inputs to outputs, so each proof assumes only equalities that are proven earlier in topological order; registers are handled by induction. A wrongly named signal cannot make a false claim pass: its `$equiv` cell fails and the whole check fails. The risk is only incompleteness (a correct design with misleading names fails).

**Why did the lane-sum proof blow up?**
The reference accumulates lanes one at a time; the candidate uses a balanced tree. No internal signal of one equals any internal signal of the other, so there are no cut points and SAT must reason about the whole 128-input adder network at once. Proving that two differently associated XOR-heavy adder networks are equal is a known hard case for CDCL solvers (the same reason multiplier equivalence is hard). I measured it: 12,347 variables, 33,797 clauses, and MiniSat, Glucose and CaDiCaL all failed to finish within 120 s.

**How does your decomposition work, and why is it trustworthy?**
Two parts. Per candidate, the candidate and the all-ADD tree share node names, so each node is its own small proof. Once per benchmark, I prove reference equals all-ADD tree through 46 intermediate designs, each differing from the last by one rewrite: an adjacent swap in the accumulation chain or a rotation `(A+B)+C -> A+(B+C)`. Naming every node by the set of lanes it sums makes all unchanged nodes cut points, so each link is a three-operand proof. Equivalence is transitive, so candidate equals reference. Trust comes from: the same Yosys commands as the original checker, a certificate that hashes every intermediate design and checks its endpoints against the frozen files, and tests where 7 realistic bugs and a corrupted rewrite step are all rejected.

**Why exact widths in the intermediate designs?**
Every node is wide enough for the largest possible sum of its lanes, so no link depends on modular wrap-around. The one place widths change (the reference's 12-bit accumulator) is proven directly and is easy because the association order matches.

**Limits?**
It only accelerates designs that expose the tree's node names. Arbitrary agent-written RTL falls back to the monolithic proof and times out (tested). Industrial equivalence checkers handle this with datapath extraction and arithmetic normalization; an SMT or algebraic rewriting layer would be the next step.

**Did formal ever catch something simulation missed?**
Yes, in the agent eval. One design dropped the reset on the `y_o` data register, a common area trick in real designs but a spec violation here. It passed the 10,000-transaction testbench, which does check reset values, because Verilator initializes registers to zero by default, so the unreset register looked reset. Formal flagged all 32 bits of `y_o`, and checker v2 produces the concrete trace. A second design used an asynchronous reset, which is not equivalent to the synchronous reference and was rejected. I confirmed it: the same compiled testbench passes by default and fails with `+verilator+rand+reset+2` ("y_o nonzero during reset"). The lesson: randomize initial state in simulation, and keep formal as the final gate because testbenches have blind spots you do not know about.

**Did formal ever reject a correct design?**
Also yes, twice for the same reason: Yosys 0.68's `proc` pass converts `case` lookup tables into ROMs, and `equiv_make` cannot analyze memories. With `proc -norom` the design proves in 0.28 s. Earlier, a correct hierarchical design failed because the checker never flattens. Both are fixed in checker v2; v1 stays frozen for comparability. An environment that rejects correct answers silently punishes good behavior, so false rejections matter as much as false accepts.

### Physical design

**Walk me through the flow.**
Yosys synthesis with ABC technology mapping to the Nangate45 library (adders map to full-adder and half-adder cells). Floorplan: fixed die and core, I/O pin placement, tap cells, power grid on metal 1, 4 and 7. Global placement (RePlAce), timing-driven repair (buffering and resizing), detailed placement (OpenDP), clock tree synthesis (TritonCTS), global routing (FastRoute), detailed routing (TritonRoute), fill, then parasitic extraction and final static timing and power with OpenSTA. The GDS is merged with KLayout.

**Why does a floorplan-stage estimate predict the final score so well?**
At floorplan time OpenSTA times the synthesized netlist with essentially ideal wires, so it captures logic depth and cell delays. In these small, low-utilization designs, placement and routing add small and fairly uniform wire delay and a few buffers, so the ranking barely changes. It is optimistic in absolute terms (cmp32 baseline: 7.69 ns estimated vs 7.62 ns final), so estimates should be compared with estimates. It is not a perfect selector. Its top design was the true best in only 5 of 15 benchmarks, and in one benchmark screening to its top 25% would have thrown away the true best: Opus's Ling adder ranked 40th of 116 at floorplan. At placement the baseline adder lost 91 ps of slack to wiring and the Ling adder only 53 ps, so the ranking flipped. A global-placement proxy (27% of tool time) kept the true best in every benchmark. The lesson: validate a proxy on the designs your optimizer actually produces, because novel designs are exactly where a proxy tuned on older designs fails.

**Why is synthesis area a bad proxy here?**
The reward is timing-dominated, and in several grammars faster designs are bigger, so synthesis area can even anti-correlate with the final score (Spearman -0.91 in the popcount tree, where the all-CLA design is both largest and best).

**Why did the plain `+` tree beat hand-written carry-lookahead in the lane sum?**
Because Yosys can see the whole all-`+` tree. Its `alumacc` pass merges it into one 16-operand `$macc` cell, which becomes a single carry-save compressor tree of full adders with one final carry-propagate adder, already the fast structure (I checked: one `$macc` cell for the all-ADD tree). A hand-written CLA node hides its addition from Yosys. At a leaf it puts about 80 gates of explicit carry logic in front of the compressor tree (315 ps less slack, 22 um^2 more area); at the root it only splits the tree into two `$macc` cells (17 ps). So the grammar's "local" choice is not local after synthesis.

**What is in "area"?**
Total standard-cell area after routing: logic, flip-flops, clock buffers, timing-repair buffers and tap cells. Filler cells are excluded. Tap cells are constant within a benchmark, so they shift all scores equally.

### Reinforcement learning

**How is the problem formulated?**
As a budgeted sequential design problem: each episode has 16 queries; an action is a complete design (a mask); the state is the history of evaluated designs; the step reward is the improvement of the best-so-far score, so the return is final best minus seed best. Duplicates are rejected before any EDA and cost nothing. It is closer to a bandit or black-box optimization problem than to a long-horizon MDP.

**Why REINFORCE and not PPO?**
Each query costs about 23 s of EDA and budgets are 16 queries per run. With so few samples, a simple score-function estimator with a moving baseline and clipped advantages is easier to audit and replay exactly. The research question was whether any online learning signal helps at this budget, not which optimizer is best.

**What is v2 and why did it beat v1 on adders?**
v1 treats each mask bit as an independent Bernoulli, so its expected number of boundaries is large and good designs (few boundaries) are rare. v2 first samples the boundary count K, then K ordered positions. Good adder designs have one to three boundaries, and v2's seed-based initialization put most mass on small K. That representation, not learning, explains the gap, which the frozen-policy controls later confirmed.

**Explain the gradient bug.**
v2 resamples until it draws a mask it has not evaluated. So the actual proposal distribution is `q(m) = p(m) / (1 - P(S))` over unseen masks. The code used `grad log p(m)`. The right score is `grad log q(m) = grad log p(m) + sum_{s in S} p(s) grad log p(s) / (1 - P(S))`. The extra term matters when much of the mass is on seen masks, which was 41 to 50% at the start. Test: a correct score has zero mean under its own distribution; on exhaustively enumerated small mask spaces the corrected version has mean 1e-16 and the old one does not. v3 uses the corrected score; the clearest behavioral sign is that v3 stops pushing down the logit of a category it can never sample.

**Did the fix improve results?**
No. On the popcount-tree study no method beat the best seed. The fix changed learning dynamics as predicted, but the limiting factor was coverage: every one of 192 proposals was at least 8 flips away from the best seed, and a one-flip sweep then found a better design right next to it.

**Why were learning and frozen hybrids identical in the fresh-width study?**
The hybrid alternated global policy samples with local one-flip edits of the current best. The local edits found the improvements; the global policy, with only 8 updates per run, changed which designs it proposed (21 of 96 actions differed) but none of those changed the incumbent. So updates were real but not useful at that budget.

**What did the learned local-edit study show?**
Nothing could differ. No run beat the all-ADD seed because all 15 of its one-edit neighbors are worse (measured), so learned and uniform local search tied exactly. The cause is synthesis: Yosys merges an all-`+` tree into one 16-operand `$macc` (a carry-save compressor tree with one final adder), and any hand-written CLA node hides an addition from it. A leaf CLA costs 315 ps of slack; a root CLA, which just splits the tree into two `$macc` cells, costs 17 ps. The lesson for environment design: an action space that looks local in RTL can be global after synthesis, so check the landscape before asking a learner to exploit it.

**So does RL work here?**
What I can defend: representation and exploration mattered much more than online learning at 16-query budgets, and the controls are the reason I know that. I would expect learning to matter with larger budgets, many tasks sharing one policy, or a model prior (an LLM) instead of a tabular policy.

### Agents

**How is the agent environment designed?**
Four tools with realistic costs: simulate (4 s), prove_equivalence (1 s), estimate_ppa (6 s, floorplan-stage proxy), place_and_route (23 s, budget of 4, re-verifies, failures still count). The score is the best verified place-and-route result. Two conditions separate the value of cheap tools: full tools vs place_and_route only.

**What happened?**
72 preregistered episodes, all complete ($65.54 of API usage). Four findings. (1) Cheap tools help the weaker models most: 15 of 36 episodes with all tools beat the noise floor against 9 of 36 with place-and-route only (paired: 12 better with tools, 5 worse, 19 tied); for Haiku and Sonnet it was 7/24 vs 1/24, while Opus reached 8/12 either way. (2) Agents escape grammar limits: on popcount32, where the old structural grammar had collapsed to 3 physical outcomes, Opus wrote registered popcount trees up to +2.020 and Sonnet and Haiku wrote counter trees (+1.196, +1.119); Opus's comparator reached +0.281 and Sonnet's priority encoder +0.431. (3) Styles differ: Sonnet stops early and locks in the baseline, Haiku spends the whole budget and can end below baseline, Opus calibrates the reward first and costs the most. (4) Verification cut both ways: formal caught a missing reset that passed simulation, and wrongly rejected a correct lookup-table design (fixed in checker v2).

**Did the agents game the environment?**
Twice, and neither time by breaking verification. The subtle one is the noise floor: on the 32-bit adder, Haiku and Opus submitted designs whose synthesized netlist is identical to the baseline's (the sum moved into a named wire) and scored up to +0.030 from placement differences alone. It was not deliberate: Opus wrote that the native `+` mapping was already at the depth limit and submitted it, and the score simply came back higher. A post-hoc outcome that treats scores inside the null-edit band (-0.087 and +0.030) as ties cut Haiku's improvements from 11 of 24 to 2.

The deliberate one is a hole in the spec. Every task is a registered block, but the checkers prove only cycle equivalence. In one popcount episode Opus checked that the equivalence checker accepts a different state encoding, then moved half of the logic past the output register, balancing the input and output paths. The design is correct (checker v2 proves it and a bounded check from reset finds no mismatch in 16 cycles) and meets every constraint, and it scored +5.008, about 2.5 times the best registered design. But its output is no longer a flip-flop, so in a real chip the next block inherits the delay. Its two submissions are the only ones of 227 with unregistered outputs. The protocol counts it; the fix is a netlist check that every output bit is a flip-flop output, which the analysis now runs. The lesson for RL environments: the most capable policy optimizes the checker, not the intent, so every unstated rule is a future exploit.

**What was distinctive about Opus?**
Calibration. In all 12 of its all-tools episodes it first estimated a deliberately logic-free design (for example `y_o <= a_i`) to find the best slack any design could reach, concluded how much logic delay was actually in play (about 0.2 to 0.3 ns), and only then searched. Haiku and Sonnet never did this. It is legitimate because estimates are not rewards, but it shows that any tool accepting unverified designs leaks information about the reward function, which matters when designing a training environment. It also costs the most: $2.96 per all-tools episode against $0.32 for Sonnet.

**What is the most impressive thing an agent did?**
Two designs by Opus 5. A Ling adder (prefix tree over pseudo-carries built from generate and transmit signals) where the output-hold multiplexer is folded into two early sum candidates, so the late carry drives a single mux level: the best 32-bit adder in the project (+0.169 against +0.131 for all prior search). It came from a first attempt at one episode that stopped early and was rerun, so it is shown separately from the scored grid. And two popcounts that beat the best design of a grammar built specifically for popcount trees (+1.587): a Wallace tree of full-adder compressors (+1.685) and a bit-sliced tree that counts all eight nibbles at once as 8-bit vectors and uses each level's known maximum to replace carry logic (+2.020), written without the cheap tools. Both are how a human datapath designer would attack the problem.

**What would you change in the agent environment next?**
Use checker v2 (counterexamples as feedback, no false rejections on lookup tables or hierarchy), randomize initial register state in simulation, canonicalize RTL or score only gains beyond the measured noise floor so null edits earn nothing, estimate at the placement stage rather than floorplan, and reward verified improvement per unit of EDA cost so an agent learns to stop early like Sonnet instead of spending budget blindly like Haiku.

**What did the pilot teach you?**
The frozen formal checker does not flatten hierarchy, so a correct design with a helper module failed equivalence. I made the environment require one flat module rather than silently changing the frozen checker.

**How would you turn this into a training environment?**
Task suite: many modules and interfaces with references and testbenches, including harder datapaths. Reward: verified improvement over a baseline, zero for anything unverified, optionally a small shaping term from cheap proxies. Throughput: parallel workers, caching, proxy-first screening so only promising designs reach full routing. Safety: hygiene checks, fixed flows, and holding out tasks and references so a model cannot memorize them.

### Scaling this into a training environment

**What would you change to train a model on this environment, not just evaluate it?**
Four things. (1) A much larger task suite: many interfaces and functions (arithmetic, control, FSMs, FIFOs, protocol blocks), each with a reference model, a testbench and a formal harness, plus held-out tasks. (2) An asynchronous evaluation service: rollouts submit RTL, a pool of containerized EDA workers returns rewards, with the content-addressed cache shared across rollouts. (3) A multi-fidelity reward: cheap verification for every candidate, a placement-stage estimate as the screen, and full place-and-route only for candidates that pass it, with the screen re-validated on the policy's own designs (a floorplan screen missed the most novel design here). (4) Monitoring for reward hacking: track designs that pass simulation but fail formal, and sample transcripts for attempts to exploit the harness.

**How would you shape the reward?**
Keep the gate strict: anything unverified earns the failure reward, never partial credit, because partial credit for "almost correct" is exactly what an optimizer exploits. Put rich diagnostics (failing vector, unproven signals, timing report) in the observation instead of the reward. Reward verified improvement over a baseline so the scale is comparable across tasks, and consider rewarding Pareto improvements rather than one fixed weighting.

**What if a task has no reference RTL?**
Use a reference model in software driven through the testbench, SystemVerilog assertions checked by bounded model checking for protocol properties, and equivalence only where a trusted reference exists. A model-written reference is itself a hacking surface, so references should come from a separate, trusted source.

**How do you handle EDA nondeterminism at scale?**
Pin the container and tool versions, use repeatable-build flags, and include tool versions in the cache key, as here. Then measure the noise floor instead of assuming it is zero: here null edits moved scores by -0.087 to +0.030, and agents found that on their own. For robustness, canonicalize RTL before scoring (strip comments, normalize names) or score each design over a few formatting variants or placement seeds and use the median or worst case, which costs more but stops a policy from overfitting one lucky layout.

**Would results on Nangate45 transfer to an advanced node?**
Relative logic-depth effects mostly transfer; wire delay, congestion and variation matter much more at advanced nodes and at realistic utilization, so the floorplan proxy would probably lose fidelity there. The method (measure proxy fidelity per stage and per task before trusting it) transfers even if the numbers do not.

### EDA latency

**Where does evaluation time go?**
Median 23.3 s per design on one worker: 4.2 s to build and run the 10,000-transaction Verilator testbench, 0.23 s of formal, 18.7 s in the OpenROAD flow. Only 10.3 s of the flow is tool time in the stage logs; the other 8.3 s is overhead, because each evaluation starts a container and each stage starts a new tool process that reloads the libraries and the design. The largest tool share is detailed routing plus fill, GDS merge and reports (4.8 s). Formal is about 1% of the total.

**How would you get to thousands of evaluations per hour?**
Parallel workers with per-design locks (691 designs per hour with 16 workers, 4.6x one worker), multi-fidelity screening (about 2.2x fewer tool-seconds when screening after global placement, which kept the true best in every benchmark), caching of identical designs, and removing fixed overhead per run (container start, flow setup, final GDS merge and report images are a large share of wall time for small designs).

### Research process

**Why preregister experiments for a personal project?**
Because the search space and the analysis choices are large enough to fool myself. Freezing methods, seeds, budgets and metrics before measuring, and recording pre-measurement fixes as amendments, is what makes the negative results believable and the positive ones worth something.

**What mistakes did you make?**
A loose testbench (reward hack); overlapping random-number streams across methods (caught before search); an evaluator CLI that missed a new benchmark; the biased gradient; a degenerate popcount grammar (142 masks, 3 physical outcomes); a formal checker that did not scale; a formal checker that cannot see through hierarchy or ROMs; counting sub-noise agent gains as improvements until I measured the noise floor; and trusting a proxy validated on grammar designs until it misranked a novel one. Each one is documented with the fix and when it was caught.

## 4. Honest limitations

- Open 45 nm library and OpenROAD, not commercial tools or a production PDK. No tapeout.
- Small blocks (tens to a thousand cells) at low utilization and a relaxed 10 ns clock.
- The reward is a proxy: no switching-activity power, no multi-corner timing, no DRC/LVS signoff beyond what the open flow reports.
- RL studies use 3 random seeds per condition and 16-query budgets: good for detecting large effects and for falsifying claims, not for small effects.
- The decomposed proof covers tree-structured candidates only.
- Scores carry a formatting and naming noise floor (up to about 0.1 here); small gains need the variant check before they count.
- The checkers prove cycle equivalence only. Interface rules such as registered outputs need their own structural check; one agent design exploited that gap.

## 5. Glossary

| Term | Meaning |
|---|---|
| WNS / TNS | Worst / total negative slack. Here WNS is the worst setup slack, positive when timing is met |
| CTS | Clock tree synthesis |
| PDN | Power delivery network (the metal 1/4/7 power grid) |
| CLA | Carry-lookahead: carries computed from generate `g = a & b` and propagate `p = a ^ b` terms |
| Sklansky, Kogge-Stone, Brent-Kung | Parallel-prefix adder networks trading depth, fan-out and wiring |
| Carry-select | Compute a block's sum for both carry-in values and select |
| Cut point | An internal signal proven equal in both designs and then assumed equal to split a proof |
| REINFORCE | Policy gradient `E[(R - b) grad log pi(a)]` with a baseline `b` |
| Frozen control | The same policy with updates disabled; isolates the effect of learning |
| Diversity gate | Preregistered check that a design grammar produces physically different designs |
