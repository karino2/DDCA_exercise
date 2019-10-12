# $testBenchName="testbench_mipstest_add"
# $testBenchName="testbench_d2s_one"
$testBenchName="testbench_dmac_d2s"

$vivadoPath = "C:\Xilinx\Vivado\2019.1\bin";

& $vivadoPath\xelab.bat -timescale "1ns/1ps" -stat $testBenchName;
& $vivadoPath\xsim.bat "work.$testBenchName" -t sim.tcl;

