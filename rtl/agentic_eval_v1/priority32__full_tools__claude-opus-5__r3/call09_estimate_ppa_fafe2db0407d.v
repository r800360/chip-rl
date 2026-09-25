module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire s4 = |a_i[31:16];
wire [15:0] l1 = s4 ? a_i[31:16] : a_i[15:0];
wire s3 = |l1[15:8];
wire [7:0] l2 = s3 ? l1[15:8] : l1[7:0];
wire s2 = |l2[7:4];
wire [3:0] l3 = s2 ? l2[7:4] : l2[3:0];
wire s1 = |l3[3:2];
wire [1:0] l4 = s1 ? l3[3:2] : l3[1:0];
wire s0 = l4[1];
wire hit = |a_i;
wire [5:0] chosen = {hit, s4, s3, s2, s1, s0};

wire wen = rst_n & valid_i;
always @(posedge clk) begin
    valid_o <= wen;
    y_o <= wen ? chosen : (y_o & {6{rst_n}});
end
endmodule