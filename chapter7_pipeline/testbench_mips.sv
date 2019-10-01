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


module testbench_mipstest_add(
    );
    logic clk, reset;

    mips_pipeline #("mipstest_add.mem") dut(clk, reset);
    
    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
        clk = 0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10;
        assert(dut.DecodeStage.RegFile.regs[3] == 32'd8) else $error("fail reg3 add, %b", dut.DecodeStage.RegFile.regs[3]);
        $display("mips add test done");
    end
    
endmodule


module testbench_mipstest_lwsw(
    );
    logic clk, reset;

    mips_pipeline #("mipstest_lwsw.mem") dut(clk, reset);
    
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
        assert(dut.DecodeStage.RegFile.regs[5] == 32'd8) else $error("fail reg5 lwsw, %b", dut.DecodeStage.RegFile.regs[5]);
        $display("mips lwsw test done");
    end
    
endmodule

module testbench_mipstest_beq(
    );
    logic clk, reset;

    mips_pipeline #("mipstest_beq.mem") dut(clk, reset);
                         
    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; #10;
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        clk = 0; #10; clk = 1; #10; clk=0; #10; clk=1; #10; clk=0; #10; clk = 1; #10; 
        $display("mips beq test begin");
        assert(dut.DecodeStage.RegFile.regs[4] === 6) else $error("first jump is occure wrongly, %h", dut.DecodeStage.RegFile.regs[4]);
        assert(dut.DecodeStage.RegFile.regs[5] === 7) else $error("second jump is not occure wrongly, %h", dut.DecodeStage.RegFile.regs[5]);
        assert(dut.DecodeStage.RegFile.regs[6] === 3) else $error("second jump seems jump too much, %h", dut.DecodeStage.RegFile.regs[6]);
        $display("mips beq test end");
    end
    
endmodule

/*
// Test bench writen in text book 7.6.3.
module testbench_mipstest_books(
    );
    logic clk, reset;

    logic [31:0] pc;
    logic [31:0] instr;
    
    romcode #("mipstest.mem") InstRom(pc[15:2], instr);
        
    all_without_rom dut(clk, reset, instr, pc);
                     
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
            if(dut.DataMem.SRAM[84] === 7) begin
                $display("Simulation succeeded");
                $stop;
            end
        end    
endmodule
*/