`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/19 19:26:43
// Design Name: 
// Module Name: xor
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


module myxor(
    input logic [3:0] a,
    output logic y
    );
    always_comb
        case(a)
            4'b0001: y=1;
            4'b0010: y=1;
            4'b0100: y=1;
            4'b1000: y=1;
            4'b1110: y=1;
            4'b1101: y=1;
            4'b1011: y=1;
            4'b0111: y=1;
            default: y=0;
        endcase
endmodule

module testbench_myxor();
    logic [3:0] a;
    logic y;
    
    myxor dut(a, y);
    
    initial begin
        a = 4'b0000; #10;
        assert (y===0) else $error("myxor: 0000 failed.");
        a = 4'b0001; #10;
        assert (y===1) else $error("myxor: 0001 failed.");
        a = 4'b0101; #10;
        assert (y===0) else $error("myxor: 0101 failed.");
        a = 4'b0100; #10;
        assert (y===1) else $error("myxor: 0100 failed.");
        a = 4'b1111; #10;
        assert (y===0) else $error("myxor: 1111 failed.");
        a = 4'b0111; #10;
        assert (y===1) else $error("myxor: 01111 failed.");
        a = 4'b0011; #10;
        assert (y===0) else $error("myxor: 0011 failed.");
        a = 4'b1011; #10;
        assert (y===1) else $error("myxor: 10111 failed.");
    end
endmodule