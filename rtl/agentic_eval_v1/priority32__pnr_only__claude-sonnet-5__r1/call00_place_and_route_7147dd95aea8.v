module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

function [2:0] pri8;
    input [7:0] bits;
    begin
        casez (bits)
            8'b1???????: pri8 = 3'd7;
            8'b01??????: pri8 = 3'd6;
            8'b001?????: pri8 = 3'd5;
            8'b0001????: pri8 = 3'd4;
            8'b00001???: pri8 = 3'd3;
            8'b000001??: pri8 = 3'd2;
            8'b0000001?: pri8 = 3'd1;
            8'b00000001: pri8 = 3'd0;
            default:     pri8 = 3'd0;
        endcase
    end
endfunction

wire [7:0] g_hit;
wire [2:0] g_idx0, g_idx1, g_idx2, g_idx3;

assign g_hit[0] = |a_i[7:0];
assign g_hit[1] = |a_i[15:8];
assign g_hit[2] = |a_i[23:16];
assign g_hit[3] = |a_i[31:24];

assign g_idx0 = pri8(a_i[7:0]);
assign g_idx1 = pri8(a_i[15:8]);
assign g_idx2 = pri8(a_i[23:16]);
assign g_idx3 = pri8(a_i[31:24]);

wire hit_0 = |a_i;
wire [4:0] idx_0 = g_hit[3] ? {2'd3, g_idx3} :
                    g_hit[2] ? {2'd2, g_idx2} :
                    g_hit[1] ? {2'd1, g_idx1} :
                               {2'd0, g_idx0};

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
