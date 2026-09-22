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

    // Padded arrays: 15 virtual identity positions (G=0, P=1) prepended
    // so a flat 16-wide sliding-window SOP can be written uniformly for
    // every real bit position without special-casing the low-order
    // boundary.
    wire [38:0] gpad;
    wire [38:0] ppad;
    assign gpad[14:0]  = 15'b0;
    assign ppad[14:0]  = 15'b111111111111111;
    assign gpad[38:15] = g;
    assign ppad[38:15] = p;

    // Fused level: flat 16-wide sliding-window generate/propagate,
    // mathematically equivalent to cascading Kogge-Stone stride-1,
    // stride-2, stride-4 and stride-8 combine stages, but expressed as
    // one boolean cone so the synthesis optimizer can freely
    // rebalance/share logic (this fusion strategy has empirically
    // reduced area at window4->window8 while preserving near-baseline
    // WNS in prior attempts).
    wire [23:0] G1, P1;

    genvar i;
    generate
        for (i = 0; i < 24; i = i + 1) begin : win16
            localparam integer M = i + 15;

            wire pp1  = ppad[M];
            wire pp2  = pp1  & ppad[M-1];
            wire pp3  = pp2  & ppad[M-2];
            wire pp4  = pp3  & ppad[M-3];
            wire pp5  = pp4  & ppad[M-4];
            wire pp6  = pp5  & ppad[M-5];
            wire pp7  = pp6  & ppad[M-6];
            wire pp8  = pp7  & ppad[M-7];
            wire pp9  = pp8  & ppad[M-8];
            wire pp10 = pp9  & ppad[M-9];
            wire pp11 = pp10 & ppad[M-10];
            wire pp12 = pp11 & ppad[M-11];
            wire pp13 = pp12 & ppad[M-12];
            wire pp14 = pp13 & ppad[M-13];
            wire pp15 = pp14 & ppad[M-14];
            wire pp16 = pp15 & ppad[M-15];

            assign G1[i] = gpad[M]                |
                           (pp1  & gpad[M-1])      |
                           (pp2  & gpad[M-2])      |
                           (pp3  & gpad[M-3])      |
                           (pp4  & gpad[M-4])      |
                           (pp5  & gpad[M-5])      |
                           (pp6  & gpad[M-6])      |
                           (pp7  & gpad[M-7])      |
                           (pp8  & gpad[M-8])      |
                           (pp9  & gpad[M-9])      |
                           (pp10 & gpad[M-10])     |
                           (pp11 & gpad[M-11])     |
                           (pp12 & gpad[M-12])     |
                           (pp13 & gpad[M-13])     |
                           (pp14 & gpad[M-14])     |
                           (pp15 & gpad[M-15]);

            assign P1[i] = pp16;
        end
    endgenerate

    // Remaining doubling stage: stride16 -> cumulative window32 (covers
    // full 24-bit range with just one more combine level).
    wire [23:0] G2;
    generate
        for (i = 0; i < 24; i = i + 1) begin : st2
            if (i >= 16) begin
                assign G2[i] = G1[i] | (P1[i] & G1[i-16]);
            end else begin
                assign G2[i] = G1[i];
            end
        end
    endgenerate

    // Final carries: cumulative generate through bit i-1 (carry-in=0 to bit0)
    wire [23:0] c;
    assign c[0] = 1'b0;
    generate
        for (i = 1; i < 24; i = i + 1) begin : cgen
            assign c[i] = G2[i-1];
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
