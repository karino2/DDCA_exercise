`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/19 18:03:47
// Design Name: 
// Module Name: sillyfunction
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


module sillyfunction(
    input logic a, b, c,
    output logic y
    );
    assign y= ~a & ~b & ~c |
    a & ~b & ~c |
    a & ~b & c;
endmodule

module testbench_sillyfunction();
    logic a, b, c, y;
    
    sillyfunction dut(a, b, c,  y);
    
    initial begin
        a = 0; b = 0; c=0; #10;
        assert (y===1) else $error("000 failed.");
        c = 1; #10;
        assert(y === 0) else $error("001 failed.");
        a = 1; b = 0; c= 0; #10;
        assert( y=== 1) else $error("100 failed.");
    end
endmodule
    
