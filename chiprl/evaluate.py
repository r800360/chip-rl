from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

from chiprl.benchmarks import (
    BENCHMARKS,
    Benchmark,
    ROOT,
    get_benchmark,
)
from chiprl.formal import check_equivalence


ORFS = Path.home() / "eda" / "OpenROAD-flow-scripts"
DOCKER_SHELL = ORFS / "flow" / "util" / "docker_shell"

EVALUATOR_SCHEMA_VERSION = "4"


def run(
    cmd: list[str],
    *,
    env=None,
) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd,
        cwd=ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def command_text(cmd: list[str]) -> str | None:
    try:
        p = run(cmd)
        if p.returncode == 0:
            return p.stdout.strip()
    except OSError:
        pass

    return None


def environment_manifest() -> dict[str, Any]:
    or_image = os.environ.get(
        "OR_IMAGE",
        "openroad/orfs:local",
    )

    return {
        "python": sys.version.split()[0],
        "platform": platform.platform(),

        "verilator": command_text(
            ["verilator", "--version"]
        ),

        "or_image": or_image,

        "or_image_id": command_text([
            "docker",
            "image",
            "inspect",
            or_image,
            "--format={{.Id}}",
        ]),

        "orfs_git_commit": command_text([
            "git",
            "-C",
            str(ORFS),
            "rev-parse",
            "HEAD",
        ]),
    }


def make_fingerprint(
    candidate: Path,
    benchmark: Benchmark,
    environment: dict[str, Any],
) -> tuple[str, dict[str, Any]]:

    components = {
        "schema_version":
            EVALUATOR_SCHEMA_VERSION,

        "benchmark":
            benchmark.name,

        "top_module":
            benchmark.top_module,

        "rtl_sha256":
            sha256_file(candidate),

        "testbench_sha256":
            sha256_file(benchmark.testbench),

        "reference_rtl_sha256":
            sha256_file(benchmark.reference),

        "orfs_config_sha256":
            sha256_file(
                benchmark.orfs_config_host
            ),

        "sdc_sha256":
            sha256_file(benchmark.sdc),

        "formal_seq":
            benchmark.formal_seq,

        "or_image":
            environment["or_image"],

        "or_image_id":
            environment["or_image_id"],

        "orfs_git_commit":
            environment["orfs_git_commit"],

        "verilator":
            environment["verilator"],
    }

    encoded = json.dumps(
        components,
        sort_keys=True,
        separators=(",", ":"),
    ).encode()

    evaluation_id = (
        sha256_bytes(encoded)[:16]
    )

    return evaluation_id, components


def numeric_metric(
    metrics: dict[str, Any],
    *names: str,
) -> float | int | None:

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


def load_json(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}

    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return {}


def extract_metrics(
    metrics: dict[str, Any],
) -> dict[str, Any]:

    return {
        "area": numeric_metric(
            metrics,
            "finish__design__instance__area",
        ),

        "cells": numeric_metric(
            metrics,
            "finish__design__instance__count__stdcell",
            "finish__design__instance__count",
        ),

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

        "hold_wns": numeric_metric(
            metrics,
            "finish__timing__hold__ws",
        ),

        "setup_violations": numeric_metric(
            metrics,
            "finish__timing__drv__setup_violation_count",
        ),

        "hold_violations": numeric_metric(
            metrics,
            "finish__timing__drv__hold_violation_count",
        ),

        "power_w": numeric_metric(
            metrics,
            "finish__power__total",
        ),

        # Preserve for inspection, but do not use
        # this metric in optimization yet.
        "fmax_hz": numeric_metric(
            metrics,
            "finish__timing__fmax__clock:core_clock",
            "finish__timing__fmax",
        ),
    }


def proxy_reward_v0(
    result: dict[str, Any],
) -> float:

    if not result["functional"]:
        return -1000.0

    if not result["formal_ok"]:
        return -1000.0

    if not result["place_route_ok"]:
        return -500.0

    area = result.get("area")
    wns = result.get("wns")

    if area is None or wns is None:
        return -250.0

    return (
        -0.001 * float(area)
        + 10.0 * float(wns)
    )


