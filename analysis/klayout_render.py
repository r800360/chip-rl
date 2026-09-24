"""KLayout batch script: render a routed GDS, zoomed to the placed logic.

Runs inside the ORFS container (KLayout 0.30):
  klayout -zz -r analysis/klayout_render.py \
      -rd gds=<6_final.gds> -rd def=<6_final.def> -rd out=<png> [-rd size=1400]
Filler, tap and I/O buffer cells are ignored when computing the zoom window.
"""
import re

import pya  # provided by KLayout

LYP = "/OpenROAD-flow-scripts/flow/platforms/nangate45/FreePDK45.lyp"


def logic_bbox(def_path, margin_um=4.0):
    text = open(def_path).read()
    units = float(re.search(r"UNITS DISTANCE MICRONS (\d+)", text).group(1))
    comps = text[text.index("COMPONENTS"):text.index("END COMPONENTS")]
    xs, ys = [], []
    for m in re.finditer(r"-\s+(\S+)\s+(\S+)\s+.*?(?:PLACED|FIXED)\s+\(\s*(-?\d+)\s+(-?\d+)\s*\)", comps):
        cell = m.group(2)
        if cell.startswith(("FILLCELL", "TAPCELL", "BUF_", "CLKBUF_")):
            continue
        xs.append(int(m.group(3)) / units)
        ys.append(int(m.group(4)) / units)
    window = float(globals().get("window", "0"))
    if window > 0:  # densest square window of logic cells
        best = max(((sum(1 for u, v in zip(xs, ys) if x <= u < x + window and y <= v < y + window), x, y)
                    for x in xs for y in ys), key=lambda t: t[0])
        _, x, y = best
        return pya.DBox(x - 2, y - 2, x + window, y + window)
    x1, x2, y1, y2 = min(xs), max(xs), min(ys), max(ys)
    # square window around the logic
    cx, cy = (x1 + x2) / 2, (y1 + y2) / 2
    half = max(x2 - x1, y2 - y1) / 2 + margin_um
    return pya.DBox(cx - half, cy - half, cx + half, cy + half)


size = int(globals().get("size", "1400"))
layout = pya.Layout()  # standalone layouts are editable
layout.read(gds)  # noqa: F821  (set by -rd)
top = layout.top_cell()
# Drop filler cells so placed logic and routing are visible.
for inst in [i for i in top.each_inst() if i.cell.name.startswith("FILLCELL")]:
    inst.delete()
view = pya.LayoutView()
view.show_layout(layout, True)
view.load_layer_props(LYP)
view.max_hier()
view.set_config("background-color", "#0d0d0d")
view.set_config("grid-visible", "false")
view.set_config("text-visible", "false")
box = logic_bbox(def_)  # noqa: F821
view.zoom_box(box)
view.save_image_with_options(out, size, size, 0, 2, 0, box, False)  # noqa: F821
print("rendered", out, box)
