module tb;

    logic clk = 0;
    logic rst_n = 0;
    logic valid_i = 0;

    logic [15:0] a_i = 0;
    logic [15:0] b_i = 0;

    logic valid_o;
    logic [15:0] y_o;

    logic [31:0] rng = 32'h1ACE_B00C;

    always #5 clk = ~clk;

    addpipe16 dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_i(valid_i),
        .a_i(a_i),
        .b_i(b_i),
        .valid_o(valid_o),
        .y_o(y_o)
    );


    function automatic [31:0] next_rng(
        input [31:0] x
    );
        begin
            next_rng = {
                x[30:0],
                x[31] ^ x[21] ^ x[1] ^ x[0]
            };
        end
    endfunction


    task automatic check_add_and_hold(
        input logic [15:0] a,
        input logic [15:0] b
    );
        logic [15:0] expected;

        begin
            expected = a + b;

            a_i = a;
            b_i = b;
            valid_i = 1'b1;

            @(posedge clk);
            #1;

            if (valid_o !== 1'b1)
                $fatal(
                    1,
                    "valid_o missing for %0d + %0d",
                    a,
                    b
                );

            if (y_o !== expected)
                $fatal(
                    1,
                    "wrong result: %0d + %0d got %0d expected %0d",
                    a,
                    b,
                    y_o,
                    expected
                );

            // Change inputs aggressively while invalid.
            a_i = a ^ 16'hA5A5;
            b_i = b ^ 16'h5A5A;
            valid_i = 1'b0;

            @(posedge clk);
            #1;

            if (valid_o !== 1'b0)
                $fatal(
                    1,
                    "valid_o asserted during invalid cycle"
                );

            if (y_o !== expected)
                $fatal(
                    1,
                    "y_o did not hold during invalid cycle"
                );
        end
    endtask


    initial begin
        repeat (2) @(posedge clk);
        #1;

        if (valid_o !== 1'b0 || y_o !== 16'd0)
            $fatal(1, "reset failure");

        rst_n = 1'b1;

        // Important edge cases.
        check_add_and_hold(16'h0000, 16'h0000);
        check_add_and_hold(16'h0000, 16'hFFFF);
        check_add_and_hold(16'hFFFF, 16'h0001);
        check_add_and_hold(16'hFFFF, 16'hFFFF);
        check_add_and_hold(16'h7FFF, 16'h0001);
        check_add_and_hold(16'h8000, 16'h8000);
        check_add_and_hold(16'hAAAA, 16'h5555);

        // 10,000 deterministic pseudo-random tests.
        for (int i = 0; i < 10000; i++) begin
            rng = next_rng(rng);

            check_add_and_hold(
                rng[15:0],
                rng[31:16]
            );
        end

        // Consecutive valid cycles.
        a_i = 16'd1000;
        b_i = 16'd2000;
        valid_i = 1'b1;

        @(posedge clk);
        #1;

        if (!valid_o || y_o !== 16'd3000)
            $fatal(1, "back-to-back #1 failed");

        a_i = 16'd3000;
        b_i = 16'd4000;
        valid_i = 1'b1;

        @(posedge clk);
        #1;

        if (!valid_o || y_o !== 16'd7000)
            $fatal(1, "back-to-back #2 failed");

        $display("PASS addpipe16 randomized+protocol");
        $finish;
    end

endmodule
