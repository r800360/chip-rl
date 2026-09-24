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
wire hit_2 = |a_i[7:4];
wire [4:0] idx_2 = a_i[7] ? 5'd7 : a_i[6] ? 5'd6 : a_i[5] ? 5'd5 : a_i[4] ? 5'd4 : 5'd0;
wire hit_3 = |a_i[8];
wire [4:0] idx_3 = a_i[8] ? 5'd8 : 5'd0;
wire hit_4 = |a_i[9];
wire [4:0] idx_4 = a_i[9] ? 5'd9 : 5'd0;
wire hit_5 = |a_i[10];
wire [4:0] idx_5 = a_i[10] ? 5'd10 : 5'd0;
wire hit_6 = |a_i[11];
wire [4:0] idx_6 = a_i[11] ? 5'd11 : 5'd0;
wire hit_7 = |a_i[12];
wire [4:0] idx_7 = a_i[12] ? 5'd12 : 5'd0;
wire hit_8 = |a_i[13];
wire [4:0] idx_8 = a_i[13] ? 5'd13 : 5'd0;
wire hit_9 = |a_i[14];
wire [4:0] idx_9 = a_i[14] ? 5'd14 : 5'd0;
wire hit_10 = |a_i[15];
wire [4:0] idx_10 = a_i[15] ? 5'd15 : 5'd0;
wire hit_11 = |a_i[16];
wire [4:0] idx_11 = a_i[16] ? 5'd16 : 5'd0;
wire hit_12 = |a_i[17];
wire [4:0] idx_12 = a_i[17] ? 5'd17 : 5'd0;
wire hit_13 = |a_i[18];
wire [4:0] idx_13 = a_i[18] ? 5'd18 : 5'd0;
wire hit_14 = |a_i[19];
wire [4:0] idx_14 = a_i[19] ? 5'd19 : 5'd0;
wire hit_15 = |a_i[20];
wire [4:0] idx_15 = a_i[20] ? 5'd20 : 5'd0;
wire hit_16 = |a_i[21];
wire [4:0] idx_16 = a_i[21] ? 5'd21 : 5'd0;
wire hit_17 = |a_i[22];
wire [4:0] idx_17 = a_i[22] ? 5'd22 : 5'd0;
wire hit_18 = |a_i[23];
wire [4:0] idx_18 = a_i[23] ? 5'd23 : 5'd0;
wire hit_19 = |a_i[24];
wire [4:0] idx_19 = a_i[24] ? 5'd24 : 5'd0;
wire hit_20 = |a_i[25];
wire [4:0] idx_20 = a_i[25] ? 5'd25 : 5'd0;
wire hit_21 = |a_i[26];
wire [4:0] idx_21 = a_i[26] ? 5'd26 : 5'd0;
wire hit_22 = |a_i[27];
wire [4:0] idx_22 = a_i[27] ? 5'd27 : 5'd0;
wire hit_23 = |a_i[28];
wire [4:0] idx_23 = a_i[28] ? 5'd28 : 5'd0;
wire hit_24 = |a_i[29];
wire [4:0] idx_24 = a_i[29] ? 5'd29 : 5'd0;
wire hit_25 = |a_i[30];
wire [4:0] idx_25 = a_i[30] ? 5'd30 : 5'd0;
wire hit_26 = |a_i[31];
wire [4:0] idx_26 = a_i[31] ? 5'd31 : 5'd0;

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
wire [5:0] chosen_16 = hit_16 ? {1'b1, idx_16} : chosen_15;
wire [5:0] chosen_17 = hit_17 ? {1'b1, idx_17} : chosen_16;
wire [5:0] chosen_18 = hit_18 ? {1'b1, idx_18} : chosen_17;
wire [5:0] chosen_19 = hit_19 ? {1'b1, idx_19} : chosen_18;
wire [5:0] chosen_20 = hit_20 ? {1'b1, idx_20} : chosen_19;
wire [5:0] chosen_21 = hit_21 ? {1'b1, idx_21} : chosen_20;
wire [5:0] chosen_22 = hit_22 ? {1'b1, idx_22} : chosen_21;
wire [5:0] chosen_23 = hit_23 ? {1'b1, idx_23} : chosen_22;
wire [5:0] chosen_24 = hit_24 ? {1'b1, idx_24} : chosen_23;
wire [5:0] chosen_25 = hit_25 ? {1'b1, idx_25} : chosen_24;
wire [5:0] chosen_26 = hit_26 ? {1'b1, idx_26} : chosen_25;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen_26;
    end
end
endmodule
