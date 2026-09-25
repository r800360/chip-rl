module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire [31:0] v0 = a_i - ((a_i >> 1) & 32'h55555555);
wire [31:0] v1 = (v0 & 32'h33333333) + ((v0 >> 2) & 32'h33333333);
wire [31:0] v2 = (v1 + (v1 >> 4)) & 32'h0F0F0F0F;
wire [7:0] byte_sum = v2[7:0] + v2[15:8] + v2[23:16] + v2[31:24];
wire [5:0] total_0 = byte_sum[5:0];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= total_0;
    end
end
endmodule
