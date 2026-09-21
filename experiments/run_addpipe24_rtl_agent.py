from __future__ import annotations

import argparse
import json
import shlex
import subprocess

from chiprl.agent_env_addpipe24 import (
    Addpipe24OpenRTLAgentEnv,
)


def parse_json_response(
    text: str,
):
    text = text.strip()

    try:
        return json.loads(
            text
        )
    except json.JSONDecodeError:
        pass

    start = text.find("{")
    end = text.rfind("}")

    if (
        start >= 0
        and end > start
    ):
        return json.loads(
            text[
                start:end + 1
            ]
        )

    raise ValueError(
        "Model response contained "
        "no parseable JSON object"
    )


def main():
    parser = (
        argparse.ArgumentParser()
    )

    parser.add_argument(
        "--run-id",
        required=True,
    )

    parser.add_argument(
        "--budget",
        type=int,
        default=16,
    )

    parser.add_argument(
        "--command",
        required=True,
    )

    args = parser.parse_args()

    env = (
        Addpipe24OpenRTLAgentEnv(
            run_id=args.run_id,
            budget=args.budget,
        )
    )

    command = shlex.split(
        args.command
    )

    transcript_dir = (
        env.run_dir
        / "model_transcript"
    )

    transcript_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    while not env.done:
        step = env.attempts_used

        observation = (
            env.observe()
        )

        (
            transcript_dir
            / f"observation_{step:03d}.json"
        ).write_text(
            json.dumps(
                observation,
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )

        print()
        print("=" * 72)
        print(
            f"OPEN RTL ATTEMPT "
            f"{step + 1}/{args.budget}"
        )
        print("=" * 72)

        proc = subprocess.run(
            command,
            input=json.dumps(
                observation
            ),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        (
            transcript_dir
            / f"response_{step:03d}.txt"
        ).write_text(
            proc.stdout
        )

        (
            transcript_dir
            / f"stderr_{step:03d}.txt"
        ).write_text(
            proc.stderr
        )

        if proc.returncode != 0:
            raise RuntimeError(
                "Model command failed:\n"
                + proc.stderr
            )

        proposal = (
            parse_json_response(
                proc.stdout
            )
        )

        print(
            "proposal:",
            proposal.get(
                "name"
            ),
        )

        print(
            "rationale:",
            proposal.get(
                "rationale"
            ),
        )

        record = env.step(
            proposal
        )

        print(
            "status:",
            record["status"],
        )

        result = record.get(
            "result"
        )

        if result:
            print(
                "functional=",
                result[
                    "functional"
                ],
                "formal=",
                result[
                    "formal_ok"
                ],
                "route=",
                result[
                    "place_route_ok"
                ],
            )

            if result[
                "place_route_ok"
            ]:
                print(
                    "cells=",
                    result["cells"],
                    "area=",
                    result["area"],
                    "wns=",
                    result["wns"],
                    "power=",
                    result["power_w"],
                    "reward=",
                    result[
                        "proxy_reward_v0"
                    ],
                )

        if record.get(
            "feedback_tail"
        ):
            print()
            print(
                record[
                    "feedback_tail"
                ]
            )

    print()
    print("=" * 72)
    print(
        "ADDPIPE24 OPEN RTL RUN COMPLETE"
    )
    print("=" * 72)

    print(
        "attempts:",
        env.attempts_used,
    )

    print(
        "successful physical designs:",
        len(
            env.successful_agent_rows()
        ),
    )

    print(
        "combined frontier points:",
        len(
            env.current_frontier()
        ),
    )

    best = (
        env.current_bests()[
            "best_proxy_reward"
        ]
    )

    best_label = (
        best.get("agent_name")
        or best.get("mask")
        or best.get("candidate")
        or "unknown"
    )

    print(
        "best reward:",
        best["proxy_reward_v0"],
        best_label,
    )

    print(
        "state:",
        env.state_path,
    )


if __name__ == "__main__":
    main()
