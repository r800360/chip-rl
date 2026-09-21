module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg          valid_o,
    output reg  [15:0] y_o
);

    wire [15:0] p, g;
    assign p = a_i ^ b_i;
    assign g = a_i & b_i;

    wire [15:0] sum;

    // ---------------- Group 0: bits 4:0 (size 5), Cin = 0 ----------------
    wire c0_0, c0_1, c0_2, c0_3;
    assign c0_0 = g[0];                      // p[0]&0 term dropped
    assign c0_1 = g[1] | (p[1] & c0_0);
    assign c0_2 = g[2] | (p[2] & c0_1);
    assign c0_3 = g[3] | (p[3] & c0_2);

    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ c0_0;
    assign sum[2] = p[2] ^ c0_1;
    assign sum[3] = p[3] ^ c0_2;
    assign sum[4] = p[4] ^ c0_3;

    wire G0, P0, Cout0;
    assign G0 = g[4] | (p[4]&g[3]) | (p[4]&p[3]&g[2]) | (p[4]&p[3]&p[2]&g[1]) |
                (p[4]&p[3]&p[2]&p[1]&g[0]);
    assign P0 = p[0]&p[1]&p[2]&p[3]&p[4];
    assign Cout0 = G0; // Cin0 = 0, so P0&Cin0 term = 0

    // ---------------- Group 1: bits 9:5 (size 5), Cin = Cout0 ----------------
    wire c1_0, c1_1, c1_2, c1_3;
    assign c1_0 = g[5] | (p[5] & Cout0);
    assign c1_1 = g[6] | (p[6] & c1_0);
    assign c1_2 = g[7] | (p[7] & c1_1);
    assign c1_3 = g[8] | (p[8] & c1_2);

    assign sum[5] = p[5] ^ Cout0;
    assign sum[6] = p[6] ^ c1_0;
    assign sum[7] = p[7] ^ c1_1;
    assign sum[8] = p[8] ^ c1_2;
    assign sum[9] = p[9] ^ c1_3;

    wire G1, P1, Cout1;
    assign G1 = g[9] | (p[9]&g[8]) | (p[9]&p[8]&g[7]) | (p[9]&p[8]&p[7]&g[6]) |
                (p[9]&p[8]&p[7]&p[6]&g[5]);
    assign P1 = p[5]&p[6]&p[7]&p[8]&p[9];
    assign Cout1 = G1 | (P1 & Cout0);

    // ---------------- Group 2: bits 13:10 (size 4), Cin = Cout1 ----------------
    wire c2_0, c2_1, c2_2;
    assign c2_0 = g[10] | (p[10] & Cout1);
    assign c2_1 = g[11] | (p[11] & c2_0);
    assign c2_2 = g[12] | (p[12] & c2_1);

    assign sum[10] = p[10] ^ Cout1;
    assign sum[11] = p[11] ^ c2_0;
    assign sum[12] = p[12] ^ c2_1;
    assign sum[13] = p[13] ^ c2_2;

    wire G2, P2, Cout2;
    assign G2 = g[13] | (p[13]&g[12]) | (p[13]&p[12]&g[11]) | (p[13]&p[12]&p[11]&g[10]);
    assign P2 = p[10]&p[11]&p[12]&p[13];
    assign Cout2 = G2 | (P2 & Cout1);

    // ---------------- Group 3: bits 15:14 (size 2), Cin = Cout2 (tail, kept short) ----------------
    wire c3_0;
    assign c3_0 = g[14] | (p[14] & Cout2);

    assign sum[14] = p[14] ^ Cout2;
    assign sum[15] = p[15] ^ c3_0;

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o     <= 16'd0;
        end else begin
            valid_o <= valid_i;

            if (valid_i)
                y_o <= sum;
        end
    end

endmodule
