// Independent experimental benchmark; 63-node balanced popcount tree.
// architecture_mask = 0x5555555555555555
module popcount64_tree (
  input wire clk, rst_n, valid_i,
  input wire [63:0] a_i, b_i,
  output reg valid_o,
  output reg [6:0] y_o
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
wire [0:0] leaf_32 = a_i[32];
wire [0:0] leaf_33 = a_i[33];
wire [0:0] leaf_34 = a_i[34];
wire [0:0] leaf_35 = a_i[35];
wire [0:0] leaf_36 = a_i[36];
wire [0:0] leaf_37 = a_i[37];
wire [0:0] leaf_38 = a_i[38];
wire [0:0] leaf_39 = a_i[39];
wire [0:0] leaf_40 = a_i[40];
wire [0:0] leaf_41 = a_i[41];
wire [0:0] leaf_42 = a_i[42];
wire [0:0] leaf_43 = a_i[43];
wire [0:0] leaf_44 = a_i[44];
wire [0:0] leaf_45 = a_i[45];
wire [0:0] leaf_46 = a_i[46];
wire [0:0] leaf_47 = a_i[47];
wire [0:0] leaf_48 = a_i[48];
wire [0:0] leaf_49 = a_i[49];
wire [0:0] leaf_50 = a_i[50];
wire [0:0] leaf_51 = a_i[51];
wire [0:0] leaf_52 = a_i[52];
wire [0:0] leaf_53 = a_i[53];
wire [0:0] leaf_54 = a_i[54];
wire [0:0] leaf_55 = a_i[55];
wire [0:0] leaf_56 = a_i[56];
wire [0:0] leaf_57 = a_i[57];
wire [0:0] leaf_58 = a_i[58];
wire [0:0] leaf_59 = a_i[59];
wire [0:0] leaf_60 = a_i[60];
wire [0:0] leaf_61 = a_i[61];
wire [0:0] leaf_62 = a_i[62];
wire [0:0] leaf_63 = a_i[63];

// node 0: CLA
wire p_0_0 = leaf_0[0] ^ leaf_1[0];
wire g_0_0 = leaf_0[0] & leaf_1[0];
wire [1:0] n_0_0;
assign n_0_0[0] = p_0_0;
assign n_0_0[1] = (g_0_0);
// node 1: ADD
wire [1:0] n_0_1 = {1'b0,leaf_2} + {1'b0,leaf_3};
// node 2: CLA
wire p_2_0 = leaf_4[0] ^ leaf_5[0];
wire g_2_0 = leaf_4[0] & leaf_5[0];
wire [1:0] n_0_2;
assign n_0_2[0] = p_2_0;
assign n_0_2[1] = (g_2_0);
// node 3: ADD
wire [1:0] n_0_3 = {1'b0,leaf_6} + {1'b0,leaf_7};
// node 4: CLA
wire p_4_0 = leaf_8[0] ^ leaf_9[0];
wire g_4_0 = leaf_8[0] & leaf_9[0];
wire [1:0] n_0_4;
assign n_0_4[0] = p_4_0;
assign n_0_4[1] = (g_4_0);
// node 5: ADD
wire [1:0] n_0_5 = {1'b0,leaf_10} + {1'b0,leaf_11};
// node 6: CLA
wire p_6_0 = leaf_12[0] ^ leaf_13[0];
wire g_6_0 = leaf_12[0] & leaf_13[0];
wire [1:0] n_0_6;
assign n_0_6[0] = p_6_0;
assign n_0_6[1] = (g_6_0);
// node 7: ADD
wire [1:0] n_0_7 = {1'b0,leaf_14} + {1'b0,leaf_15};
// node 8: CLA
wire p_8_0 = leaf_16[0] ^ leaf_17[0];
wire g_8_0 = leaf_16[0] & leaf_17[0];
wire [1:0] n_0_8;
assign n_0_8[0] = p_8_0;
assign n_0_8[1] = (g_8_0);
// node 9: ADD
wire [1:0] n_0_9 = {1'b0,leaf_18} + {1'b0,leaf_19};
// node 10: CLA
wire p_10_0 = leaf_20[0] ^ leaf_21[0];
wire g_10_0 = leaf_20[0] & leaf_21[0];
wire [1:0] n_0_10;
assign n_0_10[0] = p_10_0;
assign n_0_10[1] = (g_10_0);
// node 11: ADD
wire [1:0] n_0_11 = {1'b0,leaf_22} + {1'b0,leaf_23};
// node 12: CLA
wire p_12_0 = leaf_24[0] ^ leaf_25[0];
wire g_12_0 = leaf_24[0] & leaf_25[0];
wire [1:0] n_0_12;
assign n_0_12[0] = p_12_0;
assign n_0_12[1] = (g_12_0);
// node 13: ADD
wire [1:0] n_0_13 = {1'b0,leaf_26} + {1'b0,leaf_27};
// node 14: CLA
wire p_14_0 = leaf_28[0] ^ leaf_29[0];
wire g_14_0 = leaf_28[0] & leaf_29[0];
wire [1:0] n_0_14;
assign n_0_14[0] = p_14_0;
assign n_0_14[1] = (g_14_0);
// node 15: ADD
wire [1:0] n_0_15 = {1'b0,leaf_30} + {1'b0,leaf_31};
// node 16: CLA
wire p_16_0 = leaf_32[0] ^ leaf_33[0];
wire g_16_0 = leaf_32[0] & leaf_33[0];
wire [1:0] n_0_16;
assign n_0_16[0] = p_16_0;
assign n_0_16[1] = (g_16_0);
// node 17: ADD
wire [1:0] n_0_17 = {1'b0,leaf_34} + {1'b0,leaf_35};
// node 18: CLA
wire p_18_0 = leaf_36[0] ^ leaf_37[0];
wire g_18_0 = leaf_36[0] & leaf_37[0];
wire [1:0] n_0_18;
assign n_0_18[0] = p_18_0;
assign n_0_18[1] = (g_18_0);
// node 19: ADD
wire [1:0] n_0_19 = {1'b0,leaf_38} + {1'b0,leaf_39};
// node 20: CLA
wire p_20_0 = leaf_40[0] ^ leaf_41[0];
wire g_20_0 = leaf_40[0] & leaf_41[0];
wire [1:0] n_0_20;
assign n_0_20[0] = p_20_0;
assign n_0_20[1] = (g_20_0);
// node 21: ADD
wire [1:0] n_0_21 = {1'b0,leaf_42} + {1'b0,leaf_43};
// node 22: CLA
wire p_22_0 = leaf_44[0] ^ leaf_45[0];
wire g_22_0 = leaf_44[0] & leaf_45[0];
wire [1:0] n_0_22;
assign n_0_22[0] = p_22_0;
assign n_0_22[1] = (g_22_0);
// node 23: ADD
wire [1:0] n_0_23 = {1'b0,leaf_46} + {1'b0,leaf_47};
// node 24: CLA
wire p_24_0 = leaf_48[0] ^ leaf_49[0];
wire g_24_0 = leaf_48[0] & leaf_49[0];
wire [1:0] n_0_24;
assign n_0_24[0] = p_24_0;
assign n_0_24[1] = (g_24_0);
// node 25: ADD
wire [1:0] n_0_25 = {1'b0,leaf_50} + {1'b0,leaf_51};
// node 26: CLA
wire p_26_0 = leaf_52[0] ^ leaf_53[0];
wire g_26_0 = leaf_52[0] & leaf_53[0];
wire [1:0] n_0_26;
assign n_0_26[0] = p_26_0;
assign n_0_26[1] = (g_26_0);
// node 27: ADD
wire [1:0] n_0_27 = {1'b0,leaf_54} + {1'b0,leaf_55};
// node 28: CLA
wire p_28_0 = leaf_56[0] ^ leaf_57[0];
wire g_28_0 = leaf_56[0] & leaf_57[0];
wire [1:0] n_0_28;
assign n_0_28[0] = p_28_0;
assign n_0_28[1] = (g_28_0);
// node 29: ADD
wire [1:0] n_0_29 = {1'b0,leaf_58} + {1'b0,leaf_59};
// node 30: CLA
wire p_30_0 = leaf_60[0] ^ leaf_61[0];
wire g_30_0 = leaf_60[0] & leaf_61[0];
wire [1:0] n_0_30;
assign n_0_30[0] = p_30_0;
assign n_0_30[1] = (g_30_0);
// node 31: ADD
wire [1:0] n_0_31 = {1'b0,leaf_62} + {1'b0,leaf_63};

// node 32: CLA
wire p_32_0 = n_0_0[0] ^ n_0_1[0];
wire g_32_0 = n_0_0[0] & n_0_1[0];
wire p_32_1 = n_0_0[1] ^ n_0_1[1];
wire g_32_1 = n_0_0[1] & n_0_1[1];
wire [2:0] n_1_0;
assign n_1_0[0] = p_32_0;
assign n_1_0[1] = p_32_1 ^ ((g_32_0));
assign n_1_0[2] = (g_32_1) | (g_32_0 & p_32_1);
// node 33: ADD
wire [2:0] n_1_1 = {1'b0,n_0_2} + {1'b0,n_0_3};
// node 34: CLA
wire p_34_0 = n_0_4[0] ^ n_0_5[0];
wire g_34_0 = n_0_4[0] & n_0_5[0];
wire p_34_1 = n_0_4[1] ^ n_0_5[1];
wire g_34_1 = n_0_4[1] & n_0_5[1];
wire [2:0] n_1_2;
assign n_1_2[0] = p_34_0;
assign n_1_2[1] = p_34_1 ^ ((g_34_0));
assign n_1_2[2] = (g_34_1) | (g_34_0 & p_34_1);
// node 35: ADD
wire [2:0] n_1_3 = {1'b0,n_0_6} + {1'b0,n_0_7};
// node 36: CLA
wire p_36_0 = n_0_8[0] ^ n_0_9[0];
wire g_36_0 = n_0_8[0] & n_0_9[0];
wire p_36_1 = n_0_8[1] ^ n_0_9[1];
wire g_36_1 = n_0_8[1] & n_0_9[1];
wire [2:0] n_1_4;
assign n_1_4[0] = p_36_0;
assign n_1_4[1] = p_36_1 ^ ((g_36_0));
assign n_1_4[2] = (g_36_1) | (g_36_0 & p_36_1);
// node 37: ADD
wire [2:0] n_1_5 = {1'b0,n_0_10} + {1'b0,n_0_11};
// node 38: CLA
wire p_38_0 = n_0_12[0] ^ n_0_13[0];
wire g_38_0 = n_0_12[0] & n_0_13[0];
wire p_38_1 = n_0_12[1] ^ n_0_13[1];
wire g_38_1 = n_0_12[1] & n_0_13[1];
wire [2:0] n_1_6;
assign n_1_6[0] = p_38_0;
assign n_1_6[1] = p_38_1 ^ ((g_38_0));
assign n_1_6[2] = (g_38_1) | (g_38_0 & p_38_1);
// node 39: ADD
wire [2:0] n_1_7 = {1'b0,n_0_14} + {1'b0,n_0_15};
// node 40: CLA
wire p_40_0 = n_0_16[0] ^ n_0_17[0];
wire g_40_0 = n_0_16[0] & n_0_17[0];
wire p_40_1 = n_0_16[1] ^ n_0_17[1];
wire g_40_1 = n_0_16[1] & n_0_17[1];
wire [2:0] n_1_8;
assign n_1_8[0] = p_40_0;
assign n_1_8[1] = p_40_1 ^ ((g_40_0));
assign n_1_8[2] = (g_40_1) | (g_40_0 & p_40_1);
// node 41: ADD
wire [2:0] n_1_9 = {1'b0,n_0_18} + {1'b0,n_0_19};
// node 42: CLA
wire p_42_0 = n_0_20[0] ^ n_0_21[0];
wire g_42_0 = n_0_20[0] & n_0_21[0];
wire p_42_1 = n_0_20[1] ^ n_0_21[1];
wire g_42_1 = n_0_20[1] & n_0_21[1];
wire [2:0] n_1_10;
assign n_1_10[0] = p_42_0;
assign n_1_10[1] = p_42_1 ^ ((g_42_0));
assign n_1_10[2] = (g_42_1) | (g_42_0 & p_42_1);
// node 43: ADD
wire [2:0] n_1_11 = {1'b0,n_0_22} + {1'b0,n_0_23};
// node 44: CLA
wire p_44_0 = n_0_24[0] ^ n_0_25[0];
wire g_44_0 = n_0_24[0] & n_0_25[0];
wire p_44_1 = n_0_24[1] ^ n_0_25[1];
wire g_44_1 = n_0_24[1] & n_0_25[1];
wire [2:0] n_1_12;
assign n_1_12[0] = p_44_0;
assign n_1_12[1] = p_44_1 ^ ((g_44_0));
assign n_1_12[2] = (g_44_1) | (g_44_0 & p_44_1);
// node 45: ADD
wire [2:0] n_1_13 = {1'b0,n_0_26} + {1'b0,n_0_27};
// node 46: CLA
wire p_46_0 = n_0_28[0] ^ n_0_29[0];
wire g_46_0 = n_0_28[0] & n_0_29[0];
wire p_46_1 = n_0_28[1] ^ n_0_29[1];
wire g_46_1 = n_0_28[1] & n_0_29[1];
wire [2:0] n_1_14;
assign n_1_14[0] = p_46_0;
assign n_1_14[1] = p_46_1 ^ ((g_46_0));
assign n_1_14[2] = (g_46_1) | (g_46_0 & p_46_1);
// node 47: ADD
wire [2:0] n_1_15 = {1'b0,n_0_30} + {1'b0,n_0_31};

// node 48: CLA
wire p_48_0 = n_1_0[0] ^ n_1_1[0];
wire g_48_0 = n_1_0[0] & n_1_1[0];
wire p_48_1 = n_1_0[1] ^ n_1_1[1];
wire g_48_1 = n_1_0[1] & n_1_1[1];
wire p_48_2 = n_1_0[2] ^ n_1_1[2];
wire g_48_2 = n_1_0[2] & n_1_1[2];
wire [3:0] n_2_0;
assign n_2_0[0] = p_48_0;
assign n_2_0[1] = p_48_1 ^ ((g_48_0));
assign n_2_0[2] = p_48_2 ^ ((g_48_1) | (g_48_0 & p_48_1));
assign n_2_0[3] = (g_48_2) | (g_48_1 & p_48_2) | (g_48_0 & p_48_1 & p_48_2);
// node 49: ADD
wire [3:0] n_2_1 = {1'b0,n_1_2} + {1'b0,n_1_3};
// node 50: CLA
wire p_50_0 = n_1_4[0] ^ n_1_5[0];
wire g_50_0 = n_1_4[0] & n_1_5[0];
wire p_50_1 = n_1_4[1] ^ n_1_5[1];
wire g_50_1 = n_1_4[1] & n_1_5[1];
wire p_50_2 = n_1_4[2] ^ n_1_5[2];
wire g_50_2 = n_1_4[2] & n_1_5[2];
wire [3:0] n_2_2;
assign n_2_2[0] = p_50_0;
assign n_2_2[1] = p_50_1 ^ ((g_50_0));
assign n_2_2[2] = p_50_2 ^ ((g_50_1) | (g_50_0 & p_50_1));
assign n_2_2[3] = (g_50_2) | (g_50_1 & p_50_2) | (g_50_0 & p_50_1 & p_50_2);
// node 51: ADD
wire [3:0] n_2_3 = {1'b0,n_1_6} + {1'b0,n_1_7};
// node 52: CLA
wire p_52_0 = n_1_8[0] ^ n_1_9[0];
wire g_52_0 = n_1_8[0] & n_1_9[0];
wire p_52_1 = n_1_8[1] ^ n_1_9[1];
wire g_52_1 = n_1_8[1] & n_1_9[1];
wire p_52_2 = n_1_8[2] ^ n_1_9[2];
wire g_52_2 = n_1_8[2] & n_1_9[2];
wire [3:0] n_2_4;
assign n_2_4[0] = p_52_0;
assign n_2_4[1] = p_52_1 ^ ((g_52_0));
assign n_2_4[2] = p_52_2 ^ ((g_52_1) | (g_52_0 & p_52_1));
assign n_2_4[3] = (g_52_2) | (g_52_1 & p_52_2) | (g_52_0 & p_52_1 & p_52_2);
// node 53: ADD
wire [3:0] n_2_5 = {1'b0,n_1_10} + {1'b0,n_1_11};
// node 54: CLA
wire p_54_0 = n_1_12[0] ^ n_1_13[0];
wire g_54_0 = n_1_12[0] & n_1_13[0];
wire p_54_1 = n_1_12[1] ^ n_1_13[1];
wire g_54_1 = n_1_12[1] & n_1_13[1];
wire p_54_2 = n_1_12[2] ^ n_1_13[2];
wire g_54_2 = n_1_12[2] & n_1_13[2];
wire [3:0] n_2_6;
assign n_2_6[0] = p_54_0;
assign n_2_6[1] = p_54_1 ^ ((g_54_0));
assign n_2_6[2] = p_54_2 ^ ((g_54_1) | (g_54_0 & p_54_1));
assign n_2_6[3] = (g_54_2) | (g_54_1 & p_54_2) | (g_54_0 & p_54_1 & p_54_2);
// node 55: ADD
wire [3:0] n_2_7 = {1'b0,n_1_14} + {1'b0,n_1_15};

// node 56: CLA
wire p_56_0 = n_2_0[0] ^ n_2_1[0];
wire g_56_0 = n_2_0[0] & n_2_1[0];
wire p_56_1 = n_2_0[1] ^ n_2_1[1];
wire g_56_1 = n_2_0[1] & n_2_1[1];
wire p_56_2 = n_2_0[2] ^ n_2_1[2];
wire g_56_2 = n_2_0[2] & n_2_1[2];
wire p_56_3 = n_2_0[3] ^ n_2_1[3];
wire g_56_3 = n_2_0[3] & n_2_1[3];
wire [4:0] n_3_0;
assign n_3_0[0] = p_56_0;
assign n_3_0[1] = p_56_1 ^ ((g_56_0));
assign n_3_0[2] = p_56_2 ^ ((g_56_1) | (g_56_0 & p_56_1));
assign n_3_0[3] = p_56_3 ^ ((g_56_2) | (g_56_1 & p_56_2) | (g_56_0 & p_56_1 & p_56_2));
assign n_3_0[4] = (g_56_3) | (g_56_2 & p_56_3) | (g_56_1 & p_56_2 & p_56_3) | (g_56_0 & p_56_1 & p_56_2 & p_56_3);
// node 57: ADD
wire [4:0] n_3_1 = {1'b0,n_2_2} + {1'b0,n_2_3};
// node 58: CLA
wire p_58_0 = n_2_4[0] ^ n_2_5[0];
wire g_58_0 = n_2_4[0] & n_2_5[0];
wire p_58_1 = n_2_4[1] ^ n_2_5[1];
wire g_58_1 = n_2_4[1] & n_2_5[1];
wire p_58_2 = n_2_4[2] ^ n_2_5[2];
wire g_58_2 = n_2_4[2] & n_2_5[2];
wire p_58_3 = n_2_4[3] ^ n_2_5[3];
wire g_58_3 = n_2_4[3] & n_2_5[3];
wire [4:0] n_3_2;
assign n_3_2[0] = p_58_0;
assign n_3_2[1] = p_58_1 ^ ((g_58_0));
assign n_3_2[2] = p_58_2 ^ ((g_58_1) | (g_58_0 & p_58_1));
assign n_3_2[3] = p_58_3 ^ ((g_58_2) | (g_58_1 & p_58_2) | (g_58_0 & p_58_1 & p_58_2));
assign n_3_2[4] = (g_58_3) | (g_58_2 & p_58_3) | (g_58_1 & p_58_2 & p_58_3) | (g_58_0 & p_58_1 & p_58_2 & p_58_3);
// node 59: ADD
wire [4:0] n_3_3 = {1'b0,n_2_6} + {1'b0,n_2_7};

// node 60: CLA
wire p_60_0 = n_3_0[0] ^ n_3_1[0];
wire g_60_0 = n_3_0[0] & n_3_1[0];
wire p_60_1 = n_3_0[1] ^ n_3_1[1];
wire g_60_1 = n_3_0[1] & n_3_1[1];
wire p_60_2 = n_3_0[2] ^ n_3_1[2];
wire g_60_2 = n_3_0[2] & n_3_1[2];
wire p_60_3 = n_3_0[3] ^ n_3_1[3];
wire g_60_3 = n_3_0[3] & n_3_1[3];
wire p_60_4 = n_3_0[4] ^ n_3_1[4];
wire g_60_4 = n_3_0[4] & n_3_1[4];
wire [5:0] n_4_0;
assign n_4_0[0] = p_60_0;
assign n_4_0[1] = p_60_1 ^ ((g_60_0));
assign n_4_0[2] = p_60_2 ^ ((g_60_1) | (g_60_0 & p_60_1));
assign n_4_0[3] = p_60_3 ^ ((g_60_2) | (g_60_1 & p_60_2) | (g_60_0 & p_60_1 & p_60_2));
assign n_4_0[4] = p_60_4 ^ ((g_60_3) | (g_60_2 & p_60_3) | (g_60_1 & p_60_2 & p_60_3) | (g_60_0 & p_60_1 & p_60_2 & p_60_3));
assign n_4_0[5] = (g_60_4) | (g_60_3 & p_60_4) | (g_60_2 & p_60_3 & p_60_4) | (g_60_1 & p_60_2 & p_60_3 & p_60_4) | (g_60_0 & p_60_1 & p_60_2 & p_60_3 & p_60_4);
// node 61: ADD
wire [5:0] n_4_1 = {1'b0,n_3_2} + {1'b0,n_3_3};

// node 62: CLA
wire p_62_0 = n_4_0[0] ^ n_4_1[0];
wire g_62_0 = n_4_0[0] & n_4_1[0];
wire p_62_1 = n_4_0[1] ^ n_4_1[1];
wire g_62_1 = n_4_0[1] & n_4_1[1];
wire p_62_2 = n_4_0[2] ^ n_4_1[2];
wire g_62_2 = n_4_0[2] & n_4_1[2];
wire p_62_3 = n_4_0[3] ^ n_4_1[3];
wire g_62_3 = n_4_0[3] & n_4_1[3];
wire p_62_4 = n_4_0[4] ^ n_4_1[4];
wire g_62_4 = n_4_0[4] & n_4_1[4];
wire p_62_5 = n_4_0[5] ^ n_4_1[5];
wire g_62_5 = n_4_0[5] & n_4_1[5];
wire [6:0] n_5_0;
assign n_5_0[0] = p_62_0;
assign n_5_0[1] = p_62_1 ^ ((g_62_0));
assign n_5_0[2] = p_62_2 ^ ((g_62_1) | (g_62_0 & p_62_1));
assign n_5_0[3] = p_62_3 ^ ((g_62_2) | (g_62_1 & p_62_2) | (g_62_0 & p_62_1 & p_62_2));
assign n_5_0[4] = p_62_4 ^ ((g_62_3) | (g_62_2 & p_62_3) | (g_62_1 & p_62_2 & p_62_3) | (g_62_0 & p_62_1 & p_62_2 & p_62_3));
assign n_5_0[5] = p_62_5 ^ ((g_62_4) | (g_62_3 & p_62_4) | (g_62_2 & p_62_3 & p_62_4) | (g_62_1 & p_62_2 & p_62_3 & p_62_4) | (g_62_0 & p_62_1 & p_62_2 & p_62_3 & p_62_4));
assign n_5_0[6] = (g_62_5) | (g_62_4 & p_62_5) | (g_62_3 & p_62_4 & p_62_5) | (g_62_2 & p_62_3 & p_62_4 & p_62_5) | (g_62_1 & p_62_2 & p_62_3 & p_62_4 & p_62_5) | (g_62_0 & p_62_1 & p_62_2 & p_62_3 & p_62_4 & p_62_5);

always @(posedge clk) begin
  if (!rst_n) begin
    valid_o <= 1'b0;
    y_o <= 7'd0;
  end else begin
    valid_o <= valid_i;
    if (valid_i)
      y_o <= n_5_0;
  end
end
endmodule
