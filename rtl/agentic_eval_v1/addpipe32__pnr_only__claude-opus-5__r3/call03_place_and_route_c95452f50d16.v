module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

    // Ling-adder carry network.
    // g[i] = a&b , t[i-1] = a[i-1]|b[i-1] , p[i] = a^b
    // H[i] = g[i] | t[i-1]*H[i-1]        (pseudo carry)
    // c[i-1] = t[i-1] & H[i-1]
    // sum[i] = H[i-1] ? (p[i]^t[i-1]) : p[i]
    wire [31:0] pxo, gen, tor;
    wire [31:0] h1, t1, h2, t2, h3, t3, h4, t4, h5;
    wire [31:0] sum;

    assign pxo = a_i ^ b_i;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gp
            assign gen[i] = a_i[i] & b_i[i];
            if (i == 0) begin : t_lsb
                assign tor[i] = 1'b0;
            end else begin : t_gen
                assign tor[i] = a_i[i-1] | b_i[i-1];
            end
        end

        // prefix level 1 (span 1): collapses to one complex gate from inputs
        for (i = 0; i < 32; i = i + 1) begin : l1
            if (i >= 1) begin : d
                assign h1[i] = gen[i] | gen[i-1];
                assign t1[i] = tor[i] & tor[i-1];
            end else begin : nd
                assign h1[i] = gen[i];
                assign t1[i] = tor[i];
            end
        end

        // prefix level 2 (span 2)
        for (i = 0; i < 32; i = i + 1) begin : l2
            if (i >= 2) begin : d
                assign h2[i] = h1[i] | (t1[i] & h1[i-2]);
                assign t2[i] = t1[i] & t1[i-2];
            end else begin : nd
                assign h2[i] = h1[i];
                assign t2[i] = t1[i];
            end
        end

        // prefix level 3 (span 4)
        for (i = 0; i < 32; i = i + 1) begin : l3
            if (i >= 4) begin : d
                assign h3[i] = h2[i] | (t2[i] & h2[i-4]);
                assign t3[i] = t2[i] & t2[i-4];
            end else begin : nd
                assign h3[i] = h2[i];
                assign t3[i] = t2[i];
            end
        end

        // prefix level 4 (span 8)
        for (i = 0; i < 32; i = i + 1) begin : l4
            if (i >= 8) begin : d
                assign h4[i] = h3[i] | (t3[i] & h3[i-8]);
                assign t4[i] = t3[i] & t3[i-8];
            end else begin : nd
                assign h4[i] = h3[i];
                assign t4[i] = t3[i];
            end
        end

        // prefix level 5 (span 16)
        for (i = 0; i < 32; i = i + 1) begin : l5
            if (i >= 16) begin : d
                assign h5[i] = h4[i] | (t4[i] & h4[i-16]);
            end else begin : nd
                assign h5[i] = h4[i];
            end
        end

        // sum selection: single mux level driven by the pseudo carry
        for (i = 0; i < 32; i = i + 1) begin : sm
            if (i == 0) begin : b0
                assign sum[0] = pxo[0];
            end else begin : bn
                assign sum[i] = h5[i-1] ? (pxo[i] ^ tor[i]) : pxo[i];
            end
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
