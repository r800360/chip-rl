export DESIGN_NAME = popcount16_tree
export PLATFORM    = nangate45
export VERILOG_FILES = /work/rtl/popcount16_tree/baseline.v
export SDC_FILE      = /work/orfs/popcount16_tree/constraint.sdc
# Constant floorplan and density across the eight candidates of this width.
export DIE_AREA  = 0 0 80 80
export CORE_AREA = 5 5 75 75
export PLACE_DENSITY = 0.20
export TNS_END_PERCENT = 100
export SYNTH_REPEATABLE_BUILD = 1
export PDN_TCL = /OpenROAD-flow-scripts/flow/designs/nangate45/gcd/grid_strategy-M1-M4-M7.tcl
