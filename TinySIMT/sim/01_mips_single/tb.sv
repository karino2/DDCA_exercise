
// $value$plusargs("arg0=%s", testrom_file);

module testbench_mipstest_add(
    );
    logic clk, reset;

    logic [31:0] sramReadData, sramAddress, sramWriteData, dmaSrcAddress, dmaDstAddress;
    logic sramWriteEnable, halt, dmaValid;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress[13:0], sramWriteEnable, sramWriteData, sramReadData);

    mips_single #("mipstest_add.mem") dut(clk, reset, 1'b0, sramReadData, sramAddress, sramWriteData, sramWriteEnable,
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, dmaValid, halt);
                     
    initial begin
        dmaValid = 0;
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


module testbench_mipssingle_d2s_one(
    );
    logic clk, reset;

    logic [31:0] sramReadData, sramAddress, sramWriteData, dmaSrcAddress, dmaDstAddress;
    logic sramWriteEnable, halt, dmaValid, stall;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress[13:0], sramWriteEnable, sramWriteData, sramReadData);

    mips_single #("d2s_one_test.mem") dut(clk, reset, stall, sramReadData, sramAddress, sramWriteData, sramWriteEnable,
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, dmaValid, halt);
                     
    initial begin
        stall = 0;
        dmaValid = 0;
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
        dmaValid = 1;
        #10;
        clk = 1; #10;
        // $display("pc=%h, instr=%h, %b", dut.pc, dut.instr, dmaCmd);
        clk = 0; #10;
        dmaValid = 0; #10;
        assert(dut.RegFile.regs[3] === 32'd1234) else $error("fail to resume from DMAC. reg3=%b", dut.RegFile.regs[3]);
        clk = 1; #10; clk = 0; #10;
        $display("d2s one test done");
    end
    
endmodule


module testbench_dmac_d2s(
    );
    logic clk, reset;

    logic [31:0] sramReadData, sramAddress, sramWriteData, dmaSrcAddress, dmaDstAddress;
    logic sramWriteEnable, halt, dmaValid, stall;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress[13:0], sramWriteEnable, sramWriteData, sramReadData);
/*
module dma_ctrl(input logic clk, reset, 
                input logic [1:0] cmd,
                input logic [31:0] srcAddr, destAddr,
                input logic [9:0] width,
                input logic [31:0] sramReadData, dramReadData, 
                output logic [13:0] sramAddress,
                output logic [31:0] sramWriteData,
                output logic sramWriteEnable,
                output logic [31:0] dramAddress, dramWriteData,
                output logic dramWriteEnable, dramReadEnable,
                input logic dramValid,
                output logic stall, dmaValid);
*/
    dma_ctrl dut(clk, reset, dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth,
                sramReadData, dramReadData,
                sramAddress, sramWriteData, sramWriteEnable,
                dramAddress, dramWriteData, dramWriteEnable, dramReadEnable,
                dramValid, stall, dmaValid);

                     
    initial begin
        dmaCmd = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;        
        clk = 0; #10; clk = 1; #10;
        assert({stall, dmaValid, sramWriteEnable, dramWriteEnable, dramReadEnable}  === 0) else $error("Dormant state produce wrong signal.");
        assert(dut.state === 0) else $error("initial state is not dormant.");
        $display("dmac d2s test done");
    end
    
endmodule


