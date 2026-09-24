#!/usr/bin/env bash
# Render close-up layout images from routed GDS with KLayout inside the ORFS image,
# then compose docs/figures/layout_gallery.png.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=docs/figures/layouts
mkdir -p "$OUT"

render() {  # name benchmark_dir eval_id window_um
  local name=$1 bench=$2 id=$3 window=$4
  local d=results/nangate45/$bench/eval_$id
  docker run --rm -u "$(id -u):$(id -g)" -e QT_QPA_PLATFORM=offscreen -v "$PWD:/work" -w /work \
    "${OR_IMAGE:-openroad/orfs:local}" bash -c \
    "klayout -zz -r analysis/klayout_render.py -rd gds=$d/6_final.gds -rd def_=$d/6_final.def \
     -rd out=$OUT/$name.png -rd size=1100 -rd window=$window" | tail -1
}

render lanesum_all_add   lanesum16x8_tree 4ba1e7122835b05f 30
render lanesum_all_cla   lanesum16x8_tree 3b88dc6eb1853246 30
render addpipe16_claude  addpipe16        80bdfb5eb43c47c8 30
render popcount32_all_cla popcount32_tree c09e8884b6c7b6ba 30
cp reports/nangate45/lanesum16x8_tree/eval_4ba1e7122835b05f/final_routing.webp.png "$OUT/lanesum_all_add_full_die.png"

. .venv/bin/activate
python -m analysis.figures_layouts
