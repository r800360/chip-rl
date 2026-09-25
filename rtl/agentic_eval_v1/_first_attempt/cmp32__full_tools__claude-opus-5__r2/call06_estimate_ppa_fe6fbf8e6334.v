module cmp32 (
    input wire clk, input wire rst_n, input wire valid_i,
    input wire [31:0] a_i, input wire [31:0] b_i,
    output reg valid_o, output reg [0:0] y_o
);
wire [31:0] x = a_i ^ b_i;
wire r = &x;
wire sel  = rst_n & valid_i;
wire hold = rst_n & y_o;
always @(posedge clk) begin
    valid_o <= rst_n & valid_i;
    y_o <= sel ? r : hold;
end
endmodule