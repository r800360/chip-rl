module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// SWAR (bit-trick) population count
wire [31:0] v1 = a_i - ((a_i >> 1) & 32'h55555555);
wire [31:0] v2 = (v1 & 32'h33333333) + ((v1 >> 2) & 32'h33333333);
wire [31:0] v3 = (v2 + (v2 >> 4)) & 32'h0F0F0F0F;
wire [31:0] v4 = v3 + (v3 << 8) + (v3 << 16) + (v3 << 24);
wire [5:0] total_0 = v4[29:24];

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
