module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Binary tree-structured priority encoder
wire [4:0] idx_0;
wire hit_0;

wire [4:0] l0[31:0], l1[15:0], l2[7:0], l3[3:0], l4[1:0];
wire h0[31:0], h1[15:0], h2[7:0], h3[3:0], h4[1:0];

// Level 0: for each bit
assign h0[31] = a_i[31]; assign l0[31] = 5'd31;
assign h0[30] = a_i[30]; assign l0[30] = 5'd30;
assign h0[29] = a_i[29]; assign l0[29] = 5'd29;
assign h0[28] = a_i[28]; assign l0[28] = 5'd28;
assign h0[27] = a_i[27]; assign l0[27] = 5'd27;
assign h0[26] = a_i[26]; assign l0[26] = 5'd26;
assign h0[25] = a_i[25]; assign l0[25] = 5'd25;
assign h0[24] = a_i[24]; assign l0[24] = 5'd24;
assign h0[23] = a_i[23]; assign l0[23] = 5'd23;
assign h0[22] = a_i[22]; assign l0[22] = 5'd22;
assign h0[21] = a_i[21]; assign l0[21] = 5'd21;
assign h0[20] = a_i[20]; assign l0[20] = 5'd20;
assign h0[19] = a_i[19]; assign l0[19] = 5'd19;
assign h0[18] = a_i[18]; assign l0[18] = 5'd18;
assign h0[17] = a_i[17]; assign l0[17] = 5'd17;
assign h0[16] = a_i[16]; assign l0[16] = 5'd16;
assign h0[15] = a_i[15]; assign l0[15] = 5'd15;
assign h0[14] = a_i[14]; assign l0[14] = 5'd14;
assign h0[13] = a_i[13]; assign l0[13] = 5'd13;
assign h0[12] = a_i[12]; assign l0[12] = 5'd12;
assign h0[11] = a_i[11]; assign l0[11] = 5'd11;
assign h0[10] = a_i[10]; assign l0[10] = 5'd10;
assign h0[9] = a_i[9]; assign l0[9] = 5'd9;
assign h0[8] = a_i[8]; assign l0[8] = 5'd8;
assign h0[7] = a_i[7]; assign l0[7] = 5'd7;
assign h0[6] = a_i[6]; assign l0[6] = 5'd6;
assign h0[5] = a_i[5]; assign l0[5] = 5'd5;
assign h0[4] = a_i[4]; assign l0[4] = 5'd4;
assign h0[3] = a_i[3]; assign l0[3] = 5'd3;
assign h0[2] = a_i[2]; assign l0[2] = 5'd2;
assign h0[1] = a_i[1]; assign l0[1] = 5'd1;
assign h0[0] = a_i[0]; assign l0[0] = 5'd0;

// Level 1: pairs
assign h1[15] = h0[31] | h0[30]; assign l1[15] = h0[31] ? l0[31] : l0[30];
assign h1[14] = h0[29] | h0[28]; assign l1[14] = h0[29] ? l0[29] : l0[28];
assign h1[13] = h0[27] | h0[26]; assign l1[13] = h0[27] ? l0[27] : l0[26];
assign h1[12] = h0[25] | h0[24]; assign l1[12] = h0[25] ? l0[25] : l0[24];
assign h1[11] = h0[23] | h0[22]; assign l1[11] = h0[23] ? l0[23] : l0[22];
assign h1[10] = h0[21] | h0[20]; assign l1[10] = h0[21] ? l0[21] : l0[20];
assign h1[9] = h0[19] | h0[18]; assign l1[9] = h0[19] ? l0[19] : l0[18];
assign h1[8] = h0[17] | h0[16]; assign l1[8] = h0[17] ? l0[17] : l0[16];
assign h1[7] = h0[15] | h0[14]; assign l1[7] = h0[15] ? l0[15] : l0[14];
assign h1[6] = h0[13] | h0[12]; assign l1[6] = h0[13] ? l0[13] : l0[12];
assign h1[5] = h0[11] | h0[10]; assign l1[5] = h0[11] ? l0[11] : l0[10];
assign h1[4] = h0[9] | h0[8]; assign l1[4] = h0[9] ? l0[9] : l0[8];
assign h1[3] = h0[7] | h0[6]; assign l1[3] = h0[7] ? l0[7] : l0[6];
assign h1[2] = h0[5] | h0[4]; assign l1[2] = h0[5] ? l0[5] : l0[4];
assign h1[1] = h0[3] | h0[2]; assign l1[1] = h0[3] ? l0[3] : l0[2];
assign h1[0] = h0[1] | h0[0]; assign l1[0] = h0[1] ? l0[1] : l0[0];

// Level 2: quads
assign h2[7] = h1[15] | h1[14]; assign l2[7] = h1[15] ? l1[15] : l1[14];
assign h2[6] = h1[13] | h1[12]; assign l2[6] = h1[13] ? l1[13] : l1[12];
assign h2[5] = h1[11] | h1[10]; assign l2[5] = h1[11] ? l1[11] : l1[10];
assign h2[4] = h1[9] | h1[8]; assign l2[4] = h1[9] ? l1[9] : l1[8];
assign h2[3] = h1[7] | h1[6]; assign l2[3] = h1[7] ? l1[7] : l1[6];
assign h2[2] = h1[5] | h1[4]; assign l2[2] = h1[5] ? l1[5] : l1[4];
assign h2[1] = h1[3] | h1[2]; assign l2[1] = h1[3] ? l1[3] : l1[2];
assign h2[0] = h1[1] | h1[0]; assign l2[0] = h1[1] ? l1[1] : l1[0];

// Level 3: octets
assign h3[3] = h2[7] | h2[6]; assign l3[3] = h2[7] ? l2[7] : l2[6];
assign h3[2] = h2[5] | h2[4]; assign l3[2] = h2[5] ? l2[5] : l2[4];
assign h3[1] = h2[3] | h2[2]; assign l3[1] = h2[3] ? l2[3] : l2[2];
assign h3[0] = h2[1] | h2[0]; assign l3[0] = h2[1] ? l2[1] : l2[0];

// Level 4: 16-bit halves
assign h4[1] = h3[3] | h3[2]; assign l4[1] = h3[3] ? l3[3] : l3[2];
assign h4[0] = h3[1] | h3[0]; assign l4[0] = h3[1] ? l3[1] : l3[0];

// Final: 32-bit result
assign hit_0 = h4[1] | h4[0];
assign idx_0 = h4[1] ? l4[1] : l4[0];

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