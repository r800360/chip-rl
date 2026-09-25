// latency study copy of rtl/generated/cmp32_shared_seed/seed_02_00008000.v
module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire lt_0 = (a_i[15:0] < b_i[15:0]);
wire eq_0 = (a_i[15:0] == b_i[15:0]);
wire lt_1 = (a_i[31:16] < b_i[31:16]);
wire eq_1 = (a_i[31:16] == b_i[31:16]);

wire cmp_0 = lt_0;
wire cmp_1 = lt_1 | (eq_1 & cmp_0);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_1;
    end
end
endmodule
