# $testBenchName="testbench_hello_ddr";
$testBenchName="tb"

$vivadoPath = "C:\Xilinx\Vivado\2019.1\bin";

& $vivadoPath\xelab.bat -L unisims_ver -L secureip -d x2Gb -d sg15E -d x16 -timescale "1ns/1ps" -stat $testBenchName;
& $vivadoPath\xsim.bat "work.$testBenchName" -t sim.tcl;

