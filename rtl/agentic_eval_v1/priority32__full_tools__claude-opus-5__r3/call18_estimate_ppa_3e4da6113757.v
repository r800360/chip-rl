module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// upper/lower 16 handled independently, then selected by hi16
wire [15:0] au = a_i[31:16];
wire [15:0] al = a_i[15:0];

wire [15:0] pu1 = au  | {1'b0, au[15:1]};
wire [15:0] pu2 = pu1 | {2'b0, pu1[15:2]};
wire [15:0] pu4 = pu2 | {4'b0, pu2[15:4]};
wire [15:0] mu  = pu4 | {8'b0, pu4[15:8]};

wire [15:0] pl1 = al  | {1'b0, al[15:1]};
wire [15:0] pl2 = pl1 | {2'b0, pl1[15:2]};
wire [15:0] pl4 = pl2 | {4'b0, pl2[15:4]};
wire [15:0] ml  = pl4 | {8'b0, pl4[15:8]};

wire hu = mu[0];
wire hl = ml[0];

wire [3:0] iu, il;
assign iu[3] = mu[8];
assign iu[2] = mu[12] | (mu[4] & ~mu[8]);
assign iu[1] = mu[14] | (mu[10]&~mu[12]) | (mu[6]&~mu[8]) | (mu[2]&~mu[4]);
assign iu[0] = mu[15] | (mu[13]&~mu[14]) | (mu[11]&~mu[12]) | (mu[9]&~mu[10]) |
               (mu[7]&~mu[8]) | (mu[5]&~mu[6]) | (mu[3]&~mu[4]) | (mu[1]&~mu[2]);
assign il[3] = ml[8];
assign il[2] = ml[12] | (ml[4] & ~ml[8]);
assign il[1] = ml[14] | (ml[10]&~ml[12]) | (ml[6]&~ml[8]) | (ml[2]&~ml[4]);
assign il[0] = ml[15] | (ml[13]&~ml[14]) | (ml[11]&~ml[12]) | (ml[9]&~ml[10]) |
               (ml[7]&~ml[8]) | (ml[5]&~ml[6]) | (ml[3]&~ml[4]) | (ml[1]&~ml[2]);

wire [5:0] chosen;
assign chosen[5] = hu | hl;
assign chosen[4] = hu;
assign chosen[3:0] = hu ? iu : il;

wire wen  = rst_n & valid_i;
wire keep = rst_n & ~valid_i;
always @(posedge clk) begin
    valid_o <= wen;
    y_o <= ({6{wen}} & chosen) | ({6{keep}} & y_o);
end
endmodule