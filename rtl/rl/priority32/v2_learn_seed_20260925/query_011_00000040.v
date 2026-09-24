module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire hit_0 = |a_i[6:0];
wire [4:0] idx_0 = a_i[6] ? 5'd6 : a_i[5] ? 5'd5 : a_i[4] ? 5'd4 : a_i[3] ? 5'd3 : a_i[2] ? 5'd2 : a_i[1] ? 5'd1 : a_i[0] ? 5'd0 : 5'd0;
wire hit_1 = |a_i[31:7];
wire [4:0] idx_1 = a_i[31] ? 5'd31 : a_i[30] ? 5'd30 : a_i[29] ? 5'd29 : a_i[28] ? 5'd28 : a_i[27] ? 5'd27 : a_i[26] ? 5'd26 : a_i[25] ? 5'd25 : a_i[24] ? 5'd24 : a_i[23] ? 5'd23 : a_i[22] ? 5'd22 : a_i[21] ? 5'd21 : a_i[20] ? 5'd20 : a_i[19] ? 5'd19 : a_i[18] ? 5'd18 : a_i[17] ? 5'd17 : a_i[16] ? 5'd16 : a_i[15] ? 5'd15 : a_i[14] ? 5'd14 : a_i[13] ? 5'd13 : a_i[12] ? 5'd12 : a_i[11] ? 5'd11 : a_i[10] ? 5'd10 : a_i[9] ? 5'd9 : a_i[8] ? 5'd8 : a_i[7] ? 5'd7 : 5'd0;

wire [5:0] chosen_0 = hit_0 ? {1'b1, idx_0} : 6'd0;
wire [5:0] chosen_1 = hit_1 ? {1'b1, idx_1} : chosen_0;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen_1;
    end
end
endmodule
