`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/28 19:14:05
// Design Name: 
// Module Name: testbench_mips
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

module testbench_sram_fp();
    logic clk, reset;

    logic [13:0] addr0;
    logic we0;
    logic [31:0] wd0;
    logic [31:0] rd0;

    logic [13:0] addr1;
    logic we1;
    logic [31:0] wd1;
    logic [31:0] rd1;

    logic [13:0] addr2;
    logic we2;
    logic [31:0] wd2;
    logic [31:0] rd2;
    
    logic [13:0] addr3;
    logic we3;
    logic [31:0] wd3;
    logic [31:0] rd3;

    sram_fp dut(clk, reset,
            addr0, we0, wd0, rd0,
            addr1, we1, wd1, rd1,
            addr2, we2, wd2, rd2,
            addr3, we3, wd3, rd3);


    
    initial begin
        {we0, we1, we2, we3} = 4'b0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;

        // write, no bank conflict.
        {we0, we1, we2, we3} = 4'b1111;
        wd0 = 123;
        wd1 = 456;
        wd2 = 789;
        wd3 = 5555;
        addr0 = 0;
        addr1 = 5;
        addr2 = 3;
        addr3 = 2;

        clk = 0; #10; clk = 1; #10;
        {we0, we1, we2, we3} = 4'b0;
        addr0 = 5;
        addr1 = 2;
        addr2 = 3;
        addr3 = 0;
        clk = 0; #10; clk = 1; #10;
        assert(rd0 === 456) else $error("rd0 wrong, %d", rd0);
        assert(rd1 === 5555) else $error("rd1 wrong, %d", rd1);
        assert(rd2 === 789) else $error("rd2 wrong, %d", rd2);
        assert(rd3 === 123) else $error("rd3 wrong, %d", rd3);

        $display("sram_fp test done.");
    end

endmodule

