module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
function [1:0] fa3; input x; input y; input z;
    fa3 = {(x & y) | (x & z) | (y & z), x ^ y ^ z};
endfunction
function [1:0] ha2; input x; input y;
    ha2 = {x & y, x ^ y};
endfunction
function [3:0] pc8; input [7:0] v;
    reg [1:0] x, y, z, u, w, s, f;
    begin
        x = fa3(v[0], v[1], v[2]);
        y = fa3(v[3], v[4], v[5]);
        z = ha2(v[6], v[7]);
        u = fa3(x[0], y[0], z[0]);
        s = fa3(x[1], y[1], z[1]);
        w = ha2(s[0], u[1]);
        f = ha2(s[1], w[1]);
        pc8 = {f[1], f[0], w[0], u[0]};
    end
endfunction
wire [3:0] q0 = pc8(a_i[7:0]);
wire [3:0] q1 = pc8(a_i[15:8]);
wire [3:0] q2 = pc8(a_i[23:16]);
wire [3:0] q3 = pc8(a_i[31:24]);
reg [15:0] pr;
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        pr <= 16'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            pr <= {q3, q2, q1, q0};
    end
end
always @* y_o = pr[5:0];
endmodule