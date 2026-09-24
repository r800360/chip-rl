"""Figure: how early in the flow is the final score predictable?"""
from __future__ import annotations

import csv
import statistics
from collections import defaultdict

import matplotlib.pyplot as plt

from analysis.style import (
    AXIS, BLUE, GRID, INK, INK_2, MUTED, ORANGE, ROOT, SURFACE, note, save, setup,
)

STAGES = ["synth", "floorplan", "global_place", "detailed_place", "cts", "global_route"]
LABELS = {"synth": "synthesis", "floorplan": "floorplan", "global_place": "global pl.",
          "detailed_place": "detail pl.", "cts": "CTS", "global_route": "global rt."}


def main():
    setup()
    base = ROOT / "results/analysis/multifidelity_v1"
    fid = list(csv.DictReader(open(base / "fidelity.csv")))
    runs = list(csv.DictReader(open(base / "runs.csv")))

    by_bench = defaultdict(dict)
    for r in fid:
        by_bench[r["benchmark"]][r["stage"]] = r

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(11, 4.2), gridspec_kw={"width_ratios": [1.3, 1]})

    # Left: Spearman rho per stage; tick labels carry the share of flow time.
    frac = [statistics.median(float(by_bench[b][s]["median_cum_time_frac"]) for b in by_bench)
            for s in STAGES]
    xs = list(range(len(STAGES)))
    for bench, stages in by_bench.items():
        a1.plot(xs, [float(stages[s]["spearman_rho"]) for s in STAGES],
                color=AXIS, lw=1, alpha=0.9, zorder=1)
    med = [statistics.median(float(by_bench[b][s]["spearman_rho"]) for b in by_bench) for s in STAGES]
    a1.plot(xs, med, color=BLUE, lw=2, zorder=3, marker="o", markersize=7,
            markeredgecolor=SURFACE, markeredgewidth=2)
    a1.set_xticks(xs, [f"{LABELS[s]}\n{100 * f:.0f}%" for s, f in zip(STAGES, frac)],
                  fontsize=8.2)
    a1.set_xlabel("flow stage (share of full-flow tool time used so far)")
    a1.annotate(f"floorplan: median rho {med[1]:.2f}", xy=(1, med[1]), xytext=(1.5, 0.45),
                fontsize=8.5, color=INK, arrowprops=dict(arrowstyle="-", color=MUTED, lw=0.8))
    a1.annotate(f"synthesis area alone: median rho {med[0]:.2f}", xy=(0, med[0]),
                xytext=(0.35, -0.45), fontsize=8.5, color=INK,
                arrowprops=dict(arrowstyle="-", color=MUTED, lw=0.8))
    a1.axhline(0, color=AXIS, lw=0.8)
    a1.set_xlim(-0.3, len(STAGES) - 0.7)
    a1.set_ylim(-1.0, 1.08)
    a1.set_ylabel("Spearman rho with final routed score")
    a1.set_title(f"Rank fidelity of stage proxies ({len(by_bench)} benchmarks)")
    a1.plot([], [], color=AXIS, lw=1, label="one benchmark")
    a1.plot([], [], color=BLUE, lw=2, marker="o", label="median")
    a1.legend(loc="lower right")

    # Right: one benchmark's floorplan proxy vs final score.
    bench = "cmp32"
    pts = [r for r in runs if r["benchmark"] == bench]
    fp = [10 * float(r["floorplan_wns"]) - 0.001 * float(r["floorplan_area"]) for r in pts]
    fin = [float(r["final_reward"]) for r in pts]
    a2.scatter(fp, fin, s=22, color=BLUE, alpha=0.75, edgecolor=SURFACE, linewidth=0.8, zorder=2)
    best = max(range(len(fin)), key=lambda i: fin[i])
    a2.scatter([fp[best]], [fin[best]], s=70, color=ORANGE, edgecolor=SURFACE, linewidth=2,
               marker="D", zorder=3, label="best routed design")
    cut = sorted(fp, reverse=True)[max(0, round(0.25 * len(fp)) - 1)]
    a2.axvline(cut, color=MUTED, lw=0.8)
    a2.text(cut, min(fin), "  keep top 25%\n  by floorplan proxy", fontsize=8, color=INK_2, va="bottom")
    r = by_bench[bench]["floorplan"]
    a2.margins(0.06)
    a2.set_title(f"{bench}: floorplan proxy vs final (rho {float(r['spearman_rho']):.2f})")
    a2.set_xlabel("floorplan-stage proxy score")
    a2.set_ylabel("final post-route score")
    a2.legend(loc="upper left")

    kept = sum(by_bench[b]["floorplan"]["true_best_kept_at_25pct"] == "True" for b in by_bench)
    note(a1, f"{len(runs):,} routed designs. Screening to the top 25% by floorplan proxy kept "
             f"the true best design in {kept}/{len(by_bench)} benchmarks.", y=-0.27)
    fig.tight_layout(w_pad=2)
    return save(fig, "multifidelity_proxy")


if __name__ == "__main__":
    print(main())
