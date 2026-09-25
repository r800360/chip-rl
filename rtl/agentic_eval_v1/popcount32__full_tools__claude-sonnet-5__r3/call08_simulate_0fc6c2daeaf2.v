module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

reg [2:0] n0, n1, n2, n3, n4, n5, n6, n7;

always @* begin
    case (a_i[3:0])
        4'h0: n0 = 3'd0;
        4'h1, 4'h2, 4'h4, 4'h8: n0 = 3'd1;
        4'h3, 4'h5, 4'h6, 4'h9, 4'hA, 4'hC: n0 = 3'd2;
        4'h7, 4'hB, 4'hD, 4'hE: n0 = 3'd3;
        default: n0 = 3'd4;
    endcase
    case (a_i[7:4])
        4'h0: n1 = 3'd0;
        4'h1, 4'h2, 4'h4, 4'h8: n1 = 3'd1;
        4'h3, 4'h5, 4'h6, 4'h9, 4'hA, 4'hC: n1 = 3'd2;
        4'h7, 4'hB, 4'hD, 4'hE: n1 = 3'd3;
        default: n1 = 3'd4;
    endcase
    case (a_i[11:8])
        4'h0: n2 = 3'd0;
        4'h1, 4'h2, 4'h4, 4'h8: n2 = 3'd1;
        4'h3, 4'h5, 4'h6, 4'h9, 4'hA, 4'hC: n2 = 3'd2;
        4'h7, 4'hB, 4'hD, 4'hE: n2 = 3'd3;
        default: n2 = 3'd4;
    endcase
    case (a_i[15:12])
        4'h0: n3 = 3'd0;
        4'h1, 4'h2, 4'h4, 4'h8: n3 = 3'd1;
        4'h3, 4'h5, 4'h6, 4'h9, 4'hA, 4'hC: n3 = 3'd2;
        4'h7, 4'hB, 4'hD, 4'hE: n3 = 3'd3;
        default: n3 = 3'd4;
    endcase
    case (a_i[19:16])
        4'h0: n4 = 3'd0;
        4'h1, 4'h2, 4'h4, 4'h8: n4 = 3'd1;
        4'h3, 4'h5, 4'h6, 4'h9, 4'hA, 4'hC: n4 = 3'd2;
        4'h7, 4'hB, 4'hD, 4'hE: n4 = 3'd3;
        default: n4 = 3'd4;
    endcase
    case (a_i[23:20])
        4'h0: n5 = 3'd0;
        4'h1, 4'h2, 4'h4, 4'h8: n5 = 3'd1;
        4'h3, 4'h5, 4'h6, 4'h9, 4'hA, 4'hC: n5 = 3'd2;
        4'h7, 4'hB, 4'hD, 4'hE: n5 = 3'd3;
        default: n5 = 3'd4;
    endcase
    case (a_i[27:24])
        4'h0: n6 = 3'd0;
        4'h1, 4'h2, 4'h4, 4'h8: n6 = 3'd1;
        4'h3, 4'h5, 4'h6, 4'h9, 4'hA, 4'hC: n6 = 3'd2;
        4'h7, 4'hB, 4'hD, 4'hE: n6 = 3'd3;
        default: n6 = 3'd4;
    endcase
    case (a_i[31:28])
        4'h0: n7 = 3'd0;
        4'h1, 4'h2, 4'h4, 4'h8: n7 = 3'd1;
        4'h3, 4'h5, 4'h6, 4'h9, 4'hA, 4'hC: n7 = 3'd2;
        4'h7, 4'hB, 4'hD, 4'hE: n7 = 3'd3;
        default: n7 = 3'd4;
    endcase
end

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
