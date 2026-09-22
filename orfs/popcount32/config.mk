export DESIGN_NAME = popcount32
export PLATFORM    = nangate45

export VERILOG_FILES = /work/rtl/popcount32/baseline.v
export SDC_FILE      = /work/orfs/popcount32/constraint.sdc

# Fixed floorplan across all candidates so comparisons are fair.
export DIE_AREA  = 0 0 100 100
export CORE_AREA = 5 5 95 95

export PLACE_DENSITY = 0.20
export TNS_END_PERCENT = 100
export SYNTH_REPEATABLE_BUILD = 1

export PDN_TCL = /OpenROAD-flow-scripts/flow/designs/nangate45/gcd/grid_strategy-M1-M4-M7.tcl
