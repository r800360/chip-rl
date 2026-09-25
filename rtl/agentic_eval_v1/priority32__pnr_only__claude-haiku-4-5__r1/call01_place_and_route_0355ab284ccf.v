module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Optimized priority encoder using 4-level tree structure
// Reduces depth and allows better synthesis optimizations

wire [4:0] idx_0;
wire hit_0;

// Level 1: Split into 4 octets (8-bit chunks)
wire [3:0] idx_oct3, idx_oct2, idx_oct1, idx_oct0;
wire any_oct3 = |a_i[31:24];
wire any_oct2 = |a_i[23:16];
wire any_oct1 = |a_i[15:8];
wire any_oct0 = |a_i[7:0];

// 8-bit encoders for each octet
assign idx_oct3 = a_i[31] ? 4'd7 : a_i[30] ? 4'd6 : a_i[29] ? 4'd5 : a_i[28] ? 4'd4 :
                  a_i[27] ? 4'd3 : a_i[26] ? 4'd2 : a_i[25] ? 4'd1 : a_i[24] ? 4'd0 : 4'd0;

assign idx_oct2 = a_i[23] ? 4'd7 : a_i[22] ? 4'd6 : a_i[21] ? 4'd5 : a_i[20] ? 4'd4 :
                  a_i[19] ? 4'd3 : a_i[18] ? 4'd2 : a_i[17] ? 4'd1 : a_i[16] ? 4'd0 : 4'd0;

assign idx_oct1 = a_i[15] ? 4'd7 : a_i[14] ? 4'd6 : a_i[13] ? 4'd5 : a_i[12] ? 4'd4 :
                  a_i[11] ? 4'd3 : a_i[10] ? 4'd2 : a_i[9] ? 4'd1 : a_i[8] ? 4'd0 : 4'd0;

assign idx_oct0 = a_i[7] ? 4'd7 : a_i[6] ? 4'd6 : a_i[5] ? 4'd5 : a_i[4] ? 4'd4 :
                  a_i[3] ? 4'd3 : a_i[2] ? 4'd2 : a_i[1] ? 4'd1 : a_i[0] ? 4'd0 : 4'd0;

// Level 2: Select among octets with priority
wire [4:0] idx_temp;
wire any_temp;

assign any_temp = any_oct3 | any_oct2 | any_oct1 | any_oct0;
assign idx_temp = any_oct3 ? {2'd3, idx_oct3} :
                  any_oct2 ? {2'd2, idx_oct2} :
                  any_oct1 ? {2'd1, idx_oct1} :
                  {2'd0, idx_oct0};

assign hit_0 = any_temp;
assign idx_0 = idx_temp;

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
