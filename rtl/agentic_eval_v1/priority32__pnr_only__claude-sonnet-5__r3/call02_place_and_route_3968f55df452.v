module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire hit_gr3 = |a_i[31:24];
wire [2:0] idx_gr3 = a_i[31] ? 3'd7 : a_i[30] ? 3'd6 : a_i[29] ? 3'd5 : a_i[28] ? 3'd4 :
                     a_i[27] ? 3'd3 : a_i[26] ? 3'd2 : a_i[25] ? 3'd1 : a_i[24] ? 3'd0 : 3'd0;

wire hit_gr2 = |a_i[23:16];
wire [2:0] idx_gr2 = a_i[23] ? 3'd7 : a_i[22] ? 3'd6 : a_i[21] ? 3'd5 : a_i[20] ? 3'd4 :
                     a_i[19] ? 3'd3 : a_i[18] ? 3'd2 : a_i[17] ? 3'd1 : a_i[16] ? 3'd0 : 3'd0;

wire hit_gr1 = |a_i[15:8];
wire [2:0] idx_gr1 = a_i[15] ? 3'd7 : a_i[14] ? 3'd6 : a_i[13] ? 3'd5 : a_i[12] ? 3'd4 :
                     a_i[11] ? 3'd3 : a_i[10] ? 3'd2 : a_i[9]  ? 3'd1 : a_i[8]  ? 3'd0 : 3'd0;

wire hit_gr0 = |a_i[7:0];
wire [2:0] idx_gr0 = a_i[7] ? 3'd7 : a_i[6] ? 3'd6 : a_i[5] ? 3'd5 : a_i[4] ? 3'd4 :
                     a_i[3] ? 3'd3 : a_i[2] ? 3'd2 : a_i[1] ? 3'd1 : a_i[0] ? 3'd0 : 3'd0;

wire hit_0 = hit_gr3 | hit_gr2 | hit_gr1 | hit_gr0;
wire [4:0] idx_0 = hit_gr3 ? {2'd3, idx_gr3} :
                   hit_gr2 ? {2'd2, idx_gr2} :
                   hit_gr1 ? {2'd1, idx_gr1} :
                             {2'd0, idx_gr0};

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
