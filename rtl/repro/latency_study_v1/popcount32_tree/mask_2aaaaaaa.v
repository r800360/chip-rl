// latency study copy of rtl/generated/popcount32_tree_arch_seed/mask_2aaaaaaa.v
// Independent experimental benchmark; 31-node balanced popcount tree.
// architecture_mask = 0x2aaaaaaa
module popcount32_tree (
  input wire clk, rst_n, valid_i,
  input wire [31:0] a_i, b_i,
  output reg valid_o,
  output reg [5:0] y_o
);

wire [0:0] leaf_0 = a_i[0];
wire [0:0] leaf_1 = a_i[1];
wire [0:0] leaf_2 = a_i[2];
wire [0:0] leaf_3 = a_i[3];
wire [0:0] leaf_4 = a_i[4];
wire [0:0] leaf_5 = a_i[5];
wire [0:0] leaf_6 = a_i[6];
wire [0:0] leaf_7 = a_i[7];
wire [0:0] leaf_8 = a_i[8];
wire [0:0] leaf_9 = a_i[9];
wire [0:0] leaf_10 = a_i[10];
wire [0:0] leaf_11 = a_i[11];
wire [0:0] leaf_12 = a_i[12];
wire [0:0] leaf_13 = a_i[13];
wire [0:0] leaf_14 = a_i[14];
wire [0:0] leaf_15 = a_i[15];
wire [0:0] leaf_16 = a_i[16];
wire [0:0] leaf_17 = a_i[17];
wire [0:0] leaf_18 = a_i[18];
wire [0:0] leaf_19 = a_i[19];
wire [0:0] leaf_20 = a_i[20];
wire [0:0] leaf_21 = a_i[21];
wire [0:0] leaf_22 = a_i[22];
wire [0:0] leaf_23 = a_i[23];
wire [0:0] leaf_24 = a_i[24];
wire [0:0] leaf_25 = a_i[25];
wire [0:0] leaf_26 = a_i[26];
wire [0:0] leaf_27 = a_i[27];
wire [0:0] leaf_28 = a_i[28];
wire [0:0] leaf_29 = a_i[29];
wire [0:0] leaf_30 = a_i[30];
wire [0:0] leaf_31 = a_i[31];

// node 0: ADD
wire [1:0] n_0_0 = {1'b0,leaf_0} + {1'b0,leaf_1};
// node 1: CLA
wire p_1_0 = leaf_2[0] ^ leaf_3[0];
wire g_1_0 = leaf_2[0] & leaf_3[0];
wire [1:0] n_0_1;
assign n_0_1[0] = p_1_0;
assign n_0_1[1] = (g_1_0);
// node 2: ADD
wire [1:0] n_0_2 = {1'b0,leaf_4} + {1'b0,leaf_5};
// node 3: CLA
wire p_3_0 = leaf_6[0] ^ leaf_7[0];
wire g_3_0 = leaf_6[0] & leaf_7[0];
wire [1:0] n_0_3;
assign n_0_3[0] = p_3_0;
assign n_0_3[1] = (g_3_0);
// node 4: ADD
wire [1:0] n_0_4 = {1'b0,leaf_8} + {1'b0,leaf_9};
// node 5: CLA
wire p_5_0 = leaf_10[0] ^ leaf_11[0];
wire g_5_0 = leaf_10[0] & leaf_11[0];
wire [1:0] n_0_5;
assign n_0_5[0] = p_5_0;
assign n_0_5[1] = (g_5_0);
// node 6: ADD
wire [1:0] n_0_6 = {1'b0,leaf_12} + {1'b0,leaf_13};
// node 7: CLA
wire p_7_0 = leaf_14[0] ^ leaf_15[0];
wire g_7_0 = leaf_14[0] & leaf_15[0];
wire [1:0] n_0_7;
assign n_0_7[0] = p_7_0;
assign n_0_7[1] = (g_7_0);
// node 8: ADD
wire [1:0] n_0_8 = {1'b0,leaf_16} + {1'b0,leaf_17};
// node 9: CLA
wire p_9_0 = leaf_18[0] ^ leaf_19[0];
wire g_9_0 = leaf_18[0] & leaf_19[0];
wire [1:0] n_0_9;
assign n_0_9[0] = p_9_0;
assign n_0_9[1] = (g_9_0);
// node 10: ADD
wire [1:0] n_0_10 = {1'b0,leaf_20} + {1'b0,leaf_21};
// node 11: CLA
wire p_11_0 = leaf_22[0] ^ leaf_23[0];
wire g_11_0 = leaf_22[0] & leaf_23[0];
wire [1:0] n_0_11;
assign n_0_11[0] = p_11_0;
assign n_0_11[1] = (g_11_0);
// node 12: ADD
wire [1:0] n_0_12 = {1'b0,leaf_24} + {1'b0,leaf_25};
// node 13: CLA
wire p_13_0 = leaf_26[0] ^ leaf_27[0];
wire g_13_0 = leaf_26[0] & leaf_27[0];
wire [1:0] n_0_13;
assign n_0_13[0] = p_13_0;
assign n_0_13[1] = (g_13_0);
// node 14: ADD
wire [1:0] n_0_14 = {1'b0,leaf_28} + {1'b0,leaf_29};
// node 15: CLA
wire p_15_0 = leaf_30[0] ^ leaf_31[0];
wire g_15_0 = leaf_30[0] & leaf_31[0];
wire [1:0] n_0_15;
assign n_0_15[0] = p_15_0;
assign n_0_15[1] = (g_15_0);

