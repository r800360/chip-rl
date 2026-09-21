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

wire [3:0] blk_0;
assign blk_0 = {1'b0, a_i[2:0]} + {1'b0, b_i[2:0]};
assign sum[2:0] = blk_0[2:0];
wire carry_0;
assign carry_0 = blk_0[3];

wire [5:0] blk_1_0;
wire [5:0] blk_1_1;
wire [5:0] blk_1;
assign blk_1_0 = {1'b0, a_i[7:3]} + {1'b0, b_i[7:3]};
assign blk_1_1 = {1'b0, a_i[7:3]} + {1'b0, b_i[7:3]} + {{5{1'b0}}, 1'b1};
assign blk_1 = carry_0 ? blk_1_1 : blk_1_0;
assign sum[7:3] = blk_1[4:0];
wire carry_1;
assign carry_1 = blk_1[5];

wire [2:0] blk_2_0;
wire [2:0] blk_2_1;
wire [2:0] blk_2;
assign blk_2_0 = {1'b0, a_i[9:8]} + {1'b0, b_i[9:8]};
assign blk_2_1 = {1'b0, a_i[9:8]} + {1'b0, b_i[9:8]} + {{2{1'b0}}, 1'b1};
assign blk_2 = carry_1 ? blk_2_1 : blk_2_0;
assign sum[9:8] = blk_2[1:0];
wire carry_2;
assign carry_2 = blk_2[2];

wire [6:0] blk_3_0;
wire [6:0] blk_3_1;
wire [6:0] blk_3;
assign blk_3_0 = {1'b0, a_i[15:10]} + {1'b0, b_i[15:10]};
assign blk_3_1 = {1'b0, a_i[15:10]} + {1'b0, b_i[15:10]} + {{6{1'b0}}, 1'b1};
assign blk_3 = carry_2 ? blk_3_1 : blk_3_0;
assign sum[15:10] = blk_3[5:0];
wire carry_3;
assign carry_3 = blk_3[6];

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
