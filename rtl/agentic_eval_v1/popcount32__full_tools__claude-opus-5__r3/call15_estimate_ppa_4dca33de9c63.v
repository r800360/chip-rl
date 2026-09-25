module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire s1_0 = a_i[0]^a_i[1]^a_i[2];
wire c1_0 = (a_i[0]&a_i[1])|(a_i[2]&(a_i[0]^a_i[1]));
wire s1_1 = a_i[3]^a_i[4]^a_i[5];
wire c1_1 = (a_i[3]&a_i[4])|(a_i[5]&(a_i[3]^a_i[4]));
wire s1_2 = a_i[6]^a_i[7]^a_i[8];
wire c1_2 = (a_i[6]&a_i[7])|(a_i[8]&(a_i[6]^a_i[7]));
wire s1_3 = a_i[9]^a_i[10]^a_i[11];
wire c1_3 = (a_i[9]&a_i[10])|(a_i[11]&(a_i[9]^a_i[10]));
wire s1_4 = a_i[12]^a_i[13]^a_i[14];
wire c1_4 = (a_i[12]&a_i[13])|(a_i[14]&(a_i[12]^a_i[13]));
wire s1_5 = a_i[15]^a_i[16]^a_i[17];
wire c1_5 = (a_i[15]&a_i[16])|(a_i[17]&(a_i[15]^a_i[16]));
wire s1_6 = a_i[18]^a_i[19]^a_i[20];
wire c1_6 = (a_i[18]&a_i[19])|(a_i[20]&(a_i[18]^a_i[19]));
wire s1_7 = a_i[21]^a_i[22]^a_i[23];
wire c1_7 = (a_i[21]&a_i[22])|(a_i[23]&(a_i[21]^a_i[22]));
wire s1_8 = a_i[24]^a_i[25]^a_i[26];
wire c1_8 = (a_i[24]&a_i[25])|(a_i[26]&(a_i[24]^a_i[25]));
wire s1_9 = a_i[27]^a_i[28]^a_i[29];
wire c1_9 = (a_i[27]&a_i[28])|(a_i[29]&(a_i[27]^a_i[28]));
wire hs   = a_i[30]^a_i[31];
wire hc   = a_i[30]&a_i[31];

wire as0 = s1_0^s1_1^s1_2;
wire ac0 = (s1_0&s1_1)|(s1_2&(s1_0^s1_1));
wire as1 = s1_3^s1_4^s1_5;
wire ac1 = (s1_3&s1_4)|(s1_5&(s1_3^s1_4));
wire as2 = s1_6^s1_7^s1_8;
wire ac2 = (s1_6&s1_7)|(s1_8&(s1_6^s1_7));
wire as3 = s1_9^hs;
wire ac3 = s1_9&hs;

wire bs0 = c1_0^c1_1^c1_2;
wire bc0 = (c1_0&c1_1)|(c1_2&(c1_0^c1_1));
wire bs1 = c1_3^c1_4^c1_5;
wire bc1 = (c1_3&c1_4)|(c1_5&(c1_3^c1_4));
wire bs2 = c1_6^c1_7^c1_8;
wire bc2 = (c1_6&c1_7)|(c1_8&(c1_6^c1_7));
wire bs3 = c1_9^hc;
wire bc3 = c1_9&hc;

wire cs = as0^as1^as2;
wire cc = (as0&as1)|(as2&(as0^as1));

wire ds0 = bs0^bs1^bs2;
wire dc0 = (bs0&bs1)|(bs2&(bs0^bs1));
wire ds1 = ac0^ac1^ac2;
wire dc1 = (ac0&ac1)|(ac2&(ac0^ac1));
wire ds2 = bs3^ac3;
wire dc2 = bs3&ac3;

wire es = bc0^bc1^bc2;
wire ec = (bc0&bc1)|(bc2&(bc0^bc1));

wire fs = cs^as3;
wire fc = cs&as3;

wire gs = ds0^ds1^ds2;
wire gc = (ds0&ds1)|(ds2&(ds0^ds1));

wire hs4 = es^bc3^dc0;
wire hc4 = (es&bc3)|(dc0&(es^bc3));
wire is4 = dc1^dc2;
wire ic4 = dc1&dc2;

wire js = gs^cc^fc;
wire jc = (gs&cc)|(fc&(gs^cc));
wire ks = hs4^is4^gc;
wire kc = (hs4&is4)|(gc&(hs4^is4));
wire ls = ec^hc4^ic4;
wire lc = (ec&hc4)|(ic4&(ec^hc4));

wire y0 = fs;
wire y1 = js;
wire y2 = ks^jc;
wire cy2 = ks&jc;
wire y3 = ls^kc^cy2;
wire cy3 = (ls&kc)|(cy2&(ls^kc));
wire y4 = lc^cy3;
wire y5 = lc&cy3;

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