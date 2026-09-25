module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Population count using tree of adders
// Efficiently structured to minimize depth while keeping area reasonable
wire [5:0] total_0;

// Stage 1: Count bits in groups of 2
wire [1:0] s1[15:0];
assign s1[0] = a_i[0:0] + a_i[1:1];
assign s1[1] = a_i[2:2] + a_i[3:3];
assign s1[2] = a_i[4:4] + a_i[5:5];
assign s1[3] = a_i[6:6] + a_i[7:7];
assign s1[4] = a_i[8:8] + a_i[9:9];
assign s1[5] = a_i[10:10] + a_i[11:11];
assign s1[6] = a_i[12:12] + a_i[13:13];
assign s1[7] = a_i[14:14] + a_i[15:15];
assign s1[8] = a_i[16:16] + a_i[17:17];
assign s1[9] = a_i[18:18] + a_i[19:19];
assign s1[10] = a_i[20:20] + a_i[21:21];
assign s1[11] = a_i[22:22] + a_i[23:23];
assign s1[12] = a_i[24:24] + a_i[25:25];
assign s1[13] = a_i[26:26] + a_i[27:27];
assign s1[14] = a_i[28:28] + a_i[29:29];
assign s1[15] = a_i[30:30] + a_i[31:31];

// Stage 2: Sum groups of 2 into groups of 4
wire [2:0] s2[7:0];
assign s2[0] = s1[0] + s1[1];
assign s2[1] = s1[2] + s1[3];
assign s2[2] = s1[4] + s1[5];
assign s2[3] = s1[6] + s1[7];
assign s2[4] = s1[8] + s1[9];
assign s2[5] = s1[10] + s1[11];
assign s2[6] = s1[12] + s1[13];
assign s2[7] = s1[14] + s1[15];

// Stage 3: Sum groups of 4 into groups of 8
wire [3:0] s3[3:0];
assign s3[0] = s2[0] + s2[1];
assign s3[1] = s2[2] + s2[3];
assign s3[2] = s2[4] + s2[5];
assign s3[3] = s2[6] + s2[7];

// Stage 4: Sum groups of 8 into groups of 16
wire [4:0] s4[1:0];
assign s4[0] = s3[0] + s3[1];
assign s4[1] = s3[2] + s3[3];

// Final stage: Sum all 32 bits
assign total_0 = s4[0] + s4[1];

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
