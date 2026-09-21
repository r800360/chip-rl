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

wire [5:0] blk_0;
assign blk_0 = {1'b0, a_i[4:0]} + {1'b0, b_i[4:0]};
assign sum[4:0] = blk_0[4:0];
wire carry_0;
assign carry_0 = blk_0[5];

wire [11:0] blk_1_0;
wire [11:0] blk_1_1;
wire [11:0] blk_1;
assign blk_1_0 = {1'b0, a_i[15:5]} + {1'b0, b_i[15:5]};
assign blk_1_1 = {1'b0, a_i[15:5]} + {1'b0, b_i[15:5]} + {{11{1'b0}}, 1'b1};
assign blk_1 = carry_0 ? blk_1_1 : blk_1_0;
assign sum[15:5] = blk_1[10:0];
wire carry_1;
assign carry_1 = blk_1[11];

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
