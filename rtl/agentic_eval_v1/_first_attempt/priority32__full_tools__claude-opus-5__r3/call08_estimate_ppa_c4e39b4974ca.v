module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
    wire [31:0] o2x, Ax;
    wire [16:0] np;
    wire [7:0]  c;
    wire [15:0] t0;
    wire [4:0]  idx;
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : L0
            assign o2x[i] = a_i[2*i] | a_i[2*i+1];
        end
        for (i = 16; i < 32; i = i + 1) begin : L0z
            assign o2x[i] = 1'b0;
        end
        for (i = 0; i < 8; i = i + 1) begin : LC
            assign c[i] = o2x[2*i] | o2x[2*i+1];
        end
        for (i = 0; i < 16; i = i + 1) begin : LA
            assign Ax[i] = o2x[i] | o2x[i+1] | o2x[i+2] | o2x[i+3];
        end
        for (i = 16; i < 32; i = i + 1) begin : LAz
            assign Ax[i] = 1'b0;
        end
        for (i = 0; i < 16; i = i + 1) begin : LP
            assign np[i] = ~(Ax[i] | Ax[i+4] | Ax[i+8] | Ax[i+12]);
        end
        for (i = 0; i < 16; i = i + 1) begin : LT
            assign t0[i] = a_i[2*i+1] & np[i+1];
        end
    endgenerate
    assign np[16] = 1'b1;

    assign idx[4] = ~np[8];
    assign idx[3] = ~np[12] | (Ax[4] & np[8]);
    assign idx[2] = c[7] | (c[5] & np[12]) | (c[3] & np[8]) | (c[1] & np[4]);
    assign idx[1] = o2x[15] | (o2x[13] & np[14]) | (o2x[11] & np[12]) | (o2x[9] & np[10])
                  | (o2x[7] & np[8]) | (o2x[5] & np[6]) | (o2x[3] & np[4]) | (o2x[1] & np[2]);
    assign idx[0] = |t0;

    wire [5:0] chosen = {~np[0], idx};

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