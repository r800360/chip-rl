module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Balanced adder tree for population count (reduces bit growth per level)
wire [1:0] p0  = a_i[0]  + a_i[1];
wire [1:0] p1  = a_i[2]  + a_i[3];
wire [1:0] p2  = a_i[4]  + a_i[5];
wire [1:0] p3  = a_i[6]  + a_i[7];
wire [1:0] p4  = a_i[8]  + a_i[9];
wire [1:0] p5  = a_i[10] + a_i[11];
wire [1:0] p6  = a_i[12] + a_i[13];
wire [1:0] p7  = a_i[14] + a_i[15];
wire [1:0] p8  = a_i[16] + a_i[17];
wire [1:0] p9  = a_i[18] + a_i[19];
wire [1:0] p10 = a_i[20] + a_i[21];
wire [1:0] p11 = a_i[22] + a_i[23];
wire [1:0] p12 = a_i[24] + a_i[25];
wire [1:0] p13 = a_i[26] + a_i[27];
wire [1:0] p14 = a_i[28] + a_i[29];
wire [1:0] p15 = a_i[30] + a_i[31];

wire [2:0] q0 = p0  + p1;
wire [2:0] q1 = p2  + p3;
wire [2:0] q2 = p4  + p5;
wire [2:0] q3 = p6  + p7;
wire [2:0] q4 = p8  + p9;
wire [2:0] q5 = p10 + p11;
wire [2:0] q6 = p12 + p13;
wire [2:0] q7 = p14 + p15;

wire [3:0] r0 = q0 + q1;
wire [3:0] r1 = q2 + q3;
wire [3:0] r2 = q4 + q5;
wire [3:0] r3 = q6 + q7;

wire [4:0] s0 = r0 + r1;
wire [4:0] s1 = r2 + r3;

wire [5:0] total_0 = s0 + s1;

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
