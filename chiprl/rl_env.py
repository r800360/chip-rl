from __future__ import annotations

import json
from pathlib import Path
from typing import Callable, Any

from chiprl.benchmarks import ROOT
from chiprl.evaluate import evaluate


class InvalidAction(ValueError):
    pass


def is_valid_result(row: dict[str, Any]) -> bool:
    return bool(
        row.get("functional")
        and row.get("formal_ok")
        and row.get("place_route_ok")
        and row.get("area") is not None
        and row.get("wns") is not None
        and row.get("proxy_reward_v0") is not None
    )


def dominates(
    a: dict[str, Any],
    b: dict[str, Any],
) -> bool:
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
        if is_valid_result(r)
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


def mask_text(mask: int, mask_bits: int) -> str:
    digits = (mask_bits + 3) // 4
    return f"0x{mask:0{digits}x}"


class LookupMaskEvaluator:
    """
    Zero-EDA evaluator for environment testing.

    It can only return measurements that already exist in
    a supplied table. It must never be used to claim new
    physical-design results.
    """

    def __init__(self, rows):
        self.rows = {
            int(r["boundary_mask"]): dict(r)
            for r in rows
        }

    def __call__(
        self,
        mask: int,
        candidate_path: Path,
    ):
        if mask not in self.rows:
            raise KeyError(
                f"No lookup result for mask "
                f"{mask:#x}"
            )

        result = dict(
            self.rows[mask]
        )

        result["candidate"] = str(
            candidate_path.relative_to(ROOT)
        )

        result["lookup_backend"] = True

        return result


class EDAMaskEvaluator:
    """
    Real physical evaluator.

    One call corresponds to one genuine candidate query.
    """

    def __init__(
        self,
        benchmark: str,
    ):
        self.benchmark = benchmark

    def __call__(
        self,
        mask: int,
        candidate_path: Path,
    ):
        return dict(
            evaluate(
                candidate_path.relative_to(
                    ROOT
                ),
                benchmark=self.benchmark,
            )
        )


