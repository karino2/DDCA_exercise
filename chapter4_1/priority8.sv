`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/22 20:02:25
// Design Name: 
// Module Name: priority8
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


module priority8(input logic [7:0] a,
output logic [7:0] y
    );
    always_comb
        if(a[7]) y=8'b1000_0000;
        else if(a[6]) y=8'b0100_0000;
        else if(a[5]) y=8'b0010_0000;
        else if(a[4]) y=8'b0001_0000;
        else if(a[3]) y=8'b0000_1000;
        else if(a[2]) y=8'b0000_0100;
        else if(a[1]) y=8'b0000_0010;
        else if(a[0]) y=8'b0000_0001;
        else y=0;    
endmodule

module testbench_priority8();
    logic [7:0] a, y;
    
    priority8 dut(a, y);
    
    initial begin
        a = 8'b1111_1111; #10;
        assert(y===8'b1000_0000) else $error("fail 11111111");
        a = 8'b1001_0011; #10;
        assert(y==8'b1000_0000) else $error("fail 1001 0011");
        a = 8'b0101_1111; #10;
        assert(y===8'b0100_0000) else $error("fail 0100 0000");
        a = 8'b0000_0101; #10;
        assert(y===8'b0000_0100) else $error("fail 0000 0100");
    end
endmodule