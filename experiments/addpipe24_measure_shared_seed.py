from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

from chiprl.generate_addpipe24 import (
    blocks_from_mask,
    write_candidate,
)


ROOT = Path(__file__).resolve().parents[1]

PROTOCOL = (
    ROOT
    / "experiments"
    / "protocol_addpipe24.json"
)

RTL_DIR = (
    ROOT
    / "rtl"
    / "generated"
    / "addpipe24_shared_seed"
)

OUT = (
    ROOT
    / "results"
    / "addpipe24_shared_seed"
)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def pareto(rows):
    def dominates(a, b):
        return (
            a["area"] <= b["area"]
            and a["wns"] >= b["wns"]
            and (
                a["area"] < b["area"]
                or a["wns"] > b["wns"]
            )
        )

    return sorted(
        [
            row
            for row in rows
            if not any(
                dominates(other, row)
                for other in rows
                if other is not row
            )
        ],
        key=lambda r: (
            r["area"],
            -r["wns"],
        ),
    )


def main():
    if (
        OUT / "results.json"
    ).exists():
        raise SystemExit(
            "Frozen shared seed results already exist. "
            "Refusing to overwrite them."
        )

    protocol = json.loads(
        PROTOCOL.read_text()
    )

    masks = [
        int(x, 0)
        for x
        in protocol[
            "shared_initial_seed_masks"
        ]
    ]

    if len(masks) != 8:
        raise RuntimeError(
            f"Expected 8 seed masks, got {len(masks)}"
        )

    if len(set(masks)) != len(masks):
        raise RuntimeError(
            "Shared seed masks are not unique"
        )

    protocol_hash = sha256_file(
        PROTOCOL
    )

    RTL_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    OUT.mkdir(
        parents=True,
        exist_ok=True,
    )

    rows = []

    print(
        "protocol sha256:",
        protocol_hash,
    )

    for index, mask in enumerate(
        masks
    ):
        blocks = blocks_from_mask(
            mask
        )

        candidate = (
            RTL_DIR
            / f"seed_{index:02d}_"
              f"{mask:06x}.v"
        )

        write_candidate(
            mask,
            candidate,
        )

        rel = candidate.relative_to(
            ROOT
        )

        print()
        print("=" * 72)
        print(
            f"SEED {index + 1}/8 "
            f"mask=0x{mask:06x} "
            f"blocks={blocks}"
        )
        print("=" * 72)

        cmd = [
            sys.executable,
            "-m",
            "chiprl.evaluate",
            str(rel),
            "--benchmark",
            "addpipe24",
            "--no-cache",
            "--clean",
        ]

        proc = subprocess.run(
            cmd,
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        (
            OUT
            / f"seed_{index:02d}.stdout.txt"
        ).write_text(
            proc.stdout
        )

        (
            OUT
            / f"seed_{index:02d}.stderr.txt"
        ).write_text(
            proc.stderr
        )

        if proc.returncode != 0:
            raise RuntimeError(
                f"Evaluator process failed for "
                f"0x{mask:06x}:\n"
                f"{proc.stderr}"
            )

        try:
            result = json.loads(
                proc.stdout
            )
        except json.JSONDecodeError as exc:
            raise RuntimeError(
                f"Could not parse evaluator JSON "
                f"for 0x{mask:06x}"
            ) from exc

        result["seed_index"] = index
        result["boundary_mask"] = mask
        result["mask"] = (
            f"0x{mask:06x}"
        )
        result["blocks"] = list(
            blocks
        )
        result["protocol_sha256"] = (
            protocol_hash
        )

        rows.append(result)

        (
            OUT
            / "partial_results.json"
        ).write_text(
            json.dumps(
                rows,
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )

        print(
            f"functional={result['functional']} "
            f"formal={result['formal_ok']} "
            f"route={result['place_route_ok']} "
            f"cells={result['cells']} "
            f"area={result['area']} "
            f"wns={result['wns']} "
            f"power={result['power_w']} "
            f"reward={result['proxy_reward_v0']}"
        )

        if not (
            result["functional"]
            and result["formal_ok"]
            and result["place_route_ok"]
        ):
            raise RuntimeError(
                f"Shared seed 0x{mask:06x} "
                "failed the evaluator."
            )

    frontier = pareto(
        rows
    )

    summary = {
        "benchmark": "addpipe24",
        "protocol_sha256":
            protocol_hash,
        "seed_count":
            len(rows),
        "all_valid":
            all(
                r["functional"]
                and r["formal_ok"]
                and r["place_route_ok"]
                for r in rows
            ),
        "pareto_count":
            len(frontier),
        "best_reward":
            max(
                rows,
                key=lambda r:
                    r["proxy_reward_v0"],
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
    }

    (
        OUT
        / "results.json"
    ).write_text(
        json.dumps(
            rows,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (
        OUT
        / "frontier.json"
    ).write_text(
        json.dumps(
            frontier,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    (
        OUT
        / "summary.json"
    ).write_text(
        json.dumps(
            summary,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    partial = (
        OUT
        / "partial_results.json"
    )

    if partial.exists():
        partial.unlink()

    print()
    print(
        "===================================="
    )
    print(
        "ADDPIPE24 SHARED SEED COMPLETE"
    )
    print(
        "===================================="
    )

    print(
        "all valid:",
        summary["all_valid"],
    )

    print(
        "Pareto points:",
        len(frontier),
    )

    print()
    print(
        "SHARED SEED FRONTIER"
    )

    for r in frontier:
        print(
            f"  {r['mask']} "
            f"blocks={tuple(r['blocks'])!s:<20} "
            f"area={r['area']:<10} "
            f"WNS={r['wns']:<9} "
            f"reward={r['proxy_reward_v0']}"
        )

    best = summary[
        "best_reward"
    ]

    print()
    print(
        "best seed reward:",
        best["mask"],
        tuple(best["blocks"]),
        best["proxy_reward_v0"],
    )

    print()
    print(
        f"Output: {OUT}"
    )


if __name__ == "__main__":
    main()
