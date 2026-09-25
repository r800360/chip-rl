module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    wire [32:0] diff = {1'b0, a_i} - {1'b0, b_i};
    wire l5 = diff[32];
    wire sel  = valid_i & rst_n;
    wire hold = y_o & rst_n;
    always @(posedge clk) begin
        valid_o <= sel;
        y_o     <= sel ? l5 : hold;
    end
endmodule