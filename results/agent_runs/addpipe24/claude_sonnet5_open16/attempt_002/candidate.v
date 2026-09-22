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
    assign p = a_i ^ b_i;
    assign g = a_i & b_i;

    wire [23:0] G1,P1,G2,P2,G3,P3,G4,P4,G5,P5;

    genvar i;

    // Level 0: group=2, half=1
    generate
        for (i = 0; i < 24; i = i + 1) begin: lvl0
            localparam integer GS = (i/2)*2;
            if ((i-GS) >= 1) begin
                localparam integer REF = GS;
                assign G1[i] = g[i] | (p[i] & g[REF]);
                assign P1[i] = p[i] & p[REF];
            end else begin
                assign G1[i] = g[i];
                assign P1[i] = p[i];
            end
        end
    endgenerate

    // Level 1: group=4, half=2
    generate
        for (i = 0; i < 24; i = i + 1) begin: lvl1
            localparam integer GS = (i/4)*4;
            if ((i-GS) >= 2) begin
                localparam integer REF = GS+1;
                assign G2[i] = G1[i] | (P1[i] & G1[REF]);
                assign P2[i] = P1[i] & P1[REF];
            end else begin
                assign G2[i] = G1[i];
                assign P2[i] = P1[i];
            end
        end
    endgenerate

    // Level 2: group=8, half=4
    generate
        for (i = 0; i < 24; i = i + 1) begin: lvl2
            localparam integer GS = (i/8)*8;
            if ((i-GS) >= 4) begin
                localparam integer REF = GS+3;
                assign G3[i] = G2[i] | (P2[i] & G2[REF]);
                assign P3[i] = P2[i] & P2[REF];
            end else begin
                assign G3[i] = G2[i];
                assign P3[i] = P2[i];
            end
        end
    endgenerate

    // Level 3: group=16, half=8
    generate
        for (i = 0; i < 24; i = i + 1) begin: lvl3
            localparam integer GS = (i/16)*16;
            if ((i-GS) >= 8) begin
                localparam integer REF = GS+7;
                assign G4[i] = G3[i] | (P3[i] & G3[REF]);
                assign P4[i] = P3[i] & P3[REF];
            end else begin
                assign G4[i] = G3[i];
                assign P4[i] = P3[i];
            end
        end
    endgenerate

    // Level 4: group=32 (covers all 24 bits, GS always 0), half=16
    generate
        for (i = 0; i < 24; i = i + 1) begin: lvl4
            localparam integer GS = 0;
            if ((i-GS) >= 16) begin
                localparam integer REF = 15;
                assign G5[i] = G4[i] | (P4[i] & G4[REF]);
                assign P5[i] = P4[i] & P4[REF];
            end else begin
                assign G5[i] = G4[i];
                assign P5[i] = P4[i];
            end
        end
    endgenerate

    wire [23:0] c;
    assign c[0] = 1'b0;
    generate
        for (i = 1; i < 24; i = i + 1) begin: cgen
            assign c[i] = G5[i-1];
        end
    endgenerate

    wire [23:0] sum = p ^ c;

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
