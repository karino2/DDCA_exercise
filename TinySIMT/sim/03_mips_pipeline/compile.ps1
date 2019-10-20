$targetRtlNames = "alu.sv", "mips_pipeline.sv", "seqcirc.sv", "dmac.sv", "cmn.sv"
$testBenchFile = "testbench_pipeline.sv"

$vivadoPath = "C:\Xilinx\Vivado\2019.1\bin";
$rtlPath="..\..\rtl"


$targetRtls = $targetRtlNames | %{ "$rtlPath\$_"}

& $vivadoPath\xvlog.bat -sv $testBenchFile @targetRtls;
# & $vivadoPath\xelab.bat -timescale "1ns/1ps" -stat -debug all tb;
# & $vivadoPath\xelab.bat -L unisims_ver -L secureip -timescale "1ns/1ps" -stat tb;


