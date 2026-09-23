"""Additive, power-of-two popcount-tree grammar for fresh 16/64-bit tasks.

The existing popcount32_tree generator and all frozen RL source files remain
untouched. Bit order is bottom-up, left-to-right at every reduction layer.
0 means width-sized arithmetic addition; 1 means explicit CLA equations.
"""
from __future__ import annotations

from pathlib import Path

FRESH_WIDTHS = (16, 64)
SUPPORTED_WIDTHS = (16, 32, 64)  # 32 used ONLY for historical equivalence audit.


def name(width: int) -> str:
    _check_width(width)
    return f"popcount{width}_tree"


def _check_width(width: int) -> None:
    if width not in SUPPORTED_WIDTHS:
        raise ValueError(f"This frozen grammar supports {SUPPORTED_WIDTHS}: got {width}")


def mask_bits(width: int) -> int:
    _check_width(width)
    return width - 1


def mask_digits(width: int) -> int:
    return (mask_bits(width) + 3) // 4


def validate(width: int, mask: int) -> int:
    mask = int(mask)
    if not 0 <= mask < (1 << mask_bits(width)):
        raise ValueError(f"Mask out of {mask_bits(width)}-bit range: {mask}")
    return mask


def pilot_masks(width: int) -> tuple[int, ...]:
    """Eight width-scaled counterparts of the original 32-bit frozen pilot."""
    b = mask_bits(width)
    levels = width.bit_length() - 1
    assert levels >= 4
    root = 1 << (b - 1)
    top2 = ((1 << 3) - 1) << (b - 3)
    top3 = ((1 << 7) - 1) << (b - 7)
    leaf_layer = (1 << (width // 2)) - 1
    alternating = sum(1 << j for j in range(0, b, 2))
    complement = ((1 << b) - 1) ^ alternating
    masks = (0, (1 << b) - 1, root, top2, top3,
             leaf_layer, alternating, complement)
    assert len(masks) == len(set(masks)) == 8
    assert all(validate(width, m) == m for m in masks)
    return masks


def render(width: int, mask: int) -> str:
    """Generate exact single-cycle, invalid-hold RTL with a width-specific tree."""
    mask = validate(width, mask)
    b = mask_bits(width)
    out_width = width.bit_length()
    nm = name(width)
    lines = [
        f"// Independent experimental benchmark; {b}-node balanced popcount tree.",
        f"// architecture_mask = 0x{mask:0{mask_digits(width)}x}",
        f"module {nm} (",
        "  input wire clk, rst_n, valid_i,",
        f"  input wire [{width - 1}:0] a_i, b_i,",
        "  output reg valid_o,",
        f"  output reg [{out_width - 1}:0] y_o",
        ");",
        "",
    ]
    nodes = []
    for i in range(width):
        leaf = f"leaf_{i}"
        lines.append(f"wire [0:0] {leaf} = a_i[{i}];")
        nodes.append((leaf, 1))
    lines.append("")
    node_index = 0
    for level in range(width.bit_length() - 1):
        next_nodes = []
        assert len(nodes) % 2 == 0
        for pair in range(len(nodes) // 2):
            (left, lw), (right, rw) = nodes[2 * pair:2 * pair + 2]
            assert lw == rw == level + 1
            w = lw
            node = f"n_{level}_{pair}"
            selected = bool(mask & (1 << node_index))
            lines.append(f"// node {node_index}: {'CLA' if selected else 'ADD'}")
            if not selected:
                lines.append(
                    f"wire [{w}:0] {node} = "
                    f"{{1'b0,{left}}} + {{1'b0,{right}}};"
                )
            else:
                for bit in range(w):
                    lines.append(
                        f"wire p_{node_index}_{bit} = {left}[{bit}] ^ {right}[{bit}];"
                    )
                    lines.append(
                        f"wire g_{node_index}_{bit} = {left}[{bit}] & {right}[{bit}];"
                    )
                lines.append(f"wire [{w}:0] {node};")
                lines.append(f"assign {node}[0] = p_{node_index}_0;")
                for bit in range(1, w + 1):
                    terms = []
                    for generated in range(bit - 1, -1, -1):
                        term = f"g_{node_index}_{generated}"
                        for propagated in range(generated + 1, bit):
                            term += f" & p_{node_index}_{propagated}"
                        terms.append(f"({term})")
                    carry = " | ".join(terms)
                    if bit < w:
                        lines.append(
                            f"assign {node}[{bit}] = p_{node_index}_{bit} ^ ({carry});"
                        )
                    else:
                        lines.append(f"assign {node}[{w}] = {carry};")
            next_nodes.append((node, w + 1))
            node_index += 1
        nodes = next_nodes
        lines.append("")
    assert node_index == b and len(nodes) == 1 and nodes[0][1] == out_width
    lines += [
        "always @(posedge clk) begin",
        "  if (!rst_n) begin",
        "    valid_o <= 1'b0;",
        f"    y_o <= {out_width}'d0;",
        "  end else begin",
        "    valid_o <= valid_i;",
        "    if (valid_i)",
        f"      y_o <= {nodes[0][0]};",
        "  end",
        "end",
        "endmodule",
        "",
    ]
    return "\n".join(lines)


def write_candidate(width: int, mask: int, path: str | Path) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render(width, mask))
    return path


def reference(width: int) -> str:
    _check_width(width)
    y = width.bit_length()
    return f"""// Width-{width} independent behavioral oracle; b_i is reserved/ignored.
module {name(width)}_ref (
    input wire clk, rst_n, valid_i,
    input wire [{width - 1}:0] a_i, b_i,
    output reg valid_o,
    output reg [{y - 1}:0] y_o
);
reg [{y - 1}:0] computed;
integer i;
always @* begin
    computed = {y}'d0;
    for (i = 0; i < {width}; i = i + 1)
        computed = computed + a_i[i];
end
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= {y}'d0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= computed;
    end
end
endmodule
"""


def testbench(width: int) -> str:
    _check_width(width)
    y = width.bit_length()
    all_ones = (1 << width) - 1
    alt = sum(1 << i for i in range(0, width, 2))
    salt = int(("a55a" * ((width + 15) // 16))[:width // 4], 16)
    a0 = int(("0123456789abcdef" * ((width + 63) // 64))[:width // 4], 16)
    a1 = (1 << (width - 1)) | 1
    # 64-bit Xorshift source is wide enough to populate either input width.
    return f"""`timescale 1ns/1ps
module tb;
logic clk, rst_n, valid_i;
logic [{width - 1}:0] a_i, b_i;
wire valid_o;
wire [{y - 1}:0] y_o;
logic [{y - 1}:0] last_y;
logic [63:0] rng;
{name(width)} dut (.*);
initial clk = 1'b0;
always #5 clk = ~clk;
function automatic [63:0] next_rng(input [63:0] x);
  reg [63:0] t;
  begin
    t = x; t = t ^ (t << 13); t = t ^ (t >> 7); t = t ^ (t << 17);
    next_rng = t;
  end
endfunction

task automatic check(input [{width - 1}:0] a, input [{width - 1}:0] b);
  logic [{y - 1}:0] expected;
  begin
    expected = $countones(a);
    @(negedge clk);
    a_i = a; b_i = b; valid_i = 1'b1;
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== expected)
      $fatal(1, "valid result mismatch: a=%h b=%h got=%h expected=%h", a,b,y_o,expected);
    last_y = expected;
    @(negedge clk);
    a_i = ~a; b_i = b ^ {width}'h{salt:0{width // 4}x}; valid_i = 1'b0;
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== last_y)
      $fatal(1, "invalid-cycle output was not held");
  end
endtask

task automatic back_to_back(input [{width - 1}:0] a0, b0, a1, b1);
  logic [{y - 1}:0] expected;
  begin
    @(negedge clk);
    a_i = a0; b_i = b0; valid_i = 1'b1;
    expected = $countones(a0);
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== expected)
      $fatal(1, "first back-to-back result failed");
    @(negedge clk);
    a_i = a1; b_i = b1; valid_i = 1'b1;
    expected = $countones(a1);
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== expected)
      $fatal(1, "second back-to-back result failed");
    last_y = expected;
  end
endtask

initial begin
  rst_n = 1'b0; valid_i = 1'b0; a_i = 0; b_i = 0;
  last_y = {y}'d0; rng = 64'h243f6a8885a308d3;
  repeat (3) begin
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== {y}'d0)
      $fatal(1, "reset protocol failed");
  end
  @(negedge clk); rst_n = 1'b1;
  check({width}'h{0:0{width // 4}x}, {width}'h{0:0{width // 4}x});
  check({width}'h{all_ones:0{width // 4}x}, {width}'h{1:0{width // 4}x});
  check({width}'h{1 << (width - 1):0{width // 4}x}, {width}'h{(1 << (width - 1)) - 1:0{width // 4}x});
  check({width}'h{alt:0{width // 4}x}, {width}'h{all_ones ^ alt:0{width // 4}x});
  check({width}'h{1:0{width // 4}x}, {width}'h{0:0{width // 4}x});
  for (int i = 0; i < 10000; i = i + 1) begin
    rng = next_rng(rng); a_i = rng[{width - 1}:0];
    rng = next_rng(rng); b_i = rng[{width - 1}:0];
    check(a_i, b_i);
  end
  back_to_back({width}'h{a0:0{width // 4}x}, {width}'h{all_ones ^ a0:0{width // 4}x},
               {width}'h{a1:0{width // 4}x}, {width}'h{0:0{width // 4}x});
  $display("PASS {name(width)} randomized+protocol");
  $finish;
end
endmodule
"""


def config(width: int) -> str:
    _check_width(width)
    die = {16:80, 32:100, 64:150}[width]
    core = die - 5
    nm = name(width)
    return f"""export DESIGN_NAME = {nm}
export PLATFORM    = nangate45
export VERILOG_FILES = /work/rtl/{nm}/baseline.v
export SDC_FILE      = /work/orfs/{nm}/constraint.sdc
# Constant floorplan and density across the eight candidates of this width.
export DIE_AREA  = 0 0 {die} {die}
export CORE_AREA = 5 5 {core} {core}
export PLACE_DENSITY = 0.20
export TNS_END_PERCENT = 100
export SYNTH_REPEATABLE_BUILD = 1
export PDN_TCL = /OpenROAD-flow-scripts/flow/designs/nangate45/gcd/grid_strategy-M1-M4-M7.tcl
"""


def sdc(width: int) -> str:
    _check_width(width)
    nm = name(width)
    return f"""current_design {nm}
set clk_name core_clock
set clk_port_name clk
set clk_period 10.0
set clk_io_pct 0.2
set clk_port [get_ports $clk_port_name]
create_clock -name $clk_name -period $clk_period $clk_port
set clk_io_name vclk_$clk_name
create_clock -name $clk_io_name -period $clk_period
set_clock_latency 0.070 [get_clocks $clk_name]
set_clock_latency 0.070 [get_clocks $clk_io_name]
set non_clock_inputs [all_inputs -no_clocks]
set_input_delay [expr $clk_period * $clk_io_pct] -clock $clk_io_name $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock $clk_io_name [all_outputs]
"""


def benchmark(width: int):
    """Return a transient Benchmark object without changing frozen registries."""
    _check_width(width)
    from chiprl.benchmarks import Benchmark, ROOT
    nm = name(width)
    return Benchmark(
        name=nm,
        top_module=nm,
        reference_top=f"{nm}_ref",
        testbench=ROOT / "sim" / f"tb_{nm}.sv",
        reference=ROOT / "rtl/reference" / f"{nm}_ref.v",
        orfs_config_host=ROOT / "orfs" / nm / "config.mk",
        orfs_config_container=f"/work/orfs/{nm}/config.mk",
        sdc=ROOT / "orfs" / nm / "constraint.sdc",
        pass_marker=f"PASS {nm} randomized+protocol",
    )
