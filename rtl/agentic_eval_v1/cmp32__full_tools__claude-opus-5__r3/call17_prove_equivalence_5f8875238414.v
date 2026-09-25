module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire [3:0] lg, eg;
genvar i;
generate
  for (i = 0; i < 4; i = i + 1) begin : G
    assign lg[i] = a_i[8*i+7 -: 8] <  b_i[8*i+7 -: 8];
    assign eg[i] = a_i[8*i+7 -: 8] == b_i[8*i+7 -: 8];
  end
endgenerate

wire lt = lg[3] | (eg[3] & (lg[2] | (eg[2] & (lg[1] | (eg[1] & lg[0])))));

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= lt;
    end
end
endmodule