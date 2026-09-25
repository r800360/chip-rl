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
wire [15:0] s1 = h4 ? a_i[31:16] : a_i[15:0];
wire h3 = |s1[15:8];
wire [7:0] s2 = h3 ? s1[15:8] : s1[7:0];
wire h2 = |s2[7:4];
wire [3:0] s3 = h2 ? s2[7:4] : s2[3:0];
wire h1 = |s3[3:2];
wire [1:0] s4 = h1 ? s3[3:2] : s3[1:0];
wire h0 = s4[1];
wire hit = |a_i;
wire [5:0] chosen = {hit, h4, h3, h2, h1, h0};
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen;
    end
end
endmodule