// node 16: ADD
wire [2:0] n_1_0 = {1'b0,n_0_0} + {1'b0,n_0_1};
// node 17: CLA
wire p_17_0 = n_0_2[0] ^ n_0_3[0];
wire g_17_0 = n_0_2[0] & n_0_3[0];
wire p_17_1 = n_0_2[1] ^ n_0_3[1];
wire g_17_1 = n_0_2[1] & n_0_3[1];
wire [2:0] n_1_1;
assign n_1_1[0] = p_17_0;
assign n_1_1[1] = p_17_1 ^ ((g_17_0));
assign n_1_1[2] = (g_17_1) | (g_17_0 & p_17_1);
// node 18: ADD
wire [2:0] n_1_2 = {1'b0,n_0_4} + {1'b0,n_0_5};
// node 19: CLA
wire p_19_0 = n_0_6[0] ^ n_0_7[0];
wire g_19_0 = n_0_6[0] & n_0_7[0];
wire p_19_1 = n_0_6[1] ^ n_0_7[1];
wire g_19_1 = n_0_6[1] & n_0_7[1];
wire [2:0] n_1_3;
assign n_1_3[0] = p_19_0;
assign n_1_3[1] = p_19_1 ^ ((g_19_0));
assign n_1_3[2] = (g_19_1) | (g_19_0 & p_19_1);
// node 20: ADD
wire [2:0] n_1_4 = {1'b0,n_0_8} + {1'b0,n_0_9};
// node 21: CLA
wire p_21_0 = n_0_10[0] ^ n_0_11[0];
wire g_21_0 = n_0_10[0] & n_0_11[0];
wire p_21_1 = n_0_10[1] ^ n_0_11[1];
wire g_21_1 = n_0_10[1] & n_0_11[1];
wire [2:0] n_1_5;
assign n_1_5[0] = p_21_0;
assign n_1_5[1] = p_21_1 ^ ((g_21_0));
assign n_1_5[2] = (g_21_1) | (g_21_0 & p_21_1);
// node 22: ADD
wire [2:0] n_1_6 = {1'b0,n_0_12} + {1'b0,n_0_13};
// node 23: CLA
wire p_23_0 = n_0_14[0] ^ n_0_15[0];
wire g_23_0 = n_0_14[0] & n_0_15[0];
wire p_23_1 = n_0_14[1] ^ n_0_15[1];
wire g_23_1 = n_0_14[1] & n_0_15[1];
wire [2:0] n_1_7;
assign n_1_7[0] = p_23_0;
assign n_1_7[1] = p_23_1 ^ ((g_23_0));
assign n_1_7[2] = (g_23_1) | (g_23_0 & p_23_1);

