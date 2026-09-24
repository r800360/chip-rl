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
wire lt_1 = (a_i[2] < b_i[2]);
wire eq_1 = (a_i[2] == b_i[2]);
wire lt_2 = (a_i[3] < b_i[3]);
wire eq_2 = (a_i[3] == b_i[3]);
wire lt_3 = (a_i[8:4] < b_i[8:4]);
wire eq_3 = (a_i[8:4] == b_i[8:4]);
wire lt_4 = (a_i[16:9] < b_i[16:9]);
wire eq_4 = (a_i[16:9] == b_i[16:9]);
wire lt_5 = (a_i[18:17] < b_i[18:17]);
wire eq_5 = (a_i[18:17] == b_i[18:17]);
wire lt_6 = (a_i[28:19] < b_i[28:19]);
wire eq_6 = (a_i[28:19] == b_i[28:19]);
wire lt_7 = (a_i[31:29] < b_i[31:29]);
wire eq_7 = (a_i[31:29] == b_i[31:29]);

wire cmp_0 = lt_0;
wire cmp_1 = lt_1 | (eq_1 & cmp_0);
wire cmp_2 = lt_2 | (eq_2 & cmp_1);
wire cmp_3 = lt_3 | (eq_3 & cmp_2);
wire cmp_4 = lt_4 | (eq_4 & cmp_3);
wire cmp_5 = lt_5 | (eq_5 & cmp_4);
wire cmp_6 = lt_6 | (eq_6 & cmp_5);
wire cmp_7 = lt_7 | (eq_7 & cmp_6);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_7;
    end
end
endmodule
