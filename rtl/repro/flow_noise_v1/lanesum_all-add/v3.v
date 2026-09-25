// Independent experimental circuit: 16 unsigned 8-bit lane sum.
// architecture_mask = 0x0000
module lanesum16x8_tree (
  input wire clk, rst_n, valid_i,
  input wire [63:0] a_i, b_i,
  output reg valid_o,
  output reg [11:0] y_o
);

wire [7:0] leaf_0 = a_i[7:0];
wire [7:0] leaf_1 = a_i[15:8];
wire [7:0] leaf_2 = a_i[23:16];
wire [7:0] leaf_3 = a_i[31:24];
wire [7:0] leaf_4 = a_i[39:32];
wire [7:0] leaf_5 = a_i[47:40];
wire [7:0] leaf_6 = a_i[55:48];
wire [7:0] leaf_7 = a_i[63:56];
wire [7:0] leaf_8 = b_i[7:0];
wire [7:0] leaf_9 = b_i[15:8];
wire [7:0] leaf_10 = b_i[23:16];
wire [7:0] leaf_11 = b_i[31:24];
wire [7:0] leaf_12 = b_i[39:32];
wire [7:0] leaf_13 = b_i[47:40];
wire [7:0] leaf_14 = b_i[55:48];
wire [7:0] leaf_15 = b_i[63:56];

// node 0: ADD
wire [8:0] n_0_0 = {1'b0,leaf_0} + {1'b0,leaf_1};
// node 1: ADD
wire [8:0] n_0_1 = {1'b0,leaf_2} + {1'b0,leaf_3};
// node 2: ADD
wire [8:0] n_0_2 = {1'b0,leaf_4} + {1'b0,leaf_5};
// node 3: ADD
wire [8:0] n_0_3 = {1'b0,leaf_6} + {1'b0,leaf_7};
// node 4: ADD
wire [8:0] n_0_4 = {1'b0,leaf_8} + {1'b0,leaf_9};
// node 5: ADD
wire [8:0] n_0_5 = {1'b0,leaf_10} + {1'b0,leaf_11};
// node 6: ADD
wire [8:0] n_0_6 = {1'b0,leaf_12} + {1'b0,leaf_13};
// node 7: ADD
wire [8:0] n_0_7 = {1'b0,leaf_14} + {1'b0,leaf_15};

// node 8: ADD
wire [9:0] n_1_0 = {1'b0,n_0_0} + {1'b0,n_0_1};
// node 9: ADD
wire [9:0] n_1_1 = {1'b0,n_0_2} + {1'b0,n_0_3};
// node 10: ADD
wire [9:0] n_1_2 = {1'b0,n_0_4} + {1'b0,n_0_5};
// node 11: ADD
wire [9:0] n_1_3 = {1'b0,n_0_6} + {1'b0,n_0_7};

// node 12: ADD
wire [10:0] n_2_0 = {1'b0,n_1_0} + {1'b0,n_1_1};
// node 13: ADD
wire [10:0] n_2_1 = {1'b0,n_1_2} + {1'b0,n_1_3};

// node 14: ADD
wire [11:0] n_3_0 = {1'b0,n_2_0} + {1'b0,n_2_1};

always @(posedge clk) begin
  if (!rst_n) begin
    valid_o <= 1'b0;
    y_o <= 12'd0;
  end else begin
    valid_o <= valid_i;
    if (valid_i)
      y_o <= n_3_0;
  end
end
endmodule
// trailing comment
