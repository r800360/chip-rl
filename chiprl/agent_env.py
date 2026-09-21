from __future__ import annotations

import contextlib
import hashlib
import io
import json
import re
from pathlib import Path
from typing import Any

from chiprl.benchmarks import ROOT, get_benchmark
from chiprl.evaluate import evaluate


BENCHMARK_NAME = "addpipe16"

BASELINE_DATA = (
    ROOT
    / "results"
    / "addpipe16_extended"
    / "results.json"
)

RUN_ROOT = (
    ROOT
    / "results"
    / "agent_runs"
)

RTL_ROOT = (
    ROOT
    / "rtl"
    / "agent"
)


def sha256_text(text: str) -> str:
    return hashlib.sha256(
        text.encode()
    ).hexdigest()


def sanitize_name(name: str) -> str:
    name = re.sub(
        r"[^A-Za-z0-9_.-]+",
        "_",
        name.strip(),
    )

    name = name.strip("._")

    if not name:
        name = "candidate"

    return name[:80]


def dominates(a, b) -> bool:
    return (
        a["area"] <= b["area"]
        and a["wns"] >= b["wns"]
        and (
            a["area"] < b["area"]
            or
            a["wns"] > b["wns"]
        )
    )


def pareto_front(rows):
    valid = [
        r
        for r in rows
        if (
            r.get("functional")
            and r.get("formal_ok")
            and r.get("place_route_ok")
            and r.get("area") is not None
            and r.get("wns") is not None
        )
    ]

    return sorted(
        [
            r
            for r in valid
            if not any(
                dominates(other, r)
                for other in valid
                if other is not r
            )
        ],
        key=lambda r: (
            r["area"],
            -r["wns"],
        ),
    )


def label(row):
    if row.get("agent_name"):
        return row["agent_name"]

    if row.get("proposal_name"):
        return row["proposal_name"]

    if row.get("blocks") is not None:
        return str(tuple(row["blocks"]))

    return row.get(
        "candidate",
        "unknown",
    )


