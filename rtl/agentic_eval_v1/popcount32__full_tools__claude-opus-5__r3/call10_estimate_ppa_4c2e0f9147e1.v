module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [3:0] P [0:3];
genvar i;
generate
 for (i=0;i<4;i=i+1) begin : pc8
   wire b0 = a_i[8*i+0];
   wire b1 = a_i[8*i+1];
   wire b2 = a_i[8*i+2];
   wire b3 = a_i[8*i+3];
   wire b4 = a_i[8*i+4];
   wire b5 = a_i[8*i+5];
   wire b6 = a_i[8*i+6];
   wire b7 = a_i[8*i+7];
   wire s0 = b0^b1^b2;
   wire c0 = (b0&b1)|((b0^b1)&b2);
   wire s1 = b3^b4^b5;
   wire c1 = (b3&b4)|((b3^b4)&b5);
   wire s2 = b6^b7;
   wire c2 = b6&b7;
   wire cx = (s0&s1)|((s0^s1)&s2);
   wire d  = c0^c1^c2;
   wire dc = (c0&c1)|((c0^c1)&c2);
   assign P[i][0] = s0^s1^s2;
   assign P[i][1] = d^cx;
   assign P[i][2] = dc^(d&cx);
   assign P[i][3] = dc&(d&cx);
 end
endgenerate

wire A0=P[0][0], B0=P[1][0], C0=P[2][0], D0=P[3][0];
wire A1=P[0][1], B1=P[1][1], C1=P[2][1], D1=P[3][1];
wire A2=P[0][2], B2=P[1][2], C2=P[2][2], D2=P[3][2];
wire A3=P[0][3], B3=P[1][3], C3=P[2][3], D3=P[3][3];

wire s  = A0^B0^C0;
wire cq = (A0&B0)|((A0^B0)&C0);
wire Y0 = s^D0;
wire cp = s&D0;

wire s1a = A1^B1^C1;
wire cr1 = (A1&B1)|((A1^B1)&C1);
wire s2a = D1^cq^cp;
wire cr2 = (D1&cq)|((D1^cq)&cp);
wire Y1  = s1a^s2a;
wire cr3 = s1a&s2a;

wire t1 = A2^B2^C2;
wire k1 = (A2&B2)|((A2^B2)&C2);
wire t2 = D2^cr1^cr2;
wire k2 = (D2&cr1)|((D2^cr1)&cr2);
wire Y2 = t1^t2^cr3;
wire k3 = (t1&t2)|((t1^t2)&cr3);

wire m1 = A3^B3^C3;
wire n1 = (A3&B3)|((A3^B3)&C3);
wire m2 = D3^k1^k2;
wire n2 = (D3&k1)|((D3^k1)&k2);
wire Y3 = m1^m2^k3;
wire n3 = (m1&m2)|((m1^m2)&k3);

wire Y4 = n1^n2^n3;
wire Y5 = (n1&n2)|((n1^n2)&n3);

wire [5:0] total = {Y5,Y4,Y3,Y2,Y1,Y0};

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