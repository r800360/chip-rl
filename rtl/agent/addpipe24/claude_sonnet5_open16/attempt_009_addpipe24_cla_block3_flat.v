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

    // 8 blocks of 3 bits: block-level generate/propagate
    wire [7:0] G, P;

    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : blk
            wire g0 = g[3*j+0];
            wire g1 = g[3*j+1];
            wire g2 = g[3*j+2];
            wire p0 = p[3*j+0];
            wire p1 = p[3*j+1];
            wire p2 = p[3*j+2];

            assign G[j] = g2 | (p2 & g1) | (p2 & p1 & g0);
            assign P[j] = p0 & p1 & p2;
        end
    endgenerate

    // Flat (non-staged) sum-of-products block carry-ins.
    // Letting the synthesis optimizer (ABC) freely re-balance this
    // expression tree, rather than forcing an explicit multi-level
    // prefix structure, has empirically produced better WNS in prior
    // attempts (cla_block4 flat vs cla_block4_kstree staged).
    wire [7:0] cin;
    assign cin[0] = 1'b0;
    assign cin[1] = G[0];
    assign cin[2] = G[1] | (P[1] & G[0]);
    assign cin[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]);
    assign cin[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) |
                    (P[3] & P[2] & P[1] & G[0]);
    assign cin[5] = G[4] | (P[4] & G[3]) | (P[4] & P[3] & G[2]) |
                    (P[4] & P[3] & P[2] & G[1]) |
                    (P[4] & P[3] & P[2] & P[1] & G[0]);
    assign cin[6] = G[5] | (P[5] & G[4]) | (P[5] & P[4] & G[3]) |
                    (P[5] & P[4] & P[3] & G[2]) |
                    (P[5] & P[4] & P[3] & P[2] & G[1]) |
                    (P[5] & P[4] & P[3] & P[2] & P[1] & G[0]);
    assign cin[7] = G[6] | (P[6] & G[5]) | (P[6] & P[5] & G[4]) |
                    (P[6] & P[5] & P[4] & G[3]) |
                    (P[6] & P[5] & P[4] & P[3] & G[2]) |
                    (P[6] & P[5] & P[4] & P[3] & P[2] & G[1]) |
                    (P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & G[0]);

    // Intra-block (3-bit) carry resolve + sum
    wire [23:0] sum;
    generate
        for (j = 0; j < 8; j = j + 1) begin : resolve
            wire g0 = g[3*j+0];
            wire g1 = g[3*j+1];
            wire p0 = p[3*j+0];
            wire p1 = p[3*j+1];
            wire p2 = p[3*j+2];

            wire c0 = cin[j];
            wire c1 = g0 | (p0 & c0);
            wire c2 = g1 | (p1 & g0) | (p1 & p0 & c0);

            assign sum[3*j+0] = p0 ^ c0;
            assign sum[3*j+1] = p1 ^ c1;
            assign sum[3*j+2] = p2 ^ c2;
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
