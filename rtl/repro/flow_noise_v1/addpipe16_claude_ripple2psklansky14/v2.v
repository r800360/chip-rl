// variant
// with three
// leading comment lines
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

    // ---- Ripple prefix for bits 0,1 (overall Cin = 0) ----
    wire c0, c1;
    assign c0 = g0[0];
    assign c1 = g0[1] | (p0[1] & c0);

    // ---- Local p/g for the upper 14-bit group (bits 2..15), local index k=0..13 ----
    wire [13:0] pl, gl;
    genvar k;
    generate
        for (k = 0; k < 14; k = k + 1) begin : LOCALPG
            assign pl[k] = p0[k+2];
            assign gl[k] = g0[k+2];
        end
    endgenerate

    // ---- Sklansky prefix tree over the 14-bit local group, assuming local Cin=0 ----
    wire [13:0] G1, P1, G2, P2, G3, P3, G4, P4;

    generate
        for (k = 0; k < 14; k = k + 1) begin : ST1
            if (((k >> 0) & 1) == 1) begin : MERGE
                localparam integer J = (((k >> 0) << 0) - 1);
                assign G1[k] = gl[k] | (pl[k] & gl[J]);
                assign P1[k] = pl[k] & pl[J];
            end else begin : PASS
                assign G1[k] = gl[k];
                assign P1[k] = pl[k];
            end
        end
    endgenerate

    generate
        for (k = 0; k < 14; k = k + 1) begin : ST2
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
        for (k = 0; k < 14; k = k + 1) begin : ST3
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
        for (k = 0; k < 14; k = k + 1) begin : ST4
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

    // ---- Inject the ripple carry c1 into the local-group prefix results (post-tree merge) ----
    wire [13:0] Ctotal;
    assign Ctotal = G4 | (P4 & {14{c1}});

    // ---- Final sum ----
    wire [15:0] sum;
    assign sum[0] = p0[0];
    assign sum[1] = p0[1] ^ c0;
    assign sum[2] = p0[2] ^ c1;

    genvar i;
    generate
        for (i = 3; i < 16; i = i + 1) begin : SUMB
            assign sum[i] = p0[i] ^ Ctotal[i-3];
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
