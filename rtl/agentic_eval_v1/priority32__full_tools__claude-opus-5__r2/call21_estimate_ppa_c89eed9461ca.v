module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [15:0] B;
wire [15:0] O;
assign B[0]=a_i[1]|a_i[0];   assign O[0]=a_i[1];
assign B[1]=a_i[3]|a_i[2];   assign O[1]=a_i[3];
assign B[2]=a_i[5]|a_i[4];   assign O[2]=a_i[5];
assign B[3]=a_i[7]|a_i[6];   assign O[3]=a_i[7];
assign B[4]=a_i[9]|a_i[8];   assign O[4]=a_i[9];
assign B[5]=a_i[11]|a_i[10]; assign O[5]=a_i[11];
assign B[6]=a_i[13]|a_i[12]; assign O[6]=a_i[13];
assign B[7]=a_i[15]|a_i[14]; assign O[7]=a_i[15];
assign B[8]=a_i[17]|a_i[16]; assign O[8]=a_i[17];
assign B[9]=a_i[19]|a_i[18]; assign O[9]=a_i[19];
assign B[10]=a_i[21]|a_i[20];assign O[10]=a_i[21];
assign B[11]=a_i[23]|a_i[22];assign O[11]=a_i[23];
assign B[12]=a_i[25]|a_i[24];assign O[12]=a_i[25];
assign B[13]=a_i[27]|a_i[26];assign O[13]=a_i[27];
assign B[14]=a_i[29]|a_i[28];assign O[14]=a_i[29];
assign B[15]=a_i[31]|a_i[30];assign O[15]=a_i[31];
wire [7:0] H4, X1, X0;
assign H4[0]=B[1]|B[0]; assign X1[0]=B[1]; assign X0[0]=O[1]|(O[0]&~B[1]);
assign H4[1]=B[3]|B[2]; assign X1[1]=B[3]; assign X0[1]=O[3]|(O[2]&~B[3]);
assign H4[2]=B[5]|B[4]; assign X1[2]=B[5]; assign X0[2]=O[5]|(O[4]&~B[5]);
assign H4[3]=B[7]|B[6]; assign X1[3]=B[7]; assign X0[3]=O[7]|(O[6]&~B[7]);
assign H4[4]=B[9]|B[8]; assign X1[4]=B[9]; assign X0[4]=O[9]|(O[8]&~B[9]);
assign H4[5]=B[11]|B[10]; assign X1[5]=B[11]; assign X0[5]=O[11]|(O[10]&~B[11]);
assign H4[6]=B[13]|B[12]; assign X1[6]=B[13]; assign X0[6]=O[13]|(O[12]&~B[13]);
assign H4[7]=B[15]|B[14]; assign X1[7]=B[15]; assign X0[7]=O[15]|(O[14]&~B[15]);
wire [3:0] H8, Z2, Z1, Z0;
assign H8[0]=H4[1]|H4[0]; assign Z2[0]=H4[1]; assign Z1[0]=X1[1]|(X1[0]&~H4[1]); assign Z0[0]=X0[1]|(X0[0]&~H4[1]);
assign H8[1]=H4[3]|H4[2]; assign Z2[1]=H4[3]; assign Z1[1]=X1[3]|(X1[2]&~H4[3]); assign Z0[1]=X0[3]|(X0[2]&~H4[3]);
assign H8[2]=H4[5]|H4[4]; assign Z2[2]=H4[5]; assign Z1[2]=X1[5]|(X1[4]&~H4[5]); assign Z0[2]=X0[5]|(X0[4]&~H4[5]);
assign H8[3]=H4[7]|H4[6]; assign Z2[3]=H4[7]; assign Z1[3]=X1[7]|(X1[6]&~H4[7]); assign Z0[3]=X0[7]|(X0[6]&~H4[7]);
wire [1:0] H16, W3, W2, W1, W0;
assign H16[0]=H8[1]|H8[0]; assign W3[0]=H8[1];
assign W2[0]=Z2[1]|(Z2[0]&~H8[1]); assign W1[0]=Z1[1]|(Z1[0]&~H8[1]); assign W0[0]=Z0[1]|(Z0[0]&~H8[1]);
assign H16[1]=H8[3]|H8[2]; assign W3[1]=H8[3];
assign W2[1]=Z2[3]|(Z2[2]&~H8[3]); assign W1[1]=Z1[3]|(Z1[2]&~H8[3]); assign W0[1]=Z0[3]|(Z0[2]&~H8[3]);
wire hit = H16[1]|H16[0];
wire y4 = H16[1];
wire y3 = W3[1]|(W3[0]&~H16[1]);
wire y2 = W2[1]|(W2[0]&~H16[1]);
wire y1 = W1[1]|(W1[0]&~H16[1]);
wire y0 = W0[1]|(W0[0]&~H16[1]);
wire [5:0] chosen = {hit, y4, y3, y2, y1, y0};
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen;
    end
end
endmodule