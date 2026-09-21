from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "rtl" / "llm" / "addpipe16_round4"

LOW_WIDTHS = [1, 3, 5, 7]


def render(low: int) -> str:
    high = 16 - low

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
        f"wire [{low-1}:0] low_sum;",
        f"wire [{low}:0] low_carry;",
        "",
        "assign low_carry[0] = 1'b0;",
        "",
        "genvar lr;",
        "generate",
        f"    for (lr = 0; lr < {low}; lr = lr + 1) begin : low_ripple",
        "        assign low_sum[lr] =",
        "            a_i[lr] ^ b_i[lr] ^ low_carry[lr];",
        "",
        "        assign low_carry[lr + 1] =",
        "            (a_i[lr] & b_i[lr]) |",
        "            (a_i[lr] & low_carry[lr]) |",
        "            (b_i[lr] & low_carry[lr]);",
        "    end",
        "endgenerate",
        "",
        f"wire [{high-1}:0] p0;",
        f"wire [{high-1}:0] g0;",
        "",
        f"assign p0 = a_i[15:{low}] ^ b_i[15:{low}];",
        f"assign g0 = a_i[15:{low}] & b_i[15:{low}];",
        "",
    ]

    prev_p = "p0"
    prev_g = "g0"

    distance = 1

    while distance < high:
        p = f"p{distance}"
        g = f"g{distance}"
        gv = f"s{distance}"

        lines += [
            f"wire [{high-1}:0] {p};",
            f"wire [{high-1}:0] {g};",
            "",
            f"genvar {gv};",
            "generate",
            f"    for ({gv} = 0; {gv} < {high}; "
            f"{gv} = {gv} + 1) begin : prefix_{distance}",
            f"        if ({gv} >= {distance}) begin",
            f"            assign {g}[{gv}] =",
            f"                {prev_g}[{gv}] |",
            f"                ({prev_p}[{gv}] & "
            f"{prev_g}[{gv} - {distance}]);",
            "",
            f"            assign {p}[{gv}] =",
            f"                {prev_p}[{gv}] &",
            f"                {prev_p}[{gv} - {distance}];",
            "        end else begin",
            f"            assign {g}[{gv}] = {prev_g}[{gv}];",
            f"            assign {p}[{gv}] = {prev_p}[{gv}];",
            "        end",
            "    end",
            "endgenerate",
            "",
        ]

        prev_p = p
        prev_g = g
        distance *= 2

    lines += [
        f"wire [{high}:0] high_carry;",
        f"wire [{high-1}:0] high_sum;",
        "",
        f"assign high_carry[0] = low_carry[{low}];",
        "",
        "genvar hc;",
        "generate",
        f"    for (hc = 0; hc < {high}; hc = hc + 1) begin : high_carries",
        "        assign high_carry[hc + 1] =",
        f"            {prev_g}[hc] |",
        f"            ({prev_p}[hc] & high_carry[0]);",
        "",
        "        assign high_sum[hc] =",
        "            p0[hc] ^ high_carry[hc];",
        "    end",
        "endgenerate",
        "",
        "wire [15:0] sum;",
        "",
        "assign sum = {",
        "    high_sum,",
        "    low_sum",
        "};",
        "",
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
    ]

    return "\n".join(lines)


def main():
    OUT.mkdir(parents=True, exist_ok=True)

    for low in LOW_WIDTHS:
        high = 16 - low

        path = (
            OUT
            / f"ripple{low}_prefix{high}.v"
        )

        path.write_text(render(low))

        print(path.relative_to(ROOT))


if __name__ == "__main__":
    main()
