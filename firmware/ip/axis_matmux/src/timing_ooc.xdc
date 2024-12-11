create_clock -period 3.000 -name aclk -waveform {0.000 1.500} [get_ports {aclk}]

# All interfaces are synchronous to aclk
set_clock_groups -asynchronous -group [get_clocks aclk]

# Mark reset as asynchronous
set_false_path -from [get_ports aresetn]
