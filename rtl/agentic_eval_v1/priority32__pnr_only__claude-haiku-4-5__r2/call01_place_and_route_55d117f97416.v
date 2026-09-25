module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// 4-way hierarchical split
wire hit_31_24 = |a_i[31:24];
wire hit_23_16 = |a_i[23:16];
wire hit_15_8 = |a_i[15:8];
wire hit_7_0 = |a_i[7:0];

wire hit_upper = hit_31_24 | hit_23_16;
wire hit_lower = hit_15_8 | hit_7_0;
wire hit_0 = hit_upper | hit_lower;

// Each 8-bit segment
wire [3:0] idx_31_24 = a_i[31] ? 4'd7 : a_i[30] ? 4'd6 : a_i[29] ? 4'd5 : a_i[28] ? 4'd4 :
                       a_i[27] ? 4'd3 : a_i[26] ? 4'd2 : a_i[25] ? 4'd1 : a_i[24] ? 4'd0 : 4'd0;

wire [3:0] idx_23_16 = a_i[23] ? 4'd7 : a_i[22] ? 4'd6 : a_i[21] ? 4'd5 : a_i[20] ? 4'd4 :
                       a_i[19] ? 4'd3 : a_i[18] ? 4'd2 : a_i[17] ? 4'd1 : a_i[16] ? 4'd0 : 4'd0;

wire [3:0] idx_15_8 = a_i[15] ? 4'd7 : a_i[14] ? 4'd6 : a_i[13] ? 4'd5 : a_i[12] ? 4'd4 :
                      a_i[11] ? 4'd3 : a_i[10] ? 4'd2 : a_i[9] ? 4'd1 : a_i[8] ? 4'd0 : 4'd0;

wire [3:0] idx_7_0 = a_i[7] ? 4'd7 : a_i[6] ? 4'd6 : a_i[5] ? 4'd5 : a_i[4] ? 4'd4 :
                     a_i[3] ? 4'd3 : a_i[2] ? 4'd2 : a_i[1] ? 4'd1 : a_i[0] ? 4'd0 : 4'd0;

// Combine segments
wire [4:0] idx_upper = hit_31_24 ? {1'b1, idx_31_24} : {1'b0, idx_23_16};
wire [4:0] idx_lower = hit_15_8 ? {1'b1, idx_15_8} : {1'b0, idx_7_0};

wire [4:0] idx_0 = hit_upper ? idx_upper : idx_lower;

wire [5:0] chosen_0 = hit_0 ? {1'b1, idx_0} : 6'd0;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen_0;
    end
end
endmodule