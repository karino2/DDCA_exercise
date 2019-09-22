`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/22 16:04:10
// Design Name: 
// Module Name: comb49
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

/*
Combination logic of exercise 4.9.
y= a~b+~b~c+~abc

I use bit concatenation for practice.
*/

module comb49(
    input logic a, b, c,
    output y
    );
    logic [2:0] d;
    logic [2:0] tmpy;
    mux8 mux_comb(1, 0, 0, 1, 1, 1, 0, 0, d, tmpy);    
    assign d = {a, b, c};
    assign y = tmpy[0];
    
endmodule

module testbench_comb49();
    logic a, b, c, y;
    // comb49 dut(a, b, c, y);
    comb4_10 dut(a, b, c, y);
    
    initial begin
        a = 0; b = 0; c = 0; #10;
        assert(y === 1) else $error("faill 000");
        b = 1; #10;
        assert(y === 0) else $error("faill 010");
        a = 1; b = 0; #10;
        assert(y === 1) else $error("faill 100");
        c = 1; #10;
        assert(y === 1) else $error("faill 101");
        b = 1; #10;
        assert(y === 0) else $error("faill 111");        
    end
endmodule

/*
ex 4.10 is quite similar, so put in the same file.
*/
module mux4(input logic [2:0] d0, d1, d2, d3,
    input logic [1:0] s,
    output logic [2:0] y);
    assign y = s[1] ? (s[0]? d3: d2) : (s[0] ? d1: d0);
endmodule

module comb4_10(input logic a, b, c,
    output y
    );
    logic [2:0] tmpy;
    logic [2:0] a1y, a0y;
    
    // a=0 case, y = ~b~c+bc
    mux4 muxa0(1, 0, 0, 1, {b, c}, a0y);
    // a=1 case. y = ~b+~b~c = ~b
    mux4 muxa1(1, 0, 1, 0, {b, c}, a1y);
    
    // emulate mux2 by mux4.
    mux4 mux_fora(a0y, a1y, a0y, a1y, {0, a}, tmpy);
    
    assign y = tmpy[0];    
endmodule
