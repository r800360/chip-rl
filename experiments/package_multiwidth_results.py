from __future__ import annotations

import hashlib
import json
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results/multiwidth_generalization_v1"
OUT.mkdir(parents=True, exist_ok=True)

WIDTHS = (36, 48, 56)

CONTROLLED = (
    "random",
    "evolution",
    "claude_structural",
)

RL = {
    "reinforce_v1": "reinforce_v1",
    "reinforce_v2": "autoregressive_v2",
}

FINGERPRINT_KEYS = (
    "schema_version",
    "benchmark",
    "testbench_sha256",
    "reference_rtl_sha256",
    "orfs_config_sha256",
    "sdc_sha256",
    "or_image_id",
    "orfs_git_commit",
    "verilator",
)


def load(path):
    if not path.is_file():
        raise FileNotFoundError(path)
    return json.loads(path.read_text())


def mask_number(value):
    if isinstance(value, str):
        return int(value, 0)
    return int(value)


def valid(row):
    return bool(
        row.get("functional")
        and row.get("formal_ok")
        and row.get("place_route_ok")
        and row.get("area") is not None
        and row.get("wns") is not None
        and row.get("proxy_reward_v0") is not None
    )


def sha(path):
    return hashlib.sha256(
        path.read_bytes()
    ).hexdigest()


def check_fingerprint(row, expected, context):
    fp = row.get("fingerprint")

    if fp is None:
        raise RuntimeError(
            f"{context}: missing evaluator fingerprint"
        )

    for key in FINGERPRINT_KEYS:
        if fp.get(key) != expected.get(key):
            raise RuntimeError(
                f"{context}: fingerprint mismatch: {key}\n"
                f"expected={expected.get(key)}\n"
                f"observed={fp.get(key)}"
            )


files = set()
summary = []

print("=" * 100)
print("MULTIWIDTH GENERALIZATION: DATA INTEGRITY")
print("=" * 100)

for width in WIDTHS:
    name = f"addpipe{width}"
    digits = (width - 1 + 3) // 4

    protocol_path = (
        ROOT / "experiments"
        / f"protocol_{name}_rl_v2.json"
    )

    seed_dir = (
        ROOT / "results"
        / f"{name}_shared_seed"
    )

    seed_path = seed_dir / "results.json"

    protocol = load(protocol_path)
    seeds = load(seed_path)

    expected_masks = [
        mask_number(value)
        for value in protocol[
            "shared_initial_seed_masks"
        ]
    ]

    observed_masks = [
        mask_number(row["boundary_mask"])
        for row in seeds
    ]

    assert len(seeds) == 8, name
    assert observed_masks == expected_masks, name
    assert len(set(observed_masks)) == 8, name
    assert all(valid(row) for row in seeds), name

    reference_fp = seeds[0]["fingerprint"]

    for i, row in enumerate(seeds):
        check_fingerprint(
            row,
            reference_fp,
            f"{name} seed {i + 1}",
        )

    incumbent = max(
        seeds,
        key=lambda row: row["proxy_reward_v0"],
    )

    seed_score = incumbent["proxy_reward_v0"]

    print()
    print(
        name,
        "seed:",
        f"0x{mask_number(incumbent['boundary_mask']):0{digits}x}",
        f"reward={seed_score:.6f}",
    )

    runs = {}

    for method in CONTROLLED:
        directory = (
            ROOT / "results"
            / f"{name}_controlled"
            / method
        )

        rows = load(
            directory / "results.json"
        )

        runs[method] = rows

        files.update(
            directory.glob("*.json")
        )

    for method, directory_name in RL.items():
        directory = (
            ROOT / "results/rl_runs"
            / name
            / directory_name
        )

        state = load(
            directory / "state.json"
        )

        rows = []

        for q in state["queries"]:
            row = dict(
                q.get("result") or {}
            )

            row["boundary_mask"] = (
                q["boundary_mask"]
            )

            row["query_index"] = (
                q["query_index"]
            )

            rows.append(row)

        runs[method] = rows

        # Include every saved policy snapshot, not
        # just the final one.
        files.update(
            directory.glob("*.json")
        )

    for method, rows in runs.items():
        if len(rows) != 16:
            raise RuntimeError(
                f"{name}/{method}: "
                f"expected 16 queries, got {len(rows)}"
            )

        masks = [
            mask_number(row["boundary_mask"])
            for row in rows
        ]

        duplicate_count = (
            len(masks) - len(set(masks))
        )

        successful = [
            row for row in rows
            if valid(row)
        ]

        for i, row in enumerate(rows):
            if row.get("fingerprint"):
                check_fingerprint(
                    row,
                    reference_fp,
                    f"{name}/{method}/query{i+1}",
                )

        best = incumbent
        first_improvement = None

        for i, row in enumerate(rows, 1):
            if (
                valid(row)
                and row["proxy_reward_v0"]
                > best["proxy_reward_v0"]
            ):
                best = row

            if (
                first_improvement is None
                and best["proxy_reward_v0"]
                > seed_score + 1e-9
            ):
                first_improvement = i

        mean_boundaries = (
            sum(m.bit_count() for m in masks)
            / len(masks)
        )

        item = {
            "benchmark": name,
            "algorithm": method,
            "queries": len(rows),
            "successful_queries": len(successful),
            "duplicate_query_masks": duplicate_count,
            "first_improvement": first_improvement,
            "seed_reward": seed_score,
            "final_reward": best["proxy_reward_v0"],
            "reward_delta": (
                best["proxy_reward_v0"] - seed_score
            ),
            "best_mask": (
                f"0x{mask_number(best['boundary_mask']):0{digits}x}"
            ),
            "mean_boundaries": mean_boundaries,
        }

        summary.append(item)

        first = (
            str(first_improvement)
            if first_improvement is not None
            else "-"
        )

        print(
            f"  {method:<20}"
            f" valid={len(successful):2d}/16"
            f" first={first:>2}"
            f" delta={item['reward_delta']:+.6f}"
            f" meanK={mean_boundaries:.2f}"
            f" dup={duplicate_count}"
        )

    files.update(
        seed_dir.glob("*.json")
    )

    files.add(protocol_path)

    # Include the code needed to inspect or
    # regenerate structural candidates.
    files.update(
        (ROOT / "experiments").glob(
            f"{name}_*.py"
        )
    )

    files.add(
        ROOT / "chiprl"
        / f"generate_{name}.py"
    )

    files.add(
        ROOT / "adapters"
        / f"claude_{name}_structural.py"
    )

    files.add(
        ROOT / "sim"
        / f"tb_{name}.sv"
    )

    files.add(
        ROOT / "rtl/reference"
        / f"{name}_ref.v"
    )

    files.add(
        ROOT / "orfs"
        / name
        / "config.mk"
    )

    files.add(
        ROOT / "orfs"
        / name
        / "constraint.sdc"
    )

