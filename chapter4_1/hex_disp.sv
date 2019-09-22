`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/22 09:28:58
// Design Name: 
// Module Name: hex_disp
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


module hex_disp(
    input logic [3:0] data,
    output logic [6:0] segments    
    );
    always_comb
        case(data)
        //               abc_defg
        0: segments = 7'b111_1110;
        1: segments = 7'b011_0000;
        2: segments = 7'b110_1101;
        3: segments = 7'b111_1001;
        4: segments = 7'b011_0011;
        5: segments = 7'b101_1011;
        6: segments = 7'b101_1111;
        7: segments = 7'b111_0000;
        8: segments = 7'b111_1111;
        9: segments = 7'b111_0011;
        10: segments = 7'b111_0110;
        11: segments = 7'b001_1111;
        12: segments = 7'b100_1110;
        13: segments = 7'b011_1101;
        14: segments = 7'b100_1111;
        15: segments = 7'b100_0111;
        default: segments = 7'b000_0000;
    endcase
endmodule


module testbench_hex_disp();
    logic [3:0] data;
    logic [6:0] seg;
    
    hex_disp dut(data, seg);
    
    initial begin
        data = 4'b1001; #10;
        assert(seg == 7'b111_0011) else $error("fail on 0x09");
        data = 4'ha; #10;
        assert(seg == 7'b111_0110) else $error("fail on 0x0a");
    end
endmodule