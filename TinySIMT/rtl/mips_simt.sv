`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/30 09:19:18
// Design Name: 
// Module Name: mips_pipeline
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


module minPC(input logic [31:0] pc0, pc1, pc2, pc3,
            output logic [31:0] pc);
    logic [31:0] inter0, inter1;
    assign inter0 = (pc0<pc1) ? pc0 : pc1;
    assign inter1 = (pc2<pc3) ? pc2: pc3;
    assign pc = (inter0 < inter1) ? inter0: inter1;
endmodule


//  ShiftCtrl:
// 2'b01: sll
// 2'b10: srl
module ctrlunit(input logic [5:0] Opcode, input logic [5:0] Funct, 
    output logic RegWrite, output logic RegDst, output logic IsZeroImm,  output logic ALUSrc, output logic Branch, 
    output logic MemWrite, output logic MemtoReg, output logic ImmtoReg, output logic [3:0] ALUCtrl, output logic [1:0] ShiftCtrl, output logic Jump, output logic Halt,
    output logic [1:0] DmaCmd //00: nothing  01: d2s   02:s2d 
    );
    
    assign RegWrite = ((Opcode == 0)
                     | (Opcode == 6'b100011) // lw
                      | (Opcode == 6'b001000) // addi
                      | (Opcode == 6'b001010) // muli
                    | (Opcode == 6'b001111) // lui
                      | (Opcode == 6'b001100) // andi
                    | (Opcode==6'b001101)); // ori
    assign RegDst = Opcode == 0;
    
    assign IsZeroImm = (Opcode==6'b001101) // ori
                      |(Opcode==6'b001100) ;  // andi

    assign ALUSrc = ((Opcode != 0) &
                     (Opcode != 6'b000100)); //beq
    assign Branch = Opcode == 6'b000100;
    assign MemWrite = Opcode == 6'b101011;
    assign MemtoReg = Opcode == 6'b100011;
    assign ImmtoReg = Opcode == 6'b001111; // lui

    always_comb
        if(Opcode == 6'b0)
            case(Funct)
                6'b0: ShiftCtrl = 2'b01; // sll
                6'b00010: ShiftCtrl = 2'b10; // srl
                default ShiftCtrl = 2'b0;
            endcase
        else
            ShiftCtrl = 2'b0;

    always_comb
        if(Opcode == 6'b000100)
            ALUCtrl = 4'b0110;
        else if(Opcode == 6'b001101) // ori
            ALUCtrl = 4'b0001;
        else if(Opcode == 6'b001100) // andi
            ALUCtrl = 4'b0000;
        else if(Opcode == 6'b001010) // muli
            ALUCtrl = 4'b1000;
        else if(Opcode==6'b0)
            case(Funct)
                6'd34: ALUCtrl = 4'b0110;
                 6'b100100: ALUCtrl = 4'b0000;
                 6'b100101: ALUCtrl = 4'b0001;
                 6'b101010: ALUCtrl = 4'b0111;
                 default: ALUCtrl = 3'b0010;
            endcase
        else
            ALUCtrl = 4'b0010; // lw, sw, etc.

    assign Jump = Opcode == 6'b000010;
    always_comb
        case(Opcode)
            6'b110001: // d2s
                begin
                    DmaCmd = 2'b01;
                end
            6'b111001: // s2d
                begin
                    DmaCmd = 2'b10;
                end
            default:
                begin
                    DmaCmd = 2'b0;
                end
        endcase
    assign Halt = (Opcode == 6'b001110);
endmodule

/*
module romcode #(parameter FILENAME="romdata.mem")(input logic [13:0] addr,
*/

// To keep prefix F.
module fetch_address_stage
        (input logic clk, reset, Stall, Halt,
            input logic [1:0] pcSrc,
            input logic [31:0] inPC, inInstr, pcBranch, pcJump,
            output logic execOtherCore,
            output logic [31:0] pcPlus4, instr, curPC);
    logic [31:0] pc, pcCand, pcBranchCur, pcJumpCur;
    logic [1:0] pcSrcCur;

    // romcode #(FILENAME) InstRom(pc[15:2], instrRead);

    always_ff @(posedge clk, posedge reset)
        if(reset) begin
            pcCand <=  32'h0000_0000; // PC reset address.
            pcSrcCur <= 2'b0;
            pcBranchCur <= 32'h0000_0000;
            pcJumpCur <= 32'h0000_0000;
        end
        else if(!Stall) begin
            pcCand <= (inPC < pc) ? pc : pcPlus4;
            pcSrcCur <= pcSrc;
            pcBranchCur <= pcBranch;
            pcJumpCur <= pcJump;
        end

    assign curPC = pc;

    assign pc = (pcSrcCur == 2'b01) ? pcBranchCur : ((pcSrcCur == 2'b10) ? pcJumpCur : pcCand);
    assign pcPlus4 = pc+4;
    assign execOtherCore = (inPC != pc);
    assign instr = (Halt | execOtherCore) ? 32'b0 : inInstr;

    /*
    always @(posedge clk)
        $display("instr %h, pc=%h, pcSrcCurC=%b, Stall=%b", instr, pc, pcSrcCur, Stall);
    */

    // assign newPC = (pcSrc == 2'b01) ? pcBranch:  ((pcSrc == 2'b10) ? pcJump : pcPlus4);

endmodule



module fetch_stage #(parameter FILENAME="romdata.mem")
            (input logic clk, reset, Stall, Halt,
             input logic [1:0] pcSrc,
                input logic [31:0] pcBranch, pcJump,
                output logic [31:0] pcPlus4, instr);
    logic [31:0] pc, pcCand, /* newPC, */ instrRead, pcBranchCur, pcJumpCur;
    logic [1:0] pcSrcCur;

    // flopr Pcflop(clk, reset, !Stall, newPC, pcCand);
    romcode #(FILENAME) InstRom(pc[15:2], instrRead);

    always_ff @(posedge clk, posedge reset)
        if(reset) begin
            pcCand <=  32'h0000_0000; // PC reset address.
            pcSrcCur = 2'b0;
            pcBranchCur = 32'b0;
            pcJumpCur = 32'b0;
        end
        else if(!Stall) begin
            pcCand <= pcPlus4;
            pcSrcCur <= pcSrc;
            pcBranchCur = pcBranch;
            pcJumpCur = pcJump;
        end



    assign pc = (pcSrcCur == 2'b01) ? pcBranchCur : ((pcSrcCur == 2'b10) ? pcJumpCur : pcCand);
    assign pcPlus4 = pc+4;
    assign instr = Halt ? 32'b0 : instrRead;

    /*
    always @(posedge clk)
        $display("instr %h, pc=%h, pcSrcCurC=%b, Stall=%b", instr, pc, pcSrcCur, Stall);
    */

    // assign newPC = (pcSrc == 2'b01) ? pcBranch:  ((pcSrc == 2'b10) ? pcJump : pcPlus4);

endmodule

module fetch2decode(input logic clk, reset, stall, 
             input logic [1:0] pcSrcD,
             input logic [31:0] instrF, pcF,
             output logic [1:0] pcSrcDNext,
             output logic [31:0] instrD, pcD);
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
                pcD <= 32'h0000_0000; // PC reset address.
                instrD <= 0;
                pcSrcDNext <= 0;
            end
        else if(!stall)
            begin
                instrD <= instrF;
                pcD <= pcF;
                pcSrcDNext <= pcSrcD;
            end 
endmodule

module decode_stage #(parameter TID=0)(input logic clk, reset, regWriteEnable,
                    RegDst, BranchD, IsZeroImm,
            input logic [31:0] instr,
            input logic [4:0] regWriteAddr,
            input logic [31:0] regWriteData, pcPlus4, aluResM,
            input logic ForwardAD, ForwardBD,
            output logic [31:0] regReadData1, regReadData2, immExtend,
            output logic [4:0] shamt,
            output logic [4:0] outRegWriteAddr,
            output logic isBranch,
            output logic [31:0] pcBranch, pcJump);

    logic [31:0] eqLeft, eqRight;

    regfileTID #(TID) RegFile(clk, instr[25:21], instr[20:16], regWriteAddr, regWriteEnable, regWriteData, regReadData1, regReadData2);
    assign immExtend = IsZeroImm ? {16'b0, instr[15:0]} :  {{16{instr[15]}}, instr[15:0]};
    assign outRegWriteAddr = RegDst? instr[15:11] : instr[20:16];
    
    assign eqLeft = ForwardAD ? aluResM : regReadData1;
    assign eqRight = ForwardBD ? aluResM : regReadData2;
    
    assign isBranch = BranchD & (eqLeft == eqRight);
    assign pcBranch = {immExtend[29:0], 2'b00}+pcPlus4;
    assign pcJump = {pcPlus4[31:28], instr[25:0], 2'b00};
    assign shamt = instr[10:6];
endmodule


module decode2exec(input logic clk, reset, flush, stall,
            input logic [31:0] regData1D, regData2D,  
                    immExtendD,
            input logic [4:0] shamtD,
            input logic [4:0] regWriteAddrD, regRsD, regRtD,
            input logic [13:0]  ctrlD,
            output logic [31:0] regData1E, regData2E, 
                    immExtendE, 
            output logic [4:0] shamtE,
            output logic [4:0] regWriteAddrE, regRsE, regRtE,
            output logic [13:0] ctrlE);
    always_ff @(posedge clk, posedge reset)
        if(reset | flush) begin
                regData1E <= 0;
                regData2E <= 0;
                immExtendE <= 0;
                regWriteAddrE <= 0; 
                regRsE <= 0;
                regRtE <= 0;
                shamtE <= 0;
                ctrlE <= 0; // ctrl should mean nop if everything is false.
            end
        else if(!stall)
            begin
                regData1E <= regData1D;
                regData2E <= regData2D;
                immExtendE <= immExtendD;
                regWriteAddrE <= regWriteAddrD; 
                regRsE <= regRsD;
                regRtE <= regRtD;
                ctrlE <= ctrlD;
                shamtE <= shamtD;
            end 
endmodule


module exec_stage(input logic clk, reset, ALUSrc,
                input logic [3:0] ALUCtrl,
                input logic [1:0] ShiftCtrl,
                input logic [31:0] regData1, regData2, immExtend,
                input logic [4:0] shamt,
                output logic zero,
                output logic [31:0] aluRes, memWriteData);
    logic [31:0] srcB, aluRes1;
    
    assign memWriteData = regData2;

    /*
    always @(posedge clk)
        begin
            $display("exec: regData1=%h, regData2=%h, srcB=%h, ALUCtrl=%b, aluRes=%h",
                        regData1, regData2, srcB, ALUCtrl, aluRes);
        end
        */
    
    mux2 MuxSrcB(regData2, immExtend, ALUSrc, srcB); 
    
    logic cout;
    alu2 Alu(regData1, srcB, ALUCtrl, cout, zero, aluRes1);

    /*
    //  ShiftCtrl:
    // 2'b01: sll
    // 2'b10: srl
    */
    always_comb
        case(ShiftCtrl)
            2'b01: aluRes = regData2 << shamt;
            2'b10: aluRes = regData2 >> shamt;
            default aluRes = aluRes1;
        endcase
endmodule

module exec2mem(input logic clk, reset, stall, zeroE,
            input logic [31:0] aluResE, memWriteDataE, immExtendE,
                regData1E, regData2E,
            input logic [4:0] regWriteAddrE, 
            input logic [6:0]  ctrlE,
            output logic zeroM,
            output logic [31:0] aluResM, memWriteDataM, immExtendM,
                regData1M, regData2M,
            output logic [4:0]  regWriteAddrM,
            output logic [6:0]  ctrlM);
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
                zeroM <= 0;
                aluResM <= 0;
                regWriteAddrM <= 0;
                memWriteDataM <= 0;
                immExtendM <= 0;
                regData1M <= 0;
                regData2M <= 0;
                ctrlM <= 0;
            end
        else if(!stall)
            begin
                zeroM <= zeroE;
                aluResM <= aluResE;
                regWriteAddrM <= regWriteAddrE;
                memWriteDataM <= memWriteDataE;
                immExtendM <= immExtendE;
                regData1M <= regData1E;
                regData2M <= regData2E;
                ctrlM <= ctrlE;
            end 
endmodule

/*
Now this is out of CPU.
module mem_stage(input logic clk, reset, 
                memWriteEnable, 
                input logic [31:0] memAddress, memWriteData,
                output logic [31:0] memReadData);

    sram DataMem(clk, memAddress[13:0], memWriteEnable, memWriteData, memReadData);
endmodule
*/

module mem2writeback(input logic clk, reset, stall,
            input logic [31:0] aluResM, memReadDataM, 
            input logic [4:0] regWriteAddrM,
            input logic [2:0]  ctrlM,
            output logic [31:0] aluResW, memReadDataW,
            output logic [4:0] regWriteAddrW,
            output logic [2:0]  ctrlW);
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
                aluResW <= 0;
                memReadDataW <= 0;
                regWriteAddrW <= 0;
                ctrlW <= 0;
            end
        else if(!stall)
            begin
                aluResW <= aluResM;
                memReadDataW <= memReadDataM;
                regWriteAddrW <= regWriteAddrM;
                ctrlW <= ctrlM;
            end 
endmodule


module writeback_stage(input logic clk, reset, 
                        MemtoReg,
                        input logic [31:0] aluRes, memReadData,
                        output logic [31:0] regWriteData);
    assign regWriteData = MemtoReg ? memReadData : aluRes;
endmodule

module hazard(input logic [4:0] regRsD, regRtD, regRsE, regRtE,
              input logic ALUSrcD, BranchD, JumpD,
              input logic [4:0] regWriteAddrE, input logic RegWriteEnableE, input logic MemtoRegE,
              input logic [4:0] regWriteAddrM, input logic RegWriteEnableM, input logic MemtoRegM,
              input logic [4:0] regWriteAddrW, input logic RegWriteEnableW,
              input logic Halt,
              output logic [1:0] ForwardAE, ForwardBE,
              output logic ForwardAD, ForwardBD,
              output logic StallF, StallD, FlushE);
    assign ForwardAE = ((regRsE != 0) & RegWriteEnableM & (regRsE == regWriteAddrM))? 2'b10 :
                        (((regRsE != 0)& RegWriteEnableW & (regRsE == regWriteAddrW))? 2'b01 : 2'b00); 
    assign ForwardBE = ((regRtE != 0) & RegWriteEnableM & (regRtE == regWriteAddrM))? 2'b10 :
                        (((regRtE != 0)& RegWriteEnableW & (regRtE == regWriteAddrW))? 2'b01 : 2'b00); 
                        
    assign ForwardAD = ((regRsD != 0) & (regRsD == regWriteAddrM) & RegWriteEnableM)? 1: 0;
    assign ForwardBD = ((regRtD != 0) & (regRtD == regWriteAddrM) & RegWriteEnableM)? 1: 0;
                            
    logic lwstall, branchstall, branchStallALU, branchStallLw;
    
    // Take care of XXXXX case.
    assign lwstall =  (MemtoRegE & ((regRsD == regWriteAddrE) | ((regRtD == regWriteAddrE ) & ALUSrcD == 0))) ? 1: 0;
    assign branchStallALU = (BranchD & RegWriteEnableE & ((regWriteAddrE == regRsD) | (regWriteAddrE == regRtD))) ? 1: 0;
    assign branchStallLw = (BranchD & 
                ((MemtoRegE & ((regWriteAddrE == regRsD) | (regWriteAddrE == regRtD)) ) | 
                  (MemtoRegM & ((regWriteAddrM == regRsD) | (regWriteAddrM == regRtD))))) ? 1: 0;
    assign branchstall = branchStallALU | branchStallLw; 
    
    
    assign StallF = lwstall | branchstall | Halt;
    assign StallD = lwstall | branchstall | Halt;
    assign FlushE = lwstall | branchstall | JumpD;
endmodule
                

module simt_core #(parameter TID=0) (
    input logic clk,
    input logic reset, dmaStall,
    input logic [31:0] inInstr, inPC,
    input logic [31:0] sramReadData,
    output logic [31:0] curPC,
    output logic [31:0] sramDataAddress, sramWriteData,
    output logic sramWriteEnable,
    output logic [1:0] dmaCmd, //00: nothing  01: d2s   10:s2d 
    output logic [31:0] dmaSrcAddress, dmaDstAddress, 
    output logic [9:0] dmaWidth,
    output logic halt
    );
    logic RegWriteEnableD, RegDstD, ALUSrcD, BranchD, MemWriteEnableD, MemtoRegD, JumpD;
    logic [3:0] ALUCtrlD, ALUCtrlE;
    logic [1:0] ShiftCtrlD, ShiftCtrlE;

    logic RegWriteEnableW, MemtoRegW;
    logic MemWriteEnableM, RegWriteEnableM, MemtoRegM;
    logic ALUSrcE, MemWriteEnableE, RegWriteEnableE, MemtoRegE;

    logic [4:0] regWriteAddrD, regWriteAddrE, regWriteAddrM, regWriteAddrW;
    logic [31:0] pcPlus4F, instrF, pcPlus4D, instrD, pcPlus4DCand, instrDCand,
                regData1D, regData2D, immExtendD,                
                regData1E, regData2E, regData1EDash, regData2EDash, immExtendE, 
                regData1M, regData2M, immExtendM;
                // dash means after resolve forwarding.


    logic [31:0] memWriteDataE, memWriteDataM;
    logic [31:0] aluResE, aluResM, aluResMCand;
    logic zeroE;
    logic zeroM;
    logic [31:0] memReadDataM;
    logic [31:0] aluResW, memReadDataW, regWriteDataW;
    logic [4:0] shamtD, shamtE;
    
    logic StallF, StallD, FlushE;
    logic execOtherCoreF;
    
    logic [1:0] ForwardAE, ForwardBE;
    logic [4:0] regRsE, regRtE;
    logic [1:0] pcSrcD, pcSrcDNext;
    logic ForwardAD, ForwardBD;
    logic [31:0] pcBranchD, pcJumpD;                     

    logic halting, HaltD, HaltE, HaltM, HaltW;
    logic ImmtoRegD, ImmtoRegE, ImmtoRegM;
    logic IsZeroImmD;
    logic [1:0] DmaCmdD, DmaCmdE, DmaCmdM;


    assign halting = HaltD|HaltE|HaltM|HaltW | halt;

    /*
    always @(posedge clk)
        begin
            $display("");
            $display("instrD=%h, immExtendD=%h, immExtendE=%h, dstall=%b, flush=%b", instrD, immExtendD, immExtendE, dmaStall, FlushE);
            $display("regData1D=%h, regData2D=%h, regData1E=%h, regData2E=%h,", 
                        regData1D, regData2D, regData1E, regData2E);
            $display("aluRes: E=%h, M=%h, W=%h", aluResE, aluResM, aluResW);
            $display("Mem: we=%b, daddr=%h, wdata=%h, rdata=%h", MemWriteEnableM, aluResM, memWriteDataM, sramReadData);
            $display("");
        end
        */
        /*
    always @(posedge clk)
        begin
            $display("");
            $display("regWE=%h, regDst=%h, ALUSrc=%h, Branch=%h, MemWE=%h, MemReg=%h, ALUCtrl=%h, jump=%h, dmaStall=%b", 
                        RegWriteEnableD, RegDstD, ALUSrcD, BranchD, MemWriteEnableD,
                         MemtoRegD, ALUCtrlD, JumpD, dmaStall);    
            $display("regWAddrD=%h, regWAddrE=%h, regWAddrM=%h, memRDataM=%h, memRDataW=%h", 
                        regWriteAddrD, regWriteAddrE, regWriteAddrM, memReadDataM, memReadDataW);
            $display("regData1D=%h, regData2D=%h, regData1E=%h, regData2E=%h,", 
                        regData1D, regData2D, regData1E, regData2E);
            $display("regAddr1D=%d, regAddr2D=%d", instrD[25:21], instrD[20:16]);
            $display("regWAddrW=%h, regWDataW=%h, RegWriteEnableW=%h", 
                        regWriteAddrW, regWriteDataW, RegWriteEnableW);
            $display("memWDataE=%h, memWDataM=%h, memWEnableM=%b", 
                        memWriteDataE, memWriteDataM, MemWriteEnableM);
            $display("regData1D=%h, regData2D=%h, regData1E=%h, regData2E", 
                        regData1D, regData2D, regData1E, regData2E);
            $display("aluResE=%h, aluResM=%h, aluResW=%h", 
                        aluResE, aluResM, aluResW);
            $display("ForwardAE=%b, ForwardBE=%b, StallF=%b", 
                        ForwardAE, ForwardBE, StallF);
            $display("");
        end
        */

    hazard Hazard(instrD[25:21], instrD[20:16], regRsE, regRtE,
                ALUSrcD, BranchD, JumpD,
              regWriteAddrE, RegWriteEnableE, MemtoRegE,
              regWriteAddrM, RegWriteEnableM, MemtoRegM,
              regWriteAddrW, RegWriteEnableW,
              halting,
              ForwardAE, ForwardBE,
              ForwardAD, ForwardBD,
              StallF, StallD, FlushE);

    fetch_address_stage FetchStage(clk, reset, StallF|dmaStall, halting, pcSrcD, inPC, inInstr, pcBranchD, pcJumpD, execOtherCoreF, pcPlus4F, instrF, curPC);
    fetch2decode Fetch2Decode(clk, reset, StallD | dmaStall, pcSrcD, instrF, pcPlus4F, pcSrcDNext, instrDCand, pcPlus4DCand);

    /*
        F1->D1->E1
        F2->D2->E2

        execOtherCoreF2 means branch occures in some other thread at the end of D1.
        branchPredict of F1 fail. clear wrong pre-fetching.
    */
    assign instrD = (pcSrcDNext[0] | pcSrcDNext[1] | execOtherCoreF) ? 0 : instrDCand;
    assign pcPlus4D =  (pcSrcDNext[0] | pcSrcDNext[1] | execOtherCoreF) ? 32'h0000_0000 : pcPlus4DCand;

    /*
    always @(posedge clk)
        $display("(%01d) curPC=%h, inPC=%h, pcJumpD=%h, pcBranchD=%h, pcPlus4D=%h, instrD=%h, sdn=%b, eo=%b", TID, curPC, inPC, pcJumpD, pcBranchD, pcPlus4D, instrD, pcSrcDNext, execOtherCoreF);
        */

    always_ff @(posedge clk, posedge reset)
        if(reset)
            halt <= 1'b0;
        else if(HaltW)
            halt <= 1'b1;
    ctrlunit CtrlUnit(instrD[31:26], instrD[5:0], RegWriteEnableD, RegDstD, IsZeroImmD, ALUSrcD, BranchD, MemWriteEnableD,
                     MemtoRegD, ImmtoRegD, ALUCtrlD,ShiftCtrlD,  JumpD, HaltD, DmaCmdD);
                     
    decode_stage #(TID) DecodeStage(clk, reset, RegWriteEnableW, RegDstD, BranchD, IsZeroImmD, instrD, regWriteAddrW, regWriteDataW,
                          pcPlus4D, aluResM, ForwardAD, ForwardBD,
                             regData1D , regData2D, immExtendD, shamtD, regWriteAddrD, pcSrcD[0], pcBranchD, pcJumpD);
    assign pcSrcD[1] = JumpD;
    decode2exec Decode2Exec(clk, reset, FlushE & !dmaStall, dmaStall, regData1D, regData2D, immExtendD, shamtD,
                             regWriteAddrD, instrD[25:21], instrD[20:16],
                            {ALUCtrlD, ShiftCtrlD, ALUSrcD, MemWriteEnableD, RegWriteEnableD, MemtoRegD, HaltD, ImmtoRegD, DmaCmdD},
                             regData1E, regData2E, immExtendE, shamtE,
                              regWriteAddrE, regRsE, regRtE,
                            {ALUCtrlE, ShiftCtrlE, ALUSrcE, MemWriteEnableE, RegWriteEnableE, MemtoRegE, HaltE, ImmtoRegE, DmaCmdE});

    
    // resolve forwarding for exec_stage. we also use this value to d2s and s2d, so calculate outside of stage module.

    assign regData1EDash = (ForwardAE == 2'b10) ? aluResM : ((ForwardAE == 2'b01) ? regWriteDataW : regData1E);
    assign regData2EDash = (ForwardBE == 2'b10) ? aluResM : ((ForwardBE == 2'b01) ? regWriteDataW : regData2E);


    // immExtend, ImmtoReg.
    exec_stage ExecStage(clk, reset, ALUSrcE, ALUCtrlE, ShiftCtrlE, regData1EDash, regData2EDash, immExtendE, shamtE,
                         zeroE, aluResE, memWriteDataE);
    exec2mem Exec2Mem(clk, reset, dmaStall, zeroE, aluResE,
                        memWriteDataE, immExtendE, regData1EDash, regData2EDash, regWriteAddrE, 
                        {MemWriteEnableE,  RegWriteEnableE, MemtoRegE, HaltE, DmaCmdE, ImmtoRegE},
                        zeroM, aluResMCand,  memWriteDataM, immExtendM, regData1M, regData2M, regWriteAddrM,
                        {MemWriteEnableM, RegWriteEnableM, MemtoRegM, HaltM, DmaCmdM, ImmtoRegM});

    /*
        mem_stage MemStage(clk, reset, MemWriteEnableM,
                        aluResM, memWriteDataM,  memReadDataM);
        MemStage now go outside of CPU.
    */    
    assign sramWriteEnable = MemWriteEnableM;

    assign aluResM = ImmtoRegM? {immExtendM[15:0], 16'b0} : aluResMCand;

    assign sramDataAddress = aluResM;
    assign sramWriteData = memWriteDataM;
    assign memReadDataM = sramReadData;

    assign dmaCmd = DmaCmdM;
    // d2s in binary order:
    // op $dramaddr $sramaddr #width
    always_comb
        if((DmaCmdM == 2'b01) | (DmaCmdM == 2'b10) )
            begin
                dmaSrcAddress = regData1M;
                dmaDstAddress = regData2M;
                dmaWidth = immExtendM[9:0];
            end
        else
            begin
                dmaSrcAddress = 0;
                dmaDstAddress = 0;
                dmaWidth = 0;
            end


    mem2writeback Mem2WriteBack(clk, reset, dmaStall,
                         ImmtoRegM? {immExtendM[15:0], 16'b0} : aluResM,
                         memReadDataM,  regWriteAddrM,
                        {RegWriteEnableM, MemtoRegM, HaltM},
                        aluResW, memReadDataW, regWriteAddrW,
                        {RegWriteEnableW, MemtoRegW, HaltW});
    writeback_stage WriteBackStage(clk, reset, MemtoRegW, aluResW, memReadDataW, regWriteDataW);
 endmodule




module simt_group #(parameter FILENAME="romdata.mem")
        (input logic clk, reset, dmaStall,
        // sram core 0
        input logic [31:0] sramReadData0,
        output logic [31:0] sramDataAddress0, sramWriteData0,
        output logic sramWriteEnable0,
        // sram core1
        input logic [31:0] sramReadData1,
        output logic [31:0] sramDataAddress1, sramWriteData1,
        output logic sramWriteEnable1,
        // sram core2
        input logic [31:0] sramReadData2,
        output logic [31:0] sramDataAddress2, sramWriteData2,
        output logic sramWriteEnable2,
        // sram core3
        input logic [31:0] sramReadData3,
        output logic [31:0] sramDataAddress3, sramWriteData3,
        output logic sramWriteEnable3,
        // DMA
        output logic [1:0] dmaCmd, //00: nothing  01: d2s   10:s2d 
        output logic [31:0] dmaSrcAddress, dmaDstAddress, 
        output logic [9:0] dmaWidth,
        output logic halt);

    logic [31:0] curPC, instr, instrRead;


    logic [1:0] dmaCmd0; //00: nothing  01: d2s   10:s2d 
    logic [31:0] dmaSrcAddress0, dmaDstAddress0;
    logic [9:0] dmaWidth0;

    logic [1:0] dmaCmd1; //00: nothing  01: d2s   10:s2d 
    logic [31:0] dmaSrcAddress1, dmaDstAddress1;
    logic [9:0] dmaWidth1;

    logic [1:0] dmaCmd2; //00: nothing  01: d2s   10:s2d 
    logic [31:0] dmaSrcAddress2, dmaDstAddress2;
    logic [9:0] dmaWidth2;

    logic [1:0] dmaCmd3; //00: nothing  01: d2s   10:s2d 
    logic [31:0] dmaSrcAddress3, dmaDstAddress3;
    logic [9:0] dmaWidth3;

    logic halt0, halt1, halt2, halt3;
    logic [31:0] curPC0, curPC1, curPC2, curPC3;


    minPC u_minPC(curPC0, curPC1, curPC2, curPC3, curPC);

    romcode #(FILENAME) InstRom(curPC[15:2], instrRead);

    assign instr = dmaStall ? 0 : instrRead;


    

    // now only support one DMA request at a time. So only one core may issue DMA.
    always_comb
        if(dmaCmd1 != 2'b0)
            begin
                dmaSrcAddress = dmaSrcAddress1;
                dmaDstAddress = dmaDstAddress1;
                dmaWidth = dmaWidth1;                
            end
        else if(dmaCmd2 != 2'b0)
            begin
                dmaSrcAddress = dmaSrcAddress2;
                dmaDstAddress = dmaDstAddress2;
                dmaWidth = dmaWidth2;                
            end
        else if(dmaCmd3 != 2'b0)
            begin
                dmaSrcAddress = dmaSrcAddress3;
                dmaDstAddress = dmaDstAddress3;
                dmaWidth = dmaWidth3;
            end
        else
            begin
                // default: map to first core.
                dmaSrcAddress = dmaSrcAddress0;
                dmaDstAddress = dmaDstAddress0;
                dmaWidth = dmaWidth0;
            end

    // always halt simultaneously if code is correct, but use | for safety.
    assign halt = halt0 | halt1 | halt2 | halt3;

    simt_core #(0) core0(clk, reset, dmaStall,
     instr, curPC, sramReadData0,
     curPC0, sramDataAddress0, sramWriteData0, sramWriteEnable0,
     dmaCmd0, dmaSrcAddress0, dmaDstAddress0, dmaWidth0, halt0);

    simt_core #(1) core1(clk, reset, dmaStall,
     instr, curPC, sramReadData1,
     curPC1, sramDataAddress1, sramWriteData1, sramWriteEnable1,
     dmaCmd1, dmaSrcAddress1, dmaDstAddress1, dmaWidth1, halt1);

    simt_core #(2) core2(clk, reset, dmaStall,
     instr, curPC, sramReadData2,
     curPC2, sramDataAddress2, sramWriteData2, sramWriteEnable2,
     dmaCmd2, dmaSrcAddress2, dmaDstAddress2, dmaWidth2, halt2);

    simt_core #(3) core3(clk, reset, dmaStall,
     instr, curPC,  sramReadData3,
     curPC3, sramDataAddress3, sramWriteData3, sramWriteEnable3,
     dmaCmd3, dmaSrcAddress3, dmaDstAddress3, dmaWidth3, halt3);

endmodule


module simt_sram_dmac_led #(parameter FILENAME="simt_beq_backward.mem")
    (input logic clk, reset, 
        output logic halt,
        output logic [2:0] led,
        output logic [31:0] dramAddress, dramWriteData,
        output logic dramWriteEnable, dramReadEnable,
        input logic [31:0] dramReadData,
        input logic dramValid
    );
    // sram core 0
    logic [31:0] sramReadData0;
    logic [31:0] sramDataAddress0, sramWriteData0;
    logic sramWriteEnable0;
    // sram core1
    logic [31:0] sramReadData1;
    logic [31:0] sramDataAddress1, sramWriteData1;
    logic sramWriteEnable1;
    // sram core2
    logic [31:0] sramReadData2;
    logic [31:0] sramDataAddress2, sramWriteData2;
    logic sramWriteEnable2;
    // sram core3
    logic [31:0] sramReadData3;
    logic [31:0] sramDataAddress3, sramWriteData3;
    logic sramWriteEnable3;
    // DMA
    logic [1:0] dmaCmd; //00: nothing  01: d2s   10:s2d 
    logic [31:0] dmaSrcAddress, dmaDstAddress;
    logic [9:0] dmaWidth;

    logic [13:0] sramDataAddressMain;
    logic [31:0] sramReadDataMain, sramWriteDataMain;
    logic sramWriteEnableMain;

    logic [31:0] sramReadDataBuf;
    logic [13:0] sramAddressForDMAC;
    logic [31:0] sramWriteDataForDMAC;
    logic sramWriteEnableForDMAC;

    logic dmaStall;

    sram_fp DataMem(clk, reset,
            sramDataAddressMain, sramWriteEnableMain, sramWriteDataMain, sramReadDataMain,
//                sramDataAddress0[15:2], sramWriteEnable0, sramWriteData0, sramReadData0,
            sramDataAddress1[15:2], sramWriteEnable1, sramWriteData1, sramReadData1,
            sramDataAddress2[15:2], sramWriteEnable2, sramWriteData2, sramReadData2,
            sramDataAddress3[15:2], sramWriteEnable3, sramWriteData3, sramReadData3);

    simt_group #(FILENAME) u_cpus(clk, reset, dmaStall,
        sramReadData0,
        sramDataAddress0, sramWriteData0,
        sramWriteEnable0,
        // sram core1
        sramReadData1,
        sramDataAddress1, sramWriteData1,
        sramWriteEnable1,
        // sram core2
        sramReadData2,
        sramDataAddress2, sramWriteData2,
        sramWriteEnable2,
        // sram core3
        sramReadData3,
        sramDataAddress3, sramWriteData3,
        sramWriteEnable3,
        // DMA
        dmaCmd, //00: nothing  01: d2s   10:s2d 
        dmaSrcAddress, dmaDstAddress, 
        dmaWidth,
        halt);

    dma_ctrl u_dmac(clk, reset, dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth,
                sramReadDataBuf, dramReadData,
                sramAddressForDMAC, sramWriteDataForDMAC, sramWriteEnableForDMAC,
                dramAddress, dramWriteData, dramWriteEnable, dramReadEnable,
                dramValid, dmaStall);

    /*
    led map
    0x8000_0000: led[0]
    0x8000_0004: led[1]
    0x8000_0008: led[2]
    only first core map to led.
    */
    always_ff @(posedge clk, posedge reset)
        if(reset)
            begin   
                led <= 3'b0;
                sramReadDataBuf <= 32'b0;
            end
        else
            begin
                sramReadDataBuf <= sramReadDataMain;
                if(sramWriteEnable0 & sramDataAddress0[31])
                    case(sramDataAddress0[3:0])
                        4'b0: led[0] <= sramWriteData0[0];
                        4'b100: led[1] <= sramWriteData0[0];
                        4'b1000: led[2] <= sramWriteData0[0];
                    endcase
            end

  always_comb
    if(dmaStall)
      begin
        sramDataAddressMain = sramAddressForDMAC;
        sramWriteEnableMain = sramWriteEnableForDMAC;
        sramWriteDataMain = sramWriteDataForDMAC;
        sramReadData0 = 32'b0;        
      end
    else
      begin
        if(sramDataAddress0[31])
            begin
                sramDataAddressMain = 14'b0;
                sramWriteEnableMain = 0;
                sramWriteDataMain = 32'b0;
                sramReadData0 = 32'b0;        
            end
        else
            begin
                sramDataAddressMain = sramDataAddress0[15:2];
                sramWriteEnableMain = sramWriteEnable0;
                sramWriteDataMain = sramWriteData0;
                sramReadData0 = sramReadDataMain;        
            end
      end


endmodule