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
    output logic MemWrite, output logic MemtoReg, logic ImmtoReg, output logic [2:0] ALUCtrl, output logic Jump, output logic Halt,
    output logic [1:0] dmaCmd //00: nothing  01: d2s   02:s2d 
    );
    
    assign RegWrite = ((Opcode == 0) | (Opcode == 6'b100011)
         | (Opcode == 6'b001000) // addi
        | (Opcode == 6'b001111) // lui
        | (Opcode==6'b001101)); // ori
    assign RegDst = Opcode == 0;
    assign ALUSrc = ((Opcode != 0) &
         ((Opcode != 6'b000100))); // beq
    assign Branch = Opcode == 6'b000100;
    assign MemWrite = Opcode == 6'b101011;
    assign MemtoReg = Opcode == 6'b100011;
    assign ImmtoReg = Opcode == 6'b001111; // lui
    always_comb
        if(Opcode == 6'b000100)
            ALUCtrl = 3'b110;
        else if(Opcode == 6'b001101) // ori
            ALUCtrl = 3'b001;
        else
            case(Funct)
                6'd34: ALUCtrl = 3'b110;
                 6'b100100: ALUCtrl = 3'b000;
                 6'b100101: ALUCtrl = 3'b001;
                 6'b101010: ALUCtrl = 3'b111;
                 default: ALUCtrl = 3'b010;
            endcase

    always_comb
        case(Opcode)
            6'b110001: // d2s
                begin
                    dmaCmd = 2'b01;
                end
            6'b111001: // s2d
                begin
                    dmaCmd = 2'b10;
                end
            default:
                begin
                    dmaCmd = 2'b0;
                end
        endcase
    /*                     
    assign ALUCtrl = ((Opcode == 6'b000100) | ((Opcode == 0) & (Funct == 6'd34))) ? 3'b110 : 
             (Funct == 6'b100100 ? 3'b000 : (Funct == 6'b100101 ? 3'b001 : (Funct == 6'b101010 ? 3'b111 :   3'b010)));
             */
    assign Jump = Opcode == 6'b000010;
    assign Halt = (Opcode == 6'b001110);
endmodule

module mips_single #(parameter FILENAME="romdata.mem") 
        (input logic clk, reset, stall,
        input logic [31:0] sramReadData,
        output logic [31:0] sramDataAddress, sramWriteData,
        output logic sramWriteEnable,
        output logic [1:0] dmaCmd, //00: nothing  01: d2s   10:s2d 
        output logic [31:0] dmaSrcAddress, dmaDstAddress, 
        output logic [9:0] dmaWidth,
        input logic dmaValid, // notify done.
        output logic halt);
    logic [31:0] rawPC, pc, newPC;
    logic [31:0] instr, instrRead;
    logic halted, Halt;

    flopr Pcflop(clk, reset, !stall & !halted, newPC, rawPC);

    // skip DMA command that already invoked.
    assign pc = dmaValid ? rawPC+4 : rawPC;

    romcode #(FILENAME) InstRom(pc[15:2], instrRead);
    assign instr = stall ? 0 : instrRead;

    assign halt = halted;

    always_ff @(posedge clk, posedge reset)
        if (reset)
            halted <= 0;
        else if (clk)
            if(Halt)
                halted <= 1;

    always @(posedge clk)
        $display("instr %h, pc %h, opcode=%b, dmaCmd=%b", instr, pc, instr[31:26], dmaCmd);

    /*
    logic [31:0] sramReadData, memAddress, sramWriteData;
    logic sramWriteEnable;
    sram DataMem(clk, memAddress, sramWriteEnable, sramWriteData, sramReadData);
    */
    
    
    logic [4:0] regAddr1, regAddr2, regWriteAddr;
    logic regWriteEnable;
    logic [31:0] regReadData1, regReadData2, regWriteData;
    
    regfile_single RegFile(clk, regAddr1, regAddr2, regWriteAddr, regWriteEnable, regWriteData, regReadData1, regReadData2);

    logic RegWrite, RegDst, ALUSrc, Branch; 
    logic MemWrite, MemtoReg, ImmtoReg, Jump;
    logic [2:0] ALUCtrl;
        
    ctrlunit CtrlUnit(instr[31:26], instr[5:0], RegWrite, RegDst, ALUSrc, Branch, MemWrite, MemtoReg, ImmtoReg, ALUCtrl, Jump, Halt, dmaCmd);

    assign regWriteAddr = RegDst? instr[15:11] : instr[20:16]; 
    assign regAddr1 = instr[25:21];
    assign regAddr2 = instr[20:16];
    assign regWriteEnable = RegWrite;    
    
    logic [31:0] signImm, srcB, alures;
    
    assign signImm = {{16{instr[15]}}, instr[15:0]};
    
    logic cout, zero;
    
    mux2 MuxSrcB(regReadData2, signImm, ALUSrc, srcB); 
    
    alu Alu(regReadData1, srcB, ALUCtrl, cout, zero, alures);

    assign sramDataAddress = alures;
    assign sramWriteData = regReadData2;
    assign sramWriteEnable = MemWrite;

    // d2s in binary order:
    // op $dramaddr $sramaddr #width
    always_comb
        if((dmaCmd == 2'b01) | (dmaCmd == 2'b10) )
            begin
                dmaSrcAddress = regReadData1;
                dmaDstAddress = regReadData2;
                dmaWidth = signImm[9:0];
            end
        else
            begin
                dmaSrcAddress = 0;
                dmaDstAddress = 0;
                dmaWidth = 0;
            end
 
    
    assign regWriteData = MemtoReg ? sramReadData : (ImmtoReg? {signImm[15:0], 16'b0} : alures);
 
    logic [31:0] pcPlus4, pcBranch, pcCand1, pcJump;
    
    assign pcPlus4 = pc+4;
    assign pcBranch = {signImm[29:0], 2'b00}+pcPlus4;
    assign pcJump = {pcPlus4[31:28], instr[25:0], 2'b00};
    
    
    assign pcCand1 = (zero & Branch) ? pcBranch : pcPlus4;
    assign newPC = Jump?pcJump : pcCand1;
        
endmodule
