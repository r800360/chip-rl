module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire l3 = (a_i[31:24] < b_i[31:24]);
wire e3 = (a_i[31:24] == b_i[31:24]);
wire l2 = (a_i[23:16] < b_i[23:16]);
wire e2 = (a_i[23:16] == b_i[23:16]);
wire l1 = (a_i[15:8]  < b_i[15:8]);
wire e1 = (a_i[15:8]  == b_i[15:8]);
wire l0 = (a_i[7:0]   < b_i[7:0]);

wire hi  = l3 | (e3 & l2);
wire ehi = e3 & e2;
wire lo  = l1 | (e1 & l0);

wire cmp_0 = hi | (ehi & lo);

wire sel  = rst_n & valid_i;
wire hold = rst_n & y_o[0];

always @(posedge clk) begin
    valid_o <= sel;
    y_o <= sel ? cmp_0 : hold;
end
endmodule
