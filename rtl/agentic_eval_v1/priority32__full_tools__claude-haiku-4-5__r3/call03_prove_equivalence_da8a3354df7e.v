module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Logarithmic priority encoder using tree structure
wire [4:0] idx;
wire hit;

// Stage 1: Find priority in upper vs lower 16 bits
wire hit_h = |a_i[31:16];
wire hit_l = |a_i[15:0];
wire [15:0] data_s1 = hit_h ? a_i[31:16] : a_i[15:0];
wire bit4 = hit_h;

// Stage 2: Find priority in upper vs lower 8 bits of selected 16
wire hit_hh = |data_s1[15:8];
wire [7:0] data_s2 = hit_hh ? data_s1[15:8] : data_s1[7:0];
wire bit3 = hit_hh;

// Stage 3: Find priority in upper vs lower 4 bits of selected 8
wire hit_hhh = |data_s2[7:4];
wire [3:0] data_s3 = hit_hhh ? data_s2[7:4] : data_s2[3:0];
wire bit2 = hit_hhh;

// Stage 4: Find priority in upper vs lower 2 bits of selected 4
wire hit_h4 = |data_s3[3:2];
wire [1:0] data_s4 = hit_h4 ? data_s3[3:2] : data_s3[1:0];
wire bit1 = hit_h4;

// Stage 5: Find the single bit
wire bit0 = data_s4[1];

// Assemble index
assign idx = {bit4, bit3, bit2, bit1, bit0};
assign hit = |a_i[31:0];

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
