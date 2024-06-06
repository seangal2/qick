create_clock -period 1.000 -name aclk -waveform {0.000 0.500} [get_ports aclk]
create_clock -period 10.000 -name s_axi_aclk -waveform {0.000 5.000} [get_ports s_axi_aclk]
set_input_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports {s_axi_araddr[*]}]
set_input_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.400 [get_ports {s_axi_araddr[*]}]
set_input_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports {s_axi_awaddr[*]}]
set_input_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.400 [get_ports {s_axi_awaddr[*]}]
set_input_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports {s_axi_wdata[*]}]
set_input_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.400 [get_ports {s_axi_wdata[*]}]
set_input_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports {s_axi_wstrb[*]}]
set_input_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.400 [get_ports {s_axi_wstrb[*]}]
set _xlnx_shared_i0 [get_ports {s_axis_tdata[*]}]
set_input_delay -clock [get_clocks aclk] -min -add_delay 0.200 $_xlnx_shared_i0
set_input_delay -clock [get_clocks aclk] -max -add_delay 0.400 $_xlnx_shared_i0
set_input_delay -clock [get_clocks aclk] -min -add_delay 0.200 [get_ports aresetn]
set_input_delay -clock [get_clocks aclk] -max -add_delay 0.400 [get_ports aresetn]
set_input_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports s_axi_aresetn]
set_input_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.400 [get_ports s_axi_aresetn]
set_input_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports s_axi_arvalid]
set_input_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.400 [get_ports s_axi_arvalid]
set_input_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports s_axi_awvalid]
set_input_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.400 [get_ports s_axi_awvalid]
set_input_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports s_axi_bready]
set_input_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.400 [get_ports s_axi_bready]
set_input_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports s_axi_rready]
set_input_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.400 [get_ports s_axi_rready]
set_input_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports s_axi_wvalid]
set_input_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.400 [get_ports s_axi_wvalid]
set_input_delay -clock [get_clocks aclk] -min -add_delay 0.200 [get_ports s_axis_tvalid]
set_input_delay -clock [get_clocks aclk] -max -add_delay 0.400 [get_ports s_axis_tvalid]
set_output_delay -clock [get_clocks aclk] -min -add_delay 0.200 [get_ports {m0_axis_tdata[*]}]
set_output_delay -clock [get_clocks aclk] -max -add_delay 0.500 [get_ports {m0_axis_tdata[*]}]
set_output_delay -clock [get_clocks aclk] -min -add_delay 0.200 [get_ports {m1_axis_tdata[*]}]
set_output_delay -clock [get_clocks aclk] -max -add_delay 0.500 [get_ports {m1_axis_tdata[*]}]
set_output_delay -clock [get_clocks aclk] -min -add_delay 0.200 [get_ports {m2_axis_tdata[*]}]
set_output_delay -clock [get_clocks aclk] -max -add_delay 0.500 [get_ports {m2_axis_tdata[*]}]
set_output_delay -clock [get_clocks aclk] -min -add_delay 0.200 [get_ports {m3_axis_tdata[*]}]
set_output_delay -clock [get_clocks aclk] -max -add_delay 0.500 [get_ports {m3_axis_tdata[*]}]
set_output_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports {s_axi_rdata[*]}]
set_output_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.500 [get_ports {s_axi_rdata[*]}]
set_output_delay -clock [get_clocks aclk] -min -add_delay 0.200 [get_ports m0_axis_tvalid]
set_output_delay -clock [get_clocks aclk] -max -add_delay 0.500 [get_ports m0_axis_tvalid]
set_output_delay -clock [get_clocks aclk] -min -add_delay 0.200 [get_ports m1_axis_tvalid]
set_output_delay -clock [get_clocks aclk] -max -add_delay 0.500 [get_ports m1_axis_tvalid]
set_output_delay -clock [get_clocks aclk] -min -add_delay 0.200 [get_ports m2_axis_tvalid]
set_output_delay -clock [get_clocks aclk] -max -add_delay 0.500 [get_ports m2_axis_tvalid]
set_output_delay -clock [get_clocks aclk] -min -add_delay 0.200 [get_ports m3_axis_tvalid]
set_output_delay -clock [get_clocks aclk] -max -add_delay 0.500 [get_ports m3_axis_tvalid]
set_output_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports s_axi_arready]
set_output_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.500 [get_ports s_axi_arready]
set_output_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports s_axi_awready]
set_output_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.500 [get_ports s_axi_awready]
set_output_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports s_axi_bvalid]
set_output_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.500 [get_ports s_axi_bvalid]
set_output_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports s_axi_rvalid]
set_output_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.500 [get_ports s_axi_rvalid]
set_output_delay -clock [get_clocks s_axi_aclk] -min -add_delay 0.200 [get_ports s_axi_wready]
set_output_delay -clock [get_clocks s_axi_aclk] -max -add_delay 0.500 [get_ports s_axi_wready]
set_clock_groups -asynchronous -group [get_clocks s_axi_aclk] -group [get_clocks aclk]

set_false_path -to [all_outputs]