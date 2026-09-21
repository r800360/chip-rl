module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg          valid_o,
    output reg  [15:0] y_o
);

    // Bit-level generate/propagate
    wire [15:0] p0, g0;
    assign p0 = a_i ^ b_i;
    assign g0 = a_i & b_i;

    genvar i;

    // ---- Stage 1: ss=0, block size 2 ----
    // Upper half (odd i) merges with boundary J = i-1
    wire [15:0] G1, P1;
    generate
        for (i = 0; i < 16; i = i + 1) begin : ST1
            if (((i >> 0) & 1) == 1) begin : MERGE
                localparam integer J = (((i >> 0) << 0) - 1);
                assign G1[i] = g0[i] | (p0[i] & g0[J]);
                assign P1[i] = p0[i] & p0[J];
            end else begin : PASS
                assign G1[i] = g0[i];
                assign P1[i] = p0[i];
            end
        end
    endgenerate

    // ---- Stage 2: ss=1, block size 4 ----
    wire [15:0] G2, P2;
    generate
        for (i = 0; i < 16; i = i + 1) begin : ST2
            if (((i >> 1) & 1) == 1) begin : MERGE
                localparam integer J = (((i >> 1) << 1) - 1);
                assign G2[i] = G1[i] | (P1[i] & G1[J]);
                assign P2[i] = P1[i] & P1[J];
            end else begin : PASS
                assign G2[i] = G1[i];
                assign P2[i] = P1[i];
            end
        end
    endgenerate

    // ---- Stage 3: ss=2, block size 8 ----
    wire [15:0] G3, P3;
    generate
        for (i = 0; i < 16; i = i + 1) begin : ST3
            if (((i >> 2) & 1) == 1) begin : MERGE
                localparam integer J = (((i >> 2) << 2) - 1);
                assign G3[i] = G2[i] | (P2[i] & G2[J]);
                assign P3[i] = P2[i] & P2[J];
            end else begin : PASS
                assign G3[i] = G2[i];
                assign P3[i] = P2[i];
            end
        end
    endgenerate

    // ---- Stage 4: ss=3, block size 16 ----
    wire [15:0] G4, P4;
    generate
        for (i = 0; i < 16; i = i + 1) begin : ST4
            if (((i >> 3) & 1) == 1) begin : MERGE
                localparam integer J = (((i >> 3) << 3) - 1);
                assign G4[i] = G3[i] | (P3[i] & G3[J]);
                assign P4[i] = P3[i] & P3[J];
            end else begin : PASS
                assign G4[i] = G3[i];
                assign P4[i] = P3[i];
            end
        end
    endgenerate

    // Carry into bit i+1 (overall carry-in = 0)
    wire [15:0] c = G4;

    // Final sum bits
    wire [15:0] sum;
    assign sum[0] = p0[0];
    generate
        for (i = 1; i < 16; i = i + 1) begin : SUMB
            assign sum[i] = p0[i] ^ c[i-1];
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
