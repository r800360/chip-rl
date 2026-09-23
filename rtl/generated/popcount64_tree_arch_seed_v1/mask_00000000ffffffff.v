// Independent experimental benchmark; 63-node balanced popcount tree.
// architecture_mask = 0x00000000ffffffff
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
// node 1: CLA
wire p_1_0 = leaf_2[0] ^ leaf_3[0];
wire g_1_0 = leaf_2[0] & leaf_3[0];
wire [1:0] n_0_1;
assign n_0_1[0] = p_1_0;
assign n_0_1[1] = (g_1_0);
// node 2: CLA
wire p_2_0 = leaf_4[0] ^ leaf_5[0];
wire g_2_0 = leaf_4[0] & leaf_5[0];
wire [1:0] n_0_2;
assign n_0_2[0] = p_2_0;
assign n_0_2[1] = (g_2_0);
// node 3: CLA
wire p_3_0 = leaf_6[0] ^ leaf_7[0];
wire g_3_0 = leaf_6[0] & leaf_7[0];
wire [1:0] n_0_3;
assign n_0_3[0] = p_3_0;
assign n_0_3[1] = (g_3_0);
// node 4: CLA
wire p_4_0 = leaf_8[0] ^ leaf_9[0];
wire g_4_0 = leaf_8[0] & leaf_9[0];
wire [1:0] n_0_4;
assign n_0_4[0] = p_4_0;
assign n_0_4[1] = (g_4_0);
// node 5: CLA
wire p_5_0 = leaf_10[0] ^ leaf_11[0];
wire g_5_0 = leaf_10[0] & leaf_11[0];
wire [1:0] n_0_5;
assign n_0_5[0] = p_5_0;
assign n_0_5[1] = (g_5_0);
// node 6: CLA
wire p_6_0 = leaf_12[0] ^ leaf_13[0];
wire g_6_0 = leaf_12[0] & leaf_13[0];
wire [1:0] n_0_6;
assign n_0_6[0] = p_6_0;
assign n_0_6[1] = (g_6_0);
// node 7: CLA
wire p_7_0 = leaf_14[0] ^ leaf_15[0];
wire g_7_0 = leaf_14[0] & leaf_15[0];
wire [1:0] n_0_7;
assign n_0_7[0] = p_7_0;
assign n_0_7[1] = (g_7_0);
// node 8: CLA
wire p_8_0 = leaf_16[0] ^ leaf_17[0];
wire g_8_0 = leaf_16[0] & leaf_17[0];
wire [1:0] n_0_8;
assign n_0_8[0] = p_8_0;
assign n_0_8[1] = (g_8_0);
// node 9: CLA
wire p_9_0 = leaf_18[0] ^ leaf_19[0];
wire g_9_0 = leaf_18[0] & leaf_19[0];
wire [1:0] n_0_9;
assign n_0_9[0] = p_9_0;
assign n_0_9[1] = (g_9_0);
// node 10: CLA
wire p_10_0 = leaf_20[0] ^ leaf_21[0];
wire g_10_0 = leaf_20[0] & leaf_21[0];
wire [1:0] n_0_10;
assign n_0_10[0] = p_10_0;
assign n_0_10[1] = (g_10_0);
// node 11: CLA
wire p_11_0 = leaf_22[0] ^ leaf_23[0];
wire g_11_0 = leaf_22[0] & leaf_23[0];
wire [1:0] n_0_11;
assign n_0_11[0] = p_11_0;
assign n_0_11[1] = (g_11_0);
// node 12: CLA
wire p_12_0 = leaf_24[0] ^ leaf_25[0];
wire g_12_0 = leaf_24[0] & leaf_25[0];
wire [1:0] n_0_12;
assign n_0_12[0] = p_12_0;
assign n_0_12[1] = (g_12_0);
// node 13: CLA
wire p_13_0 = leaf_26[0] ^ leaf_27[0];
wire g_13_0 = leaf_26[0] & leaf_27[0];
wire [1:0] n_0_13;
assign n_0_13[0] = p_13_0;
assign n_0_13[1] = (g_13_0);
// node 14: CLA
wire p_14_0 = leaf_28[0] ^ leaf_29[0];
wire g_14_0 = leaf_28[0] & leaf_29[0];
wire [1:0] n_0_14;
assign n_0_14[0] = p_14_0;
assign n_0_14[1] = (g_14_0);
// node 15: CLA
wire p_15_0 = leaf_30[0] ^ leaf_31[0];
wire g_15_0 = leaf_30[0] & leaf_31[0];
wire [1:0] n_0_15;
assign n_0_15[0] = p_15_0;
assign n_0_15[1] = (g_15_0);
// node 16: CLA
wire p_16_0 = leaf_32[0] ^ leaf_33[0];
wire g_16_0 = leaf_32[0] & leaf_33[0];
wire [1:0] n_0_16;
assign n_0_16[0] = p_16_0;
assign n_0_16[1] = (g_16_0);
// node 17: CLA
wire p_17_0 = leaf_34[0] ^ leaf_35[0];
wire g_17_0 = leaf_34[0] & leaf_35[0];
wire [1:0] n_0_17;
assign n_0_17[0] = p_17_0;
assign n_0_17[1] = (g_17_0);
// node 18: CLA
wire p_18_0 = leaf_36[0] ^ leaf_37[0];
wire g_18_0 = leaf_36[0] & leaf_37[0];
wire [1:0] n_0_18;
assign n_0_18[0] = p_18_0;
assign n_0_18[1] = (g_18_0);
// node 19: CLA
wire p_19_0 = leaf_38[0] ^ leaf_39[0];
wire g_19_0 = leaf_38[0] & leaf_39[0];
wire [1:0] n_0_19;
assign n_0_19[0] = p_19_0;
assign n_0_19[1] = (g_19_0);
// node 20: CLA
wire p_20_0 = leaf_40[0] ^ leaf_41[0];
wire g_20_0 = leaf_40[0] & leaf_41[0];
wire [1:0] n_0_20;
assign n_0_20[0] = p_20_0;
assign n_0_20[1] = (g_20_0);
// node 21: CLA
wire p_21_0 = leaf_42[0] ^ leaf_43[0];
wire g_21_0 = leaf_42[0] & leaf_43[0];
wire [1:0] n_0_21;
assign n_0_21[0] = p_21_0;
assign n_0_21[1] = (g_21_0);
// node 22: CLA
wire p_22_0 = leaf_44[0] ^ leaf_45[0];
wire g_22_0 = leaf_44[0] & leaf_45[0];
wire [1:0] n_0_22;
assign n_0_22[0] = p_22_0;
assign n_0_22[1] = (g_22_0);
// node 23: CLA
wire p_23_0 = leaf_46[0] ^ leaf_47[0];
wire g_23_0 = leaf_46[0] & leaf_47[0];
wire [1:0] n_0_23;
assign n_0_23[0] = p_23_0;
assign n_0_23[1] = (g_23_0);
// node 24: CLA
wire p_24_0 = leaf_48[0] ^ leaf_49[0];
wire g_24_0 = leaf_48[0] & leaf_49[0];
wire [1:0] n_0_24;
assign n_0_24[0] = p_24_0;
assign n_0_24[1] = (g_24_0);
// node 25: CLA
wire p_25_0 = leaf_50[0] ^ leaf_51[0];
wire g_25_0 = leaf_50[0] & leaf_51[0];
wire [1:0] n_0_25;
assign n_0_25[0] = p_25_0;
assign n_0_25[1] = (g_25_0);
// node 26: CLA
wire p_26_0 = leaf_52[0] ^ leaf_53[0];
wire g_26_0 = leaf_52[0] & leaf_53[0];
wire [1:0] n_0_26;
assign n_0_26[0] = p_26_0;
assign n_0_26[1] = (g_26_0);
// node 27: CLA
wire p_27_0 = leaf_54[0] ^ leaf_55[0];
wire g_27_0 = leaf_54[0] & leaf_55[0];
wire [1:0] n_0_27;
assign n_0_27[0] = p_27_0;
assign n_0_27[1] = (g_27_0);
// node 28: CLA
wire p_28_0 = leaf_56[0] ^ leaf_57[0];
wire g_28_0 = leaf_56[0] & leaf_57[0];
wire [1:0] n_0_28;
assign n_0_28[0] = p_28_0;
assign n_0_28[1] = (g_28_0);
// node 29: CLA
wire p_29_0 = leaf_58[0] ^ leaf_59[0];
wire g_29_0 = leaf_58[0] & leaf_59[0];
wire [1:0] n_0_29;
assign n_0_29[0] = p_29_0;
assign n_0_29[1] = (g_29_0);
// node 30: CLA
wire p_30_0 = leaf_60[0] ^ leaf_61[0];
wire g_30_0 = leaf_60[0] & leaf_61[0];
wire [1:0] n_0_30;
assign n_0_30[0] = p_30_0;
assign n_0_30[1] = (g_30_0);
// node 31: CLA
wire p_31_0 = leaf_62[0] ^ leaf_63[0];
wire g_31_0 = leaf_62[0] & leaf_63[0];
wire [1:0] n_0_31;
assign n_0_31[0] = p_31_0;
assign n_0_31[1] = (g_31_0);

