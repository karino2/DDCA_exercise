`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/23 19:48:54
// Design Name: 
// Module Name: alu
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

module adder(
    input logic [31:0] a, b,
    input logic cin,
    output logic [31:0] s,
    output logic cout);
    
    assign {cout, s} = a+b+cin;

endmodule

module subtractor(input logic [31:0] a, b,
                   output logic [31:0] y);                
    assign y = a-b;
endmodule

module comparator(input logic [31:0] a, b,
                output logic eq, neq, lt, lte, gt, gte);
    assign eq = (a == b);
    assign neq = (a != b);
    assign lt = (a < b);
    assign lte = (a <= b);
    assign gt = (a > b);
    assign gte = (a >= b);
endmodule

module mux4(input logic [31:0] d0, d1, d2, d3,
    input logic [1:0]s,
    output logic [31:0]y
    );
    always_comb
    case(s)
        2'd0: y=d0;
        2'd1: y=d1;
        2'd2: y=d2;
        2'd3: y=d3;
    endcase
endmodule

module mux2(input logic [31:0] d0, d1,
    input logic s,
    output logic [31:0]y
    );
    assign y = s ? d1 : d0;
endmodule

/*
010: add
110: subtract
000: and
001: or
111: set less than

*/
module alu(
    input logic [31:0] a, b,
    input logic [2:0] f,
    output logic cout,
    output logic zero,
    output logic [31:0] y
    );
    
    logic [31:0] bb, s;

    mux2 bmux(b, ~b, f[2], bb);
    adder aluadder(a, bb, f[2], s, cout);
    mux4 lastmux(a&bb, a|bb, s, {31'b0, s[31]}, f[1:0], y);
    assign zero = (y == 0);
endmodule

/*
module testbench_alu();
    logic [31:0] a, b, y;
    logic [2:0] f;
    logic cout;
    
    alu dut(a, b, f, cout, y);
    initial begin
        // add
        f = 3'b010;
        a = 3; b = 5; #10;
        assert(y === 8 & cout===0) else $error("fail 3+5");
        a = 32'h8000_0000; b = 32'h8000_0000; #10;
        assert(y === 0 & cout===1) else $error("fail cout");
        
        // subtract
        f = 3'b110;
        a = 12; b=24; #10;
        assert(y === -12 & cout===0) else $error("fail 12-24");
       
        // and 
        f = 3'b000;
        a = 32'b01011; b = 32'b111; #10;
        assert(y === 32'b011) else $error("fail and");

        // or
        f = 3'b001; #10;
        assert(y === 32'b01111) else $error("fail or, %b", y);
                
        // slt
        f = 3'b111;
        a = 32; b = 31; #10;
        assert(y === 0) else $error("fail slt false case. %b", y);
        a = 31; b = 40; #10;
        assert(y === 1) else $error("fail slt true case. %b", y);
        
    end
    
endmodule
*/