assert len(summary) == 15
assert sum(x["queries"] for x in summary) == 240

files.update(
    (ROOT / "chiprl").glob("*.py")
)

for filename in (
    "protocol_multiwidth_generalization_v1.json",
    "multiwidth_shared_seed_freeze_v1.json",
    "amendment_addpipe36_testbench_width_v1.json",
):
    files.add(
        ROOT / "experiments" / filename
    )

files.add(
    ROOT / "experiments"
    / "run_multiwidth_generalization_v1.sh"
)

files = sorted(files)

for path in files:
    if not path.is_file():
        raise FileNotFoundError(path)

manifest = {
    "experiment": "multiwidth_generalization_v1",
    "git_commit": subprocess.check_output(
        ["git", "rev-parse", "HEAD"],
        text=True,
    ).strip(),
    "total_search_queries": 240,
    "num_algorithms": 5,
    "num_benchmarks": 3,
    "summary": summary,
    "files": {
        str(path.relative_to(ROOT)): {
            "sha256": sha(path),
            "bytes": path.stat().st_size,
        }
        for path in files
    },
}

summary_path = OUT / "compact_summary.json"

summary_path.write_text(
    json.dumps(
        manifest,
        indent=2,
        sort_keys=True,
    ) + "\n"
)

archive = OUT / "multiwidth_results_bundle.zip"

with zipfile.ZipFile(
    archive,
    "w",
    compression=zipfile.ZIP_DEFLATED,
    compresslevel=9,
) as z:
    z.write(
        summary_path,
        summary_path.relative_to(ROOT),
    )

    for path in files:
        z.write(
            path,
            path.relative_to(ROOT),
        )

# Independently verify ZIP integrity.
with zipfile.ZipFile(archive) as z:
    bad = z.testzip()

assert bad is None, bad

print()
print("=" * 100)
print("PASS: 15 runs, 240 saved queries")
print("PASS: frozen seed and fingerprint checks")
print("PASS: compressed archive integrity")
print("=" * 100)

print("Summary:", summary_path)
print("Archive:", archive)
print("Archive bytes:", archive.stat().st_size)
print("Archive SHA256:", sha(archive))
