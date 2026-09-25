module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// round 1
wire e0 = a_i[0]^a_i[1];
wire s0 = e0^a_i[2];
wire r0 = (a_i[0]&a_i[1])|(e0&a_i[2]);
wire e1 = a_i[3]^a_i[4];
wire s1 = e1^a_i[5];
wire r1 = (a_i[3]&a_i[4])|(e1&a_i[5]);
wire e2 = a_i[6]^a_i[7];
wire s2 = e2^a_i[8];
wire r2 = (a_i[6]&a_i[7])|(e2&a_i[8]);
wire e3 = a_i[9]^a_i[10];
wire s3 = e3^a_i[11];
wire r3 = (a_i[9]&a_i[10])|(e3&a_i[11]);
wire e4 = a_i[12]^a_i[13];
wire s4 = e4^a_i[14];
wire r4 = (a_i[12]&a_i[13])|(e4&a_i[14]);
wire e5 = a_i[15]^a_i[16];
wire s5 = e5^a_i[17];
wire r5 = (a_i[15]&a_i[16])|(e5&a_i[17]);
wire e6 = a_i[18]^a_i[19];
wire s6 = e6^a_i[20];
wire r6 = (a_i[18]&a_i[19])|(e6&a_i[20]);
wire e7 = a_i[21]^a_i[22];
wire s7 = e7^a_i[23];
wire r7 = (a_i[21]&a_i[22])|(e7&a_i[23]);
wire e8 = a_i[24]^a_i[25];
wire s8 = e8^a_i[26];
wire r8 = (a_i[24]&a_i[25])|(e8&a_i[26]);
wire e9 = a_i[27]^a_i[28];
wire s9 = e9^a_i[29];
wire r9 = (a_i[27]&a_i[28])|(e9&a_i[29]);
wire hs = a_i[30]^a_i[31];
wire hc = a_i[30]&a_i[31];

// round 2
wire f0 = s0^s1;
wire u0 = f0^s2;
wire uc0 = (s0&s1)|(f0&s2);
wire f1 = s3^s4;
wire u1 = f1^s5;
wire uc1 = (s3&s4)|(f1&s5);
wire f2 = s6^s7;
wire u2 = f2^s8;
wire uc2 = (s6&s7)|(f2&s8);
wire u3 = s9^hs;
wire uc3 = s9&hs;

wire g0 = r0^r1;
wire v0 = g0^r2;
wire vc0 = (r0&r1)|(g0&r2);
wire g1 = r3^r4;
wire v1 = g1^r5;
wire vc1 = (r3&r4)|(g1&r5);
wire g2x = r6^r7;
wire v2 = g2x^r8;
wire vc2 = (r6&r7)|(g2x&r8);
wire v3 = r9^hc;
wire vc3 = r9&hc;

// round 3
wire w0 = u3^u0;
wire wc0 = u3&u0;
wire w1 = u1^u2;
wire wc1 = u1&u2;

wire h0 = v3^uc3;
wire x0 = h0^v0;
wire xc0 = (v3&uc3)|(h0&v0);
wire h1 = v1^v2;
wire x1 = h1^uc0;
wire xc1 = (v1&v2)|(h1&uc0);
wire x2 = uc1^uc2;
wire xc2 = uc1&uc2;

wire z0 = vc3^vc0;
wire zc0 = vc3&vc0;
wire z1 = vc1^vc2;
wire zc1 = vc1&vc2;

// round 4
wire h2 = x0^x2;
wire m0 = h2^x1;
wire mc0 = (x0&x2)|(h2&x1);
wire m1 = wc0^wc1;
wire mc1 = wc0&wc1;

wire h3 = z0^z1;
wire n0 = h3^xc1;
wire nc0 = (z0&z1)|(h3&xc1);
wire n1 = xc0^xc2;
wire nc1 = xc0&xc2;

wire o0 = zc0^zc1;
wire oc0 = zc0&zc1;

// round 5
wire h4 = n1^mc1;
wire q0 = h4^n0;
wire qc0 = (n1&mc1)|(h4&n0);
wire h5 = o0^nc1;
wire rr0 = h5^nc0;
wire rc0 = (o0&nc1)|(h5&nc0);

// final CPA
wire y0 = w0^w1;
wire k1 = w0&w1;
wire t1 = m1^k1;
wire y1 = t1^m0;
wire k2 = (m1&k1)|(t1&m0);
wire p2 = mc0^q0;
wire y2 = p2^k2;
wire k3 = (mc0&q0)|(p2&k2);
wire p3 = rr0^qc0;
wire y3 = p3^k3;
wire k4 = (rr0&qc0)|(p3&k3);
wire p4 = oc0^rc0;
wire y4 = p4^k4;
wire y5 = (oc0&rc0)|(p4&k4);

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