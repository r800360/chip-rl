module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
function [1:0] fa;
  input x, y, z;
  begin
    fa = {((x&y)|(x&z)|(y&z)), (x^y^z)};
  end
endfunction

// ---- lower half (bits 0..15) ----
wire [1:0] la = fa(a_i[0],a_i[1],a_i[2]);
wire [1:0] lb = fa(a_i[3],a_i[4],a_i[5]);
wire [1:0] lc = fa(a_i[6],a_i[7],a_i[8]);
wire [1:0] ld = fa(a_i[9],a_i[10],a_i[11]);
wire [1:0] le = fa(a_i[12],a_i[13],a_i[14]);
wire [1:0] lf = {1'b0, a_i[15]};
wire [2:0] lg0 = la + lb;
wire [2:0] lg1 = lc + ld;
wire [2:0] lg2 = le + lf;
wire [3:0] lh = lg0 + lg1;
wire [4:0] lo16 = lh + lg2;

// ---- upper half (bits 16..31) ----
wire [1:0] ua = fa(a_i[16],a_i[17],a_i[18]);
wire [1:0] ub = fa(a_i[19],a_i[20],a_i[21]);
wire [1:0] uc = fa(a_i[22],a_i[23],a_i[24]);
wire [1:0] ud = fa(a_i[25],a_i[26],a_i[27]);
wire [1:0] ue = fa(a_i[28],a_i[29],a_i[30]);
wire [1:0] uf = {1'b0, a_i[31]};
wire [2:0] ug0 = ua + ub;
wire [2:0] ug1 = uc + ud;
wire [2:0] ug2 = ue + uf;
wire [3:0] uh = ug0 + ug1;
wire [4:0] up16 = uh + ug2;

wire [5:0] tot = lo16 + up16;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= tot;
    end
end
endmodule