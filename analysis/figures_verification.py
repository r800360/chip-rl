"""Figures about correctness: the day-one reward hack and formal-proof scaling."""
from __future__ import annotations

import csv
import json
import statistics
from pathlib import Path

import matplotlib.pyplot as plt

from analysis.style import (
    AXIS, BLUE, CRITICAL, GRID, INK, INK_2, MUTED, ORANGE, ROOT, SURFACE, note, save, setup,
)


def reward_hack():
    """Loose testbench: every spec-violating variant beat its correct twin."""
    rows = list(csv.DictReader(open(ROOT / "results/random_search/20260920_loose_spec/results.csv")))
    arch = {}
    for r in rows:
        key = r["architecture"]
        arch.setdefault(key, {})["ok" if r["gated_output"] == "True" else "hack"] = r
    names = {"behavioral": "a + b (behavioral)", "carry_select": "carry-select",
             "chunk4": "4-bit chunks", "chunk2": "2-bit chunks", "ripple": "ripple carry"}
    order = sorted(arch, key=lambda k: float(arch[k]["hack"]["proxy_reward_v0"]))

    fig, ax = plt.subplots(figsize=(7.4, 3.6))
    for y, key in enumerate(order):
        ok = float(arch[key]["ok"]["proxy_reward_v0"])
        hack = float(arch[key]["hack"]["proxy_reward_v0"])
        a_ok, a_hack = float(arch[key]["ok"]["area"]), float(arch[key]["hack"]["area"])
        ax.plot([ok, hack], [y, y], color=AXIS, lw=2, zorder=1)
        ax.scatter([ok], [y], s=64, color=BLUE, edgecolor=SURFACE, linewidth=2, zorder=3)
        ax.scatter([hack], [y], s=64, color=ORANGE, edgecolor=SURFACE, linewidth=2, zorder=3,
                   marker="D")
        ax.text(hack + 0.06, y, f"-{100 * (a_ok - a_hack) / a_ok:.0f}% area",
                va="center", fontsize=8.5, color=INK_2)
    ax.set_yticks(range(len(order)), [names[k] for k in order])
    ax.set_xlabel("proxy reward under the loose testbench (higher looks better)")
    ax.set_xlim(72.9, 76.9)
    ax.grid(axis="y", visible=False)
    ax.scatter([], [], s=64, color=BLUE, label="correct: holds y_o when valid_i is low")
    ax.scatter([], [], s=64, color=ORANGE, marker="D", label="violates spec: drops the hold enable")
    ax.legend(loc="lower right", fontsize=8.5)
    ax.set_title("Day-one reward hacking: each spec violation outscored its correct twin")
    note(ax, "8-bit registered adder, 10 random designs, Sept 20. A stricter testbench plus "
             "Yosys sequential equivalence rejects all 5 violations.", y=-0.2)
    return save(fig, "reward_hacking_loose_spec")


def formal_scaling():
    """Monolithic equivalence explodes on multi-operand sums; decomposition fixes it."""
    hard = json.loads((ROOT / "results/formal/lanesum16x8_monolithic_hardness_v1.json").read_text())
    cert = json.loads((ROOT / "results/formal/lanesum16x8_tree_reassociation_certificate_v1.json").read_text())
    per_candidate = []
    for p in (ROOT / "results/evaluations/lanesum16x8_tree").glob("*.json"):
        if p.name.endswith(".metrics.json"):
            continue
        r = json.loads(p.read_text())
        if r.get("formal_ok"):
            per_candidate.append(r["formal_runtime_s"])

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10.2, 3.9), gridspec_kw={"width_ratios": [1, 1.25]})

    # Left: original checker time grows with the number of summed operands.
    def median_formal(bench):
        vals = []
        for p in (ROOT / "results/evaluations" / bench).glob("*.json"):
            if not p.name.endswith(".metrics.json"):
                r = json.loads(p.read_text())
                if r.get("formal_ok"):
                    vals.append(r["formal_runtime_s"])
        return statistics.median(vals)

    labels = ["popcount\n16 x 1 bit", "popcount\n32 x 1 bit", "popcount\n64 x 1 bit", "lane sum\n16 x 8 bit"]
    values = [median_formal("popcount16_tree"), median_formal("popcount32_tree"),
              median_formal("popcount64_tree"), 69 * 60 + 55]
    colors = [BLUE, BLUE, BLUE, CRITICAL]
    a1.bar(range(4), values, width=0.55, color=colors, edgecolor=SURFACE, linewidth=0)
    a1.set_yscale("log")
    a1.set_xticks(range(4), labels, fontsize=8.5)
    a1.set_ylabel("seconds per proof (log)")
    a1.set_ylim(0.1, 20000)
    for i, v in enumerate(values):
        text = f"{v:.2f} s" if v < 100 else "killed at 70 min"
        a1.text(i, v * 1.35, text, ha="center", fontsize=8.5, color=INK_2)
    a1.set_title("Original checker: one monolithic proof")
    a1.grid(axis="x", visible=False)

    # Right: what each approach costs on the lane-sum benchmark.
    items = [
        ("original Yosys proof", 69 * 60 + 55, CRITICAL, True),
    ]
    for s in hard["solvers"]:
        name = {"minisat22": "MiniSat", "glucose4": "Glucose 4", "cadical195": "CaDiCaL 1.9"}[s["solver"]]
        items.append((f"{name} on the CNF", s["limit_s"], CRITICAL, s["outcome"] == "TIMEOUT"))
    items.append((f"one-time certificate\n({cert['link_count']} rewrite proofs)", cert["total_wall_s"], BLUE, False))
    items.append(("per candidate (cut points)", statistics.median(per_candidate), BLUE, False))
    ys = list(range(len(items)))[::-1]
    for y, (label, value, color, censored) in zip(ys, items):
        a2.barh(y, value, height=0.5, color=color, edgecolor=SURFACE, linewidth=0)
        text = (f">{value:,.0f} s, no result" if censored else f"{value:.2f} s")
        a2.text(value * 1.3, y, text, va="center", fontsize=8.5, color=INK_2)
    a2.set_yticks(ys, [i[0] for i in items], fontsize=8.5)
    a2.set_xscale("log")
    a2.set_xlim(0.1, 300000)
    a2.set_xlabel("seconds (log)")
    a2.grid(axis="y", visible=False)
    a2.set_title("Lane sum: monolithic vs decomposed proof")
    note(a2, f"CNF: {hard['cnf_variables']:,} variables, {hard['cnf_clauses']:,} clauses. "
             "Decomposed proofs use the same Yosys equivalence commands.", y=-0.2)
    fig.tight_layout(w_pad=3)
    return save(fig, "formal_scaling")


if __name__ == "__main__":
    setup()
    print(reward_hack())
    print(formal_scaling())