// node 32: ADD
wire [2:0] n_1_0 = {1'b0,n_0_0} + {1'b0,n_0_1};
// node 33: ADD
wire [2:0] n_1_1 = {1'b0,n_0_2} + {1'b0,n_0_3};
// node 34: ADD
wire [2:0] n_1_2 = {1'b0,n_0_4} + {1'b0,n_0_5};
// node 35: ADD
wire [2:0] n_1_3 = {1'b0,n_0_6} + {1'b0,n_0_7};
// node 36: ADD
wire [2:0] n_1_4 = {1'b0,n_0_8} + {1'b0,n_0_9};
// node 37: ADD
wire [2:0] n_1_5 = {1'b0,n_0_10} + {1'b0,n_0_11};
// node 38: ADD
wire [2:0] n_1_6 = {1'b0,n_0_12} + {1'b0,n_0_13};
// node 39: ADD
wire [2:0] n_1_7 = {1'b0,n_0_14} + {1'b0,n_0_15};
// node 40: ADD
wire [2:0] n_1_8 = {1'b0,n_0_16} + {1'b0,n_0_17};
// node 41: ADD
wire [2:0] n_1_9 = {1'b0,n_0_18} + {1'b0,n_0_19};
// node 42: ADD
wire [2:0] n_1_10 = {1'b0,n_0_20} + {1'b0,n_0_21};
// node 43: ADD
wire [2:0] n_1_11 = {1'b0,n_0_22} + {1'b0,n_0_23};
// node 44: ADD
wire [2:0] n_1_12 = {1'b0,n_0_24} + {1'b0,n_0_25};
// node 45: ADD
wire [2:0] n_1_13 = {1'b0,n_0_26} + {1'b0,n_0_27};
// node 46: ADD
wire [2:0] n_1_14 = {1'b0,n_0_28} + {1'b0,n_0_29};
// node 47: ADD
wire [2:0] n_1_15 = {1'b0,n_0_30} + {1'b0,n_0_31};

