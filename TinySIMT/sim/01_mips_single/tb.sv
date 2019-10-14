
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
    logic [3:0] ledval; 
    logic dramWriteEnable, dramReadEnable, dramValid;
    logic [31:0] dramAddress, dramWriteData, dramReadData;
    mips_single_sram_dmac_led #("d2s_test.mem")
      dut(clk, reset, 
        halt,
        ledval,
        dramAddress, dramWriteData,
        dramWriteEnable, dramReadEnable,
        dramReadData,
        dramValid
    );


    /*
    logic [31:0] sramReadData, sramWriteData, dmaSrcAddress, dmaDstAddress,
                dramReadData, dramAddress, dramWriteData;
    logic [13:0] sramAddress, sramAddressForDMAC;
    logic [31:0] sramReadDataForCPU, sramAddressForCPU, sramWriteDataForCPU;
    logic sramWriteEnableForCPU;
    logic [31:0] sramReadDataForDMAC, sramWriteDataForDMAC;
    logic sramWriteEnableForDMAC;

    logic sramWriteEnable, halt, stall, dramWriteEnable, dramReadEnable, dramValid;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress, sramWriteEnable, sramWriteData, sramReadData);
*/
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
/*
    mips_single #("d2s_test.mem") u_cpu(clk, reset, stall, sramReadDataForCPU, sramAddressForCPU, sramWriteDataForCPU, sramWriteEnableForCPU,
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);

    dma_ctrl u_dmac(clk, reset, dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth,
                sramReadDataForDMAC, dramReadData,
                sramAddressForDMAC, sramWriteDataForDMAC, sramWriteEnableForDMAC,
                dramAddress, dramWriteData, dramWriteEnable, dramReadEnable,
                dramValid, stall);

    logic [2:0] ledval;

    always_ff @(posedge clk, posedge reset)
        if(reset)
            ledval <= 3'b0;
        else if(sramWriteEnableForCPU & sramAddressForCPU[31])
            case(sramAddressForCPU[3:0])
                4'b0: ledval[0] <= sramWriteDataForCPU[0];
                4'b100: ledval[1] <= sramWriteDataForCPU[0];
                4'b1000: ledval[2] <= sramWriteDataForCPU[0];
            endcase

  always_comb
    if(stall)
      begin
        sramAddress = sramAddressForDMAC;
        sramWriteEnable = sramWriteEnableForDMAC;
        sramWriteData = sramWriteDataForDMAC;
        sramReadDataForDMAC = sramReadData;
      end
    else
        if(sramAddressForCPU[31])
            begin
                sramAddress = 14'b0;
                sramWriteEnable = 0;
                sramWriteData = 32'b0;
                sramReadDataForCPU = 32'b0;        
            end
        else
            begin
                sramAddress = sramAddressForCPU[15:2];
                sramWriteEnable = sramWriteEnableForCPU;
                sramWriteData = sramWriteDataForCPU;
                sramReadDataForCPU = sramReadData;        
            end
*/

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
        $display("d2s_test check led done");
    end
    
endmodule

