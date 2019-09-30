`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/24 09:17:08
// Design Name: 
// Module Name: flopr
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


module flopr(
    input logic clk,
    input logic reset,
    input logic [31:0] a,
    output logic [31:0] y
    );
    always_ff @(posedge clk, posedge reset)
        if(reset) y <= 32'h0040_0000; // PC reset address.
        else y <= a;        
endmodule

/*
module testbencch_flopr();
    logic clk, reset;
    logic [31:0] a, y;
    
    flopr dut(clk, reset, a, y);
    
    initial begin
        reset = 1; #10;
        assert(y === 0) else $error("fail reset");
        reset = 0;
        clk = 0;
        a = 10; #10;
        assert(y === 0) else $error("fail for wait clk");
        clk = 1; #10;
        assert(y === 32'd10) else $error("fail for clk, %b", y);
    end
endmodule
*/

/*
we design ROM as 64K byte, 16K word. address needs 14bit.
*/
module romcode #(parameter FILENAME="romdata.mem")(input logic [13:0] addr,
            output logic [31:0] instr);
    logic [31:0] ROM [16*1024-1:0];
    
    initial begin
        $readmemh(FILENAME, ROM);
    end
    
    assign instr = ROM[addr];
endmodule

/*
test for following data:
1111ffff
aaaacccc
deadbeaf
002f0123

module testbench_romcode();
    logic [13:0] addr;
    logic [31:0] instr;
    
    romcode dux(addr, instr);
    
    initial begin
        addr = 14'd2; #10;
        assert(instr === 32'hdeadbeaf) else $error("fail ROM address 2");
        addr = 14'b0; #10;
        assert(instr === 32'h1111ffff) else $error("fail ROM address 0");
    end
endmodule
*/

module regfile(
    input logic clk,
    input logic [4:0] a1, a2, a3,
    input logic we3,
    input logic [31:0] wd3,
    output logic [31:0] rd1, rd2);

    logic [31:0] regs [31:0];

    always_ff @(posedge clk)
        if(we3) regs[a3] <= wd3;

    always @(posedge clk)
        $display("1=%h, 2=%h, 3=%h, 4=%h, 5=%h, 6=%h, 7=%h, 8=%h", regs[1], regs[2], regs[3], regs[4], regs[5], regs[6], regs[7], regs[8]);
        
    assign rd1 = (a1 == 0)? 0 : regs[a1];
    assign rd2 = (a2 == 0)?  0 : regs[a2];    
 endmodule
 
 /*
 module testbench_regfile();
    logic [4:0] a1, a2, a3;
    logic clk, we3;
    logic [31:0] wd3, rd1, rd2;
    
    regfile dut(clk, a1, a2, a3, we3, wd3, rd1, rd2);
    
    initial begin
        wd3 = 32'habcd_1234; a3 = 5'b0_1100; we3 = 1; clk = 1; #10;
        clk = 0; #10;
        clk = 1; wd3 = 32'h4321_ffaa; a3 = 5'b0_1001; we3 = 1; clk = 1; #10;
        clk = 0; we3 = 0; #10;
        a1 = 5'b0_1100; clk = 1; #10;
        assert(rd1 === 32'habcd_1234) else $error("read a1 fail");
        clk = 0; #10;
        a1 = 5'b0_1001; a2 = 5'b0_1100; clk = 1; #10;
        assert(rd2 === 32'habcd_1234) else $error("read both, a2 fail");
        assert(rd1 === 32'h4321_ffaa) else $error("read both, a1 fail");
    end
 endmodule
 */
 
 
 /*
SRAM 64K byte, 16K word. address needs 14bit.
*/
module sram(input logic clk,
            input logic [13:0] addr,
            input logic we,
            input logic [31:0] wd,
            output logic [31:0] rd);
    logic [31:0] SRAM [16*1024-1:0];
    
    always_ff @(posedge clk)
        if(we) SRAM[addr] <= wd;
        
    assign rd = SRAM[addr];
endmodule

/*
 module testbench_sram();
    logic [13:0] a1;
    logic clk, we;
    logic [31:0] wd, rd;
    
    sram dut(clk, a1, we, wd, rd);
    
    initial begin
        wd = 32'habcd_1234; a1 = 14'b1100; we = 1; clk = 1; #10;
        clk = 0; #10;
        clk = 1; wd = 32'h4321_ffaa; a1 = 14'b1001; we = 1; clk = 1; #10;
        clk = 0; we = 0; #10;
        a1 = 14'b1100; clk = 1; #10;
        assert(rd === 32'habcd_1234) else $error("read first fail");
        clk = 0; #10;
        a1 = 14'b1001; clk = 1; #10;
        assert(rd === 32'h4321_ffaa) else $error("read second fail");
    end
 endmodule
*/