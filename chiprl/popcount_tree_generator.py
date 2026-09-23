"""An exploratory 32-bit popcount architecture grammar; never edits popcount32.

31 mask bits select the implementation of the 31 internal nodes of a
balanced binary reduction tree. Bit 0..15 selects at the leaf-pair layer;
bit 30 selects at the root. 0 = sized arithmetic addition, 1 = explicit
carry-lookahead equations. Both preserve identical one-cycle protocol.

Synthesis may still collapse alternatives. The separate pilot measures that
possibility *before* this grammar is admitted to a new RL experiment.
"""
from __future__ import annotations

from pathlib import Path

NAME = "popcount32_tree"
BITS = 31
MAX_MASK = (1 << BITS) - 1
PILOT_MASKS = (
    0x00000000,  # arithmetic throughout
    0x7fffffff,  # explicit carry-lookahead throughout
    0x40000000,  # root only
    0x70000000,  # top two tree layers
    0x7f000000,  # top three tree layers
    0x0000ffff,  # leaf-pair layer only
    0x55555555,  # alternating decisions
    0x2aaaaaaa,  # complementary decisions
)


def _validate(mask: int) -> int:
    mask = int(mask)
    if not 0 <= mask <= MAX_MASK:
        raise ValueError(f"mask outside 31-bit space: {mask}")
    return mask


def render(mask: int) -> str:
    mask = _validate(mask)
    lines = [
        "// Independent experimental benchmark; 31-node balanced popcount tree.",
        f"// architecture_mask = 0x{mask:08x}",
        "module popcount32_tree (",
        "  input wire clk, rst_n, valid_i,",
        "  input wire [31:0] a_i, b_i,",
        "  output reg valid_o,",
        "  output reg [5:0] y_o",
        ");",
        "",
    ]
    nodes = []
    for i in range(32):
        name = f"leaf_{i}"
        lines.append(f"wire [0:0] {name} = a_i[{i}];")
        nodes.append((name, 1))
    lines.append("")
    node_index = 0
    for level in range(5):
        next_nodes = []
        for pair in range(len(nodes) // 2):
            (left, w_left), (right, w_right) = nodes[2 * pair: 2 * pair + 2]
            assert w_left == w_right == level + 1
            w = w_left
            name = f"n_{level}_{pair}"
            selected = bool(mask & (1 << node_index))
            lines.append(f"// node {node_index}: {'CLA' if selected else 'ADD'}")
            if not selected:
                lines.append(
                    f"wire [{w}:0] {name} = "
                    f"{{1'b0,{left}}} + {{1'b0,{right}}};"
                )
            else:
                # The explicit parallel carry equations differ structurally
                # from '+' and ripple carry, while remaining exact arithmetic.
                for bit in range(w):
                    lines.append(
                        f"wire p_{node_index}_{bit} = {left}[{bit}] ^ {right}[{bit}];"
                    )
                    lines.append(
                        f"wire g_{node_index}_{bit} = {left}[{bit}] & {right}[{bit}];"
                    )
                lines.append(f"wire [{w}:0] {name};")
                lines.append(f"assign {name}[0] = p_{node_index}_0;")
                for bit in range(1, w + 1):
                    carry_terms = []
                    for generated in range(bit - 1, -1, -1):
                        term = f"g_{node_index}_{generated}"
                        for propagated in range(generated + 1, bit):
                            term += f" & p_{node_index}_{propagated}"
                        carry_terms.append(f"({term})")
                    carry = " | ".join(carry_terms)
                    if bit < w:
                        lines.append(
                            f"assign {name}[{bit}] = p_{node_index}_{bit} ^ ({carry});"
                        )
                    else:
                        lines.append(f"assign {name}[{w}] = {carry};")
            next_nodes.append((name, w + 1))
            node_index += 1
        nodes = next_nodes
        lines.append("")
    assert node_index == BITS and len(nodes) == 1 and nodes[0][1] == 6
    lines += [
        "always @(posedge clk) begin",
        "  if (!rst_n) begin",
        "    valid_o <= 1'b0;",
        "    y_o <= 6'd0;",
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


def write_candidate(mask: int, path: str | Path) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render(mask))
    return path


def python_oracle(a: int) -> int:
    return (a & 0xffffffff).bit_count()
