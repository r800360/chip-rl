"""Figure: cumulative routed designs over time, with the project's milestones."""
from __future__ import annotations

import datetime as dt
import glob
import os

import matplotlib.dates as mdates
import matplotlib.pyplot as plt

from analysis.style import AXIS, BLUE, INK, INK_2, MUTED, ORANGE, ROOT, SURFACE, note, save, setup

MILESTONES = [
    ("2026-09-20 18:44", "evaluator: RTL to GDS"),
    ("2026-09-20 19:04", "reward hack found and closed"),
    ("2026-09-20 19:46", "formal equivalence gate"),
    ("2026-09-21 12:56", "Claude writes 16 verified adders"),
    ("2026-09-21 20:41", "RL environment"),
    ("2026-09-22 01:14", "hierarchical REINFORCE v2"),
    ("2026-09-22 16:34", "3 fresh widths: v2 improves 3/3"),
    ("2026-09-23 11:08", "576-query causal test: learning = frozen"),
    ("2026-09-23 11:09", "gradient bias found and fixed"),
    ("2026-09-23 13:09", "one-flip sweep finds missed design"),
    ("2026-09-23 16:19", "local vs global: 384 queries"),
    ("2026-09-24 12:51", "decomposed formal proof"),
    ("2026-09-24 13:44", "agentic Claude eval"),
]


def routed_design_times():
    """GDS write time of every routed design, excluding reproduction copies."""
    import json
    for path in glob.glob(str(ROOT / "results/evaluations/*/*.json")):
        if path.endswith(".metrics.json"):
            continue
        r = json.loads(open(path).read())
        if not r.get("place_route_ok") or r.get("candidate", "").startswith("rtl/repro/"):
            continue
        gds = ROOT / (r.get("gds") or "")
        if r.get("gds") and gds.is_file():
            yield dt.datetime.fromtimestamp(os.path.getmtime(gds))


def main():
    setup()
    times = sorted(t for t in routed_design_times())
    fig, ax = plt.subplots(figsize=(10.5, 4.6))
    ax.step(times, range(1, len(times) + 1), where="post", color=BLUE, lw=2)
    ax.set_ylabel("routed designs (GDS written)")
    ax.xaxis.set_major_locator(mdates.DayLocator())
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %d"))
    ax.xaxis.set_minor_locator(mdates.HourLocator(byhour=[6, 12, 18]))
    ymax = len(times) * 1.08
    ax.set_ylim(0, ymax)
    for i, (stamp, label) in enumerate(MILESTONES):
        t = dt.datetime.strptime(stamp, "%Y-%m-%d %H:%M")
        count = sum(1 for x in times if x <= t)
        y_text = ymax * (0.93 - 0.068 * (i % 12))
        ax.plot([t, t], [count, y_text], color=AXIS, lw=0.8, zorder=1)
        ax.scatter([t], [count], s=26, color=ORANGE, edgecolor=SURFACE, linewidth=1.2, zorder=3)
        ax.text(t, y_text, " " + label, fontsize=7.8, color=INK, va="center")
    ax.set_title(f"Sept 20 to 24: {len(times):,} designs taken from RTL to GDS")
    note(ax, "Each step is one routed GDS. All designs after the first 69 (8-bit, day one) passed simulation "
             "and formal equivalence before routing. Milestones are commit times.", y=-0.13)
    return save(fig, "timeline")


if __name__ == "__main__":
    print(main())
