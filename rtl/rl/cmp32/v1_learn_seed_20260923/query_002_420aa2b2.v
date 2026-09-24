module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire lt_0 = (a_i[1:0] < b_i[1:0]);
wire eq_0 = (a_i[1:0] == b_i[1:0]);
wire lt_1 = (a_i[4:2] < b_i[4:2]);
wire eq_1 = (a_i[4:2] == b_i[4:2]);
wire lt_2 = (a_i[5] < b_i[5]);
wire eq_2 = (a_i[5] == b_i[5]);
wire lt_3 = (a_i[7:6] < b_i[7:6]);
wire eq_3 = (a_i[7:6] == b_i[7:6]);
wire lt_4 = (a_i[9:8] < b_i[9:8]);
wire eq_4 = (a_i[9:8] == b_i[9:8]);
wire lt_5 = (a_i[13:10] < b_i[13:10]);
wire eq_5 = (a_i[13:10] == b_i[13:10]);
wire lt_6 = (a_i[15:14] < b_i[15:14]);
wire eq_6 = (a_i[15:14] == b_i[15:14]);
wire lt_7 = (a_i[17:16] < b_i[17:16]);
wire eq_7 = (a_i[17:16] == b_i[17:16]);
wire lt_8 = (a_i[19:18] < b_i[19:18]);
wire eq_8 = (a_i[19:18] == b_i[19:18]);
wire lt_9 = (a_i[25:20] < b_i[25:20]);
wire eq_9 = (a_i[25:20] == b_i[25:20]);
wire lt_10 = (a_i[30:26] < b_i[30:26]);
wire eq_10 = (a_i[30:26] == b_i[30:26]);
wire lt_11 = (a_i[31] < b_i[31]);
wire eq_11 = (a_i[31] == b_i[31]);

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

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_11;
    end
end
endmodule
