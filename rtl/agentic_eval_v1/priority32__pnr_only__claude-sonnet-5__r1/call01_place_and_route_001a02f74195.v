module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire hit_0 = |a_i;

wire hi16 = |a_i[31:16];
wire [15:0] sel16 = hi16 ? a_i[31:16] : a_i[15:0];

wire hi8 = |sel16[15:8];
wire [7:0] sel8 = hi8 ? sel16[15:8] : sel16[7:0];

wire hi4 = |sel8[7:4];
wire [3:0] sel4 = hi4 ? sel8[7:4] : sel8[3:0];

wire hi2 = |sel4[3:2];
wire [1:0] sel2 = hi2 ? sel4[3:2] : sel4[1:0];

wire hi1 = sel2[1];

wire [4:0] idx_0 = {hi16, hi8, hi4, hi2, hi1};

wire [5:0] chosen_0 = hit_0 ? {1'b1, idx_0} : 6'd0;

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