class StructuralMaskEnv:
    """
    Query-budgeted RL environment over a structural
    boundary-mask architecture space.

    Action
    ------
    An integer containing the complete boundary mask.

    Reward
    ------
    Increase in best-so-far proxy_reward_v0.

        r_t = best_t - best_(t-1)

    Therefore the undiscounted episode return telescopes to

        final_best - initial_best.

    Invalid or duplicate masks are rejected before an EDA
    query and do not consume query budget.

    Once a unique candidate has been submitted to the
    evaluator it consumes one query, regardless of its
    physical outcome.
    """

    def __init__(
        self,
        *,
        benchmark: str,
        width: int,
        run_id: str,
        budget: int,
        seed_rows,
        render_candidate: Callable[
            [int, Path],
            Any,
        ],
        evaluate_candidate: Callable[
            [int, Path],
            dict[str, Any],
        ],
    ):
        self.benchmark = benchmark
        self.width = int(width)
        self.mask_bits = self.width - 1

        if self.width < 2:
            raise ValueError(
                "width must be >= 2"
            )

        self.max_mask = (
            1 << self.mask_bits
        ) - 1

        self.run_id = run_id
        self.budget = int(budget)

        if self.budget <= 0:
            raise ValueError(
                "budget must be positive"
            )

        self.seed_rows = [
            dict(r)
            for r in seed_rows
        ]

        if not self.seed_rows:
            raise ValueError(
                "seed_rows cannot be empty"
            )

        for row in self.seed_rows:
            if not is_valid_result(row):
                raise ValueError(
                    "All seed rows must be valid "
                    "physical evaluations"
                )

        self.render_candidate = (
            render_candidate
        )

        self.evaluate_candidate = (
            evaluate_candidate
        )

        self.run_dir = (
            ROOT
            / "results"
            / "rl_runs"
            / benchmark
            / run_id
        )

        self.rtl_dir = (
            ROOT
            / "rtl"
            / "rl"
            / benchmark
            / run_id
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

        if self.state_path.exists():
            self.state = json.loads(
                self.state_path.read_text()
            )

            if (
                self.state["benchmark"]
                != benchmark
                or self.state["width"]
                != width
                or self.state["budget"]
                != budget
            ):
                raise RuntimeError(
                    "Existing RL run metadata "
                    "does not match requested environment"
                )

        else:
            self.state = {
                "run_id":
                    run_id,

                "benchmark":
                    benchmark,

                "width":
                    width,

                "mask_bits":
                    self.mask_bits,

                "budget":
                    budget,

                "queries":
                    [],
            }

            self._save()

        self.seed_masks = {
            int(r["boundary_mask"])
            for r in self.seed_rows
        }

    def _save(self):
        self.state_path.write_text(
            json.dumps(
                self.state,
                indent=2,
                sort_keys=True,
            ) + "\n"
        )

    @property
    def queries_used(self):
        return len(
            self.state["queries"]
        )

    @property
    def queries_remaining(self):
        return (
            self.budget
            - self.queries_used
        )

    @property
    def done(self):
        return (
            self.queries_used
            >= self.budget
        )

    def own_results(self):
        rows = []

        for q in self.state[
            "queries"
        ]:
            result = q.get(
                "result"
            )

            if result is None:
                continue

            # The evaluator owns physical metrics while the
            # environment owns action metadata.  Normalize
            # them here so both newly evaluated and resumed
            # query records have the same row schema as the
            # measured seed corpus.
            row = dict(
                result
            )

            row["boundary_mask"] = int(
                q["boundary_mask"]
            )

            row["mask"] = q.get(
                "mask",
                mask_text(
                    int(
                        q["boundary_mask"]
                    ),
                    self.mask_bits,
                ),
            )

            row["query_index"] = int(
                q["query_index"]
            )

            rows.append(
                row
            )

        return rows

    def successful_rows(self):
        return (
            list(self.seed_rows)
            + [
                r
                for r in self.own_results()
                if is_valid_result(r)
            ]
        )

    def seen_masks(self):
        seen = set(
            self.seed_masks
        )

        for q in self.state[
            "queries"
        ]:
            seen.add(
                int(q["boundary_mask"])
            )

        return seen

    def best_row(self):
        return max(
            self.successful_rows(),
            key=lambda r:
                r["proxy_reward_v0"],
        )

    def observation(self):
        best = self.best_row()

        return {
            "benchmark":
                self.benchmark,

            "width":
                self.width,

            "mask_bits":
                self.mask_bits,

            "max_mask":
                self.max_mask,

            "queries_used":
                self.queries_used,

            "queries_remaining":
                self.queries_remaining,

            "budget":
                self.budget,

            "initial_seed_archive":
                self.seed_rows,

            "own_query_history":
                self.state["queries"],

            "best_so_far": {
                "boundary_mask":
                    int(
                        best[
                            "boundary_mask"
                        ]
                    ),

                "mask":
                    mask_text(
                        int(
                            best[
                                "boundary_mask"
                            ]
                        ),
                        self.mask_bits,
                    ),

                "area":
                    best["area"],

                "wns":
                    best["wns"],

                "power_w":
                    best["power_w"],

                "proxy_reward_v0":
                    best[
                        "proxy_reward_v0"
                    ],
            },

            "frontier":
                pareto_front(
                    self.successful_rows()
                ),

            "reward_definition":
                (
                    "increase in best-so-far "
                    "proxy_reward_v0"
                ),

            "invalid_action_rule":
                (
                    "out-of-range or already-seen masks "
                    "are rejected before evaluation and "
                    "do not consume query budget"
                ),
        }

    def step(
        self,
        mask: int,
    ):
        if self.done:
            raise RuntimeError(
                "RL query budget exhausted"
            )

        if not isinstance(
            mask,
            int,
        ):
            raise InvalidAction(
                "mask must be an integer"
            )

        if not (
            0 <= mask <= self.max_mask
        ):
            raise InvalidAction(
                f"mask outside "
                f"0..{self.max_mask:#x}"
            )

        if mask in self.seen_masks():
            raise InvalidAction(
                f"mask {mask_text(mask, self.mask_bits)} "
                "has already been evaluated"
            )

        old_best = (
            self.best_row()[
                "proxy_reward_v0"
            ]
        )

        query_index = (
            self.queries_used
        )

        candidate = (
            self.rtl_dir
            / (
                f"query_{query_index:03d}_"
                f"{mask:0{(self.mask_bits + 3)//4}x}.v"
            )
        )

        self.render_candidate(
            mask,
            candidate,
        )

        # From this point onward the unique candidate has
        # been submitted and therefore consumes one query.
        try:
            result = dict(
                self.evaluate_candidate(
                    mask,
                    candidate,
                )
            )

            status = (
                "success"
                if is_valid_result(result)
                else "evaluation_failed"
            )

            error = None

        except Exception as exc:
            result = None
            status = (
                "evaluator_exception"
            )
            error = (
                f"{type(exc).__name__}: "
                f"{exc}"
            )

        record = {
            "query_index":
                query_index,

            "boundary_mask":
                mask,

            "mask":
                mask_text(
                    mask,
                    self.mask_bits,
                ),

            "status":
                status,

            "result":
                result,

            "error":
                error,
        }

        self.state[
            "queries"
        ].append(
            record
        )

        self._save()

        new_best = (
            self.best_row()[
                "proxy_reward_v0"
            ]
        )

        reward = max(
            0.0,
            new_best - old_best,
        )

        info = {
            "query_index":
                query_index,

            "mask":
                record["mask"],

            "status":
                status,

            "reward":
                reward,

            "old_best_reward":
                old_best,

            "new_best_reward":
                new_best,

            "improved_incumbent":
                new_best > old_best,

            "queries_used":
                self.queries_used,

            "queries_remaining":
                self.queries_remaining,
        }

        return (
            self.observation(),
            reward,
            self.done,
            info,
        )
