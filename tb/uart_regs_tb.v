
`timescale 1ns/1ps

module uart_regs_tb;

    reg clk;
    reg rst_n;

    // Bus signals
    reg [1:0] bus_addr;
    reg bus_wr_en;
    reg bus_rd_en;
    reg [7:0] bus_wdata;
    wire [7:0] bus_rdata;

    // TX signals
    wire [7:0] tx_data;
    wire tx_start;
    reg tx_busy;

    // RX signals
    reg [7:0] rx_data;
    reg rx_valid;
    reg rx_busy;
    reg framing_error;

    integer errors;

    // Device Under Test
    uart_regs uut (
        .clk(clk),
        .rst_n(rst_n),

        .bus_addr(bus_addr),
        .bus_wr_en(bus_wr_en),
        .bus_rd_en(bus_rd_en),
        .bus_wdata(bus_wdata),
        .bus_rdata(bus_rdata),

        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),

        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_busy(rx_busy),
        .framing_error(framing_error)
    );

    // 50 MHz clock
    always #10 clk = ~clk;

    initial begin

        $dumpfile("sim/waveforms/uart_regs.vcd");
        $dumpvars(0, uart_regs_tb);

        // Initialize signals
        clk = 0;
        rst_n = 0;

        bus_addr = 0;
        bus_wr_en = 0;
        bus_rd_en = 0;
        bus_wdata = 0;

        tx_busy = 0;

        rx_data = 0;
        rx_valid = 0;
        rx_busy = 0;
        framing_error = 0;

        errors = 0;

        // Reset
        #50;
        rst_n = 1;

        repeat (2) @(posedge clk);

        // =================================
        // TEST 1: TX DATA WRITE
        // =================================

        $display("\nTEST 1: TX DATA WRITE");

        @(negedge clk);
        bus_addr = 2'b00;
        bus_wdata = 8'b01000001;
        bus_wr_en = 1'b1;

        @(posedge clk);
        #1;

        if (tx_data == 8'b01000001) begin
            $display("PASS: TX data stored correctly");
        end
        else begin
            $display("FAIL: TX data incorrect");
            errors = errors + 1;
        end

        if (tx_start == 1'b1) begin
            $display("PASS: TX start pulse generated");
        end
        else begin
            $display("FAIL: TX start pulse missing");
            errors = errors + 1;
        end

        @(negedge clk);
        bus_wr_en = 0;

        @(posedge clk);
        #1;

        if (tx_start == 0) begin
            $display("PASS: TX start pulse cleared");
        end
        else begin
            $display("FAIL: TX start pulse did not clear");
            errors = errors + 1;
        end

        // =================================
        // TEST 2: WRITE WHILE TX BUSY
        // =================================

        $display("\nTEST 2: WRITE WHILE TX BUSY");

        @(negedge clk);
        tx_busy = 1;
        bus_addr = 2'b00;
        bus_wdata = 8'h55;
        bus_wr_en = 1;

        @(posedge clk);
        #1;

        if (tx_data == 8'b01000001 && tx_start == 0) begin
            $display("PASS: Busy transmitter rejected write");
        end
        else begin
            $display("FAIL: Busy transmitter accepted write");
            errors = errors + 1;
        end

        @(negedge clk);
        bus_wr_en = 0;
        tx_busy = 0;

        // =================================
        // TEST 3: RX DATA CAPTURE
        // =================================

        $display("\nTEST 3: RX DATA CAPTURE");

        @(negedge clk);
        rx_data = 8'b10100101;
        rx_valid = 1;

        @(posedge clk);
        #1;

        @(negedge clk);
        rx_valid = 0;
        bus_addr = 2'b01;

        #1;

        if (bus_rdata == 8'b10100101) begin
            $display("PASS: RX data captured correctly");
        end
        else begin
            $display("FAIL: RX data incorrect");
            errors = errors + 1;
        end

        // =================================
        // TEST 4: RX AVAILABLE STATUS
        // =================================

        $display("\nTEST 4: RX AVAILABLE STATUS");

        bus_addr = 2'b10;
        #1;

        if (bus_rdata[2] == 1'b1) begin
            $display("PASS: RX available flag is HIGH");
        end
        else begin
            $display("FAIL: RX available flag is LOW");
            errors = errors + 1;
        end

        // =================================
        // TEST 5: CLEAR RX AVAILABLE
        // =================================

        $display("\nTEST 5: CLEAR RX AVAILABLE");

        @(negedge clk);
        bus_addr = 2'b01;
        bus_rd_en = 1;

        @(posedge clk);
        #1;

        if (uut.rx_available == 0) begin
            $display("PASS: RX available flag cleared");
        end
        else begin
            $display("FAIL: RX available flag not cleared");
            errors = errors + 1;
        end

        @(negedge clk);
        bus_rd_en = 0;

        // =================================
        // TEST 6: FRAMING ERROR STATUS
        // =================================

        $display("\nTEST 6: FRAMING ERROR STATUS");

        @(negedge clk);
        framing_error = 1;

        @(posedge clk);
        #1;

        @(negedge clk);
        framing_error = 0;
        bus_addr = 2'b10;

        #1;

        if (bus_rdata[3] == 1'b1) begin
            $display("PASS: Framing error status stored");
        end
        else begin
            $display("FAIL: Framing error status missing");
            errors = errors + 1;
        end

        // =================================
        // TEST 7: CLEAR FRAMING ERROR
        // =================================

        $display("\nTEST 7: CLEAR FRAMING ERROR");

        @(negedge clk);
        bus_rd_en = 1;
        bus_addr = 2'b10;

        @(posedge clk);
        #1;

        if (uut.framing_error_status == 0) begin
            $display("PASS: Framing error status cleared");
        end
        else begin
            $display("FAIL: Framing error status not cleared");
            errors = errors + 1;
        end

        @(negedge clk);
        bus_rd_en = 0;

        // =================================
        // FINAL RESULT
        // =================================

        #20;

        $display("\n-----------------------------");

        if (errors == 0) begin
            $display("ALL UART REGISTERS TESTS PASSED");
        end
        else begin
            $display("TEST FAILED: %0d errors", errors);
        end

        $display("-----------------------------");

        #50;
        $finish;

    end

endmodule
