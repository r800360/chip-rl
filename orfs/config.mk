export DESIGN_NAME = addpipe
export PLATFORM    = nangate45

# /work is ~/fpga/chip-rl because docker_shell maps the
# current working directory there.
export VERILOG_FILES = /work/rtl/addpipe.v
export SDC_FILE      = /work/orfs/constraint.sdc

# Give this extremely small toy design a fixed, reasonable floorplan.
# Using utilization-based sizing can make tiny designs too small for PDN.
export DIE_AREA  = 0 0 40 40
export CORE_AREA = 5 5 35 35

export PLACE_DENSITY = 0.20
export TNS_END_PERCENT = 100
export SYNTH_REPEATABLE_BUILD = 1

# Reuse the Nangate45 GCD power-grid recipe, which is designed
# for a small block.
export PDN_TCL = /OpenROAD-flow-scripts/flow/designs/nangate45/gcd/grid_strategy-M1-M4-M7.tcl
