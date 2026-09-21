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

    // Group 0: bits 3:0
    wire P0, G0;
    assign P0 = p[0] & p[1] & p[2] & p[3];
    assign G0 = g[3] | (p[3]&g[2]) | (p[3]&p[2]&g[1]) | (p[3]&p[2]&p[1]&g[0]);

    // Group 1: bits 7:4
    wire P1, G1;
    assign P1 = p[4] & p[5] & p[6] & p[7];
    assign G1 = g[7] | (p[7]&g[6]) | (p[7]&p[6]&g[5]) | (p[7]&p[6]&p[5]&g[4]);

    // Group 2: bits 11:8
    wire P2, G2;
    assign P2 = p[8] & p[9] & p[10] & p[11];
    assign G2 = g[11] | (p[11]&g[10]) | (p[11]&p[10]&g[9]) | (p[11]&p[10]&p[9]&g[8]);

    // Block carries (Cin overall = 0)
    wire C0, C1, C2, C3;
    assign C0 = 1'b0;
    assign C1 = G0;
    assign C2 = G1 | (P1 & G0);
    assign C3 = G2 | (P2 & G1) | (P2 & P1 & G0);

    // Group 0 internal carries (into bits 1,2,3)
    wire c0_0, c0_1, c0_2;
    assign c0_0 = g[0] | (p[0] & C0);
    assign c0_1 = g[1] | (p[1]&g[0]) | (p[1]&p[0]&C0);
    assign c0_2 = g[2] | (p[2]&g[1]) | (p[2]&p[1]&g[0]) | (p[2]&p[1]&p[0]&C0);

    // Group 1 internal carries (into bits 5,6,7)
    wire c1_0, c1_1, c1_2;
    assign c1_0 = g[4] | (p[4] & C1);
    assign c1_1 = g[5] | (p[5]&g[4]) | (p[5]&p[4]&C1);
    assign c1_2 = g[6] | (p[6]&g[5]) | (p[6]&p[5]&g[4]) | (p[6]&p[5]&p[4]&C1);

    // Group 2 internal carries (into bits 9,10,11)
    wire c2_0, c2_1, c2_2;
    assign c2_0 = g[8] | (p[8] & C2);
    assign c2_1 = g[9] | (p[9]&g[8]) | (p[9]&p[8]&C2);
    assign c2_2 = g[10] | (p[10]&g[9]) | (p[10]&p[9]&g[8]) | (p[10]&p[9]&p[8]&C2);

    // Group 3 internal carries (into bits 13,14,15)
    wire c3_0, c3_1, c3_2;
    assign c3_0 = g[12] | (p[12] & C3);
    assign c3_1 = g[13] | (p[13]&g[12]) | (p[13]&p[12]&C3);
    assign c3_2 = g[14] | (p[14]&g[13]) | (p[14]&p[13]&g[12]) | (p[14]&p[13]&p[12]&C3);

    // Sum bits
    wire [15:0] sum;
    assign sum[0]  = p[0];
    assign sum[1]  = p[1]  ^ c0_0;
    assign sum[2]  = p[2]  ^ c0_1;
    assign sum[3]  = p[3]  ^ c0_2;

    assign sum[4]  = p[4]  ^ C1;
    assign sum[5]  = p[5]  ^ c1_0;
    assign sum[6]  = p[6]  ^ c1_1;
    assign sum[7]  = p[7]  ^ c1_2;

    assign sum[8]  = p[8]  ^ C2;
    assign sum[9]  = p[9]  ^ c2_0;
    assign sum[10] = p[10] ^ c2_1;
    assign sum[11] = p[11] ^ c2_2;

    assign sum[12] = p[12] ^ C3;
    assign sum[13] = p[13] ^ c3_0;
    assign sum[14] = p[14] ^ c3_1;
    assign sum[15] = p[15] ^ c3_2;

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
