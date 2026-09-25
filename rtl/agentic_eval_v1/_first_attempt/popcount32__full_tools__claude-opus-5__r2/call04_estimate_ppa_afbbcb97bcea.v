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

wire [1:0] t0 = fa(a_i[0],a_i[1],a_i[2]);
wire [1:0] t1 = fa(a_i[3],a_i[4],a_i[5]);
wire [1:0] t2 = fa(a_i[6],a_i[7],a_i[8]);
wire [1:0] t3 = fa(a_i[9],a_i[10],a_i[11]);
wire [1:0] t4 = fa(a_i[12],a_i[13],a_i[14]);
wire [1:0] t5 = fa(a_i[15],a_i[16],a_i[17]);
wire [1:0] t6 = fa(a_i[18],a_i[19],a_i[20]);
wire [1:0] t7 = fa(a_i[21],a_i[22],a_i[23]);
wire [1:0] t8 = fa(a_i[24],a_i[25],a_i[26]);
wire [1:0] t9 = fa(a_i[27],a_i[28],a_i[29]);
wire [1:0] t10 = {1'b0, a_i[30]};
wire [1:0] t11 = {1'b0, a_i[31]};

wire [3:0] s0 = t0 + t1 + t2 + t3;
wire [3:0] s1 = t4 + t5 + t6 + t7;
wire [3:0] s2 = t8 + t9 + t10 + t11;
wire [5:0] tot = s0 + s1 + s2;

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