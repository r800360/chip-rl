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
You are an autonomous RTL hardware-design search agent.

Your job is to propose exactly ONE new synthesizable Verilog candidate
for the hardware-design environment described in the user message.

Optimize based on actual observed physical-design feedback, not on
textbook reputation alone.

Requirements:

1. Return exactly one JSON object containing:
   - "name"
   - "rationale"
   - "rtl"

2. "rtl" must contain one complete synthesizable Verilog implementation
   of the required top module.

3. Preserve the exact sequential interface and semantics of the
   reference RTL.

4. Do not instantiate technology-specific cells or unavailable modules.

5. Do not merely reproduce an already-observed design. Seek a genuinely
   different implementation with a plausible physical-design reason for
   improving scalar reward or the observed Pareto frontier.

6. Learn from all previous successful and failed attempts supplied in
   the observation, including their RTL and measured results.

7. Actual quality is determined only by:
   Verilator -> formal equivalence -> OpenROAD.

8. Do not assume an architecture is fast or small merely because of its
   textbook name. Use the empirical history.

9. Commit to one promising next experiment rather than exhaustively
   debating many alternatives.

10. Keep the rationale concise. Spend the response on producing a
    complete candidate.

Output JSON only. Do not use Markdown fences.
""".strip()


def extract_text(message) -> str:
    return "\n".join(
        block.text
        for block in message.content
        if getattr(block, "type", None) == "text"
    ).strip()


def emit_metadata(message) -> None:
    usage = getattr(
        message,
        "usage",
        None,
    )

    metadata = {
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "effort": EFFORT,
        "stop_reason": getattr(
            message,
            "stop_reason",
            None,
        ),
        "content_block_types": [
            getattr(
                block,
                "type",
                type(block).__name__,
            )
            for block in message.content
        ],
        "input_tokens": getattr(
            usage,
            "input_tokens",
            None,
        ),
        "output_tokens": getattr(
            usage,
            "output_tokens",
            None,
        ),
        "request_id": getattr(
            message,
            "_request_id",
            None,
        ),
    }

    print(
        "CHIPRL_MODEL_METADATA="
        + json.dumps(
            metadata,
            sort_keys=True,
        ),
        file=sys.stderr,
    )


def main():
    observation_text = sys.stdin.read()

    try:
        observation = json.loads(
            observation_text
        )
    except json.JSONDecodeError as exc:
        raise SystemExit(
            f"Invalid observation JSON: {exc}"
        )

    client = Anthropic()

    # Use the streaming API even though this adapter only
    # needs the final accumulated message. Large max_tokens
    # values can exceed the SDK's estimated non-streaming
    # request-duration limit. Streaming also keeps the HTTP
    # connection active during long adaptive-thinking calls.
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
                "content": (
                    "Here is the complete current "
                    "hardware-search observation.\n\n"
                    + json.dumps(
                        observation,
                        indent=2,
                        sort_keys=True,
                    )
                    + "\n\n"
                    "Choose and emit exactly one "
                    "next RTL proposal."
                ),
            }
        ],
    ) as stream:
        message = stream.get_final_message()

    # Always log the provider/model configuration,
    # usage, block types, and stop reason to stderr.
    # run_rtl_agent.py preserves stderr per attempt.
    emit_metadata(message)

    text = extract_text(message)

    if not text:
        raise SystemExit(
            "Claude returned no text block. "
            f"stop_reason={message.stop_reason!r}; "
            "inspect this attempt's stderr transcript "
            "for token usage and content block types."
        )

    try:
        proposal = json.loads(text)
    except json.JSONDecodeError:
        start = text.find("{")
        end = text.rfind("}")

        if start < 0 or end <= start:
            raise SystemExit(
                "Claude produced text but no "
                "parseable JSON object."
            )

        try:
            proposal = json.loads(
                text[start:end + 1]
            )
        except json.JSONDecodeError as exc:
            raise SystemExit(
                "Claude produced malformed JSON: "
                f"{exc}"
            )

    for key in (
        "name",
        "rationale",
        "rtl",
    ):
        if key not in proposal:
            raise SystemExit(
                f"Claude proposal missing {key!r}"
            )

    if not isinstance(
        proposal["rtl"],
        str,
    ):
        raise SystemExit(
            "'rtl' must be a string"
        )

    if "module addpipe16" not in proposal["rtl"]:
        raise SystemExit(
            "Proposal does not contain "
            "'module addpipe16'"
        )

    # stdout belongs exclusively to the protocol
    # between this adapter and run_rtl_agent.py.
    print(
        json.dumps(
            proposal,
            separators=(",", ":"),
        )
    )


if __name__ == "__main__":
    main()
