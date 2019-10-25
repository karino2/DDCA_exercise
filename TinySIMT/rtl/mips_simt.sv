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


module minPC(input logic [7:0] pc0, pc1, pc2, pc3,
            output logic [7:0] pc);
    logic [7:0] inter0, inter1;
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

module address_stage_core
        (input logic clk, reset, Stall, isInitBubble,
            input logic [1:0] pcSrc,
            input logic [7:0] inPC_D, pcBranch, pcJump,
            output logic [7:0] curPC);

    always_ff @(posedge clk, posedge reset)
        if(reset) begin
            curPC <= 8'b0;
        end
        else if(!Stall) begin
            case(pcSrc)
                2'b01:
                    curPC <= pcBranch;
                2'b10:
                    curPC <= pcJump;
                default:
                    if((inPC_D == curPC) & !isInitBubble)
                        curPC <= curPC+1;
            endcase
        end

endmodule

module address2fetch_core(input logic clk, reset, stall, 
             input logic [1:0] pcSrcD,
             input logic haltingA, 
             output logic [1:0] pcSrcDNext,
             output logic haltingF);
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
                pcSrcDNext <= 0;
                haltingF <= 0;
            end
        else if(!stall)
            begin
                pcSrcDNext <= pcSrcD;
                haltingF <= haltingA;
            end 
endmodule



module fetch2decode(input logic clk, reset, stall, flush,
             input logic [31:0] instrF,
             input logic [7:0] inPC,
             input logic haltingF, 
             output logic [31:0] instrD,
             output logic [7:0] inPC_D,
             output logic haltingD);
    always_ff @(posedge clk, posedge reset)
        if(reset | flush) begin
                inPC_D <= 8'b0;
                instrD <= 0;
                haltingD <= 0;
            end
        else if(!stall)
            begin
                instrD <= instrF;
                inPC_D <= inPC;
                haltingD <= haltingF;
            end 
endmodule

module decode_stage #(parameter TID=0)(input logic clk, reset, regWriteEnable,
                    RegDst, BranchD, IsZeroImm,
            input logic [31:0] instr,
            input logic [4:0] regWriteAddr,
            input logic [31:0] regWriteData, 
            input logic [7:0] pcPlus4,
            input logic [31:0] aluResM,
            input logic ForwardAD, ForwardBD,
            output logic [31:0] regReadData1, regReadData2, immExtend,
            output logic [4:0] shamt,
            output logic [4:0] outRegWriteAddr,
            output logic isBranch,
            output logic [7:0] pcBranch, pcJump);

    logic [31:0] eqLeft, eqRight;

    regfileTID #(TID) RegFile(clk, instr[25:21], instr[20:16], regWriteAddr, regWriteEnable, regWriteData, regReadData1, regReadData2);
    assign immExtend = IsZeroImm ? {16'b0, instr[15:0]} :  {{16{instr[15]}}, instr[15:0]};
    assign outRegWriteAddr = RegDst? instr[15:11] : instr[20:16];
    
    assign eqLeft = ForwardAD ? aluResM : regReadData1;
    assign eqRight = ForwardBD ? aluResM : regReadData2;
    
    assign isBranch = BranchD & (eqLeft == eqRight);
    /*
    assign pcBranch = {immExtend[27:0], 2'b00}+pcPlus4;
    assign pcJump = {pcPlus4[31:28], instr[25:0], 2'b00};
    */
    assign pcBranch = {immExtend[7:0]}+pcPlus4;
    assign pcJump = {instr[7:0]};
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
                output logic [31:0] aluRes, shiftRes, mulRes, memWriteData);
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
    alu Alu(regData1, srcB, ALUCtrl[2:0], cout, zero, aluRes);

    assign mulRes = regData1*immExtend[16:0];

    /*
    //  ShiftCtrl:
    // 2'b01: sll
    // 2'b10: srl
    */
    always_comb
        case(ShiftCtrl)
            2'b01: shiftRes = regData2 << shamt;
            2'b10: shiftRes = regData2 >> shamt;
            default shiftRes = 32'b0;
        endcase
endmodule

