module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// More balanced tree structure
wire [4:0] s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6;

assign s1_0 = a_i[0] + a_i[1] + a_i[2] + a_i[3] + a_i[4];
assign s1_1 = a_i[5] + a_i[6] + a_i[7] + a_i[8] + a_i[9];
assign s1_2 = a_i[10] + a_i[11] + a_i[12] + a_i[13] + a_i[14];
assign s1_3 = a_i[15] + a_i[16] + a_i[17] + a_i[18] + a_i[19];
assign s1_4 = a_i[20] + a_i[21] + a_i[22] + a_i[23] + a_i[24];
assign s1_5 = a_i[25] + a_i[26] + a_i[27] + a_i[28] + a_i[29];
assign s1_6 = a_i[30] + a_i[31];

// Second level
wire [5:0] s2_0, s2_1, s2_2, s2_3;
assign s2_0 = {s1_0[4], s1_0} + {s1_1[4], s1_1};
assign s2_1 = {s1_2[4], s1_2} + {s1_3[4], s1_3};
assign s2_2 = {s1_4[4], s1_4} + {s1_5[4], s1_5};
assign s2_3 = {1'd0, s1_6, 4'd0};

// Third level
wire [6:0] s3_0, s3_1;
assign s3_0 = {s2_0[5], s2_0} + {s2_1[5], s2_1};
assign s3_1 = {s2_2[5], s2_2} + {s2_3[5], s2_3};

// Final level
wire [6:0] pc_0 = s3_0 + s3_1;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= pc_0[5:0];
    end
end
endmodule
