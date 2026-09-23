"""Additive non-popcount task: sum sixteen unsigned 8-bit lanes.

Eight lanes arrive in each 64-bit input. The fifteen internal reduction
nodes independently select ordinary addition (0) or explicit CLA (1).
The tree topology and operator grammar deliberately match popcount-tree,
so this tests *functional transfer*, not transfer to a new topology.
Never modify previously frozen popcount generators or benchmarks.
"""
from __future__ import annotations

from pathlib import Path

NAME = 'lanesum16x8_tree'
BITS = 15
PILOT_MASKS = (0x0000, 0x7fff, 0x4000, 0x7000,
               0x7f00, 0x00ff, 0x5555, 0x2aaa)


def validate(mask: int) -> int:
    mask = int(mask)
    if not 0 <= mask < (1 << BITS):
        raise ValueError(f'Expected a 15-bit mask: {mask}')
    return mask


def render(mask: int) -> str:
    mask = validate(mask)
    lines = [
        '// Independent experimental circuit: 16 unsigned 8-bit lane sum.',
        f'// architecture_mask = 0x{mask:04x}',
        f'module {NAME} (',
        '  input wire clk, rst_n, valid_i,',
        '  input wire [63:0] a_i, b_i,',
        '  output reg valid_o,',
        '  output reg [11:0] y_o',
        ');',
        '',
    ]
    nodes = []
    for i in range(16):
        leaf = f'leaf_{i}'
        source = 'a_i' if i < 8 else 'b_i'
        lane = i if i < 8 else i - 8
        lines.append(f'wire [7:0] {leaf} = {source}[{8*lane+7}:{8*lane}];')
        nodes.append((leaf, 8))
    lines.append('')
    node_index = 0
    for level in range(4):
        nxt = []
        for pair in range(len(nodes) // 2):
            (left, lw), (right, rw) = nodes[2*pair:2*pair+2]
            assert lw == rw == 8 + level
            w = lw
            node = f'n_{level}_{pair}'
            cla = bool(mask & (1 << node_index))
            lines.append(f"// node {node_index}: {'CLA' if cla else 'ADD'}")
            if not cla:
                lines.append(f"wire [{w}:0] {node} = {{1'b0,{left}}} + {{1'b0,{right}}};")
            else:
                for bit in range(w):
                    lines.append(f'wire p_{node_index}_{bit} = {left}[{bit}] ^ {right}[{bit}];')
                    lines.append(f'wire g_{node_index}_{bit} = {left}[{bit}] & {right}[{bit}];')
                lines.append(f'wire [{w}:0] {node};')
                lines.append(f'assign {node}[0] = p_{node_index}_0;')
                for bit in range(1, w + 1):
                    terms = []
                    for generated in range(bit - 1, -1, -1):
                        term = f'g_{node_index}_{generated}'
                        for propagated in range(generated + 1, bit):
                            term += f' & p_{node_index}_{propagated}'
                        terms.append(f'({term})')
                    carry = ' | '.join(terms)
                    if bit < w:
                        lines.append(f'assign {node}[{bit}] = p_{node_index}_{bit} ^ ({carry});')
                    else:
                        lines.append(f'assign {node}[{w}] = {carry};')
            nxt.append((node, w + 1))
            node_index += 1
        nodes = nxt
        lines.append('')
    assert node_index == BITS and len(nodes) == 1 and nodes[0][1] == 12
    lines += [
        'always @(posedge clk) begin',
        "  if (!rst_n) begin",
        "    valid_o <= 1'b0;",
        "    y_o <= 12'd0;",
        '  end else begin',
        '    valid_o <= valid_i;',
        '    if (valid_i)',
        f'      y_o <= {nodes[0][0]};',
        '  end',
        'end',
        'endmodule',
        '',
    ]
    return '\n'.join(lines)


def write_candidate(mask: int, path: str | Path) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render(mask))
    return path


def oracle(a: int, b: int) -> int:
    assert 0 <= a < (1 << 64) and 0 <= b < (1 << 64)
    return sum((a >> (8*i)) & 255 for i in range(8)) + \
           sum((b >> (8*i)) & 255 for i in range(8))


def reference() -> str:
    return f'''// Independent behavioral reference: sixteen unsigned 8-bit inputs.
module {NAME}_ref (
  input wire clk, rst_n, valid_i,
  input wire [63:0] a_i, b_i,
  output reg valid_o,
  output reg [11:0] y_o
);
reg [11:0] computed;
integer i;
always @* begin
  computed = 12'd0;
  for (i = 0; i < 8; i = i + 1) begin
    computed = computed + a_i[(i*8) +: 8];
    computed = computed + b_i[(i*8) +: 8];
  end
end
always @(posedge clk) begin
  if (!rst_n) begin
    valid_o <= 1'b0;
    y_o <= 12'd0;
  end else begin
    valid_o <= valid_i;
    if (valid_i) y_o <= computed;
  end
end
endmodule
'''


