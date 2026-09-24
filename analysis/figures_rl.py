"""Figures for the RL studies: learning-vs-frozen effects and search coverage."""
from __future__ import annotations

import csv
import json
from collections import Counter
from pathlib import Path

import matplotlib.pyplot as plt

from analysis.style import (
    AQUA, AXIS, BLUE, GRID, INK, INK_2, MUTED, ORANGE, ROOT, SURFACE, note, save, setup,
)


def _csv(rel):
    return list(csv.DictReader(open(ROOT / rel)))


def learning_effects() -> Path:
    """Paired final-reward differences: learning policy minus identical frozen policy."""
    rows = []
    for r in _csv("results/crossfamily_policy_causality_v1/paired_comparisons.csv"):
        if r["method_a"] == "v2_learn" and r["method_b"] == "v2_frozen":
            rows.append(("Cross-family (Sept 22-23)\nv2 learning vs v2 frozen", float(r["delta_a_minus_b"]),
                         r["benchmark"]))
    for r in _csv("results/popcount_tree_v3_pilot_v1/audit/paired_effects.csv"):
        if r.get("method_a") == "v3_conditioned" and r.get("method_b") == "v2_frozen":
            rows.append(("Popcount tree (Sept 23)\nv3 corrected gradient vs frozen",
                         float(r["final_reward_delta_a_minus_b"]), "popcount32_tree"))
    for r in _csv("results/popcount_freshwidth_search_v1/audit/paired_effects.csv"):
        rows.append(("Fresh widths (Sept 23)\nhybrid learning vs hybrid frozen",
                     float(r["hybrid_learning_effect"]), f"popcount{r['width']}_tree"))
    lane = ROOT / "results/learned_local_study_v1_audit/paired.csv"
    if lane.is_file():
        for r in csv.DictReader(open(lane)):
            rows.append(("Lane sum (Sept 24)\nlearned vs uniform local edits",
                         float(r["learned_local_minus_uniform"]), "lanesum16x8_tree"))
            rows.append(("Lane sum (Sept 24)\nlearned vs frozen hybrid",
                         float(r["learned_hybrid_minus_frozen"]), "lanesum16x8_tree"))

    studies = list(dict.fromkeys(r[0] for r in rows))
    fig, ax = plt.subplots(figsize=(7.2, 0.9 + 0.75 * len(studies)))
    for y, study in enumerate(reversed(studies)):
        vals = [v for s, v, _ in rows if s == study]
        counts = Counter("+" if v > 1e-9 else "-" if v < -1e-9 else "0" for v in vals)
        jitter = [((i % 5) - 2) * 0.07 for i in range(len(vals))]
        ax.scatter(vals, [y + j for j in jitter], s=46, color=BLUE, edgecolor=SURFACE,
                   linewidth=1.5, zorder=3)
        ax.text(1.02, y, f"{counts['+']} better, {counts['-']} worse, {counts['0']} tied",
                va="center", fontsize=8.5, color=INK_2, transform=ax.get_yaxis_transform())
    ax.axvline(0, color=INK_2, lw=1)
    ax.set_yticks(range(len(studies)), list(reversed(studies)), fontsize=8.5)
    ax.set_xlim(-0.16, 0.16)
    ax.set_xlabel("final reward, learning minus frozen (paired: same seed designs, same RNG)")
    ax.grid(axis="y", visible=False)
    ax.set_title("Online policy updates never produced a repeatable gain over the frozen policy")
    note(ax, "Each dot is one matched pair of 16-query runs. Frozen controls start from the "
             "identical policy and sample with the same random streams.", y=-0.16)
    return save(fig, "rl_learning_vs_frozen")


def neighborhood() -> Path:
    """The v3 pilot never sampled near its best seed; the one-flip sweep found an improvement."""
    q = _csv("results/popcount_tree_v3_pilot_v1/audit/query_trajectories.csv")
    ks = Counter(int(r["K"]) for r in q)
    flips = _csv("results/popcount_tree_oneflip_v1/results.csv")

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10.6, 3.8), gridspec_kw={"width_ratios": [1, 1.2]})
    xs = sorted(ks)
    a1.bar(xs, [ks[k] for k in xs], width=0.8, color=BLUE, edgecolor=SURFACE, linewidth=0)
    a1.axvline(31, color=ORANGE, lw=2)
    a1.text(30.6, max(ks.values()) * 0.9, "best seed\nK = 31", ha="right", fontsize=8.5, color=INK)
    a1.axvspan(24, 30.5, color=GRID, alpha=0.6, lw=0)
    a1.text(27.2, max(ks.values()) * 0.55, "never\nsampled", ha="center", fontsize=8.5, color=INK_2)
    a1.set_xlim(-0.5, 32)
    a1.set_xlabel("K = carry-lookahead nodes in proposal (of 31)")
    a1.set_ylabel("proposals")
    a1.set_title(f"192 RL proposals by distance from the best seed")
    a1.grid(axis="x", visible=False)

    level_of = lambda b: 0 if b < 16 else 1 if b < 24 else 2 if b < 28 else 3 if b < 30 else 4
    colors = [ORANGE if float(r["delta_vs_seed"]) > 0 else BLUE for r in flips]
    deltas = [1000 * float(r["delta_vs_seed"]) for r in flips]
    bits = [int(r["removed_bit"]) for r in flips]
    a2.bar(bits, deltas, width=0.75, color=colors, edgecolor=SURFACE, linewidth=0)
    a2.axhline(0, color=INK_2, lw=1)
    for lo, hi in [(16, 23.5), (28, 29.5)]:
        a2.axvspan(lo - 0.5, hi, color=GRID, alpha=0.45, lw=0, zorder=0)
    a2.set_xticks([7.5, 19.5, 25.5, 28.5, 30], ["leaf level (16 nodes)", "L1", "L2", "L3", "\nroot"],
                  fontsize=8.2)
    best = max(flips, key=lambda r: float(r["delta_vs_seed"]))
    a2.annotate(f"node {best['removed_bit']}: +{1000 * float(best['delta_vs_seed']):.1f}, "
                "replicated 3/3", xy=(int(best["removed_bit"]), 1000 * float(best["delta_vs_seed"])),
                xytext=(4, -330), fontsize=8.5, color=INK,
                arrowprops=dict(arrowstyle="-", color=MUTED, lw=0.8))
    a2.set_ylim(-900, 60)
    a2.set_xlabel("tree node switched from CLA to plain adder")
    a2.set_ylabel("reward change vs best seed (x 0.001)")
    a2.set_title("All 31 one-flip neighbors of the best seed, measured")
    a2.grid(axis="x", visible=False)
    note(a1, "popcount32_tree, Sept 23. Every proposal was at least 8 flips from the best seed.", y=-0.22)
    fig.tight_layout(w_pad=3)
    return save(fig, "rl_search_coverage")


if __name__ == "__main__":
    setup()
    print(learning_effects())
    print(neighborhood())
