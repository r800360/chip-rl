module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Multi-level tree priority encoder with better balance
wire [4:0] idx_0;
wire hit_0;

// Level 1: Check 4 octets (8-bit each)
wire any_oct3 = |a_i[31:24];
wire any_oct2 = |a_i[23:16];
wire any_oct1 = |a_i[15:8];
wire any_oct0 = |a_i[7:0];

// Find index within each octet (0-7)
wire [2:0] idx_oct3, idx_oct2, idx_oct1, idx_oct0;

assign idx_oct3 = a_i[31] ? 3'd7 : a_i[30] ? 3'd6 : a_i[29] ? 3'd5 : a_i[28] ? 3'd4 :
                  a_i[27] ? 3'd3 : a_i[26] ? 3'd2 : a_i[25] ? 3'd1 : a_i[24] ? 3'd0 : 3'd0;

assign idx_oct2 = a_i[23] ? 3'd7 : a_i[22] ? 3'd6 : a_i[21] ? 3'd5 : a_i[20] ? 3'd4 :
                  a_i[19] ? 3'd3 : a_i[18] ? 3'd2 : a_i[17] ? 3'd1 : a_i[16] ? 3'd0 : 3'd0;

assign idx_oct1 = a_i[15] ? 3'd7 : a_i[14] ? 3'd6 : a_i[13] ? 3'd5 : a_i[12] ? 3'd4 :
                  a_i[11] ? 3'd3 : a_i[10] ? 3'd2 : a_i[9] ? 3'd1 : a_i[8] ? 3'd0 : 3'd0;

assign idx_oct0 = a_i[7] ? 3'd7 : a_i[6] ? 3'd6 : a_i[5] ? 3'd5 : a_i[4] ? 3'd4 :
                  a_i[3] ? 3'd3 : a_i[2] ? 3'd2 : a_i[1] ? 3'd1 : a_i[0] ? 3'd0 : 3'd0;

// Level 2: Combine octets with priority
wire [4:0] idx_combined;
wire hit_combined;

assign hit_combined = any_oct3 | any_oct2 | any_oct1 | any_oct0;
assign idx_combined = any_oct3 ? {any_oct3, idx_oct3 + 3'd0} + 5'd24 :
                      any_oct2 ? {any_oct2, idx_oct2 + 3'd0} + 5'd16 :
                      any_oct1 ? {any_oct1, idx_oct1 + 3'd0} + 5'd8 :
                      {any_oct0, idx_oct0 + 3'd0};

assign hit_0 = hit_combined;
assign idx_0 = idx_combined;

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
