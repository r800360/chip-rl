module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    wire [31:0] lt0 = ~a_i & b_i;
    wire [31:0] gt0 = a_i & ~b_i;
    wire [15:0] lt1, gt1;
    wire [7:0]  lt2, gt2;
    wire [3:0]  lt3, gt3;
    wire [1:0]  lt4, gt4;
    genvar i;
    generate
      for (i=0;i<16;i=i+1) begin : g1
        assign lt1[i] = lt0[2*i+1] | (~gt0[2*i+1] & lt0[2*i]);
        assign gt1[i] = gt0[2*i+1] | (~lt0[2*i+1] & gt0[2*i]);
      end
      for (i=0;i<8;i=i+1) begin : g2
        assign lt2[i] = lt1[2*i+1] | (~gt1[2*i+1] & lt1[2*i]);
        assign gt2[i] = gt1[2*i+1] | (~lt1[2*i+1] & gt1[2*i]);
      end
      for (i=0;i<4;i=i+1) begin : g3
        assign lt3[i] = lt2[2*i+1] | (~gt2[2*i+1] & lt2[2*i]);
        assign gt3[i] = gt2[2*i+1] | (~lt2[2*i+1] & gt2[2*i]);
      end
      for (i=0;i<2;i=i+1) begin : g4
        assign lt4[i] = lt3[2*i+1] | (~gt3[2*i+1] & lt3[2*i]);
        assign gt4[i] = gt3[2*i+1] | (~lt3[2*i+1] & gt3[2*i]);
      end
    endgenerate
    wire l5 = lt4[1] | (~gt4[1] & lt4[0]);
    wire sel  = valid_i & rst_n;
    wire hold = y_o & rst_n;
    always @(posedge clk) begin
        valid_o <= sel;
        y_o     <= sel ? l5 : hold;
    end
endmodule