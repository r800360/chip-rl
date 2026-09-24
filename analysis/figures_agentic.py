"""Figures for the agentic Claude eval."""
from __future__ import annotations

import csv
import json
import statistics

import matplotlib.pyplot as plt

from analysis.agentic_eval import CONDITIONS, MODELS, TASKS
from analysis.style import AXIS, BLUE, INK, INK_2, MUTED, ORANGE, ROOT, SURFACE, note, save, setup

LABEL = {"claude-haiku-4-5": "Haiku 4.5", "claude-sonnet-5": "Sonnet 5", "claude-opus-5": "Opus 5"}
COND = {"full_tools": ("all tools", BLUE, "o"), "pnr_only": ("place_and_route only", ORANGE, "D")}


def load():
    rows = list(csv.DictReader(open(ROOT / "results/analysis/agentic_eval_v1/episodes.csv")))
    for r in rows:
        r["delta"] = float(r["delta"]) if r["delta"] not in ("", "None") else None
        r["headroom"] = float(r["headroom"])
    return rows


def outcomes(rows):
    fig, axes = plt.subplots(1, 4, figsize=(13.5, 3.9), sharey=False)
    for ax, task in zip(axes, TASKS):
        if not any(r["task"] == task for r in rows):
            ax.set_title(f"{task} (pending)", fontsize=10.5)
            continue
        head = next(r["headroom"] for r in rows if r["task"] == task)
        ax.axhline(0, color=INK_2, lw=1)
        ax.axhline(head, color=MUTED, lw=1, ls="--")
        ax.text(2.45, head, "best from\nprior search", fontsize=7.5, color=MUTED, va="center", ha="right")
        for i, model in enumerate(MODELS):
            for j, cond in enumerate(CONDITIONS):
                name, color, marker = COND[cond]
                vals = [r["delta"] for r in rows if (r["task"], r["model"], r["condition"]) == (task, model, cond)
                        and r["delta"] is not None]
                x = i + (-0.14 if j == 0 else 0.14)
                ax.scatter([x] * len(vals), vals, s=38, color=color, marker=marker,
                           edgecolor=SURFACE, linewidth=1.2, zorder=3, alpha=0.95)
        ax.set_xticks(range(len(MODELS)), [LABEL[m] for m in MODELS], fontsize=8.5)
        ax.set_xlim(-0.5, 2.5)
        ax.set_title(task, fontsize=10.5)
        ax.grid(axis="x", visible=False)
        lo = min([r["delta"] for r in rows if r["task"] == task and r["delta"] is not None] + [0])
        ax.set_ylim(min(lo * 1.15, -0.05 * head), head * 1.35)
    axes[0].set_ylabel("best verified score minus baseline")
    for cond in CONDITIONS:
        name, color, marker = COND[cond]
        axes[0].scatter([], [], s=38, color=color, marker=marker, label=name)
    axes[0].legend(loc="lower left", fontsize=8)
    fig.suptitle("Agentic RTL optimization: each dot is one episode (4 place-and-route runs)",
                 x=0.01, ha="left", fontsize=11.5, fontweight="bold", color=INK)
    note(axes[0], "Below zero: every submitted design scored worse than the baseline and the agent never "
                  "resubmitted the baseline.", y=-0.14)
    fig.tight_layout(rect=(0, 0, 1, 0.94), w_pad=1.6)
    return save(fig, "agentic_eval_outcomes")


def process():
    s = json.loads((ROOT / "results/analysis/agentic_eval_v1/summary.json").read_text())
    table = s["by_model_condition"]
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10.5, 3.6))
    width = 0.34
    for j, cond in enumerate(CONDITIONS):
        name, color, _ = COND[cond]
        xs, share, cost = [], [], []
        for i, model in enumerate(MODELS):
            row = next((t for t in table if t["model"] == model and t["condition"] == cond), None)
            if row:
                xs.append(i + (j - 0.5) * width)
                share.append(100 * row["failed_share"])
                cost.append(row["mean_cost_usd"])
        a1.bar(xs, share, width=width * 0.9, color=color, edgecolor=SURFACE, linewidth=0, label=name)
        a2.bar(xs, cost, width=width * 0.9, color=color, edgecolor=SURFACE, linewidth=0, label=name)
        for x, v in zip(xs, share):
            a1.text(x, v + 0.8, f"{v:.0f}%", ha="center", fontsize=8.2, color=INK_2)
        for x, v in zip(xs, cost):
            a2.text(x, v * 1.03 + 0.01, f"${v:.2f}", ha="center", fontsize=8.2, color=INK_2)
    for ax in (a1, a2):
        ax.set_xticks(range(len(MODELS)), [LABEL[m] for m in MODELS])
        ax.grid(axis="x", visible=False)
    a1.set_ylabel("% of place-and-route budget")
    a1.set_title("Budget spent on designs that failed verification")
    a1.legend(loc="upper right", fontsize=8)
    a2.set_ylabel("USD per episode")
    a2.set_title("API cost per episode")
    note(a2, f"{s['episodes']} episodes, total ${s['total_cost_usd']:.2f}.", y=-0.16)
    fig.tight_layout(w_pad=3)
    return save(fig, "agentic_eval_process")


if __name__ == "__main__":
    setup()
    rows = load()
    print(outcomes(rows))
    print(process())
