$testBenchName="testbench_mipstest_add"

$vivadoPath = "C:\Xilinx\Vivado\2019.1\bin";

& $vivadoPath\xsim.bat "work.$testBenchName" -t sim.tcl;

