
module testbench_integrate_all_d2s_check_led;
   bit          clk = 0;
   bit          rstn = 0;
   bit   [3:0]  led;
   bit [3:0] btn;

   wire         ddr3_reset_n;
   wire  [15:0] ddr3_dq;
   wire  [1:0]  ddr3_dqs_p;
   wire  [1:0]  ddr3_dqs_n;
   wire  [13:0] ddr3_addr;
   wire  [2:0]  ddr3_ba;
   wire         ddr3_ras_n;
   wire         ddr3_cas_n;
   wire         ddr3_we_n;
   wire  [0:0]  ddr3_ck_p;
   wire  [0:0]  ddr3_ck_n;
   wire  [0:0]  ddr3_cke;
   wire  [0:0] 	ddr3_cs_n;
   wire  [1:0]  ddr3_dm;
   wire  [0:0]  ddr3_odt;

   
   initial begin
      forever
        #5ns clk = ~clk; // 100MHz
   end


   initial begin
      btn = 4'b0;
      rstn = 0;
      #10ns;
      rstn = 1;

      wait(dut.u_ddr_io.init_calib_complete);
      $display("===============");
      $display("===============");
      $display("Calibration Done");
      $display("===============");
      $display("===============");
      btn[1] = 1;
      #10ns;
      btn[1] = 0;
      #10ns;

      /*
      $display("halt=%b, stall=%b", dut.halt, dut.u_mips_sram_dmac_led.u_cpu.stall);
      $display("mem[3]=%h", dut.u_mips_sram_dmac_led.DataMem.SRAM[3]);

      $display("pc=%h, instr=%h", dut.u_mips_sram_dmac_led.u_cpu.pc, dut.u_mips_sram_dmac_led.u_cpu.instr);
      repeat(50)
        begin
          #10ns;
          $display("pc=%h, instr=%h, halt=%b, stall=%b", dut.u_mips_sram_dmac_led.u_cpu.pc, dut.u_mips_sram_dmac_led.u_cpu.instr, dut.halt, dut.u_mips_sram_dmac_led.u_cpu.stall);
        end

      $stop(0);
      */

      wait(dut.halt);
      $display("mem[3]=%h", dut.u_mips_sram_dmac_led.DataMem.SRAM[3]);

      assert(led === 4'b1101) else $error("led wrong, %b", led);

      // assert(ledval === 3'b111) else $error("ledval wrong, %b", ledval);


      #1us;
      $stop(0);
   end

   glbl glbl();


   arty_top_pipeline dut (
     .ddr3_dq      (ddr3_dq),
     .ddr3_dqs_n   (ddr3_dqs_n),
     .ddr3_dqs_p   (ddr3_dqs_p),
     .ddr3_addr	   (ddr3_addr),
     .ddr3_ba	   (ddr3_ba),
     .ddr3_ras_n   (ddr3_ras_n),
     .ddr3_cas_n   (ddr3_cas_n),
     .ddr3_we_n	   (ddr3_we_n),
     .ddr3_reset_n (ddr3_reset_n),
     .ddr3_ck_p	   (ddr3_ck_p),
     .ddr3_ck_n	   (ddr3_ck_n),
     .ddr3_cke	   (ddr3_cke),
     .ddr3_cs_n	   (ddr3_cs_n),
     .ddr3_dm      (ddr3_dm),
     .ddr3_odt     (ddr3_odt),
     .sys_clk      (clk),
     .sys_rstn     (rstn),
     .btn (btn),
     .led          (led)
   );


   ddr3_model u_comp_ddr3
   (
     .rst_n     (ddr3_reset_n),
     .ck        (ddr3_ck_p),
     .ck_n      (ddr3_ck_n),
     .cke       (ddr3_cke),
     .cs_n      (ddr3_cs_n),
     .ras_n     (ddr3_ras_n),
     .cas_n     (ddr3_cas_n),
     .we_n      (ddr3_we_n),
     .dm_tdqs   (ddr3_dm),
     .ba        (ddr3_ba),
     .addr      (ddr3_addr),
     .dq        (ddr3_dq),
     .dqs       (ddr3_dqs_p),
     .dqs_n     (ddr3_dqs_n),
     .tdqs_n    (),
     .odt       (ddr3_odt)
    );

endmodule


module testbench_integrate_all_d2s_simple;
   bit          clk = 0;
   bit          rstn = 0;
   bit   [3:0]  led;
   bit [3:0] btn;

   wire         ddr3_reset_n;
   wire  [15:0] ddr3_dq;
   wire  [1:0]  ddr3_dqs_p;
   wire  [1:0]  ddr3_dqs_n;
   wire  [13:0] ddr3_addr;
   wire  [2:0]  ddr3_ba;
   wire         ddr3_ras_n;
   wire         ddr3_cas_n;
   wire         ddr3_we_n;
   wire  [0:0]  ddr3_ck_p;
   wire  [0:0]  ddr3_ck_n;
   wire  [0:0]  ddr3_cke;
   wire  [0:0] 	ddr3_cs_n;
   wire  [1:0]  ddr3_dm;
   wire  [0:0]  ddr3_odt;

   
   initial begin
      forever
        #5ns clk = ~clk; // 100MHz
   end


   initial begin
      btn = 4'b0;
      rstn = 0;
      #10ns;
      rstn = 1;

      wait(dut.u_ddr_io.init_calib_complete);
      $display("===============");
      $display("===============");
      $display("Calibration Done");
      $display("===============");
      $display("===============");
      btn[1] = 1;
      #10ns;
      btn[1] = 0;
      #10ns;

      wait(dut.halt);

      assert(led === 4'b1001) else $error("led wrong, %b", led);
      $display("testbench_integrate_all_d2s_simple done");

      // assert(ledval === 3'b111) else $error("ledval wrong, %b", ledval);


      #1us;
      $stop(0);
   end

   glbl glbl();


   arty_top_pipeline #("d2s_simple_test.mem") dut (
     .ddr3_dq      (ddr3_dq),
     .ddr3_dqs_n   (ddr3_dqs_n),
     .ddr3_dqs_p   (ddr3_dqs_p),
     .ddr3_addr	   (ddr3_addr),
     .ddr3_ba	   (ddr3_ba),
     .ddr3_ras_n   (ddr3_ras_n),
     .ddr3_cas_n   (ddr3_cas_n),
     .ddr3_we_n	   (ddr3_we_n),
     .ddr3_reset_n (ddr3_reset_n),
     .ddr3_ck_p	   (ddr3_ck_p),
     .ddr3_ck_n	   (ddr3_ck_n),
     .ddr3_cke	   (ddr3_cke),
     .ddr3_cs_n	   (ddr3_cs_n),
     .ddr3_dm      (ddr3_dm),
     .ddr3_odt     (ddr3_odt),
     .sys_clk      (clk),
     .sys_rstn     (rstn),
     .btn (btn),
     .led          (led)
   );


   ddr3_model u_comp_ddr3
   (
     .rst_n     (ddr3_reset_n),
     .ck        (ddr3_ck_p),
     .ck_n      (ddr3_ck_n),
     .cke       (ddr3_cke),
     .cs_n      (ddr3_cs_n),
     .ras_n     (ddr3_ras_n),
     .cas_n     (ddr3_cas_n),
     .we_n      (ddr3_we_n),
     .dm_tdqs   (ddr3_dm),
     .ba        (ddr3_ba),
     .addr      (ddr3_addr),
     .dq        (ddr3_dq),
     .dqs       (ddr3_dqs_p),
     .dqs_n     (ddr3_dqs_n),
     .tdqs_n    (),
     .odt       (ddr3_odt)
    );

endmodule

module testbench_reset_clk_forever;
   bit          clk = 0;
   bit          rstn = 0;
   bit   [3:0]  led;
   bit [3:0] btn;

   wire         ddr3_reset_n;
   wire  [15:0] ddr3_dq;
   wire  [1:0]  ddr3_dqs_p;
   wire  [1:0]  ddr3_dqs_n;
   wire  [13:0] ddr3_addr;
   wire  [2:0]  ddr3_ba;
   wire         ddr3_ras_n;
   wire         ddr3_cas_n;
   wire         ddr3_we_n;
   wire  [0:0]  ddr3_ck_p;
   wire  [0:0]  ddr3_ck_n;
   wire  [0:0]  ddr3_cke;
   wire  [0:0] 	ddr3_cs_n;
   wire  [1:0]  ddr3_dm;
   wire  [0:0]  ddr3_odt;

   
   initial begin
      forever
        #5ns clk = ~clk; // 100MHz
   end


   initial begin
      btn = 4'b0;
      rstn = 0;
      #10ns;
      rstn = 1;

      wait(dut.halt);
      $display("pc=%h, instr=%h, halt=%b, stall=%b", dut.u_mips_sram_dmac_led.u_cpu.pc, dut.u_mips_sram_dmac_led.u_cpu.instr, dut.halt, dut.u_mips_sram_dmac_led.u_cpu.stall);

      btn[1] = 1;
      #10ns;
      btn[1] = 0;
      #10ns;


      $display("pc=%h, instr=%h, halt=%b, stall=%b", dut.u_mips_sram_dmac_led.u_cpu.pc, dut.u_mips_sram_dmac_led.u_cpu.instr, dut.halt, dut.u_mips_sram_dmac_led.u_cpu.stall);

      $display("pc=%h, instr=%h", dut.u_mips_sram_dmac_led.u_cpu.pc, dut.u_mips_sram_dmac_led.u_cpu.instr);
      repeat(50)
        begin
          #10ns;
          $display("pc=%h, instr=%h, halt=%b, stall=%b", dut.u_mips_sram_dmac_led.u_cpu.pc, dut.u_mips_sram_dmac_led.u_cpu.instr, dut.halt, dut.u_mips_sram_dmac_led.u_cpu.stall);
        end

      $stop(0);

   end


   glbl glbl();

   arty_top_pipeline #("halt_test.mem") dut (
     .ddr3_dq      (ddr3_dq),
     .ddr3_dqs_n   (ddr3_dqs_n),
     .ddr3_dqs_p   (ddr3_dqs_p),
     .ddr3_addr	   (ddr3_addr),
     .ddr3_ba	   (ddr3_ba),
     .ddr3_ras_n   (ddr3_ras_n),
     .ddr3_cas_n   (ddr3_cas_n),
     .ddr3_we_n	   (ddr3_we_n),
     .ddr3_reset_n (ddr3_reset_n),
     .ddr3_ck_p	   (ddr3_ck_p),
     .ddr3_ck_n	   (ddr3_ck_n),
     .ddr3_cke	   (ddr3_cke),
     .ddr3_cs_n	   (ddr3_cs_n),
     .ddr3_dm      (ddr3_dm),
     .ddr3_odt     (ddr3_odt),
     .sys_clk      (clk),
     .sys_rstn     (rstn),
     .btn (btn),
     .led          (led)
   );


endmodule
