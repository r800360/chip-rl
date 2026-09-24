module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire lt_0 = (a_i[11:0] < b_i[11:0]);
wire eq_0 = (a_i[11:0] == b_i[11:0]);
wire lt_1 = (a_i[17:12] < b_i[17:12]);
wire eq_1 = (a_i[17:12] == b_i[17:12]);
wire lt_2 = (a_i[23:18] < b_i[23:18]);
wire eq_2 = (a_i[23:18] == b_i[23:18]);
wire lt_3 = (a_i[31:24] < b_i[31:24]);
wire eq_3 = (a_i[31:24] == b_i[31:24]);

wire cmp_0 = lt_0;
wire cmp_1 = lt_1 | (eq_1 & cmp_0);
wire cmp_2 = lt_2 | (eq_2 & cmp_1);
wire cmp_3 = lt_3 | (eq_3 & cmp_2);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_3;
    end
end
endmodule
