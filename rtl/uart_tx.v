
module uart_tx (
    input clk,
    input rst_n,
    input baud_tick,
    input tx_start,
    input [7:0] tx_data,

    output reg tx,
    output reg tx_busy,
    output reg tx_done
);

    // FSM state declarations
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    // Internal registers
    reg [1:0] state;
    reg [7:0] tx_shift_reg;
    reg [2:0] bit_index;

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            state        <= IDLE;
            tx_shift_reg <= 8'b0;
            bit_index    <= 3'b0;
            tx           <= 1'b1;
            tx_busy      <= 1'b0;
            tx_done      <= 1'b0;
        end

        else begin

            // Default: done is a one-cycle pulse
            tx_done <= 1'b0;

            case (state)

                // Wait for transmission request
                IDLE: begin
                    tx       <= 1'b1;
                    tx_busy  <= 1'b0;
                    bit_index <= 3'b0;

                    if (tx_start) begin
                        tx_shift_reg <= tx_data;
                        tx_busy      <= 1'b1;
                        tx           <= 1'b0;
                        state        <= START;
                    end
                end

                // Hold start bit for one bit period
                START: begin
                    if (baud_tick) begin
                        tx           <= tx_shift_reg[0];
                        tx_shift_reg <= tx_shift_reg >> 1;
                        bit_index    <= 3'b0;
                        state        <= DATA;
                    end
                end

                // Transmit eight data bits, LSB first
                DATA: begin
                    if (baud_tick) begin
                        if (bit_index == 3'd7) begin
                            tx    <= 1'b1;
                            state <= STOP;
                        end
                        else begin
                            tx           <= tx_shift_reg[0];
                            tx_shift_reg <= tx_shift_reg >> 1;
                            bit_index    <= bit_index + 1'b1;
                        end
                    end
                end

                // Hold stop bit for one bit period
                STOP: begin
                    if (baud_tick) begin
                        tx      <= 1'b1;
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;
                        state   <= IDLE;
                    end
                end

                default: begin
                    state   <= IDLE;
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;
                end

            endcase
        end
    end

endmodule
