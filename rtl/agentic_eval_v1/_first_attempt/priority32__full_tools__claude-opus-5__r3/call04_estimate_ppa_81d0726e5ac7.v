module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
    genvar i;
    // ---- bit 0 : mask uses only even-position bits above ----
    wire [31:0] evx, odx, Gx;
    wire [16:0] Se;
    wire [15:0] t0;
    generate
        for (i = 0; i < 16; i = i + 1) begin : SPL
            assign evx[i] = a_i[2*i];
            assign odx[i] = a_i[2*i+1];
        end
        for (i = 16; i < 32; i = i + 1) begin : SPZ
            assign evx[i] = 1'b0;
            assign odx[i] = 1'b0;
        end
        for (i = 0; i < 16; i = i + 1) begin : GG
            assign Gx[i] = evx[i] | evx[i+1] | evx[i+2] | evx[i+3];
        end
        for (i = 16; i < 32; i = i + 1) begin : GZ
            assign Gx[i] = 1'b0;
        end
        for (i = 0; i < 16; i = i + 1) begin : SE
            assign Se[i] = Gx[i] | Gx[i+4] | Gx[i+8] | Gx[i+12];
        end
        for (i = 0; i < 16; i = i + 1) begin : T0
            assign t0[i] = odx[i] & ~Se[i+1];
        end
    endgenerate
    assign Se[16] = 1'b0;
    wire idx0 = |t0;

    // ---- bit 1 ----
    wire [15:0] e1x, ohx, Hx;
    wire [8:0]  S1;
    wire [7:0]  t1;
    generate
        for (i = 0; i < 8; i = i + 1) begin : E1
            assign e1x[i] = a_i[4*i]   | a_i[4*i+1];
            assign ohx[i] = a_i[4*i+2] | a_i[4*i+3];
        end
        for (i = 8; i < 16; i = i + 1) begin : E1Z
            assign e1x[i] = 1'b0;
            assign ohx[i] = 1'b0;
        end
        for (i = 0; i < 8; i = i + 1) begin : HH
            assign Hx[i] = e1x[i] | e1x[i+1] | e1x[i+2] | e1x[i+3];
        end
        for (i = 8; i < 16; i = i + 1) begin : HZ
            assign Hx[i] = 1'b0;
        end
        for (i = 0; i < 8; i = i + 1) begin : S1G
            assign S1[i] = Hx[i] | Hx[i+4];
        end
        for (i = 0; i < 8; i = i + 1) begin : T1
            assign t1[i] = ohx[i] & ~S1[i+1];
        end
    endgenerate
    assign S1[8] = 1'b0;
    wire idx1 = |t1;

    // ---- bit 2 ----
    wire [3:0] c2, cH;
    wire [4:0] S2;
    wire [3:0] t2;
    generate
        for (i = 0; i < 4; i = i + 1) begin : C2
            assign c2[i] = a_i[8*i]   | a_i[8*i+1] | a_i[8*i+2] | a_i[8*i+3];
            assign cH[i] = a_i[8*i+4] | a_i[8*i+5] | a_i[8*i+6] | a_i[8*i+7];
        end
    endgenerate
    assign S2[4] = 1'b0;
    assign S2[3] = c2[3];
    assign S2[2] = c2[3] | c2[2];
    assign S2[1] = c2[3] | c2[2] | c2[1];
    assign S2[0] = 1'b0;
    generate
        for (i = 0; i < 4; i = i + 1) begin : T2
            assign t2[i] = cH[i] & ~S2[i+1];
        end
    endgenerate
    wire idx2 = |t2;

    // ---- bit 3, 4, hit ----
    wire d1h = |a_i[23:16];
    wire idx3 = (|a_i[31:24]) | ((|a_i[15:8]) & ~d1h);
    wire idx4 = |a_i[31:16];
    wire hit  = |a_i;

    wire [5:0] chosen = {hit, idx4, idx3, idx2, idx1, idx0};

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