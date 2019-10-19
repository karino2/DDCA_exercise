# $testBenchName="testbench_mipstest_add"
# $testBenchName="testbench_mipssingle_d2s_one"
# $testBenchName="testbench_dmac_d2s"
# $testBenchName="testbench_luiori"
# $testBenchName="testbench_halt"
# $testBenchName="testbench_d2stest_cpuonly"
# $testBenchName="testbench_d2stest_check_led"
# $testBenchName="testbench_d2stest_failcase"
# $testBenchName="testbench_jtag_adapter";
# $testBenchName="testbench_fifo";
# $testBenchName="testbench_d2stest_check_led_mock_ddr";
# $testBenchName="testbench_mipstest_reset";
# $testBenchName="testbench_d2s_simple";
# $testBenchName="testbench_d2s_simple_fail2";
# $testBenchName="testbench_s2d_cpuonly";
# $testBenchName="testbench_dram2dram_copy";
$testBenchName="testbench_d2s_simple_writeback";

$vivadoPath = "C:\Xilinx\Vivado\2019.1\bin";

& $vivadoPath\xelab.bat -timescale "1ns/1ps" -stat $testBenchName;
& $vivadoPath\xsim.bat "work.$testBenchName" -t sim.tcl;

