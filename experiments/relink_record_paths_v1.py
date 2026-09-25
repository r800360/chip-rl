"""Point evaluation records at RTL files that were moved after evaluation.

A record's `candidate` field is the path the design was first evaluated
from. Folders that were later renamed (a pilot run, an aborted history run,
the partial first attempt of some agent episodes) left records pointing at
paths that no longer exist. Evaluation IDs depend on file contents, not
paths, so each record is relinked to a file on disk with the same SHA-256
and keeps the old path in `candidate_moved_from`. Nothing else changes.

Run: python -m experiments.relink_record_paths_v1   (idempotent)
"""
from __future__ import annotations

import hashlib
import json
from collections import defaultdict
from pathlib import Path

from chiprl.benchmarks import ROOT


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    by_sha = defaultdict(list)
    for path in sorted((ROOT / "rtl").rglob("*.v")):
        by_sha[sha256(path)].append(path.relative_to(ROOT).as_posix())
    relinked = []
    for record_path in sorted((ROOT / "results" / "evaluations").glob("*/*.json")):
        if record_path.name.endswith(".metrics.json"):
            continue
        record = json.loads(record_path.read_text())
        old = record.get("candidate", "")
        if not old or (ROOT / old).is_file():
            continue
        matches = by_sha.get(record["fingerprint"]["rtl_sha256"], [])
        if not matches:
            raise RuntimeError(f"{record_path}: no file with the content of {old}")
        name = Path(old).name
        new = min(matches, key=lambda p: (Path(p).name != name, p))
        record["candidate_moved_from"] = old
        record["candidate"] = new
        record_path.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n")
        relinked.append((record_path.relative_to(ROOT).as_posix(), old, new))
    for row in relinked:
        print(*row, sep="\n  ")
    print(f"{len(relinked)} records relinked")


if __name__ == "__main__":
    main()
