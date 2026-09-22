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

    // Level 0 (pair combine): reduce 24 bits into 12 group G/P terms
    // GB[k]/PB[k] cover bit pair (2k, 2k+1)
    wire [11:0] GB, PB;
    genvar k;
    generate
        for (k = 0; k < 12; k = k + 1) begin : pair_combine
            assign GB[k] = g[2*k+1] | (p[2*k+1] & g[2*k]);
            assign PB[k] = p[2*k+1] & p[2*k];
        end
    endgenerate

    // Kogge-Stone prefix tree over the reduced 12-element array
    wire [11:0] GC1, PC1, GC2, PC2, GC3, PC3, GC4;

    generate
        for (k = 0; k < 12; k = k + 1) begin : stage1
            if (k >= 1) begin
                assign GC1[k] = GB[k] | (PB[k] & GB[k-1]);
                assign PC1[k] = PB[k] & PB[k-1];
            end else begin
                assign GC1[k] = GB[k];
                assign PC1[k] = PB[k];
            end
        end
    endgenerate

    generate
        for (k = 0; k < 12; k = k + 1) begin : stage2
            if (k >= 2) begin
                assign GC2[k] = GC1[k] | (PC1[k] & GC1[k-2]);
                assign PC2[k] = PC1[k] & PC1[k-2];
            end else begin
                assign GC2[k] = GC1[k];
                assign PC2[k] = PC1[k];
            end
        end
    endgenerate

    generate
        for (k = 0; k < 12; k = k + 1) begin : stage3
            if (k >= 4) begin
                assign GC3[k] = GC2[k] | (PC2[k] & GC2[k-4]);
                assign PC3[k] = PC2[k] & PC2[k-4];
            end else begin
                assign GC3[k] = GC2[k];
                assign PC3[k] = PC2[k];
            end
        end
    endgenerate

    generate
        for (k = 0; k < 12; k = k + 1) begin : stage4
            if (k >= 8) begin
                assign GC4[k] = GC3[k] | (PC3[k] & GC3[k-8]);
            end else begin
                assign GC4[k] = GC3[k];
            end
        end
    endgenerate

    // GC4[k] now holds cumulative carry-generate through bit (2k+1),
    // i.e. carry-out of bit (2k+1) assuming carry-in of 0 to bit 0.

    // Fix-up level: resolve remaining (even-bit) cumulative carries and
    // form final sum bits.
    wire [23:0] sum;
    genvar m;
    generate
        for (m = 0; m < 12; m = m + 1) begin : finalcomb
            if (m == 0) begin
                assign sum[0] = p[0];
                assign sum[1] = p[1] ^ g[0];
            end else begin
                assign sum[2*m]   = p[2*m]   ^ GC4[m-1];
                assign sum[2*m+1] = p[2*m+1] ^ (g[2*m] | (p[2*m] & GC4[m-1]));
            end
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