def testbench() -> str:
    return f'''`timescale 1ns/1ps
module tb;
logic clk, rst_n, valid_i;
logic [63:0] a_i, b_i;
wire valid_o;
wire [11:0] y_o;
logic [11:0] last_y;
logic [63:0] rng;
{NAME} dut (.*);
initial clk = 1'b0;
always #5 clk = ~clk;
function automatic [63:0] next_rng(input [63:0] x);
  reg [63:0] t;
  begin
    t = x; t = t ^ (t << 13); t = t ^ (t >> 7); t = t ^ (t << 17);
    next_rng = t;
  end
endfunction
function automatic [11:0] expected(input [63:0] a, input [63:0] b);
  logic [11:0] total;
  begin
    total = 12'd0;
    for (int i = 0; i < 8; i = i + 1) begin
      total = total + a[8*i +: 8];
      total = total + b[8*i +: 8];
    end
    expected = total;
  end
endfunction

task automatic check(input [63:0] a, input [63:0] b);
  logic [11:0] e;
  begin
    e = expected(a,b);
    @(negedge clk);
    a_i=a; b_i=b; valid_i=1'b1;
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== e)
      $fatal(1,"valid result mismatch: a=%h b=%h got=%h expected=%h",a,b,y_o,e);
    last_y=e;
    @(negedge clk);
    a_i=~a; b_i=~b; valid_i=1'b0;
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== last_y)
      $fatal(1,"invalid-cycle output was not held");
  end
endtask
initial begin
  rst_n=1'b0; valid_i=1'b0; a_i=0; b_i=0;
  last_y=12'd0; rng=64'h243f6a8885a308d3;
  repeat (3) begin
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== 12'd0)
      $fatal(1,"reset protocol failed");
  end
  @(negedge clk); rst_n=1'b1;
  check(64'h0000000000000000,64'h0000000000000000);
  check(64'hffffffffffffffff,64'hffffffffffffffff);
  check(64'h0101010101010101,64'h0101010101010101);
  check(64'h8000ff0000ff0080,64'h008000ff00ff8000);
  check(64'h0123456789abcdef,64'hfedcba9876543210);
  for (int i=0;i<10000;i=i+1) begin
    rng=next_rng(rng); a_i=rng;
    rng=next_rng(rng); b_i=rng;
    check(a_i,b_i);
  end
  // Back-to-back valid cycles, without an intervening invalid cycle.
  @(negedge clk); a_i=64'hffff0000ffff0000; b_i=64'h0000ffff0000ffff; valid_i=1'b1;
  @(posedge clk); #1;
  if (valid_o !== 1'b1 || y_o !== expected(a_i,b_i))
    $fatal(1,"back-to-back first cycle failed");
  @(negedge clk); a_i=64'h123456789abcdef0; b_i=64'hf0edcba987654321; valid_i=1'b1;
  @(posedge clk); #1;
  if (valid_o !== 1'b1 || y_o !== expected(a_i,b_i))
    $fatal(1,"back-to-back second cycle failed");
  $display("PASS {NAME} randomized+protocol");
  $finish;
end
endmodule
'''


def config() -> str:
    return f'''export DESIGN_NAME = {NAME}
export PLATFORM = nangate45
export VERILOG_FILES = /work/rtl/{NAME}/baseline.v
export SDC_FILE = /work/orfs/{NAME}/constraint.sdc
export DIE_AREA = 0 0 200 200
export CORE_AREA = 5 5 195 195
export PLACE_DENSITY = 0.20
export TNS_END_PERCENT = 100
export SYNTH_REPEATABLE_BUILD = 1
export PDN_TCL = /OpenROAD-flow-scripts/flow/designs/nangate45/gcd/grid_strategy-M1-M4-M7.tcl
'''


def sdc() -> str:
    return f'''current_design {NAME}
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
'''


def benchmark():
    from chiprl.benchmarks import Benchmark, ROOT
    return Benchmark(
        name=NAME, top_module=NAME, reference_top=f'{NAME}_ref',
        testbench=ROOT / 'sim' / f'tb_{NAME}.sv',
        reference=ROOT / 'rtl/reference' / f'{NAME}_ref.v',
        orfs_config_host=ROOT / 'orfs' / NAME / 'config.mk',
        orfs_config_container=f'/work/orfs/{NAME}/config.mk',
        sdc=ROOT / 'orfs' / NAME / 'constraint.sdc',
        pass_marker=f'PASS {NAME} randomized+protocol',
    )
