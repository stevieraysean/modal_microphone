set_property PACKAGE_PIN E3 [get_ports i_clock]
set_property IOSTANDARD LVCMOS18 [get_ports i_clock]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

create_clock -period 10 [get_ports i_clock]
create_genereated_clock -name i_clk_3072e2 -source [get_ports r_clk_384e6] -divide_by 125 [get_pins REGA/Q]