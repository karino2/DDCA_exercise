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
    assign Jump = Opcode == 6'b000010;     
endmodule

/*
module romcode #(parameter FILENAME="romdata.mem")(input logic [13:0] addr,
*/
module fetch_stage #(parameter FILENAME="romdata.mem")
            (input logic clk, reset, Stall, pcSrc,
                input logic [31:0] pcBranch,
                output logic [31:0] pcPlus4, instr);
    logic [31:0] pc, newPC;

    flopr Pcflop(clk, reset, !Stall, newPC, pc);
    romcode #(FILENAME) InstRom(pc[15:2], instr);    
    assign pcPlus4 = pc+4;
    
    always @(posedge clk)
        $display("instr %h", instr);    

    assign newPC = pcSrc? pcBranch: pcPlus4;

endmodule

module fetch2decode(input logic clk, reset, stall, isBranch,
             input logic [31:0] instrF, pcF,
             output logic [31:0] instrD, pcD);
    always_ff @(posedge clk, posedge reset)
        if(reset | isBranch) begin
                pcD <= 32'h0040_0000; // PC reset address.
                instrD <= 0;
            end
        else if(!stall)
            begin
                instrD <= instrF;
                pcD <= pcF;
            end 
endmodule

module decode_stage(input logic clk, reset, regWriteEnable,
                    RegDst, BranchD,
            input logic [31:0] instr,
            input logic [4:0] regWriteAddr,
            input logic [31:0] regWriteData, pcPlus4, aluResM,
            input logic ForwardAD, ForwardBD,
            output logic [31:0] regReadData1, regReadData2, immExtend,
            output logic [4:0] outRegWriteAddr,
            output logic pcSrcD,
            output logic [31:0] pcBranch);

    logic [31:0] eqLeft, eqRight;

    regfile RegFile(clk, instr[25:21], instr[20:16], regWriteAddr, regWriteEnable, regWriteData, regReadData1, regReadData2);
    assign immExtend = {{16{instr[15]}}, instr[15:0]};
    assign outRegWriteAddr = RegDst? instr[15:11] : instr[20:16];
    
    assign eqLeft = ForwardAD ? aluResM : regReadData1;
    assign eqRight = ForwardBD ? aluResM : regReadData2;
    
    assign pcSrcD = BranchD & (eqLeft == eqRight);
    assign pcBranch = {immExtend[29:0], 2'b00}+pcPlus4;    
endmodule


module decode2exec(input logic clk, reset, flush,
            input logic [31:0] regData1D, regData2D,  
                    immExtendD, 
            input logic [4:0] regWriteAddrD, regRsD, regRtD,
            input logic [6:0]  ctrlD,
            output logic [31:0] regData1E, regData2E, 
                    immExtendE, 
            output logic [4:0] regWriteAddrE, regRsE, regRtE,
            output logic [6:0] ctrlE);
    always_ff @(posedge clk, posedge reset)
        if(reset | flush) begin
                regData1E <= 0;
                regData2E <= 0;
                immExtendE <= 0;
                regWriteAddrE <= 0; 
                regRsE <= 0;
                regRtE <= 0;
                ctrlE <= 0; // ctrl should mean nop if everything is false.
            end
        else
            begin
                regData1E <= regData1D;
                regData2E <= regData2D;
                immExtendE <= immExtendD;
                regWriteAddrE <= regWriteAddrD; 
                regRsE <= regRsD;
                regRtE <= regRtD;
                ctrlE <= ctrlD;
            end 
endmodule


module exec_stage(input logic clk, reset, ALUSrc,
                input logic [2:0] ALUCtrl,
                input logic [31:0] regData1, regData2, immExtend, 
                aluResM, regWriteDataW,
                input logic [1:0] ForwardAE, ForwardBE,
                output logic zero,
                output logic [31:0] aluRes, memWriteData);
    logic [31:0] srcB;
    logic [31:0] regData1H, regData2H;
    
    assign regData1H = (ForwardAE == 2'b10) ? aluResM : ((ForwardAE == 2'b01) ? regWriteDataW : regData1);
    assign regData2H = (ForwardBE == 2'b10) ? aluResM : ((ForwardBE == 2'b01) ? regWriteDataW : regData2);
    assign memWriteData = regData2H;
    always @(posedge clk)
        begin
            $display("regData1H=%h, regData2H=%h, regData1=%h, regData2=%h, immExtend=%h",
                        regData1H, regData2H, regData1, regData2, immExtend);
        end
    
    
    mux2 MuxSrcB(regData2H, immExtend, ALUSrc, srcB); 
    
    logic cout;
    alu Alu(regData1H, srcB, ALUCtrl, cout, zero, aluRes);