// isShift, isMul
module exec2mem(input logic clk, reset, stall, zeroE,
            input logic [31:0] aluResE, shiftResE, mulResE, memWriteDataE, immExtendE,
                regData1E, regData2E,
            input logic [4:0] regWriteAddrE, 
            input logic [8:0]  ctrlE,
            output logic zeroM,
            output logic [31:0] aluResM, shiftResM, mulResM, memWriteDataM, immExtendM,
                regData1M, regData2M,
            output logic [4:0]  regWriteAddrM,
            output logic [8:0]  ctrlM);
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
                zeroM <= 0;
                aluResM <= 0;
                shiftResM <= 0;
                mulResM <= 0;
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
                shiftResM <= shiftResE;
                mulResM <= mulResE;
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
              output logic StallA, StallF, StallD, FlushE);
    assign ForwardAE = ((regRsE != 0) & RegWriteEnableM & (regRsE == regWriteAddrM))? 2'b10 :
                        (((regRsE != 0)& RegWriteEnableW & (regRsE == regWriteAddrW))? 2'b01 : 2'b00); 
    assign ForwardBE = ((regRtE != 0) & RegWriteEnableM & (regRtE == regWriteAddrM))? 2'b10 :
                        (((regRtE != 0)& RegWriteEnableW & (regRtE == regWriteAddrW))? 2'b01 : 2'b00); 
                        
    assign ForwardAD = ((regRsD != 0) & (regRsD == regWriteAddrM) & RegWriteEnableM)? 1: 0;
    assign ForwardBD = ((regRtD != 0) & (regRtD == regWriteAddrM) & RegWriteEnableM)? 1: 0;
                            
    logic lwstall, branchstall, branchStallALU, branchStallLw;
    
    // Take care of XXXXX case.
    assign lwstall =  (MemtoRegE & ((regRsD == regWriteAddrE) | ((regRtD == regWriteAddrE ) & ALUSrcD == 0))) ? 1: 0;
    assign branchStallALU = (BranchD & RegWriteEnableE & (regWriteAddrE != 0) & ((regWriteAddrE == regRsD) | (regWriteAddrE == regRtD))) ? 1: 0;
    assign branchStallLw = (BranchD & 
                ((MemtoRegE & ((regWriteAddrE == regRsD) | (regWriteAddrE == regRtD)) ) | 
                  (MemtoRegM & ((regWriteAddrM == regRsD) | (regWriteAddrM == regRtD))))) ? 1: 0;
    assign branchstall = branchStallALU | branchStallLw; 
    
    
    assign StallA = lwstall | branchstall | Halt;
    assign StallF = lwstall | branchstall | Halt;
    assign StallD = lwstall | branchstall | Halt;
    assign FlushE = lwstall | branchstall | JumpD;
endmodule
                

module simt_core #(parameter TID=0) (
    input logic clk,
    input logic reset, dmaStall, somebodyStallA,
    input logic [31:0] inInstrF,
    input logic [7:0] inPC_F,
    input logic [31:0] sramReadData,
    output logic [7:0] curPC,
    output logic StallA, 
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
    logic [31:0] instrF, instrD, instrDCand, regData1D, regData2D, immExtendD,                
                regData1E, regData2E, regData1EDash, regData2EDash, immExtendE, 
                regData1M, regData2M, immExtendM;
                // dash means after resolve forwarding.


    logic [31:0] memWriteDataE, memWriteDataM;
    logic [31:0] aluResE, aluResM, shiftResE, shiftResM, mulResE, mulResM, aluResMCand;
    logic zeroE, zeroM,  isShiftM, isMulM;
    logic [31:0] memReadDataM;
    logic [31:0] aluResW, memReadDataW, regWriteDataW;
    logic [4:0] shamtD, shamtE;
    
    logic StallF, StallD, FlushE;
    logic [7:0] inPC_D;
    logic isInitBubble;
    
    logic [1:0] ForwardAE, ForwardBE;
    logic [4:0] regRsE, regRtE;
    logic [1:0] pcSrcD, pcSrcDNext;
    logic ForwardAD, ForwardBD;
    logic [7:0] pcBranchD, pcJumpD;                     

    logic halting, haltingF, haltingD, HaltD, HaltE, HaltM, HaltW;
    logic ImmtoRegD, ImmtoRegE, ImmtoRegM;
    logic IsZeroImmD;
    logic [1:0] DmaCmdD, DmaCmdE, DmaCmdM;

    assign halting = HaltD|HaltE|HaltM|HaltW | halt;

