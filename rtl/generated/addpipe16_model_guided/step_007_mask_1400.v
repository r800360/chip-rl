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

wire [11:0] blk_0;
assign blk_0 = {1'b0, a_i[10:0]} + {1'b0, b_i[10:0]};
assign sum[10:0] = blk_0[10:0];
wire carry_0;
assign carry_0 = blk_0[11];

wire [2:0] blk_1_0;
wire [2:0] blk_1_1;
wire [2:0] blk_1;
assign blk_1_0 = {1'b0, a_i[12:11]} + {1'b0, b_i[12:11]};
assign blk_1_1 = {1'b0, a_i[12:11]} + {1'b0, b_i[12:11]} + {{2{1'b0}}, 1'b1};
assign blk_1 = carry_0 ? blk_1_1 : blk_1_0;
assign sum[12:11] = blk_1[1:0];
wire carry_1;
assign carry_1 = blk_1[2];

wire [3:0] blk_2_0;
wire [3:0] blk_2_1;
wire [3:0] blk_2;
assign blk_2_0 = {1'b0, a_i[15:13]} + {1'b0, b_i[15:13]};
assign blk_2_1 = {1'b0, a_i[15:13]} + {1'b0, b_i[15:13]} + {{3{1'b0}}, 1'b1};
assign blk_2 = carry_1 ? blk_2_1 : blk_2_0;
assign sum[15:13] = blk_2[2:0];
wire carry_2;
assign carry_2 = blk_2[3];

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
