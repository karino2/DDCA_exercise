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
        if(reset) y <= 0;
        else y <= a;        
endmodule

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
