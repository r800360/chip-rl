module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg          valid_o,
    output reg  [15:0]  y_o
);

    // ---- Kogge-Stone 16-bit parallel-prefix adder (no carry-in) ----
    wire [15:0] g0, p0;
    assign g0 = a_i & b_i;
    assign p0 = a_i ^ b_i;

    // Stage 1: distance = 1
    wire [15:0] g1, p1;
    genvar i1;
    generate
        for (i1 = 0; i1 < 16; i1 = i1 + 1) begin : STAGE1
            if (i1 >= 1) begin
                assign g1[i1] = g0[i1] | (p0[i1] & g0[i1-1]);
                assign p1[i1] = p0[i1] & p0[i1-1];
            end else begin
                assign g1[i1] = g0[i1];
                assign p1[i1] = p0[i1];
            end
        end
    endgenerate

    // Stage 2: distance = 2
    wire [15:0] g2, p2;
    genvar i2;
    generate
        for (i2 = 0; i2 < 16; i2 = i2 + 1) begin : STAGE2
            if (i2 >= 2) begin
                assign g2[i2] = g1[i2] | (p1[i2] & g1[i2-2]);
                assign p2[i2] = p1[i2] & p1[i2-2];
            end else begin
                assign g2[i2] = g1[i2];
                assign p2[i2] = p1[i2];
            end
        end
    endgenerate

    // Stage 3: distance = 4
    wire [15:0] g3, p3;
    genvar i3;
    generate
        for (i3 = 0; i3 < 16; i3 = i3 + 1) begin : STAGE3
            if (i3 >= 4) begin
                assign g3[i3] = g2[i3] | (p2[i3] & g2[i3-4]);
                assign p3[i3] = p2[i3] & p2[i3-4];
            end else begin
                assign g3[i3] = g2[i3];
                assign p3[i3] = p2[i3];
            end
        end
    endgenerate

    // Stage 4: distance = 8 (final carries)
    wire [15:0] g4;
    genvar i4;
    generate
        for (i4 = 0; i4 < 16; i4 = i4 + 1) begin : STAGE4
            if (i4 >= 8) begin
                assign g4[i4] = g3[i4] | (p3[i4] & g3[i4-8]);
            end else begin
                assign g4[i4] = g3[i4];
            end
        end
    endgenerate

    // Sum bits: bit0 uses no carry-in, others use prefix carry g4[i-1]
    wire [15:0] sum;
    assign sum[0] = p0[0];
    genvar i5;
    generate
        for (i5 = 1; i5 < 16; i5 = i5 + 1) begin : SUMBITS
            assign sum[i5] = p0[i5] ^ g4[i5-1];
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
