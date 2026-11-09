
# ==========================================
# UART ASIC - SKY130 Timing Constraints
# System Clock: 50 MHz
# Clock Period: 20 ns
# ==========================================

# 1. Define the system clock
create_clock -name clk -period 20.000 [get_ports clk]

# 2. Clock uncertainty
set_clock_uncertainty 0.200 [get_clocks clk]

# 3. Clock transition time
set_clock_transition 0.100 [get_clocks clk]

# 4. Processor bus input delays
set_input_delay 2.000 -clock clk [get_ports {bus_addr[0]}]
set_input_delay 2.000 -clock clk [get_ports {bus_addr[1]}]
set_input_delay 2.000 -clock clk [get_ports bus_wr_en]
set_input_delay 2.000 -clock clk [get_ports bus_rd_en]
set_input_delay 2.000 -clock clk [get_ports {bus_wdata[*]}]

# 5. Output delays
set_output_delay 2.000 -clock clk [get_ports {bus_rdata[*]}]
set_output_delay 2.000 -clock clk [get_ports tx]

# 6. Asynchronous input paths
# UART RX is asynchronous to the system clock.
set_false_path -from [get_ports rx]

# Reset is asynchronous and is not timed as normal data.
set_false_path -from [get_ports rst_n]
