module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [1:0] L1 [0:15];
wire [2:0] L2 [0:7];
wire [3:0] L3 [0:3];
wire [4:0] L4 [0:1];
wire [5:0] L5;
genvar i;
generate
 for (i=0;i<16;i=i+1) begin : g1
   assign L1[i][0] = a_i[2*i]^a_i[2*i+1];
   assign L1[i][1] = a_i[2*i]&a_i[2*i+1];
 end
 for (i=0;i<8;i=i+1) begin : g2
   wire c0 = L1[2*i][0]&L1[2*i+1][0];
   wire p1 = L1[2*i][1]^L1[2*i+1][1];
   wire g1 = L1[2*i][1]&L1[2*i+1][1];
   assign L2[i][0] = L1[2*i][0]^L1[2*i+1][0];
   assign L2[i][1] = p1^c0;
   assign L2[i][2] = g1|(p1&c0);
 end
 for (i=0;i<4;i=i+1) begin : g3
   wire c0 = L2[2*i][0]&L2[2*i+1][0];
   wire p1 = L2[2*i][1]^L2[2*i+1][1];
   wire g1 = L2[2*i][1]&L2[2*i+1][1];
   wire c1 = g1|(p1&c0);
   wire p2 = L2[2*i][2]^L2[2*i+1][2];
   wire g2 = L2[2*i][2]&L2[2*i+1][2];
   assign L3[i][0] = L2[2*i][0]^L2[2*i+1][0];
   assign L3[i][1] = p1^c0;
   assign L3[i][2] = p2^c1;
   assign L3[i][3] = g2|(p2&c1);
 end
 for (i=0;i<2;i=i+1) begin : g4
   wire c0 = L3[2*i][0]&L3[2*i+1][0];
   wire p1 = L3[2*i][1]^L3[2*i+1][1];
   wire g1 = L3[2*i][1]&L3[2*i+1][1];
   wire c1 = g1|(p1&c0);
   wire p2 = L3[2*i][2]^L3[2*i+1][2];
   wire g2 = L3[2*i][2]&L3[2*i+1][2];
   wire c2 = g2|(p2&c1);
   wire p3 = L3[2*i][3]^L3[2*i+1][3];
   wire g3 = L3[2*i][3]&L3[2*i+1][3];
   assign L4[i][0] = L3[2*i][0]^L3[2*i+1][0];
   assign L4[i][1] = p1^c0;
   assign L4[i][2] = p2^c1;
   assign L4[i][3] = p3^c2;
   assign L4[i][4] = g3|(p3&c2);
 end
endgenerate
wire fc0 = L4[0][0]&L4[1][0];
wire fp1 = L4[0][1]^L4[1][1];
wire fg1 = L4[0][1]&L4[1][1];
wire fc1 = fg1|(fp1&fc0);
wire fp2 = L4[0][2]^L4[1][2];
wire fg2 = L4[0][2]&L4[1][2];
wire fc2 = fg2|(fp2&fc1);
wire fp3 = L4[0][3]^L4[1][3];
wire fg3 = L4[0][3]&L4[1][3];
wire fc3 = fg3|(fp3&fc2);
wire fp4 = L4[0][4]^L4[1][4];
wire fg4 = L4[0][4]&L4[1][4];
assign L5[0] = L4[0][0]^L4[1][0];
assign L5[1] = fp1^fc0;
assign L5[2] = fp2^fc1;
assign L5[3] = fp3^fc2;
assign L5[4] = fp4^fc3;
assign L5[5] = fg4|(fp4&fc3);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= L5;
    end
end
endmodule