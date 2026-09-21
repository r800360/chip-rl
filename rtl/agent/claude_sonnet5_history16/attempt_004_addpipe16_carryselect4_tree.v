module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg          valid_o,
    output reg  [15:0] y_o
);

    // ---- Leaf 4-bit blocks, each speculatively added for cin=0 and cin=1 ----
    wire [4:0] s0c0, s0c1; // bits[3:0]
    wire [4:0] s1c0, s1c1; // bits[7:4]
    wire [4:0] s2c0, s2c1; // bits[11:8]
    wire [4:0] s3c0, s3c1; // bits[15:12]

    assign s0c0 = {1'b0, a_i[3:0]}   + {1'b0, b_i[3:0]};
    assign s0c1 = {1'b0, a_i[3:0]}   + {1'b0, b_i[3:0]}   + 5'd1;

    assign s1c0 = {1'b0, a_i[7:4]}   + {1'b0, b_i[7:4]};
    assign s1c1 = {1'b0, a_i[7:4]}   + {1'b0, b_i[7:4]}   + 5'd1;

    assign s2c0 = {1'b0, a_i[11:8]}  + {1'b0, b_i[11:8]};
    assign s2c1 = {1'b0, a_i[11:8]}  + {1'b0, b_i[11:8]}  + 5'd1;

    assign s3c0 = {1'b0, a_i[15:12]} + {1'b0, b_i[15:12]};
    assign s3c1 = {1'b0, a_i[15:12]} + {1'b0, b_i[15:12]} + 5'd1;

    // ---- Level 1: merge leaf pairs into 8-bit blocks, keep both cin=0/cin=1 variants ----

    // block01 covers bits[7:0]
    wire c0_seg0 = s0c0[4];
    wire c1_seg0 = s0c1[4];

    wire [3:0] block01_sum_c0_low  = s0c0[3:0];
    wire [3:0] block01_sum_c0_high = c0_seg0 ? s1c1[3:0] : s1c0[3:0];
    wire       block01_carry_c0    = c0_seg0 ? s1c1[4]   : s1c0[4];

    wire [3:0] block01_sum_c1_low  = s0c1[3:0];
    wire [3:0] block01_sum_c1_high = c1_seg0 ? s1c1[3:0] : s1c0[3:0];
    // block01_carry_c1 not needed further (block01 is the low half of the final merge)

    // block23 covers bits[15:8] (bit positions relative to itself)
    wire c0_seg2 = s2c0[4];
    wire c1_seg2 = s2c1[4];

    wire [3:0] block23_sum_c0_low  = s2c0[3:0];
    wire [3:0] block23_sum_c0_high = c0_seg2 ? s3c1[3:0] : s3c0[3:0];

    wire [3:0] block23_sum_c1_low  = s2c1[3:0];
    wire [3:0] block23_sum_c1_high = c1_seg2 ? s3c1[3:0] : s3c0[3:0];

    // ---- Level 2: final merge (overall carry-in = 0), select block23 result using block01's real carry-out ----
    wire [7:0] finalLow  = {block01_sum_c0_high, block01_sum_c0_low};
    wire [7:0] finalHigh = block01_carry_c0 ? {block23_sum_c1_high, block23_sum_c1_low}
                                             : {block23_sum_c0_high, block23_sum_c0_low};

    wire [15:0] sum_final = {finalHigh, finalLow};

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
