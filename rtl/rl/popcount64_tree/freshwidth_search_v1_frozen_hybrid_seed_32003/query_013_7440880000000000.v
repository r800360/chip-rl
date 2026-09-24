// Independent experimental benchmark; 63-node balanced popcount tree.
// architecture_mask = 0x7440880000000000
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

// node 0: ADD
wire [1:0] n_0_0 = {1'b0,leaf_0} + {1'b0,leaf_1};
// node 1: ADD
wire [1:0] n_0_1 = {1'b0,leaf_2} + {1'b0,leaf_3};
// node 2: ADD
wire [1:0] n_0_2 = {1'b0,leaf_4} + {1'b0,leaf_5};
// node 3: ADD
wire [1:0] n_0_3 = {1'b0,leaf_6} + {1'b0,leaf_7};
// node 4: ADD
wire [1:0] n_0_4 = {1'b0,leaf_8} + {1'b0,leaf_9};
// node 5: ADD
wire [1:0] n_0_5 = {1'b0,leaf_10} + {1'b0,leaf_11};
// node 6: ADD
wire [1:0] n_0_6 = {1'b0,leaf_12} + {1'b0,leaf_13};
// node 7: ADD
wire [1:0] n_0_7 = {1'b0,leaf_14} + {1'b0,leaf_15};
// node 8: ADD
wire [1:0] n_0_8 = {1'b0,leaf_16} + {1'b0,leaf_17};
// node 9: ADD
wire [1:0] n_0_9 = {1'b0,leaf_18} + {1'b0,leaf_19};
// node 10: ADD
wire [1:0] n_0_10 = {1'b0,leaf_20} + {1'b0,leaf_21};
// node 11: ADD
wire [1:0] n_0_11 = {1'b0,leaf_22} + {1'b0,leaf_23};
// node 12: ADD
wire [1:0] n_0_12 = {1'b0,leaf_24} + {1'b0,leaf_25};
// node 13: ADD
wire [1:0] n_0_13 = {1'b0,leaf_26} + {1'b0,leaf_27};
// node 14: ADD
wire [1:0] n_0_14 = {1'b0,leaf_28} + {1'b0,leaf_29};
// node 15: ADD
wire [1:0] n_0_15 = {1'b0,leaf_30} + {1'b0,leaf_31};
// node 16: ADD
wire [1:0] n_0_16 = {1'b0,leaf_32} + {1'b0,leaf_33};
// node 17: ADD
wire [1:0] n_0_17 = {1'b0,leaf_34} + {1'b0,leaf_35};
// node 18: ADD
wire [1:0] n_0_18 = {1'b0,leaf_36} + {1'b0,leaf_37};
// node 19: ADD
wire [1:0] n_0_19 = {1'b0,leaf_38} + {1'b0,leaf_39};
// node 20: ADD
wire [1:0] n_0_20 = {1'b0,leaf_40} + {1'b0,leaf_41};
// node 21: ADD
wire [1:0] n_0_21 = {1'b0,leaf_42} + {1'b0,leaf_43};
// node 22: ADD
wire [1:0] n_0_22 = {1'b0,leaf_44} + {1'b0,leaf_45};
// node 23: ADD
wire [1:0] n_0_23 = {1'b0,leaf_46} + {1'b0,leaf_47};
// node 24: ADD
wire [1:0] n_0_24 = {1'b0,leaf_48} + {1'b0,leaf_49};
// node 25: ADD
wire [1:0] n_0_25 = {1'b0,leaf_50} + {1'b0,leaf_51};
// node 26: ADD
wire [1:0] n_0_26 = {1'b0,leaf_52} + {1'b0,leaf_53};
// node 27: ADD
wire [1:0] n_0_27 = {1'b0,leaf_54} + {1'b0,leaf_55};
// node 28: ADD
wire [1:0] n_0_28 = {1'b0,leaf_56} + {1'b0,leaf_57};
// node 29: ADD
wire [1:0] n_0_29 = {1'b0,leaf_58} + {1'b0,leaf_59};
// node 30: ADD
wire [1:0] n_0_30 = {1'b0,leaf_60} + {1'b0,leaf_61};
// node 31: ADD
wire [1:0] n_0_31 = {1'b0,leaf_62} + {1'b0,leaf_63};

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
// node 43: CLA
wire p_43_0 = n_0_22[0] ^ n_0_23[0];
wire g_43_0 = n_0_22[0] & n_0_23[0];
wire p_43_1 = n_0_22[1] ^ n_0_23[1];
wire g_43_1 = n_0_22[1] & n_0_23[1];
wire [2:0] n_1_11;
assign n_1_11[0] = p_43_0;
assign n_1_11[1] = p_43_1 ^ ((g_43_0));
assign n_1_11[2] = (g_43_1) | (g_43_0 & p_43_1);
// node 44: ADD
wire [2:0] n_1_12 = {1'b0,n_0_24} + {1'b0,n_0_25};
// node 45: ADD
wire [2:0] n_1_13 = {1'b0,n_0_26} + {1'b0,n_0_27};
// node 46: ADD
wire [2:0] n_1_14 = {1'b0,n_0_28} + {1'b0,n_0_29};
// node 47: CLA
wire p_47_0 = n_0_30[0] ^ n_0_31[0];
wire g_47_0 = n_0_30[0] & n_0_31[0];
wire p_47_1 = n_0_30[1] ^ n_0_31[1];
wire g_47_1 = n_0_30[1] & n_0_31[1];
wire [2:0] n_1_15;
assign n_1_15[0] = p_47_0;
assign n_1_15[1] = p_47_1 ^ ((g_47_0));
assign n_1_15[2] = (g_47_1) | (g_47_0 & p_47_1);

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

// node 56: ADD
wire [4:0] n_3_0 = {1'b0,n_2_0} + {1'b0,n_2_1};
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
// node 61: CLA
wire p_61_0 = n_3_2[0] ^ n_3_3[0];
wire g_61_0 = n_3_2[0] & n_3_3[0];
wire p_61_1 = n_3_2[1] ^ n_3_3[1];
wire g_61_1 = n_3_2[1] & n_3_3[1];
wire p_61_2 = n_3_2[2] ^ n_3_3[2];
wire g_61_2 = n_3_2[2] & n_3_3[2];
wire p_61_3 = n_3_2[3] ^ n_3_3[3];
wire g_61_3 = n_3_2[3] & n_3_3[3];
wire p_61_4 = n_3_2[4] ^ n_3_3[4];
wire g_61_4 = n_3_2[4] & n_3_3[4];
wire [5:0] n_4_1;
assign n_4_1[0] = p_61_0;
assign n_4_1[1] = p_61_1 ^ ((g_61_0));
assign n_4_1[2] = p_61_2 ^ ((g_61_1) | (g_61_0 & p_61_1));
assign n_4_1[3] = p_61_3 ^ ((g_61_2) | (g_61_1 & p_61_2) | (g_61_0 & p_61_1 & p_61_2));
assign n_4_1[4] = p_61_4 ^ ((g_61_3) | (g_61_2 & p_61_3) | (g_61_1 & p_61_2 & p_61_3) | (g_61_0 & p_61_1 & p_61_2 & p_61_3));
assign n_4_1[5] = (g_61_4) | (g_61_3 & p_61_4) | (g_61_2 & p_61_3 & p_61_4) | (g_61_1 & p_61_2 & p_61_3 & p_61_4) | (g_61_0 & p_61_1 & p_61_2 & p_61_3 & p_61_4);

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
