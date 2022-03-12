set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports clk]

set_property PACKAGE_PIN A8 [get_ports slideSwitch]
set_property IOSTANDARD LVCMOS33 [get_ports slideSwitch]

set_property PACKAGE_PIN H5 [get_ports led0]
set_property IOSTANDARD LVCMOS18 [get_ports led0]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
