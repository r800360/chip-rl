module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// direct sum-of-products priority encoder with shared prefix ORs
wire o31_16 = |a_i[31:16];
wire o31_24 = |a_i[31:24];
wire o31_28 = |a_i[31:28];
wire o31_20 = |a_i[31:20];
wire o31_12 = |a_i[31:12];
wire o31_8  = |a_i[31:8];
wire o31_4  = |a_i[31:4];

wire idx4 = o31_16;
wire idx3 = o31_24 | (~o31_16 & |a_i[15:8]);
wire idx2 = o31_28 | (~o31_24 & |a_i[23:20]) | (~o31_16 & |a_i[15:12]) | (~o31_12 & |a_i[7:4]);
wire idx1 = (|a_i[31:30]) | (~o31_28 & |a_i[27:26]) | (~o31_24 & |a_i[23:22]) |
            (~o31_20 & |a_i[19:18]) | (~o31_16 & |a_i[15:14]) | (~o31_12 & |a_i[11:10]) |
            (~o31_8  & |a_i[7:6])   | (~o31_4  & |a_i[3:2]);
wire [31:0] pn;
assign pn[31] = 1'b0;
assign pn[30] = ~a_i[31];
assign pn[29] = ~|a_i[31:30];
assign pn[28] = ~|a_i[31:29];
assign pn[27] = ~o31_28;
assign pn[26] = ~|a_i[31:27];
assign pn[25] = ~|a_i[31:26];
assign pn[24] = ~|a_i[31:25];
assign pn[23] = ~o31_24;
assign pn[22] = ~|a_i[31:23];
assign pn[21] = ~|a_i[31:22];
assign pn[20] = ~|a_i[31:21];
assign pn[19] = ~o31_20;
assign pn[18] = ~|a_i[31:19];
assign pn[17] = ~|a_i[31:18];
assign pn[16] = ~|a_i[31:17];
assign pn[15] = ~o31_16;
assign pn[14] = ~|a_i[31:15];
assign pn[13] = ~|a_i[31:14];
assign pn[12] = ~|a_i[31:13];
assign pn[11] = ~o31_12;
assign pn[10] = ~|a_i[31:11];
assign pn[9]  = ~|a_i[31:10];
assign pn[8]  = ~|a_i[31:9];
assign pn[7]  = ~o31_8;
assign pn[6]  = ~|a_i[31:7];
assign pn[5]  = ~|a_i[31:6];
assign pn[4]  = ~|a_i[31:5];
assign pn[3]  = ~o31_4;
assign pn[2]  = ~|a_i[31:3];
assign pn[1]  = ~|a_i[31:2];
assign pn[0]  = ~|a_i[31:1];

wire idx0 = (a_i[31]) | (pn[30]&a_i[29]) | (pn[28]&a_i[27]) | (pn[26]&a_i[25]) |
            (pn[24]&a_i[23]) | (pn[22]&a_i[21]) | (pn[20]&a_i[19]) | (pn[18]&a_i[17]) |
            (pn[16]&a_i[15]) | (pn[14]&a_i[13]) | (pn[12]&a_i[11]) | (pn[10]&a_i[9]) |
            (pn[8]&a_i[7])   | (pn[6]&a_i[5])   | (pn[4]&a_i[3])   | (pn[2]&a_i[1]);

wire hit = ~pn[0] | a_i[0];
wire [5:0] chosen_0 = {hit, idx4, idx3, idx2, idx1, idx0};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen_0;
    end
end
endmodule