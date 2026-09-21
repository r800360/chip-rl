from __future__ import annotations

import argparse
import json
from pathlib import Path

from chiprl.evaluate import evaluate
from chiprl.generate_addpipe16 import (
    CandidateSpec,
    MAX_MASK,
    write_candidate,
)


ROOT = Path(__file__).resolve().parents[1]

TAG = "addpipe16_model_guided"

GEN_DIR = (
    ROOT
    / "rtl"
    / "generated"
    / TAG
)

OUT_DIR = (
    ROOT
    / "results"
    / TAG
)

HISTORY = OUT_DIR / "history.json"


KNOWN_RESULT_FILES = [
    ROOT
    / "results"
    / "addpipe16_random_pilot"
    / "results.json",

    ROOT
    / "results"
    / "addpipe16_online_compare"
    / "random.json",

    ROOT
    / "results"
    / "addpipe16_online_compare"
    / "evolution.json",

    ROOT
    / "results"
    / "addpipe16_single_split"
    / "results.json",
]


def load_json(path: Path):
    if not path.is_file():
        return []

    return json.loads(
        path.read_text()
    )


def previously_measured_masks():
    masks = set()

    for path in KNOWN_RESULT_FILES:
        rows = load_json(path)

        for row in rows:
            if "boundary_mask" in row:
                masks.add(
                    int(row["boundary_mask"])
                )

    for row in load_json(HISTORY):
        masks.add(
            int(row["boundary_mask"])
        )

    return masks


def parse_mask(text: str) -> int:
    value = int(text, 0)

    if not 0 <= value <= MAX_MASK:
        raise argparse.ArgumentTypeError(
            f"{text}: mask must be between "
            f"0 and 0x{MAX_MASK:04x}"
        )

    return value


def dominates(a, b):
    return (
        a["area"] <= b["area"]
        and a["wns"] >= b["wns"]
        and (
            a["area"] < b["area"]
            or a["wns"] > b["wns"]
        )
    )


def pareto_front(rows):
    valid = [
        r
        for r in rows
        if (
            r["functional"]
            and r["formal_ok"]
            and r["place_route_ok"]
            and r["area"] is not None
            and r["wns"] is not None
        )
    ]

    return sorted(
        [
            r
            for r in valid
            if not any(
                dominates(other, r)
                for other in valid
                if other is not r
            )
        ],
        key=lambda r: (
            r["area"],
            -r["wns"],
        ),
    )


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "masks",
        nargs="+",
        type=parse_mask,
    )

    args = parser.parse_args()

    if len(set(args.masks)) != len(args.masks):
        raise SystemExit(
            "Duplicate masks supplied in this batch."
        )

    measured = previously_measured_masks()

    duplicates = [
        mask
        for mask in args.masks
        if mask in measured
    ]

    if duplicates:
        text = ", ".join(
            f"0x{x:04x}"
            for x in duplicates
        )

        raise SystemExit(
            "Already evaluated masks: "
            + text
        )

    GEN_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    OUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    history = load_json(HISTORY)

    round_number = (
        max(
            (
                int(r.get("guided_round", 0))
                for r in history
            ),
            default=0,
        )
        + 1
    )

    print(
        f"MODEL-GUIDED ROUND {round_number}"
    )

    print(
        f"Previous guided evaluations: "
        f"{len(history)}"
    )

    for index, mask in enumerate(args.masks):
        spec = CandidateSpec(mask)

        global_step = len(history)

        path = (
            GEN_DIR
            / (
                f"step_{global_step:03d}_"
                f"mask_{mask:04x}.v"
            )
        )

        write_candidate(
            spec,
            path,
        )

        print()
        print(
            f"=== proposal {index + 1}/"
            f"{len(args.masks)} "
            f"mask=0x{mask:04x} "
            f"blocks={spec.blocks} ==="
        )

        result = dict(
            evaluate(
                path.relative_to(ROOT),
                benchmark="addpipe16",
            )
        )

        result["guided_round"] = (
            round_number
        )

        result["guided_step"] = (
            global_step
        )

        result["proposer"] = (
            "GPT-5.6 Sol interactive"
        )

        result["boundary_mask"] = mask
        result["blocks"] = list(spec.blocks)

        history.append(result)

        HISTORY.write_text(
            json.dumps(
                history,
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )

        print(
            f"formal={result['formal_ok']} "
            f"route={result['place_route_ok']} "
            f"cells={result['cells']} "
            f"area={result['area']} "
            f"wns={result['wns']} "
            f"power={result['power_w']} "
            f"reward={result['proxy_reward_v0']}"
        )

    frontier = pareto_front(history)

    (
        OUT_DIR
        / "guided_pareto.json"
    ).write_text(
        json.dumps(
            frontier,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    print()
    print("==============================")
    print("GUIDED HISTORY")
    print("==============================")

    print(
        f"evaluations: {len(history)} / 16"
    )

    best = max(
        history,
        key=lambda r:
            r["proxy_reward_v0"],
    )

    print(
        f"best reward: "
        f"mask=0x{best['boundary_mask']:04x} "
        f"blocks={tuple(best['blocks'])} "
        f"area={best['area']} "
        f"WNS={best['wns']} "
        f"reward={best['proxy_reward_v0']}"
    )

    print(
        f"guided Pareto points: "
        f"{len(frontier)}"
    )


if __name__ == "__main__":
    main()
