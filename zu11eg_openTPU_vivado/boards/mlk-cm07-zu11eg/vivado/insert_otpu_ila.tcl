proc debug_bus_bits {leaf width} {
    set result {}
    for {set bit 0} {$bit < $width} {incr bit} {
        set net [get_nets -hier -quiet -filter "NAME =~ \"*u_slice/${leaf}*\[$bit\]\""]
        if {[llength $net] != 1} {
            error "expected one net for ${leaf}\[$bit\], found: $net"
        }
        lappend result $net
    }
    return $result
}

proc debug_bus {core probe port_width leaf} {
    set port [get_debug_ports ${core}/${probe}]
    if {$port eq ""} {
        create_debug_port $core probe
        set port [get_debug_ports ${core}/${probe}]
    }
    set_property PORT_WIDTH $port_width $port
    connect_debug_port $port [debug_bus_bits $leaf $port_width]
}

set slice_cell [get_cells -hier -quiet -filter {NAME =~ "*u_board/u_slice"}]
if {[llength $slice_cell] != 1} {
    error "cannot resolve the slice cell for the ILAs: $slice_cell"
}
set clk_pin [get_pins -quiet ${slice_cell}/core_clk]
set core_clk_nets [get_nets -quiet -of_objects $clk_pin]
if {[llength $core_clk_nets] != 1} {
    error "cannot resolve the core clock net for the ILAs: pins=$clk_pin nets=$core_clk_nets"
}
set core_clk_net [lindex $core_clk_nets 0]
puts "OTPU_ILA_CLOCK_NET=$core_clk_net"

create_debug_core u_ila_mxu ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_mxu]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_mxu]
connect_debug_port u_ila_mxu/clk $core_clk_net
set_property PORT_WIDTH 4 [get_debug_ports u_ila_mxu/probe0]
connect_debug_port u_ila_mxu/probe0 [debug_bus_bits otpu_dbg_mxu_ctrl 4]
debug_bus u_ila_mxu probe1 32 otpu_dbg_mxu_raddr
debug_bus u_ila_mxu probe2 32 otpu_dbg_mxu_rdata
debug_bus u_ila_mxu probe3 32 otpu_dbg_mxu_waddr
debug_bus u_ila_mxu probe4 32 otpu_dbg_mxu_wdata
puts "OTPU_ILA_MXU_INSERTED"

create_debug_core u_ila_vpu ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_vpu]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_vpu]
connect_debug_port u_ila_vpu/clk $core_clk_net
set_property PORT_WIDTH 8 [get_debug_ports u_ila_vpu/probe0]
connect_debug_port u_ila_vpu/probe0 [debug_bus_bits otpu_dbg_vpu_ctrl 8]
debug_bus u_ila_vpu probe1 32 otpu_dbg_vpu_raddr_a
debug_bus u_ila_vpu probe2 32 otpu_dbg_vpu_rdata_a
debug_bus u_ila_vpu probe3 32 otpu_dbg_vpu_raddr_b
debug_bus u_ila_vpu probe4 32 otpu_dbg_vpu_rdata_b
debug_bus u_ila_vpu probe5 32 otpu_dbg_vpu_waddr
debug_bus u_ila_vpu probe6 32 otpu_dbg_vpu_wdata
puts "OTPU_ILA_VPU_INSERTED"
