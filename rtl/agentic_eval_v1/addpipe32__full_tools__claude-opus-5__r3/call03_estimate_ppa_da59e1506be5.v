module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

wire [8:0]  s0 = {1'b0, a_i[7:0]}   + {1'b0, b_i[7:0]};
wire [8:0]  s1_0 = {1'b0, a_i[15:8]}  + {1'b0, b_i[15:8]};
wire [8:0]  s1_1 = {1'b0, a_i[15:8]}  + {1'b0, b_i[15:8]} + 9'd1;
wire [8:0]  s2_0 = {1'b0, a_i[23:16]} + {1'b0, b_i[23:16]};
wire [8:0]  s2_1 = {1'b0, a_i[23:16]} + {1'b0, b_i[23:16]} + 9'd1;
wire [7:0]  s3_0 = a_i[31:24] + b_i[31:24];
wire [7:0]  s3_1 = a_i[31:24] + b_i[31:24] + 8'd1;

wire c1 = s0[8];
wire [8:0] r1 = c1 ? s1_1 : s1_0;
wire c2 = r1[8];
wire [8:0] r2 = c2 ? s2_1 : s2_0;
wire c3 = r2[8];
wire [7:0] r3 = c3 ? s3_1 : s3_0;

wire [31:0] sum = {r3, r2[7:0], r1[7:0], s0[7:0]};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= sum;
    end
end

endmodule