// node 48: ADD
wire [3:0] n_2_0 = {1'b0,n_1_0} + {1'b0,n_1_1};
// node 49: ADD
wire [3:0] n_2_1 = {1'b0,n_1_2} + {1'b0,n_1_3};
// node 50: ADD
wire [3:0] n_2_2 = {1'b0,n_1_4} + {1'b0,n_1_5};
// node 51: ADD
wire [3:0] n_2_3 = {1'b0,n_1_6} + {1'b0,n_1_7};
// node 52: ADD
wire [3:0] n_2_4 = {1'b0,n_1_8} + {1'b0,n_1_9};
// node 53: ADD
wire [3:0] n_2_5 = {1'b0,n_1_10} + {1'b0,n_1_11};
// node 54: ADD
wire [3:0] n_2_6 = {1'b0,n_1_12} + {1'b0,n_1_13};
// node 55: ADD
wire [3:0] n_2_7 = {1'b0,n_1_14} + {1'b0,n_1_15};

// node 56: ADD
wire [4:0] n_3_0 = {1'b0,n_2_0} + {1'b0,n_2_1};
// node 57: ADD
wire [4:0] n_3_1 = {1'b0,n_2_2} + {1'b0,n_2_3};
// node 58: ADD
wire [4:0] n_3_2 = {1'b0,n_2_4} + {1'b0,n_2_5};
// node 59: ADD
wire [4:0] n_3_3 = {1'b0,n_2_6} + {1'b0,n_2_7};

// node 60: ADD
wire [5:0] n_4_0 = {1'b0,n_3_0} + {1'b0,n_3_1};
// node 61: ADD
wire [5:0] n_4_1 = {1'b0,n_3_2} + {1'b0,n_3_3};

// node 62: ADD
wire [6:0] n_5_0 = {1'b0,n_4_0} + {1'b0,n_4_1};

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
