module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
    // Sklansky carry tree (or propagate); carry selects the precomputed flop data
    wire [31:0] gv [0:5];
    wire [31:0] tv [0:5];
    assign gv[0] = a_i & b_i;
    assign tv[0] = a_i | b_i;
    genvar l, i;
    generate
      for (l = 0; l < 5; l = l + 1) begin : lev
        for (i = 0; i < 32; i = i + 1) begin : bt
          if (((i >> l) & 1) == 1) begin : mg
            assign gv[l+1][i] = gv[l][i] | (tv[l][i] & gv[l][((i >> l) << l) - 1]);
            assign tv[l+1][i] = tv[l][i] & tv[l][((i >> l) << l) - 1];
          end else begin : ps
            assign gv[l+1][i] = gv[l][i];
            assign tv[l+1][i] = tv[l][i];
          end
        end
      end
    endgenerate
    wire [31:0] p    = a_i ^ b_i;
    wire [31:0] c    = {gv[5][30:0], 1'b0};
    wire        sel  = valid_i & rst_n;
    wire [31:0] hold = y_o & {32{rst_n}};
    wire [31:0] d0   = sel ?  p : hold;
    wire [31:0] d1   = sel ? ~p : hold;
always @(posedge clk) begin
    valid_o <= valid_i & rst_n;
    y_o     <= (c & d1) | (~c & d0);
end
endmodule
