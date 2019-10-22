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
    input logic en,
    input logic [31:0] a,
    output logic [31:0] y
    );
    always_ff @(posedge clk, posedge reset)
        if(reset) y <= 32'h0040_0000; // PC reset address.
        else if(en) y <= a;        
endmodule

/*
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
*/

/*
we design ROM as 64K byte, 16K word. address needs 14bit.
*/
module romcode #(parameter FILENAME="romdata.mem")(input logic [13:0] addr,
            output logic [31:0] instr);
    logic [31:0] ROM [16*1024-1:0];
    
    initial begin
        $readmemh(FILENAME, ROM);
    end
    
    assign instr = ROM[addr];
endmodule

/*
test for following data:
1111ffff
aaaacccc
deadbeaf
002f0123

module testbench_romcode();
    logic [13:0] addr;
    logic [31:0] instr;
    
    romcode dux(addr, instr);
    
    initial begin
        addr = 14'd2; #10;
        assert(instr === 32'hdeadbeaf) else $error("fail ROM address 2");
        addr = 14'b0; #10;
        assert(instr === 32'h1111ffff) else $error("fail ROM address 0");
    end
endmodule
*/

module regfile_single(
    input logic clk,
    input logic [4:0] a1, a2, a3,
    input logic we3,
    input logic [31:0] wd3,
    output logic [31:0] rd1, rd2);

    logic [31:0] regs [31:0];

    always_ff @(posedge clk)
        if(we3) begin
            regs[a3] <= wd3;
            if(a3 != 0)
                $display("reg write: a3=%h, wd3=%h", a3, wd3);
        end

    /*
    always @(posedge clk)
        $display("1=%h, 2=%h, 3=%h, 4=%h, 5=%h, 6=%h, 7=%h, 8=%h", regs[1], regs[2], regs[3], regs[4], regs[5], regs[6], regs[7], regs[8]);
        */
        
    assign rd1 = (a1 == 0)? 0 : regs[a1];
    assign rd2 = (a2 == 0)?  0 : regs[a2];    
 endmodule


