module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg         valid_o,
    output reg  [15:0] y_o
);

wire [15:0] sum;

wire [1:0] blk_0;
assign blk_0 = {1'b0, a_i[0:0]} + {1'b0, b_i[0:0]};
assign sum[0:0] = blk_0[0:0];
wire carry_0;
assign carry_0 = blk_0[1];

wire [1:0] blk_1_0;
wire [1:0] blk_1_1;
wire [1:0] blk_1;
assign blk_1_0 = {1'b0, a_i[1:1]} + {1'b0, b_i[1:1]};
assign blk_1_1 = {1'b0, a_i[1:1]} + {1'b0, b_i[1:1]} + {{1{1'b0}}, 1'b1};
assign blk_1 = carry_0 ? blk_1_1 : blk_1_0;
assign sum[1:1] = blk_1[0:0];
wire carry_1;
assign carry_1 = blk_1[1];

wire [1:0] blk_2_0;
wire [1:0] blk_2_1;
wire [1:0] blk_2;
assign blk_2_0 = {1'b0, a_i[2:2]} + {1'b0, b_i[2:2]};
assign blk_2_1 = {1'b0, a_i[2:2]} + {1'b0, b_i[2:2]} + {{1{1'b0}}, 1'b1};
assign blk_2 = carry_1 ? blk_2_1 : blk_2_0;
assign sum[2:2] = blk_2[0:0];
wire carry_2;
assign carry_2 = blk_2[1];

wire [1:0] blk_3_0;
wire [1:0] blk_3_1;
wire [1:0] blk_3;
assign blk_3_0 = {1'b0, a_i[3:3]} + {1'b0, b_i[3:3]};
assign blk_3_1 = {1'b0, a_i[3:3]} + {1'b0, b_i[3:3]} + {{1{1'b0}}, 1'b1};
assign blk_3 = carry_2 ? blk_3_1 : blk_3_0;
assign sum[3:3] = blk_3[0:0];
wire carry_3;
assign carry_3 = blk_3[1];

wire [1:0] blk_4_0;
wire [1:0] blk_4_1;
wire [1:0] blk_4;
assign blk_4_0 = {1'b0, a_i[4:4]} + {1'b0, b_i[4:4]};
assign blk_4_1 = {1'b0, a_i[4:4]} + {1'b0, b_i[4:4]} + {{1{1'b0}}, 1'b1};
assign blk_4 = carry_3 ? blk_4_1 : blk_4_0;
assign sum[4:4] = blk_4[0:0];
wire carry_4;
assign carry_4 = blk_4[1];

wire [1:0] blk_5_0;
wire [1:0] blk_5_1;
wire [1:0] blk_5;
assign blk_5_0 = {1'b0, a_i[5:5]} + {1'b0, b_i[5:5]};
assign blk_5_1 = {1'b0, a_i[5:5]} + {1'b0, b_i[5:5]} + {{1{1'b0}}, 1'b1};
assign blk_5 = carry_4 ? blk_5_1 : blk_5_0;
assign sum[5:5] = blk_5[0:0];
wire carry_5;
assign carry_5 = blk_5[1];

wire [1:0] blk_6_0;
wire [1:0] blk_6_1;
wire [1:0] blk_6;
assign blk_6_0 = {1'b0, a_i[6:6]} + {1'b0, b_i[6:6]};
assign blk_6_1 = {1'b0, a_i[6:6]} + {1'b0, b_i[6:6]} + {{1{1'b0}}, 1'b1};
assign blk_6 = carry_5 ? blk_6_1 : blk_6_0;
assign sum[6:6] = blk_6[0:0];
wire carry_6;
assign carry_6 = blk_6[1];

wire [1:0] blk_7_0;
wire [1:0] blk_7_1;
wire [1:0] blk_7;
assign blk_7_0 = {1'b0, a_i[7:7]} + {1'b0, b_i[7:7]};
assign blk_7_1 = {1'b0, a_i[7:7]} + {1'b0, b_i[7:7]} + {{1{1'b0}}, 1'b1};
assign blk_7 = carry_6 ? blk_7_1 : blk_7_0;
assign sum[7:7] = blk_7[0:0];
wire carry_7;
assign carry_7 = blk_7[1];

wire [1:0] blk_8_0;
wire [1:0] blk_8_1;
wire [1:0] blk_8;
assign blk_8_0 = {1'b0, a_i[8:8]} + {1'b0, b_i[8:8]};
assign blk_8_1 = {1'b0, a_i[8:8]} + {1'b0, b_i[8:8]} + {{1{1'b0}}, 1'b1};
assign blk_8 = carry_7 ? blk_8_1 : blk_8_0;
assign sum[8:8] = blk_8[0:0];
wire carry_8;
assign carry_8 = blk_8[1];

wire [1:0] blk_9_0;
wire [1:0] blk_9_1;
wire [1:0] blk_9;
assign blk_9_0 = {1'b0, a_i[9:9]} + {1'b0, b_i[9:9]};
assign blk_9_1 = {1'b0, a_i[9:9]} + {1'b0, b_i[9:9]} + {{1{1'b0}}, 1'b1};
assign blk_9 = carry_8 ? blk_9_1 : blk_9_0;
assign sum[9:9] = blk_9[0:0];
wire carry_9;
assign carry_9 = blk_9[1];

wire [1:0] blk_10_0;
wire [1:0] blk_10_1;
wire [1:0] blk_10;
assign blk_10_0 = {1'b0, a_i[10:10]} + {1'b0, b_i[10:10]};
assign blk_10_1 = {1'b0, a_i[10:10]} + {1'b0, b_i[10:10]} + {{1{1'b0}}, 1'b1};
assign blk_10 = carry_9 ? blk_10_1 : blk_10_0;
assign sum[10:10] = blk_10[0:0];
wire carry_10;
assign carry_10 = blk_10[1];

wire [1:0] blk_11_0;
wire [1:0] blk_11_1;
wire [1:0] blk_11;
assign blk_11_0 = {1'b0, a_i[11:11]} + {1'b0, b_i[11:11]};
assign blk_11_1 = {1'b0, a_i[11:11]} + {1'b0, b_i[11:11]} + {{1{1'b0}}, 1'b1};
assign blk_11 = carry_10 ? blk_11_1 : blk_11_0;
assign sum[11:11] = blk_11[0:0];
wire carry_11;
assign carry_11 = blk_11[1];

wire [1:0] blk_12_0;
wire [1:0] blk_12_1;
wire [1:0] blk_12;
assign blk_12_0 = {1'b0, a_i[12:12]} + {1'b0, b_i[12:12]};
assign blk_12_1 = {1'b0, a_i[12:12]} + {1'b0, b_i[12:12]} + {{1{1'b0}}, 1'b1};
assign blk_12 = carry_11 ? blk_12_1 : blk_12_0;
assign sum[12:12] = blk_12[0:0];
wire carry_12;
assign carry_12 = blk_12[1];

wire [1:0] blk_13_0;
wire [1:0] blk_13_1;
wire [1:0] blk_13;
assign blk_13_0 = {1'b0, a_i[13:13]} + {1'b0, b_i[13:13]};
assign blk_13_1 = {1'b0, a_i[13:13]} + {1'b0, b_i[13:13]} + {{1{1'b0}}, 1'b1};
assign blk_13 = carry_12 ? blk_13_1 : blk_13_0;
assign sum[13:13] = blk_13[0:0];
wire carry_13;
assign carry_13 = blk_13[1];

wire [1:0] blk_14_0;
wire [1:0] blk_14_1;
wire [1:0] blk_14;
assign blk_14_0 = {1'b0, a_i[14:14]} + {1'b0, b_i[14:14]};
assign blk_14_1 = {1'b0, a_i[14:14]} + {1'b0, b_i[14:14]} + {{1{1'b0}}, 1'b1};
assign blk_14 = carry_13 ? blk_14_1 : blk_14_0;
assign sum[14:14] = blk_14[0:0];
wire carry_14;
assign carry_14 = blk_14[1];

wire [1:0] blk_15_0;
wire [1:0] blk_15_1;
wire [1:0] blk_15;
assign blk_15_0 = {1'b0, a_i[15:15]} + {1'b0, b_i[15:15]};
assign blk_15_1 = {1'b0, a_i[15:15]} + {1'b0, b_i[15:15]} + {{1{1'b0}}, 1'b1};
assign blk_15 = carry_14 ? blk_15_1 : blk_15_0;
assign sum[15:15] = blk_15[0:0];
wire carry_15;
assign carry_15 = blk_15[1];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 16'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule
