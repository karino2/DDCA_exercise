set dev 0
set bit "../../syn/output/arty_top.bit"
set ltx "../../syn/output/arty_top.ltx"

open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] $dev]
set_property FULL_PROBES.FILE ${ltx} [lindex [get_hw_devices] $dev]
refresh_hw_device [lindex [get_hw_devices] $dev]

source io.tcl

# mw 0 1234
