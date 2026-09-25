module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
    // low 16 Kogge-Stone
    wire [15:0] al = a_i[15:0],  bl = b_i[15:0];
    wire [15:0] ah = a_i[31:16], bh = b_i[31:16];
    wire [15:0] pl = al ^ bl, gl = al & bl;
    wire [15:0] ph = ah ^ bh, gh = ah & bh;

    wire [15:0] GL1 = gl | (pl & {gl[14:0],1'b0});
    wire [15:0] PL1 = pl & {pl[14:0],1'b0};
    wire [15:0] GL2 = GL1 | (PL1 & {GL1[13:0],2'b0});
    wire [15:0] PL2 = PL1 & {PL1[13:0],2'b0};
    wire [15:0] GL3 = GL2 | (PL2 & {GL2[11:0],4'b0});
    wire [15:0] PL3 = PL2 & {PL2[11:0],4'b0};
    wire [15:0] GL4 = GL3 | (PL3 & {GL3[7:0],8'b0});

    wire        c   = GL4[15];
    wire [15:0] sum_lo = pl ^ {GL4[14:0],1'b0};

    wire [15:0] GH1 = gh | (ph & {gh[14:0],1'b0});
    wire [15:0] PH1 = ph & {ph[14:0],1'b1};
    wire [15:0] GH2 = GH1 | (PH1 & {GH1[13:0],2'b0});
    wire [15:0] PH2 = PH1 & {PH1[13:0],2'b11};
    wire [15:0] GH3 = GH2 | (PH2 & {GH2[11:0],4'b0});
    wire [15:0] PH3 = PH2 & {PH2[11:0],4'hf};
    wire [15:0] GH4 = GH3 | (PH3 & {GH3[7:0],8'b0});
    wire [15:0] PH4 = PH3 & {PH3[7:0],8'hff};

    wire [15:0] sum_h0 = ph ^ {GH4[14:0],1'b0};
    wire [15:0] sum_h1 = ph ^ {(GH4[14:0] | PH4[14:0]),1'b1};
    wire [15:0] sum_hi = c ? sum_h1 : sum_h0;

    wire [31:0] sum = {sum_hi, sum_lo};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= sum;
    end
end
endmodule