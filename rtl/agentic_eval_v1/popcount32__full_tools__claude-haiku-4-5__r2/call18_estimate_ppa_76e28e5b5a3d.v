module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Different grouping pattern to reduce critical path depth
wire [4:0] g0, g1, g2, g3, g4, g5, g6, g7;

assign g0 = a_i[0] + a_i[1] + a_i[2] + a_i[3] + a_i[4];
assign g1 = a_i[5] + a_i[6] + a_i[7];
assign g2 = a_i[8] + a_i[9] + a_i[10];
assign g3 = a_i[11] + a_i[12] + a_i[13];
assign g4 = a_i[14] + a_i[15] + a_i[16];
assign g5 = a_i[17] + a_i[18] + a_i[19];
assign g6 = a_i[20] + a_i[21] + a_i[22] + a_i[23] + a_i[24];
assign g7 = a_i[25] + a_i[26] + a_i[27] + a_i[28] + a_i[29];

wire [1:0] g8 = a_i[30] + a_i[31];

wire [5:0] p0 = {g0[4], g0} + {g1[4], g1};
wire [5:0] p1 = {g2[4], g2} + {g3[4], g3};
wire [5:0] p2 = {g4[4], g4} + {g5[4], g5};
wire [5:0] p3 = {g6[4], g6} + {g7[4], g7};

wire [6:0] q0 = {p0[5], p0} + {p1[5], p1};
wire [6:0] q1 = {p2[5], p2} + {p3[5], p3} + {5'b0, g8};

wire [6:0] pc_0_full = q0 + q1;

wire [5:0] pc_0 = pc_0_full[5:0];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= pc_0;
    end
end
endmodule
