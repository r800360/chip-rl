module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    wire lt = (a_i < b_i);
    wire en = valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= valid_i & rst_n;
        y_o <= en ? lt : (y_o & rst_n);
    end
endmodule