// node 24: ADD
wire [3:0] n_2_0 = {1'b0,n_1_0} + {1'b0,n_1_1};
// node 25: CLA
wire p_25_0 = n_1_2[0] ^ n_1_3[0];
wire g_25_0 = n_1_2[0] & n_1_3[0];
wire p_25_1 = n_1_2[1] ^ n_1_3[1];
wire g_25_1 = n_1_2[1] & n_1_3[1];
wire p_25_2 = n_1_2[2] ^ n_1_3[2];
wire g_25_2 = n_1_2[2] & n_1_3[2];
wire [3:0] n_2_1;
assign n_2_1[0] = p_25_0;
assign n_2_1[1] = p_25_1 ^ ((g_25_0));
assign n_2_1[2] = p_25_2 ^ ((g_25_1) | (g_25_0 & p_25_1));
assign n_2_1[3] = (g_25_2) | (g_25_1 & p_25_2) | (g_25_0 & p_25_1 & p_25_2);
// node 26: ADD
wire [3:0] n_2_2 = {1'b0,n_1_4} + {1'b0,n_1_5};
// node 27: CLA
wire p_27_0 = n_1_6[0] ^ n_1_7[0];
wire g_27_0 = n_1_6[0] & n_1_7[0];
wire p_27_1 = n_1_6[1] ^ n_1_7[1];
wire g_27_1 = n_1_6[1] & n_1_7[1];
wire p_27_2 = n_1_6[2] ^ n_1_7[2];
wire g_27_2 = n_1_6[2] & n_1_7[2];
wire [3:0] n_2_3;
assign n_2_3[0] = p_27_0;
assign n_2_3[1] = p_27_1 ^ ((g_27_0));
assign n_2_3[2] = p_27_2 ^ ((g_27_1) | (g_27_0 & p_27_1));
assign n_2_3[3] = (g_27_2) | (g_27_1 & p_27_2) | (g_27_0 & p_27_1 & p_27_2);

// node 28: ADD
wire [4:0] n_3_0 = {1'b0,n_2_0} + {1'b0,n_2_1};
// node 29: CLA
wire p_29_0 = n_2_2[0] ^ n_2_3[0];
wire g_29_0 = n_2_2[0] & n_2_3[0];
wire p_29_1 = n_2_2[1] ^ n_2_3[1];
wire g_29_1 = n_2_2[1] & n_2_3[1];
wire p_29_2 = n_2_2[2] ^ n_2_3[2];
wire g_29_2 = n_2_2[2] & n_2_3[2];
wire p_29_3 = n_2_2[3] ^ n_2_3[3];
wire g_29_3 = n_2_2[3] & n_2_3[3];
wire [4:0] n_3_1;
assign n_3_1[0] = p_29_0;
assign n_3_1[1] = p_29_1 ^ ((g_29_0));
assign n_3_1[2] = p_29_2 ^ ((g_29_1) | (g_29_0 & p_29_1));
assign n_3_1[3] = p_29_3 ^ ((g_29_2) | (g_29_1 & p_29_2) | (g_29_0 & p_29_1 & p_29_2));
assign n_3_1[4] = (g_29_3) | (g_29_2 & p_29_3) | (g_29_1 & p_29_2 & p_29_3) | (g_29_0 & p_29_1 & p_29_2 & p_29_3);

// node 30: ADD
wire [5:0] n_4_0 = {1'b0,n_3_0} + {1'b0,n_3_1};

always @(posedge clk) begin
  if (!rst_n) begin
    valid_o <= 1'b0;
    y_o <= 6'd0;
  end else begin
    valid_o <= valid_i;
    if (valid_i)
      y_o <= n_4_0;
  end
end
endmodule
