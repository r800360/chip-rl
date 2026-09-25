module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Optimized tree structure for popcount with proper widths
// Level 1: Pairs (0-1, 2-3, etc.)
wire [1:0] p0 = a_i[0] + a_i[1];
wire [1:0] p1 = a_i[2] + a_i[3];
wire [1:0] p2 = a_i[4] + a_i[5];
wire [1:0] p3 = a_i[6] + a_i[7];
wire [1:0] p4 = a_i[8] + a_i[9];
wire [1:0] p5 = a_i[10] + a_i[11];
wire [1:0] p6 = a_i[12] + a_i[13];
wire [1:0] p7 = a_i[14] + a_i[15];
wire [1:0] p8 = a_i[16] + a_i[17];
wire [1:0] p9 = a_i[18] + a_i[19];
wire [1:0] p10 = a_i[20] + a_i[21];
wire [1:0] p11 = a_i[22] + a_i[23];
wire [1:0] p12 = a_i[24] + a_i[25];
wire [1:0] p13 = a_i[26] + a_i[27];
wire [1:0] p14 = a_i[28] + a_i[29];
wire [1:0] p15 = a_i[30] + a_i[31];

// Level 2: Groups of 4
wire [2:0] g0 = p0 + p1;
wire [2:0] g1 = p2 + p3;
wire [2:0] g2 = p4 + p5;
wire [2:0] g3 = p6 + p7;
wire [2:0] g4 = p8 + p9;
wire [2:0] g5 = p10 + p11;
wire [2:0] g6 = p12 + p13;
wire [2:0] g7 = p14 + p15;

// Level 3: Groups of 8
wire [3:0] h0 = g0 + g1;
wire [3:0] h1 = g2 + g3;
wire [3:0] h2 = g4 + g5;
wire [3:0] h3 = g6 + g7;

// Level 4: Groups of 16
wire [4:0] q0 = h0 + h1;
wire [4:0] q1 = h2 + h3;

// Final: All 32 bits
wire [5:0] total_0 = q0 + q1;

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
