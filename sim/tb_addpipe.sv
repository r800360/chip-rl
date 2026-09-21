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


    task automatic check_add_and_hold(
        input int unsigned a,
        input int unsigned b
    );
        logic [7:0] expected;
        logic [7:0] poison_a;
        logic [7:0] poison_b;

        begin
            expected = (a + b) & 8'hff;

            // Valid transaction.
            a_i = a[7:0];
            b_i = b[7:0];
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

            // Invalid cycle.
            // Deliberately alter the inputs. The original addpipe
            // semantics require y_o to retain the previous valid result.
            poison_a = a[7:0] ^ 8'hA5;
            poison_b = b[7:0] ^ 8'h5A;

            a_i = poison_a;
            b_i = poison_b;
            valid_i = 1'b0;

            @(posedge clk);
            #1;

            if (valid_o !== 1'b0)
                $fatal(
                    1,
                    "valid_o remained asserted"
                );

            if (y_o !== expected)
                $fatal(
                    1,
                    "y_o changed while invalid: previous=%0d got=%0d with poison inputs %0d,%0d",
                    expected,
                    y_o,
                    poison_a,
                    poison_b
                );
        end
    endtask


    task automatic check_back_to_back;
        begin
            // Transaction 1.
            a_i = 8'd10;
            b_i = 8'd20;
            valid_i = 1'b1;

            @(posedge clk);
            #1;

            if (valid_o !== 1'b1 || y_o !== 8'd30)
                $fatal(
                    1,
                    "back-to-back transaction 1 failed"
                );

            // Transaction 2 immediately follows transaction 1.
            a_i = 8'd100;
            b_i = 8'd55;
            valid_i = 1'b1;

            @(posedge clk);
            #1;

            if (valid_o !== 1'b1 || y_o !== 8'd155)
                $fatal(
                    1,
                    "back-to-back transaction 2 failed"
                );

            // Invalid cycle must retain the previous result.
            a_i = 8'hFF;
            b_i = 8'hFF;
            valid_i = 1'b0;

            @(posedge clk);
            #1;

            if (valid_o !== 1'b0)
                $fatal(
                    1,
                    "valid_o asserted after back-to-back test"
                );

            if (y_o !== 8'd155)
                $fatal(
                    1,
                    "y_o failed to hold after back-to-back test"
                );
        end
    endtask


    initial begin
        // Reset for two clocks.
        repeat (2) @(posedge clk);
        #1;

        if (valid_o !== 1'b0)
            $fatal(
                1,
                "valid_o reset failure"
            );

        if (y_o !== 8'd0)
            $fatal(
                1,
                "y_o reset failure"
            );

        rst_n = 1'b1;

        // Exhaustively test every possible 8-bit addition and
        // verify output-hold behavior after each transaction.
        for (int a = 0; a < 256; a++) begin
            for (int b = 0; b < 256; b++) begin
                check_add_and_hold(a, b);
            end
        end

        // Test consecutive valid transactions with no bubble.
        check_back_to_back();

        $display("PASS exhaustive+protocol: 65536 additions");
        $finish;
    end

endmodule
