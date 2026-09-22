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
    "addpipe24": Benchmark(
        name="addpipe24",

        top_module="addpipe24",
        reference_top="addpipe24_ref",

        testbench=ROOT / "sim" / "tb_addpipe24.sv",
        reference=ROOT / "rtl/reference/addpipe24_ref.v",

        orfs_config_host=ROOT / "orfs/addpipe24/config.mk",
        orfs_config_container="/work/orfs/addpipe24/config.mk",
        sdc=ROOT / "orfs/addpipe24/constraint.sdc",

        pass_marker="PASS addpipe24 randomized+protocol",
    ),
    "addpipe32": Benchmark(
        name="addpipe32",

        top_module="addpipe32",
        reference_top="addpipe32_ref",

        testbench=ROOT / "sim" / "tb_addpipe32.sv",
        reference=ROOT / "rtl/reference/addpipe32_ref.v",

        orfs_config_host=ROOT / "orfs/addpipe32/config.mk",
        orfs_config_container="/work/orfs/addpipe32/config.mk",
        sdc=ROOT / "orfs/addpipe32/constraint.sdc",

        pass_marker="PASS addpipe32 randomized+protocol",
    ),
    "addpipe40": Benchmark(
        name="addpipe40",

        top_module="addpipe40",
        reference_top="addpipe40_ref",

        testbench=ROOT / "sim" / "tb_addpipe40.sv",
        reference=ROOT / "rtl/reference/addpipe40_ref.v",

        orfs_config_host=ROOT / "orfs/addpipe40/config.mk",
        orfs_config_container="/work/orfs/addpipe40/config.mk",
        sdc=ROOT / "orfs/addpipe40/constraint.sdc",

        pass_marker="PASS addpipe40 randomized+protocol",
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
