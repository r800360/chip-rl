module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// nibble level
wire [7:0] nh, n1, n0;
assign nh[0] = |a_i[3:0];   assign n1[0] = |a_i[3:2];   assign n0[0] = a_i[3] | (a_i[1] & ~a_i[2]);
assign nh[1] = |a_i[7:4];   assign n1[1] = |a_i[7:6];   assign n0[1] = a_i[7] | (a_i[5] & ~a_i[6]);
assign nh[2] = |a_i[11:8];  assign n1[2] = |a_i[11:10]; assign n0[2] = a_i[11] | (a_i[9] & ~a_i[10]);
assign nh[3] = |a_i[15:12]; assign n1[3] = |a_i[15:14]; assign n0[3] = a_i[15] | (a_i[13] & ~a_i[14]);
assign nh[4] = |a_i[19:16]; assign n1[4] = |a_i[19:18]; assign n0[4] = a_i[19] | (a_i[17] & ~a_i[18]);
assign nh[5] = |a_i[23:20]; assign n1[5] = |a_i[23:22]; assign n0[5] = a_i[23] | (a_i[21] & ~a_i[22]);
assign nh[6] = |a_i[27:24]; assign n1[6] = |a_i[27:26]; assign n0[6] = a_i[27] | (a_i[25] & ~a_i[26]);
assign nh[7] = |a_i[31:28]; assign n1[7] = |a_i[31:30]; assign n0[7] = a_i[31] | (a_i[29] & ~a_i[30]);

// byte level
wire [3:0] bh, b2, b1, b0;
assign bh[0] = nh[1] | nh[0]; assign b2[0] = nh[1];
assign b1[0] = nh[1] ? n1[1] : n1[0];
assign b0[0] = nh[1] ? n0[1] : n0[0];
assign bh[1] = nh[3] | nh[2]; assign b2[1] = nh[3];
assign b1[1] = nh[3] ? n1[3] : n1[2];
assign b0[1] = nh[3] ? n0[3] : n0[2];
assign bh[2] = nh[5] | nh[4]; assign b2[2] = nh[5];
assign b1[2] = nh[5] ? n1[5] : n1[4];
assign b0[2] = nh[5] ? n0[5] : n0[4];
assign bh[3] = nh[7] | nh[6]; assign b2[3] = nh[7];
assign b1[3] = nh[7] ? n1[7] : n1[6];
assign b0[3] = nh[7] ? n0[7] : n0[6];

// half-word level
wire [1:0] hh, h3, h2, h1, h0;
assign hh[0] = bh[1] | bh[0]; assign h3[0] = bh[1];
assign h2[0] = bh[1] ? b2[1] : b2[0];
assign h1[0] = bh[1] ? b1[1] : b1[0];
assign h0[0] = bh[1] ? b0[1] : b0[0];
assign hh[1] = bh[3] | bh[2]; assign h3[1] = bh[3];
assign h2[1] = bh[3] ? b2[3] : b2[2];
assign h1[1] = bh[3] ? b1[3] : b1[2];
assign h0[1] = bh[3] ? b0[3] : b0[2];

// word level
wire hit = hh[1] | hh[0];
wire w4 = hh[1];
wire w3 = hh[1] ? h3[1] : h3[0];
wire w2 = hh[1] ? h2[1] : h2[0];
wire w1 = hh[1] ? h1[1] : h1[0];
wire w0 = hh[1] ? h0[1] : h0[0];

wire [5:0] chosen_0 = {hit, w4, w3, w2, w1, w0};

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