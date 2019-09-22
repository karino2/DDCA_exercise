`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/22 10:28:12
// Design Name: 
// Module Name: mux8
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


module mux8(input logic [3:0] d0, d1, d2, d3, d4, d5, d6, d7,
    input logic [2:0]s,
    output logic [3:0]y
    );
    always_comb
    case(s)
        3'd0: y=d0;
        3'd1: y=d1;
        3'd2: y=d2;
        3'd3: y=d3;
        3'd4: y=d4;
        3'd5: y=d5;
        3'd6: y=d6;
        3'd7: y=d7;
    endcase
endmodule


module testbench_mux8();
    logic [3:0] d0, d1, d2, d3, d4, d5, d6, d7, y;
    logic [2:0] s;
    
    mux8 dut(d0, d1, d2, d3, d4, d5, d6, d7, s, y);
    
    initial begin
        d0 = 4'b1111;
        d1 = 4'b1110;
        d2 = 4'b1101;
        d3 = 4'b1011;
        d4 = 4'b0111;
        d5 = 4'b1100;
        d6 = 4'b1010;
        d7 = 4'b1100;
        
        s = 0; #10;
        assert(y===4'b1111) else $error("fail 0");
        s = 6; #10;
        assert(y===4'b1010) else $error("fail 6");
        s = 2; #10;
        assert(y===4'b1101) else $error("fail 2");
    end
endmodule
