module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Hierarchical priority encoder with reduced depth
wire hit_31_24, hit_23_16, hit_15_8, hit_7_0;
wire [4:0] idx_31_24, idx_23_16, idx_15_8, idx_7_0;

// Stage 1: Encode each 8-bit group in parallel
assign hit_31_24 = |a_i[31:24];
assign idx_31_24 = a_i[31] ? 5'd31 : a_i[30] ? 5'd30 : a_i[29] ? 5'd29 : a_i[28] ? 5'd28 : a_i[27] ? 5'd27 : a_i[26] ? 5'd26 : a_i[25] ? 5'd25 : 5'd24;

assign hit_23_16 = |a_i[23:16];
assign idx_23_16 = a_i[23] ? 5'd23 : a_i[22] ? 5'd22 : a_i[21] ? 5'd21 : a_i[20] ? 5'd20 : a_i[19] ? 5'd19 : a_i[18] ? 5'd18 : a_i[17] ? 5'd17 : 5'd16;

assign hit_15_8 = |a_i[15:8];
assign idx_15_8 = a_i[15] ? 5'd15 : a_i[14] ? 5'd14 : a_i[13] ? 5'd13 : a_i[12] ? 5'd12 : a_i[11] ? 5'd11 : a_i[10] ? 5'd10 : a_i[9] ? 5'd9 : 5'd8;

assign hit_7_0 = |a_i[7:0];
assign idx_7_0 = a_i[7] ? 5'd7 : a_i[6] ? 5'd6 : a_i[5] ? 5'd5 : a_i[4] ? 5'd4 : a_i[3] ? 5'd3 : a_i[2] ? 5'd2 : a_i[1] ? 5'd1 : 5'd0;

// Stage 2: Select from upper half vs lower half
wire hit_upper = hit_31_24 | hit_23_16;
wire hit_lower = hit_15_8 | hit_7_0;
wire [4:0] idx_upper = hit_31_24 ? idx_31_24 : idx_23_16;
wire [4:0] idx_lower = hit_15_8 ? idx_15_8 : idx_7_0;

// Stage 3: Final selection
wire hit_0 = hit_upper | hit_lower;
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