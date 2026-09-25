module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [31:0] s1 = a_i | (a_i >> 1);
wire [31:0] s2 = s1 | (s1 >> 2);
wire [31:0] s3 = s2 | (s2 >> 4);
wire [31:0] s4 = s3 | (s3 >> 8);
wire [31:0] s5 = s4 | (s4 >> 16);
wire [31:0] oh = s5 & ~(s5 >> 1);
wire y4 = |(oh & 32'hFFFF0000);
wire y3 = |(oh & 32'hFF00FF00);
wire y2 = |(oh & 32'hF0F0F0F0);
wire y1 = |(oh & 32'hCCCCCCCC);
wire y0 = |(oh & 32'hAAAAAAAA);
wire hit = s5[0];
wire [5:0] chosen = {hit, y4, y3, y2, y1, y0};
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