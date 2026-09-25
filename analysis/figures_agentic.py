"""Figures for the agentic Claude eval."""
from __future__ import annotations

import csv
import json

import matplotlib.pyplot as plt

from analysis.agentic_eval import CONDITIONS, MODELS, TASKS
from analysis.style import (
    BLUE, GRID, INK, INK_2, MUTED, ORANGE, ROOT, SURFACE, note, save, setup,
)

LABEL = {"claude-haiku-4-5": "Haiku 4.5", "claude-sonnet-5": "Sonnet 5", "claude-opus-5": "Opus 5"}
COND = {"full_tools": ("all tools", BLUE, "o"), "pnr_only": ("place_and_route only", ORANGE, "D")}


def load():
    rows = list(csv.DictReader(open(ROOT / "results/analysis/agentic_eval_v1/episodes.csv")))
    for r in rows:
        r["delta"] = float(r["delta"]) if r["delta"] not in ("", "None") else None
        r["headroom"] = float(r["headroom"])
        r["rep"] = int(r["rep"])
    return rows


def round_half_away(x: float) -> str:
    from decimal import ROUND_HALF_UP, Decimal
    return f"{Decimal(str(x)).quantize(Decimal('0.001'), rounding=ROUND_HALF_UP):+}"


def tree_grammar_best_gain() -> float:
    """Best popcount32_tree design (same function and flow as popcount32) over the popcount32 baseline."""
    from chiprl.agentic_env import TASKS as ENV_TASKS
    best = max(json.loads(p.read_text()).get("proxy_reward_v0") or -1e9
               for p in (ROOT / "results/evaluations/popcount32_tree").glob("*.json")
               if not p.name.endswith(".metrics.json")
               and not json.loads(p.read_text())["candidate"].startswith("rtl/repro/"))
    return best - ENV_TASKS["popcount32"].baseline_result()["proxy_reward_v0"]


def outcomes(rows, summary):
    lo, hi = summary["null_edit_noise_band"]
    tree_best = tree_grammar_best_gain()
    fig, axes = plt.subplots(1, 4, figsize=(14.5, 4.5))
    for ax, task in zip(axes, TASKS):
        head = next(r["headroom"] for r in rows if r["task"] == task)
        ax.axhspan(lo, hi, color=GRID, zorder=0)
        ax.axhline(0, color=INK_2, lw=1)
        ax.axhline(head, color=MUTED, lw=1, ls="--")
        ax.text(len(MODELS) - 0.45, head, "best of all\nprior search", fontsize=7.5, color=MUTED,
                va="bottom", ha="right")
        if task == "popcount32":
            ax.axhline(tree_best, color=MUTED, lw=1, ls=":")
            ax.text(-0.5, tree_best, "tree grammar best", fontsize=7.5,
                    color=MUTED, va="bottom", ha="left")
        for i, model in enumerate(MODELS):
            for j, cond in enumerate(CONDITIONS):
                name, color, marker = COND[cond]
                for r in rows:
                    if (r["task"], r["model"], r["condition"]) != (task, model, cond) or r["delta"] is None:
                        continue
                    x = i + (-0.18 if j == 0 else 0.18) + (r["rep"] - 2) * 0.07
                    if r["best_output_registered"] == "False":
                        # Logic moved past the output register: counted, but flagged.
                        ax.scatter([x], [r["delta"]], s=46, facecolor="none", edgecolor=color, marker=marker,
                                   linewidth=1.6, zorder=3)
                        ax.annotate("output not\nregistered", xy=(x, r["delta"]), xytext=(-8, -2),
                                    textcoords="offset points", fontsize=7.5, color=INK, ha="right", va="top")
                        continue
                    ax.scatter([x], [r["delta"]], s=40, color=color, marker=marker,
                               edgecolor=SURFACE, linewidth=1.2, zorder=3)
        ax.set_xticks(range(len(MODELS)), [LABEL[m] for m in MODELS], fontsize=8.8)
        ax.set_xlim(-0.55, len(MODELS) - 0.45)
        ax.set_title(task, fontsize=10.5)
        ax.grid(axis="x", visible=False)
        vals = [r["delta"] for r in rows if r["task"] == task and r["delta"] is not None]
        low, high = min(vals + [lo]), max(vals + [head])
        pad = 0.12 * (high - low)
        ax.set_ylim(low - pad, high + 2 * pad)
    axes[0].set_ylabel("best verified score minus baseline")
    handles = [plt.Line2D([], [], color=COND[c][1], marker=COND[c][2], ls="", markersize=7,
                          label=COND[c][0]) for c in CONDITIONS]
    handles.append(plt.Rectangle((0, 0), 1, 1, color=GRID,
                                 label=f"noise floor: scores of null edits ({round_half_away(lo)} to {round_half_away(hi)})"))
    fig.legend(handles=handles, loc="upper right", ncol=3, frameon=False, fontsize=9)
    fig.suptitle("Agentic RTL optimization: one dot per episode (budget of 4 place-and-route runs)",
                 x=0.01, ha="left", fontsize=11.5, fontweight="bold", color=INK)
    note(axes[0], "A null edit leaves the synthesized netlist identical to the baseline's; its score still "
                  "moves with placement. Dots inside the band are ties.", y=-0.13)
    fig.tight_layout(rect=(0, 0, 1, 0.9), w_pad=1.4)
    return save(fig, "agentic_eval_outcomes")


def process(summary):
    table = summary["by_model_condition"]
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10.5, 3.7))
    width = 0.36
    for j, cond in enumerate(CONDITIONS):
        name, color, _ = COND[cond]
        for panel, key, fmt in ((a1, "failed_share", "{:.0f}%"), (a2, "mean_cost_usd", "${:.2f}")):
            for i, model in enumerate(MODELS):
                row = next((t for t in table if t["model"] == model and t["condition"] == cond), None)
                if not row:
                    continue
                value = 100 * row[key] if key == "failed_share" else row[key]
                x = i + (j - 0.5) * width
                panel.bar([x], [value], width=width * 0.9, color=color, edgecolor=SURFACE, linewidth=0,
                          label=name if i == 0 else None)
                panel.text(x, value * 1.02 + (0.2 if key == "failed_share" else 0.02), fmt.format(value),
                           ha="center", fontsize=8.2, color=INK_2)
    for ax in (a1, a2):
        ax.set_xticks(range(len(MODELS)), [LABEL[m] for m in MODELS])
        ax.grid(axis="x", visible=False)
    a1.set_ylabel("% of place-and-route budget")
    a1.set_title("Budget spent on designs that failed verification")
    a1.legend(loc="upper right", fontsize=8)
    a2.set_ylabel("USD per episode")
    a2.set_title("API cost per episode")
    note(a2, f"All {summary['episodes']} episodes; total ${summary['total_cost_usd']:.2f}.", y=-0.15)
    fig.tight_layout(w_pad=3)
    return save(fig, "agentic_eval_process")


if __name__ == "__main__":
    setup()
    summary = json.loads((ROOT / "results/analysis/agentic_eval_v1/summary.json").read_text())
    rows = load()
    print(outcomes(rows, summary))
    print(process(summary))
