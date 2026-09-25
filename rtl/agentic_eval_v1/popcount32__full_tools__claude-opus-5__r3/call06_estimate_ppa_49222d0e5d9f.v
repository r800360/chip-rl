module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// ---------------- round 1 : 10 FA + 1 HA ----------------
wire s0 = (a_i[0]^a_i[1])^a_i[2];
wire r0 = (a_i[0]&a_i[1])|((a_i[0]|a_i[1])&a_i[2]);
wire s1 = (a_i[3]^a_i[4])^a_i[5];
wire r1 = (a_i[3]&a_i[4])|((a_i[3]|a_i[4])&a_i[5]);
wire s2 = (a_i[6]^a_i[7])^a_i[8];
wire r2 = (a_i[6]&a_i[7])|((a_i[6]|a_i[7])&a_i[8]);
wire s3 = (a_i[9]^a_i[10])^a_i[11];
wire r3 = (a_i[9]&a_i[10])|((a_i[9]|a_i[10])&a_i[11]);
wire s4 = (a_i[12]^a_i[13])^a_i[14];
wire r4 = (a_i[12]&a_i[13])|((a_i[12]|a_i[13])&a_i[14]);
wire s5 = (a_i[15]^a_i[16])^a_i[17];
wire r5 = (a_i[15]&a_i[16])|((a_i[15]|a_i[16])&a_i[17]);
wire s6 = (a_i[18]^a_i[19])^a_i[20];
wire r6 = (a_i[18]&a_i[19])|((a_i[18]|a_i[19])&a_i[20]);
wire s7 = (a_i[21]^a_i[22])^a_i[23];
wire r7 = (a_i[21]&a_i[22])|((a_i[21]|a_i[22])&a_i[23]);
wire s8 = (a_i[24]^a_i[25])^a_i[26];
wire r8 = (a_i[24]&a_i[25])|((a_i[24]|a_i[25])&a_i[26]);
wire s9 = (a_i[27]^a_i[28])^a_i[29];
wire r9 = (a_i[27]&a_i[28])|((a_i[27]|a_i[28])&a_i[29]);
wire hs = a_i[30]^a_i[31];
wire hc = a_i[30]&a_i[31];

// ---------------- round 2 ----------------
wire u0 = (s0^s1)^s2;
wire uc0 = (s0&s1)|((s0|s1)&s2);
wire u1 = (s3^s4)^s5;
wire uc1 = (s3&s4)|((s3|s4)&s5);
wire u2 = (s6^s7)^s8;
wire uc2 = (s6&s7)|((s6|s7)&s8);
wire u3 = s9^hs;
wire uc3 = s9&hs;

wire v0 = (r0^r1)^r2;
wire vc0 = (r0&r1)|((r0|r1)&r2);
wire v1 = (r3^r4)^r5;
wire vc1 = (r3&r4)|((r3|r4)&r5);
wire v2 = (r6^r7)^r8;
wire vc2 = (r6&r7)|((r6|r7)&r8);
wire v3 = r9^hc;
wire vc3 = r9&hc;

// ---------------- round 3 ----------------
wire w0 = u3^u0;
wire wc0 = u3&u0;
wire w1 = u1^u2;
wire wc1 = u1&u2;

wire x0 = (v3^uc3)^v0;
wire xc0 = (v3&uc3)|((v3|uc3)&v0);
wire x1 = (v1^v2)^uc0;
wire xc1 = (v1&v2)|((v1|v2)&uc0);
wire x2 = uc1^uc2;
wire xc2 = uc1&uc2;

wire z0 = vc3^vc0;
wire zc0 = vc3&vc0;
wire z1 = vc1^vc2;
wire zc1 = vc1&vc2;

// ---------------- round 4 ----------------
wire m0 = (x0^x2)^x1;
wire mc0 = (x0&x2)|((x0|x2)&x1);
wire m1 = wc0^wc1;
wire mc1 = wc0&wc1;

wire n0 = (z0^z1)^xc1;
wire nc0 = (z0&z1)|((z0|z1)&xc1);
wire n1 = xc0^xc2;
wire nc1 = xc0&xc2;

wire o0 = zc0^zc1;
wire oc0 = zc0&zc1;

// ---------------- round 5 ----------------
wire q0 = (n1^mc1)^n0;
wire qc0 = (n1&mc1)|((n1|mc1)&n0);
wire rr0 = (o0^nc1)^nc0;
wire rc0 = (o0&nc1)|((o0|nc1)&nc0);

// ---------------- final CPA (2 rows) ----------------
wire A0 = w0,  B0 = w1;
wire A1 = m1,  B1 = m0;
wire A2 = mc0, B2 = q0;
wire A3 = rr0, B3 = qc0;
wire A4 = oc0, B4 = rc0;

wire y0 = A0^B0;
wire k1 = A0&B0;
wire y1 = (A1^k1)^B1;
wire k2 = (A1&k1)|((A1|k1)&B1);
wire p2 = A2^B2;
wire g2 = A2&B2;
wire y2 = p2^k2;
wire k3 = g2|(p2&k2);
wire p3 = A3^B3;
wire g3 = A3&B3;
wire y3 = p3^k3;
wire k4 = g3|(p3&k3);
wire p4 = A4^B4;
wire g4 = A4&B4;
wire y4 = p4^k4;
wire y5 = g4|(p4&k4);

wire [5:0] total = {y5,y4,y3,y2,y1,y0};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= total;
    end
end
endmodule