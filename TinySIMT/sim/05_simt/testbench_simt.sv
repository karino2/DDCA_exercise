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
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        // $display("re: %h, %h, %h, %h", rd0, rd1, rd2, rd3);
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
        clk = 0; #10; clk = 1; #10;
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


module simt_with_sram_dmaout #(parameter FILENAME="simt_simple_test.mem")
(input logic clk, reset,
    // DMA
    input logic dmaStall,
    output logic [1:0] dmaCmd, //00: nothing  01: d2s   10:s2d 
    output logic [31:0] dmaSrcAddress, dmaDstAddress,
    output logic [9:0] dmaWidth,
    output logic halt);
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

        sram_fp DataMem(clk, reset,
                sramDataAddress0[15:2], sramWriteEnable0, sramWriteData0, sramReadData0,
                sramDataAddress1[15:2], sramWriteEnable1, sramWriteData1, sramReadData1,
                sramDataAddress2[15:2], sramWriteEnable2, sramWriteData2, sramReadData2,
                sramDataAddress3[15:2], sramWriteEnable3, sramWriteData3, sramReadData3);

        simt_group #(FILENAME) u_cpus(clk, reset, dmaStall,
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

module simt_with_sram #(parameter FILENAME="simt_simple_test.mem")(input logic clk, reset, output logic halt);
        // DMA
        logic [1:0] dmaCmd; //00: nothing  01: d2s   10:s2d 
        logic [31:0] dmaSrcAddress, dmaDstAddress;
        logic [9:0] dmaWidth;

        simt_with_sram_dmaout #(FILENAME) u_simt_with_sram_dmaout(
             clk, reset,
              1'b0, dmaCmd,  dmaSrcAddress, dmaDstAddress, dmaWidth,
                halt
        );

endmodule

