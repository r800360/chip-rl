from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]

ORFS = Path.home() / "eda" / "OpenROAD-flow-scripts"
DOCKER_SHELL = ORFS / "flow" / "util" / "docker_shell"

TOP_MODULE = "addpipe"
TESTBENCH = ROOT / "sim" / "tb_addpipe.sv"
ORFS_CONFIG = "/work/orfs/config.mk"


def run(cmd: list[str], *, env=None) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd,
        cwd=ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )


def numeric_metric(
    metrics: dict[str, Any],
    *names: str,
) -> float | int | None:
    """
    Return the first available numeric metric.

    Multiple names are accepted because ORFS/OpenROAD metric naming
    has evolved across releases.
    """
    for name in names:
        if name not in metrics:
            continue

        value = metrics[name]

        if isinstance(value, (int, float)):
            return value

        try:
            return float(value)
        except (TypeError, ValueError):
            pass

    return None


def load_orfs_metrics(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}

    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return {}


def extract_metrics(metrics: dict[str, Any]) -> dict[str, Any]:
    return {
        # Final placed/routed instance area, um^2 for Nangate45.
        "area": numeric_metric(
            metrics,
            "finish__design__instance__area",
        ),

        # Final setup timing.
        "wns": numeric_metric(
            metrics,
            "finish__timing__setup__ws",
            "finish__timing__wns",
            "finish__timing__ws",
        ),

        "tns": numeric_metric(
            metrics,
            "finish__timing__setup__tns",
            "finish__timing__tns",
        ),

        # Prefer standard-cell count when available.
        "cells": numeric_metric(
            metrics,
            "finish__design__instance__count__stdcell",
            "finish__design__instance__count",
        ),

        "wirelength": numeric_metric(
            metrics,
            "detailedroute__route__wirelength",
        ),

        "drc_errors": numeric_metric(
            metrics,
            "detailedroute__route__drc_errors",
        ),

        "power_w": numeric_metric(
            metrics,
            "finish__power__total",
        ),
    }


def reward(result: dict[str, Any]) -> float:
    """
    Deliberately simple v0 reward.

    We are NOT claiming this is a good hardware objective.
    Investigating its failure modes is part of the project.
    """
    if not result["functional"]:
        return -1000.0

    if not result["place_route_ok"]:
        return -500.0

    area = result.get("area")
    wns = result.get("wns")

    # Do not silently reward a run with missing QoR data.
    if area is None or wns is None:
        return -250.0

    return -0.001 * float(area) + 10.0 * float(wns)


def evaluate(candidate: str | Path) -> dict[str, Any]:
    candidate = Path(candidate)

    if not candidate.is_absolute():
        candidate = ROOT / candidate

    candidate = candidate.resolve()

    try:
        relative_candidate = candidate.relative_to(ROOT)
    except ValueError:
        raise ValueError(
            f"Candidate must be inside {ROOT}, got {candidate}"
        )

    if not candidate.is_file():
        raise FileNotFoundError(candidate)

    digest = hashlib.sha256(candidate.read_bytes()).hexdigest()[:12]
    variant = f"eval_{digest}"

    build_dir = ROOT / ".chiprl" / "verilator" / digest

    if build_dir.exists():
        shutil.rmtree(build_dir)

    build_dir.mkdir(parents=True)

    total_start = time.perf_counter()

    # ------------------------------------------------------------
    # 1. Functional verification
    # ------------------------------------------------------------

    verilator_start = time.perf_counter()

    compile_result = run(
        [
            "verilator",
            "--binary",
            "--timing",
            "-Wall",
            "-Wno-fatal",
            "--Mdir",
            str(build_dir),
            str(candidate),
            str(TESTBENCH),
            "--top-module",
            "tb",
        ]
    )

    sim_result = None
    functional = False

    if compile_result.returncode == 0:
        sim_result = run([str(build_dir / "Vtb")])

        functional = (
            sim_result.returncode == 0
            and "PASS" in sim_result.stdout
        )

    verilator_runtime = time.perf_counter() - verilator_start

    if not functional:
        result = {
            "candidate": str(relative_candidate),
            "id": digest,
            "functional": False,
            "synthesis_ok": False,
            "place_route_ok": False,

            "area": None,
            "wns": None,
            "tns": None,
            "cells": None,
            "wirelength": None,
            "drc_errors": None,
            "power_w": None,

            "runtime_s": round(
                time.perf_counter() - total_start, 3
            ),
            "verilator_runtime_s": round(
                verilator_runtime, 3
            ),
            "orfs_runtime_s": 0.0,

            "reward": -1000.0,
            "gds": None,
        }

        save_result(result)

        print_failure(
            "Verilator",
            sim_result.stdout if sim_result else compile_result.stdout,
        )

        return result

    # ------------------------------------------------------------
    # 2. ASIC physical design
    # ------------------------------------------------------------

    env = os.environ.copy()
    env.setdefault("OR_IMAGE", "openroad/orfs:local")

    candidate_in_container = (
        "/work/" + relative_candidate.as_posix()
    )

    orfs_start = time.perf_counter()

    orfs_result = run(
        [
            str(DOCKER_SHELL),
            "make",
            f"DESIGN_CONFIG={ORFS_CONFIG}",
            f"VERILOG_FILES={candidate_in_container}",
            f"FLOW_VARIANT={variant}",
        ],
        env=env,
    )

    orfs_runtime = time.perf_counter() - orfs_start

    result_dir = (
        ROOT
        / "results"
        / "nangate45"
        / TOP_MODULE
        / variant
    )

    log_dir = (
        ROOT
        / "logs"
        / "nangate45"
        / TOP_MODULE
        / variant
    )

    synthesis_ok = (result_dir / "1_synth.odb").is_file()

    gds = result_dir / "6_final.gds"

    place_route_ok = (
        orfs_result.returncode == 0
        and gds.is_file()
    )

    metrics_file = log_dir / "6_report.json"
    raw_metrics = load_orfs_metrics(metrics_file)
    qos = extract_metrics(raw_metrics)

    result = {
        "candidate": str(relative_candidate),
        "id": digest,

        "functional": functional,
        "synthesis_ok": synthesis_ok,
        "place_route_ok": place_route_ok,

        **qos,

        "runtime_s": round(
            time.perf_counter() - total_start, 3
        ),
        "verilator_runtime_s": round(
            verilator_runtime, 3
        ),
        "orfs_runtime_s": round(
            orfs_runtime, 3
        ),

        "reward": None,

        "gds": (
            str(gds.relative_to(ROOT))
            if gds.is_file()
            else None
        ),

        "metrics_file": (
            str(metrics_file.relative_to(ROOT))
            if metrics_file.is_file()
            else None
        ),
    }

    result["reward"] = round(reward(result), 6)

    save_result(result)

    if not place_route_ok:
        print_failure("OpenROAD", orfs_result.stdout)

    return result


def save_result(result: dict[str, Any]) -> None:
    out_dir = ROOT / "results" / "evaluations"
    out_dir.mkdir(parents=True, exist_ok=True)

    path = out_dir / f'{result["id"]}.json'

    path.write_text(
        json.dumps(result, indent=2) + "\n"
    )


def print_failure(stage: str, output: str) -> None:
    print(f"\n--- {stage} failure: last 50 lines ---")

    for line in output.splitlines()[-50:]:
        print(line)

    print("--- end failure output ---\n")


def main() -> None:
    candidate = (
        sys.argv[1]
        if len(sys.argv) > 1
        else "rtl/addpipe.v"
    )

    result = evaluate(candidate)

    print(json.dumps(result, indent=2))

    if not result["functional"] or not result["place_route_ok"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
