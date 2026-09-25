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

// Build encoders for 4-bit chunks
wire [3:0] enc [7:0];
assign enc[7] = a_i[31] ? 4'd3 : a_i[30] ? 4'd2 : a_i[29] ? 4'd1 : a_i[28] ? 4'd0 : 4'd0;
assign enc[6] = a_i[27] ? 4'd3 : a_i[26] ? 4'd2 : a_i[25] ? 4'd1 : a_i[24] ? 4'd0 : 4'd0;
assign enc[5] = a_i[23] ? 4'd3 : a_i[22] ? 4'd2 : a_i[21] ? 4'd1 : a_i[20] ? 4'd0 : 4'd0;
assign enc[4] = a_i[19] ? 4'd3 : a_i[18] ? 4'd2 : a_i[17] ? 4'd1 : a_i[16] ? 4'd0 : 4'd0;
assign enc[3] = a_i[15] ? 4'd3 : a_i[14] ? 4'd2 : a_i[13] ? 4'd1 : a_i[12] ? 4'd0 : 4'd0;
assign enc[2] = a_i[11] ? 4'd3 : a_i[10] ? 4'd2 : a_i[9] ? 4'd1 : a_i[8] ? 4'd0 : 4'd0;
assign enc[1] = a_i[7] ? 4'd3 : a_i[6] ? 4'd2 : a_i[5] ? 4'd1 : a_i[4] ? 4'd0 : 4'd0;
assign enc[0] = a_i[3] ? 4'd3 : a_i[2] ? 4'd2 : a_i[1] ? 4'd1 : a_i[0] ? 4'd0 : 4'd0;

wire hit [7:0];
assign hit[7] = |a_i[31:28];
assign hit[6] = |a_i[27:24];
assign hit[5] = |a_i[23:20];
assign hit[4] = |a_i[19:16];
assign hit[3] = |a_i[15:12];
assign hit[2] = |a_i[11:8];
assign hit[1] = |a_i[7:4];
assign hit[0] = |a_i[3:0];

wire [2:0] chunk_sel = hit[7] ? 3'd7 : hit[6] ? 3'd6 : hit[5] ? 3'd5 : hit[4] ? 3'd4 : hit[3] ? 3'd3 : hit[2] ? 3'd2 : hit[1] ? 3'd1 : 3'd0;

wire [4:0] idx_0 = {chunk_sel, enc[chunk_sel][1:0]};
wire [5:0] chosen_0 = {hit_0, idx_0};

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