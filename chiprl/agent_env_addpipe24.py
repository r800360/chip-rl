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


BENCHMARK_NAME = "addpipe24"

SEED_DATA = (
    ROOT
    / "results"
    / "addpipe24_shared_seed"
    / "results.json"
)

RUN_ROOT = (
    ROOT
    / "results"
    / "agent_runs"
    / "addpipe24"
)

RTL_ROOT = (
    ROOT
    / "rtl"
    / "agent"
    / "addpipe24"
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

    return (
        name[:80]
        if name
        else "candidate"
    )


def dominates(a, b) -> bool:
    return (
        a["area"] <= b["area"]
        and a["wns"] >= b["wns"]
        and (
            a["area"] < b["area"]
            or a["wns"] > b["wns"]
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


def row_label(row):
    if row.get("agent_name"):
        return row["agent_name"]

    if row.get("mask"):
        return row["mask"]

    if row.get("blocks") is not None:
        return str(tuple(row["blocks"]))

    return row.get(
        "candidate",
        "unknown",
    )


class Addpipe24OpenRTLAgentEnv:
    """
    Unrestricted addpipe24 RTL-search environment.

    Important experimental isolation:
      * baseline knowledge = frozen eight shared seeds only
      * random/evolution/structural-Claude results are never loaded
      * addpipe16 results are never loaded
      * the agent sees only its own subsequent trajectory
    """

    def __init__(
        self,
        *,
        run_id: str,
        budget: int = 16,
    ):
        self.run_id = sanitize_name(
            run_id
        )

        self.budget = int(
            budget
        )

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

        self.seed_rows = json.loads(
            SEED_DATA.read_text()
        )

        if len(self.seed_rows) != 8:
            raise RuntimeError(
                "Expected exactly 8 frozen seed rows"
            )

        self.reference_rtl = (
            self.benchmark.reference.read_text()
        )

        self.state = (
            self._load_state()
        )

        self.seed_source_hashes = (
            self._seed_source_hashes()
        )

    def _load_state(self):
        if self.state_path.is_file():
            state = json.loads(
                self.state_path.read_text()
            )

            if (
                state["budget"]
                != self.budget
            ):
                raise RuntimeError(
                    "Existing run budget differs "
                    "from requested budget"
                )

            return state

        state = {
            "run_id":
                self.run_id,

            "benchmark":
                BENCHMARK_NAME,

            "budget":
                self.budget,

            "attempts":
                [],
        }

        self._save_state(
            state
        )

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

    def _seed_source_hashes(self):
        """
        Duplicate baseline consists ONLY of the
        frozen eight shared-seed RTL sources.

        Previous agent runs and controlled-search
        RTL are deliberately excluded.
        """
        hashes = set()

        for row in self.seed_rows:
            candidate = row.get(
                "candidate"
            )

            if not candidate:
                continue

            path = ROOT / candidate

            if path.is_file():
                hashes.add(
                    sha256_text(
                        path.read_text()
                    )
                )

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

        for attempt in self.state[
            "attempts"
        ]:
            result = attempt.get(
                "result"
            )

            if (
                isinstance(
                    result,
                    dict,
                )
                and result.get(
                    "functional"
                )
                and result.get(
                    "formal_ok"
                )
                and result.get(
                    "place_route_ok"
                )
            ):
                rows.append(
                    result
                )

        return rows

    def all_successful_rows(self):
        return (
            list(
                self.seed_rows
            )
            + self.successful_agent_rows()
        )

    def current_frontier(self):
        return pareto_front(
            self.all_successful_rows()
        )

    def current_bests(self):
        rows = (
            self.all_successful_rows()
        )

        return {
            "best_proxy_reward":
                max(
                    rows,
                    key=lambda r:
                        r[
                            "proxy_reward_v0"
                        ],
                ),

            "minimum_area":
                min(
                    rows,
                    key=lambda r:
                        r["area"],
                ),

            "best_wns":
                max(
                    rows,
                    key=lambda r:
                        r["wns"],
                ),

            "minimum_reported_power":
                min(
                    rows,
                    key=lambda r:
                        r["power_w"],
                ),
        }

    def _compact_result(
        self,
        result,
    ):
        if result is None:
            return None

        return {
            "candidate":
                result.get(
                    "candidate"
                ),

            "functional":
                result.get(
                    "functional"
                ),

            "formal_ok":
                result.get(
                    "formal_ok"
                ),

            "place_route_ok":
                result.get(
                    "place_route_ok"
                ),

            "cells":
                result.get(
                    "cells"
                ),

            "area":
                result.get(
                    "area"
                ),

            "wns":
                result.get(
                    "wns"
                ),

            "power_w":
                result.get(
                    "power_w"
                ),

            "proxy_reward_v0":
                result.get(
                    "proxy_reward_v0"
                ),

            "runtime_s":
                result.get(
                    "runtime_s"
                ),
        }

    def _compact_seed(
        self,
        row,
    ):
        return {
            "mask":
                row["mask"],

            "blocks":
                row["blocks"],

            "cells":
                row["cells"],

            "area":
                row["area"],

            "wns":
                row["wns"],

            "power_w":
                row["power_w"],

            "proxy_reward_v0":
                row[
                    "proxy_reward_v0"
                ],
        }

    def observe(
        self,
    ) -> dict[str, Any]:
        bests = (
            self.current_bests()
        )

        previous = []

        for attempt in self.state[
            "attempts"
        ]:
            index = attempt[
                "attempt_index"
            ]

            source_path = (
                self.run_dir
                / f"attempt_{index:03d}"
                / "candidate.v"
            )

            try:
                previous_rtl = (
                    source_path.read_text()
                )
            except OSError:
                previous_rtl = ""

            previous.append({
                "attempt_index":
                    index,

                "name":
                    attempt["name"],

                "rationale":
                    attempt[
                        "rationale"
                    ],

                "status":
                    attempt["status"],

                "result":
                    self._compact_result(
                        attempt.get(
                            "result"
                        )
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
                "label":
                    row_label(row),

                "area":
                    row["area"],

                "wns":
                    row["wns"],

                "power_w":
                    row["power_w"],

                "proxy_reward_v0":
                    row[
                        "proxy_reward_v0"
                    ],
            }

        return {
            "experiment":
                "addpipe24 unrestricted RTL search",

            "isolation_notice":
                (
                    "The only pre-search physical "
                    "measurements supplied are the "
                    "eight frozen shared seeds below. "
                    "No random, evolution, previous "
                    "Claude structural-search, or "
                    "addpipe16 search results are "
                    "available to you."
                ),

            "task":
                (
                    "Design arbitrary synthesizable "
                    "Verilog implementing addpipe24 "
                    "while improving physical QoR."
                ),

            "attempt_budget":
                self.budget,

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
                        "fmax_hz is not a validated "
                        "objective and must not be "
                        "optimized."
                    ),
            },

            "correctness_contract": {
                "top_module":
                    "addpipe24",

                "reference_rtl":
                    self.reference_rtl,

                "requirements": [
                    "Preserve exact sequential behavior.",
                    "valid_o must match the reference.",
                    "y_o must hold when valid_i is low.",
                    "Reset behavior must match exactly.",
                    "Use synthesizable single-file Verilog.",
                    "Do not instantiate unavailable or technology-specific cells."
                ],
            },

            "fixed_environment": {
                "technology":
                    "Nangate45",

                "clock_period_ns":
                    10.0,

                "correctness_pipeline":
                    (
                        "Verilator -> Yosys sequential "
                        "formal equivalence -> OpenROAD"
                    ),
            },

            "frozen_shared_seed_measurements": [
                self._compact_seed(
                    row
                )
                for row in self.seed_rows
            ],

            "current_bests": {
                key:
                    compact_best(
                        value
                    )
                for key, value
                in bests.items()
            },

            "observed_frontier": [
                compact_best(
                    row
                )
                for row
                in self.current_frontier()
            ],

            "own_previous_attempts":
                previous,

            "required_response": {
                "format":
                    "JSON only",

                "schema": {
                    "name":
                        "short candidate name",

                    "rationale":
                        (
                            "brief technical hypothesis "
                            "based only on supplied "
                            "observations"
                        ),

                    "rtl":
                        (
                            "complete synthesizable "
                            "Verilog containing module "
                            "addpipe24"
                        ),
                },
            },
        }

    def step(
        self,
        proposal: dict[str, Any],
    ):
        if self.done:
            raise RuntimeError(
                "Agent budget exhausted"
            )

        attempt_index = (
            self.attempts_used
        )

        try:
            name = sanitize_name(
                str(
                    proposal["name"]
                )
            )

            rationale = str(
                proposal[
                    "rationale"
                ]
            ).strip()

            rtl = str(
                proposal["rtl"]
            )

        except KeyError as exc:
            raise ValueError(
                "Proposal requires name, "
                "rationale, and rtl"
            ) from exc

        source_hash = (
            sha256_text(rtl)
        )

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
                    "name":
                        name,

                    "rationale":
                        rationale,

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
        ).write_text(
            rtl
        )

        own_hashes = {
            a["source_sha256"]
            for a
            in self.state[
                "attempts"
            ]
            if a.get(
                "source_sha256"
            )
        }

        duplicate = (
            source_hash
            in self.seed_source_hashes
            or source_hash
            in own_hashes
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
                        "Rejected before EDA: exact "
                        "source hash duplicates a "
                        "shared seed or this run's "
                        "previous proposal."
                    ),
            }

            self.state[
                "attempts"
            ].append(
                record
            )

            self._save_state()

            return record

        candidate_path = (
            self.rtl_dir
            / (
                f"attempt_{attempt_index:03d}_"
                f"{name}.v"
            )
        )

        candidate_path.write_text(
            rtl
        )

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

        console = (
            captured.getvalue()
        )

        feedback_tail = "\n".join(
            console.splitlines()[-80:]
        )

        if not result[
            "functional"
        ]:
            status = (
                "simulation_failed"
            )

        elif not result[
            "formal_ok"
        ]:
            status = (
                "formal_failed"
            )

        elif not result[
            "place_route_ok"
        ]:
            status = (
                "physical_failed"
            )

        else:
            status = "success"

        result = dict(
            result
        )

        result[
            "agent_name"
        ] = name

        result[
            "agent_rationale"
        ] = rationale

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
        ].append(
            record
        )

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
