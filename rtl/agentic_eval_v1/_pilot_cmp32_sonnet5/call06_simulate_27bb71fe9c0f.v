module cmp_tree #(parameter WIDTH=32) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output lt,
    output eq
);
generate
    if (WIDTH==1) begin
        assign lt = (~a)&b;
        assign eq = ~(a^b);
    end else begin
        localparam WH = WIDTH/2;
        wire lt_hi, eq_hi, lt_lo, eq_lo;
        cmp_tree #(.WIDTH(WIDTH-WH)) hi(.a(a[WIDTH-1:WH]), .b(b[WIDTH-1:WH]), .lt(lt_hi), .eq(eq_hi));
        cmp_tree #(.WIDTH(WH)) lo(.a(a[WH-1:0]), .b(b[WH-1:0]), .lt(lt_lo), .eq(eq_lo));
        assign lt = lt_hi | (eq_hi & lt_lo);
        assign eq = eq_hi & eq_lo;
    end
endgenerate
endmodule

module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire cmp_0, eq_unused;
cmp_tree #(.WIDTH(32)) u_cmp (.a(a_i), .b(b_i), .lt(cmp_0), .eq(eq_unused));

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_0;
    end
end
endmodule
