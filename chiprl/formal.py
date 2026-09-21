from __future__ import annotations

import hashlib
import os
import subprocess
import time
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]

ORFS = Path.home() / "eda" / "OpenROAD-flow-scripts"
DOCKER_SHELL = ORFS / "flow" / "util" / "docker_shell"

REFERENCE = (
    ROOT
    / "rtl"
    / "reference"
    / "addpipe_ref.v"
)

FORMAL_SEQ = 4


def check_equivalence(
    candidate: str | Path,
) -> dict[str, Any]:
    candidate = Path(candidate)

    if not candidate.is_absolute():
        candidate = ROOT / candidate

    candidate = candidate.resolve()
    candidate_rel = candidate.relative_to(ROOT)

    digest = hashlib.sha256(
        candidate.read_bytes()
    ).hexdigest()[:16]

    formal_dir = (
        ROOT
        / ".chiprl"
        / "formal"
    )

    formal_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    script_host = (
        formal_dir
        / f"{digest}.ys"
    )

    script_container = (
        f"/work/.chiprl/formal/{digest}.ys"
    )

    candidate_container = (
        "/work/"
        + candidate_rel.as_posix()
    )

    reference_container = (
        "/work/"
        + REFERENCE.relative_to(ROOT).as_posix()
    )

    script_host.write_text(
        f"""
read_verilog -formal {reference_container}
read_verilog -formal {candidate_container}

proc
opt

equiv_make addpipe_ref addpipe equiv
hierarchy -top equiv

equiv_simple -seq {FORMAL_SEQ}
equiv_induct -seq {FORMAL_SEQ}
equiv_status -assert
""".lstrip()
    )

    env = os.environ.copy()

    env.setdefault(
        "OR_IMAGE",
        "openroad/orfs:local",
    )

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

    runtime = (
        time.perf_counter()
        - start
    )

    proven = (
        proc.returncode == 0
        and
        "Equivalence successfully proven!"
        in proc.stdout
    )

    return {
        "formal_ok": proven,
        "formal_runtime_s": round(
            runtime,
            3,
        ),
        "formal_returncode":
            proc.returncode,
        "formal_output":
            proc.stdout,
    }
