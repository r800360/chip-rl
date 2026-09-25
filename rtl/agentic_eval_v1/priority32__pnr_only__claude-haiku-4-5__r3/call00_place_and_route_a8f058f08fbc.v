module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire hit_0 = |a_i[31:0];

// Tree-based priority encoder - divide and conquer approach
wire upper_half_valid = |a_i[31:16];
wire [3:0] upper_idx;
wire [3:0] lower_idx;

// Encode upper half (bits 31:16) - 4 bits per 16 bits
assign upper_idx = 
    a_i[31] ? 4'd15 : a_i[30] ? 4'd14 : a_i[29] ? 4'd13 : a_i[28] ? 4'd12 :
    a_i[27] ? 4'd11 : a_i[26] ? 4'd10 : a_i[25] ? 4'd9 : a_i[24] ? 4'd8 :
    a_i[23] ? 4'd7 : a_i[22] ? 4'd6 : a_i[21] ? 4'd5 : a_i[20] ? 4'd4 :
    a_i[19] ? 4'd3 : a_i[18] ? 4'd2 : a_i[17] ? 4'd1 : 4'd0;

// Encode lower half (bits 15:0) - 4 bits per 16 bits  
assign lower_idx =
    a_i[15] ? 4'd15 : a_i[14] ? 4'd14 : a_i[13] ? 4'd13 : a_i[12] ? 4'd12 :
    a_i[11] ? 4'd11 : a_i[10] ? 4'd10 : a_i[9] ? 4'd9 : a_i[8] ? 4'd8 :
    a_i[7] ? 4'd7 : a_i[6] ? 4'd6 : a_i[5] ? 4'd5 : a_i[4] ? 4'd4 :
    a_i[3] ? 4'd3 : a_i[2] ? 4'd2 : a_i[1] ? 4'd1 : 4'd0;

// Select between upper and lower
wire [4:0] idx_0 = upper_half_valid ? {1'b1, upper_idx} : {1'b0, lower_idx};

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