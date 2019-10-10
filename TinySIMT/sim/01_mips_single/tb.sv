
// $value$plusargs("arg0=%s", testrom_file);

module testbench_mipstest_add(
    );
    logic clk, reset;

    logic [31:0] memReadData, memAddress, memWriteData;
    logic memWriteEnable;
    sram DataMem(clk, memAddress, memWriteEnable, memWriteData, memReadData);
    mips_single #("mipstest_add.mem") dut(clk, reset, 0, memReadData, memAddress, memWriteData, memWriteEnable);
                     
    initial begin
        clk = 0; reset = 1; #10;
        // $display("next instr address=%h, nextInstr=%h", pc, instr);
        reset = 0; clk = 1; #10;
        // $display("next instr address=%h, nextInstr=%h", pc, instr);
        clk = 0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk = 0; #10;
        assert(dut.RegFile.regs[3] == 32'd8) else $error("fail reg3 add, %b", dut.RegFile.regs[3]);
        $display("mips add test done");
    end
    
endmodule


