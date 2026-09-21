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

wire [4:0] blk_1_0;
wire [4:0] blk_1_1;
wire [4:0] blk_1;
assign blk_1_0 = {1'b0, a_i[4:1]} + {1'b0, b_i[4:1]};
assign blk_1_1 = {1'b0, a_i[4:1]} + {1'b0, b_i[4:1]} + {{4{1'b0}}, 1'b1};
assign blk_1 = carry_0 ? blk_1_1 : blk_1_0;
assign sum[4:1] = blk_1[3:0];
wire carry_1;
assign carry_1 = blk_1[4];

wire [1:0] blk_2_0;
wire [1:0] blk_2_1;
wire [1:0] blk_2;
assign blk_2_0 = {1'b0, a_i[5:5]} + {1'b0, b_i[5:5]};
assign blk_2_1 = {1'b0, a_i[5:5]} + {1'b0, b_i[5:5]} + {{1{1'b0}}, 1'b1};
assign blk_2 = carry_1 ? blk_2_1 : blk_2_0;
assign sum[5:5] = blk_2[0:0];
wire carry_2;
assign carry_2 = blk_2[1];

wire [4:0] blk_3_0;
wire [4:0] blk_3_1;
wire [4:0] blk_3;
assign blk_3_0 = {1'b0, a_i[9:6]} + {1'b0, b_i[9:6]};
assign blk_3_1 = {1'b0, a_i[9:6]} + {1'b0, b_i[9:6]} + {{4{1'b0}}, 1'b1};
assign blk_3 = carry_2 ? blk_3_1 : blk_3_0;
assign sum[9:6] = blk_3[3:0];
wire carry_3;
assign carry_3 = blk_3[4];

wire [2:0] blk_4_0;
wire [2:0] blk_4_1;
wire [2:0] blk_4;
assign blk_4_0 = {1'b0, a_i[11:10]} + {1'b0, b_i[11:10]};
assign blk_4_1 = {1'b0, a_i[11:10]} + {1'b0, b_i[11:10]} + {{2{1'b0}}, 1'b1};
assign blk_4 = carry_3 ? blk_4_1 : blk_4_0;
assign sum[11:10] = blk_4[1:0];
wire carry_4;
assign carry_4 = blk_4[2];

wire [1:0] blk_5_0;
wire [1:0] blk_5_1;
wire [1:0] blk_5;
assign blk_5_0 = {1'b0, a_i[12:12]} + {1'b0, b_i[12:12]};
assign blk_5_1 = {1'b0, a_i[12:12]} + {1'b0, b_i[12:12]} + {{1{1'b0}}, 1'b1};
assign blk_5 = carry_4 ? blk_5_1 : blk_5_0;
assign sum[12:12] = blk_5[0:0];
wire carry_5;
assign carry_5 = blk_5[1];

wire [3:0] blk_6_0;
wire [3:0] blk_6_1;
wire [3:0] blk_6;
assign blk_6_0 = {1'b0, a_i[15:13]} + {1'b0, b_i[15:13]};
assign blk_6_1 = {1'b0, a_i[15:13]} + {1'b0, b_i[15:13]} + {{3{1'b0}}, 1'b1};
assign blk_6 = carry_5 ? blk_6_1 : blk_6_0;
assign sum[15:13] = blk_6[2:0];
wire carry_6;
assign carry_6 = blk_6[3];

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
