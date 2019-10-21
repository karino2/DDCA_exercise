param([string] $argBenchName="")

# $testBenchName="testbench_ddr_with_jtag_adapter"
# $testBenchName="testbench_dma_with_jtag_adapter"
# $testBenchName="testbench_integrate_all_d2s_check_led"
# $testBenchName="testbench_reset_clk_forever"
$testBenchName="testbench_integrate_all_d2s_simple";

if($argBenchName) {
    $testBenchName = $argBenchName;
}



$vivadoPath = "C:\Xilinx\Vivado\2019.1\bin";

& $vivadoPath\xelab.bat -L unisims_ver -L secureip -d x2Gb -d sg15E -d x16 -timescale "1ns/1ps" -stat $testBenchName;
& $vivadoPath\xsim.bat "work.$testBenchName" -t sim.tcl;

