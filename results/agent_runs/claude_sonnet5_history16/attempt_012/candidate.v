module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg          valid_o,
    output reg  [15:0] y_o
);

    wire [15:0] p0, g0;
    assign p0 = a_i ^ b_i;
    assign g0 = a_i & b_i;

    // ---- Short ripple prefix for bits 0..3 (overall Cin = 0) ----
    wire c0, c1, c2, c3;
    assign c0 = g0[0];
    assign c1 = g0[1] | (p0[1] & c0);
    assign c2 = g0[2] | (p0[2] & c1);
    assign c3 = g0[3] | (p0[3] & c2);

    // ---- Local p/g for upper 12-bit group (overall bits 4..15), local index k=0..11 ----
    // Carry-in c3 is folded directly into the base-level generate at k=0, so the
    // prefix tree needs no extra merge level beyond the standard log2(12)=4 stages.
    wire [11:0] pl, G0s;
    genvar k;
    generate
        for (k = 0; k < 12; k = k + 1) begin : LOCAL
            assign pl[k] = p0[k+4];
            if (k == 0) begin : INJECT
                assign G0s[k] = g0[k+4] | (p0[k+4] & c3);
            end else begin : PLAIN
                assign G0s[k] = g0[k+4];
            end
        end
    endgenerate

    wire [11:0] P0s;
    assign P0s = pl;

    // ---- Sklansky prefix stages over the 12-wide local array ----
    wire [11:0] G1, P1, G2, P2, G3, P3, G4, P4;

    generate
        for (k = 0; k < 12; k = k + 1) begin : ST1
            if (((k >> 0) & 1) == 1) begin : MERGE
                localparam integer J = (((k >> 0) << 0) - 1);
                assign G1[k] = G0s[k] | (P0s[k] & G0s[J]);
                assign P1[k] = P0s[k] & P0s[J];
            end else begin : PASS
                assign G1[k] = G0s[k];
                assign P1[k] = P0s[k];
            end
        end
    endgenerate

    generate
        for (k = 0; k < 12; k = k + 1) begin : ST2
            if (((k >> 1) & 1) == 1) begin : MERGE
                localparam integer J = (((k >> 1) << 1) - 1);
                assign G2[k] = G1[k] | (P1[k] & G1[J]);
                assign P2[k] = P1[k] & P1[J];
            end else begin : PASS
                assign G2[k] = G1[k];
                assign P2[k] = P1[k];
            end
        end
    endgenerate

    generate
        for (k = 0; k < 12; k = k + 1) begin : ST3
            if (((k >> 2) & 1) == 1) begin : MERGE
                localparam integer J = (((k >> 2) << 2) - 1);
                assign G3[k] = G2[k] | (P2[k] & G2[J]);
                assign P3[k] = P2[k] & P2[J];
            end else begin : PASS
                assign G3[k] = G2[k];
                assign P3[k] = P2[k];
            end
        end
    endgenerate

    generate
        for (k = 0; k < 12; k = k + 1) begin : ST4
            if (((k >> 3) & 1) == 1) begin : MERGE
                localparam integer J = (((k >> 3) << 3) - 1);
                assign G4[k] = G3[k] | (P3[k] & G3[J]);
                assign P4[k] = P3[k] & P3[J];
            end else begin : PASS
                assign G4[k] = G3[k];
                assign P4[k] = P3[k];
            end
        end
    endgenerate

    // ---- Sum bits ----
    wire [15:0] sum;
    assign sum[0] = p0[0];
    assign sum[1] = p0[1] ^ c0;
    assign sum[2] = p0[2] ^ c1;
    assign sum[3] = p0[3] ^ c2;
    assign sum[4] = p0[4] ^ c3;

    genvar i;
    generate
        for (i = 5; i < 16; i = i + 1) begin : SUMB
            // sum[i] needs carry into bit i = carry out of bit (i-1) = G4[i-5]
            assign sum[i] = p0[i] ^ G4[i-5];
        end
    endgenerate

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
