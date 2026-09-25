module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire [32:0] brw;
assign brw[0] = 1'b0;

genvar i;
generate
  for (i = 0; i < 32; i = i + 1) begin : g
    assign brw[i+1] = (~a_i[i] & b_i[i]) | ((~a_i[i] | b_i[i]) & brw[i]);
  end
endgenerate

wire cmp_0 = brw[32];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'b0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_0;
    end
end
endmodule
