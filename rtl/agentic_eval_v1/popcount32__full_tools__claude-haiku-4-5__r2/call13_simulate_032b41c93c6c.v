module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Optimized tree structure using smaller intermediates where possible
wire [4:0] s0, s1, s2, s3, s4, s5;
wire [1:0] s6;

assign s0 = a_i[0] + a_i[1] + a_i[2] + a_i[3] + a_i[4];
assign s1 = a_i[5] + a_i[6] + a_i[7] + a_i[8] + a_i[9];
assign s2 = a_i[10] + a_i[11] + a_i[12] + a_i[13] + a_i[14];
assign s3 = a_i[15] + a_i[16] + a_i[17] + a_i[18] + a_i[19];
assign s4 = a_i[20] + a_i[21] + a_i[22] + a_i[23] + a_i[24];
assign s5 = a_i[25] + a_i[26] + a_i[27] + a_i[28] + a_i[29];
assign s6 = a_i[30] + a_i[31];

// Two parallel adder trees
wire [5:0] sum_left = ({1'b0, s0} + {1'b0, s1}) + ({1'b0, s2} + {1'b0, s3});
wire [5:0] sum_right = ({1'b0, s4} + {1'b0, s5}) + {4'b0, s6};

// Final result
wire [6:0] pc_0_full = {sum_left[5], sum_left} + {sum_right[5], sum_right};

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