class Addpipe16AgentEnv:
    """
    Hardware-design environment.

    Every submitted RTL proposal consumes one attempt,
    including duplicates and incorrect designs.

    A proposal reaches OpenROAD only after:
        simulation PASS
        formal equivalence PASS
    """

    def __init__(
        self,
        *,
        run_id: str,
        budget: int = 16,
    ):
        self.run_id = sanitize_name(run_id)
        self.budget = int(budget)

        if self.budget <= 0:
            raise ValueError(
                "budget must be positive"
            )

        self.benchmark = get_benchmark(
            BENCHMARK_NAME
        )

        self.run_dir = (
            RUN_ROOT
            / self.run_id
        )

        self.rtl_dir = (
            RTL_ROOT
            / self.run_id
        )

        self.run_dir.mkdir(
            parents=True,
            exist_ok=True,
        )

        self.rtl_dir.mkdir(
            parents=True,
            exist_ok=True,
        )

        self.state_path = (
            self.run_dir
            / "state.json"
        )

        self.baseline_rows = json.loads(
            BASELINE_DATA.read_text()
        )

        self.reference_rtl = (
            self.benchmark.reference.read_text()
        )

        self.state = self._load_state()

        self.preexisting_hashes = (
            self._scan_existing_rtl_hashes()
        )

        # Do not classify candidates already belonging
        # to this run as preexisting when resuming.
        for attempt in self.state["attempts"]:
            source_hash = attempt.get(
                "source_sha256"
            )

            if source_hash:
                self.preexisting_hashes.discard(
                    source_hash
                )

    def _load_state(self):
        if self.state_path.is_file():
            state = json.loads(
                self.state_path.read_text()
            )

            if state["budget"] != self.budget:
                raise RuntimeError(
                    "Existing run uses budget "
                    f"{state['budget']}, requested "
                    f"{self.budget}"
                )

            return state

        state = {
            "run_id": self.run_id,
            "benchmark": BENCHMARK_NAME,
            "budget": self.budget,
            "attempts": [],
        }

        self._save_state(state)

        return state

    def _save_state(
        self,
        state=None,
    ):
        if state is None:
            state = self.state

        self.state_path.write_text(
            json.dumps(
                state,
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )

    def _scan_existing_rtl_hashes(self):
        """
        Hash the frozen pre-agent RTL corpus.

        Previous autonomous-agent runs are deliberately
        excluded so integration tests or earlier model runs
        cannot contaminate a new experiment's starting state.
        """
        hashes = set()

        rtl_root = ROOT / "rtl"
        agent_root = rtl_root / "agent"

        for path in rtl_root.rglob("*.v"):
            # rtl/agent contains outputs of previous agent
            # experiments, not the frozen baseline corpus.
            if agent_root in path.parents:
                continue

            try:
                hashes.add(
                    sha256_text(
                        path.read_text()
                    )
                )
            except OSError:
                pass

        return hashes

    @property
    def attempts_used(self):
        return len(
            self.state["attempts"]
        )

    @property
    def attempts_remaining(self):
        return max(
            0,
            self.budget
            - self.attempts_used,
        )

    @property
    def done(self):
        return (
            self.attempts_used
            >= self.budget
        )

    def successful_agent_rows(self):
        rows = []

        for attempt in self.state["attempts"]:
            result = attempt.get("result")

            if (
                isinstance(result, dict)
                and result.get("functional")
                and result.get("formal_ok")
                and result.get("place_route_ok")
            ):
                rows.append(result)

        return rows

    def all_successful_rows(self):
        return (
            list(self.baseline_rows)
            + self.successful_agent_rows()
        )

    def current_frontier(self):
        return pareto_front(
            self.all_successful_rows()
        )

    def current_bests(self):
        rows = self.all_successful_rows()

        return {
            "best_proxy_reward": max(
                rows,
                key=lambda r:
                    r["proxy_reward_v0"],
            ),

            "minimum_area": min(
                rows,
                key=lambda r:
                    r["area"],
            ),

            "best_wns": max(
                rows,
                key=lambda r:
                    r["wns"],
            ),

            "minimum_reported_power": min(
                rows,
                key=lambda r:
                    r["power_w"],
            ),
        }

    def _compact_result(self, result):
        if result is None:
            return None

        return {
            "candidate":
                result.get("candidate"),

            "functional":
                result.get("functional"),

            "formal_ok":
                result.get("formal_ok"),

            "place_route_ok":
                result.get("place_route_ok"),

            "cells":
                result.get("cells"),

            "area":
                result.get("area"),

            "wns":
                result.get("wns"),

            "tns":
                result.get("tns"),

            "power_w":
                result.get("power_w"),

            "proxy_reward_v0":
                result.get(
                    "proxy_reward_v0"
                ),

            "runtime_s":
                result.get("runtime_s"),
        }

    def observe(self) -> dict[str, Any]:
        bests = self.current_bests()

        frontier = [
            {
                "label": label(row),
                "area": row["area"],
                "wns": row["wns"],
                "power_w": row["power_w"],
                "proxy_reward_v0":
                    row["proxy_reward_v0"],
            }
            for row in self.current_frontier()
        ]

        previous = []

        # API calls are stateless, so provide the model with
        # the source of its previous proposals. This allows it
        # to repair formal/simulation failures and make genuine
        # RTL-level revisions rather than relying on names and
        # rationales alone.
        for attempt in self.state["attempts"]:
            attempt_index = attempt["attempt_index"]

            rtl_path = (
                self.run_dir
                / f"attempt_{attempt_index:03d}"
                / "candidate.v"
            )

            try:
                previous_rtl = rtl_path.read_text()
            except OSError:
                previous_rtl = ""

            previous.append({
                "attempt_index":
                    attempt_index,

                "name":
                    attempt["name"],

                "rationale":
                    attempt["rationale"],

                "status":
                    attempt["status"],

                "result":
                    self._compact_result(
                        attempt.get("result")
                    ),

                "feedback_tail":
                    attempt.get(
                        "feedback_tail",
                        "",
                    ),

                "rtl":
                    previous_rtl,
            })

        def compact_best(row):
            return {
                "label": label(row),
                "area": row["area"],
                "wns": row["wns"],
                "power_w": row["power_w"],
                "proxy_reward_v0":
                    row["proxy_reward_v0"],
            }

        return {
            "task": (
                "Design functionally equivalent "
                "addpipe16 RTL with improved "
                "physical QoR."
            ),

            "attempt_budget": self.budget,
            "attempts_used":
                self.attempts_used,
            "attempts_remaining":
                self.attempts_remaining,

            "objective": {
                "proxy_reward_v0":
                    "-0.001 * area + 10 * WNS",

                "multiobjective":
                    (
                        "Also seek non-dominated "
                        "area/WNS designs and lower "
                        "reported power."
                    ),

                "warning":
                    (
                        "Do not optimize fmax_hz; "
                        "that metric has not been "
                        "validated."
                    ),
            },

            "correctness_contract": {
                "top_module":
                    "addpipe16",

                "reference_rtl":
                    self.reference_rtl,

                "requirements": [
                    "Preserve exact sequential behavior.",
                    "valid_o must match the reference.",
                    "y_o must hold when valid_i is low.",
                    "Reset behavior must match exactly.",
                    "Use synthesizable Verilog in one file.",
                    "Do not instantiate unavailable technology-specific cells."
                ],
            },

            "fixed_environment": {
                "technology":
                    "Nangate45",

                "clock_period_ns":
                    10.0,

                "correctness_pipeline":
                    (
                        "Verilator simulation -> "
                        "Yosys sequential formal "
                        "equivalence -> OpenROAD"
                    ),
            },

            "current_bests": {
                key: compact_best(value)
                for key, value
                in bests.items()
            },

            "observed_frontier":
                frontier,

            "recent_attempts":
                previous,

            "required_response": {
                "format":
                    "JSON only",

                "schema": {
                    "name":
                        "short candidate name",

                    "rationale":
                        (
                            "why this RTL may improve "
                            "on previous observations"
                        ),

                    "rtl":
                        (
                            "complete Verilog source "
                            "containing module addpipe16"
                        ),
                },
            },
        }

    def step(
        self,
        proposal: dict[str, Any],
    ) -> dict[str, Any]:
        if self.done:
            raise RuntimeError(
                "Agent budget exhausted"
            )

        attempt_index = self.attempts_used

        try:
            name = sanitize_name(
                str(proposal["name"])
            )

            rationale = str(
                proposal["rationale"]
            ).strip()

            rtl = str(
                proposal["rtl"]
            )

        except KeyError as exc:
            raise ValueError(
                "Proposal requires name, "
                "rationale, and rtl"
            ) from exc

        source_hash = sha256_text(rtl)

        attempt_dir = (
            self.run_dir
            / f"attempt_{attempt_index:03d}"
        )

        attempt_dir.mkdir(
            parents=True,
            exist_ok=True,
        )

        (
            attempt_dir
            / "proposal.json"
        ).write_text(
            json.dumps(
                {
                    "name": name,
                    "rationale": rationale,
                    "source_sha256":
                        source_hash,
                },
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )

        (
            attempt_dir
            / "candidate.v"
        ).write_text(rtl)

        run_hashes = {
            a["source_sha256"]
            for a in self.state["attempts"]
            if a.get("source_sha256")
        }

        duplicate = (
            source_hash
            in self.preexisting_hashes
            or source_hash
            in run_hashes
        )

        if duplicate:
            record = {
                "attempt_index":
                    attempt_index,

                "name":
                    name,

                "rationale":
                    rationale,

                "source_sha256":
                    source_hash,

                "status":
                    "duplicate_source",

                "result":
                    None,

                "feedback_tail":
                    (
                        "Rejected before evaluation: "
                        "exact RTL source hash was "
                        "already present."
                    ),
            }

            self.state[
                "attempts"
            ].append(record)

            self._save_state()

            return record

        candidate_path = (
            self.rtl_dir
            / (
                f"attempt_{attempt_index:03d}_"
                f"{name}.v"
            )
        )

        candidate_path.write_text(rtl)

        captured = io.StringIO()

        with contextlib.redirect_stdout(
            captured
        ):
            result = evaluate(
                candidate_path.relative_to(
                    ROOT
                ),
                benchmark=BENCHMARK_NAME,
            )

        console = captured.getvalue()

        feedback_tail = "\n".join(
            console.splitlines()[-80:]
        )

        if not result["functional"]:
            status = "simulation_failed"

        elif not result["formal_ok"]:
            status = "formal_failed"

        elif not result["place_route_ok"]:
            status = "physical_failed"

        else:
            status = "success"

        result = dict(result)

        result["agent_name"] = name
        result["agent_rationale"] = (
            rationale
        )

        record = {
            "attempt_index":
                attempt_index,

            "name":
                name,

            "rationale":
                rationale,

            "source_sha256":
                source_hash,

            "status":
                status,

            "result":
                result,

            "feedback_tail":
                feedback_tail,
        }

        self.state[
            "attempts"
        ].append(record)

        self._save_state()

        (
            attempt_dir
            / "result.json"
        ).write_text(
            json.dumps(
                record,
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )

        return record
