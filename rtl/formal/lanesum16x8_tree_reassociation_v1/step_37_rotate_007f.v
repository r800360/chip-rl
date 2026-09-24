// step 37: rotate_007f
module lanesum16x8_tree (
  input wire clk, rst_n, valid_i,
  input wire [63:0] a_i, b_i,
  output reg valid_o,
  output reg [11:0] y_o
);
wire [7:0] lane_0 = a_i[7:0];
wire [7:0] lane_1 = a_i[15:8];
wire [7:0] lane_2 = a_i[23:16];
wire [7:0] lane_3 = a_i[31:24];
wire [7:0] lane_4 = a_i[39:32];
wire [7:0] lane_5 = a_i[47:40];
wire [7:0] lane_6 = a_i[55:48];
wire [7:0] lane_7 = a_i[63:56];
wire [7:0] lane_8 = b_i[7:0];
wire [7:0] lane_9 = b_i[15:8];
wire [7:0] lane_10 = b_i[23:16];
wire [7:0] lane_11 = b_i[31:24];
wire [7:0] lane_12 = b_i[39:32];
wire [7:0] lane_13 = b_i[47:40];
wire [7:0] lane_14 = b_i[55:48];
wire [7:0] lane_15 = b_i[63:56];
wire [8:0] s_0003 = {1'd0,lane_0} + {1'd0,lane_1};
wire [9:0] s_0007 = {1'd0,s_0003} + {2'd0,lane_2};
wire [9:0] s_000f = s_0007 + {2'd0,lane_3};
wire [8:0] s_0030 = {1'd0,lane_4} + {1'd0,lane_5};
wire [9:0] s_0070 = {1'd0,s_0030} + {2'd0,lane_6};
wire [10:0] s_007f = {1'd0,s_000f} + {1'd0,s_0070};
wire [10:0] s_00ff = s_007f + {3'd0,lane_7};
wire [8:0] s_0300 = {1'd0,lane_8} + {1'd0,lane_9};
wire [9:0] s_0700 = {1'd0,s_0300} + {2'd0,lane_10};
wire [9:0] s_0f00 = s_0700 + {2'd0,lane_11};
wire [10:0] s_1f00 = {1'd0,s_0f00} + {3'd0,lane_12};
wire [10:0] s_3f00 = s_1f00 + {3'd0,lane_13};
wire [10:0] s_7f00 = s_3f00 + {3'd0,lane_14};
wire [10:0] s_ff00 = s_7f00 + {3'd0,lane_15};
wire [11:0] s_ffff = {1'd0,s_00ff} + {1'd0,s_ff00};
always @(posedge clk) begin
  if (!rst_n) begin
    valid_o <= 1'b0;
    y_o <= 12'd0;
  end else begin
    valid_o <= valid_i;
    if (valid_i) y_o <= s_ffff;
  end
end
endmodule
