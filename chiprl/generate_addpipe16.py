from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


WIDTH = 16
MASK_BITS = WIDTH - 1
MAX_MASK = (1 << MASK_BITS) - 1


@dataclass(frozen=True)
class CandidateSpec:
    boundary_mask: int

    @property
    def blocks(self) -> tuple[int, ...]:
        return partition_from_mask(
            self.boundary_mask
        )


def partition_from_mask(
    mask: int,
) -> tuple[int, ...]:

    if mask < 0 or mask > MAX_MASK:
        raise ValueError(mask)

    blocks = []
    start = 0

    for gap in range(WIDTH - 1):
        if mask & (1 << gap):
            blocks.append(
                gap - start + 1
            )
            start = gap + 1

    blocks.append(
        WIDTH - start
    )

    return tuple(blocks)


def mask_from_blocks(
    blocks: tuple[int, ...],
) -> int:

    if not blocks:
        raise ValueError("empty partition")

    if sum(blocks) != WIDTH:
        raise ValueError(
            f"blocks must sum to {WIDTH}: "
            f"{blocks}"
        )

    if any(w <= 0 for w in blocks):
        raise ValueError(blocks)

    mask = 0
    position = 0

    for width in blocks[:-1]:
        position += width
        mask |= 1 << (position - 1)

    return mask


def render(
    spec: CandidateSpec,
) -> str:

    blocks = spec.blocks

    lines = [
        "module addpipe16 (",
        "    input  wire        clk,",
        "    input  wire        rst_n,",
        "    input  wire        valid_i,",
        "    input  wire [15:0] a_i,",
        "    input  wire [15:0] b_i,",
        "    output reg         valid_o,",
        "    output reg  [15:0] y_o",
        ");",
        "",
        "wire [15:0] sum;",
        "",
    ]

    lo = 0

    for i, width in enumerate(blocks):
        hi = lo + width - 1

        if i == 0:
            lines.extend([
                f"wire [{width}:0] blk_{i};",

                f"assign blk_{i} = "
                f"{{1'b0, a_i[{hi}:{lo}]}} + "
                f"{{1'b0, b_i[{hi}:{lo}]}};",

                f"assign sum[{hi}:{lo}] = "
                f"blk_{i}[{width - 1}:0];",

                f"wire carry_{i};",

                f"assign carry_{i} = "
                f"blk_{i}[{width}];",
                "",
            ])

        else:
            zero_extension = (
                "{" +
                f"{width}" +
                "{1'b0}}"
            )

            lines.extend([
                f"wire [{width}:0] blk_{i}_0;",
                f"wire [{width}:0] blk_{i}_1;",
                f"wire [{width}:0] blk_{i};",

                f"assign blk_{i}_0 = "
                f"{{1'b0, a_i[{hi}:{lo}]}} + "
                f"{{1'b0, b_i[{hi}:{lo}]}};",

                f"assign blk_{i}_1 = "
                f"{{1'b0, a_i[{hi}:{lo}]}} + "
                f"{{1'b0, b_i[{hi}:{lo}]}} + "
                f"{{{zero_extension}, 1'b1}};",

                f"assign blk_{i} = "
                f"carry_{i - 1} "
                f"? blk_{i}_1 "
                f": blk_{i}_0;",

                f"assign sum[{hi}:{lo}] = "
                f"blk_{i}[{width - 1}:0];",

                f"wire carry_{i};",

                f"assign carry_{i} = "
                f"blk_{i}[{width}];",
                "",
            ])

        lo = hi + 1

    lines.extend([
        "always @(posedge clk) begin",
        "    if (!rst_n) begin",
        "        valid_o <= 1'b0;",
        "        y_o     <= 16'd0;",
        "    end else begin",
        "        valid_o <= valid_i;",
        "",
        "        if (valid_i)",
        "            y_o <= sum;",
        "    end",
        "end",
        "",
        "endmodule",
        "",
    ])

    return "\n".join(lines)


def write_candidate(
    spec: CandidateSpec,
    path: Path,
) -> None:

    path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    path.write_text(
        render(spec)
    )
