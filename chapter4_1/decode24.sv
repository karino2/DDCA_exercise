`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/22 20:27:50
// Design Name: 
// Module Name: decode24
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


module decode24(
    input logic [1:0]a,
    output logic [3:0] y
    );
    always_comb
    case(a)
        2'b00: y = 4'b0001;
        2'b01: y = 4'b0010;
        2'b10: y = 4'b0100;
        2'b11: y = 4'b1000;
        default: y = 0;
    endcase
endmodule

/*
module testbench_decode24();
    logic [1:0] a;
    logic [3:0] y;
    
    decode24 dut(a, y);
    
    initial begin
        a = 3; #10;
        assert(y === 4'b1000) else $error("fail 3");
        a = 0; #10;
        assert(y === 4'b0001) else $error("fail 0");
        a = 2; #10;
        assert(y === 4'b0100) else $error("fail 2");
    end
endmodule
*/