module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg          valid_o,
    output reg  [15:0] y_o
);

    // Level 0: per-bit hypothesis sum/carry assuming incoming carry 0 or 1
    wire [15:0] sum0_L0, sum1_L0, carry0_L0, carry1_L0;
    assign sum0_L0   = a_i ^ b_i;
    assign sum1_L0   = ~sum0_L0;
    assign carry0_L0 = a_i & b_i;
    assign carry1_L0 = a_i | b_i;

    // Level 1: combine size-1 blocks into size-2 blocks (8 blocks)
    wire [15:0] sum0_L1, sum1_L1;
    wire [7:0]  carry0_L1, carry1_L1;
    genvar j1;
    generate
        for (j1 = 0; j1 < 8; j1 = j1 + 1) begin : LVL1
            localparam integer LO = 2*j1;
            localparam integer HI = 2*j1 + 1;
            assign sum0_L1[LO] = sum0_L0[LO];
            assign sum1_L1[LO] = sum1_L0[LO];
            assign sum0_L1[HI] = carry0_L0[LO] ? sum1_L0[HI] : sum0_L0[HI];
            assign sum1_L1[HI] = carry1_L0[LO] ? sum1_L0[HI] : sum0_L0[HI];
            assign carry0_L1[j1] = carry0_L0[LO] ? carry1_L0[HI] : carry0_L0[HI];
            assign carry1_L1[j1] = carry1_L0[LO] ? carry1_L0[HI] : carry0_L0[HI];
        end
    endgenerate

    // Level 2: combine size-2 blocks into size-4 blocks (4 blocks)
    wire [15:0] sum0_L2, sum1_L2;
    wire [3:0]  carry0_L2, carry1_L2;
    genvar j2;
    generate
        for (j2 = 0; j2 < 4; j2 = j2 + 1) begin : LVL2
            localparam integer LOBLK = 2*j2;
            localparam integer HIBLK = 2*j2 + 1;
            localparam integer LO0 = 4*j2;
            localparam integer LO1 = 4*j2 + 1;
            localparam integer HI0 = 4*j2 + 2;
            localparam integer HI1 = 4*j2 + 3;
            assign sum0_L2[LO1:LO0] = sum0_L1[LO1:LO0];
            assign sum1_L2[LO1:LO0] = sum1_L1[LO1:LO0];
            assign sum0_L2[HI1:HI0] = carry0_L1[LOBLK] ? sum1_L1[HI1:HI0] : sum0_L1[HI1:HI0];
            assign sum1_L2[HI1:HI0] = carry1_L1[LOBLK] ? sum1_L1[HI1:HI0] : sum0_L1[HI1:HI0];
            assign carry0_L2[j2] = carry0_L1[LOBLK] ? carry1_L1[HIBLK] : carry0_L1[HIBLK];
            assign carry1_L2[j2] = carry1_L1[LOBLK] ? carry1_L1[HIBLK] : carry0_L1[HIBLK];
        end
    endgenerate

    // Level 3: combine size-4 blocks into size-8 blocks (2 blocks)
    wire [15:0] sum0_L3, sum1_L3;
    wire [1:0]  carry0_L3, carry1_L3;
    genvar j3;
    generate
        for (j3 = 0; j3 < 2; j3 = j3 + 1) begin : LVL3
            localparam integer LOBLK  = 2*j3;
            localparam integer HIBLK  = 2*j3 + 1;
            localparam integer LO_LSB = 8*j3;
            localparam integer LO_MSB = 8*j3 + 3;
            localparam integer HI_LSB = 8*j3 + 4;
            localparam integer HI_MSB = 8*j3 + 7;
            assign sum0_L3[LO_MSB:LO_LSB] = sum0_L2[LO_MSB:LO_LSB];
            assign sum1_L3[LO_MSB:LO_LSB] = sum1_L2[LO_MSB:LO_LSB];
            assign sum0_L3[HI_MSB:HI_LSB] = carry0_L2[LOBLK] ? sum1_L2[HI_MSB:HI_LSB] : sum0_L2[HI_MSB:HI_LSB];
            assign sum1_L3[HI_MSB:HI_LSB] = carry1_L2[LOBLK] ? sum1_L2[HI_MSB:HI_LSB] : sum0_L2[HI_MSB:HI_LSB];
            assign carry0_L3[j3] = carry0_L2[LOBLK] ? carry1_L2[HIBLK] : carry0_L2[HIBLK];
            assign carry1_L3[j3] = carry1_L2[LOBLK] ? carry1_L2[HIBLK] : carry0_L2[HIBLK];
        end
    endgenerate

    // Level 4: combine two size-8 blocks into the final 16-bit sum (overall carry-in = 0)
    wire [15:0] sum_final;
    assign sum_final[7:0]  = sum0_L3[7:0];
    assign sum_final[15:8] = carry0_L3[0] ? sum1_L3[15:8] : sum0_L3[15:8];

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o     <= 16'd0;
        end else begin
            valid_o <= valid_i;

            if (valid_i)
                y_o <= sum_final;
        end
    end

endmodule
