
`timescale 1ns/1ps

module uart_top_tb;

    reg clk;
    reg rst_n;

    // Processor bus signals
    reg [1:0] bus_addr;
    reg bus_wr_en;
    reg bus_rd_en;
    reg [7:0] bus_wdata;
    wire [7:0] bus_rdata;

    // Serial signals
    wire tx;
    wire rx;

    // Loopback connection
    assign rx = tx;

    integer errors;
    integer timeout_count;

    // Device Under Test
    uart_top #(
        .CLK_FREQ_HZ(50000000),
        .BAUD_RATE(9600)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),

        .bus_addr(bus_addr),
        .bus_wr_en(bus_wr_en),
        .bus_rd_en(bus_rd_en),
        .bus_wdata(bus_wdata),
        .bus_rdata(bus_rdata),

        .rx(rx),
        .tx(tx)
    );

    // 50 MHz clock: 20 ns period
    always #10 clk = ~clk;


    initial begin

        $dumpfile("sim/waveforms/uart_top.vcd");
        $dumpvars(0, uart_top_tb);

        // Initialize signals
        clk = 0;
        rst_n = 0;

        bus_addr = 0;
        bus_wr_en = 0;
        bus_rd_en = 0;
        bus_wdata = 0;

        errors = 0;
        timeout_count = 0;

        // Apply reset
        #100;
        rst_n = 1;

        repeat (5) @(posedge clk);

        // =================================
        // TEST 1: WRITE DATA TO TRANSMITTER
        // =================================

        $display("\nTEST 1: WRITE ASCII A");

        @(negedge clk);

        bus_addr = 2'b00;
        bus_wdata = 8'h41;
        bus_wr_en = 1;

        @(negedge clk);
        bus_wr_en = 0;

        if (uut.tx_data == 8'h41) begin
            $display("PASS: TX data register contains 0x41");
        end
        else begin
            $display("FAIL: TX data register incorrect");
            errors = errors + 1;
        end


        // =================================
        // TEST 2: TRANSMITTER BUSY CHECK
        // =================================

        $display("\nTEST 2: TRANSMITTER BUSY CHECK");

        timeout_count = 0;

        while ((uut.tx_busy !== 1'b1) &&
               (timeout_count < 100)) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        if (uut.tx_busy == 1'b1) begin
            $display("PASS: Transmitter entered busy state");
        end
        else begin
            $display("FAIL: Transmitter did not become busy");
            errors = errors + 1;
        end


        // =================================
        // TEST 3: WAIT FOR TRANSMISSION
        // =================================

        $display("\nTEST 3: TRANSMISSION COMPLETION");

        timeout_count = 0;

        while ((uut.tx_busy !== 1'b0) &&
               (timeout_count < 120000)) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        #1;

        if (uut.tx_busy == 1'b0) begin
            $display("PASS: Transmission completed");
        end
        else begin
            $display("FAIL: Transmission timeout");
            errors = errors + 1;
        end


        // =================================
        // TEST 4: WAIT FOR RECEPTION
        // =================================

        $display("\nTEST 4: RECEIVER COMPLETION");

        timeout_count = 0;

        while ((uut.uart_regs_inst.rx_available !== 1'b1) &&
               (timeout_count < 120000)) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        #1;

        if (uut.uart_regs_inst.rx_available == 1'b1) begin
            $display("PASS: Receiver completed reception");
        end
        else begin
            $display("FAIL: Receiver timeout");
            errors = errors + 1;
        end


        // =================================
        // TEST 5: VERIFY RECEIVED DATA
        // =================================

        $display("\nTEST 5: DATA VERIFICATION");

        bus_addr = 2'b01;
        #1;

        $display("Transmitted data = %h", 8'h41);
        $display("Received data    = %h", bus_rdata);

        if (bus_rdata == 8'h41) begin
            $display("PASS: Received data matches transmitted data");
        end
        else begin
            $display("FAIL: Data mismatch");
            errors = errors + 1;
        end


        // =================================
        // TEST 6: CHECK UART STATUS
        // =================================

        $display("\nTEST 6: UART STATUS CHECK");

        bus_addr = 2'b10;
        #1;

        $display("STATUS = %b", bus_rdata);

        if (bus_rdata[0] == 1'b0)
            $display("PASS: TX is idle");
        else begin
            $display("FAIL: TX is still busy");
            errors = errors + 1;
        end

        if (bus_rdata[1] == 1'b0)
            $display("PASS: RX is idle");
        else begin
            $display("FAIL: RX is still busy");
            errors = errors + 1;
        end

        if (bus_rdata[2] == 1'b1)
            $display("PASS: RX data available");
        else begin
            $display("FAIL: RX data unavailable");
            errors = errors + 1;
        end

        if (bus_rdata[3] == 1'b0)
            $display("PASS: No framing error");
        else begin
            $display("FAIL: Framing error detected");
            errors = errors + 1;
        end


        // =================================
        // TEST 7: READ RX DATA
        // =================================

        $display("\nTEST 7: READ RX DATA");

        @(negedge clk);

        bus_addr = 2'b01;
        bus_rd_en = 1;

        @(posedge clk);
        #1;

        if (bus_rdata == 8'h41) begin
            $display("PASS: RX data read successfully");
        end
        else begin
            $display("FAIL: RX data read incorrect");
            errors = errors + 1;
        end

        if (uut.uart_regs_inst.rx_available == 1'b0) begin
            $display("PASS: RX available flag cleared");
        end
        else begin
            $display("FAIL: RX available flag not cleared");
            errors = errors + 1;
        end

        @(negedge clk);
        bus_rd_en = 0;


        // =================================
        // TEST 8: VERIFY CLEARED STATUS
        // =================================

        $display("\nTEST 8: FINAL STATUS CHECK");

        bus_addr = 2'b10;
        #1;

        if (bus_rdata[2] == 1'b0) begin
            $display("PASS: RX available status cleared");
        end
        else begin
            $display("FAIL: RX available status still HIGH");
            errors = errors + 1;
        end

        if (bus_rdata[3] == 1'b0) begin
            $display("PASS: Framing error status remains clear");
        end
        else begin
            $display("FAIL: Framing error status is HIGH");
            errors = errors + 1;
        end


        // =================================
        // FINAL RESULT
        // =================================

        $display("\n================================");

        if (errors == 0) begin
            $display("ALL UART LOOPBACK TESTS PASSED");
        end
        else begin
            $display("UART LOOPBACK TEST FAILED");
            $display("Total errors = %0d", errors);
        end

        $display("================================");

        #100;
        $finish;

    end

endmodule
