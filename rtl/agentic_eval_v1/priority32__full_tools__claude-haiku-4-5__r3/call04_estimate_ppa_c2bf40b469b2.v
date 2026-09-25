module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Alternative encoding: use priority at each level more efficiently
wire [4:0] idx;

// Top level: pick upper or lower half
wire upper = |a_i[31:16];
wire [15:0] a_half = upper ? a_i[31:16] : a_i[15:0];

// Second level: pick which quarter
wire upper_q = |a_half[15:12] | |a_half[11:8];
wire [7:0] a_quart = upper_q ? a_half[15:8] : a_half[7:0];

// Third level: pick which octet
wire upper_o = |a_quart[7:6] | |a_quart[5:4];
wire [3:0] a_oct = upper_o ? a_quart[7:4] : a_quart[3:0];

// Fourth level: find exact position
wire b3 = |a_oct[3:2];
wire [1:0] a_final = b3 ? a_oct[3:2] : a_oct[1:0];

// Fifth level: distinguish final bit
wire b0 = a_final[1];

// Index assembly: reconstruct from decisions
assign idx = {upper, upper_q, upper_o, b3, b0};

wire hit = |a_i[31:0];
wire [5:0] chosen_0 = hit ? {1'b1, idx} : 6'd0;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen_0;
    end
end
endmodule
