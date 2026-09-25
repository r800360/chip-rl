module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
    // Sklansky carry tree (xor propagate); carry selects the precomputed flop data
    wire [31:0] gv [0:5];
    wire [31:0] pv [0:5];
    assign gv[0] = a_i & b_i;
    assign pv[0] = a_i ^ b_i;
    genvar l, i;
    generate
      for (l = 0; l < 5; l = l + 1) begin : lev
        for (i = 0; i < 32; i = i + 1) begin : bt
          if (((i >> l) & 1) == 1) begin : mg
            assign gv[l+1][i] = gv[l][i] | (pv[l][i] & gv[l][((i >> l) << l) - 1]);
            assign pv[l+1][i] = pv[l][i] & pv[l][((i >> l) << l) - 1];
          end else begin : ps
            assign gv[l+1][i] = gv[l][i];
            assign pv[l+1][i] = pv[l][i];
          end
        end
      end
    endgenerate
    wire [31:0] c    = {gv[5][30:0], 1'b0};
    wire        sel  = valid_i & rst_n;
    wire [31:0] hold = y_o & {32{rst_n}};
    wire [31:0] d0   = sel ?  pv[0] : hold;
    wire [31:0] d1   = sel ? ~pv[0] : hold;
always @(posedge clk) begin
    valid_o <= valid_i & rst_n;
    y_o     <= (c & d1) | (~c & d0);
end
endmodule
