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
            (input logic clk, reset, Branch,
                input logic [31:0] pcBranch,
                output logic [31:0] pcPlus4, instr);
    logic [31:0] pc, newPC;

    flopr Pcflop(clk, reset, newPC, pc);
    romcode #(FILENAME) InstRom(pc[15:2], instr);    
    assign pcPlus4 = pc+4;
    
    always @(posedge clk)
        $display("instr %h", instr);    

    assign newPC = Branch? pcBranch: pcPlus4;

endmodule

module fetch2decode(input logic clk, reset,
             input logic [31:0] instrF, pcF,
             output logic [31:0] instrD, pcD);
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
                pcD <= 32'h0040_0000; // PC reset address.
                instrD <= 0;
            end
        else
            begin
                instrD <= instrF;
                pcD <= pcF;
            end 
endmodule

module decode_stage(input logic clk, reset, regWriteEnable,
                    RegDst,
            input logic [31:0] instr,
            input logic [4:0] regWriteAddr,
            input logic [31:0] regWriteData,
            output logic [31:0] regReadData1, regReadData2, immExtend,
            output logic [4:0] outRegWriteAddr);

    regfile RegFile(clk, instr[25:21], instr[20:16], regWriteAddr, regWriteEnable, regWriteData, regReadData1, regReadData2);
    assign immExtend = {{16{instr[15]}}, instr[15:0]};
    assign outRegWriteAddr = RegDst? instr[15:11] : instr[20:16];
endmodule

module decode2exec(input logic clk, reset,
            input logic [31:0] regData1D, regData2D,  
                    immExtendD, pcPlus4D,
            input logic [4:0] regWriteAddrD,
            input logic [7:0]  ctrlD,
            output logic [31:0] regData1E, regData2E, 
                    immExtendE, pcPlus4E,
            output logic [4:0] regWriteAddrE,
            output logic [7:0] ctrlE);
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
                pcPlus4E <= 32'h0040_0000; // PC reset address. Not used.
                regData1E <= 0;
                regData2E <= 0;
                regWriteAddrE <= 0; 
                immExtendE <= 0;
                pcPlus4E <= 0;
                ctrlE = 0; // ctrl should mean nop if everything is false.
            end
        else
            begin
                pcPlus4E <= pcPlus4D;
                regData1E <= regData1D;
                regData2E <= regData2D;
                regWriteAddrE <= regWriteAddrD; 
                immExtendE <= immExtendD;
                pcPlus4E <= pcPlus4D;
                ctrlE = ctrlD;
            end 
endmodule


