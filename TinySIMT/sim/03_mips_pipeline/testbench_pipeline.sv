`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/28 19:14:05
// Design Name: 
// Module Name: testbench_mips
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module testbench_ctrlunit();
    logic [5:0] Opcode, Funct;
    logic RegWrite, RegDst, ALUSrc, Branch; 
    logic MemWrite, MemtoReg, Jump;
    logic [2:0] ALUCtrl;
    
    ctrlunit dut(Opcode, Funct, RegWrite, RegDst, ALUSrc, Branch, MemWrite, MemtoReg, ALUCtrl, Jump);
    
    initial begin
        // add
        Opcode = 0; Funct = 6'd32; #10;
        assert(RegWrite & RegDst & ~ALUSrc & ~Branch & ~MemWrite & ~MemtoReg & (ALUCtrl == 3'b010) & ~Jump) else $error("fail add");
        // sub
        Funct = 6'd34; #10;
        assert(RegWrite & RegDst & ~ALUSrc & ~Branch & ~MemWrite & ~MemtoReg & (ALUCtrl == 3'b110) & ~Jump) else $error("fail sub");
        
        // beq
        Opcode = 6'b000100; Funct = 0; #10;
        assert(~RegWrite & ~ALUSrc & Branch & ~MemWrite & (ALUCtrl == 3'b110) & ~Jump) else $error("fail beq");

        // j
        Opcode = 6'b000010; #10;
        assert(~RegWrite & ~MemWrite & Jump) else $error("fail j");
        
        // lw
        Opcode = 6'b100011; #10;
        assert(RegWrite & ~RegDst & ALUSrc & ~Branch & ~MemWrite & MemtoReg & (ALUCtrl == 3'b010) & ~Jump) else $error("fail lw");
    end

endmodule

module pipeline_with_sram #(parameter FILENAME="mipstest.mem") (
    input logic clk,
    input logic reset, stall,
    output logic halt
    );
    logic [31:0] sramReadData;
    logic [31:0] sramDataAddress, sramWriteData;
    logic sramWriteEnable;
    logic [1:0] dmaCmd; //00: nothing  01: d2s   10:s2d 
    logic [31:0] dmaSrcAddress, dmaDstAddress;
    logic [9:0] dmaWidth;
    
    mips_pipeline #(FILENAME) u_cpu(
        clk, reset, stall,
        sramReadData, sramDataAddress, sramWriteData, sramWriteEnable,
        dmaCmd, //00: nothing  01: d2s   10:s2d 
        dmaSrcAddress, dmaDstAddress, dmaWidth,
        halt
    );
    sram DataMem(clk, sramDataAddress[15:2], sramWriteEnable, sramWriteData, sramReadData);

endmodule


module testbench_mipstest_add(
    );
    logic clk, reset, halt;

    pipeline_with_sram #("mipstest_add.mem") dut(clk, reset, 0, halt);
    
    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
        clk = 0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        assert(dut.u_cpu.DecodeStage.RegFile.regs[3] == 32'd8) else $error("fail reg3 add, %b", dut.u_cpu.DecodeStage.RegFile.regs[3]);
        assert(dut.u_cpu.DecodeStage.RegFile.regs[4] == 32'd11) else $error("fail reg4 add, %b", dut.u_cpu.DecodeStage.RegFile.regs[4]);
        $display("mips add test done");
    end
    
endmodule


module testbench_mipstest_lwsw(
    );
    logic clk, reset, halt;

    pipeline_with_sram #("mipstest_lwsw.mem") dut(clk, reset, 0, halt);
    
    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
        clk = 0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        assert(dut.u_cpu.DecodeStage.RegFile.regs[5] == 32'd8) else $error("fail reg5 lwsw, %b", dut.u_cpu.DecodeStage.RegFile.regs[5]);
        $display("mips lwsw test done");
    end
    
endmodule

module testbench_mipstest_beq(
    );
    logic clk, reset, halt;

    pipeline_with_sram #("mipstest_beq.mem") dut(clk, reset, 0, halt);
                         
    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; #10;
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        $display("mips beq test begin");
        assert(dut.u_cpu.DecodeStage.RegFile.regs[4] === 6) else $error("first jump is occure wrongly, %h", dut.u_cpu.DecodeStage.RegFile.regs[4]);
        assert(dut.u_cpu.DecodeStage.RegFile.regs[5] === 7) else $error("second jump is not occure wrongly, %h", dut.u_cpu.DecodeStage.RegFile.regs[5]);
        assert(dut.u_cpu.DecodeStage.RegFile.regs[6] === 3) else $error("second jump seems jump too much, %h", dut.u_cpu.DecodeStage.RegFile.regs[6]);
        $display("mips beq test end");
    end
    
endmodule

module testbench_mipstest_orand(
    );
    logic clk, reset, halt;

    pipeline_with_sram #("mipstest_orand.mem") dut(clk, reset, 0, halt);
                         
    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; #10;
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        $display("mips orand test begin");
        assert(dut.u_cpu.DecodeStage.RegFile.regs[7] === 3) else $error("addi hazard of $7 fail, %h", dut.u_cpu.DecodeStage.RegFile.regs[7]);
        assert(dut.u_cpu.DecodeStage.RegFile.regs[4] === 7) else $error("or hazard fail, %h", dut.u_cpu.DecodeStage.RegFile.regs[4]);
        assert(dut.u_cpu.DecodeStage.RegFile.regs[5] === 4) else $error("and hazard fail. %h", dut.u_cpu.DecodeStage.RegFile.regs[5]);
        $display("mips orand test end");
    end
    
endmodule



// Test bench writen in text book 7.6.3.
module testbench_mipstest_books(
    );
    logic clk, reset, halt;

    pipeline_with_sram #("mipstest.mem") dut(clk, reset, 1'b0, halt);
                     
    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; #10;
    end

    always
        begin
            clk <= 1; #5; clk <= 0; #5;
        end
        
    always @(negedge clk)
        begin
            // 84
            if(dut.DataMem.SRAM[21] === 7) begin
                $display("Simulation succeeded");
                $stop;
            end
        end    
endmodule



module testbench_mipstest_reset(
    );
    logic clk, reset, halt;

    pipeline_with_sram #("halt_test.mem") dut(clk, reset, 1'b0, halt);
                     
    initial begin
        $display("reset test begin");
        clk = 0; reset = 1; #10; reset = 0; clk = 1; #10;
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        assert(!halt) else $error("wrongly halted before reach to write back stage.");
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        assert(halt) else $error("not halted");

        $display("pc=%h", dut.u_cpu.FetchStage.pc);
        clk = 0; reset = 1; #10; clk=1; #10;
        clk = 0; reset = 0; #10; 
        clk = 1; #10;
        $display("pc=%h", dut.u_cpu.FetchStage.pc);
        $display("reset test end");
    end
endmodule

module testbench_luiori(
    );
    logic clk, reset;

    logic halt;

    pipeline_with_sram #("luiori_test.mem") dut(clk, reset, 1'b0, halt);
                     
    initial begin
        clk = 0; reset = 1; #10; reset = 0; clk = 1; #10;

        repeat(30)
            begin
                clk = 0; #10; clk = 1; #10; 
            end
        assert(dut.u_cpu.DecodeStage.RegFile.regs[1] === 32'h04d2162e) else $error("fail lui ori, %h", dut.u_cpu.DecodeStage.RegFile.regs[1]);
        $display("mips lui ori test done");
    end
    
endmodule


module testbench_ori_unsigned(
    );
    logic clk, reset;

    logic halt;

    pipeline_with_sram #("ori_unsigned.mem") dut(clk, reset, 1'b0, halt);
                     
    initial begin
        clk = 0; reset = 1; #10; reset = 0; clk = 1; #10;

        repeat(30)
            begin
                clk = 0; #10; clk = 1; #10; 
            end
        assert(dut.u_cpu.DecodeStage.RegFile.regs[1] === 32'h0000ffff) else $error("fail ori unsigned, %h", dut.u_cpu.DecodeStage.RegFile.regs[1]);
        $display("ori unsigned test done");
    end
    
endmodule

module testbench_pipeline_d2s_one(
    );
    logic clk, reset;

    logic [31:0] sramReadData, sramAddress, sramWriteData, dmaSrcAddress, dmaDstAddress;
    logic sramWriteEnable, halt, stall;
    logic [1:0] dmaCmd;
    logic [9:0] dmaWidth;    
    sram DataMem(clk, sramAddress[15:2], sramWriteEnable, sramWriteData, sramReadData);

    mips_pipeline #("d2s_one_test.mem") dut(clk, reset, stall, sramReadData, sramAddress, sramWriteData, sramWriteEnable,
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);
                     
    initial begin
        stall = 0;
        clk = 0; reset = 1; #10;
        // $display("next instr address=%h, nextInstr=%h", pc, instr);
        reset = 0; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        assert(dmaCmd === 2'b01) else $error("dmaCmd not invoked.");
        $display("dmaWidth=%h", dmaWidth);
        assert(dmaSrcAddress === 32'd16 & dmaDstAddress === 32'd24) else $error("dmaAddress error., %h, %h", dmaSrcAddress, dmaDstAddress);
        stall = 1;
        // $display("pc=%h, instr=%h, %b", dut.pc, dut.instr, dmaCmd);
        $display("begin stall.");
        repeat(10)
            begin
               clk=0; #10; clk=1; #10;
            end
        clk = 0;
        assert(dut.DecodeStage.RegFile.regs[3] !== 32'd1234) else $error("stall fail");
        $display("stall done.");
        stall = 0;
        #10;
        clk = 1; #10;
        // $display("pc=%h, instr=%h, %b", dut.pc, dut.instr, dmaCmd);
        clk = 0; #10;
        clk = 1; #10; clk = 0; #10;
        assert(dut.DecodeStage.RegFile.regs[3] === 32'd1234) else $error("fail to resume from DMAC. reg3=%b", dut.DecodeStage.RegFile.regs[3]);
        clk = 1; #10; clk = 0; #10;
        $display("d2s one test done");
    end
    
endmodule

module testbench_flopr();
    logic clk, reset, en;
    logic [31:0] nextVal, curVal;
    
    flopr dut(clk, reset, en, nextVal, curVal);
    
    initial begin
        clk = 0;
        en = 1;
        reset = 1; #10;
        reset = 0;
        assert(curVal === 32'h0040_0000) else $error("fail reset, %h", curVal);
        nextVal = 10; #10;
        assert(curVal === 32'h0040_0000) else $error("fail for wait clk");
        clk = 1; #10;
        assert(curVal === 32'd10) else $error("fail for clk, %h", curVal);
    end
endmodule


module testbench_flopr_en();
    logic clk, reset, en;
    logic [31:0] nextVal, curVal;
    
    flopr dut(clk, reset, en, nextVal, curVal);
    
    initial begin
        nextVal = 0;
        clk = 0;
        en = 0;
        reset = 1; #10;
        reset = 0;
        assert(curVal === 32'h0040_0000) else $error("fail reset, %h", curVal);
        clk = 1; #10; clk = 0; #10; clk = 1; #10;
        assert(curVal === 32'h0040_0000) else $error("en deasserted but update curVal.");
        clk = 0; #10 
        en = 1;
        nextVal = 123;
        clk = 1; #10;
        assert(curVal === 32'd123) else $error("fail after en update, %h", curVal);
    end
endmodule


module testbench_d2stest_cpuonly(
    );
    logic clk =0;
    logic reset;

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
    mips_pipeline #("d2s_test.mem") dut(clk, reset, stall, sramReadData, sramAddress, sramWriteData, sramWriteEnable,
                                        dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);


   initial begin
      repeat(200)
        begin
            #5ns clk = ~clk; // 100MHz
        end
      
      $display("test fail");
   end

                     
    initial begin
        stall = 0;
        reset = 1;
        #10ns;
        reset = 0;

        wait(dmaCmd === 2'b01);
        assert(dmaSrcAddress === 32'd24) else $error("dmaAddress error.");
        wait(clk);
        wait(!clk);
        stall = 1;
        // $display("pc=%h, instr=%h, %b", dut.pc, dut.instr, dmaCmd);
        $display("=====");
        $display("begin stall.");
        $display("=====");
        #50ns;

        stall = 0;
        /* 12/4, 16/4, 20/4, 24/4 */
        DataMem.SRAM[3] = 123;
        DataMem.SRAM[4] = 456;
        DataMem.SRAM[5] = 789;
        DataMem.SRAM[6] = 5555;
        $display("=====");
        $display("end stall.");
        $display("=====");
        #300ns;
        // led is wrongly mapped to SRAM[2:0] in testbed.
        assert(DataMem.SRAM[0] ===1 & DataMem.SRAM[1] === 1 & DataMem.SRAM[2] === 1) else $error("fail to turn on all led. mem[0]=%h, mem[1]=%h, mem[2]=%h", DataMem.SRAM[0], DataMem.SRAM[1], DataMem.SRAM[2]);
        assert(halt) else $error("not halted");
        $display("d2s_test cpu only: done");

        $stop(0);
    end
    
endmodule
