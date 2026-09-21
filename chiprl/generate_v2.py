from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class CandidateSpec:
    family: str
    param: int
    hold_style: str


HOLD_STYLES = (
    "implicit_if",
    "explicit_else",
    "ternary",
    "case",
)


def header() -> str:
    return """module addpipe (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_i,
    input  wire [7:0] a_i,
    input  wire [7:0] b_i,
    output reg        valid_o,
    output reg  [7:0] y_o
);

"""


def registered_body(sum_expr: str, style: str) -> str:
    if style == "implicit_if":
        update = f"""
        valid_o <= valid_i;
        if (valid_i)
            y_o <= {sum_expr};
"""

    elif style == "explicit_else":
        update = f"""
        valid_o <= valid_i;
        if (valid_i)
            y_o <= {sum_expr};
        else
            y_o <= y_o;
"""

    elif style == "ternary":
        update = f"""
        valid_o <= valid_i;
        y_o <= valid_i ? {sum_expr} : y_o;
"""

    elif style == "case":
        update = f"""
        valid_o <= valid_i;
        case (valid_i)
            1'b1:    y_o <= {sum_expr};
            default: y_o <= y_o;
        endcase
"""

    else:
        raise ValueError(style)

    return f"""
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 8'd0;
    end else begin
{update}
    end
end
"""


def behavioral(spec: CandidateSpec) -> str:
    body = """
wire [7:0] sum;
assign sum = a_i + b_i;
"""

    return (
        header()
        + body
        + registered_body("sum", spec.hold_style)
        + "\nendmodule\n"
    )


def ripple(spec: CandidateSpec) -> str:
    body = """
wire [7:0] sum;
wire [8:0] carry;

assign carry[0] = 1'b0;

genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : ripple
        assign sum[i] =
            a_i[i] ^ b_i[i] ^ carry[i];

        assign carry[i + 1] =
            (a_i[i] & b_i[i]) |
            (a_i[i] & carry[i]) |
            (b_i[i] & carry[i]);
    end
endgenerate
"""

    return (
        header()
        + body
        + registered_body("sum", spec.hold_style)
        + "\nendmodule\n"
    )


def chunked(spec: CandidateSpec) -> str:
    width = spec.param

    if width not in (1, 2, 4):
        raise ValueError(width)

    groups = 8 // width

    lines = [
        "wire [7:0] sum;",
        "",
    ]

    for g in range(groups):
        lo = g * width
        hi = lo + width - 1

        lines.append(
            f"wire [{width}:0] part_{g};"
        )

        carry_in = (
            "1'b0"
            if g == 0
            else f"part_{g - 1}[{width}]"
        )

        lines.append(
            f"assign part_{g} = "
            f"{{1'b0, a_i[{hi}:{lo}]}} + "
            f"{{1'b0, b_i[{hi}:{lo}]}} + "
            f"{carry_in};"
        )

        lines.append(
            f"assign sum[{hi}:{lo}] = "
            f"part_{g}[{width - 1}:0];"
        )

        lines.append("")

    return (
        header()
        + "\n".join(lines)
        + registered_body("sum", spec.hold_style)
        + "\nendmodule\n"
    )


def carry_select(spec: CandidateSpec) -> str:
    split = spec.param

    if split < 1 or split > 7:
        raise ValueError(split)

    upper = 8 - split

    body = f"""
wire [{split}:0] lo;
wire [{upper}:0] hi0;
wire [{upper}:0] hi1;
wire [7:0] sum;

assign lo =
    {{1'b0, a_i[{split - 1}:0]}}
    +
    {{1'b0, b_i[{split - 1}:0]}};

assign hi0 =
    {{1'b0, a_i[7:{split}]}}
    +
    {{1'b0, b_i[7:{split}]}};

assign hi1 =
    {{1'b0, a_i[7:{split}]}}
    +
    {{1'b0, b_i[7:{split}]}}
    +
    1'b1;

assign sum[{split - 1}:0] =
    lo[{split - 1}:0];

assign sum[7:{split}] =
    lo[{split}]
    ? hi1[{upper - 1}:0]
    : hi0[{upper - 1}:0];
"""

    return (
        header()
        + body
        + registered_body("sum", spec.hold_style)
        + "\nendmodule\n"
    )


def render(spec: CandidateSpec) -> str:
    if spec.family == "behavioral":
        return behavioral(spec)

    if spec.family == "ripple":
        return ripple(spec)

    if spec.family == "chunked":
        return chunked(spec)

    if spec.family == "carry_select":
        return carry_select(spec)

    raise ValueError(spec.family)


def all_specs() -> list[CandidateSpec]:
    structural = [
        ("behavioral", 0),
        ("ripple", 0),

        ("chunked", 1),
        ("chunked", 2),
        ("chunked", 4),

        *[
            ("carry_select", split)
            for split in range(1, 8)
        ],
    ]

    return [
        CandidateSpec(
            family=family,
            param=param,
            hold_style=hold_style,
        )
        for family, param in structural
        for hold_style in HOLD_STYLES
    ]


def write_candidate(
    spec: CandidateSpec,
    path: Path,
) -> None:
    path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    path.write_text(render(spec))