module exec_stage(input logic clk, reset, ALUSrc,
                input logic [2:0] ALUCtrl,
                input logic [31:0] regData1, regData2, immExtend, pcPlus4,
                output logic zero,
                output logic [31:0] aluRes, pcBranch);
    // logic [31:0] signImm, srcB, alures;
    logic [31:0] srcB;
    mux2 MuxSrcB(regData2, immExtend, ALUSrc, srcB); 
    
    logic cout;
    alu Alu(regData1, srcB, ALUCtrl, cout, zero, aluRes);

    assign pcBranch = {immExtend[29:0], 2'b00}+pcPlus4;
endmodule

module exec2mem(input logic clk, reset, zeroE,
            input logic [31:0] aluResE, regData2E, pcBranchE,
            input logic [4:0] regWriteAddrE, 
            input logic [3:0]  ctrlE,
            output logic zeroM,
            output logic [31:0] aluResM, regData2M, pcBranchM,
            output logic [4:0]  regWriteAddrM,
            output logic [3:0]  ctrlM);
    always_ff @(posedge clk, posedge reset)
        if(reset) begin
                zeroM <= 0;
                aluResM <= 0;
                regWriteAddrM <= 0;
                regData2M <= 0;
                pcBranchM <= 0;
                ctrlM <= 0;
            end
        else
            begin
                zeroM <= zeroE;
                aluResM <= aluResE;
                regWriteAddrM <= regWriteAddrE;
                regData2M <= regData2E;
                pcBranchM <= pcBranchE;
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


module mips_pipeline #(parameter FILENAME="mipstest.mem") (
   input logic clk,
    input logic reset
    );

    logic RegWriteEnableD, RegDstD, ALUSrcD, BranchD, MemWriteEnableD, MemtoRegD, JumpD;
    logic [2:0] ALUCtrlD, ALUCtrlE;

    logic RegWriteEnableW, MemtoRegW;
    logic MemWriteEnableM, BranchM, RegWriteEnableM, MemtoRegM;
    logic ALUSrcE, MemWriteEnableE, BranchE, RegWriteEnableE, MemtoRegE;

    logic [4:0] regWriteAddrD, regWriteAddrE, regWriteAddrM, regWriteAddrW;
    logic [31:0] pcPlus4F, instrF, pcPlus4D, instrD,
                regData1D, regData2D, immExtendD,
                regData1E, regData2E, immExtendE, pcPlus4E;

    logic [31:0] aluResE, aluResM;
    logic [31:0] pcBranchE;
    logic zeroE;
    logic zeroM;
    logic [31:0] regData2M, pcBranchM, memReadDataM;
    logic [31:0] aluResW, memReadDataW, regWriteDataW;



    fetch_stage #(FILENAME) FetchStage(clk, reset, BranchM, pcBranchM, pcPlus4F, instrF);
    fetch2decode Fetch2Decode(clk, reset, instrF, pcPlus4F, instrD, pcPlus4D);

    ctrlunit CtrlUnit(instrD[31:26], instrD[5:0], RegWriteEnableD, RegDstD, ALUSrcD, BranchD, MemWriteEnableD,
                     MemtoRegD, ALUCtrlD, JumpD);
                     
    always @(posedge clk)
        begin
            $display("regWE=%h, regDst=%h, ALUSrc=%h, Branch=%h, MemWE=%h, MemReg=%h, ALUCtrl=%h, jump=%h", 
                        RegWriteEnableD, RegDstD, ALUSrcD, BranchD, MemWriteEnableD,
                         MemtoRegD, ALUCtrlD, JumpD);    
            $display("regWriteAddrD=%h, regWriteAddrE=%h, regWriteAddrM=%h", 
                        regWriteAddrD, regWriteAddrE, regWriteAddrM);
            $display("aluResE=%h, aluResM=%h, aluResW=%h", 
                        aluResE, aluResM, aluResW);
            $display("regWriteAddrW=%h, regWriteDataW=%h, RegWriteEnableW=%h", 
                        regWriteAddrW, regWriteDataW, RegWriteEnableW);
        end
                     

    decode_stage DecodeStage(clk, reset, RegWriteEnableW, RegDstD, instrD, regWriteAddrW, regWriteDataW,
                             regData1D, regData2D, immExtendD, regWriteAddrD);
    decode2exec Decode2Exec(clk, reset, regData1D, regData2D, immExtendD, pcPlus4D, regWriteAddrD, 
                            {ALUCtrlD, ALUSrcD, MemWriteEnableD, BranchD, RegWriteEnableD, MemtoRegD},
                             regData1E, regData2E, immExtendE, pcPlus4E, regWriteAddrE,
                            {ALUCtrlE, ALUSrcE, MemWriteEnableE, BranchE, RegWriteEnableE, MemtoRegE});
    exec_stage ExecStage(clk, reset, ALUSrcE, ALUCtrlE, regData1E, regData2E, immExtendE, pcPlus4E, zeroE,
                         aluResE, pcBranchE);
    exec2mem Exec2Mem(clk, reset, zeroE, aluResE, regData2E, pcBranchE, regWriteAddrE, 
                        {MemWriteEnableE, BranchE, RegWriteEnableE, MemtoRegE},
                        zeroM, aluResM,  regData2M, pcBranchM, regWriteAddrM,
                        {MemWriteEnableM, BranchM, RegWriteEnableM, MemtoRegM});
    mem_stage MemStage(clk, reset, MemWriteEnableM,
                        aluResM, regData2M,  memReadDataM);
    mem2writeback Mem2WriteBack(clk, reset, aluResM, memReadDataM, regWriteAddrM,
                        {RegWriteEnableM, MemtoRegM},
                        aluResW, memReadDataW, regWriteAddrW,
                        {RegWriteEnableW, MemtoRegW});
    writeback_stage WriteBackStage(clk, reset, MemtoRegW, aluResW, memReadDataW, regWriteDataW);
 endmodule


