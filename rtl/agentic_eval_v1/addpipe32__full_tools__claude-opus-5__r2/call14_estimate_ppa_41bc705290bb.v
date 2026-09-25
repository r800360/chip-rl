module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
    // Kogge-Stone using (g = a&b, t = a|b) carry algebra
    wire [31:0] t0 = a_i | b_i;
    wire [31:0] g0 = a_i & b_i;
    wire [31:0] p0 = a_i ^ b_i;
    wire [31:0] G1 = g0 | (t0 & {g0[30:0], 1'b0});
    wire [31:0] T1 = t0 & {t0[30:0], 1'b0};
    wire [31:0] G2 = G1 | (T1 & {G1[29:0], 2'b0});
    wire [31:0] T2 = T1 & {T1[29:0], 2'b0};
    wire [31:0] G3 = G2 | (T2 & {G2[27:0], 4'b0});
    wire [31:0] T3 = T2 & {T2[27:0], 4'b0};
    wire [31:0] G4 = G3 | (T3 & {G3[23:0], 8'b0});
    wire [31:0] T4 = T3 & {T3[23:0], 8'b0};
    wire [31:0] G5 = G4 | (T4 & {G4[15:0], 16'b0});
    wire [31:0] sum = p0 ^ {G5[30:0], 1'b0};
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i) y_o <= sum;
    end
end
endmodule