module regfileTID #(parameter TID=0) (
    input logic clk,
    input logic [4:0] a1, a2, a3,
    input logic we3,
    input logic [31:0] wd3,
    output logic [31:0] rd1, rd2);

    logic [31:0] regs [31:0];

    always_ff @(negedge clk)
        if(we3) begin
            regs[a3] <= wd3;
            $display("reg write: a3=%h, wd3=%h", a3, wd3);
        end

    /*
    always @(posedge clk)
        $display("1=%h, 2=%h, 3=%h, 4=%h, 5=%h, 6=%h, 7=%h, 8=%h", regs[1], regs[2], regs[3], regs[4], regs[5], regs[6], regs[7], regs[8]);
        */
        
    assign rd1 = (a1 == 0)? 0 : ((a1 == 5'd31)? TID : regs[a1]);
    assign rd2 = (a2 == 0)? 0 : ((a2 == 5'd31)? TID : regs[a2]);    

 endmodule


module regfile(
    input logic clk,
    input logic [4:0] a1, a2, a3,
    input logic we3,
    input logic [31:0] wd3,
    output logic [31:0] rd1, rd2);

    logic [31:0] regs [31:0];

    always_ff @(negedge clk)
        if(we3) begin
            regs[a3] <= wd3;
            $display("reg write: a3=%h, wd3=%h", a3, wd3);
        end

    /*
    always @(posedge clk)
        $display("1=%h, 2=%h, 3=%h, 4=%h, 5=%h, 6=%h, 7=%h, 8=%h", regs[1], regs[2], regs[3], regs[4], regs[5], regs[6], regs[7], regs[8]);
        */
        
    assign rd1 = (a1 == 0)? 0 : regs[a1];
    assign rd2 = (a2 == 0)?  0 : regs[a2];    
 endmodule
 
 /*
 module testbench_regfile();
    logic [4:0] a1, a2, a3;
    logic clk, we3;
    logic [31:0] wd3, rd1, rd2;
    
    regfile dut(clk, a1, a2, a3, we3, wd3, rd1, rd2);
    
    initial begin
        wd3 = 32'habcd_1234; a3 = 5'b0_1100; we3 = 1; clk = 1; #10;
        clk = 0; #10;
        clk = 1; wd3 = 32'h4321_ffaa; a3 = 5'b0_1001; we3 = 1; clk = 1; #10;
        clk = 0; we3 = 0; #10;
        a1 = 5'b0_1100; clk = 1; #10;
        assert(rd1 === 32'habcd_1234) else $error("read a1 fail");
        clk = 0; #10;
        a1 = 5'b0_1001; a2 = 5'b0_1100; clk = 1; #10;
        assert(rd2 === 32'habcd_1234) else $error("read both, a2 fail");
        assert(rd1 === 32'h4321_ffaa) else $error("read both, a1 fail");
    end
 endmodule
 */
 
 
 /*
SRAM 64K byte, 16K word. address needs 14bit.
*/
module sram(input logic clk,
            input logic [13:0] addr,
            input logic we,
            input logic [31:0] wd,
            output logic [31:0] rd);
    logic [31:0] SRAM [16*1024-1:0];

    // assume 4 byte align, no check.
    always_ff @(posedge clk)
        if(we) begin 
            SRAM[addr] <= wd;
            $display("sram write, %h, %h", addr, wd);
        end
        
    assign rd = SRAM[addr];
endmodule


 /*
SRAM 64K byte, 16K word. 4bank with 4FIFO.
Written data can be read after 2 clock cycle.
*/
module sram_fp(input logic clk, reset,
            input logic [13:0] addr0,
            input logic we0,
            input logic [31:0] wd0,
            output logic [31:0] rd0,

            input logic [13:0] addr1,
            input logic we1,
            input logic [31:0] wd1,
            output logic [31:0] rd1,

            input logic [13:0] addr2,
            input logic we2,
            input logic [31:0] wd2,
            output logic [31:0] rd2,
            
            input logic [13:0] addr3,
            input logic we3,
            input logic [31:0] wd3,
            output logic [31:0] rd3
            );
    
    // 0, 4, 8, 12, 16, ...
    logic [31:0] BANK0 [4*1024-1:0];
    // 1, 5, 9, 13, 17, ...
    logic [31:0] BANK1 [4*1024-1:0];
    // 2, 6, 10, 14, 18, ...
    logic [31:0] BANK2 [4*1024-1:0];
    // 3, 7, 11, 15, 19, ...
    logic [31:0] BANK3 [4*1024-1:0];

    logic [13:0] cur_addr0, cur_addr1, cur_addr2, cur_addr3;
    logic [31:0] cur_data0, cur_data1, cur_data2, cur_data3;
    logic cur_re0, cur_re1, cur_re2, cur_re3;
    logic full0, full1, full2, full3, empty0, empty1, empty2, empty3;

    cmn_fifo #(.DW(14+32), .AW(8))
    u_awfifo0(
    .clk      (clk),
    .rstn     (!reset),
    .we       (we0),
    .wdata    ({addr0, wd0}),
    .re       (cur_re0),
    .rdata    ({cur_addr0, cur_data0}),
    .full     (full0),
    .empty    (empty0)
    );

    cmn_fifo #(.DW(14+32), .AW(8))
    u_awfifo1(
    .clk      (clk),
    .rstn     (!reset),
    .we       (we1),
    .wdata    ({addr1, wd1}),
    .re       (cur_re1),
    .rdata    ({cur_addr1, cur_data1}),
    .full     (full1),
    .empty    (empty1)
    );
 
    cmn_fifo #(.DW(14+32), .AW(8))
    u_awfifo2(
    .clk      (clk),
    .rstn     (!reset),
    .we       (we2),
    .wdata    ({addr2, wd2}),
    .re       (cur_re2),
    .rdata    ({cur_addr2, cur_data2}),
    .full     (full2),
    .empty    (empty2)
    );

    cmn_fifo #(.DW(14+32), .AW(8))
    u_awfifo3(
    .clk      (clk),
    .rstn     (!reset),
    .we       (we3),
    .wdata    ({addr3, wd3}),
    .re       (cur_re3),
    .rdata    ({cur_addr3, cur_data3}),
    .full     (full3),
    .empty    (empty3)
    );



    always_ff @(posedge clk)
        begin
            // fifo0
            if(empty0)
                cur_re0 <= 0;
            else
                begin
                    case(cur_addr0[1:0])
                        2'b00: BANK0[cur_addr0[13:2]] <= cur_data0;
                        2'b01: BANK1[cur_addr0[13:2]] <= cur_data0;
                        2'b10: BANK2[cur_addr0[13:2]] <= cur_data0;
                        2'b11: BANK3[cur_addr0[13:2]] <= cur_data0;
                    endcase
                    cur_re0 <= 1;
                end

            // fifo1
            if(empty1)
                cur_re1 <= 0;
            else
                begin
                    case(cur_addr1[1:0])
                        2'b00:
                            if(!empty0 & (cur_addr0[1:0] == 2'b00))
                                cur_re1 <= 0;
                            else
                                begin
                                    BANK0[cur_addr1[13:2]] <= cur_data1;
                                    cur_re1 <= 1;
                                end
                        2'b01:
                            if(!empty0 & (cur_addr0[1:0] == 2'b01))
                                cur_re1 <= 0;
                            else
                                begin
                                    BANK1[cur_addr1[13:2]] <= cur_data1;
                                    cur_re1 <= 1;
                                end
                        2'b10:
                            if(!empty0 & (cur_addr0[1:0] == 2'b10))
                                cur_re1 <= 0;
                            else
                                begin
                                    BANK2[cur_addr1[13:2]] <= cur_data1;
                                    cur_re1 <= 1;
                                end
                        2'b11:
                            if(!empty0 & (cur_addr0[1:0] == 2'b11))
                                cur_re1 <= 0;
                            else
                                begin
                                    BANK3[cur_addr1[13:2]] <= cur_data1;
                                    cur_re1 <= 1;
                                end
                    endcase
                end


            // fifo2
            if(empty2)
                cur_re2 <= 0;
            else
                begin
                    case(cur_addr2[1:0])
                        2'b00:
                            if((!empty0 & (cur_addr0[1:0] == 2'b00)) | (!empty1 &(cur_addr1[1:0] == 2'b00)))
                                cur_re2 <= 0;
                            else
                                begin
                                    BANK0[cur_addr2[13:2]] <= cur_data2;
                                    cur_re2 <= 1;
                                end
                        2'b01:
                            if((!empty0 & (cur_addr0[1:0] == 2'b01)) | (!empty1 &(cur_addr1[1:0] == 2'b01)))
                                cur_re2 <= 0;
                            else
                                begin
                                    BANK1[cur_addr2[13:2]] <= cur_data2;
                                    cur_re2 <= 1;
                                end
                        2'b10:
                            if((!empty0 & (cur_addr0[1:0] == 2'b10)) | (!empty1 &(cur_addr1[1:0] == 2'b10)))
                                cur_re2 <= 0;
                            else
                                begin
                                    BANK2[cur_addr2[13:2]] <= cur_data2;
                                    cur_re2 <= 1;
                                end
                        2'b11:
                            if((!empty0 & (cur_addr0[1:0] == 2'b11)) | (!empty1 &(cur_addr1[1:0] == 2'b11)))
                                cur_re2 <= 0;
                            else
                                begin
                                    BANK3[cur_addr2[13:2]] <= cur_data2;
                                    cur_re2 <= 1;
                                end
                    endcase
                end

            // fifo3
            if(empty3)
                cur_re3 <= 0;
            else
                begin
                    case(cur_addr3[1:0])
                        2'b00:
                            if((!empty0 & (cur_addr0[1:0] == 2'b00))
                             | (!empty1 &(cur_addr1[1:0] == 2'b00))
                             | (!empty2 &(cur_addr2[1:0] == 2'b00))
                             )
                                cur_re3 <= 0;
                            else
                                begin
                                    BANK0[cur_addr3[13:2]] <= cur_data3;
                                    cur_re3 <= 1;
                                end
                        2'b01:
                            if((!empty0 & (cur_addr0[1:0] == 2'b01))
                             | (!empty1 &(cur_addr1[1:0] == 2'b01))
                             | (!empty2 &(cur_addr2[1:0] == 2'b01))
                             )
                                cur_re3 <= 0;
                            else
                                begin
                                    BANK1[cur_addr3[13:2]] <= cur_data3;
                                    cur_re3 <= 1;
                                end
                        2'b10:
                            if((!empty0 & (cur_addr0[1:0] == 2'b10))
                             | (!empty1 &(cur_addr1[1:0] == 2'b10))
                             | (!empty2 &(cur_addr2[1:0] == 2'b10))
                             )
                                cur_re3 <= 0;
                            else
                                begin
                                    BANK2[cur_addr3[13:2]] <= cur_data3;
                                    cur_re3 <= 1;
                                end
                        2'b11:
                            if((!empty0 & (cur_addr0[1:0] == 2'b11))
                             | (!empty1 &(cur_addr1[1:0] == 2'b11))
                             | (!empty2 &(cur_addr2[1:0] == 2'b11))
                             )
                                cur_re3 <= 0;
                            else
                                begin
                                    BANK3[cur_addr3[13:2]] <= cur_data3;
                                    cur_re3 <= 1;
                                end
                    endcase
                end
        end



    always_comb
        begin
            case(addr0[1:0])
                2'b00: rd0  = BANK0[addr0[13:2]];
                2'b01: rd0  = BANK1[addr0[13:2]];
                2'b10: rd0  = BANK2[addr0[13:2]];
                2'b11: rd0  = BANK3[addr0[13:2]];
                default: rd0 = 0;
            endcase
            case(addr1[1:0])
                2'b00: rd1  = BANK0[addr1[13:2]];
                2'b01: rd1  = BANK1[addr1[13:2]];
                2'b10: rd1  = BANK2[addr1[13:2]];
                2'b11: rd1  = BANK3[addr1[13:2]];
                default: rd1 = 0;
            endcase
            case(addr2[1:0])
                2'b00: rd2  = BANK0[addr2[13:2]];
                2'b01: rd2  = BANK1[addr2[13:2]];
                2'b10: rd2  = BANK2[addr2[13:2]];
                2'b11: rd2  = BANK3[addr2[13:2]];
                default: rd2 = 0;
            endcase
            case(addr3[1:0])
                2'b00: rd3  = BANK0[addr3[13:2]];
                2'b01: rd3  = BANK1[addr3[13:2]];
                2'b10: rd3  = BANK2[addr3[13:2]];
                2'b11: rd3  = BANK3[addr3[13:2]];
                default: rd3 = 0;
            endcase
        end
endmodule


/*
 module testbench_sram();
    logic [13:0] a1;
    logic clk, we;
    logic [31:0] wd, rd;
    
    sram dut(clk, a1, we, wd, rd);
    
    initial begin
        wd = 32'habcd_1234; a1 = 14'b1100; we = 1; clk = 1; #10;
        clk = 0; #10;
        clk = 1; wd = 32'h4321_ffaa; a1 = 14'b1001; we = 1; clk = 1; #10;
        clk = 0; we = 0; #10;
        a1 = 14'b1100; clk = 1; #10;
        assert(rd === 32'habcd_1234) else $error("read first fail");
        clk = 0; #10;
        a1 = 14'b1001; clk = 1; #10;
        assert(rd === 32'h4321_ffaa) else $error("read second fail");
    end
 endmodule
*/