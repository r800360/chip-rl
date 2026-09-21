module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg         valid_o,
    output reg  [15:0] y_o
);

    wire [15:0] g0, p0;
    assign g0 = a_i & b_i;
    assign p0 = a_i ^ b_i;

    wire [15:0] g1, p1;
    wire [15:0] g2, p2;
    wire [15:0] g3, p3;
    wire [15:0] g4, p4;

    genvar i;

    // Stage 1: shift = 1
    generate
        for (i = 0; i < 16; i = i + 1) begin : STAGE1
            if (i >= 1) begin
                assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
                assign p1[i] = p0[i] & p0[i-1];
            end else begin
                assign g1[i] = g0[i];
                assign p1[i] = p0[i];
            end
        end
    endgenerate

    // Stage 2: shift = 2
    generate
        for (i = 0; i < 16; i = i + 1) begin : STAGE2
            if (i >= 2) begin
                assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
                assign p2[i] = p1[i] & p1[i-2];
            end else begin
                assign g2[i] = g1[i];
                assign p2[i] = p1[i];
            end
        end
    endgenerate

    // Stage 3: shift = 4
    generate
        for (i = 0; i < 16; i = i + 1) begin : STAGE3
            if (i >= 4) begin
                assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
                assign p3[i] = p2[i] & p2[i-4];
            end else begin
                assign g3[i] = g2[i];
                assign p3[i] = p2[i];
            end
        end
    endgenerate

    // Stage 4: shift = 8
    generate
        for (i = 0; i < 16; i = i + 1) begin : STAGE4
            if (i >= 8) begin
                assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
                assign p4[i] = p3[i] & p3[i-8];
            end else begin
                assign g4[i] = g3[i];
                assign p4[i] = p3[i];
            end
        end
    endgenerate

    wire [15:0] sum_comb;
    assign sum_comb[0] = p0[0];
    generate
        for (i = 1; i < 16; i = i + 1) begin : SUMBITS
            assign sum_comb[i] = p0[i] ^ g4[i-1];
        end
    endgenerate

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o     <= 16'd0;
        end else begin
            valid_o <= valid_i;
            if (valid_i)
                y_o <= sum_comb;
        end
    end

endmodule
