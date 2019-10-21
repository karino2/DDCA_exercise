set dev 0
# set bit "output/arty_top.bit"
# set ltx "output/arty_top.ltx"
set bit "output/arty_top_pipeline.bit"
set ltx "output/arty_top_pipeline.ltx"

open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] $dev]
set_property FULL_PROBES.FILE ${ltx} [lindex [get_hw_devices] $dev]
refresh_hw_device [lindex [get_hw_devices] $dev]

source io.tcl

# mw 0 1234
