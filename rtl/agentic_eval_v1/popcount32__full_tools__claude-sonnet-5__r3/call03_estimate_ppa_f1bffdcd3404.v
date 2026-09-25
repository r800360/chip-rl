module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// SWAR bit-trick popcount
wire [31:0] w1 = a_i - ((a_i >> 1) & 32'h55555555);
wire [31:0] w2 = (w1 & 32'h33333333) + ((w1 >> 2) & 32'h33333333);
wire [31:0] w3 = (w2 + (w2 >> 4)) & 32'h0f0f0f0f;
wire [31:0] w4 = w3 + (w3 >> 8);
wire [31:0] w5 = w4 + (w4 >> 16);
wire [5:0] total_0 = w5[5:0];

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
