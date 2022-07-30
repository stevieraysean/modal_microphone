set_property PACKAGE_PIN E3 [get_ports i_clock]
set_property IOSTANDARD LVCMOS18 [get_ports i_clock]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

