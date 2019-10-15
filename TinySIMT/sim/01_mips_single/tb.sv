
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
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, 1'b0, halt);
                     
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
    logic sramWriteEnable, dramWriteEnable, dramReadEnable, dramValid, halt, stall;
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
        assert(sramAddress === 12) else $error("SRAM01 write address is wrong. %h", sramAddress);
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

        dramReadData = 456;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

        dramReadData = 789;
        dramValid = 1;
        clk = 0; #10; clk = 1; #10; 
        dramValid = 0;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;clk = 0; #10; clk = 1; #10; clk = 0; #10; clk = 1; #10;

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

module testbench_jtag_adapter(
    );
    logic clk;

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
        assert(m_axi_rready === 1) else $error("read ready not asserted");
        assert(m_axi_araddr === 12) else $error("read address is wrong");


        assert({m_axi_awvalid, m_axi_wvalid, dramValid} === 0) else $error("read state is wrong");

        // response.
        m_axi_rid = 1;
        m_axi_rdata = 1234;
        m_axi_rvalid = 1;

        clk = 0; #10; clk = 1; #10;
        assert(dramValid) else $error("not finish reading");

        $display("jtag_adapter test done");
    end
    
endmodule
