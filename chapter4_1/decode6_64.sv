`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/22 20:41:08
// Design Name: 
// Module Name: decode6_64
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


module decode6_64(
    input logic [5:0] a,
    output logic [63:0] y
    );
    logic [3:0] high, mid, low;
    decode24 highdec(a[5:4], high);
    decode24 middec(a[3:2], mid);
    decode24 lowdec(a[1:0], low);
    
    assign y = {{16{high[3]}}, {16{high[2]}}, {16{high[1]}}, {16{high[0]}}} & {4{{4{mid[3]}}, {4{mid[2]}}, {4{mid[1]}}, {4{mid[0]}}}} & {16{low[3:0]}};
    
endmodule

module testbench_decode6_64();
    logic [5:0] a;
    logic [63:0] y;
    
    decode6_64 dut(a, y);

    initial begin
        a = 6'b111111; #10;
        assert(y === 64'h8000_0000_0000_0000) else $error("fail 111111");
        a = 6'b111110; #10;
        assert(y === 64'h4000_0000_0000_0000) else $error("fail 111110");
        a = 6'b111101; #10;
        assert(y === 64'h2000_0000_0000_0000) else $error("fail b111101");
        a = 6'b111100; #10;
        assert(y === 64'h1000_0000_0000_0000) else $error("fail b111100");
        a = 6'b111011; #10;
        assert(y === 64'h0800_0000_0000_0000) else $error("fail b111011");
        a = 6'b111010; #10;
        assert(y === 64'h0400_0000_0000_0000) else $error("fail b111010");
        a = 6'b000001; #10;
        assert(y === 64'h0000_0000_0000_0002) else $error("fail b000001 %b", y);
        a = 6'b000000; #10;
        assert(y === 64'h0000_0000_0000_0001) else $error("fail b000000");
    end    
endmodule