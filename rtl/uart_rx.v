
module uart_rx #(
    parameter CLK_FREQ_HZ = 50000000,
    parameter BAUD_RATE   = 9600
)(
    input clk,
    input rst_n,
    input rx,

    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg rx_busy,
    output reg framing_error
);

    // Calculate clock cycles per UART bit
    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;
    localparam integer HALF_BIT     = CLKS_PER_BIT / 2;

    // Calculate counter width
    function integer clog2;
        input integer value;
        integer temp;
        begin
            temp = value - 1;
            for (clog2 = 0; temp > 0; clog2 = clog2 + 1)
                temp = temp >> 1;
        end
    endfunction

    localparam integer COUNTER_WIDTH =
        (CLKS_PER_BIT <= 1) ? 1 : clog2(CLKS_PER_BIT);

    // FSM state declarations
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    // Internal registers
    reg [1:0] state;
    reg [COUNTER_WIDTH-1:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] rx_shift_reg;

    // Synchronizer registers
    reg rx_sync;
    reg rx_sync_d;

    // Two-flop synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync   <= 1'b1;
            rx_sync_d <= 1'b1;
        end
        else begin
            rx_sync   <= rx;
            rx_sync_d <= rx_sync;
        end
    end

    // UART receiver FSM
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            state         <= IDLE;
            clk_count     <= 0;
            bit_index     <= 0;
            rx_shift_reg  <= 8'b0;
            rx_data       <= 8'b0;
            rx_valid      <= 1'b0;
            rx_busy       <= 1'b0;
            framing_error <= 1'b0;
        end

        else begin

            // Default pulse values
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;

            case (state)

                // Wait for start bit
                IDLE: begin
                    rx_busy   <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;

                    if (rx_sync_d && !rx_sync) begin
                        rx_busy  <= 1'b1;
                        clk_count <= 0;
                        state    <= START;
                    end
                end

                // Check the middle of start bit
                START: begin
                    if (clk_count == HALF_BIT - 1) begin
                        clk_count <= 0;

                        if (rx_sync == 1'b0) begin
                            bit_index <= 0;
                            state <= DATA;
                        end
                        else begin
                            state <= IDLE;
                            rx_busy <= 1'b0;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                // Receive eight data bits, LSB first
                DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        rx_shift_reg[bit_index] <= rx_sync;

                        if (bit_index == 3'd7) begin
                            state <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                // Check stop bit
                STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        rx_busy <= 1'b0;
                        state <= IDLE;

                        if (rx_sync == 1'b1) begin
                            rx_data <= rx_shift_reg;
                            rx_valid <= 1'b1;
                        end
                        else begin
                            framing_error <= 1'b1;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    clk_count <= 0;
                    rx_busy <= 1'b0;
                end

            endcase
        end
    end

endmodule
