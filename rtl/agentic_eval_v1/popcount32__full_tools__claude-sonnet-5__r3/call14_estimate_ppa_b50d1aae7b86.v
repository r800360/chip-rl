module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

function [3:0] pc8;
    input [7:0] v;
    integer i;
    begin
        pc8 = v[0]+v[1]+v[2]+v[3]+v[4]+v[5]+v[6]+v[7];
    end
endfunction

wire [3:0] b0 = pc8(a_i[7:0]);
wire [3:0] b1 = pc8(a_i[15:8]);
wire [3:0] b2 = pc8(a_i[23:16]);
wire [3:0] b3 = pc8(a_i[31:24]);

wire [4:0] j0 = b0 + b1;
wire [4:0] j1 = b2 + b3;

wire [5:0] total_0 = j0 + j1;

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
