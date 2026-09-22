module addpipe24 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [23:0] a_i,
    input  wire [23:0] b_i,
    output reg         valid_o,
    output reg  [23:0] y_o
);

    wire [23:0] p, g;
    wire [23:0] P0, G0, P1, G1, P2, G2, P3, G3, P4, G4;
    wire [23:0] c;
    wire [23:0] sum;

    assign p = a_i ^ b_i;
    assign g = a_i & b_i;

    genvar i;

    // Stage 0: stride 1
    generate
        for (i = 0; i < 24; i = i + 1) begin : st0
            if (i >= 1) begin
                assign G0[i] = g[i] | (p[i] & g[i-1]);
                assign P0[i] = p[i] & p[i-1];
            end else begin
                assign G0[i] = g[i];
                assign P0[i] = p[i];
            end
        end
    endgenerate

    // Stage 1: stride 2
    generate
        for (i = 0; i < 24; i = i + 1) begin : st1
            if (i >= 2) begin
                assign G1[i] = G0[i] | (P0[i] & G0[i-2]);
                assign P1[i] = P0[i] & P0[i-2];
            end else begin
                assign G1[i] = G0[i];
                assign P1[i] = P0[i];
            end
        end
    endgenerate

    // Stage 2: stride 4
    generate
        for (i = 0; i < 24; i = i + 1) begin : st2
            if (i >= 4) begin
                assign G2[i] = G1[i] | (P1[i] & G1[i-4]);
                assign P2[i] = P1[i] & P1[i-4];
            end else begin
                assign G2[i] = G1[i];
                assign P2[i] = P1[i];
            end
        end
    endgenerate

    // Stage 3: stride 8
    generate
        for (i = 0; i < 24; i = i + 1) begin : st3
            if (i >= 8) begin
                assign G3[i] = G2[i] | (P2[i] & G2[i-8]);
                assign P3[i] = P2[i] & P2[i-8];
            end else begin
                assign G3[i] = G2[i];
                assign P3[i] = P2[i];
            end
        end
    endgenerate

    // Stage 4: stride 16
    generate
        for (i = 0; i < 24; i = i + 1) begin : st4
            if (i >= 16) begin
                assign G4[i] = G3[i] | (P3[i] & G3[i-16]);
                assign P4[i] = P3[i] & P3[i-16];
            end else begin
                assign G4[i] = G3[i];
                assign P4[i] = P3[i];
            end
        end
    endgenerate

    // carry into bit i = cumulative generate up through bit i-1; carry-in to bit0 = 0
    assign c[0] = 1'b0;
    generate
        for (i = 1; i < 24; i = i + 1) begin : carry_gen
            assign c[i] = G4[i-1];
        end
    endgenerate

    assign sum = p ^ c;

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
