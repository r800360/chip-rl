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
function [2:0] pc4; input [3:0] v;
    reg [1:0] x, w, f;
    begin
        x = fa3(v[0], v[1], v[2]);
        w = ha2(x[0], v[3]);
        f = ha2(x[1], w[1]);
        pc4 = {f[1], f[0], w[0]};
    end
endfunction

wire [2:0] q0 = pc4(a_i[3:0]);
wire [2:0] q1 = pc4(a_i[7:4]);
wire [2:0] q2 = pc4(a_i[11:8]);
wire [2:0] q3 = pc4(a_i[15:12]);
wire [2:0] q4 = pc4(a_i[19:16]);
wire [2:0] q5 = pc4(a_i[23:20]);
wire [2:0] q6 = pc4(a_i[27:24]);
wire [2:0] q7 = pc4(a_i[31:28]);

reg [23:0] pr;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        pr <= 24'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            pr <= {q7, q6, q5, q4, q3, q2, q1, q0};
    end
end

always @* begin
    y_o = (({3'b0, pr[2:0]} + {3'b0, pr[5:3]}) + ({3'b0, pr[8:6]} + {3'b0, pr[11:9]}))
        + (({3'b0, pr[14:12]} + {3'b0, pr[17:15]}) + ({3'b0, pr[20:18]} + {3'b0, pr[23:21]}));
    end
endmodule