endmodule

module exec2mem(input logic clk, reset, zeroE,
            input logic [31:0] aluResE, memWriteDataE,
            input logic [4:0] regWriteAddrE, 
            input logic [2:0]  ctrlE,
            output logic zeroM,
            output logic [31:0] aluResM, memWriteDataM, 
            output logic [4:0]  regWriteAddrM,
            output logic [2:0]  ctrlM);
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
                zeroM <= 0;
                aluResM <= 0;
                regWriteAddrM <= 0;
                memWriteDataM <= 0;
                ctrlM <= 0;
            end
        else
            begin
                zeroM <= zeroE;
                aluResM <= aluResE;
                regWriteAddrM <= regWriteAddrE;
                memWriteDataM <= memWriteDataE;
                ctrlM <= ctrlE;
            end 
endmodule


module mem_stage(input logic clk, reset, 
                memWriteEnable, 
                input logic [31:0] memAddress, memWriteData,
                output logic [31:0] memReadData);

    sram DataMem(clk, memAddress[13:0], memWriteEnable, memWriteData, memReadData);
endmodule

module mem2writeback(input logic clk, reset,
            input logic [31:0] aluResM, memReadDataM, 
            input logic [4:0] regWriteAddrM,
            input logic [1:0]  ctrlM,
            output logic [31:0] aluResW, memReadDataW,
            output logic [4:0] regWriteAddrW,
            output logic [1:0]  ctrlW);
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
                aluResW <= 0;
                memReadDataW <= 0;
                regWriteAddrW <= 0;
                ctrlW <= 0;
            end
        else
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
    mux2 ResForReg(aluRes, memReadData, MemtoReg, regWriteData);
endmodule

