module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
function MJ; input x, y, z; MJ = (x&y)|((x|y)&z); endfunction

wire [9:0] fs, fc;
genvar i;
generate for (i=0;i<10;i=i+1) begin : L1
  assign fs[i] = a_i[3*i] ^ a_i[3*i+1] ^ a_i[3*i+2];
  assign fc[i] = MJ(a_i[3*i], a_i[3*i+1], a_i[3*i+2]);
end endgenerate

wire As = (a_i[30]^a_i[31]) ^ fs[0];
wire Ac = MJ(a_i[30], a_i[31], fs[0]);
wire Bs = (fs[1]^fs[2]) ^ fs[3];
wire Bc = MJ(fs[1],fs[2],fs[3]);
wire Cs = (fs[4]^fs[5]) ^ fs[6];
wire Cc = MJ(fs[4],fs[5],fs[6]);
wire Ds = (fs[7]^fs[8]) ^ fs[9];
wire Dc = MJ(fs[7],fs[8],fs[9]);
wire Es = Cs ^ Ds;
wire Ec = Cs & Ds;
wire y0 = (As ^ Bs) ^ Es;
wire Gc = MJ(As, Bs, Es);

wire Ps = (fc[0]^fc[1]) ^ fc[2], Pc = MJ(fc[0],fc[1],fc[2]);
wire Qs = (fc[3]^fc[4]) ^ fc[5], Qc = MJ(fc[3],fc[4],fc[5]);
wire Rs = (fc[6]^fc[7]) ^ fc[8], Rc = MJ(fc[6],fc[7],fc[8]);
wire Ss = (fc[9]^Ac) ^ Ps,       Sc = MJ(fc[9],Ac,Ps);
wire Ts = (Qs^Rs) ^ Bc,          Tc = MJ(Qs,Rs,Bc);
wire Us = (Cc^Dc) ^ Ss,          Uc = MJ(Cc,Dc,Ss);
wire Vs = (Ec^Ts) ^ Us,          Vc = MJ(Ec,Ts,Us);
wire y1 = Gc ^ Vs;
wire Wc = Gc & Vs;

wire X1s = (Pc^Qc) ^ Rc,   X1c = MJ(Pc,Qc,Rc);
wire X2s = (Sc^Tc) ^ X1s,  X2c = MJ(X1s,Sc,Tc);
wire X3s = (Uc^Vc) ^ X2s,  X3c = MJ(Uc,X2s,Vc);
wire y2 = X3s ^ Wc;
wire Yc = X3s & Wc;

wire Z1s = (X1c^X2c) ^ X3c, Z1c = MJ(X1c,X2c,X3c);
wire y3 = Z1s ^ Yc;
wire Zc = Z1s & Yc;

wire y4 = Z1c ^ Zc;
wire y5 = Z1c & Zc;

wire [5:0] tot = {y5,y4,y3,y2,y1,y0};

always @(posedge clk) begin
  if (!rst_n) begin
    valid_o <= 1'b0;
    y_o <= 6'd0;
  end else begin
    valid_o <= valid_i;
    if (valid_i) y_o <= tot;
  end
end
endmodule