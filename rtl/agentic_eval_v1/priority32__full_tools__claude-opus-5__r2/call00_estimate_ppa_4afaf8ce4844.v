module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire q3 = |a_i[31:24];
wire q2 = |a_i[23:16];
wire q1 = |a_i[15:8];
wire q0 = |a_i[7:0];
wire [7:0] s8 = q3 ? a_i[31:24] : q2 ? a_i[23:16] : q1 ? a_i[15:8] : a_i[7:0];
wire y4 = q3 | q2;
wire y3 = q3 | (q1 & ~q2);
wire p3 = |s8[7:6];
wire p2 = |s8[5:4];
wire p1 = |s8[3:2];
wire [1:0] s2 = p3 ? s8[7:6] : p2 ? s8[5:4] : p1 ? s8[3:2] : s8[1:0];
wire y2 = p3 | p2;
wire y1 = p3 | (p1 & ~p2);
wire y0 = s2[1];
wire hit = q3 | q2 | q1 | q0;
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