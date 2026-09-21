from __future__ import annotations

import hashlib
import os
import subprocess
import time
from pathlib import Path
from typing import Any

from chiprl.benchmarks import Benchmark, ROOT


ORFS = Path.home() / "eda" / "OpenROAD-flow-scripts"
DOCKER_SHELL = ORFS / "flow" / "util" / "docker_shell"


def check_equivalence(
    candidate: str | Path,
    benchmark: Benchmark,
) -> dict[str, Any]:
    candidate = Path(candidate)

    if not candidate.is_absolute():
        candidate = ROOT / candidate

    candidate = candidate.resolve()

    candidate_rel = candidate.relative_to(ROOT)
    reference_rel = benchmark.reference.relative_to(ROOT)

    digest_input = (
        candidate.read_bytes()
        + benchmark.reference.read_bytes()
        + benchmark.name.encode()
    )

    digest = hashlib.sha256(
        digest_input
    ).hexdigest()[:16]

    formal_dir = ROOT / ".chiprl" / "formal"
    formal_dir.mkdir(parents=True, exist_ok=True)

    script_host = formal_dir / f"{digest}.ys"
    script_container = f"/work/.chiprl/formal/{digest}.ys"

    candidate_container = (
        "/work/" + candidate_rel.as_posix()
    )

    reference_container = (
        "/work/" + reference_rel.as_posix()
    )

    script_host.write_text(
        f"""
read_verilog -formal {reference_container}
read_verilog -formal {candidate_container}

proc
opt

equiv_make {benchmark.reference_top} {benchmark.top_module} equiv
hierarchy -top equiv

equiv_simple -seq {benchmark.formal_seq}
equiv_induct -seq {benchmark.formal_seq}
equiv_status -assert
""".lstrip()
    )

    env = os.environ.copy()
    env.setdefault("OR_IMAGE", "openroad/orfs:local")

    start = time.perf_counter()

    proc = subprocess.run(
        [
            str(DOCKER_SHELL),
            "yosys",
            "-s",
            script_container,
        ],
        cwd=ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )

    return {
        "formal_ok": (
            proc.returncode == 0
            and "Equivalence successfully proven!"
            in proc.stdout
        ),

        "formal_runtime_s": round(
            time.perf_counter() - start,
            3,
        ),

        "formal_returncode": proc.returncode,
        "formal_output": proc.stdout,
    }
