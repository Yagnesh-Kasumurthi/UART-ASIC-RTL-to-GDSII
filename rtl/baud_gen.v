
module baud_gen #(
    parameter CLK_FREQ_HZ = 50000000,
    parameter BAUD_RATE   = 9600
)(
    input clk,
    input rst_n,
    output reg baud_tick
);

    // Calculate clock cycles required for one UART bit
    localparam CLKS_PER_BIT =
        (CLK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE;

    // Calculate the required counter width
    localparam COUNTER_WIDTH =
        (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);

    // Internal counter register
    reg [COUNTER_WIDTH-1:0] counter;

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            counter   <= 0;
            baud_tick <= 1'b0;
        end

        else begin
            baud_tick <= 1'b0;

            if (counter == CLKS_PER_BIT - 1) begin
                counter   <= 0;
                baud_tick <= 1'b1;
            end

            else begin
                counter <= counter + 1'b1;
            end
        end

    end

endmodule
