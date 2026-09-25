module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

// Bitwise less-than/greater-than signals
wire [31:0] gt_bit = a_i & ~b_i;
wire [31:0] lt_bit = ~a_i & b_i;

// Balanced binary tree priority reduction (MSB has priority)
wire [15:0] lt1, eq1;
wire [7:0]  lt2, eq2;
wire [3:0]  lt3, eq3;
wire [1:0]  lt4, eq4;
wire lt5, eq5;

genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin: g1
        assign eq1[i] = ~(lt_bit[2*i+1] | gt_bit[2*i+1]) & ~(lt_bit[2*i] | gt_bit[2*i]);
        assign lt1[i] = lt_bit[2*i+1] | (~(lt_bit[2*i+1] | gt_bit[2*i+1]) & lt_bit[2*i]);
    end
    for (i = 0; i < 8; i = i + 1) begin: g2
        assign eq2[i] = eq1[2*i+1] & eq1[2*i];
        assign lt2[i] = lt1[2*i+1] | (eq1[2*i+1] & lt1[2*i]);
    end
    for (i = 0; i < 4; i = i + 1) begin: g3
        assign eq3[i] = eq2[2*i+1] & eq2[2*i];
        assign lt3[i] = lt2[2*i+1] | (eq2[2*i+1] & lt2[2*i]);
    end
    for (i = 0; i < 2; i = i + 1) begin: g4
        assign eq4[i] = eq3[2*i+1] & eq3[2*i];
        assign lt4[i] = lt3[2*i+1] | (eq3[2*i+1] & lt3[2*i]);
    end
endgenerate

assign eq5 = eq4[1] & eq4[0];
assign lt5 = lt4[1] | (eq4[1] & lt4[0]);

wire cmp_0 = lt5;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_0;
    end
end
endmodule
