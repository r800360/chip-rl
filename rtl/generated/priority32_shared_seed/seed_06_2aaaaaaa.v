module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire hit_0 = |a_i[1:0];
wire [4:0] idx_0 = a_i[1] ? 5'd1 : a_i[0] ? 5'd0 : 5'd0;
wire hit_1 = |a_i[3:2];
wire [4:0] idx_1 = a_i[3] ? 5'd3 : a_i[2] ? 5'd2 : 5'd0;
wire hit_2 = |a_i[5:4];
wire [4:0] idx_2 = a_i[5] ? 5'd5 : a_i[4] ? 5'd4 : 5'd0;
wire hit_3 = |a_i[7:6];
wire [4:0] idx_3 = a_i[7] ? 5'd7 : a_i[6] ? 5'd6 : 5'd0;
wire hit_4 = |a_i[9:8];
wire [4:0] idx_4 = a_i[9] ? 5'd9 : a_i[8] ? 5'd8 : 5'd0;
wire hit_5 = |a_i[11:10];
wire [4:0] idx_5 = a_i[11] ? 5'd11 : a_i[10] ? 5'd10 : 5'd0;
wire hit_6 = |a_i[13:12];
wire [4:0] idx_6 = a_i[13] ? 5'd13 : a_i[12] ? 5'd12 : 5'd0;
wire hit_7 = |a_i[15:14];
wire [4:0] idx_7 = a_i[15] ? 5'd15 : a_i[14] ? 5'd14 : 5'd0;
wire hit_8 = |a_i[17:16];
wire [4:0] idx_8 = a_i[17] ? 5'd17 : a_i[16] ? 5'd16 : 5'd0;
wire hit_9 = |a_i[19:18];
wire [4:0] idx_9 = a_i[19] ? 5'd19 : a_i[18] ? 5'd18 : 5'd0;
wire hit_10 = |a_i[21:20];
wire [4:0] idx_10 = a_i[21] ? 5'd21 : a_i[20] ? 5'd20 : 5'd0;
wire hit_11 = |a_i[23:22];
wire [4:0] idx_11 = a_i[23] ? 5'd23 : a_i[22] ? 5'd22 : 5'd0;
wire hit_12 = |a_i[25:24];
wire [4:0] idx_12 = a_i[25] ? 5'd25 : a_i[24] ? 5'd24 : 5'd0;
wire hit_13 = |a_i[27:26];
wire [4:0] idx_13 = a_i[27] ? 5'd27 : a_i[26] ? 5'd26 : 5'd0;
wire hit_14 = |a_i[29:28];
wire [4:0] idx_14 = a_i[29] ? 5'd29 : a_i[28] ? 5'd28 : 5'd0;
wire hit_15 = |a_i[31:30];
wire [4:0] idx_15 = a_i[31] ? 5'd31 : a_i[30] ? 5'd30 : 5'd0;

wire [5:0] chosen_0 = hit_0 ? {1'b1, idx_0} : 6'd0;
wire [5:0] chosen_1 = hit_1 ? {1'b1, idx_1} : chosen_0;
wire [5:0] chosen_2 = hit_2 ? {1'b1, idx_2} : chosen_1;
wire [5:0] chosen_3 = hit_3 ? {1'b1, idx_3} : chosen_2;
wire [5:0] chosen_4 = hit_4 ? {1'b1, idx_4} : chosen_3;
wire [5:0] chosen_5 = hit_5 ? {1'b1, idx_5} : chosen_4;
wire [5:0] chosen_6 = hit_6 ? {1'b1, idx_6} : chosen_5;
wire [5:0] chosen_7 = hit_7 ? {1'b1, idx_7} : chosen_6;
wire [5:0] chosen_8 = hit_8 ? {1'b1, idx_8} : chosen_7;
wire [5:0] chosen_9 = hit_9 ? {1'b1, idx_9} : chosen_8;
wire [5:0] chosen_10 = hit_10 ? {1'b1, idx_10} : chosen_9;
wire [5:0] chosen_11 = hit_11 ? {1'b1, idx_11} : chosen_10;
wire [5:0] chosen_12 = hit_12 ? {1'b1, idx_12} : chosen_11;
wire [5:0] chosen_13 = hit_13 ? {1'b1, idx_13} : chosen_12;
wire [5:0] chosen_14 = hit_14 ? {1'b1, idx_14} : chosen_13;
wire [5:0] chosen_15 = hit_15 ? {1'b1, idx_15} : chosen_14;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen_15;
    end
end
endmodule
