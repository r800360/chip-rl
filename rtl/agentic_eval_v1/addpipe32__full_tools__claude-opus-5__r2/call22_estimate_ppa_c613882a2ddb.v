module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
    // Knowles-style: Kogge-Stone lower levels, limited-fanout upper levels
    wire [31:0] p0 = a_i ^ b_i;
    wire [31:0] g0 = a_i & b_i;
    wire [31:0] G1 = g0 | (p0 & {g0[30:0], 1'b0});
    wire [31:0] P1 = p0 & {p0[30:0], 1'b0};
    wire [31:0] G2 = G1 | (P1 & {G1[29:0], 2'b0});
    wire [31:0] P2 = P1 & {P1[29:0], 2'b0};
    wire [31:0] G3 = G2 | (P2 & {G2[27:0], 4'b0});
    wire [31:0] P3 = P2 & {P2[27:0], 4'b0};
    // level 4: only even positions need full KS; odd positions reuse neighbour
    wire [31:0] G4, P4, G5;
    assign G4 = G3 | (P3 & {G3[23:0], 8'b0});
    assign P4 = P3 & {P3[23:0], 8'b0};
    assign G5 = G4 | (P4 & {G4[15:0], 16'b0});
    wire [31:0] cin = {G5[30:0], 1'b0};
    wire [31:0] sum = p0 ^ cin;
    wire        sel = valid_i & rst_n;
always @(posedge clk) begin
    valid_o <= sel;
    y_o     <= sel ? sum : (y_o & {32{rst_n}});
end
endmodule