$vivadoPath = "C:\Xilinx\Vivado\2019.1\bin";

& $vivadoPath\xvlog.bat -sv -i ../../rtl -i ../../ip/output/mmcm -i ../../ip/output/mig -i ../../ip/output/mig/mig/example_design/sim -i ../../ip/output/jtag_axi -f target_files.f
