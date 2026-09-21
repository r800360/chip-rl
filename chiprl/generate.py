from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class CandidateSpec:
    architecture: str
    gated_output: bool


def registered_body(
    sum_expr: str,
    gated_output: bool,
) -> str:
    if gated_output:
        update = f"""
        valid_o <= valid_i;

        if (valid_i)
            y_o <= {sum_expr};
"""
    else:
        update = f"""
        valid_o <= valid_i;
        y_o <= {sum_expr};
"""

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


def behavioral(spec: CandidateSpec) -> str:
    return (
        header()
        + "wire [7:0] sum = a_i + b_i;\n"
        + registered_body(
            "sum",
            spec.gated_output,
        )
        + "\nendmodule\n"
    )


def ripple(spec: CandidateSpec) -> str:
    return (
        header()
        + """
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
        + registered_body(
            "sum",
            spec.gated_output,
        )
        + "\nendmodule\n"
    )


def chunk2(spec: CandidateSpec) -> str:
    return (
        header()
        + """
wire [2:0] s0;
wire [2:0] s1;
wire [2:0] s2;
wire [2:0] s3;

wire [7:0] sum;

assign s0 = {1'b0, a_i[1:0]}
          + {1'b0, b_i[1:0]};

assign s1 = {1'b0, a_i[3:2]}
          + {1'b0, b_i[3:2]}
          + s0[2];

assign s2 = {1'b0, a_i[5:4]}
          + {1'b0, b_i[5:4]}
          + s1[2];

assign s3 = {1'b0, a_i[7:6]}
          + {1'b0, b_i[7:6]}
          + s2[2];

assign sum = {
    s3[1:0],
    s2[1:0],
    s1[1:0],
    s0[1:0]
};
"""
        + registered_body(
            "sum",
            spec.gated_output,
        )
        + "\nendmodule\n"
    )


def chunk4(spec: CandidateSpec) -> str:
    return (
        header()
        + """
wire [4:0] lo;
wire [4:0] hi;
wire [7:0] sum;

assign lo =
    {1'b0, a_i[3:0]}
    +
    {1'b0, b_i[3:0]};

assign hi =
    {1'b0, a_i[7:4]}
    +
    {1'b0, b_i[7:4]}
    +
    lo[4];

assign sum = {
    hi[3:0],
    lo[3:0]
};
"""
        + registered_body(
            "sum",
            spec.gated_output,
        )
        + "\nendmodule\n"
    )


def carry_select(spec: CandidateSpec) -> str:
    return (
        header()
        + """
wire [4:0] lo;

wire [4:0] hi0;
wire [4:0] hi1;

wire [3:0] hi_selected;
wire [7:0] sum;

assign lo =
    {1'b0, a_i[3:0]}
    +
    {1'b0, b_i[3:0]};

assign hi0 =
    {1'b0, a_i[7:4]}
    +
    {1'b0, b_i[7:4]};

assign hi1 =
    {1'b0, a_i[7:4]}
    +
    {1'b0, b_i[7:4]}
    +
    5'd1;

assign hi_selected =
    lo[4]
    ? hi1[3:0]
    : hi0[3:0];

assign sum = {
    hi_selected,
    lo[3:0]
};
"""
        + registered_body(
            "sum",
            spec.gated_output,
        )
        + "\nendmodule\n"
    )


GENERATORS = {
    "behavioral": behavioral,
    "ripple": ripple,
    "chunk2": chunk2,
    "chunk4": chunk4,
    "carry_select": carry_select,
}


def render(spec: CandidateSpec) -> str:
    return GENERATORS[
        spec.architecture
    ](spec)


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
