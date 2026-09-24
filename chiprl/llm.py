"""Claude API helpers: credentials, per-model request settings and pricing."""
from __future__ import annotations

import os
from pathlib import Path

from chiprl.benchmarks import ROOT

# USD per million tokens: (input, output, cache write 5 min, cache read)
PRICES = {
    "claude-haiku-4-5": (1.00, 5.00, 1.25, 0.10),
    "claude-sonnet-5": (2.00, 10.00, 2.50, 0.20),
    "claude-opus-5": (5.00, 25.00, 6.25, 0.50),
    "claude-opus-5-5": (4.00, 20.00, 5.00, 0.20),
    "claude-fable-5-1": (10.00, 50.00, 12.50, 0.25),
}


def load_api_key() -> None:
    """Use ANTHROPIC_API_KEY if set, else CLAUDE_KEY from resources/.env."""
    if os.environ.get("ANTHROPIC_API_KEY"):
        return
    env = ROOT / "resources" / ".env"
    if env.is_file():
        for line in env.read_text().splitlines():
            key, _, value = line.partition("=")
            if key.strip() in ("CLAUDE_KEY", "ANTHROPIC_API_KEY") and value.strip():
                os.environ["ANTHROPIC_API_KEY"] = value.strip().strip('"').strip("'")
                return
    raise RuntimeError("No Anthropic API key: set ANTHROPIC_API_KEY or resources/.env")


def request_settings(model: str, effort: str = "high") -> dict:
    """Thinking/effort parameters that each model accepts."""
    if model == "claude-haiku-4-5":
        # Haiku 4.5 takes a fixed thinking budget and rejects `effort`.
        return {"thinking": {"type": "enabled", "budget_tokens": 8000}}
    return {"thinking": {"type": "adaptive"}, "output_config": {"effort": effort}}


def cost_usd(model: str, usage: dict) -> float:
    inp, out, write, read = PRICES[model]
    return (
        usage.get("input_tokens", 0) * inp
        + usage.get("output_tokens", 0) * out
        + usage.get("cache_creation_input_tokens", 0) * write
        + usage.get("cache_read_input_tokens", 0) * read
    ) / 1e6
