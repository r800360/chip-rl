`timescale 1ns/1ps

module tb;

logic        clk;
logic        rst_n;
logic        valid_i;
logic [35:0] a_i;
logic [35:0] b_i;

wire         valid_o;
wire [35:0]  y_o;

logic [35:0] last_y;
logic [63:0] rng;

integer i;

addpipe36 dut (
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


function automatic [63:0] next_rng(
    input [63:0] x
);
    reg [63:0] y;
begin
    y = x;
    y = y ^ (y << 13);
    y = y ^ (y >> 7);
    y = y ^ (y << 17);
    next_rng = y;
end
endfunction


task automatic check_valid_then_hold(
    input [35:0] a,
    input [35:0] b
);
    logic [35:0] expected;
begin
    expected = a + b;

    @(negedge clk);

    a_i     = a;
    b_i     = b;
    valid_i = 1'b1;

    @(posedge clk);
    #1;

    if (valid_o !== 1'b1)
        $fatal(1, "valid_o not asserted");

    if (y_o !== expected)
        $fatal(
            1,
            "sum mismatch: a=%h b=%h got=%h expected=%h",
            a,
            b,
            y_o,
            expected
        );

    last_y = expected;

    @(negedge clk);

    a_i     = ~a;
    b_i     = b ^ 36'h55aa55aa5;
    valid_i = 1'b0;

    @(posedge clk);
    #1;

    if (valid_o !== 1'b0)
        $fatal(
            1,
            "valid_o asserted while invalid"
        );

    if (y_o !== last_y)
        $fatal(
            1,
            "y_o changed while invalid"
        );
end
endtask


task automatic check_back_to_back(
    input [35:0] a0,
    input [35:0] b0,
    input [35:0] a1,
    input [35:0] b1
);
    logic [35:0] e0;
    logic [35:0] e1;
begin
    e0 = a0 + b0;
    e1 = a1 + b1;

    @(negedge clk);

    a_i     = a0;
    b_i     = b0;
    valid_i = 1'b1;

    @(posedge clk);
    #1;

    if (valid_o !== 1'b1 || y_o !== e0)
        $fatal(
            1,
            "first back-to-back result failed"
        );

    @(negedge clk);

    a_i     = a1;
    b_i     = b1;
    valid_i = 1'b1;

    @(posedge clk);
    #1;

    if (valid_o !== 1'b1 || y_o !== e1)
        $fatal(
            1,
            "second back-to-back result failed"
        );

    last_y = e1;
end
endtask


initial begin
    rst_n   = 1'b0;
    valid_i = 1'b0;
    a_i     = 36'd0;
    b_i     = 36'd0;
    last_y  = 36'd0;
    rng     = 64'h243f6a8885a308d3;

    repeat (3) begin
        @(posedge clk);
        #1;

        if (valid_o !== 1'b0)
            $fatal(
                1,
                "valid_o nonzero during reset"
            );

        if (y_o !== 36'd0)
            $fatal(
                1,
                "y_o nonzero during reset"
            );
    end

    @(negedge clk);
    rst_n = 1'b1;

    check_valid_then_hold(
        36'h000000000,
        36'h000000000
    );

    check_valid_then_hold(
        36'hfffffffff,
        36'h000000001
    );

    check_valid_then_hold(
        36'hfffffffff,
        36'hfffffffff
    );

    check_valid_then_hold(
        36'haaaaaaaaa,
        36'h555555555
    );

    check_valid_then_hold(
        36'h800000000,
        36'h800000000
    );

    check_valid_then_hold(
        36'h7ffffffff,
        36'h000000001
    );

    for (i = 0; i < 10000; i = i + 1) begin
        rng = next_rng(rng);
        a_i = rng[35:0];

        rng = next_rng(rng);
        b_i = rng[35:0];

        check_valid_then_hold(
            a_i,
            b_i
        );
    end

    check_back_to_back(
        36'h23456789a,
        36'h102030405,
        36'hedcba9876,
        36'h011223344
    );

    $display(
        "PASS addpipe36 randomized+protocol"
    );

    $finish;
end

endmodule
