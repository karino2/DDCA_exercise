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

module testbench_sram_fp_bank_conflict();
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

        // write, bank conflict
        {we0, we1, we2, we3} = 4'b1111;
        wd0 = 123;
        wd1 = 456;
        wd2 = 789;
        wd3 = 5555;
        addr0 = 12;
        addr1 = 8;
        addr2 = 4;
        addr3 = 0;

        clk = 0; #10; clk = 1; #10;
        {we0, we1, we2, we3} = 4'b0;
        addr0 = 0;
        addr1 = 4;
        addr2 = 8;
        addr3 = 12;
        clk = 0; #10; clk = 1; #10;
        // first thread result must be written first.
        assert(rd3 === 123) else $error("rd3 is wrong. %d", rd3);
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        assert(rd3 === 123);
        assert(rd2 ===  456) else $error("rd2 is wrong. %d", rd2);
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        assert(rd3 === 123);
        assert(rd2 === 456);
        assert(rd1 ===  789) else $error("rd1 is wrong. %d", rd1);
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        assert(rd3 === 123);
        assert(rd2 === 456);
        assert(rd1 === 789);
        assert(rd0 ===  5555) else $error("rd0 is wrong. %d", rd1);
        $display("sram_fp bank conflict test done.");
    end

endmodule


module simt_with_sram #(parameter FILENAME="simt_simple_test.mem")(input logic clk, reset, output logic halt);
        // sram core 0
        logic [31:0] sramReadData0;
        logic [31:0] sramDataAddress0, sramWriteData0;
        logic sramWriteEnable0;
        // sram core1
        logic [31:0] sramReadData1;
        logic [31:0] sramDataAddress1, sramWriteData1;
        logic sramWriteEnable1;
        // sram core2
        logic [31:0] sramReadData2;
        logic [31:0] sramDataAddress2, sramWriteData2;
        logic sramWriteEnable2;
        // sram core3
        logic [31:0] sramReadData3;
        logic [31:0] sramDataAddress3, sramWriteData3;
        logic sramWriteEnable3;
        // DMA
        logic [1:0] dmaCmd; //00: nothing  01: d2s   10:s2d 
        logic [31:0] dmaSrcAddress, dmaDstAddress;
        logic [9:0] dmaWidth;

        sram_fp DataMem(clk, reset,
                sramDataAddress0[15:2], sramWriteEnable0, sramWriteData0, sramReadData0,
                sramDataAddress1[15:2], sramWriteEnable1, sramWriteData1, sramReadData1,
                sramDataAddress2[15:2], sramWriteEnable2, sramWriteData2, sramReadData2,
                sramDataAddress3[15:2], sramWriteEnable3, sramWriteData3, sramReadData3);

        simt_group #(FILENAME) u_cpus(clk, reset, 1'b0,
            sramReadData0,
            sramDataAddress0, sramWriteData0,
            sramWriteEnable0,
            // sram core1
            sramReadData1,
            sramDataAddress1, sramWriteData1,
            sramWriteEnable1,
            // sram core2
            sramReadData2,
            sramDataAddress2, sramWriteData2,
            sramWriteEnable2,
            // sram core3
            sramReadData3,
            sramDataAddress3, sramWriteData3,
            sramWriteEnable3,
            // DMA
            dmaCmd, //00: nothing  01: d2s   10:s2d 
            dmaSrcAddress, dmaDstAddress, 
            dmaWidth,
            halt);



endmodule

module testbench_simt_simple();
    logic clk, reset, halt;

    simt_with_sram #("simt_simple_test.mem") dut(clk, reset, halt);

    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
        repeat(50)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dut.DataMem.BANK0[0] === 3) else $error("wrong first data: %h", dut.DataMem.BANK0[0]);
        assert(dut.DataMem.BANK1[0] === 7) else $error("wrong sec data: %h", dut.DataMem.BANK1[0]);
        assert(dut.DataMem.BANK2[0] === 11) else $error("wrong third data: %h", dut.DataMem.BANK2[0]);
        assert(dut.DataMem.BANK3[0] === 15) else $error("wrong fourth data: %h", dut.DataMem.BANK3[0]);
    end
endmodule