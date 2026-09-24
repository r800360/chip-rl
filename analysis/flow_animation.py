"""Animated GIF: one design through the physical flow, from OpenROAD's own renders."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FRAMES = [
    ("final_placement.webp.png", "1  Placement: standard cells placed in rows"),
    ("cts_default_core_clock.webp.png", "2  Clock tree synthesis: clock buffers and clock nets"),
    ("final_routing.webp.png", "3  Routing: signal wires on the metal layers"),
    ("final_worst_path.webp.png", "4  Static timing: the critical path, input pin to register"),
]


def main(bench: str = "lanesum16x8_tree", eval_id: str = "4ba1e7122835b05f") -> Path:
    src = ROOT / "reports" / "nangate45" / bench / f"eval_{eval_id}"
    try:
        font = ImageFont.truetype("DejaVuSans.ttf", 26)
        small = ImageFont.truetype("DejaVuSans.ttf", 18)
    except OSError:
        font = small = ImageFont.load_default()
    frames = []
    for name, caption in FRAMES:
        img = Image.open(src / name).convert("RGB").resize((720, 720))
        canvas = Image.new("RGB", (720, 800), (252, 252, 251))
        canvas.paste(img, (0, 80))
        draw = ImageDraw.Draw(canvas)
        draw.text((18, 14), caption, fill=(11, 11, 11), font=font)
        draw.text((18, 50), "lanesum16x8_tree, all-ADD baseline, Nangate45, OpenROAD renders",
                  fill=(82, 81, 78), font=small)
        frames.append(canvas)
    out = ROOT / "docs" / "figures" / "flow_stages.gif"
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=1800, loop=0, optimize=True)
    return out


if __name__ == "__main__":
    print(main())
