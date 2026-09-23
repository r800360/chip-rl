// Independent experimental benchmark; 15-node balanced popcount tree.
// architecture_mask = 0x00ff
module popcount16_tree (
  input wire clk, rst_n, valid_i,
  input wire [15:0] a_i, b_i,
  output reg valid_o,
  output reg [4:0] y_o
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

// node 8: ADD
wire [2:0] n_1_0 = {1'b0,n_0_0} + {1'b0,n_0_1};
// node 9: ADD
wire [2:0] n_1_1 = {1'b0,n_0_2} + {1'b0,n_0_3};
// node 10: ADD
wire [2:0] n_1_2 = {1'b0,n_0_4} + {1'b0,n_0_5};
// node 11: ADD
wire [2:0] n_1_3 = {1'b0,n_0_6} + {1'b0,n_0_7};

// node 12: ADD
wire [3:0] n_2_0 = {1'b0,n_1_0} + {1'b0,n_1_1};
// node 13: ADD
wire [3:0] n_2_1 = {1'b0,n_1_2} + {1'b0,n_1_3};

// node 14: ADD
wire [4:0] n_3_0 = {1'b0,n_2_0} + {1'b0,n_2_1};

always @(posedge clk) begin
  if (!rst_n) begin
    valid_o <= 1'b0;
    y_o <= 5'd0;
  end else begin
    valid_o <= valid_i;
    if (valid_i)
      y_o <= n_3_0;
  end
end
endmodule
