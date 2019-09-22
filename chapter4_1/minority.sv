`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/19 21:11:04
// Design Name: 
// Module Name: minority
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


module minority(
    input logic a,
    input logic b,
    input logic c,
    output logic y
    );
    assign y = ~a & ~b | ~a & ~c | ~b & ~c;
endmodule

module testbench_minority();
    logic a, b, c, y;
    
    minority dut(a, b, c, y);
    
    initial begin
        a = 0; b = 0; c=0; #10;
        assert(y===1) else $error("000 fail");
        a = 1; b = 1; c=1; #10;
        assert(y===0) else $error("111 fail");
        b = 0; #10;
        assert(y===0) else $error("101 fail");
        c = 0; #10;
        assert(y===1) else $error("100 fail");
    end
endmodule
