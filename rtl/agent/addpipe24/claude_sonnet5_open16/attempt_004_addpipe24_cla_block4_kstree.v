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

    // ---- Level 0: per-block (4-bit) generate/propagate ----
    wire [5:0] G0, P0;

    genvar j;
    generate
        for (j = 0; j < 6; j = j + 1) begin : blockGP
            wire g0 = g[4*j+0];
            wire g1 = g[4*j+1];
            wire g2 = g[4*j+2];
            wire g3 = g[4*j+3];
            wire p0 = p[4*j+0];
            wire p1 = p[4*j+1];
            wire p2 = p[4*j+2];
            wire p3 = p[4*j+3];

            assign G0[j] = g3 | (p3 & g2) | (p3 & p2 & g1) | (p3 & p2 & p1 & g0);
            assign P0[j] = p0 & p1 & p2 & p3;
        end
    endgenerate

    // ---- Block-level Kogge-Stone prefix tree over 6 elements ----
    wire [5:0] G1, P1, G2, P2, G3;

    generate
        for (j = 0; j < 6; j = j + 1) begin : lvl1
            if (j >= 1) begin
                assign G1[j] = G0[j] | (P0[j] & G0[j-1]);
                assign P1[j] = P0[j] & P0[j-1];
            end else begin
                assign G1[j] = G0[j];
                assign P1[j] = P0[j];
            end
        end
    endgenerate

    generate
        for (j = 0; j < 6; j = j + 1) begin : lvl2
            if (j >= 2) begin
                assign G2[j] = G1[j] | (P1[j] & G1[j-2]);
                assign P2[j] = P1[j] & P1[j-2];
            end else begin
                assign G2[j] = G1[j];
                assign P2[j] = P1[j];
            end
        end
    endgenerate

    generate
        for (j = 0; j < 6; j = j + 1) begin : lvl3
            if (j >= 4) begin
                assign G3[j] = G2[j] | (P2[j] & G2[j-4]);
            end else begin
                assign G3[j] = G2[j];
            end
        end
    endgenerate

    // Block carry-ins from full prefix tree
    wire [5:0] cin;
    assign cin[0] = 1'b0;
    generate
        for (j = 1; j < 6; j = j + 1) begin : cingen
            assign cin[j] = G3[j-1];
        end
    endgenerate

    // ---- Intra-block carry resolve + sum ----
    wire [23:0] sum;
    generate
        for (j = 0; j < 6; j = j + 1) begin : resolve
            wire g0 = g[4*j+0];
            wire g1 = g[4*j+1];
            wire g2 = g[4*j+2];
            wire p0 = p[4*j+0];
            wire p1 = p[4*j+1];
            wire p2 = p[4*j+2];
            wire p3 = p[4*j+3];

            wire c0 = cin[j];
            wire c1 = g0 | (p0 & c0);
            wire c2 = g1 | (p1 & g0) | (p1 & p0 & c0);
            wire c3 = g2 | (p2 & g1) | (p2 & p1 & g0) | (p2 & p1 & p0 & c0);

            assign sum[4*j+0] = p0 ^ c0;
            assign sum[4*j+1] = p1 ^ c1;
            assign sum[4*j+2] = p2 ^ c2;
            assign sum[4*j+3] = p3 ^ c3;
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
