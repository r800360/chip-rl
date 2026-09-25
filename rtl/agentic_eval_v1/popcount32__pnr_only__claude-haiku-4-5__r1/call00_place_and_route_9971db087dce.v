module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Hierarchical population count using balanced tree
// Count pairs of bits
wire [1:0] p0  = a_i[0] + a_i[1];
wire [1:0] p1  = a_i[2] + a_i[3];
wire [1:0] p2  = a_i[4] + a_i[5];
wire [1:0] p3  = a_i[6] + a_i[7];
wire [1:0] p4  = a_i[8] + a_i[9];
wire [1:0] p5  = a_i[10] + a_i[11];
wire [1:0] p6  = a_i[12] + a_i[13];
wire [1:0] p7  = a_i[14] + a_i[15];
wire [1:0] p8  = a_i[16] + a_i[17];
wire [1:0] p9  = a_i[18] + a_i[19];
wire [1:0] p10 = a_i[20] + a_i[21];
wire [1:0] p11 = a_i[22] + a_i[23];
wire [1:0] p12 = a_i[24] + a_i[25];
wire [1:0] p13 = a_i[26] + a_i[27];
wire [1:0] p14 = a_i[28] + a_i[29];
wire [1:0] p15 = a_i[30] + a_i[31];

// Count quads (sum of 2-bit pairs)
wire [2:0] q0 = {1'b0, p0} + {1'b0, p1};
wire [2:0] q1 = {1'b0, p2} + {1'b0, p3};
wire [2:0] q2 = {1'b0, p4} + {1'b0, p5};
wire [2:0] q3 = {1'b0, p6} + {1'b0, p7};
wire [2:0] q4 = {1'b0, p8} + {1'b0, p9};
wire [2:0] q5 = {1'b0, p10} + {1'b0, p11};
wire [2:0] q6 = {1'b0, p12} + {1'b0, p13};
wire [2:0] q7 = {1'b0, p14} + {1'b0, p15};

// Count octets (sum of 3-bit quads)
wire [3:0] o0 = {1'b0, q0} + {1'b0, q1};
wire [3:0] o1 = {1'b0, q2} + {1'b0, q3};
wire [3:0] o2 = {1'b0, q4} + {1'b0, q5};
wire [3:0] o3 = {1'b0, q6} + {1'b0, q7};

// Count hextuples (sum of 4-bit octets)
wire [4:0] h0 = {1'b0, o0} + {1'b0, o1};
wire [4:0] h1 = {1'b0, o2} + {1'b0, o3};

// Final sum (5-bit + 5-bit = 6-bit)
wire [5:0] total_0 = {1'b0, h0} + {1'b0, h1};

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
