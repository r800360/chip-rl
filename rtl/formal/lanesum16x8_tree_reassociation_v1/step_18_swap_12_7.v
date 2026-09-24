// step 18: swap_12_7
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
wire [10:0] s_010f = {1'd0,s_000f} + {3'd0,lane_8};
wire [10:0] s_011f = s_010f + {3'd0,lane_4};
wire [10:0] s_031f = s_011f + {3'd0,lane_9};
wire [10:0] s_033f = s_031f + {3'd0,lane_5};
wire [11:0] s_073f = {1'd0,s_033f} + {4'd0,lane_10};
wire [11:0] s_077f = s_073f + {4'd0,lane_6};
wire [11:0] s_0f7f = s_077f + {4'd0,lane_11};
wire [11:0] s_0fff = s_0f7f + {4'd0,lane_7};
wire [11:0] s_1fff = s_0fff + {4'd0,lane_12};
wire [11:0] s_3fff = s_1fff + {4'd0,lane_13};
wire [11:0] s_7fff = s_3fff + {4'd0,lane_14};
wire [11:0] s_ffff = s_7fff + {4'd0,lane_15};
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
