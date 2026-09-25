module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Optimized tree structure for popcount
// Bits 0-3
wire [2:0] group0 = {a_i[0] + a_i[1]} + {a_i[2] + a_i[3]};
// Bits 4-7
wire [2:0] group1 = {a_i[4] + a_i[5]} + {a_i[6] + a_i[7]};
// Bits 8-11
wire [2:0] group2 = {a_i[8] + a_i[9]} + {a_i[10] + a_i[11]};
// Bits 12-15
wire [2:0] group3 = {a_i[12] + a_i[13]} + {a_i[14] + a_i[15]};
// Bits 16-19
wire [2:0] group4 = {a_i[16] + a_i[17]} + {a_i[18] + a_i[19]};
// Bits 20-23
wire [2:0] group5 = {a_i[20] + a_i[21]} + {a_i[22] + a_i[23]};
// Bits 24-27
wire [2:0] group6 = {a_i[24] + a_i[25]} + {a_i[26] + a_i[27]};
// Bits 28-31
wire [2:0] group7 = {a_i[28] + a_i[29]} + {a_i[30] + a_i[31]};

// Second level
wire [3:0] half0 = group0 + group1;
wire [3:0] half1 = group2 + group3;
wire [3:0] half2 = group4 + group5;
wire [3:0] half3 = group6 + group7;

// Third level
wire [4:0] quarter0 = half0 + half1;
wire [4:0] quarter1 = half2 + half3;

// Final
wire [5:0] total_0 = quarter0 + quarter1;

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
