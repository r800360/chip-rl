module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

    wire [2:0] g0 = a_i[0]  + a_i[1]  + a_i[2]  + a_i[3];
    wire [2:0] g1 = a_i[4]  + a_i[5]  + a_i[6]  + a_i[7];
    wire [2:0] g2 = a_i[8]  + a_i[9]  + a_i[10] + a_i[11];
    wire [2:0] g3 = a_i[12] + a_i[13] + a_i[14] + a_i[15];
    wire [2:0] g4 = a_i[16] + a_i[17] + a_i[18] + a_i[19];
    wire [2:0] g5 = a_i[20] + a_i[21] + a_i[22] + a_i[23];
    wire [2:0] g6 = a_i[24] + a_i[25] + a_i[26] + a_i[27];
    wire [2:0] g7 = a_i[28] + a_i[29] + a_i[30] + a_i[31];

    wire [3:0] h0 = g0 + g1;
    wire [3:0] h1 = g2 + g3;
    wire [3:0] h2 = g4 + g5;
    wire [3:0] h3 = g6 + g7;

    wire [4:0] q0 = h0 + h1;
    wire [4:0] q1 = h2 + h3;

    wire [5:0] total = q0 + q1;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= total;
    end
end
endmodule