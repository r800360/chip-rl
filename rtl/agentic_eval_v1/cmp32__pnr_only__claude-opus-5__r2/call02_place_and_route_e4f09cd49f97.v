module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire cmp_0 = (a_i[31:0] < b_i[31:0]);

wire sel  = rst_n & valid_i;
wire hold = rst_n & y_o[0];

always @(posedge clk) begin
    valid_o <= sel;
    y_o <= sel ? cmp_0 : hold;
end
endmodule
