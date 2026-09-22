export DESIGN_NAME = addpipe40
export PLATFORM    = nangate45

export VERILOG_FILES = /work/rtl/addpipe40/baseline.v
export SDC_FILE      = /work/orfs/addpipe40/constraint.sdc

# Fixed floorplan across all candidates so comparisons are fair.
export DIE_AREA  = 0 0 120 120
export CORE_AREA = 5 5 115 115

export PLACE_DENSITY = 0.20
export TNS_END_PERCENT = 100
export SYNTH_REPEATABLE_BUILD = 1

export PDN_TCL = /OpenROAD-flow-scripts/flow/designs/nangate45/gcd/grid_strategy-M1-M4-M7.tcl
