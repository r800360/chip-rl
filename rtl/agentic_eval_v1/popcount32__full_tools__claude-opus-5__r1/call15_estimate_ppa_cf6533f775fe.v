module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [9:0] x0 = {a_i[27],a_i[24],a_i[21],a_i[18],a_i[15],a_i[12],a_i[9],a_i[6],a_i[3],a_i[0]};
wire [9:0] x1 = {a_i[28],a_i[25],a_i[22],a_i[19],a_i[16],a_i[13],a_i[10],a_i[7],a_i[4],a_i[1]};
wire [9:0] x2 = {a_i[29],a_i[26],a_i[23],a_i[20],a_i[17],a_i[14],a_i[11],a_i[8],a_i[5],a_i[2]};
wire [9:0] xh = x0 ^ x1;
wire [9:0] s1 = xh ^ x2;
wire [9:0] c1 = (x0 & x1) | (xh & x2);
wire [9:0] fl = s1 & c1;

wire ph = a_i[30]^a_i[31];
wire P_s = ph^s1[0];
wire P_c = (a_i[30]&a_i[31])|(ph&s1[0]);
wire qh = s1[1]^s1[2];
wire Q_s = qh^s1[3];
wire Q_c = (s1[1]&s1[2])|(qh&s1[3]);
wire rh = s1[4]^s1[5];
wire R_s = rh^s1[6];
wire R_c = (s1[4]&s1[5])|(rh&s1[6]);
wire th = s1[7]^s1[8];
wire T_s = th^s1[9];
wire T_c = (s1[7]&s1[8])|(th&s1[9]);
wire U_s = P_s^Q_s;
wire U_c = P_s&Q_s;
wire V_s = R_s^T_s;
wire V_c = R_s&T_s;
wire y0 = U_s^V_s;
wire W_c = U_s&V_s;

wire ah = c1[0]^c1[1];
wire A_s = ah^c1[2];
wire A_c = (c1[0]&c1[1])|(ah&c1[2]);
wire bh = c1[3]^c1[4];
wire B_s = bh^c1[5];
wire B_c = (c1[3]&c1[4])|(bh&c1[5]);
wire chh = c1[6]^c1[7];
wire C_s = chh^c1[8];
wire C_c = (c1[6]&c1[7])|(chh&c1[8]);
wire dh = c1[9]^P_c;
wire D_s = dh^Q_c;
wire D_c = (c1[9]&P_c)|(dh&Q_c);
wire eh = A_s^B_s;
wire E_s = eh^C_s;
wire E_c = (A_s&B_s)|(eh&C_s);
wire fh = R_c^T_c;
wire F_s = fh^U_c;
wire F_c = (R_c&T_c)|(fh&U_c);
wire gh = D_s^V_c;
wire G_s = gh^E_s;
wire G_c = (D_s&V_c)|(gh&E_s);
wire H_s = F_s^W_c;
wire H_c = F_s&W_c;

wire ih = A_c^B_c;
wire I_s = ih^C_c;
wire I_c = (A_c&B_c)|(ih&C_c);
wire jh = D_c^E_c;
wire J_s = jh^F_c;
wire J_c = (D_c&E_c)|(jh&F_c);
wire L_s = G_c^H_c;
wire L_c = G_c&H_c;
wire M_s = I_s^J_s;
wire M_c = I_s&J_s;

wire nh = I_c^J_c;
wire N_s = nh^L_c;
wire N_c = (I_c&J_c)|(nh&L_c);

// explicit carry-lookahead tail
wire t1 = G_s ^ H_s;
wire gg1 = G_s & H_s;
wire t2 = L_s ^ M_s;
wire gg2 = L_s & M_s;
wire t3 = N_s ^ M_c;
wire gg3 = N_s & M_c;
wire y1 = t1;
wire y2 = t2 ^ gg1;
wire c2 = gg2 | (t2 & gg1);
wire y3 = t3 ^ c2;
wire c3 = gg3 | (t3 & gg2) | (t3 & t2 & gg1);
wire y4 = N_c ^ c3;
wire all1 = (&fl) & a_i[30] & a_i[31];

wire [5:0] total_0 = {all1, y4, y3, y2, y1, y0};

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