`timescale 1ns/1ps

module tb;

logic        clk;
logic        rst_n;
logic        valid_i;
logic [31:0] a_i;
logic [31:0] b_i;

wire         valid_o;
wire [31:0]  y_o;

logic [31:0] last_y;
logic [31:0] rng;

integer i;

addpipe32 dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .valid_i (valid_i),
    .a_i     (a_i),
    .b_i     (b_i),
    .valid_o (valid_o),
    .y_o     (y_o)
);

initial clk = 1'b0;
always #5 clk = ~clk;


function automatic [31:0] next_rng(
    input [31:0] x
);
begin
    next_rng =
        (x * 32'd1664525)
        + 32'd1013904223;
end
endfunction


task automatic check_valid_then_hold(
    input [31:0] a,
    input [31:0] b
);
    logic [31:0] expected;
begin
    expected = a + b;

    @(negedge clk);

    a_i     = a;
    b_i     = b;
    valid_i = 1'b1;

    @(posedge clk);
    #1;

    if (valid_o !== 1'b1) begin
        $fatal(
            1,
            "valid_o not asserted: a=%h b=%h",
            a,
            b
        );
    end

    if (y_o !== expected) begin
        $fatal(
            1,
            "sum mismatch: a=%h b=%h got=%h expected=%h",
            a,
            b,
            y_o,
            expected
        );
    end

    last_y = expected;

    /*
     * Poison the data inputs while valid_i=0.
     * y_o must retain the previous valid result.
     */
    @(negedge clk);

    a_i     = ~a;
    b_i     = b ^ 32'hA55AA5;
    valid_i = 1'b0;

    @(posedge clk);
    #1;

    if (valid_o !== 1'b0) begin
        $fatal(
            1,
            "valid_o asserted during invalid cycle"
        );
    end

    if (y_o !== last_y) begin
        $fatal(
            1,
            "y_o changed while invalid: got=%h expected=%h",
            y_o,
            last_y
        );
    end
end
endtask


task automatic check_back_to_back(
    input [31:0] a0,
    input [31:0] b0,
    input [31:0] a1,
    input [31:0] b1
);
    logic [31:0] e0;
    logic [31:0] e1;
begin
    e0 = a0 + b0;
    e1 = a1 + b1;

    @(negedge clk);

    a_i     = a0;
    b_i     = b0;
    valid_i = 1'b1;

    @(posedge clk);
    #1;

    if (valid_o !== 1'b1 || y_o !== e0) begin
        $fatal(
            1,
            "back-to-back first result failed"
        );
    end

    /*
     * No invalid cycle here.
     */
    @(negedge clk);

    a_i     = a1;
    b_i     = b1;
    valid_i = 1'b1;

    @(posedge clk);
    #1;

    if (valid_o !== 1'b1 || y_o !== e1) begin
        $fatal(
            1,
            "back-to-back second result failed"
        );
    end

    last_y = e1;
end
endtask


initial begin
    rst_n   = 1'b0;
    valid_i = 1'b0;
    a_i     = 32'd0;
    b_i     = 32'd0;
    last_y  = 32'd0;

    rng = 32'h243f6a88;

    repeat (3) begin
        @(posedge clk);
        #1;

        if (valid_o !== 1'b0) begin
            $fatal(
                1,
                "valid_o nonzero during reset"
            );
        end

        if (y_o !== 32'd0) begin
            $fatal(
                1,
                "y_o nonzero during reset"
            );
        end
    end

    @(negedge clk);
    rst_n = 1'b1;

    /*
     * Directed arithmetic boundaries.
     */
    check_valid_then_hold(
        32'h000000,
        32'h000000
    );

    check_valid_then_hold(
        32'hffffff,
        32'h000001
    );

    check_valid_then_hold(
        32'hffffff,
        32'hffffff
    );

    check_valid_then_hold(
        32'haaaaaa,
        32'h555555
    );

    check_valid_then_hold(
        32'h800000,
        32'h800000
    );

    check_valid_then_hold(
        32'h7fffff,
        32'h000001
    );

    /*
     * Deterministic pseudo-random arithmetic/protocol tests.
     */
    for (i = 0; i < 10000; i = i + 1) begin
        rng = next_rng(rng);
        a_i = rng[31:0];

        rng = next_rng(rng);
        b_i = rng[31:0];

        check_valid_then_hold(
            a_i,
            b_i
        );
    end

    /*
     * Explicit consecutive valid transactions.
     */
    check_back_to_back(
        32'h123456,
        32'h010203,
        32'hfedcba,
        32'h001122
    );

    check_back_to_back(
        32'hffffff,
        32'h000001,
        32'h333333,
        32'h777777
    );

    $display(
        "PASS addpipe32 randomized+protocol"
    );

    $finish;
end

endmodule
