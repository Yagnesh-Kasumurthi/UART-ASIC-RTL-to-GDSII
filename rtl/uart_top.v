
module uart_top #(
    parameter CLK_FREQ_HZ = 50000000,
    parameter BAUD_RATE   = 9600
)(
    input clk,
    input rst_n,

    // Processor bus interface
    input [1:0] bus_addr,
    input bus_wr_en,
    input bus_rd_en,
    input [7:0] bus_wdata,
    output [7:0] bus_rdata,

    // Serial interface
    input rx,
    output tx
);

    // Internal baud generator signal
    wire baud_tick;

    // Internal transmitter signals
    wire [7:0] tx_data;
    wire tx_start;
    wire tx_busy;
    wire tx_done;

    // Internal receiver signals
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_busy;
    wire framing_error;


    // ----------------------------------
    // 1. BAUD GENERATOR
    // ----------------------------------

    baud_gen #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick)
    );


    // ----------------------------------
    // 2. UART TRANSMITTER
    // ----------------------------------

    uart_tx uart_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );


    // ----------------------------------
    // 3. UART RECEIVER
    // ----------------------------------

    uart_rx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_busy(rx_busy),
        .framing_error(framing_error)
    );


    // ----------------------------------
    // 4. UART REGISTER INTERFACE
    // ----------------------------------

    uart_regs uart_regs_inst (
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

endmodule
