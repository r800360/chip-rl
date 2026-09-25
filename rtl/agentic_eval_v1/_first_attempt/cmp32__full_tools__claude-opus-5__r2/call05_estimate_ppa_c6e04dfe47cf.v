module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
wire hi_lt = (a_i[31:16] < b_i[31:16]);
wire hi_eq = (a_i[31:16] == b_i[31:16]);
wire lo_lt = (a_i[15:0]  < b_i[15:0]);
wire cmp = hi_lt | (hi_eq & lo_lt);

wire sel  = rst_n & valid_i;
wire hold = rst_n & y_o;
always @(posedge clk) begin
    valid_o <= rst_n & valid_i;
    y_o <= sel ? cmp : hold;
end
endmodule