module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    always @(posedge clk) begin
        valid_o <= valid_i;
        y_o     <= a_i[0];
    end
endmodule