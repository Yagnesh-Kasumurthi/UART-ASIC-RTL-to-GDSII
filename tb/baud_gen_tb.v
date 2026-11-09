
`timescale 1ns/1ps

module baud_gen_tb;

    // Testbench signals
    reg clk;
    reg rst_n;
    wire baud_tick;

    // Instantiate the baud generator
    baud_gen #(
        .CLK_FREQ_HZ(50000000),
        .BAUD_RATE(9600)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick)
    );

    // Generate 50 MHz clock (20 ns period)
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // Apply reset and run simulation
    initial begin

        $dumpfile("baud_gen.vcd");
        $dumpvars(0,baud_gen_tb);

        rst_n = 1'b0;

        // Hold reset for 5 clock cycles
        repeat (5) @(posedge clk);

        rst_n = 1'b1;

        $display("Reset released. Starting baud generator test.");

        // Wait for first baud tick
        @(posedge baud_tick);
        $display("First baud tick detected at time %0t ns", $time);

        // Wait for second baud tick
        @(posedge baud_tick);
        $display("Second baud tick detected at time %0t ns", $time);

        $display("Baud generator test completed.");

        #100;
        $finish;
    end

    // Monitor important signals
    initial begin
        $monitor("Time=%0t | clk=%b | rst_n=%b | counter=%d | baud_tick=%b",
                 $time, clk, rst_n, uut.counter, baud_tick);
    end

endmodule
