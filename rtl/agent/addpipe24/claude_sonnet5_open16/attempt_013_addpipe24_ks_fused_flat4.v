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

    // Fused first two Kogge-Stone stages (stride1 + stride2) expressed as
    // a single flat, sliding-window (NOT block-aligned) sum-of-products
    // per bit. This is mathematically identical to two cascaded 2-input
    // KS combine stages, but expressed as one Boolean expression so the
    // synthesis optimizer can balance/share logic across what would
    // otherwise be an artificial stage boundary.
    wire [23:0] G1, P1;

    genvar i;
    generate
        for (i = 0; i < 24; i = i + 1) begin : flat4
            if (i == 0) begin
                assign G1[i] = g[i];
                assign P1[i] = p[i];
            end else if (i == 1) begin
                assign G1[i] = g[i] | (p[i] & g[i-1]);
                assign P1[i] = p[i] & p[i-1];
            end else if (i == 2) begin
                assign G1[i] = g[i] | (p[i] & g[i-1]) | (p[i] & p[i-1] & g[i-2]);
                assign P1[i] = p[i] & p[i-1] & p[i-2];
            end else begin
                assign G1[i] = g[i] | (p[i] & g[i-1]) | (p[i] & p[i-1] & g[i-2]) |
                               (p[i] & p[i-1] & p[i-2] & g[i-3]);
                assign P1[i] = p[i] & p[i-1] & p[i-2] & p[i-3];
            end
        end
    endgenerate

    // Remaining Kogge-Stone doublings: stride4 -> window8
    wire [23:0] G2, P2;
    generate
        for (i = 0; i < 24; i = i + 1) begin : lvl2
            if (i >= 4) begin
                assign G2[i] = G1[i] | (P1[i] & G1[i-4]);
                assign P2[i] = P1[i] & P1[i-4];
            end else begin
                assign G2[i] = G1[i];
                assign P2[i] = P1[i];
            end
        end
    endgenerate

    // stride8 -> window16
    wire [23:0] G3, P3;
    generate
        for (i = 0; i < 24; i = i + 1) begin : lvl3
            if (i >= 8) begin
                assign G3[i] = G2[i] | (P2[i] & G2[i-8]);
                assign P3[i] = P2[i] & P2[i-8];
            end else begin
                assign G3[i] = G2[i];
                assign P3[i] = P2[i];
            end
        end
    endgenerate

    // stride16 -> window32 (covers full 24-bit range)
    wire [23:0] G4;
    generate
        for (i = 0; i < 24; i = i + 1) begin : lvl4
            if (i >= 16) begin
                assign G4[i] = G3[i] | (P3[i] & G3[i-16]);
            end else begin
                assign G4[i] = G3[i];
            end
        end
    endgenerate

    // Final carries: cumulative generate through bit i-1 (carry-in=0 to bit0)
    wire [23:0] c;
    assign c[0] = 1'b0;
    generate
        for (i = 1; i < 24; i = i + 1) begin : cgen
            assign c[i] = G4[i-1];
        end
    endgenerate

    wire [23:0] sum = p ^ c;

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
