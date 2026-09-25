module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire h4 = |a_i[31:16];
wire [15:0] w16 = h4 ? a_i[31:16] : a_i[15:0];
wire h3 = |w16[15:8];
wire [7:0] w8 = h3 ? w16[15:8] : w16[7:0];
wire h2 = |w8[7:4];
wire [3:0] w4 = h2 ? w8[7:4] : w8[3:0];
wire h1 = |w4[3:2];
wire [1:0] w2 = h1 ? w4[3:2] : w4[1:0];
wire h0 = w2[1];
wire hit = |w2;

wire [5:0] chosen_0 = {hit, h4, h3, h2, h1, h0};

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