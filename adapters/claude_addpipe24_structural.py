from __future__ import annotations

import json
import os
import sys

from anthropic import Anthropic


MODEL = os.environ.get(
    "CHIPRL_CLAUDE_MODEL",
    "claude-sonnet-5",
)

MAX_TOKENS = int(
    os.environ.get(
        "CHIPRL_CLAUDE_MAX_TOKENS",
        "48000",
    )
)

EFFORT = os.environ.get(
    "CHIPRL_CLAUDE_EFFORT",
    "high",
)


SYSTEM = """
You are selecting architectures in a CONTROLLED hardware-search
experiment.

You are NOT allowed to write or modify RTL.

The action space is exactly one 23-bit boundary mask. The mask represents
an ordered composition of a 24-bit adder. Bit i of the mask inserts a
block boundary after datapath bit i.

The environment uses one frozen structural RTL generator for every
algorithm. Your only action is choosing the next previously unseen mask.

Use ONLY the measurements supplied in the observation. Do not assume
that another algorithm has evaluated anything else.

Optimize:
    proxy_reward_v0 = -0.001 * area + 10 * WNS

Also consider discovery of non-dominated area/WNS tradeoffs.

Output exactly one JSON object:

{
  "mask": "0x123456",
  "rationale": "brief technical reason"
}

Requirements:
- mask must be between 0x000000 and 0x7fffff
- do not repeat a mask listed as already measured
- output JSON only
- do not output Verilog
""".strip()


def main():
    observation = json.loads(
        sys.stdin.read()
    )

    client = Anthropic()

    with client.messages.stream(
        model=MODEL,
        max_tokens=MAX_TOKENS,
        thinking={
            "type": "adaptive",
        },
        output_config={
            "effort": EFFORT,
        },
        system=SYSTEM,
        messages=[
            {
                "role": "user",
                "content": json.dumps(
                    observation,
                    indent=2,
                    sort_keys=True,
                ),
            }
        ],
    ) as stream:
        message = (
            stream.get_final_message()
        )

    text = "\n".join(
        block.text
        for block in message.content
        if getattr(
            block,
            "type",
            None,
        ) == "text"
    ).strip()

    if not text:
        raise SystemExit(
            "Claude returned no text block"
        )

    try:
        proposal = json.loads(
            text
        )
    except json.JSONDecodeError:
        start = text.find("{")
        end = text.rfind("}")

        if start < 0 or end <= start:
            raise

        proposal = json.loads(
            text[start:end + 1]
        )

    if (
        "mask" not in proposal
        or "rationale" not in proposal
    ):
        raise SystemExit(
            "Response requires mask and rationale"
        )

    mask = int(
        str(proposal["mask"]),
        0,
    )

    if not (
        0 <= mask <= 0x7fffff
    ):
        raise SystemExit(
            "Mask outside 23-bit space"
        )

    print(
        json.dumps({
            "mask":
                f"0x{mask:06x}",

            "rationale":
                str(
                    proposal[
                        "rationale"
                    ]
                ),
        })
    )


if __name__ == "__main__":
    main()
