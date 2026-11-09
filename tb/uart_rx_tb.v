initial begin

    errors = 0;
    rx = 1'b1;
    rst_n = 1'b0;

    // Reset
    #100;
    rst_n = 1'b1;
    #100;

    // TEST 1: Valid frame
    $display("\nTEST 1: Valid UART frame");

    fork
        begin
            send_uart_frame(8'b01000001, 1'b1);
        end

        begin
            wait(rx_valid == 1'b1);
            #1;

            if (rx_data == 8'b01000001 && framing_error == 1'b0)
                $display("PASS: Valid frame received");
            else begin
                $display("FAIL: Valid frame reception");
                errors = errors + 1;
            end
        end
    join

    // TEST 2: Invalid stop bit
    $display("\nTEST 2: Invalid stop bit");

    fork
        begin
            send_uart_frame(8'b01000001, 1'b0);
        end

        begin
            wait(framing_error == 1'b1);
            #1;

            if (framing_error == 1'b1)
                $display("PASS: Framing error detected");
            else begin
                $display("FAIL: Framing error not detected");
                errors = errors + 1;
            end
        end
    join

    #10;

    if (rx_busy == 1'b0)
        $display("PASS: Receiver returned to idle");
    else begin
        $display("FAIL: Receiver still busy");
        errors = errors + 1;
    end

    // Final result
    if (errors == 0)
        $display("\nALL TESTS PASSED");
    else
        $display("\nTEST FAILED: %0d errors", errors);

    #100;
    $finish;

end