module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
    // ---------------- nibble population counts (8 nibbles, 3 bits each) -------
    wire [7:0] x0 = {a_i[28],a_i[24],a_i[20],a_i[16],a_i[12],a_i[8],a_i[4],a_i[0]};
    wire [7:0] x1 = {a_i[29],a_i[25],a_i[21],a_i[17],a_i[13],a_i[9],a_i[5],a_i[1]};
    wire [7:0] x2 = {a_i[30],a_i[26],a_i[22],a_i[18],a_i[14],a_i[10],a_i[6],a_i[2]};
    wire [7:0] x3 = {a_i[31],a_i[27],a_i[23],a_i[19],a_i[15],a_i[11],a_i[7],a_i[3]};

    wire [7:0] hs = x0 ^ x1;
    wire [7:0] hc = x0 & x1;
    wire [7:0] ht = x2 ^ x3;
    wire [7:0] hu = x2 & x3;
    wire [7:0] hm = hs & ht;
    wire [7:0] he = hc ^ hu;

    wire [7:0] n0 = hs ^ ht;
    wire [7:0] n1 = he ^ hm;
    wire [7:0] n2 = (hc & hu) | (hm & he);

    // ---------------- byte counts : 4 lanes of (3-bit + 3-bit) ---------------
    wire [3:0] ea0 = {n0[6],n0[4],n0[2],n0[0]};
    wire [3:0] eb0 = {n0[7],n0[5],n0[3],n0[1]};
    wire [3:0] ea1 = {n1[6],n1[4],n1[2],n1[0]};
    wire [3:0] eb1 = {n1[7],n1[5],n1[3],n1[1]};
    wire [3:0] ea2 = {n2[6],n2[4],n2[2],n2[0]};
    wire [3:0] eb2 = {n2[7],n2[5],n2[3],n2[1]};

    wire [3:0] p0 = ea0 ^ eb0;
    wire [3:0] g0 = ea0 & eb0;
    wire [3:0] p1 = ea1 ^ eb1;
    wire [3:0] g1 = ea1 & eb1;
    wire [3:0] p2 = ea2 ^ eb2;
    wire [3:0] g2 = ea2 & eb2;

    wire [3:0] bc0 = p0;
    wire [3:0] bc1 = p1 ^ g0;
    wire [3:0] k2  = g1 | (p1 & g0);
    wire [3:0] bc2 = p2 ^ k2;
    wire [3:0] bc3 = g2 | (p2 & k2);

    // ---------------- half-word counts : 2 lanes of (4-bit + 4-bit) ----------
    wire [1:0] fa0 = {bc0[2],bc0[0]};
    wire [1:0] fb0 = {bc0[3],bc0[1]};
    wire [1:0] fa1 = {bc1[2],bc1[0]};
    wire [1:0] fb1 = {bc1[3],bc1[1]};
    wire [1:0] fa2 = {bc2[2],bc2[0]};
    wire [1:0] fb2 = {bc2[3],bc2[1]};
    wire [1:0] fa3 = {bc3[2],bc3[0]};
    wire [1:0] fb3 = {bc3[3],bc3[1]};

    wire [1:0] q0 = fa0 ^ fb0;
    wire [1:0] r0 = fa0 & fb0;
    wire [1:0] q1 = fa1 ^ fb1;
    wire [1:0] r1 = fa1 & fb1;
    wire [1:0] q2 = fa2 ^ fb2;
    wire [1:0] r2 = fa2 & fb2;
    wire [1:0] q3 = fa3 ^ fb3;
    wire [1:0] r3 = fa3 & fb3;

    wire [1:0] hh0 = q0;
    wire [1:0] d1  = r0;
    wire [1:0] hh1 = q1 ^ d1;
    wire [1:0] d2  = r1 | (q1 & d1);
    wire [1:0] hh2 = q2 ^ d2;
    wire [1:0] d3  = r2 | (q2 & d2);
    wire [1:0] hh3 = q3 ^ d3;
    wire [1:0] hh4 = r3 | (q3 & d3);

    // ---------------- final 5-bit + 5-bit carry-lookahead adder --------------
    wire [4:0] va = {hh4[0],hh3[0],hh2[0],hh1[0],hh0[0]};
    wire [4:0] vb = {hh4[1],hh3[1],hh2[1],hh1[1],hh0[1]};
    wire [4:0] pp = va ^ vb;
    wire [4:0] gg = va & vb;

    wire cc1 = gg[0];
    wire cc2 = gg[1] | (pp[1] & gg[0]);
    wire cc3 = gg[2] | (pp[2] & gg[1]) | (pp[2] & pp[1] & gg[0]);
    wire cc4 = gg[3] | (pp[3] & gg[2]) | (pp[3] & pp[2] & gg[1])
                     | (pp[3] & pp[2] & pp[1] & gg[0]);
    wire cc5 = gg[4] | (pp[4] & gg[3]) | (pp[4] & pp[3] & gg[2])
                     | (pp[4] & pp[3] & pp[2] & gg[1])
                     | (pp[4] & pp[3] & pp[2] & pp[1] & gg[0]);

    wire [5:0] total_0 = {cc5, pp[4]^cc4, pp[3]^cc3, pp[2]^cc2, pp[1]^cc1, pp[0]};

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o <= 6'd0;
        end else begin
            valid_o <= valid_i;
            if (valid_i)
                y_o <= total_0;
        end
    end
endmodule