from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class Benchmark:
    name: str

    top_module: str
    reference_top: str

    testbench: Path
    reference: Path

    orfs_config_host: Path
    orfs_config_container: str
    sdc: Path

    pass_marker: str

    platform: str = "nangate45"
    formal_seq: int = 4


BENCHMARKS = {
    "addpipe8": Benchmark(
        name="addpipe8",

        top_module="addpipe",
        reference_top="addpipe_ref",

        testbench=ROOT / "sim" / "tb_addpipe.sv",
        reference=ROOT / "rtl/reference/addpipe_ref.v",

        orfs_config_host=ROOT / "orfs/config.mk",
        orfs_config_container="/work/orfs/config.mk",
        sdc=ROOT / "orfs/constraint.sdc",

        pass_marker=(
            "PASS exhaustive+protocol: 65536 additions"
        ),
    ),

    "addpipe16": Benchmark(
        name="addpipe16",

        top_module="addpipe16",
        reference_top="addpipe16_ref",

        testbench=ROOT / "sim" / "tb_addpipe16.sv",
        reference=ROOT / "rtl/reference/addpipe16_ref.v",

        orfs_config_host=ROOT / "orfs/addpipe16/config.mk",
        orfs_config_container="/work/orfs/addpipe16/config.mk",
        sdc=ROOT / "orfs/addpipe16/constraint.sdc",

        pass_marker="PASS addpipe16 randomized+protocol",
    ),
}


def get_benchmark(name: str) -> Benchmark:
    try:
        return BENCHMARKS[name]
    except KeyError:
        raise ValueError(
            f"Unknown benchmark {name!r}; "
            f"choose from {sorted(BENCHMARKS)}"
        )
