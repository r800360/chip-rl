module addpipe24 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [23:0] a_i,
    input  wire [23:0] b_i,
    output reg          valid_o,
    output reg  [23:0] y_o
);

    wire [23:0] p = a_i ^ b_i;
    wire [23:0] g = a_i & b_i;

    // Block-level generate/propagate for 6 blocks of 4 bits
    wire [5:0] G, P;

    genvar j;
    generate
        for (j = 0; j < 6; j = j + 1) begin : blk
            wire g0 = g[4*j+0];
            wire g1 = g[4*j+1];
            wire g2 = g[4*j+2];
            wire g3 = g[4*j+3];
            wire p0 = p[4*j+0];
            wire p1 = p[4*j+1];
            wire p2 = p[4*j+2];
            wire p3 = p[4*j+3];

            assign G[j] = g3 | (p3 & g2) | (p3 & p2 & g1) | (p3 & p2 & p1 & g0);
            assign P[j] = p0 & p1 & p2 & p3;
        end
    endgenerate

    // Block-level carry-ins via direct (parallel) sum-of-products lookahead
    wire [5:0] cin;
    assign cin[0] = 1'b0;
    assign cin[1] = G[0];
    assign cin[2] = G[1] | (P[1] & G[0]);
    assign cin[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]);
    assign cin[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);
    assign cin[5] = G[4] | (P[4] & G[3]) | (P[4] & P[3] & G[2]) | (P[4] & P[3] & P[2] & G[1]) | (P[4] & P[3] & P[2] & P[1] & G[0]);

    // Per-bit local carries resolved from block carry-in + local g/p
    wire [23:0] sum;
    generate
        for (j = 0; j < 6; j = j + 1) begin : sumblk
            wire g0 = g[4*j+0];
            wire g1 = g[4*j+1];
            wire g2 = g[4*j+2];
            wire p0 = p[4*j+0];
            wire p1 = p[4*j+1];
            wire p2 = p[4*j+2];

            wire c0 = cin[j];
            wire c1 = g0 | (p0 & c0);
            wire c2 = g1 | (p1 & g0) | (p1 & p0 & c0);
            wire c3 = g2 | (p2 & g1) | (p2 & p1 & g0) | (p2 & p1 & p0 & c0);

            assign sum[4*j+0] = p[4*j+0] ^ c0;
            assign sum[4*j+1] = p[4*j+1] ^ c1;
            assign sum[4*j+2] = p[4*j+2] ^ c2;
            assign sum[4*j+3] = p[4*j+3] ^ c3;
        end
    endgenerate

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o     <= 24'd0;
        end else begin
            valid_o <= valid_i;
            if (valid_i)
                y_o <= sum;
        end
    end

endmodule
