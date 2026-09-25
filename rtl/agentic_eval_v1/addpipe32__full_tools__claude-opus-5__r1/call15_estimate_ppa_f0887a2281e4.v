module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
    // Kogge-Stone carry tree with OR-propagate
    wire [31:0] gv [0:5];
    wire [31:0] tv [0:5];
    assign gv[0] = a_i & b_i;
    assign tv[0] = a_i | b_i;
    genvar l, i;
    generate
      for (l = 0; l < 5; l = l + 1) begin : lev
        for (i = 0; i < 32; i = i + 1) begin : bt
          if (i >= (1 << l)) begin : mg
            assign gv[l+1][i] = gv[l][i] | (tv[l][i] & gv[l][i-(1<<l)]);
            assign tv[l+1][i] = tv[l][i] & tv[l][i-(1<<l)];
          end else begin : ps
            assign gv[l+1][i] = gv[l][i];
            assign tv[l+1][i] = tv[l][i];
          end
        end
      end
    endgenerate
    wire [31:0] sum = (a_i ^ b_i) ^ {gv[5][30:0], 1'b0};
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