/*
                       aluResW, memReadDataW, regWriteAddrW,
                        {RegWriteEnableW, MemtoRegW, HaltW});
 */
    always @(posedge clk)
        begin
            if(MemtoRegW)
                $display("(%01d), rdataW=%h", TID, memReadDataW);
            if(MemtoRegM)
                $display("(%01d), raddrM=%h, %h", TID, aluResM, aluResM[15:2]);
        end
        /*
    always @(posedge clk)
        begin
            $display("(%01d)", TID);
            $display("inInstrF=%h, inPC_F=%h, curPC=%h", inInstrF, inPC_F, curPC);
            $display("StallA=%b, b=%b, pcSrcD=%b, pcBranchD=%h, pcJD=%h", StallA, BranchD, pcSrcD, pcBranchD, pcJumpD);
            $display("pcSrcDNext=%b, haltingF", pcSrcDNext, haltingF);
            $display("inPC_D=%h, curPC_D=%h, curPC=%h, inPC=%h", inPC_D, curPC_D, curPC, inPC_F);
            $display("instrD=%h, immExtendD=%h, immExtendE=%h, dstall=%b, flush=%b", instrD, immExtendD, immExtendE, dmaStall, FlushE);
            $display("ForwardAE=%b, ForwardBE=%b, StallF=%b", 
                        ForwardAE, ForwardBE, StallF);
            $display("aluRes: E=%h, M=%h, W=%h", aluResE, aluResM, aluResW);
            $display("regData1D=%h, regData2D=%h, regData1E=%h, regData2E=%h,", 
                        regData1D, regData2D, regData1E, regData2E);
            $display("RegWriteEnable: D=%b, E=%b, M=%b, W=%b", RegWriteEnableD, RegWriteEnableE, RegWriteEnableM, RegWriteEnableW);
            $display("RegWriteEAddr: D=%h, E=%h, M=%h, W=%h", regWriteAddrD, regWriteAddrE, regWriteAddrM, regWriteAddrW);
            $display("");
        end
            $display("regWE=%h, regDst=%h, ALUSrc=%h, Branch=%h, MemWE=%h, MemReg=%h, ALUCtrl=%h, jump=%h, dmaStall=%b", 
                        RegWriteEnableD, RegDstD, ALUSrcD, BranchD, MemWriteEnableD,
                         MemtoRegD, ALUCtrlD, JumpD, dmaStall);    
            $display("Mem: we=%b, daddr=%h, wdata=%h, rdata=%h, dmaCmd=%b", MemWriteEnableM, aluResM, memWriteDataM, sramReadData, DmaCmdM);
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
              StallA, StallF, StallD, FlushE);

    // forbidden to place nop in beggining.
    assign isInitBubble = (curPC == 0) & (instrDCand === 0);


    address_stage_core AddressStage(clk, reset, somebodyStallA|dmaStall, isInitBubble, pcSrcD, inPC_D, pcBranchD, pcJumpD, curPC);
    address2fetch_core Address2FetchCore(clk, reset, StallD | dmaStall, pcSrcD, halting, pcSrcDNext, haltingF);

    // fetch stage in core.
    assign instrF = (pcSrcDNext[0] | pcSrcDNext[1] |haltingF) ? 32'b0 : inInstrF;

    fetch2decode Fetch2Decode(clk, reset, StallD | dmaStall, (!StallD & (pcSrcD[0] | pcSrcD[1])), instrF, inPC_F, haltingF, instrDCand, inPC_D, haltingD);

    assign instrD = (inPC_D != curPC) ? 32'b0 : instrDCand;


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
                          curPC+8'b1, aluResMCand, ForwardAD, ForwardBD,
                             regData1D , regData2D, immExtendD, shamtD, regWriteAddrD, pcSrcD[0], pcBranchD, pcJumpD);
    assign pcSrcD[1] = JumpD;
    decode2exec Decode2Exec(clk, reset, ((inPC_D != curPC) | FlushE) & !dmaStall, dmaStall, regData1D, regData2D, immExtendD, shamtD,
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
                         zeroE, aluResE, shiftResE, mulResE, memWriteDataE);
    exec2mem Exec2Mem(clk, reset, dmaStall, zeroE, aluResE, shiftResE, mulResE, 
                        memWriteDataE, immExtendE, regData1EDash, regData2EDash, regWriteAddrE, 
                        {(ShiftCtrlE != 2'b00), ALUCtrlE[3],  MemWriteEnableE,  RegWriteEnableE, MemtoRegE, HaltE, DmaCmdE, ImmtoRegE},
                        zeroM, aluResMCand, shiftResM, mulResM, memWriteDataM, immExtendM, regData1M, regData2M, regWriteAddrM,
                        {isShiftM, isMulM, MemWriteEnableM, RegWriteEnableM, MemtoRegM, HaltM, DmaCmdM, ImmtoRegM});

    // execstage is tight timing, move mulResM next stage.
    // assign mulResM =  regData1M*immExtendM;


    /*
        mem_stage MemStage(clk, reset, MemWriteEnableM,
                        aluResM, memWriteDataM,  memReadDataM);
        MemStage now go outside of CPU.
    */    
    assign sramWriteEnable = MemWriteEnableM;


 

    assign sramDataAddress = ImmtoRegM? {immExtendM[15:0], 16'b0} :
                    (isShiftM ? shiftResM : aluResMCand);
    assign aluResM = isMulM? mulResM : sramDataAddress;
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

/*

    SIMT group.

 */

module address_stage(input logic clk, reset, stall,
        input logic [7:0] reqPC0, reqPC1, reqPC2, reqPC3, fetchPC_F,
        output logic [7:0] fetchPC
);
    logic [7:0] reqPC;
    minPC u_minPC(reqPC0, reqPC1, reqPC2, reqPC3, reqPC);

    always_ff @(posedge clk, posedge reset)
        if(reset)
            fetchPC <= 8'b0;
        else if(!stall)
            begin
                if(fetchPC_F == reqPC)
                    fetchPC <= fetchPC_F+1;
                else
                    fetchPC <= reqPC;
            end



endmodule

module address2fetch(input logic clk, reset, stall, 
        input logic [7:0] fetchPC_A,
        output logic [7:0] fetchPC_F);
    always_ff @(posedge clk, posedge reset)
        if(reset)
            fetchPC_F <= 8'b1111_1111; // start from -1.
        else if(!stall)
            fetchPC_F <= fetchPC_A;
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

    logic [7:0] fetchPC_A, fetchPC_F, curPC_Req;
    logic [31:0] instrF, instrRead;


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
    logic [7:0] curPC0, curPC1, curPC2, curPC3;
    logic StallA, StallA0, StallA1, StallA2, StallA3;


    address_stage AddressStage(clk, reset, StallA, curPC0, curPC1, curPC2, curPC3, fetchPC_F, fetchPC_A);

    assign StallA = StallA0 | StallA1 | StallA2 | StallA3;
    address2fetch Address2Fetch(clk, reset, StallA | dmaStall, fetchPC_A, fetchPC_F);

    romcode #(FILENAME) InstRom({2'b00, fetchPC_F}, instrRead);

    /*
    always @(posedge clk)
        begin
            $display("fetchPC_A=%h, F=%h, instrRead=%h, instrF=%h, curPC=%h, %h, %h, %h", fetchPC_A, fetchPC_F, instrRead, instrF, curPC0, curPC1, curPC2, curPC3);
        end
        */

    // reset time first instruction ignore.
    assign instrF = (dmaStall | (fetchPC_F == -1)) ? 0 : instrRead;

    // now only support one DMA request at a time. So only one core may issue DMA.
    always_comb
        if(dmaCmd1 != 2'b0)
            begin
                dmaSrcAddress = dmaSrcAddress1;
                dmaDstAddress = dmaDstAddress1;
                dmaWidth = dmaWidth1;
                dmaCmd = dmaCmd1;
            end
        else if(dmaCmd2 != 2'b0)
            begin
                dmaSrcAddress = dmaSrcAddress2;
                dmaDstAddress = dmaDstAddress2;
                dmaWidth = dmaWidth2;                
                dmaCmd = dmaCmd2;
            end
        else if(dmaCmd3 != 2'b0)
            begin
                dmaSrcAddress = dmaSrcAddress3;
                dmaDstAddress = dmaDstAddress3;
                dmaWidth = dmaWidth3;
                dmaCmd = dmaCmd3;
            end
        else
            begin
                // default: map to first core.
                dmaSrcAddress = dmaSrcAddress0;
                dmaDstAddress = dmaDstAddress0;
                dmaWidth = dmaWidth0;
                dmaCmd = dmaCmd0;
            end

    // always halt simultaneously if code is correct, but use | for safety.
    assign halt = halt0 | halt1 | halt2 | halt3;

    simt_core #(0) core0(clk, reset, dmaStall, StallA,
     instrF, fetchPC_F, sramReadData0,
     curPC0, StallA0, sramDataAddress0, sramWriteData0, sramWriteEnable0,
     dmaCmd0, dmaSrcAddress0, dmaDstAddress0, dmaWidth0, halt0);

    simt_core #(1) core1(clk, reset, dmaStall, StallA,
     instrF, fetchPC_F, sramReadData1,
     curPC1, StallA1, sramDataAddress1, sramWriteData1, sramWriteEnable1,
     dmaCmd1, dmaSrcAddress1, dmaDstAddress1, dmaWidth1, halt1);

    simt_core #(2) core2(clk, reset, dmaStall, StallA,
     instrF, fetchPC_F, sramReadData2,
     curPC2, StallA2, sramDataAddress2, sramWriteData2, sramWriteEnable2,
     dmaCmd2, dmaSrcAddress2, dmaDstAddress2, dmaWidth2, halt2);

    simt_core #(3) core3(clk, reset, dmaStall, StallA,
     instrF, fetchPC_F,  sramReadData3,
     curPC3, StallA3, sramDataAddress3, sramWriteData3, sramWriteEnable3,
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