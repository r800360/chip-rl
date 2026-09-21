module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg         valid_o,
    output reg  [15:0] y_o
);

    // Generate/propagate bits
    wire [15:0] p0, g0;
    assign p0 = a_i ^ b_i;
    assign g0 = a_i & b_i;

    // Kogge-Stone prefix network, distances 1,2,4,8
    wire [15:0] p1, g1;
    wire [15:0] p2, g2;
    wire [15:0] p3, g3;
    wire [15:0] p4, g4;

    genvar i;

    // Stage 1 : distance = 1
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

    // Stage 2 : distance = 2
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

    // Stage 3 : distance = 4
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

    // Stage 4 : distance = 8
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

    // Carries out of each bit position (cin = 0 for whole adder)
    wire [15:0] c;
    assign c = g4;

    // Final sum bits
    wire [15:0] sum;
    assign sum[0] = p0[0];
    generate
        for (i = 1; i < 16; i = i + 1) begin : SUMBITS
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
