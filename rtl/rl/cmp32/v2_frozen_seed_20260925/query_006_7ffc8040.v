module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire lt_0 = (a_i[6:0] < b_i[6:0]);
wire eq_0 = (a_i[6:0] == b_i[6:0]);
wire lt_1 = (a_i[15:7] < b_i[15:7]);
wire eq_1 = (a_i[15:7] == b_i[15:7]);
wire lt_2 = (a_i[18:16] < b_i[18:16]);
wire eq_2 = (a_i[18:16] == b_i[18:16]);
wire lt_3 = (a_i[19] < b_i[19]);
wire eq_3 = (a_i[19] == b_i[19]);
wire lt_4 = (a_i[20] < b_i[20]);
wire eq_4 = (a_i[20] == b_i[20]);
wire lt_5 = (a_i[21] < b_i[21]);
wire eq_5 = (a_i[21] == b_i[21]);
wire lt_6 = (a_i[22] < b_i[22]);
wire eq_6 = (a_i[22] == b_i[22]);
wire lt_7 = (a_i[23] < b_i[23]);
wire eq_7 = (a_i[23] == b_i[23]);
wire lt_8 = (a_i[24] < b_i[24]);
wire eq_8 = (a_i[24] == b_i[24]);
wire lt_9 = (a_i[25] < b_i[25]);
wire eq_9 = (a_i[25] == b_i[25]);
wire lt_10 = (a_i[26] < b_i[26]);
wire eq_10 = (a_i[26] == b_i[26]);
wire lt_11 = (a_i[27] < b_i[27]);
wire eq_11 = (a_i[27] == b_i[27]);
wire lt_12 = (a_i[28] < b_i[28]);
wire eq_12 = (a_i[28] == b_i[28]);
wire lt_13 = (a_i[29] < b_i[29]);
wire eq_13 = (a_i[29] == b_i[29]);
wire lt_14 = (a_i[30] < b_i[30]);
wire eq_14 = (a_i[30] == b_i[30]);
wire lt_15 = (a_i[31] < b_i[31]);
wire eq_15 = (a_i[31] == b_i[31]);

wire cmp_0 = lt_0;
wire cmp_1 = lt_1 | (eq_1 & cmp_0);
wire cmp_2 = lt_2 | (eq_2 & cmp_1);
wire cmp_3 = lt_3 | (eq_3 & cmp_2);
wire cmp_4 = lt_4 | (eq_4 & cmp_3);
wire cmp_5 = lt_5 | (eq_5 & cmp_4);
wire cmp_6 = lt_6 | (eq_6 & cmp_5);
wire cmp_7 = lt_7 | (eq_7 & cmp_6);
wire cmp_8 = lt_8 | (eq_8 & cmp_7);
wire cmp_9 = lt_9 | (eq_9 & cmp_8);
wire cmp_10 = lt_10 | (eq_10 & cmp_9);
wire cmp_11 = lt_11 | (eq_11 & cmp_10);
wire cmp_12 = lt_12 | (eq_12 & cmp_11);
wire cmp_13 = lt_13 | (eq_13 & cmp_12);
wire cmp_14 = lt_14 | (eq_14 & cmp_13);
wire cmp_15 = lt_15 | (eq_15 & cmp_14);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_15;
    end
end
endmodule
