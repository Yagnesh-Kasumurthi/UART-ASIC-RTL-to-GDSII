
module uart_regs (
    input clk,
    input rst_n,

    // Bus interface
    input [1:0] bus_addr,
    input bus_wr_en,
    input bus_rd_en,
    input [7:0] bus_wdata,
    output reg [7:0] bus_rdata,

    // UART transmitter interface
    output reg [7:0] tx_data,
    output reg tx_start,
    input tx_busy,

    // UART receiver interface
    input [7:0] rx_data,
    input rx_valid,
    input rx_busy,
    input framing_error
);

    // Register address definitions
    localparam TX_DATA = 2'b00;
    localparam RX_DATA = 2'b01;
    localparam STATUS  = 2'b10;
    localparam CONTROL = 2'b11;

    // Internal storage registers
    reg [7:0] rx_data_reg;
    reg rx_available;
    reg framing_error_status;

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            tx_data              <= 8'b0;
            tx_start             <= 1'b0;
            rx_data_reg          <= 8'b0;
            rx_available         <= 1'b0;
            framing_error_status <= 1'b0;
        end

        else begin

            // Default TX request is LOW
            tx_start <= 1'b0;

            // Capture received data
            if (rx_valid) begin
                rx_data_reg  <= rx_data;
                rx_available <= 1'b1;
            end

            // Store framing error
            if (framing_error) begin
                framing_error_status <= 1'b1;
            end

            // Bus write operation
            if (bus_wr_en) begin

                case (bus_addr)

                    TX_DATA: begin
                        if (!tx_busy) begin
                            tx_data  <= bus_wdata;
                            tx_start <= 1'b1;
                        end
                    end

                    CONTROL: begin
                        // Reserved for future use
                    end

                    default: begin
                    end

                endcase
            end

            // Bus read side effects
            if (bus_rd_en) begin

                case (bus_addr)

                    RX_DATA: begin
                        rx_available <= 1'b0;
                    end

                    STATUS: begin
                        framing_error_status <= 1'b0;
                    end

                    default: begin
                    end

                endcase
            end

        end
    end

    // Combinational read multiplexer
    always @(*) begin

        case (bus_addr)

            TX_DATA: begin
                bus_rdata = tx_data;
            end

            RX_DATA: begin
                bus_rdata = rx_data_reg;
            end

            STATUS: begin
                bus_rdata = 8'b0;

                bus_rdata[0] = tx_busy;
                bus_rdata[1] = rx_busy;
                bus_rdata[2] = rx_available;
                bus_rdata[3] = framing_error_status;
            end

            CONTROL: begin
                bus_rdata = 8'b0;
            end

            default: begin
                bus_rdata = 8'b0;
            end

        endcase

    end

endmodule
