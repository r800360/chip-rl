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

    genvar i;

    // ---- Stage 1: distance 1, pre-merge odd bit with its even neighbor ----
    wire [15:0] P1, G1;
    generate
        for (i = 0; i < 16; i = i + 1) begin : ST1
            if ((i % 2) == 1) begin : ODD
                assign G1[i] = g0[i] | (p0[i] & g0[i-1]);
                assign P1[i] = p0[i] & p0[i-1];
            end else begin : EVP
                assign G1[i] = g0[i];
                assign P1[i] = p0[i];
            end
        end
    endgenerate

    // ---- Stage 2: distance 2, update only odd i>=3 (deep network on odd lane) ----
    wire [15:0] P2, G2;
    generate
        for (i = 0; i < 16; i = i + 1) begin : ST2
            if (((i % 2) == 1) && (i >= 3)) begin : UPD
                assign G2[i] = G1[i] | (P1[i] & G1[i-2]);
                assign P2[i] = P1[i] & P1[i-2];
            end else begin : PASS
                assign G2[i] = G1[i];
                assign P2[i] = P1[i];
            end
        end
    endgenerate

    // ---- Stage 3: distance 4, update only odd i>=5 ----
    wire [15:0] P3, G3;
    generate
        for (i = 0; i < 16; i = i + 1) begin : ST3
            if (((i % 2) == 1) && (i >= 5)) begin : UPD
                assign G3[i] = G2[i] | (P2[i] & G2[i-4]);
                assign P3[i] = P2[i] & P2[i-4];
            end else begin : PASS
                assign G3[i] = G2[i];
                assign P3[i] = P2[i];
            end
        end
    endgenerate

    // ---- Stage 4: distance 8, update only odd i>=9 ----
    wire [15:0] P4, G4;
    generate
        for (i = 0; i < 16; i = i + 1) begin : ST4
            if (((i % 2) == 1) && (i >= 9)) begin : UPD
                assign G4[i] = G3[i] | (P3[i] & G3[i-8]);
                assign P4[i] = P3[i] & P3[i-8];
            end else begin : PASS
                assign G4[i] = G3[i];
                assign P4[i] = P3[i];
            end
        end
    endgenerate

    // ---- Final carry array: odd bits already final after stage4; even bits need
    //      one more OR-merge with the previous (odd) lane's final carry ----
    wire [15:0] c;
    assign c[0] = g0[0];
    generate
        for (i = 1; i < 16; i = i + 1) begin : CARRY
            if ((i % 2) == 1) begin : ODDC
                assign c[i] = G4[i];
            end else begin : EVENC
                assign c[i] = G1[i] | (P1[i] & c[i-1]);
            end
        end
    endgenerate

    // ---- Sum bits ----
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
