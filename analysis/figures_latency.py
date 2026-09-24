"""Figure: where one evaluation spends its time, and throughput vs parallel workers."""
from __future__ import annotations

import json

import matplotlib.pyplot as plt

from analysis.style import (
    AQUA, AXIS, BLUE, GREEN, INK, INK_2, MAGENTA, MUTED, ORANGE, ROOT, SURFACE, VIOLET, YELLOW,
    note, save, setup,
)


def main():
    setup()
    s = json.loads((ROOT / "results/eda_latency_v1/summary.json").read_text())
    m = s["median_seconds_single_worker"]
    parts = [
        ("Verilator build + 10k-transaction sim", m["verilator_build_and_sim"], BLUE),
        ("formal equivalence", m["formal_equivalence"], ORANGE),
        ("synthesis", m["stage_synth"], AQUA),
        ("floorplan", m["stage_floorplan"], YELLOW),
        ("placement", m["stage_global_place"] + m["stage_detailed_place"], MAGENTA),
        ("CTS + global route", m["stage_cts"] + m["stage_global_route"], GREEN),
        ("detailed route, fill, GDS, reports", m["stage_final"], VIOLET),
        ("container and flow overhead", m["orfs_overhead"], AXIS),
    ]
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(11, 3.9), gridspec_kw={"width_ratios": [1.45, 1]})
    left = 0.0
    for label, value, color in parts:
        a1.barh(0, value, left=left, height=0.42, color=color, edgecolor=SURFACE, linewidth=2)
        left += value
    total = left
    # legend rows below the bar, in order
    for i, (label, value, color) in enumerate(parts):
        y = -0.55 - 0.16 * i
        a1.scatter([0.4], [y], s=60, marker="s", color=color, clip_on=False)
        a1.text(1.0, y, f"{label}: {value:.1f} s ({100 * value / total:.0f}%)", va="center",
                fontsize=8.6, color=INK_2)
    a1.set_ylim(-1.9, 0.4)
    a1.set_yticks([])
    a1.set_xlim(0, total * 1.02)
    a1.set_xlabel("seconds (median over 32 designs, one worker)")
    a1.grid(axis="y", visible=False)
    a1.spines["left"].set_visible(False)
    a1.set_title(f"One verified evaluation: {total:.0f} s")

    thr = s["throughput"]
    workers = sorted(int(w) for w in thr)
    rate = [thr[str(w)]["designs_per_hour"] for w in workers]
    base = rate[0]
    a2.plot(workers, [base * w for w in workers], color=AXIS, lw=1.2, ls="--", label="linear scaling")
    a2.plot(workers, rate, color=BLUE, lw=2, marker="o", markersize=7, markeredgecolor=SURFACE,
            markeredgewidth=2, label="measured")
    for w, r in zip(workers, rate):
        a2.text(w, r + base * 0.6, f"{r:.0f}/h", ha="center", fontsize=8.5, color=INK)
    a2.set_xscale("log", base=2)
    a2.set_xticks(workers, [str(w) for w in workers])
    a2.set_ylim(0, max(rate) * 1.35)
    a2.set_xlabel("parallel worker processes")
    a2.set_ylabel("designs per hour")
    a2.set_title("Throughput with parallel workers")
    a2.legend(loc="upper left")
    ident = "all runs bit-identical to frozen results" if s["all_runs_identical_to_frozen"] else "NOT identical"
    note(a2, f"{s['cpu_count']} logical CPUs; {ident}.", y=-0.2)
    fig.tight_layout(w_pad=3)
    return save(fig, "eda_latency")


if __name__ == "__main__":
    print(main())
