module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [7:0] q0, q1, q2;
genvar i;
generate
 for (i=0;i<8;i=i+1) begin : lf
   wire pp = a_i[4*i]  ^a_i[4*i+1];
   wire gg = a_i[4*i]  &a_i[4*i+1];
   wire rr = a_i[4*i+2]^a_i[4*i+3];
   wire hh = a_i[4*i+2]&a_i[4*i+3];
   wire tt = pp&rr;
   assign q0[i] = pp^rr;
   assign q1[i] = (gg^hh)^tt;
   assign q2[i] = gg&hh;
 end
endgenerate

// round 1
wire a0  = q0[0]^q0[1]^q0[2];
wire ac0 = (q0[0]&q0[1])|(q0[2]&(q0[0]^q0[1]));
wire a1  = q0[3]^q0[4]^q0[5];
wire ac1 = (q0[3]&q0[4])|(q0[5]&(q0[3]^q0[4]));
wire a2  = q0[6]^q0[7];
wire ac2 = q0[6]&q0[7];

wire b0  = q1[0]^q1[1]^q1[2];
wire bc0 = (q1[0]&q1[1])|(q1[2]&(q1[0]^q1[1]));
wire b1  = q1[3]^q1[4]^q1[5];
wire bc1 = (q1[3]&q1[4])|(q1[5]&(q1[3]^q1[4]));
wire b2  = q1[6]^q1[7];
wire bc2 = q1[6]&q1[7];

wire c0  = q2[0]^q2[1]^q2[2];
wire cc0 = (q2[0]&q2[1])|(q2[2]&(q2[0]^q2[1]));
wire c1  = q2[3]^q2[4]^q2[5];
wire cc1 = (q2[3]&q2[4])|(q2[5]&(q2[3]^q2[4]));
wire c2  = q2[6]^q2[7];
wire cc2 = q2[6]&q2[7];

// round 2
wire y0 = (a2^a0)^a1;
wire d0 = (a2&a0)|(a1&(a2^a0));

wire e0  = (ac2^b2)^ac0;
wire ec0 = (ac2&b2)|(ac0&(ac2^b2));
wire e1  = (ac1^b0)^b1;
wire ec1 = (ac1&b0)|(b1&(ac1^b0));

wire f0  = (c2^c0)^c1;
wire fc0 = (c2&c0)|(c1&(c2^c0));
wire f1  = (bc2^bc0)^bc1;
wire fc1 = (bc2&bc0)|(bc1&(bc2^bc0));

wire g0  = (cc2^cc0)^cc1;
wire gc0 = (cc2&cc0)|(cc1&(cc2^cc0));

// round 3
wire y1 = (e0^d0)^e1;
wire h0 = (e0&d0)|(e1&(e0^d0));

wire i0  = (f0^ec0)^f1;
wire ic0 = (f0&ec0)|(f1&(f0^ec0));

wire j0  = (g0^fc0)^fc1;
wire jc0 = (g0&fc0)|(fc1&(g0^fc0));

// round 4
wire y2 = (ec1^i0)^h0;
wire k0 = (ec1&i0)|(h0&(ec1^i0));

wire y3 = (j0^ic0)^k0;
wire l0 = (j0&ic0)|(k0&(j0^ic0));

wire y4 = (gc0^jc0)^l0;
wire y5 = (gc0&jc0)|(l0&(gc0^jc0));

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