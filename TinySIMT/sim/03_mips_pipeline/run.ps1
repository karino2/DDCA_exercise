param([string] $argBenchName="")

$testBenchName="testbench_ctrlunit";

if($argBenchName) {
    $testBenchName = $argBenchName;
}

$vivadoPath = "C:\Xilinx\Vivado\2019.1\bin";

& $vivadoPath\xelab.bat -timescale "1ns/1ps" -stat $testBenchName;
& $vivadoPath\xsim.bat "work.$testBenchName" -t sim.tcl;

