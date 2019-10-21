"xvlog*", "xelab*", "webtalk*","xsim*", "sim.log", "*.wdb", "*.vcd" | %{Remove-Item $_}
Remove-Item -Recurse xsim*