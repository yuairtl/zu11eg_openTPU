# PL UART used by FSBL/U-Boot/Linux after the bitstream is loaded.
#
# F002 PCB workaround: the reference R2 pinout is M17=RXD and M16=TXD, but
# this board routes CH342K TXD1 (pin 5) to M16 and CH342K RXD1 (pin 6) to M17.
# Compensate on the FPGA side so the UART input receives CH342 TXD1 and the
# UART output drives CH342 RXD1. A future PCB ECO should swap UART_TXD_PL and
# UART_RXD_PL on the CH342 side and restore the reference R2 pin assignment.
set_property PACKAGE_PIN M16 [get_ports UART_0_rxd]
set_property PACKAGE_PIN M17 [get_ports UART_0_txd]
set_property IOSTANDARD LVCMOS18 [get_ports UART_0_rxd]
set_property IOSTANDARD LVCMOS18 [get_ports UART_0_txd]

# The UART is an asynchronous external interface. Its receiver already has the
# vendor synchronizer; do not invent a source-synchronous clock relationship.
set_false_path -from [get_ports UART_0_rxd]
set_false_path -to [get_ports UART_0_txd]

# The DDR4 reset_n pins are asynchronous, slow control outputs. MIG constrains
# the source-synchronous DDR interface itself; these two pins need no external
# output-delay clock.
set_false_path -to [get_ports ddr4_rtl_0_reset_n]
set_false_path -to [get_ports ddr4_rtl_1_reset_n]