module testbench_simt_simple();
    logic clk, reset, halt;

    simt_with_sram #("simt_simple_test.mem") dut(clk, reset, halt);

    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
        repeat(10)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK0[0] === 3) else $error("wrong first data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK0[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK1[0] === 7) else $error("wrong sec data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK1[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK2[0] === 11) else $error("wrong third data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK2[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK3[0] === 15) else $error("wrong fourth data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK3[0]);
    end
endmodule


module testbench_simt_beq_forward();
    logic clk, reset, halt;

    simt_with_sram #("simt_beq_forward.mem") dut(clk, reset, halt);

    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
        repeat(50)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK0[0] === 7) else $error("wrong first data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK0[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK1[0] === 2) else $error("wrong sec data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK1[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK2[0] === 7) else $error("wrong third data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK2[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK3[0] === 7) else $error("wrong fourth data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK3[0]);
    end
endmodule

module testbench_simt_beq_complex();
    logic clk, reset, halt;

    simt_with_sram #("simt_beq_complex.mem") dut(clk, reset, halt);

    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
 //       repeat(20)
        repeat(50)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK0[0] === 16) else $error("wrong first data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK0[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK1[0] === 5) else $error("wrong sec data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK1[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK2[0] === 16) else $error("wrong third data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK2[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK3[0] === 13) else $error("wrong fourth data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK3[0]);
    end
endmodule


module testbench_simt_beq_backward();
    logic clk, reset, halt;

    simt_with_sram #("simt_beq_backward.mem") dut(clk, reset, halt);

    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
        repeat(250)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK0[0] === 1) else $error("wrong first data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK0[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK1[0] === 1) else $error("wrong sec data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK1[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK2[0] === 55) else $error("wrong third data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK2[0]);
        assert(dut.u_simt_with_sram_dmaout.DataMem.BANK3[0] === 1) else $error("wrong fourth data: %h", dut.u_simt_with_sram_dmaout.DataMem.BANK3[0]);
    end
endmodule


module testbench_luiori(
    );
    logic clk, reset;

    logic halt;

    simt_with_sram #("luiori_test.mem") dut(clk, reset, halt);
                     
    initial begin
        clk = 0; reset = 1; #10; reset = 0; clk = 1; #10;

        repeat(30)
            begin
                clk = 0; #10; clk = 1; #10; 
            end
        assert(dut.u_simt_with_sram_dmaout.u_cpus.core1.DecodeStage.RegFile.regs[1] === 32'h04d2162e) else $error("fail lui ori, %h", dut.u_simt_with_sram_dmaout.u_cpus.core1.DecodeStage.RegFile.regs[1]);
        $display("mips lui ori test done");
    end
    
endmodule


module testbench_ori_unsigned(
    );
    logic clk, reset;

    logic halt;

    simt_with_sram #("ori_unsigned.mem") dut(clk, reset, halt);
                     
    initial begin
        clk = 0; reset = 1; #10; reset = 0; clk = 1; #10;

        repeat(30)
            begin
                clk = 0; #10; clk = 1; #10; 
            end
        assert(dut.u_simt_with_sram_dmaout.u_cpus.core1.DecodeStage.RegFile.regs[1] === 32'h0000ffff) else $error("fail ori unsigned, %h", dut.u_simt_with_sram_dmaout.u_cpus.core1.DecodeStage.RegFile.regs[1]);
        $display("ori unsigned test done");
    end
    
endmodule


module testbench_simt_srl_andi();
    logic clk, reset, halt;

    simt_with_sram #("srl_andi.mem") dut(clk, reset, halt);

    initial begin
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
        repeat(20)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        assert(dut.u_simt_with_sram_dmaout.u_cpus.core1.DecodeStage.RegFile.regs[2] === 32'h3f) else $error("wrong reg[2], %h", dut.u_simt_with_sram_dmaout.u_cpus.core1.DecodeStage.RegFile.regs[2]);
    end
endmodule


module testbench_simt_swlw();
    logic clk, reset, halt, dmaStall;
    logic [1:0] dmaCmd;
    logic [31:0] dmaSrcAddress, dmaDstAddress;
    logic [9:0] dmaWidth;
    logic [31:0] vectorpos;
    logic [31:0] histvectors[32];

    simt_with_sram_dmaout #("simt_swlw.mem") dut(clk, reset, dmaStall, dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);

    initial begin
        dmaStall = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
        repeat(13)
            begin
                clk = 0; #10; clk = 1; #10;
            end


        assert(dut.u_cpus.core0.DecodeStage.RegFile.regs[2] === 1) else $error("wrong reg2. %h", dut.u_cpus.core0.DecodeStage.RegFile.regs[2]);

        // 0x514 byte = 0x145 word.
        // bank = 1. 
        $display("[0x514]=%h", dut.DataMem.BANK1[32'h51]);
        $display("test swlw end");
        
    end
endmodule

module testbench_simt_slt();
    logic clk, reset, halt, dmaStall;
    logic [1:0] dmaCmd;
    logic [31:0] dmaSrcAddress, dmaDstAddress;
    logic [9:0] dmaWidth;
    logic [31:0] vectorpos;
    logic [31:0] histvectors[32];

    simt_with_sram_dmaout #("slt_test.mem") dut(clk, reset, dmaStall, dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);

    initial begin
        dmaStall = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
        repeat(12)
            begin
                clk = 0; #10; clk = 1; #10;
            end


        $display("reg[3]=%h", dut.u_cpus.core0.DecodeStage.RegFile.regs[3]);
        assert(dut.u_cpus.core0.DecodeStage.RegFile.regs[3] === 0) else $error("wrong reg2. %h", dut.u_cpus.core0.DecodeStage.RegFile.regs[2]);

        $display("test slt end");
        
    end
endmodule


module testbench_simt_histo32();
    logic clk, reset, halt, dmaStall;
    logic [1:0] dmaCmd;
    logic [31:0] dmaSrcAddress, dmaDstAddress;
    logic [9:0] dmaWidth;
    logic [31:0] vectorpos;
    logic [31:0] histvectors[32];

    simt_with_sram_dmaout #("simt_histo32.mem") dut(clk, reset, dmaStall, dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, halt);

    initial begin
        $display("begin histo32 test");
        $readmemh("hist_target.mem", histvectors);
        dmaStall = 0;
        clk = 0; reset = 1; #10;
        reset = 0; clk = 1; #10;
        // $display("dmaCmd=%b", dmaCmd);
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;

        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        // $display("dmaCmd=%b", dmaCmd);

        // here dmaCmd is 1.
        // $display("dmaCmd=%b", dmaCmd);
        dmaStall = 1;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10;
        vectorpos = 0;
        repeat(8)
            begin
               dut.DataMem.BANK0[vectorpos] = histvectors[vectorpos*4];
               dut.DataMem.BANK1[vectorpos] = histvectors[vectorpos*4+1];
               dut.DataMem.BANK2[vectorpos] = histvectors[vectorpos*4+2];
               dut.DataMem.BANK3[vectorpos] = histvectors[vectorpos*4+3];
               clk = 1; #10;
               vectorpos = vectorpos+1;
               clk = 0; #10;
            end
        clk = 1; #10;
        dmaStall = 0;
        clk = 0; #10; clk = 1; #10;
        clk = 0; #10; clk = 1; #10;
        while(dmaCmd === 2'b0)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        // just ignore last s2d and check SRAM directly.
        dmaStall = 1;
        clk = 0; #10; clk = 1; #10;
        dmaStall = 0;
        repeat(!halt)
            begin
                clk = 0; #10; clk = 1; #10;
            end

        // 0x514 byte = 0x145 word.
        // bank = 1. 
        $display("[0x514]=%h", dut.DataMem.BANK1[32'h51]);

        // result is placed from 0x1080.
        // 0x1080/4 = 0x0420 word.
        // bank base is 0x420/4 = 0x108

        // show 0x2e8 (it must be written first time, 0x9A).
        // 0x2e8 byte = 0xba word = bank2: 0x2e
        $display("[0x2e8] = %h", dut.DataMem.BANK2[32'h2e]);

        // show 000006d0, 01b4 (it must be written in core1, first time. 0x94)
        // 0x6d0 byte = 0x1b4 word = bank0: 6d
        $display("[0x6d0] = %h", dut.DataMem.BANK0[32'h6d]);

        // show result of 100 for all core.
        // core0: 0x80+100*4 = 0x210 = 0x84 word = bank0 0x21
        // core1: 0x480+100*4 = 0x610 = 0x184 word = bank0 0x61
        // core2: 0x880+100*4 = 0xA10 = 0x284 word = bank0 0xa1
        // core3: 0xC80+100*4 = 0xE10 = 0x384 word = bank0 0xe1
        $display("res100: core0=%h, core1=%h, core2=%h, core3=%h",
            dut.DataMem.BANK0[32'h21],        
            dut.DataMem.BANK0[32'h61],        
            dut.DataMem.BANK0[32'ha1],        
            dut.DataMem.BANK0[32'he1],        
         );


        // check 4 bank result.
        // bank0: 100: 2
        // bank1: 101: 3
        // bank2: 102: 4
        // bank3: 103: 2

        assert(dut.DataMem.BANK0[32'h108+25] === 2) else $error("wrong first data: %h", dut.DataMem.BANK0[32'h108+25]);
        assert(dut.DataMem.BANK1[32'h108+25] === 3) else $error("wrong sec data: %h", dut.DataMem.BANK1[32'h108+25]);
        assert(dut.DataMem.BANK2[32'h108+25] === 4) else $error("wrong third data: %h", dut.DataMem.BANK2[32'h108+25]);
        assert(dut.DataMem.BANK3[32'h108+25] === 2) else $error("wrong fourth data: %h", dut.DataMem.BANK3[32'h108+25]);

        $display("simt histo32 test done.");
    end
endmodule