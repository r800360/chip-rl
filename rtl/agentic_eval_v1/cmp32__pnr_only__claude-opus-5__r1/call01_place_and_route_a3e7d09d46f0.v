module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire cmp = (a_i < b_i);
wire en  = rst_n & valid_i;
wire hold = rst_n & y_o;

always @(posedge clk) begin
    valid_o <= en;
    y_o     <= en ? cmp : hold;
end
endmodule