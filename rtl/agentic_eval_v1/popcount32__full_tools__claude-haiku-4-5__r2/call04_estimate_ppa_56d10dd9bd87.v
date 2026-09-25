module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Tree-based popcount structure for better synthesis
wire [4:0] s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7;

assign s1_0 = {4'd0, a_i[0]} + {4'd0, a_i[1]} + {4'd0, a_i[2]} + {4'd0, a_i[3]};
assign s1_1 = {4'd0, a_i[4]} + {4'd0, a_i[5]} + {4'd0, a_i[6]} + {4'd0, a_i[7]};
assign s1_2 = {4'd0, a_i[8]} + {4'd0, a_i[9]} + {4'd0, a_i[10]} + {4'd0, a_i[11]};
assign s1_3 = {4'd0, a_i[12]} + {4'd0, a_i[13]} + {4'd0, a_i[14]} + {4'd0, a_i[15]};
assign s1_4 = {4'd0, a_i[16]} + {4'd0, a_i[17]} + {4'd0, a_i[18]} + {4'd0, a_i[19]};
assign s1_5 = {4'd0, a_i[20]} + {4'd0, a_i[21]} + {4'd0, a_i[22]} + {4'd0, a_i[23]};
assign s1_6 = {4'd0, a_i[24]} + {4'd0, a_i[25]} + {4'd0, a_i[26]} + {4'd0, a_i[27]};
assign s1_7 = {4'd0, a_i[28]} + {4'd0, a_i[29]} + {4'd0, a_i[30]} + {4'd0, a_i[31]};

// Second level
wire [5:0] s2_0, s2_1, s2_2, s2_3;
assign s2_0 = {s1_0[4], s1_0} + {s1_1[4], s1_1};
assign s2_1 = {s1_2[4], s1_2} + {s1_3[4], s1_3};
assign s2_2 = {s1_4[4], s1_4} + {s1_5[4], s1_5};
assign s2_3 = {s1_6[4], s1_6} + {s1_7[4], s1_7};

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
