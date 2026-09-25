module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

function [2:0] pc4;
    input [3:0] v;
    begin
        case (v)
            4'h0: pc4 = 3'd0;
            4'h1, 4'h2, 4'h4, 4'h8: pc4 = 3'd1;
            4'h3, 4'h5, 4'h6, 4'h9, 4'hA, 4'hC: pc4 = 3'd2;
            4'h7, 4'hB, 4'hD, 4'hE: pc4 = 3'd3;
            4'hF: pc4 = 3'd4;
            default: pc4 = 3'd0;
        endcase
    end
endfunction

wire [2:0] n0 = pc4(a_i[3:0]);
wire [2:0] n1 = pc4(a_i[7:4]);
wire [2:0] n2 = pc4(a_i[11:8]);
wire [2:0] n3 = pc4(a_i[15:12]);
wire [2:0] n4 = pc4(a_i[19:16]);
wire [2:0] n5 = pc4(a_i[23:20]);
wire [2:0] n6 = pc4(a_i[27:24]);
wire [2:0] n7 = pc4(a_i[31:28]);

wire [3:0] m0 = n0 + n1;
wire [3:0] m1 = n2 + n3;
wire [3:0] m2 = n4 + n5;
wire [3:0] m3 = n6 + n7;

wire [4:0] k0 = m0 + m1;
wire [4:0] k1 = m2 + m3;

wire [5:0] total_0 = k0 + k1;

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
