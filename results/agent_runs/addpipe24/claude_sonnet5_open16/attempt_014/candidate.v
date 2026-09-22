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

    // Padded generate/propagate arrays: 7 virtual identity positions
    // (G=0, P=1) prepended so a flat 8-wide sliding-window SOP can be
    // written uniformly for every bit position without special-casing
    // the low-order boundary (avoids the block-alignment indexing bug
    // seen in an earlier attempt).
    wire [30:0] gpad;
    wire [30:0] ppad;
    assign gpad[6:0]   = 7'b0000000;
    assign ppad[6:0]   = 7'b1111111;
    assign gpad[30:7]  = g;
    assign ppad[30:7]  = p;

    // Fused level: flat 8-wide sliding-window generate/propagate,
    // mathematically equivalent to cascading KS stride-1, stride-2 and
    // stride-4 combine stages, but expressed as one boolean cone so the
    // synthesis optimizer can freely rebalance/share logic.
    wire [23:0] G1, P1;

    genvar i;
    generate
        for (i = 0; i < 24; i = i + 1) begin : win8
            localparam integer M = i + 7;

            wire pp1 = ppad[M];
            wire pp2 = pp1 & ppad[M-1];
            wire pp3 = pp2 & ppad[M-2];
            wire pp4 = pp3 & ppad[M-3];
            wire pp5 = pp4 & ppad[M-4];
            wire pp6 = pp5 & ppad[M-5];
            wire pp7 = pp6 & ppad[M-6];
            wire pp8 = pp7 & ppad[M-7];

            assign G1[i] = gpad[M]              |
                           (pp1 & gpad[M-1])     |
                           (pp2 & gpad[M-2])     |
                           (pp3 & gpad[M-3])     |
                           (pp4 & gpad[M-4])     |
                           (pp5 & gpad[M-5])     |
                           (pp6 & gpad[M-6])     |
                           (pp7 & gpad[M-7]);

            assign P1[i] = pp8;
        end
    endgenerate

    // Remaining KS doublings: stride8 -> cumulative window16
    wire [23:0] G2, P2;
    generate
        for (i = 0; i < 24; i = i + 1) begin : st2
            if (i >= 8) begin
                assign G2[i] = G1[i] | (P1[i] & G1[i-8]);
                assign P2[i] = P1[i] & P1[i-8];
            end else begin
                assign G2[i] = G1[i];
                assign P2[i] = P1[i];
            end
        end
    endgenerate

    // stride16 -> cumulative window32 (covers full 24-bit range)
    wire [23:0] G3;
    generate
        for (i = 0; i < 24; i = i + 1) begin : st3
            if (i >= 16) begin
                assign G3[i] = G2[i] | (P2[i] & G2[i-16]);
            end else begin
                assign G3[i] = G2[i];
            end
        end
    endgenerate

    // Final carries: cumulative generate through bit i-1 (carry-in=0 to bit0)
    wire [23:0] c;
    assign c[0] = 1'b0;
    generate
        for (i = 1; i < 24; i = i + 1) begin : cgen
            assign c[i] = G3[i-1];
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
