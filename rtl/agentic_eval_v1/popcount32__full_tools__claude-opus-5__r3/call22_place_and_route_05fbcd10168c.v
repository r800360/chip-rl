module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire s0 = a_i[0]^a_i[1]^a_i[2];
wire c0 = (a_i[0]&a_i[1])|(a_i[2]&(a_i[0]^a_i[1]));
wire s1 = a_i[3]^a_i[4]^a_i[5];
wire c1 = (a_i[3]&a_i[4])|(a_i[5]&(a_i[3]^a_i[4]));
wire s2 = a_i[6]^a_i[7]^a_i[8];
wire c2 = (a_i[6]&a_i[7])|(a_i[8]&(a_i[6]^a_i[7]));
wire s3 = a_i[9]^a_i[10]^a_i[11];
wire c3 = (a_i[9]&a_i[10])|(a_i[11]&(a_i[9]^a_i[10]));
wire s4 = a_i[12]^a_i[13]^a_i[14];
wire c4 = (a_i[12]&a_i[13])|(a_i[14]&(a_i[12]^a_i[13]));
wire s5 = a_i[15]^a_i[16]^a_i[17];
wire c5 = (a_i[15]&a_i[16])|(a_i[17]&(a_i[15]^a_i[16]));
wire s6 = a_i[18]^a_i[19]^a_i[20];
wire c6 = (a_i[18]&a_i[19])|(a_i[20]&(a_i[18]^a_i[19]));
wire s7 = a_i[21]^a_i[22]^a_i[23];
wire c7 = (a_i[21]&a_i[22])|(a_i[23]&(a_i[21]^a_i[22]));
wire s8 = a_i[24]^a_i[25]^a_i[26];
wire c8 = (a_i[24]&a_i[25])|(a_i[26]&(a_i[24]^a_i[25]));
wire s9 = a_i[27]^a_i[28]^a_i[29];
wire c9 = (a_i[27]&a_i[28])|(a_i[29]&(a_i[27]^a_i[28]));

wire as0 = s0^s1^s2;
wire ac0 = (s0&s1)|(s2&(s0^s1));
wire as1 = s3^s4^s5;
wire ac1 = (s3&s4)|(s5&(s3^s4));
wire as2 = s6^s7^s8;
wire ac2 = (s6&s7)|(s8&(s6^s7));
wire as3 = s9^a_i[30]^a_i[31];
wire ac3 = (a_i[30]&a_i[31])|(s9&(a_i[30]^a_i[31]));

wire bs0 = c0^c1^c2;
wire bc0 = (c0&c1)|(c2&(c0^c1));
wire bs1 = c3^c4^c5;
wire bc1 = (c3&c4)|(c5&(c3^c4));
wire bs2 = c6^c7^c8;
wire bc2 = (c6&c7)|(c8&(c6^c7));

wire cs = as0^as1^as2;
wire cc = (as0&as1)|(as2&(as0^as1));

wire p0  = (c9^ac3)^bs0;
wire pc0 = (c9&ac3)|(bs0&(c9^ac3));
wire p1  = ac0^ac1^ac2;
wire pc1 = (ac0&ac1)|(ac2&(ac0^ac1));
wire p2  = bs1^bs2;
wire pc2 = bs1&bs2;

wire es = bc0^bc1^bc2;
wire ec = (bc0&bc1)|(bc2&(bc0^bc1));

wire y0 = cs^as3;
wire fc = cs&as3;
wire q0  = (p0^p2)^p1;
wire qc0 = (p0&p2)|(p1&(p0^p2));
wire r0  = (pc0^pc2)^es;
wire rc0 = (pc0&pc2)|(es&(pc0^pc2));

wire y1  = (cc^fc)^q0;
wire gc  = (cc&fc)|(q0&(cc^fc));
wire u0  = (pc1^r0)^qc0;
wire uc0 = (pc1&r0)|(qc0&(pc1^r0));
wire v0  = (ec^rc0)^uc0;
wire vc0 = (ec&rc0)|(uc0&(ec^rc0));

wire y2 = u0^gc;
wire w  = u0&gc;
wire y3 = v0^w;
wire cw = v0&w;
wire y4 = vc0^cw;
wire y5 = vc0&cw;

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