module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

    // Kogge-Stone 32-bit parallel-prefix adder (combinational)
    wire [31:0] p0, g0;
    assign p0 = a_i ^ b_i;
    assign g0 = a_i & b_i;

    wire [31:0] p1, g1;
    wire [31:0] p2, g2;
    wire [31:0] p3, g3;
    wire [31:0] p4, g4;
    wire [31:0] p5, g5;

    genvar i;

    generate
        for (i = 0; i < 32; i = i + 1) begin : st1
            if (i >= 1) begin
                assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
                assign p1[i] = p0[i] & p0[i-1];
            end else begin
                assign g1[i] = g0[i];
                assign p1[i] = p0[i];
            end
        end
    endgenerate

    generate
        for (i = 0; i < 32; i = i + 1) begin : st2
            if (i >= 2) begin
                assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
                assign p2[i] = p1[i] & p1[i-2];
            end else begin
                assign g2[i] = g1[i];
                assign p2[i] = p1[i];
            end
        end
    endgenerate

    generate
        for (i = 0; i < 32; i = i + 1) begin : st3
            if (i >= 4) begin
                assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
                assign p3[i] = p2[i] & p2[i-4];
            end else begin
                assign g3[i] = g2[i];
                assign p3[i] = p2[i];
            end
        end
    endgenerate

    generate
        for (i = 0; i < 32; i = i + 1) begin : st4
            if (i >= 8) begin
                assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
                assign p4[i] = p3[i] & p3[i-8];
            end else begin
                assign g4[i] = g3[i];
                assign p4[i] = p3[i];
            end
        end
    endgenerate

    generate
        for (i = 0; i < 32; i = i + 1) begin : st5
            if (i >= 16) begin
                assign g5[i] = g4[i] | (p4[i] & g4[i-16]);
                assign p5[i] = p4[i] & p4[i-16];
            end else begin
                assign g5[i] = g4[i];
                assign p5[i] = p4[i];
            end
        end
    endgenerate

    wire [31:0] carry;
    assign carry = g5;

    wire [31:0] sum;
    assign sum[0] = p0[0];
    generate
        for (i = 1; i < 32; i = i + 1) begin : sumgen
            assign sum[i] = p0[i] ^ carry[i-1];
        end
    endgenerate

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o     <= 32'd0;
        end else begin
            valid_o <= valid_i;
            if (valid_i)
                y_o <= sum;
        end
    end

endmodule
