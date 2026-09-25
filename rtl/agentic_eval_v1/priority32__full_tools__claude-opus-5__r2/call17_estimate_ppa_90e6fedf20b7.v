module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire C3 = |a_i[31:24];
wire C2 = |a_i[23:16];
wire C1 = |a_i[15:8];
wire C0 = |a_i[7:0];
wire nQ3 = ~C3;
wire nQ2 = ~(C3 | C2);
wire nQ1 = ~(C3 | C2 | C1);
wire m2_3 = |a_i[31:28];
wire m1_3 = (a_i[31] | a_i[30]) | (~m2_3 & (a_i[27] | a_i[26]));
wire m0_3 = a_i[31] | (a_i[29] & ~a_i[30]) | (~m2_3 & (a_i[27] | (a_i[25] & ~a_i[26])));
wire m2_2 = |a_i[23:20];
wire m1_2 = (a_i[23] | a_i[22]) | (~m2_2 & (a_i[19] | a_i[18]));
wire m0_2 = a_i[23] | (a_i[21] & ~a_i[22]) | (~m2_2 & (a_i[19] | (a_i[17] & ~a_i[18])));
wire m2_1 = |a_i[15:12];
wire m1_1 = (a_i[15] | a_i[14]) | (~m2_1 & (a_i[11] | a_i[10]));
wire m0_1 = a_i[15] | (a_i[13] & ~a_i[14]) | (~m2_1 & (a_i[11] | (a_i[9] & ~a_i[10])));
wire m2_0 = |a_i[7:4];
wire m1_0 = (a_i[7] | a_i[6]) | (~m2_0 & (a_i[3] | a_i[2]));
wire m0_0 = a_i[7] | (a_i[5] & ~a_i[6]) | (~m2_0 & (a_i[3] | (a_i[1] & ~a_i[2])));
wire y4 = C3 | C2;
wire y3 = C3 | (C1 & nQ2);
wire y2 = m2_3 | (m2_2 & nQ3) | (m2_1 & nQ2) | (m2_0 & nQ1);
wire y1 = m1_3 | (m1_2 & nQ3) | (m1_1 & nQ2) | (m1_0 & nQ1);
wire y0 = m0_3 | (m0_2 & nQ3) | (m0_1 & nQ2) | (m0_0 & nQ1);
wire hit = C3 | C2 | C1 | C0;
wire [5:0] chosen = {hit, y4, y3, y2, y1, y0};
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen;
    end
end
endmodule