set wanted xczu11eg-ffvc1760-2-i
set found [get_parts -quiet $wanted]
puts "VIVADO_VERSION=[version -short]"
puts "WANTED_PART=$wanted"
puts "FOUND_PART=$found"
if {$found eq ""} {
    error "target part is not installed: $wanted"
}
puts "PART_CHECK_OK"
exit
