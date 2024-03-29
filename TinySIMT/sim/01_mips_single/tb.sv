
// $value$plusargs("arg0=%s", testrom_file);

module testbench_mipstest_add(
    );
    logic clk, reset;

    logic [31:0] sramReadData, sramAddress, sramWriteData, dmaSrcAddress, dmaDstAddress;
    logic sramWriteEnable, halt;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress[15:2], sramWriteEnable, sramWriteData, sramReadData);

    mips_single #("mipstest_add.mem") dut(clk, reset, 1'b0, sramReadData, sramAddress, sramWriteData, sramWriteEnable,
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);
                     
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


module testbench_mipstest_reset(
    );
    logic clk, reset;

    logic [31:0] sramReadData, sramAddress, sramWriteData, dmaSrcAddress, dmaDstAddress;
    logic sramWriteEnable, halt;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress[15:2], sramWriteEnable, sramWriteData, sramReadData);

    mips_single #("halt_test.mem") dut(clk, reset, 1'b0, sramReadData, sramAddress, sramWriteData, sramWriteEnable,
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);
                     
    initial begin
        $display("reset test begin");
        clk = 0; reset = 1; #10; reset = 0; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        assert(halt) else $error("not halted");

        $display("pc=%h", dut.pc);
        clk = 0; reset = 1; #10; clk=1; #10;
        clk = 0; reset = 0; #10; 
        clk = 1; #10;
        $display("pc=%h", dut.pc);
        $display("reset test end");
    end
endmodule



module testbench_luiori(
    );
    logic clk, reset;

    logic [31:0] sramReadData, sramAddress, sramWriteData, dmaSrcAddress, dmaDstAddress;
    logic sramWriteEnable, halt;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress[15:2], sramWriteEnable, sramWriteData, sramReadData);

    mips_single #("luiori_test.mem") dut(clk, reset, 1'b0, sramReadData, sramAddress, sramWriteData, sramWriteEnable,
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);
                     
    initial begin
        clk = 0; reset = 1; #10; reset = 0; clk = 1; #10;

        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk = 0; #10;
        assert(dut.RegFile.regs[1] === 32'h04d2162e) else $error("fail lui ori, %h", dut.RegFile.regs[1]);
        $display("mips lui ori test done");
    end
    
endmodule

module testbench_halt(
    );
    logic clk, reset;

    logic [31:0] sramReadData, sramAddress, sramWriteData, dmaSrcAddress, dmaDstAddress;
    logic sramWriteEnable, halt;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress[15:2], sramWriteEnable, sramWriteData, sramReadData);

    mips_single #("halt_test.mem") dut(clk, reset, 1'b0, sramReadData, sramAddress, sramWriteData, sramWriteEnable,
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);
                     
    initial begin
        $display("halt test begin");
        clk = 0; reset = 1; #10; reset = 0; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        assert(halt) else $error("not halted");
        $display("halt test end");
    end
    
endmodule

