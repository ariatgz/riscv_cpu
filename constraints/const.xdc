# 200MHz Active Differential Clock (Bank 34)
set_property PACKAGE_PIN R4 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_p]

set_property PACKAGE_PIN T4 [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_n]

# System Reset (Bank 34, Active Low)
set_property PACKAGE_PIN T6 [get_ports rst_n]
set_property IOSTANDARD LVCMOS15 [get_ports rst_n]

# UART TXD (Bank 13)
set_property PACKAGE_PIN AB15 [get_ports uart_tx_out]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx_out]

set_property PACKAGE_PIN E17 [get_ports led_out]
set_property IOSTANDARD LVCMOS33 [get_ports led_out]