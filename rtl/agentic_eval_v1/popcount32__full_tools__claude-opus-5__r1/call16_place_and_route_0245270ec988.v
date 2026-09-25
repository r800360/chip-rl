module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [9:0] x0 = {a_i[27],a_i[24],a_i[21],a_i[18],a_i[15],a_i[12],a_i[9],a_i[6],a_i[3],a_i[0]};
wire [9:0] x1 = {a_i[28],a_i[25],a_i[22],a_i[19],a_i[16],a_i[13],a_i[10],a_i[7],a_i[4],a_i[1]};
wire [9:0] x2 = {a_i[29],a_i[26],a_i[23],a_i[20],a_i[17],a_i[14],a_i[11],a_i[8],a_i[5],a_i[2]};
wire [9:0] xh = x0 ^ x1;
wire [9:0] s1 = xh ^ x2;
wire [9:0] c1 = (x0 & x1) | (xh & x2);
wire [9:0] fl = s1 & c1;

wire e0 = s1[0]^s1[1];
wire s2_0 = e0^s1[2];
wire c2_0 = (s1[0]&s1[1])|(e0&s1[2]);
wire e1 = s1[3]^s1[4];
wire s2_1 = e1^s1[5];
wire c2_1 = (s1[3]&s1[4])|(e1&s1[5]);
wire e2 = s1[6]^s1[7];
wire s2_2 = e2^s1[8];
wire c2_2 = (s1[6]&s1[7])|(e2&s1[8]);
wire e3 = s1[9]^a_i[30];
wire s2_3 = e3^a_i[31];
wire c2_3 = (s1[9]&a_i[30])|(e3&a_i[31]);
wire f0 = c1[0]^c1[1];
wire u_0 = f0^c1[2];
wire v_0 = (c1[0]&c1[1])|(f0&c1[2]);
wire f1 = c1[3]^c1[4];
wire u_1 = f1^c1[5];
wire v_1 = (c1[3]&c1[4])|(f1&c1[5]);
wire f2 = c1[6]^c1[7];
wire u_2 = f2^c1[8];
wire v_2 = (c1[6]&c1[7])|(f2&c1[8]);

wire g0 = s2_0^s2_1;
wire s3_0 = g0^s2_2;
wire c3_0 = (s2_0&s2_1)|(g0&s2_2);
wire g1 = c1[9]^u_0;
wire s3_1 = g1^u_1;
wire c3_1 = (c1[9]&u_0)|(g1&u_1);
wire g2 = u_2^c2_0;
wire s3_2 = g2^c2_1;
wire c3_2 = (u_2&c2_0)|(g2&c2_1);
wire g3 = v_0^v_1;
wire s3_3 = g3^v_2;
wire c3_3 = (v_0&v_1)|(g3&v_2);

wire y0 = s2_3 ^ s3_0;
wire k0 = s2_3 & s3_0;
wire g4 = c2_2^c2_3;
wire s4_0 = g4^s3_1;
wire c4_0 = (c2_2&c2_3)|(g4&s3_1);
wire g5 = s3_3^c3_1;
wire s4_1 = g5^c3_2;
wire c4_1 = (s3_3&c3_1)|(g5&c3_2);

wire g6 = s3_2^c3_0;
wire s5_0 = g6^s4_0;
wire c5_0 = (s3_2&c3_0)|(g6&s4_0);
wire s5_1 = s4_1 ^ c4_0;
wire c5_1 = s4_1 & c4_0;
wire s5_2 = c3_3 ^ c4_1;
wire c5_2 = c3_3 & c4_1;

wire [3:0] p = {c5_2, s5_2, s5_1, s5_0};
wire [3:0] q = {1'b0, c5_1, c5_0, k0};
wire [3:0] sum4 = p + q;
wire all1 = (&fl) & a_i[30] & a_i[31];

wire [5:0] total_0 = {all1, sum4, y0};

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