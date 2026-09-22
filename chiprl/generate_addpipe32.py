from __future__ import annotations

import argparse
from pathlib import Path


WIDTH = 32
MASK_BITS = WIDTH - 1
MAX_MASK = (1 << MASK_BITS) - 1


def blocks_from_mask(
    mask: int,
) -> tuple[int, ...]:
    if mask < 0 or mask > MAX_MASK:
        raise ValueError(
            f"mask must fit in {MASK_BITS} bits"
        )

    blocks = []
    current = 1

    for boundary in range(
        MASK_BITS
    ):
        if mask & (1 << boundary):
            blocks.append(current)
            current = 1
        else:
            current += 1

    blocks.append(current)

    assert sum(blocks) == WIDTH

    return tuple(blocks)


def render(
    mask: int,
) -> str:
    blocks = blocks_from_mask(
        mask
    )

    lines = [
        "module addpipe32 (",
        "    input  wire        clk,",
        "    input  wire        rst_n,",
        "    input  wire        valid_i,",
        "    input  wire [31:0] a_i,",
        "    input  wire [31:0] b_i,",
        "    output reg         valid_o,",
        "    output reg  [31:0] y_o",
        ");",
        "",
    ]

    lo = 0
    sum_names = []
    previous_carry = None

    for index, width in enumerate(
        blocks
    ):
        hi = lo + width - 1

        a_slice = (
            f"a_i[{hi}:{lo}]"
            if width > 1
            else f"a_i[{lo}]"
        )

        b_slice = (
            f"b_i[{hi}:{lo}]"
            if width > 1
            else f"b_i[{lo}]"
        )

        if index == 0:
            lines += [
                f"wire [{width}:0] block_{index};",
                f"wire [{width - 1}:0] sum_{index};",
                f"wire carry_{index};",
                "",
                f"assign block_{index} =",
                f"    {{1'b0, {a_slice}}} +",
                f"    {{1'b0, {b_slice}}};",
                "",
                f"assign sum_{index} =",
                f"    block_{index}[{width - 1}:0];",
                "",
                f"assign carry_{index} =",
                f"    block_{index}[{width}];",
                "",
            ]

        else:
            lines += [
                f"wire [{width}:0] block_{index}_0;",
                f"wire [{width}:0] block_{index}_1;",
                f"wire [{width}:0] block_{index};",
                f"wire [{width - 1}:0] sum_{index};",
                f"wire carry_{index};",
                "",
                f"assign block_{index}_0 =",
                f"    {{1'b0, {a_slice}}} +",
                f"    {{1'b0, {b_slice}}};",
                "",
                f"assign block_{index}_1 =",
                f"    {{1'b0, {a_slice}}} +",
                f"    {{1'b0, {b_slice}}} +",
                f"    {width + 1}'d1;",
                "",
                f"assign block_{index} =",
                f"    {previous_carry}",
                f"    ? block_{index}_1",
                f"    : block_{index}_0;",
                "",
                f"assign sum_{index} =",
                f"    block_{index}[{width - 1}:0];",
                "",
                f"assign carry_{index} =",
                f"    block_{index}[{width}];",
                "",
            ]

        sum_names.append(
            f"sum_{index}"
        )

        previous_carry = (
            f"carry_{index}"
        )

        lo = hi + 1

    lines += [
        "wire [31:0] sum;",
        "",
        "assign sum = {",
    ]

    for i, name in enumerate(
        reversed(sum_names)
    ):
        comma = (
            ","
            if i
            < len(sum_names) - 1
            else ""
        )

        lines.append(
            f"    {name}{comma}"
        )

    lines += [
        "};",
        "",
        "always @(posedge clk) begin",
        "    if (!rst_n) begin",
        "        valid_o <= 1'b0;",
        "        y_o     <= 32'd0;",
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
    ]

    return "\n".join(lines)


def write_candidate(
    mask: int,
    path: str | Path,
) -> Path:
    path = Path(path)

    path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    path.write_text(
        render(mask)
    )

    return path


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "mask",
        help=(
            "31-bit boundary mask, "
            "e.g. 0x000800"
        ),
    )

    parser.add_argument(
        "output",
        type=Path,
    )

    args = parser.parse_args()

    mask = int(
        args.mask,
        0,
    )

    blocks = blocks_from_mask(
        mask
    )

    path = write_candidate(
        mask,
        args.output,
    )

    print(
        f"mask=0x{mask:08x} "
        f"blocks={blocks}"
    )

    print(path)


if __name__ == "__main__":
    main()
