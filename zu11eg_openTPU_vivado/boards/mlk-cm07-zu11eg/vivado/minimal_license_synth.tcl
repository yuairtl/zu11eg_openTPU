set here [file dirname [file normalize [info script]]]
set part xczu11eg-ffvc1760-2-i
if {[info exists env(XILINXD_LICENSE_FILE)]} {
    puts "LICENSE_FILE=$env(XILINXD_LICENSE_FILE)"
} else {
    puts "LICENSE_FILE=<Vivado default search path>"
}
puts "LICENSE_PART=$part"
read_verilog [file join $here minimal_license_synth.v]
synth_design -top minimal_license_synth -part $part -mode out_of_context
puts "LICENSE_SYNTH_OK"
exit
