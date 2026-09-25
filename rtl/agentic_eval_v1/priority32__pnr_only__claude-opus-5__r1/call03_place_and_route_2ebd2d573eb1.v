module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// ---- level 1 : nibble occupancy and nibble-local bits ----
wire n0 = |a_i[3:0];
wire n1 = |a_i[7:4];
wire n2 = |a_i[11:8];
wire n3 = |a_i[15:12];
wire n4 = |a_i[19:16];
wire n5 = |a_i[23:20];
wire n6 = |a_i[27:24];
wire n7 = |a_i[31:28];

wire u0 = a_i[3]  | a_i[2];
wire u1 = a_i[7]  | a_i[6];
wire u2 = a_i[11] | a_i[10];
wire u3 = a_i[15] | a_i[14];
wire u4 = a_i[19] | a_i[18];
wire u5 = a_i[23] | a_i[22];
wire u6 = a_i[27] | a_i[26];
wire u7 = a_i[31] | a_i[30];

wire l0 = a_i[3]  | (~a_i[2]  & a_i[1]);
wire l1 = a_i[7]  | (~a_i[6]  & a_i[5]);
wire l2 = a_i[11] | (~a_i[10] & a_i[9]);
wire l3 = a_i[15] | (~a_i[14] & a_i[13]);
wire l4 = a_i[19] | (~a_i[18] & a_i[17]);
wire l5 = a_i[23] | (~a_i[22] & a_i[21]);
wire l6 = a_i[27] | (~a_i[26] & a_i[25]);
wire l7 = a_i[31] | (~a_i[30] & a_i[29]);

// ---- level 2 : "nothing higher" masks (single NOR gates) ----
wire nb7  = ~n7;
wire nb3  = ~n3;
wire nb1  = ~n1;
wire hb5  = ~(n7 | n6);
wire hb4  = ~(n7 | n6 | n5);
wire hb3  = ~(n7 | n6 | n5 | n4);
wire eb32 = ~(n3 | n2);
wire eb54 = ~(n5 | n4);
wire m654 = ~(n6 | n5 | n4);

wire e76 = n7 | n6;
wire e32 = n3 | n2;

// ---- high index bits ----
wire s2  = n7 | n6 | n5 | n4;
wire s1  = e76 | (eb54 & e32);
wire s0  = n7 | (~n6 & n5) | (m654 & n3) | (m654 & eb32 & n1);
wire hit = s2 | n3 | n2 | n1 | n0;

// ---- low index bits : upper/lower half factored, low fanout masks ----
wire au = u7 | (u6 & nb7) | (u5 & hb5) | (u4 & hb4);
wire cu = u3 | (u2 & nb3) | (eb32 & (u1 | (u0 & nb1)));
wire y1 = au | (hb3 & cu);

wire al = l7 | (l6 & nb7) | (l5 & hb5) | (l4 & hb4);
wire cl = l3 | (l2 & nb3) | (eb32 & (l1 | (l0 & nb1)));
wire y0 = al | (hb3 & cl);

wire [5:0] chosen = {hit, s2, s1, s0, y1, y0};

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