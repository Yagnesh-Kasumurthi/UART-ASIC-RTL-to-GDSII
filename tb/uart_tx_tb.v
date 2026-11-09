
`timescale 1ns/1ps

module uart_tx_tb;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg tx_start;
    reg [7:0] tx_data;

    wire baud_tick;
    wire tx;
    wire tx_busy;
    wire tx_done;

    integer i;
    integer errors;

    // UART bit period
    localparam BIT_PERIOD_NS = 104160;

    // Instantiate baud generator
    baud_gen #(
        .CLK_FREQ_HZ(50000000),
        .BAUD_RATE(9600)
    ) baud_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick)
    );

    // Instantiate UART transmitter
    uart_tx uut (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // Generate 50 MHz clock
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // Main test sequence
    initial begin

        // Generate waveform
        $dumpfile("sim/waveforms/uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);

        // Initialize signals
        rst_n    = 1'b0;
        tx_start = 1'b0;
        tx_data  = 8'b00000000;
        errors   = 0;

        // Apply reset
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        $display("--------------------------------");
        $display("UART TRANSMITTER TEST STARTED");
        $display("--------------------------------");

        // Wait for baud timing alignment
        @(posedge baud_tick);
        @(negedge clk);

        // Transmit ASCII character A (65)
        tx_data  = 8'b01000001;
        tx_start = 1'b1;

        @(negedge clk);
        tx_start = 1'b0;

        $display("Transmitting data: %b", tx_data);

        // Check busy status
        if (tx_busy !== 1'b1) begin
            $display("ERROR: tx_busy did not become HIGH");
            errors = errors + 1;
        end

        // Wait for start bit
        wait (tx == 1'b0);

        // Sample middle of start bit
        #(BIT_PERIOD_NS/2);

        if (tx !== 1'b0) begin
            $display("ERROR: Start bit incorrect");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Start bit = 0");
        end

        // Check eight data bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin

            #BIT_PERIOD_NS;

            if (tx !== tx_data[i]) begin
                $display("ERROR: Data bit %0d incorrect. Expected=%b, Got=%b",
                         i, tx_data[i], tx);
                errors = errors + 1;
            end
            else begin
                $display("PASS: Data bit %0d = %b", i, tx);
            end

        end

        // Check stop bit
        #BIT_PERIOD_NS;

        if (tx !== 1'b1) begin
            $display("ERROR: Stop bit incorrect");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Stop bit = 1");
        end

        // Wait for transmission completion
        @(posedge tx_done);
        @(negedge clk);

        if (tx_busy !== 1'b0) begin
            $display("ERROR: tx_busy did not become LOW");
            errors = errors + 1;
        end
        else begin
            $display("PASS: tx_busy = 0");
        end

        // Final test result
        $display("--------------------------------");

        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);

        $display("--------------------------------");

        #100;
        $finish;

    end

    // Monitor important signals
    initial begin
        $monitor("Time=%0t | baud_tick=%b | tx_start=%b | tx=%b | busy=%b | done=%b",
                 $time, baud_tick, tx_start, tx, tx_busy, tx_done);
    end

    // Simulation timeout protection
    initial begin
        #2000000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule
