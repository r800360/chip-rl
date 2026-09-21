import hashlib
import json
import shutil
from pathlib import Path

from chiprl.evaluate import evaluate


ROOT = Path(__file__).resolve().parents[1]
TOP_MODULE = "addpipe"

CANDIDATE = ROOT / "rtl/candidates/candidate_00.v"


def variant_for(path: Path) -> str:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()[:12]
    return f"eval_{digest}"


def clear_variant(variant: str) -> None:
    for tree in ("results", "logs", "reports", "objects"):
        path = (
            ROOT
            / tree
            / "nangate45"
            / TOP_MODULE
            / variant
        )

        shutil.rmtree(path, ignore_errors=True)


def main():
    variant = variant_for(CANDIDATE)

    runs = []

    for i in range(3):
        print(f"\n===== Fresh run {i + 1}/3 =====")

        clear_variant(variant)

        result = evaluate(
            CANDIDATE.relative_to(ROOT)
        )

        runs.append(result)

        print(
            f"area={result['area']} "
            f"cells={result['cells']} "
            f"wns={result['wns']} "
            f"tns={result['tns']} "
            f"orfs={result['orfs_runtime_s']}s"
        )

    output = ROOT / "results/reproducibility_candidate_00.json"

    output.write_text(
        json.dumps(runs, indent=2) + "\n"
    )

    print("\nSummary:")
    print(
        f"{'run':>4} "
        f"{'cells':>8} "
        f"{'area':>12} "
        f"{'WNS':>12} "
        f"{'TNS':>12} "
        f"{'ORFS/s':>12}"
    )

    for i, r in enumerate(runs, 1):
        print(
            f"{i:>4} "
            f"{r['cells']:>8} "
            f"{r['area']:>12.3f} "
            f"{r['wns']:>12.6f} "
            f"{r['tns']:>12} "
            f"{r['orfs_runtime_s']:>12.3f}"
        )


if __name__ == "__main__":
    main()
