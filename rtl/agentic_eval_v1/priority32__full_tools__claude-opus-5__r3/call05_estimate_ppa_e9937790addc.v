module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire wen = rst_n & valid_i;
always @(posedge clk) begin
    valid_o <= wen;
    y_o <= wen ? {5'b0, ^a_i} : (y_o & {6{rst_n}});
end
endmodule