module testbench_mipssingle_d2s_one(
    );
    logic clk, reset;

    logic [31:0] sramReadData, sramAddress, sramWriteData, dmaSrcAddress, dmaDstAddress;
    logic sramWriteEnable, halt, stall;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress[15:2], sramWriteEnable, sramWriteData, sramReadData);

    mips_single #("d2s_one_test.mem") dut(clk, reset, stall, sramReadData, sramAddress, sramWriteData, sramWriteEnable,
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);
                     
    initial begin
        stall = 0;
        clk = 0; reset = 1; #10;
        // $display("next instr address=%h, nextInstr=%h", pc, instr);
        reset = 0; clk = 1; #10;        
        clk = 0; #10; clk = 1; #10;
        assert(dmaCmd === 2'b01) else $error("dmaCmd not invoked.");
        assert(dmaSrcAddress === 32'd16 & dmaDstAddress === 32'd24) else $error("dmaAddress error.");
        stall = 1;
        // $display("pc=%h, instr=%h, %b", dut.pc, dut.instr, dmaCmd);
        $display("begin stall.");
        clk=0; #10; clk=1; #10; clk=0; #10;
        assert(dut.RegFile.regs[3] !== 32'd1234) else $error("stall fail");
        $display("stall done.");
        stall = 0;
        #10;
        clk = 1; #10;
        // $display("pc=%h, instr=%h, %b", dut.pc, dut.instr, dmaCmd);
        clk = 0; #10;
        clk = 1; #10; clk = 0; #10;
        assert(dut.RegFile.regs[3] === 32'd1234) else $error("fail to resume from DMAC. reg3=%b", dut.RegFile.regs[3]);
        clk = 1; #10; clk = 0; #10;
        $display("d2s one test done");
    end
    
endmodule

module testbench_dmac_d2s(
    );
    logic clk, reset;

    logic [31:0] sramReadData, sramWriteData,  dmaSrcAddress, dmaDstAddress,
                dramAddress, dramReadData, dramWriteData;
    logic [13:0] sramAddress;
    logic sramWriteEnable, dramWriteEnable, dramReadEnable, dramValid, stall;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress, sramWriteEnable, sramWriteData, sramReadData);

    dma_ctrl dut(clk, reset, dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth,
                sramReadData, dramReadData,
                sramAddress, sramWriteData, sramWriteEnable,
                dramAddress, dramWriteData, dramWriteEnable, dramReadEnable,
                dramValid, stall);

                     
    initial begin
        $display("dmac d2s test begin");
        dmaCmd = 0;
        dramValid = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;        
        clk = 0; #10; clk = 1; #10;
        assert({stall, sramWriteEnable, dramWriteEnable, dramReadEnable}  === 0) else $error("Dormant state produce wrong signal.");
        assert(dut.state === 0) else $error("initial state is not dormant.");

        dmaCmd = 2'b01; // d2s
        dmaSrcAddress = 24;
        dmaDstAddress = 12;
        dmaWidth = 4; // 4word = 16byte.

        clk = 0; #10; clk = 1; #10;
        assert(dut.state === 1) else $error("not in D2S_BEGIN state.");
        assert(stall) else $error("not stall in D2S_BEGIN");
        dmaCmd = 2'b00; // turn off dmaCmd after stall.

        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10;

        assert(dramReadEnable) else $error("DRAM read not invoked.");
        assert(dramAddress === 24) else $error("DRAM read address is wrong. %h", dramAddress);
        assert(stall) else $error("not stall2.");

        dramReadData = 1234;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        assert(!dramReadEnable) else $error("DRAM read not turn off.");
        assert(sramWriteEnable) else $error("SRAM write not enabled. we=%b, state=%h", sramWriteEnable, dut.state);
        assert(sramAddress === 3) else $error("SRAM01 write address is wrong. %h", sramAddress);
        assert(sramWriteData === 1234) else $error("SRAM write data is wrong. %h", sramWriteData);
        assert(stall) else $error("not stall3.");

        dramValid = 0;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramReadEnable) else $error("DRAM read2 not invoked.");
        assert(dramAddress === 24+4) else $error("DRAM read2 address is wrong. %h", dramAddress);
        assert(stall) else $error("not stall4.");

        dramReadData = 5678;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        dramReadData = 32'habcd;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;

        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        dramReadData = 32'hef12;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;

        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        // 12, 16, 20, 24 divided by 4.
        assert(DataMem.SRAM[3] === 1234) else $error("dram[12] is wrong, %h", DataMem.SRAM[3]);
        assert(DataMem.SRAM[4] === 5678) else $error("dram[16] is wrong");
        assert(DataMem.SRAM[5] === 32'habcd) else $error("dram[20] is wrong");
        assert(DataMem.SRAM[6] === 32'hef12) else $error("dram[24] is wrong");

        assert(!stall) else $error("wrongly stalled.");
        assert(dut.state === 0) else $error("not DORMANT. %h", dut.state);
        $display("dmac d2s test done");
    end
    
endmodule


/*
This test is very fragil and deeply cooupled to asm and cpu behaviour.
*/
module testbench_d2stest_cpuonly(
    );
    logic clk, reset;

    logic [31:0] sramReadData, sramAddress, sramWriteData, dmaSrcAddress, dmaDstAddress;
    logic sramWriteEnable, halt, stall;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress[15:2], sramWriteEnable, sramWriteData, sramReadData);

    /*
    // assume in DDR,
    // 24: 123
    // 28: 456
    // 32: 789
    // 34: 5555

    led map
    0x8000_0000: led[0]
    0x8000_0004: led[1]
    0x8000_0008: led[2]
    */
    mips_single #("d2s_test.mem") dut(clk, reset, stall, sramReadData, sramAddress, sramWriteData, sramWriteEnable,
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);
                     
    initial begin
        stall = 0;
        clk = 0; reset = 1; #10;
        // $display("next instr address=%h, nextInstr=%h", pc, instr);
        reset = 0; clk = 1; #10;        
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        $display("dmaCmd=%h", dmaCmd);
        assert(dmaCmd === 2'b01) else $error("dmaCmd not invoked.");
        assert(dmaSrcAddress === 32'd24) else $error("dmaAddress error.");
        stall = 1;
        // $display("pc=%h, instr=%h, %b", dut.pc, dut.instr, dmaCmd);
        $display("begin stall.");
        clk=0; #10; clk=1; #10; clk=0; #10;

        stall = 0;
        /* 12/4, 16/4, 20/4, 24/4 */
        DataMem.SRAM[3] = 123;
        DataMem.SRAM[4] = 456;
        DataMem.SRAM[5] = 789;
        DataMem.SRAM[6] = 5555;
        #10;
        clk = 1; #10;

        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        // led is wrongly mapped to SRAM[2:0] in testbed.
        assert(DataMem.SRAM[0] ===1 & DataMem.SRAM[1] === 1 & DataMem.SRAM[2] === 1) else $error("fail to turn on all led.");
        assert(halt) else $error("not halted");
        $display("d2s_test cpu only: done");
    end
    
endmodule


module testbench_d2stest_check_led(
    );
    logic clk, reset;

    logic halt;
    logic [2:0] ledval; 
    logic dramWriteEnable, dramReadEnable, dramValid;
    logic [31:0] dramAddress, dramWriteData, dramReadData;

    /*
    // assume in DDR,
    // 24: 123
    // 28: 456
    // 32: 789
    // 34: 5555

    led map
    0x8000_0000: led[0]
    0x8000_0004: led[1]
    0x8000_0008: led[2]
*/
    mips_single_sram_dmac_led #("d2s_test.mem")
      dut(clk, reset, 
        halt,
        ledval,
        dramAddress, dramWriteData,
        dramWriteEnable, dramReadEnable,
        dramReadData,
        dramValid
    );

    initial begin
        dramValid = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;

        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10;
        clk = 1; #10; 
        // $display("deb1, %h", dmaDstAddress);
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramReadEnable) else $error("DRAM read not invoked.");
        assert(dramAddress === 24) else $error("DRAM read address is wrong. %h", dramAddress);

        dramReadData = 123;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        // $display("sramAddr=%h, %b", sramAddressForDMAC, stall);
        clk = 0; #10; clk = 1; #10;
        // $display("sramAddr=%h, %b", sramAddressForDMAC, stall);
        clk = 0; #10; clk = 1; #10;
        // $display("sramAddr=%h", sramAddressForDMAC);
        clk = 0; #10; clk = 1; #10;
        // $display("sramAddr=%h", sramAddressForDMAC);
        clk = 0; #10; clk = 1; #10;
        // $display("sramAddr=%h", sramAddressForDMAC);
        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramAddress === 28);

        dramReadData = 456;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramAddress === 32);

        dramReadData = 789;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        assert(dramAddress === 36);
        dramReadData = 5555;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(ledval === 3'b111) else $error("ledval wrong, %b", ledval);
        assert(halt) else $error("not halted %b", halt);
        $display("d2s_test check led done");
    end
    
endmodule


/*
This is rather test of asm.
*/
module testbench_d2stest_failcase(
    );
    logic clk, reset;

    logic halt;
    logic [2:0] ledval; 
    logic dramWriteEnable, dramReadEnable, dramValid;
    logic [31:0] dramAddress, dramWriteData, dramReadData;

    /*
    // assume in DDR,
    // 24: 123
    // 28: 456
    // 32: 789
    // 34: 5555
    
    // give wrong value for test.

    led map
    0x8000_0000: led[0]
    0x8000_0004: led[1]
    0x8000_0008: led[2]
*/
    mips_single_sram_dmac_led #("d2s_test.mem")
      dut(clk, reset, 
        halt,
        ledval,
        dramAddress, dramWriteData,
        dramWriteEnable, dramReadEnable,
        dramReadData,
        dramValid
    );

    initial begin
        dramValid = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;

        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10;
        clk = 1; #10; 
        // $display("deb1, %h", dmaDstAddress);
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        dramReadData = 111;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        dramReadData = 111;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        dramReadData = 111;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        dramReadData = 111;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(ledval === 3'b101) else $error("ledval wrong, %b", ledval);
        assert(halt) else $error("not halted %b", halt);
        $display("d2s_test check led done");
    end
    
endmodule


module testbench_d2s_simple(
    );
    logic clk, reset;

    logic halt;
    logic [2:0] ledval; 
    logic dramWriteEnable, dramReadEnable, dramValid;
    logic [31:0] dramAddress, dramWriteData, dramReadData;

    /*
    // assume in DDR,
    // 0: 0000ffff
    // 4: 0
    // 8: 1
    // C: XXXXXX

*/
    mips_single_sram_dmac_led #("d2s_simple_test.mem")
      dut(clk, reset, 
        halt,
        ledval,
        dramAddress, dramWriteData,
        dramWriteEnable, dramReadEnable,
        dramReadData,
        dramValid
    );

    initial begin
        dramValid = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;

        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10;
        clk = 1; #10; 
        // $display("deb1, %h", dmaDstAddress);
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramReadEnable) else $error("DRAM read not invoked.");
        assert(dramAddress === 0) else $error("DRAM read address is wrong. %h", dramAddress);

        dramReadData = 32'h0000ffff;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramAddress === 4);

        dramReadData = 0;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramAddress === 8);

        dramReadData = 1;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        assert(dramAddress === 12);
        dramReadData = 5555; // whatever.
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(ledval === 3'b111) else $error("ledval wrong, %b", ledval);
        assert(halt) else $error("not halted %b", halt);
        $display("d2s_simple test done");
    end
    
endmodule

module testbench_d2s_simple_writeback(
    );
    logic clk, reset;

    logic halt;
    logic [2:0] ledval; 
    logic dramWriteEnable, dramReadEnable, dramValid;
    logic [31:0] dramAddress, dramWriteData, dramReadData;

    /*
    // assume in DDR,
    // 0: 0000ffff
    // 4: 0
    // 8: 1
    // C: XXXXXX

*/
    mips_single_sram_dmac_led #("d2s_simple_writeback_test.mem")
      dut(clk, reset, 
        halt,
        ledval,
        dramAddress, dramWriteData,
        dramWriteEnable, dramReadEnable,
        dramReadData,
        dramValid
    );

    initial begin
        dramValid = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;

        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10;
        clk = 1; #10; 
        // $display("deb1, %h", dmaDstAddress);
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramReadEnable) else $error("DRAM read not invoked.");
        assert(dramAddress === 0) else $error("DRAM read address is wrong. %h", dramAddress);

        dramReadData = 32'h0000ffff;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramAddress === 4);

        dramReadData = 0;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramAddress === 8);

        dramReadData = 1;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        assert(dramAddress === 12);
        dramReadData = 5555; // whatever.
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        repeat(0)
            begin
                clk = 0; #10; clk = 1; #10;
            end


        assert(dramWriteEnable) else $error("DRAM write not invoked.");
        assert(dramAddress === 32'h10) else $error("DRAM write address is wrong. %h", dramAddress);
        assert(dramWriteData === 32'h0000ffff) else $error("write data is wrong %h", dramWriteData);
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramWriteEnable) else $error("DRAM write2 not invoked.");
        assert(dramAddress === 32'h14) else $error("DRAM write2 address is wrong. %h", dramAddress);
        assert(dramWriteData === 0) else $error("write2 data is wrong %h", dramWriteData);

        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramWriteEnable) else $error("DRAM write3 not invoked.");
        assert(dramAddress === 32'h18) else $error("DRAM write3 address is wrong. %h", dramAddress);
        assert(dramWriteData === 32'h1) else $error("write3 data is wrong %h", dramWriteData);
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;

        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramAddress === 32'h1C) else $error("DRAM write4 address is wrong. %h", dramAddress);
        // We do not care forth data.

        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
                repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(ledval === 3'b111) else $error("ledval wrong, %b", ledval);
        assert(halt) else $error("not halted %b", halt);
        $display("d2s_simple writeback test done");
    end
    
endmodule

module testbench_s2d_cpuonly(
    );
    logic clk, reset;

    logic halt;
    logic [2:0] ledval; 
    logic dramWriteEnable, dramReadEnable, dramValid;
    logic [31:0] dramAddress, dramWriteData, dramReadData;

    /*
    // copy data to DDR,
    // 0018: 123
    // 001C: 456
    // 0020: 789
    // 0024: 5555

*/
    mips_single_sram_dmac_led #("s2d_test.mem")
      dut(clk, reset, 
        halt,
        ledval,
        dramAddress, dramWriteData,
        dramWriteEnable, dramReadEnable,
        dramReadData,
        dramValid
    );

    initial begin
        dramValid = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;

        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramWriteEnable) else $error("DRAM write not invoked.");
        assert(dramAddress === 32'h18) else $error("DRAM write address is wrong. %h", dramAddress);
        assert(dramWriteData === 123) else $error("write data is wrong %h", dramWriteData);

        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramWriteEnable) else $error("DRAM write2 not invoked.");
        assert(dramAddress === 32'h1C) else $error("DRAM write2 address is wrong. %h", dramAddress);
        assert(dramWriteData === 456) else $error("write2 data is wrong %h", dramWriteData);

        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramWriteEnable) else $error("DRAM write3 not invoked.");
        assert(dramAddress === 32'h20) else $error("DRAM write3 address is wrong. %h", dramAddress);
        assert(dramWriteData === 789) else $error("write3 data is wrong %h", dramWriteData);
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;

        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end
        assert(dramWriteEnable) else $error("DRAM write4 not invoked.");
        assert(dramAddress === 32'h24) else $error("DRAM write4 address is wrong. %h", dramAddress);
        assert(dramWriteData === 5555) else $error("write4 data is wrong %h", dramWriteData);

        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
                repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(halt) else $error("not halted %b", halt);
        $display("s2d test done");
    end
    
endmodule


/* only first data is valid case. */
module testbench_d2s_simple_fail2(
    );
    logic clk, reset;

    logic halt;
    logic [2:0] ledval; 
    logic dramWriteEnable, dramReadEnable, dramValid;
    logic [31:0] dramAddress, dramWriteData, dramReadData;

    /*
    // assume in DDR,
    // 0: 0000ffff
    // 4: 0
    // 8: 1
    // C: XXXXXX

*/
    mips_single_sram_dmac_led #("d2s_simple_test.mem")
      dut(clk, reset, 
        halt,
        ledval,
        dramAddress, dramWriteData,
        dramWriteEnable, dramReadEnable,
        dramReadData,
        dramValid
    );

    initial begin
        dramValid = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;

        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10;
        clk = 1; #10; 
        // $display("deb1, %h", dmaDstAddress);
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramReadEnable) else $error("DRAM read not invoked.");
        assert(dramAddress === 0) else $error("DRAM read address is wrong. %h", dramAddress);

        dramReadData = 32'h0000ffff;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramAddress === 4);

        dramReadData = 32'h5555aaaa;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramAddress === 8);

        dramReadData = 32'haaaa5555;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        assert(dramAddress === 12);
        dramReadData = 1234; // not used.
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(ledval === 3'b001) else $error("ledval wrong, %b", ledval);
        assert(halt) else $error("not halted %b", halt);
        $display("d2s_simple fail case test done");
    end
    
endmodule

module testbench_jtag_adapter(
    );
    logic clk, reset;

    logic [31:0] dramAddress, dramReadData, dramWriteData;
    logic dramWriteEnable, dramReadEnable, dramValid;

    logic [3:0]m_axi_awid;
    logic [31:0]m_axi_awaddr;
    logic [7:0]m_axi_awlen;
    logic [2:0]m_axi_awsize;
    logic [1:0]m_axi_awburst;
    logic m_axi_awlock;
    logic [3:0]m_axi_awcache;
    logic [2:0]m_axi_awprot;
    logic m_axi_awvalid;
    logic m_axi_awready;
    logic [31:0]m_axi_wdata;
    logic [3:0]m_axi_wstrb;
    logic m_axi_wlast;
    logic m_axi_wvalid;
    logic m_axi_wready;
    logic [3:0]m_axi_bid;
    logic [1:0]m_axi_bresp;
    logic m_axi_bvalid;
    logic m_axi_bready;
    logic [3:0]m_axi_arid;
    logic [31:0]m_axi_araddr;
    logic [7:0]m_axi_arlen;
    logic [2:0]m_axi_arsize;
    logic [1:0]m_axi_arburst;
    logic m_axi_arlock;
    logic [3:0]m_axi_arcache;
    logic [2:0]m_axi_arprot;
    logic [3:0]m_axi_arqos;
    logic m_axi_arvalid;
    logic m_axi_arready;
    logic [3:0]m_axi_rid;
    logic [31:0]m_axi_rdata;
    logic [1:0]m_axi_rresp;
    logic m_axi_rlast;
    logic m_axi_rvalid;
    logic m_axi_rready;


  jtag_adapter dut (
    .clk(clk),                     // input wire aclk
    .reset(reset),
    .dramAddress(dramAddress), .dramWriteData(dramWriteData),
    .readEnable(dramReadEnable), .writeEnable(dramWriteEnable),
    .dramReadData(dramReadData),
    .dramValid(dramValid),

    .m_axi_awid(m_axi_awid),        // output wire [3 : 0] m_axi_awid
    .m_axi_awaddr(m_axi_awaddr),    // output wire [31 : 0] m_axi_awaddr
    .m_axi_awlen(m_axi_awlen),      // output wire [7 : 0] m_axi_awlen
    .m_axi_awsize(m_axi_awsize),    // output wire [2 : 0] m_axi_awsize
    .m_axi_awburst(m_axi_awburst),  // output wire [1 : 0] m_axi_awburst
    .m_axi_awlock(m_axi_awlock),    // output wire m_axi_awlock
    .m_axi_awcache(m_axi_awcache),  // output wire [3 : 0] m_axi_awcache
    .m_axi_awprot(m_axi_awprot),    // output wire [2 : 0] m_axi_awprot
    .m_axi_awvalid(m_axi_awvalid),  // output wire m_axi_awvalid
    .m_axi_awready(m_axi_awready),  // input wire m_axi_awready
    .m_axi_wdata(m_axi_wdata),      // output wire [31 : 0] m_axi_wdata
    .m_axi_wstrb(m_axi_wstrb),      // output wire [3 : 0] m_axi_wstrb
    .m_axi_wlast(m_axi_wlast),      // output wire m_axi_wlast
    .m_axi_wvalid(m_axi_wvalid),    // output wire m_axi_wvalid
    .m_axi_wready(m_axi_wready),    // input wire m_axi_wready
    .m_axi_bid(m_axi_bid),          // input wire [3 : 0] m_axi_bid
    .m_axi_bresp(m_axi_bresp),      // input wire [1 : 0] m_axi_bresp
    .m_axi_bvalid(m_axi_bvalid),    // input wire m_axi_bvalid
    .m_axi_bready(m_axi_bready),    // output wire m_axi_bready
    .m_axi_arid(m_axi_arid),        // output wire [3 : 0] m_axi_arid
    .m_axi_araddr(m_axi_araddr),    // output wire [31 : 0] m_axi_araddr
    .m_axi_arlen(m_axi_arlen),      // output wire [7 : 0] m_axi_arlen
    .m_axi_arsize(m_axi_arsize),    // output wire [2 : 0] m_axi_arsize
    .m_axi_arburst(m_axi_arburst),  // output wire [1 : 0] m_axi_arburst
    .m_axi_arlock(m_axi_arlock),    // output wire m_axi_arlock
    .m_axi_arcache(m_axi_arcache),  // output wire [3 : 0] m_axi_arcache
    .m_axi_arprot(m_axi_arprot),    // output wire [2 : 0] m_axi_arprot
    .m_axi_arvalid(m_axi_arvalid),  // output wire m_axi_arvalid
    .m_axi_arready(m_axi_arready),  // input wire m_axi_arready
    .m_axi_rid(m_axi_rid),          // input wire [3 : 0] m_axi_rid
    .m_axi_rdata(m_axi_rdata),      // input wire [31 : 0] m_axi_rdata
    .m_axi_rresp(m_axi_rresp),      // input wire [1 : 0] m_axi_rresp
    .m_axi_rlast(m_axi_rlast),      // input wire m_axi_rlast
    .m_axi_rvalid(m_axi_rvalid),    // input wire m_axi_rvalid
    .m_axi_rready(m_axi_rready)     // output wire m_axi_rready
  );

                     
    initial begin
        $display("jtag_adapter test begin");
        dramReadEnable = 0;
        dramWriteEnable = 0;
        m_axi_awready = 0;
        m_axi_wready = 0;
        m_axi_bvalid = 0;
        m_axi_arready = 0;
        m_axi_rvalid = 0;

        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;


        m_axi_awready = 1;
        m_axi_wready = 1;
        m_axi_bvalid = 0;
        m_axi_arready = 1;
        m_axi_rvalid = 0;

        clk = 0; #10; clk = 1; #10;
        assert({m_axi_awvalid, m_axi_wvalid, m_axi_arvalid, m_axi_rready, dramValid} === 0) else $error("initial state is wrong");

        // read request.
        dramReadEnable = 1;
        dramAddress = 12;
        clk = 0; #10; clk = 1; #10;
        assert(m_axi_arvalid === 1) else $error("read address valid not asserted");
        assert(m_axi_rready === 0) else $error("read ready is asserted");
        assert(m_axi_araddr === 12) else $error("read address is wrong");
        assert({m_axi_awvalid, m_axi_wvalid, dramValid} === 0) else $error("read state is wrong");

        // finish ar handshake, wait data.
        clk = 0; #10; clk = 1; #10;
        assert(m_axi_arvalid === 0) else $error("read address valid assert twice wrongly");
        assert(m_axi_rready === 1) else $error("read ready is asserted");


        // data comming.
        m_axi_rid = 1;
        m_axi_rdata = 1234;
        m_axi_rvalid = 1;
        clk = 0; #10; clk = 1; #10;
        assert(m_axi_rready === 0) else $error("read ready is asserted twice after rvalid, wrong.");

        assert(dramReadData === 1234) else $error("read data is wrong");
        assert(dramValid) else $error("not finish reading");
        clk = 0; #10; clk = 1; #10;
        assert(dut.state === 0) else $error("fail to back to DORMANT. %b", dut.state);
        clk = 0; #10; clk = 1; #10;

        $display("jtag_adapter test done");
    end
    
endmodule


module testbench_fifo(
    );
    logic clk, rstn, we, re, full, empty;
    logic[0:1] wdata, rdata;


    cmn_fifo #(.DW(2), .AW(1))
    dut(
    .clk      (clk),
    .rstn     (rstn),
    .we       (we),
    .wdata    (wdata),
    .re       (re),
    .rdata    (rdata),
    .full     (full),
    .empty    (empty)
    );

                     
    initial begin
        we = 0;
        re = 0;
        rstn = 0;
        #10ns;
        rstn = 1;

        clk = 0; #10; clk = 1; #10;
        assert(!full & empty) else $error("init state wrong");

        wdata = 2'b11;
        we = 1;
        clk=0; #10; clk=1; #10;
     
        // this line is fail because AW=1 means 2 depth fifo.
        // assert(full) else $error("not full after write");
        assert(!empty) else $error("empty after write");
        assert(rdata === 2'b11) else $error("top value is different");

        we = 0;
        clk=0; #10; clk=1; #10;
        assert(rdata === 2'b11) else $error("top value is different after we deasserted");
        
        re = 1;
        clk=0; #10; clk=1; #10;
        assert(empty && !full) else $error("state error after read");

        $display("end fifo normal test");

    end
endmodule

module testbench_d2stest_check_led_mock_ddr(
    );
    logic clk, reset;

    logic halt;
    logic [2:0] ledval; 
    logic dramWriteEnable, dramReadEnable, dramValid;
    logic [31:0] dramAddress, dramWriteData, dramReadData;

    logic [3:0]m_axi_awid;
    logic [31:0]m_axi_awaddr;
    logic [7:0]m_axi_awlen;
    logic [2:0]m_axi_awsize;
    logic [1:0]m_axi_awburst;
    logic m_axi_awlock;
    logic [3:0]m_axi_awcache;
    logic [2:0]m_axi_awprot;
    logic m_axi_awvalid;
    logic m_axi_awready;
    logic [31:0]m_axi_wdata;
    logic [3:0]m_axi_wstrb;
    logic m_axi_wlast;
    logic m_axi_wvalid;
    logic m_axi_wready;
    logic [3:0]m_axi_bid;
    logic [1:0]m_axi_bresp;
    logic m_axi_bvalid;
    logic m_axi_bready;
    logic [3:0]m_axi_arid;
    logic [31:0]m_axi_araddr;
    logic [7:0]m_axi_arlen;
    logic [2:0]m_axi_arsize;
    logic [1:0]m_axi_arburst;
    logic m_axi_arlock;
    logic [3:0]m_axi_arcache;
    logic [2:0]m_axi_arprot;
    logic [3:0]m_axi_arqos;
    logic m_axi_arvalid;
    logic m_axi_arready;
    logic [3:0]m_axi_rid;
    logic [31:0]m_axi_rdata;
    logic [1:0]m_axi_rresp;
    logic m_axi_rlast;
    logic m_axi_rvalid;
    logic m_axi_rready;

    /*
    // assume in DDR,
    // 24: 123
    // 28: 456
    // 32: 789
    // 34: 5555

    led map
    0x8000_0000: led[0]
    0x8000_0004: led[1]
    0x8000_0008: led[2]
*/
    mips_single_sram_dmac_led #("d2s_test.mem")
      dut(clk, reset, 
        halt,
        ledval,
        dramAddress, dramWriteData,
        dramWriteEnable, dramReadEnable,
        dramReadData,
        dramValid
    );

  jtag_adapter u_jtag_adapter (
    .clk(clk),                     // input wire aclk
    .reset(reset),
    .dramAddress(dramAddress), .dramWriteData(dramWriteData),
    .readEnable(dramReadEnable), .writeEnable(dramWriteEnable),
    .dramReadData(dramReadData),
    .dramValid(dramValid),

    .m_axi_awid(m_axi_awid),        // output wire [3 : 0] m_axi_awid
    .m_axi_awaddr(m_axi_awaddr),    // output wire [31 : 0] m_axi_awaddr
    .m_axi_awlen(m_axi_awlen),      // output wire [7 : 0] m_axi_awlen
    .m_axi_awsize(m_axi_awsize),    // output wire [2 : 0] m_axi_awsize
    .m_axi_awburst(m_axi_awburst),  // output wire [1 : 0] m_axi_awburst
    .m_axi_awlock(m_axi_awlock),    // output wire m_axi_awlock
    .m_axi_awcache(m_axi_awcache),  // output wire [3 : 0] m_axi_awcache
    .m_axi_awprot(m_axi_awprot),    // output wire [2 : 0] m_axi_awprot
    .m_axi_awvalid(m_axi_awvalid),  // output wire m_axi_awvalid
    .m_axi_awready(m_axi_awready),  // input wire m_axi_awready
    .m_axi_wdata(m_axi_wdata),      // output wire [31 : 0] m_axi_wdata
    .m_axi_wstrb(m_axi_wstrb),      // output wire [3 : 0] m_axi_wstrb
    .m_axi_wlast(m_axi_wlast),      // output wire m_axi_wlast
    .m_axi_wvalid(m_axi_wvalid),    // output wire m_axi_wvalid
    .m_axi_wready(m_axi_wready),    // input wire m_axi_wready
    .m_axi_bid(m_axi_bid),          // input wire [3 : 0] m_axi_bid
    .m_axi_bresp(m_axi_bresp),      // input wire [1 : 0] m_axi_bresp
    .m_axi_bvalid(m_axi_bvalid),    // input wire m_axi_bvalid
    .m_axi_bready(m_axi_bready),    // output wire m_axi_bready
    .m_axi_arid(m_axi_arid),        // output wire [3 : 0] m_axi_arid
    .m_axi_araddr(m_axi_araddr),    // output wire [31 : 0] m_axi_araddr
    .m_axi_arlen(m_axi_arlen),      // output wire [7 : 0] m_axi_arlen
    .m_axi_arsize(m_axi_arsize),    // output wire [2 : 0] m_axi_arsize
    .m_axi_arburst(m_axi_arburst),  // output wire [1 : 0] m_axi_arburst
    .m_axi_arlock(m_axi_arlock),    // output wire m_axi_arlock
    .m_axi_arcache(m_axi_arcache),  // output wire [3 : 0] m_axi_arcache
    .m_axi_arprot(m_axi_arprot),    // output wire [2 : 0] m_axi_arprot
    .m_axi_arvalid(m_axi_arvalid),  // output wire m_axi_arvalid
    .m_axi_arready(m_axi_arready),  // input wire m_axi_arready
    .m_axi_rid(m_axi_rid),          // input wire [3 : 0] m_axi_rid
    .m_axi_rdata(m_axi_rdata),      // input wire [31 : 0] m_axi_rdata
    .m_axi_rresp(m_axi_rresp),      // input wire [1 : 0] m_axi_rresp
    .m_axi_rlast(m_axi_rlast),      // input wire m_axi_rlast
    .m_axi_rvalid(m_axi_rvalid),    // input wire m_axi_rvalid
    .m_axi_rready(m_axi_rready)     // output wire m_axi_rready
  );



    initial begin
        {m_axi_awready, m_axi_wready, m_axi_bid, m_axi_bresp,
        m_axi_bvalid, m_axi_arready, m_axi_rid, m_axi_rdata, m_axi_rresp, m_axi_rvalid, m_axi_rlast} = 0;

        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;

        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10;
        clk = 1; #10; 
        // $display("deb1, %h", dmaDstAddress);
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(dramReadEnable) else $error("DRAM read not invoked.");
        assert(dramAddress === 24) else $error("DRAM read address is wrong. %h", dramAddress);
        assert(m_axi_araddr === 24) else $error("araddr is wrong. %h", m_axi_araddr);


        m_axi_arready = 1;
        clk = 0; #10; clk = 1;
        assert(m_axi_arready & m_axi_arvalid) else $error("arvalid is not asserted");
        #10; clk = 0; #10; clk = 1;
        assert(!(m_axi_arready & m_axi_rvalid)) else $error("ar handshake occure twice");
        #10; clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        m_axi_arready = 0;

        assert(m_axi_rready) else $error("not go to read handshake, rready is deasserted %b", m_axi_rready);
        // $display("jtag_adapter.state=%b", u_jtag_adapter.state);

        m_axi_rdata = 123;
        m_axi_rlast = 1;
        m_axi_rvalid = 1;
        clk = 0; #10; clk = 1; 
        // $display("jtag_adapter.state=%b", u_jtag_adapter.state);
        assert(m_axi_rready & m_axi_rvalid) else $error("read handshake fail, %b, %b", m_axi_rready, m_axi_rvalid);
        #10; clk = 0; #10; clk = 1;
        assert(!(m_axi_rready & m_axi_rvalid)) else $error("read handshake occure twice. master side should de-assert");
        assert(dramValid) else $error("dramValid not asserted");

        m_axi_rvalid = 0;
        // $display("jtag_adapter.state=%b", u_jtag_adapter.state);
        // assert(dramValid);
        // $display("dramValid1=%b", dramValid);
        #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;



        assert(m_axi_araddr === 28) else $error("araddr is wrong. %h", m_axi_araddr);
        m_axi_arready = 1;
        clk = 0; #10; clk = 1;#10;
        m_axi_arready = 0;
        #10; clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        m_axi_rdata = 456;
        m_axi_rlast = 1;
        m_axi_rvalid = 1;
        clk = 0; #10; clk = 1; #10;
        m_axi_rvalid = 0;

        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        assert(m_axi_araddr === 32) else $error("araddr is wrong. %h", m_axi_araddr);
        m_axi_arready = 1;
        clk = 0; #10; clk = 1;#10;
        m_axi_arready = 0;
        #10; clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        m_axi_rdata = 789;
        m_axi_rlast = 1;
        m_axi_rvalid = 1;
        clk = 0; #10; clk = 1; #10;
        m_axi_rvalid = 0;

        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        assert(m_axi_araddr === 36) else $error("araddr is wrong. %h", m_axi_araddr);
        m_axi_arready = 1;
        clk = 0; #10; clk = 1;#10;
        m_axi_arready = 0;
        #10; clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        m_axi_rdata = 5555;
        m_axi_rlast = 1;
        m_axi_rvalid = 1;
        clk = 0; #10; clk = 1; #10;
        m_axi_rvalid = 0;

        repeat(60)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(ledval === 3'b111) else $error("ledval wrong, %b", ledval);
        assert(halt) else $error("not halted %b", halt);
        $display("end testbench_d2stest_check_led_mock_ddr");
    end
    
endmodule

module testbench_dram2dram_copy(
    );
    logic clk, reset;

    logic halt;
    logic [2:0] ledval; 
    logic dramWriteEnable, dramReadEnable, dramValid;
    logic [31:0] dramAddress, dramWriteData, dramReadData;

    mips_single_sram_dmac_led #("dram2dram_copy_test.mem")
      dut(clk, reset, 
        halt,
        ledval,
        dramAddress, dramWriteData,
        dramWriteEnable, dramReadEnable,
        dramReadData,
        dramValid
    );

    initial begin
        dramValid = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;

        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramReadEnable) else $error("dramRead not invoked");
        assert(dramAddress === 0) else $error("dramRead wrong address");

        dramReadData = 123;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;

        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramReadEnable) else $error("dramRead2 not invoked");
        assert(dramAddress === 4) else $error("dramRead2 wrong address");
        dramReadData = 456;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;

        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramReadEnable) else $error("dramRead3 not invoked");
        assert(dramAddress === 8) else $error("dramRead3 wrong address");
        dramReadData = 789;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;

        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramReadEnable) else $error("dramRead4 not invoked");
        assert(dramAddress === 12) else $error("dramRead4 wrong address");
        dramReadData = 5555;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;

        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dut.DataMem.SRAM[0] === 123) else $error("sram[0] wrong");
        assert(dut.DataMem.SRAM[1] === 456) else $error("sram[1] wrong");
        assert(dut.DataMem.SRAM[2] === 789) else $error("sram[2] wrong");
        assert(dut.DataMem.SRAM[3] === 5555) else $error("sram[3] wrong");


        assert(dramWriteEnable) else $error("DRAM write not invoked.");
        assert(dramAddress === 32'h10) else $error("DRAM write address is wrong. %h", dramAddress);
        assert(dramWriteData === 123) else $error("write data is wrong %h", dramWriteData);

        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramWriteEnable) else $error("DRAM write2 not invoked.");
        assert(dramAddress === 32'h14) else $error("DRAM write2 address is wrong. %h", dramAddress);
        assert(dramWriteData === 456) else $error("write2 data is wrong %h", dramWriteData);

        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dramWriteEnable) else $error("DRAM write3 not invoked.");
        assert(dramAddress === 32'h18) else $error("DRAM write3 address is wrong. %h", dramAddress);
        assert(dramWriteData === 789) else $error("write3 data is wrong %h", dramWriteData);
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;

        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end
        assert(dramWriteEnable) else $error("DRAM write4 not invoked.");
        assert(dramAddress === 32'h1C) else $error("DRAM write4 address is wrong. %h", dramAddress);
        assert(dramWriteData === 5555) else $error("write4 data is wrong %h", dramWriteData);

        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
                repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(halt) else $error("not halted %b", halt);
        $display("dram2dram copy test done");
    end
    
endmodule
