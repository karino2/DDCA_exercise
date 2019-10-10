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
    always_comb
        if(Opcode == 6'b000100)
            ALUCtrl = 3'b110;
        else
            case(Funct)
                6'd34: ALUCtrl = 3'b110;
                 6'b100100: ALUCtrl = 3'b000;
                 6'b100101: ALUCtrl = 3'b001;
                 6'b101010: ALUCtrl = 3'b111;
                 default: ALUCtrl = 3'b010;
            endcase
    /*                     
    assign ALUCtrl = ((Opcode == 6'b000100) | ((Opcode == 0) & (Funct == 6'd34))) ? 3'b110 : 
             (Funct == 6'b100100 ? 3'b000 : (Funct == 6'b100101 ? 3'b001 : (Funct == 6'b101010 ? 3'b111 :   3'b010)));
             */
    assign Jump = Opcode == 6'b000010;     
endmodule


module mips_single #(parameter FILENAME="romdata.mem") 
        (input logic clk, reset, stall,
        input logic [31:0] memReadData,
        output logic [31:0] memDataAddress, memWriteData,
        output logic memWriteEnable);
    logic [31:0] pc, newPC;
    logic [31:0] instr, instrRead;

    flopr Pcflop(clk, reset, !stall, newPC, pc);
    romcode #(FILENAME) InstRom(pc[15:2], instrRead);
    assign instr = stall ? 0 : instrRead;

    always @(posedge clk)
        $display("instr %h", instr);

    /*
    logic [31:0] memReadData, memAddress, memWriteData;
    logic memWriteEnable;
    sram DataMem(clk, memAddress, memWriteEnable, memWriteData, memReadData);
    */
    
    
    logic [4:0] regAddr1, regAddr2, regWriteAddr;
    logic regWriteEnable;
    logic [31:0] regReadData1, regReadData2, regWriteData;
    
    regfile RegFile(clk, regAddr1, regAddr2, regWriteAddr, regWriteEnable, regWriteData, regReadData1, regReadData2);

    logic RegWrite, RegDst, ALUSrc, Branch; 
    logic MemWrite, MemtoReg, Jump;
    logic [2:0] ALUCtrl;
        
    ctrlunit CtrlUnit(instr[31:26], instr[5:0], RegWrite, RegDst, ALUSrc, Branch, MemWrite, MemtoReg, ALUCtrl, Jump);
        
    assign regWriteAddr = RegDst? instr[15:11] : instr[20:16]; 
    assign regAddr1 = instr[25:21];
    assign regAddr2 = instr[20:16];
    assign regWriteEnable = RegWrite;    
    
    logic [31:0] signImm, srcB, alures;
    
    assign signImm = {{16{instr[15]}}, instr[15:0]};
    
    logic cout, zero;
    
    mux2 MuxSrcB(regReadData2, signImm, ALUSrc, srcB); 
    
    alu Alu(regReadData1, srcB, ALUCtrl, cout, zero, alures);

    assign memDataAddress = alures;
    assign memWriteData = regReadData2;
    assign memWriteEnable = MemWrite;
    
    mux2 ResForReg(alures, memReadData, MemtoReg, regWriteData);
 
    logic [31:0] pcPlus4, pcBranch, pcCand1, pcJump;
    
    assign pcPlus4 = pc+4;
    assign pcBranch = {signImm[29:0], 2'b00}+pcPlus4;
    assign pcJump = {pcPlus4[31:28], instr[25:0], 2'b00};
    
    
    assign pcCand1 = (zero & Branch) ? pcBranch : pcPlus4;
    assign newPC = Jump?pcJump : pcCand1;
        
endmodule
