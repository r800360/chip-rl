"""Compose the layout gallery from KLayout close-ups and one OpenROAD die view."""
from __future__ import annotations

import json
from pathlib import Path

import matplotlib.image as mpimg
import matplotlib.pyplot as plt

from analysis.style import INK, INK_2, MUTED, ROOT, save, setup

PANELS = [
    ("lanesum_all_add_full_die", "lanesum16x8_tree", "4ba1e7122835b05f",
     "Lane sum, all-ADD: full 200 x 200 um die"),
    ("lanesum_all_add", "lanesum16x8_tree", "4ba1e7122835b05f",
     "Lane sum, all-ADD: 30 um close-up"),
    ("lanesum_all_cla", "lanesum16x8_tree", "3b88dc6eb1853246",
     "Lane sum, all-CLA: 30 um close-up"),
    ("addpipe16_claude", "addpipe16", "80bdfb5eb43c47c8",
     "Claude's 16-bit adder: 30 um close-up"),
]


def metrics(bench: str, eval_id: str) -> str:
    r = json.loads((ROOT / "results/evaluations" / bench / f"{eval_id}.json").read_text())
    return f"area {r['area']:.0f} um^2, WNS {r['wns']:.3f} ns, {r['cells']} cells"


def main():
    setup()
    fig, axes = plt.subplots(2, 2, figsize=(9.6, 10.2))
    for ax, (name, bench, eval_id, title) in zip(axes.flat, PANELS):
        img = mpimg.imread(ROOT / "docs/figures/layouts" / f"{name}.png")
        ax.imshow(img)
        ax.set_xticks([])
        ax.set_yticks([])
        for spine in ax.spines.values():
            spine.set_visible(False)
        ax.grid(False)
        ax.set_title(title, fontsize=10, loc="left", color=INK)
        ax.text(0, -0.025, metrics(bench, eval_id), transform=ax.transAxes, fontsize=8.8,
                color=INK_2, va="top")
    fig.text(0.01, 0.008, "Rendered from the routed Nangate45 GDS (full die: OpenROAD; close-ups: KLayout with the "
             "FreePDK45 layer colors,\nfiller cells hidden, densest 30 x 30 um window of logic).",
             fontsize=8.2, color=MUTED)
    fig.tight_layout(rect=(0, 0.035, 1, 1), h_pad=2.2)
    png = save(fig, "layout_gallery")
    from PIL import Image  # the PNG is several MB; ship a JPEG instead
    im = Image.open(png).convert("RGB")
    im = im.resize((int(im.width * 0.75), int(im.height * 0.75)), Image.LANCZOS)
    jpg = png.with_suffix(".jpg")
    im.save(jpg, quality=86, optimize=True, progressive=True)
    png.unlink()
    return jpg


if __name__ == "__main__":
    print(main())
