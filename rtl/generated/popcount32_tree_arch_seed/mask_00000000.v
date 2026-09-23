// Independent experimental benchmark; 31-node balanced popcount tree.
// architecture_mask = 0x00000000
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
wire [2:0] n_1_0 = {1'b0,n_0_0} + {1'b0,n_0_1};
// node 17: ADD
wire [2:0] n_1_1 = {1'b0,n_0_2} + {1'b0,n_0_3};
// node 18: ADD
wire [2:0] n_1_2 = {1'b0,n_0_4} + {1'b0,n_0_5};
// node 19: ADD
wire [2:0] n_1_3 = {1'b0,n_0_6} + {1'b0,n_0_7};
// node 20: ADD
wire [2:0] n_1_4 = {1'b0,n_0_8} + {1'b0,n_0_9};
// node 21: ADD
wire [2:0] n_1_5 = {1'b0,n_0_10} + {1'b0,n_0_11};
// node 22: ADD
wire [2:0] n_1_6 = {1'b0,n_0_12} + {1'b0,n_0_13};
// node 23: ADD
wire [2:0] n_1_7 = {1'b0,n_0_14} + {1'b0,n_0_15};

// node 24: ADD
wire [3:0] n_2_0 = {1'b0,n_1_0} + {1'b0,n_1_1};
// node 25: ADD
wire [3:0] n_2_1 = {1'b0,n_1_2} + {1'b0,n_1_3};
// node 26: ADD
wire [3:0] n_2_2 = {1'b0,n_1_4} + {1'b0,n_1_5};
// node 27: ADD
wire [3:0] n_2_3 = {1'b0,n_1_6} + {1'b0,n_1_7};

// node 28: ADD
wire [4:0] n_3_0 = {1'b0,n_2_0} + {1'b0,n_2_1};
// node 29: ADD
wire [4:0] n_3_1 = {1'b0,n_2_2} + {1'b0,n_2_3};

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
