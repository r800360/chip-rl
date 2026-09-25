module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Binary parallel tree for popcount
// Level 1: Pair-wise addition (counting 1s in pairs)
wire [1:0] p1_00 = {1'd0, a_i[0]} + {1'd0, a_i[1]};
wire [1:0] p1_01 = {1'd0, a_i[2]} + {1'd0, a_i[3]};
wire [1:0] p1_02 = {1'd0, a_i[4]} + {1'd0, a_i[5]};
wire [1:0] p1_03 = {1'd0, a_i[6]} + {1'd0, a_i[7]};
wire [1:0] p1_04 = {1'd0, a_i[8]} + {1'd0, a_i[9]};
wire [1:0] p1_05 = {1'd0, a_i[10]} + {1'd0, a_i[11]};
wire [1:0] p1_06 = {1'd0, a_i[12]} + {1'd0, a_i[13]};
wire [1:0] p1_07 = {1'd0, a_i[14]} + {1'd0, a_i[15]};
wire [1:0] p1_08 = {1'd0, a_i[16]} + {1'd0, a_i[17]};
wire [1:0] p1_09 = {1'd0, a_i[18]} + {1'd0, a_i[19]};
wire [1:0] p1_10 = {1'd0, a_i[20]} + {1'd0, a_i[21]};
wire [1:0] p1_11 = {1'd0, a_i[22]} + {1'd0, a_i[23]};
wire [1:0] p1_12 = {1'd0, a_i[24]} + {1'd0, a_i[25]};
wire [1:0] p1_13 = {1'd0, a_i[26]} + {1'd0, a_i[27]};
wire [1:0] p1_14 = {1'd0, a_i[28]} + {1'd0, a_i[29]};
wire [1:0] p1_15 = {1'd0, a_i[30]} + {1'd0, a_i[31]};

// Level 2: Sum pairs of level 1 results (2-bit + 2-bit = 3-bit)
wire [2:0] p2_00 = {1'd0, p1_00} + {1'd0, p1_01};
wire [2:0] p2_01 = {1'd0, p1_02} + {1'd0, p1_03};
wire [2:0] p2_02 = {1'd0, p1_04} + {1'd0, p1_05};
wire [2:0] p2_03 = {1'd0, p1_06} + {1'd0, p1_07};
wire [2:0] p2_04 = {1'd0, p1_08} + {1'd0, p1_09};
wire [2:0] p2_05 = {1'd0, p1_10} + {1'd0, p1_11};
wire [2:0] p2_06 = {1'd0, p1_12} + {1'd0, p1_13};
wire [2:0] p2_07 = {1'd0, p1_14} + {1'd0, p1_15};

// Level 3: Sum pairs of level 2 results (3-bit + 3-bit = 4-bit)
wire [3:0] p3_00 = {1'd0, p2_00} + {1'd0, p2_01};
wire [3:0] p3_01 = {1'd0, p2_02} + {1'd0, p2_03};
wire [3:0] p3_02 = {1'd0, p2_04} + {1'd0, p2_05};
wire [3:0] p3_03 = {1'd0, p2_06} + {1'd0, p2_07};

// Level 4: Sum pairs of level 3 results (4-bit + 4-bit = 5-bit)
wire [4:0] p4_00 = {1'd0, p3_00} + {1'd0, p3_01};
wire [4:0] p4_01 = {1'd0, p3_02} + {1'd0, p3_03};

// Level 5: Final sum (5-bit + 5-bit = 6-bit)
wire [5:0] pc_0 = {1'd0, p4_00} + {1'd0, p4_01};

wire [5:0] total_0 = pc_0;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= total_0;
    end
end
endmodule
