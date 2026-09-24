// Independent experimental benchmark; 15-node balanced popcount tree.
// architecture_mask = 0x3404
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

// node 0: ADD
wire [1:0] n_0_0 = {1'b0,leaf_0} + {1'b0,leaf_1};
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
// node 4: ADD
wire [1:0] n_0_4 = {1'b0,leaf_8} + {1'b0,leaf_9};
// node 5: ADD
wire [1:0] n_0_5 = {1'b0,leaf_10} + {1'b0,leaf_11};
// node 6: ADD
wire [1:0] n_0_6 = {1'b0,leaf_12} + {1'b0,leaf_13};
// node 7: ADD
wire [1:0] n_0_7 = {1'b0,leaf_14} + {1'b0,leaf_15};

// node 8: ADD
wire [2:0] n_1_0 = {1'b0,n_0_0} + {1'b0,n_0_1};
// node 9: ADD
wire [2:0] n_1_1 = {1'b0,n_0_2} + {1'b0,n_0_3};
// node 10: CLA
wire p_10_0 = n_0_4[0] ^ n_0_5[0];
wire g_10_0 = n_0_4[0] & n_0_5[0];
wire p_10_1 = n_0_4[1] ^ n_0_5[1];
wire g_10_1 = n_0_4[1] & n_0_5[1];
wire [2:0] n_1_2;
assign n_1_2[0] = p_10_0;
assign n_1_2[1] = p_10_1 ^ ((g_10_0));
assign n_1_2[2] = (g_10_1) | (g_10_0 & p_10_1);
// node 11: ADD
wire [2:0] n_1_3 = {1'b0,n_0_6} + {1'b0,n_0_7};

// node 12: CLA
wire p_12_0 = n_1_0[0] ^ n_1_1[0];
wire g_12_0 = n_1_0[0] & n_1_1[0];
wire p_12_1 = n_1_0[1] ^ n_1_1[1];
wire g_12_1 = n_1_0[1] & n_1_1[1];
wire p_12_2 = n_1_0[2] ^ n_1_1[2];
wire g_12_2 = n_1_0[2] & n_1_1[2];
wire [3:0] n_2_0;
assign n_2_0[0] = p_12_0;
assign n_2_0[1] = p_12_1 ^ ((g_12_0));
assign n_2_0[2] = p_12_2 ^ ((g_12_1) | (g_12_0 & p_12_1));
assign n_2_0[3] = (g_12_2) | (g_12_1 & p_12_2) | (g_12_0 & p_12_1 & p_12_2);
// node 13: CLA
wire p_13_0 = n_1_2[0] ^ n_1_3[0];
wire g_13_0 = n_1_2[0] & n_1_3[0];
wire p_13_1 = n_1_2[1] ^ n_1_3[1];
wire g_13_1 = n_1_2[1] & n_1_3[1];
wire p_13_2 = n_1_2[2] ^ n_1_3[2];
wire g_13_2 = n_1_2[2] & n_1_3[2];
wire [3:0] n_2_1;
assign n_2_1[0] = p_13_0;
assign n_2_1[1] = p_13_1 ^ ((g_13_0));
assign n_2_1[2] = p_13_2 ^ ((g_13_1) | (g_13_0 & p_13_1));
assign n_2_1[3] = (g_13_2) | (g_13_1 & p_13_2) | (g_13_0 & p_13_1 & p_13_2);

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