def clear_variant(
    benchmark: Benchmark,
    evaluation_id: str,
) -> None:

    variant = f"eval_{evaluation_id}"

    for tree in (
        "results",
        "logs",
        "reports",
        "objects",
    ):
        path = (
            ROOT
            / tree
            / benchmark.platform
            / benchmark.top_module
            / variant
        )

        shutil.rmtree(
            path,
            ignore_errors=True,
        )

    shutil.rmtree(
        ROOT
        / ".chiprl"
        / "verilator"
        / evaluation_id,
        ignore_errors=True,
    )


def save_result(
    path: Path,
    result: dict[str, Any],
) -> None:

    path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    path.write_text(
        json.dumps(
            result,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )


def print_failure(
    stage: str,
    output: str,
) -> None:

    print(
        f"\n--- {stage} failure: "
        "last 60 lines ---"
    )

    for line in output.splitlines()[-60:]:
        print(line)

    print("--- end failure output ---\n")


def evaluate(
    candidate: str | Path,
    *,
    benchmark: str | Benchmark = "addpipe8",
    cache: bool = True,
    clean: bool = False,
) -> dict[str, Any]:

    if isinstance(benchmark, str):
        benchmark = get_benchmark(benchmark)

    candidate = Path(candidate)

    if not candidate.is_absolute():
        candidate = ROOT / candidate

    candidate = candidate.resolve()

    try:
        relative_candidate = (
            candidate.relative_to(ROOT)
        )
    except ValueError:
        raise ValueError(
            f"Candidate must be inside "
            f"{ROOT}: {candidate}"
        )

    if not candidate.is_file():
        raise FileNotFoundError(candidate)

    environment = environment_manifest()

    evaluation_id, fingerprint = (
        make_fingerprint(
            candidate,
            benchmark,
            environment,
        )
    )

    variant = f"eval_{evaluation_id}"

    result_json = (
        ROOT
        / "results"
        / "evaluations"
        / benchmark.name
        / f"{evaluation_id}.json"
    )

    raw_metrics_copy = (
        ROOT
        / "results"
        / "evaluations"
        / benchmark.name
        / f"{evaluation_id}.metrics.json"
    )

    if clean:
        clear_variant(
            benchmark,
            evaluation_id,
        )

        result_json.unlink(
            missing_ok=True
        )

        raw_metrics_copy.unlink(
            missing_ok=True
        )

    if cache and result_json.is_file():
        result = load_json(result_json)

        if result:
            result["cache_hit"] = True
            return result

    build_dir = (
        ROOT
        / ".chiprl"
        / "verilator"
        / evaluation_id
    )

    shutil.rmtree(
        build_dir,
        ignore_errors=True,
    )

    build_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    total_start = time.perf_counter()

    # ========================================================
    # 1. Dynamic simulation
    # ========================================================

    verilator_start = time.perf_counter()

    compile_result = run([
        "verilator",
        "--binary",
        "--timing",
        "-Wall",
        "-Wno-fatal",
        "--Mdir",
        str(build_dir),
        str(candidate),
        str(benchmark.testbench),
        "--top-module",
        "tb",
    ])

    sim_result = None
    functional = False

    if compile_result.returncode == 0:
        sim_result = run([
            str(build_dir / "Vtb")
        ])

        functional = (
            sim_result.returncode == 0
            and benchmark.pass_marker
            in sim_result.stdout
        )

    verilator_runtime = (
        time.perf_counter()
        - verilator_start
    )

    base_result: dict[str, Any] = {
        "evaluation_id":
            evaluation_id,

        "benchmark":
            benchmark.name,

        "candidate":
            str(relative_candidate),

        "fingerprint":
            fingerprint,

        "environment":
            environment,

        "functional":
            functional,

        "formal_ok":
            False,

        "synthesis_ok":
            False,

        "place_route_ok":
            False,

        "area":
            None,

        "cells":
            None,

        "wns":
            None,

        "tns":
            None,

        "hold_wns":
            None,

        "setup_violations":
            None,

        "hold_violations":
            None,

        "power_w":
            None,

        "fmax_hz":
            None,

        "runtime_s":
            None,

        "verilator_runtime_s":
            round(verilator_runtime, 3),

        "formal_runtime_s":
            0.0,

        "orfs_runtime_s":
            0.0,

        "proxy_reward_v0":
            None,

        "gds":
            None,

        "metrics_file":
            None,

        "cache_hit":
            False,
    }

    if not functional:
        base_result["runtime_s"] = round(
            time.perf_counter()
            - total_start,
            3,
        )

        base_result[
            "proxy_reward_v0"
        ] = -1000.0

        save_result(
            result_json,
            base_result,
        )

        print_failure(
            "Verilator",
            (
                sim_result.stdout
                if sim_result
                else compile_result.stdout
            ),
        )

        return base_result

    # ========================================================
    # 2. Formal equivalence
    # ========================================================

    formal_result = check_equivalence(
        relative_candidate,
        benchmark,
    )

    base_result["formal_ok"] = (
        formal_result["formal_ok"]
    )

    base_result["formal_runtime_s"] = (
        formal_result["formal_runtime_s"]
    )

    if not formal_result["formal_ok"]:
        base_result["runtime_s"] = round(
            time.perf_counter()
            - total_start,
            3,
        )

        base_result[
            "proxy_reward_v0"
        ] = -1000.0

        save_result(
            result_json,
            base_result,
        )

        print_failure(
            "Formal equivalence",
            formal_result["formal_output"],
        )

        return base_result

    # ========================================================
    # 3. ASIC physical implementation
    # ========================================================

    env = os.environ.copy()

    env.setdefault(
        "OR_IMAGE",
        "openroad/orfs:local",
    )

    candidate_container = (
        "/work/"
        + relative_candidate.as_posix()
    )

    orfs_start = time.perf_counter()

    orfs_result = run(
        [
            str(DOCKER_SHELL),
            "make",

            (
                "DESIGN_CONFIG="
                f"{benchmark.orfs_config_container}"
            ),

            (
                "VERILOG_FILES="
                f"{candidate_container}"
            ),

            f"FLOW_VARIANT={variant}",
        ],
        env=env,
    )

    orfs_runtime = (
        time.perf_counter()
        - orfs_start
    )

    result_dir = (
        ROOT
        / "results"
        / benchmark.platform
        / benchmark.top_module
        / variant
    )

    log_dir = (
        ROOT
        / "logs"
        / benchmark.platform
        / benchmark.top_module
        / variant
    )

    synth_odb = (
        result_dir
        / "1_synth.odb"
    )

    gds = (
        result_dir
        / "6_final.gds"
    )

    metrics_file = (
        log_dir
        / "6_report.json"
    )

    synthesis_ok = (
        synth_odb.is_file()
    )

    place_route_ok = (
        orfs_result.returncode == 0
        and gds.is_file()
    )

    raw_metrics = load_json(
        metrics_file
    )

    qos = extract_metrics(
        raw_metrics
    )

    if raw_metrics:
        raw_metrics_copy.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        raw_metrics_copy.write_text(
            json.dumps(
                raw_metrics,
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )

    result = {
        **base_result,
        **qos,

        "formal_ok":
            True,

        "synthesis_ok":
            synthesis_ok,

        "place_route_ok":
            place_route_ok,

        "runtime_s":
            round(
                time.perf_counter()
                - total_start,
                3,
            ),

        "orfs_runtime_s":
            round(
                orfs_runtime,
                3,
            ),

        "gds":
            (
                str(gds.relative_to(ROOT))
                if gds.is_file()
                else None
            ),

        "metrics_file":
            (
                str(
                    raw_metrics_copy.relative_to(
                        ROOT
                    )
                )
                if raw_metrics_copy.is_file()
                else None
            ),
    }

    result["proxy_reward_v0"] = round(
        proxy_reward_v0(result),
        6,
    )

    save_result(
        result_json,
        result,
    )

    if not place_route_ok:
        print_failure(
            "OpenROAD",
            orfs_result.stdout,
        )

    return result


def main() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "candidate",
    )

    parser.add_argument(
        "--benchmark",
        default="addpipe8",
        choices=tuple(sorted(BENCHMARKS)),
    )

    parser.add_argument(
        "--no-cache",
        action="store_true",
    )

    parser.add_argument(
        "--clean",
        action="store_true",
    )

    args = parser.parse_args()

    result = evaluate(
        args.candidate,
        benchmark=args.benchmark,
        cache=not args.no_cache,
        clean=args.clean,
    )

    print(
        json.dumps(
            result,
            indent=2,
        )
    )

    if not (
        result["functional"]
        and result["formal_ok"]
        and result["place_route_ok"]
    ):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
