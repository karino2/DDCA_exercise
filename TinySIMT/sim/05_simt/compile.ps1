$targetRtlNames = "alu.sv", "mips_simt.sv", "seqcirc.sv", "dmac.sv", "cmn.sv"
$testBenchFile = "testbench_simt.sv"

$vivadoPath = "C:\Xilinx\Vivado\2019.1\bin";
$rtlPath="..\..\rtl"


$targetRtls = $targetRtlNames | %{ "$rtlPath\$_"}

& $vivadoPath\xvlog.bat -sv $testBenchFile @targetRtls;


