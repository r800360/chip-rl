module tb;

    logic clk = 0;
    logic rst_n = 0;
    logic valid_i = 0;

    logic [7:0] a_i = 0;
    logic [7:0] b_i = 0;

    logic valid_o;
    logic [7:0] y_o;

    always #5 clk = ~clk;

    addpipe dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_i(valid_i),
        .a_i(a_i),
        .b_i(b_i),
        .valid_o(valid_o),
        .y_o(y_o)
    );

    task automatic check_add(
        input int unsigned a,
        input int unsigned b
    );
        logic [7:0] expected;

        begin
            expected = (a + b) & 8'hff;

            a_i = a;
            b_i = b;
            valid_i = 1'b1;

            @(posedge clk);
            #1;

            if (valid_o !== 1'b1)
                $fatal(
                    1,
                    "valid_o not asserted for %0d + %0d",
                    a,
                    b
                );

            if (y_o !== expected)
                $fatal(
                    1,
                    "wrong result: %0d + %0d => got %0d expected %0d",
                    a,
                    b,
                    y_o,
                    expected
                );

            valid_i = 1'b0;

            @(posedge clk);
            #1;

            if (valid_o !== 1'b0)
                $fatal(
                    1,
                    "valid_o remained asserted"
                );
        end
    endtask


    initial begin
        // Reset.
        repeat (2) @(posedge clk);

        #1;
        rst_n = 1'b1;

        // Exhaustively test all 8-bit input pairs.
        for (int a = 0; a < 256; a++) begin
            for (int b = 0; b < 256; b++) begin
                check_add(a, b);
            end
        end

        $display(
            "PASS exhaustive: 65536 additions"
        );

        $finish;
    end

endmodule
