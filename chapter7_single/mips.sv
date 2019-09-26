`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/24 16:45:28
// Design Name: 
// Module Name: mips
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

module ctrlunit(input logic [5:0] Opcode, input logic [5:0] Funct, 
    output logic RegWrite, output logic RegDst, output logic ALUSrc, output logic Branch, 
    output logic MemWrite, output logic MemtoReg, output logic [2:0] ALUCtrl, output logic Jump);
    
    assign RegWrite = ((Opcode == 0) | (Opcode == 6'b100011) | (Opcode == 6'b001000));
    assign RegDst = Opcode == 0;
    assign ALUSrc = ((Opcode != 0) & (Opcode != 6'b000100));
    assign Branch = Opcode == 6'b000100;
    assign MemWrite = Opcode == 6'b101011;
    assign MemtoReg = Opcode == 6'b100011;
    assign ALUCtrl = ((Opcode == 6'b000100) | ((Opcode == 0) & (Funct == 6'd34))) ? 3'b110 : 3'b010;
    assign Jump = Opcode == 6'b000010;     
endmodule

/*
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
*/

module mips(input logic clk, reset, input logic [31:0]instr, memReadData,
        output logic [31:0] nextInstrAddress, memDataAddress, memWriteData,
        output logic memWriteEnable);
    logic [31:0] newPC, pc;
    logic RegWrite, RegDst, ALUSrc, Branch; 
    logic MemWrite, MemtoReg, Jump;
    logic [2:0] ALUCtrl;
    
    flopr Pcflop(clk, reset, newPC, pc);
    
    ctrlunit CtrlUnit(instr[31:26], instr[5:0], RegWrite, RegDst, ALUSrc, Branch, MemWrite, MemtoReg, ALUCtrl, Jump);
    
    logic [4:0] a3;
    logic [31:0] rd1, rd2;
    logic [31:0] regRes;    
    
    assign a3 = RegDst? instr[15:11] : instr[20:16]; 
    regfile RegFile(clk, instr[25:21], instr[20:16], a3, RegWrite, regRes, rd1, rd2);
    
    logic [31:0] signImm, srcB, alures;
    
    assign signImm = {{16{instr[15]}}, instr[15:0]};
    
    logic cout, zero;
    
    mux2 MuxSrcB(rd2, signImm, ALUSrc, srcB); 
    
    alu Alu(rd1, srcB, ALUCtrl, cout, zero, alures);

    assign memDataAddress = alures;
    assign memWriteData = rd2;
    assign memWriteEnable = MemWrite;
    
    mux2 ResForReg(alures, memReadData, MemtoReg, regRes);
 
    logic [31:0] pcPlus4, pcBranch, pcCand1, pcJump;
    
    assign pcPlus4 = pc+4;
    assign pcBranch = {signImm[29:0], 4'b0000}+pcPlus4;
    assign pcJump = {pcPlus4[31:28], instr[25:0], 2'b00};
    
    
    assign pcCand1 = (zero & Branch) ? pcBranch : pcPlus4;
    assign newPC = Jump?pcJump : pcCand1;
    assign nextInstrAddress = newPC;
        
endmodule

module all(
    input logic clk,
    input logic reset
    );

    logic [31:0] nextInstrAddress;
    logic [31:0] instr;
    
    romcode InstRom(nextInstrAddress[13:0], instr);
    
    logic [31:0] memReadData, memAddress, memWriteData;
    logic memWriteEnable;        
    sram DataMem(clk, memAddress, memWriteEnable, memWriteData, memReadData);
    
    mips Cpu(clk, reset, instr, memReadData, nextInstrAddress, memAddress, memWriteData, memWriteEnable);
    
endmodule