module hazard(input logic [4:0] regRsD, regRtD, regRsE, regRtE,
              input logic ALUSrcD, BranchD,
              input logic [4:0] regWriteAddrE, input logic RegWriteEnableE, input logic MemtoRegE,
              input logic [4:0] regWriteAddrM, input logic RegWriteEnableM, input logic MemtoRegM,
              input logic [4:0] regWriteAddrW, input logic RegWriteEnableW,
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
    
    
    assign StallF = lwstall | branchstall;
    assign StallD = lwstall | branchstall;
    assign FlushE = lwstall | branchstall;
endmodule
                

module mips_pipeline #(parameter FILENAME="mipstest.mem") (
   input logic clk,
    input logic reset
    );

    logic RegWriteEnableD, RegDstD, ALUSrcD, BranchD, MemWriteEnableD, MemtoRegD, JumpD;
    logic [2:0] ALUCtrlD, ALUCtrlE;

    logic RegWriteEnableW, MemtoRegW;
    logic MemWriteEnableM, RegWriteEnableM, MemtoRegM;
    logic ALUSrcE, MemWriteEnableE, RegWriteEnableE, MemtoRegE;

    logic [4:0] regWriteAddrD, regWriteAddrE, regWriteAddrM, regWriteAddrW;
    logic [31:0] pcPlus4F, instrF, pcPlus4D, instrD,
                regData1D, regData2D, immExtendD,
                regData1E, regData2E, immExtendE;

    logic [31:0] memWriteDataE, memWriteDataM;
    logic [31:0] aluResE, aluResM;
    logic zeroE;
    logic zeroM;
    logic [31:0] memReadDataM;
    logic [31:0] aluResW, memReadDataW, regWriteDataW;
    
    logic StallF, StallD, FlushE;
    
    logic [1:0] ForwardAE, ForwardBE;
    logic [4:0] regRsE, regRtE;
    logic pcSrcD, ForwardAD, ForwardBD;
    logic [31:0] pcBranchD;                     
    
    always @(posedge clk)
        begin
            $display("regWE=%h, regDst=%h, ALUSrc=%h, Branch=%h, MemWE=%h, MemReg=%h, ALUCtrl=%h, jump=%h", 
                        RegWriteEnableD, RegDstD, ALUSrcD, BranchD, MemWriteEnableD,
                         MemtoRegD, ALUCtrlD, JumpD);    
            $display("regWAddrD=%h, regWAddrE=%h, regWAddrM=%h, memRDataM=%h, memRDataW=%h", 
                        regWriteAddrD, regWriteAddrE, regWriteAddrM, memReadDataM, memReadDataW);
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
        end

    hazard Hazard(instrD[25:21], instrD[20:16], regRsE, regRtE,
                ALUSrcD, BranchD,
              regWriteAddrE, RegWriteEnableE, MemtoRegE,
              regWriteAddrM, RegWriteEnableM, MemtoRegM,
              regWriteAddrW, RegWriteEnableW,
              ForwardAE, ForwardBE,
              ForwardAD, ForwardBD,
              StallF, StallD, FlushE);
    fetch_stage #(FILENAME) FetchStage(clk, reset, StallF, pcSrcD, pcBranchD, pcPlus4F, instrF);
    fetch2decode Fetch2Decode(clk, reset, StallD, pcSrcD, instrF, pcPlus4F, instrD, pcPlus4D);

    ctrlunit CtrlUnit(instrD[31:26], instrD[5:0], RegWriteEnableD, RegDstD, ALUSrcD, BranchD, MemWriteEnableD,
                     MemtoRegD, ALUCtrlD, JumpD);
                     
    decode_stage DecodeStage(clk, reset, RegWriteEnableW, RegDstD, BranchD, instrD, regWriteAddrW, regWriteDataW,
                          pcPlus4D, aluResM, ForwardAD, ForwardBD,
                             regData1D , regData2D, immExtendD, regWriteAddrD, pcSrcD, pcBranchD);
    decode2exec Decode2Exec(clk, reset, FlushE, regData1D, regData2D, immExtendD, regWriteAddrD,
                             instrD[25:21], instrD[20:16],
                            {ALUCtrlD, ALUSrcD, MemWriteEnableD, RegWriteEnableD, MemtoRegD},
                             regData1E, regData2E, immExtendE, regWriteAddrE,
                              regRsE, regRtE,
                            {ALUCtrlE, ALUSrcE, MemWriteEnableE, RegWriteEnableE, MemtoRegE});
    exec_stage ExecStage(clk, reset, ALUSrcE, ALUCtrlE, regData1E, regData2E, immExtendE, 
                        aluResM, regWriteDataW, ForwardAE, ForwardBE,
                         zeroE, aluResE, memWriteDataE);
    exec2mem Exec2Mem(clk, reset, zeroE, aluResE, memWriteDataE, regWriteAddrE, 
                        {MemWriteEnableE,  RegWriteEnableE, MemtoRegE},
                        zeroM, aluResM,  memWriteDataM, regWriteAddrM,
                        {MemWriteEnableM, RegWriteEnableM, MemtoRegM});
    mem_stage MemStage(clk, reset, MemWriteEnableM,
                        aluResM, memWriteDataM,  memReadDataM);
    mem2writeback Mem2WriteBack(clk, reset, aluResM, memReadDataM, regWriteAddrM,
                        {RegWriteEnableM, MemtoRegM},
                        aluResW, memReadDataW, regWriteAddrW,
                        {RegWriteEnableW, MemtoRegW});
    writeback_stage WriteBackStage(clk, reset, MemtoRegW, aluResW, memReadDataW, regWriteDataW);
 endmodule


