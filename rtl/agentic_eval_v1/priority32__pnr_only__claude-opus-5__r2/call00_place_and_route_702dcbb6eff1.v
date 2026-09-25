module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// ---- 4-bit leaf encoders ----
wire [7:0]  v4;
wire [15:0] e4;

assign v4[0]     = |a_i[3:0];
assign e4[1:0]   = {a_i[3]  | a_i[2],  a_i[3]  | (~a_i[2]  & a_i[1])};
assign v4[1]     = |a_i[7:4];
assign e4[3:2]   = {a_i[7]  | a_i[6],  a_i[7]  | (~a_i[6]  & a_i[5])};
assign v4[2]     = |a_i[11:8];
assign e4[5:4]   = {a_i[11] | a_i[10], a_i[11] | (~a_i[10] & a_i[9])};
assign v4[3]     = |a_i[15:12];
assign e4[7:6]   = {a_i[15] | a_i[14], a_i[15] | (~a_i[14] & a_i[13])};
assign v4[4]     = |a_i[19:16];
assign e4[9:8]   = {a_i[19] | a_i[18], a_i[19] | (~a_i[18] & a_i[17])};
assign v4[5]     = |a_i[23:20];
assign e4[11:10] = {a_i[23] | a_i[22], a_i[23] | (~a_i[22] & a_i[21])};
assign v4[6]     = |a_i[27:24];
assign e4[13:12] = {a_i[27] | a_i[26], a_i[27] | (~a_i[26] & a_i[25])};
assign v4[7]     = |a_i[31:28];
assign e4[15:14] = {a_i[31] | a_i[30], a_i[31] | (~a_i[30] & a_i[29])};

// ---- 8-bit merge ----
wire [3:0]  v8;
wire [11:0] e8;
assign v8[0]    = v4[1] | v4[0];
assign e8[2:0]  = {v4[1], v4[1] ? e4[3:2]   : e4[1:0]};
assign v8[1]    = v4[3] | v4[2];
assign e8[5:3]  = {v4[3], v4[3] ? e4[7:6]   : e4[5:4]};
assign v8[2]    = v4[5] | v4[4];
assign e8[8:6]  = {v4[5], v4[5] ? e4[11:10] : e4[9:8]};
assign v8[3]    = v4[7] | v4[6];
assign e8[11:9] = {v4[7], v4[7] ? e4[15:14] : e4[13:12]};

// ---- 16-bit merge ----
wire [1:0] v16;
wire [7:0] e16;
assign v16[0]   = v8[1] | v8[0];
assign e16[3:0] = {v8[1], v8[1] ? e8[5:3]  : e8[2:0]};
assign v16[1]   = v8[3] | v8[2];
assign e16[7:4] = {v8[3], v8[3] ? e8[11:9] : e8[8:6]};

// ---- 32-bit merge ----
wire hit = v16[1] | v16[0];
wire [5:0] chosen = {hit, v16[1], v16[1] ? e16[7:4] : e16[3:0]};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen;
    end
end
endmodule