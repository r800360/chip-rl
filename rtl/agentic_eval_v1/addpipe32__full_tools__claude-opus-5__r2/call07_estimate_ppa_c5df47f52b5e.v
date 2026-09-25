module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
    // Han-Carlson: KS over odd indices, final fix-up for even indices
    wire [31:0] p0 = a_i ^ b_i;
    wire [31:0] g0 = a_i & b_i;

    wire [31:0] G1, P1, G2, P2, G3, P3, G4, P4, G5;
    // level 1 (all bits, shift 1)
    assign G1 = g0 | (p0 & {g0[30:0], 1'b0});
    assign P1 = p0 & {p0[30:0], 1'b0};
    // KS over odd indices, shifts 2,4,8,16
    assign G2 = G1 | (P1 & {G1[29:0], 2'b0});
    assign P2 = P1 & {P1[29:0], 2'b0};
    assign G3 = G2 | (P2 & {G2[27:0], 4'b0});
    assign P3 = P2 & {P2[27:0], 4'b0};
    assign G4 = G3 | (P3 & {G3[23:0], 8'b0});
    assign P4 = P3 & {P3[23:0], 8'b0};
    assign G5 = G4 | (P4 & {G4[15:0], 16'b0});

    // carry into bit i (i>=1): odd source uses G5[i-1] directly when i-1 odd
    wire [31:0] cin;
    assign cin[0] = 1'b0;
    genvar i;
    generate
      for (i = 1; i < 32; i = i + 1) begin : CY
        if ((i-1) % 2 == 1) begin : odd
          assign cin[i] = G5[i-1];
        end else begin : even
          if (i == 1)
            assign cin[i] = g0[0];
          else
            assign cin[i] = g0[i-1] | (p0[i-1] & G5[i-2]);
        end
      end
    endgenerate

    wire [31:0] sum = p0 ^ cin;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= sum;
    end
end
endmodule