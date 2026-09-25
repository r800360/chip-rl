module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

    // Kogge-Stone parallel prefix adder
    wire [31:0] gg [0:5];
    wire [31:0] pp [0:5];

    assign gg[0] = a_i & b_i;
    assign pp[0] = a_i ^ b_i;

    genvar k, i;
    generate
        for (k = 0; k < 5; k = k + 1) begin : lvl
            for (i = 0; i < 32; i = i + 1) begin : bitpos
                if (i >= (1 << k)) begin : upd
                    assign gg[k+1][i] = gg[k][i] | (pp[k][i] & gg[k][i-(1<<k)]);
                    assign pp[k+1][i] = pp[k][i] & pp[k][i-(1<<k)];
                end else begin : cpy
                    assign gg[k+1][i] = gg[k][i];
                    assign pp[k+1][i] = pp[k][i];
                end
            end
        end
    endgenerate

    wire [31:0] sum;
    assign sum[0] = pp[0][0];
    generate
        for (i = 1; i < 32; i = i + 1) begin : sumb
            assign sum[i] = pp[0][i] ^ gg[5][i-1];
        end
    endgenerate

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
