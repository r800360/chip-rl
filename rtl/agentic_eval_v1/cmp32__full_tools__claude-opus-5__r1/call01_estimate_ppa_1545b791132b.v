module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    wire [7:0] lt, eq;
    genvar i;
    generate
      for (i=0;i<8;i=i+1) begin : ch
        assign lt[i] = a_i[4*i+3 -: 4] < b_i[4*i+3 -: 4];
        assign eq[i] = a_i[4*i+3 -: 4] == b_i[4*i+3 -: 4];
      end
    endgenerate

    wire [3:0] lt1, eq1;
    wire [1:0] lt2, eq2;
    wire       ltf;
    generate
      for (i=0;i<4;i=i+1) begin : l1
        assign lt1[i] = lt[2*i+1] | (eq[2*i+1] & lt[2*i]);
        assign eq1[i] = eq[2*i+1] & eq[2*i];
      end
      for (i=0;i<2;i=i+1) begin : l2
        assign lt2[i] = lt1[2*i+1] | (eq1[2*i+1] & lt1[2*i]);
        assign eq2[i] = eq1[2*i+1] & eq1[2*i];
      end
    endgenerate
    assign ltf = lt2[1] | (eq2[1] & lt2[0]);

    wire en = valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= valid_i & rst_n;
        y_o <= en ? ltf : (y_o & rst_n);
    end
endmodule
