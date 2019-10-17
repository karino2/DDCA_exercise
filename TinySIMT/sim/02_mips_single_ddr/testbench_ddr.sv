module testbench_ddr_with_jtag_adapter;
   bit          clk = 0;
   bit          rstn = 0;
   logic ui_clk, ui_rstn;
   bit   [3:0]  led;

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

  logic [3:0]   m_axi_awid;
  logic [31:0]  m_axi_awaddr;
  logic [7:0]   m_axi_awlen;
  logic [2:0]   m_axi_awsize;
  logic [1:0]   m_axi_awburst;
  logic         m_axi_awlock;
  logic [3:0]   m_axi_awcache;
  logic [2:0]   m_axi_awprot;
  logic         m_axi_awvalid;
  logic         m_axi_awready;
  logic [31:0]  m_axi_wdata;
  logic [3:0]   m_axi_wstrb;
  logic         m_axi_wlast;
  logic         m_axi_wvalid;
  logic         m_axi_wready;
  logic         m_axi_bready;
  logic [3:0]   m_axi_bid;
  logic [1:0]   m_axi_bresp;
  logic         m_axi_bvalid;
  logic [3:0]   m_axi_arid;
  logic [31:0]  m_axi_araddr;
  logic [7:0]   m_axi_arlen;
  logic [2:0]   m_axi_arsize;
  logic [1:0]   m_axi_arburst;
  logic         m_axi_arlock;
  logic [3:0]   m_axi_arcache;
  logic [2:0]   m_axi_arprot;
  logic         m_axi_arvalid;
  logic         m_axi_arready;
  logic         m_axi_rready;
  logic [3:0]   m_axi_rid;
  logic [31:0]  m_axi_rdata;
  logic [1:0]   m_axi_rresp;
  logic         m_axi_rlast;
  logic         m_axi_rvalid;

    logic [31:0] dramAddress, dramReadData, dramWriteData;
    logic dramWriteEnable, dramReadEnable, dramValid;

   
   initial begin
      forever
        #5ns clk = ~clk; // 100MHz
   end


   initial begin
      rstn = 0;
      #10ns;
      rstn = 1;
      dramWriteEnable = 0;
      dramReadEnable = 0;

      wait(u_ddr_io.init_calib_complete);
      $display("===============");
      $display("===============");
      $display("Calibration Done");
      $display("===============");
      $display("===============");

      $display("init. %h, %h, %h, %h, %h, %h", m_axi_awready, m_axi_wready, m_axi_bid, m_axi_bvalid, m_axi_arready, m_axi_rvalid);
      assert(!dramValid) else $error("dramValid assert wrongly");

      dramAddress = 0;
      dramReadEnable = 1;

      wait(m_axi_arready);
      /*
      $display("arready asserted, %b", u_jtag_adapter.state);
      $display("%h, %h, %h, %h, %h", m_axi_arvalid, m_axi_arready, m_axi_rready, m_axi_rvalid, m_axi_rresp);
      */
      wait(m_axi_rvalid);
      /*
      $display("rdata=%h, %h, %h, %h", m_axi_rdata, u_ddr_io.s_axi_rdata, ddr3_dq, m_axi_araddr);
      $display("rvalid asserted, %h", m_axi_rdata);
      $display("w_rsel=%b, full=%b, empty=%b, rvalid=%b, rready=%b, arvalid=%b, arready=%b", u_ddr_io.w_rsel, u_ddr_io.arf_full, u_ddr_io.arf_empty, u_ddr_io.m_axi_rvalid, u_ddr_io.m_axi_rready, u_ddr_io.m_axi_arvalid, u_ddr_io.m_axi_arready);
      $display("r_rp=%b, r_wp=%b, mem[0]=%h, mem[1]=%h", u_ddr_io.u_arfifo.r_rp, u_ddr_io.u_arfifo.r_wp, u_ddr_io.u_arfifo.u_mem.r_mem[0], u_ddr_io.u_arfifo.u_mem.r_mem[1]);
      $display("%h, %h, %h, %h, %h, %h", m_axi_awready, m_axi_wready, m_axi_bid, m_axi_bvalid, m_axi_arready, m_axi_rvalid);
      $display("dramReadData=%h, m_axi_rdata=%h, %h", dramReadData, m_axi_rdata, m_axi_rid);
      $display("rid=%b, rresp=%b, rlast=%b", m_axi_rid, m_axi_rresp, m_axi_rlast);
      */
      wait(dramValid);

      assert(dramValid) else $error("Read not finished, %b", u_jtag_adapter.state);
      dramReadEnable = 0;
      #50ns;

      $display("first read done. dramReadData=%h", dramReadData);

      dramWriteEnable = 1;
      dramWriteData = 1234;
      wait(m_axi_awready);
      wait(m_axi_wready);
      wait(m_axi_bvalid);
      wait(dramValid);
      assert(dramValid) else $error("Write not finished, %d", u_jtag_adapter.state);
      $display("write done.");

      dramWriteEnable = 0;
      #50ns;
      // $display("after write, now dormant. %h, %h, %h, %h, %h, %h", m_axi_awready, m_axi_wready, m_axi_bid, m_axi_bvalid, m_axi_arready, m_axi_rvalid);

      assert(u_jtag_adapter.state === 0) else $error("not dormant after write");


      // $display("second ready start. arready =%h, arvalid = %h, rready=%h", m_axi_arready, m_axi_arvalid, m_axi_rready);
      assert(!dramValid) else $error("dramValid assert wrongly");

      dramReadEnable = 1;
      wait(m_axi_arready & m_axi_arvalid);
      wait(m_axi_rvalid);
      /*
      $display("rdata=%h, %h, %h, %h", m_axi_rdata, u_ddr_io.s_axi_rdata, ddr3_dq, m_axi_araddr);
      $display("w_rsel=%b, full=%b, empty=%b, rvalid=%b, rready=%b, arvalid=%b, arready=%b", u_ddr_io.w_rsel, u_ddr_io.arf_full, u_ddr_io.arf_empty, u_ddr_io.m_axi_rvalid, u_ddr_io.m_axi_rready, u_ddr_io.m_axi_arvalid, u_ddr_io.m_axi_arready);
      $display("r_rp=%b, r_wp=%b, mem[0]=%h, mem[1]=%h", u_ddr_io.u_arfifo.r_rp, u_ddr_io.u_arfifo.r_wp, u_ddr_io.u_arfifo.u_mem.r_mem[0], u_ddr_io.u_arfifo.u_mem.r_mem[1]);
      $display("second read: %h, %h, %h, %h", dramReadData, m_axi_rdata, m_axi_rid,  u_ddr_io.s_axi_rdata);
      $display("w_rsel=%b, full=%b, empty=%b, rvalid=%b, rready=%b, arvalid=%b, arready=%b", u_ddr_io.w_rsel, u_ddr_io.arf_full, u_ddr_io.arf_empty, u_ddr_io.m_axi_rvalid, u_ddr_io.m_axi_rready, u_ddr_io.m_axi_arvalid, u_ddr_io.m_axi_arready);
      $display("r_rp=%b, r_wp=%b, mem[0]=%h, mem[1]=%h", u_ddr_io.u_arfifo.r_rp, u_ddr_io.u_arfifo.r_wp, u_ddr_io.u_arfifo.u_mem.r_mem[0], u_ddr_io.u_arfifo.u_mem.r_mem[1]);
      */
      wait(dramValid);
      assert(dramValid) else $error("Read2 not finished, %d", u_jtag_adapter.state);
      assert(dramReadData === 1234) else $error("written data is not read: %h", dramReadData);
      $display("second read2: dramReadData=%h", dramReadData);

      dramReadEnable = 0;

      #1us;
      $stop(0);
   end

   glbl glbl();

   ddr_io u_ddr_io(
    .ui_clk(ui_clk),
    .ui_rstn(ui_rstn),
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
    .m_axi_awid(m_axi_awid),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awlen(m_axi_awlen),
    .m_axi_awsize(m_axi_awsize),
    .m_axi_awburst(m_axi_awburst),
    .m_axi_awlock(m_axi_awlock),
    .m_axi_awcache(m_axi_awcache),
    .m_axi_awprot(m_axi_awprot),
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wstrb(m_axi_wstrb),
    .m_axi_wlast(m_axi_wlast),
    .m_axi_wvalid(m_axi_wlast),
    .m_axi_wready(m_axi_wready),
    .m_axi_bready(m_axi_bready),
    .m_axi_bid(m_axi_bid),
    .m_axi_bresp(m_axi_bresp),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_arid(m_axi_arid),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst),
    .m_axi_arlock(m_axi_arlock),
    .m_axi_arcache(m_axi_arcache),
    .m_axi_arprot(m_axi_arprot),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rready(m_axi_rready),
    .m_axi_rid(m_axi_rid),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rlast(m_axi_rlast),
    .m_axi_rvalid(m_axi_rvalid)

   );
   
  jtag_adapter u_jtag_adapter (
    .clk(ui_clk),                     // input wire aclk
    .reset(!ui_rstn),
    .dramAddress(dramAddress), .dramWriteData(dramWriteData),
    .readEnable(dramReadEnable), .writeEnable(dramWriteEnable),
    .dramReadData(dramReadData),
    .dramValid(dramValid),

    .m_axi_awid(m_axi_awid),        // output wire [3 : 0] m_axi_awid
    .m_axi_awaddr(m_axi_awaddr),    // output wire [31 : 0] m_axi_awaddr
    .m_axi_awlen(m_axi_awlen),      // output wire [7 : 0] m_axi_awlen
    .m_axi_awsize(m_axi_awsize),    // output wire [2 : 0] m_axi_awsize
    .m_axi_awburst(m_axi_awburst),  // output wire [1 : 0] m_axi_awburst
    .m_axi_awlock(m_axi_awlock),    // output wire m_axi_awlock
    .m_axi_awcache(m_axi_awcache),  // output wire [3 : 0] m_axi_awcache
    .m_axi_awprot(m_axi_awprot),    // output wire [2 : 0] m_axi_awprot
    .m_axi_awvalid(m_axi_awvalid),  // output wire m_axi_awvalid
    .m_axi_awready(m_axi_awready),  // input wire m_axi_awready
    .m_axi_wdata(m_axi_wdata),      // output wire [31 : 0] m_axi_wdata
    .m_axi_wstrb(m_axi_wstrb),      // output wire [3 : 0] m_axi_wstrb
    .m_axi_wlast(m_axi_wlast),      // output wire m_axi_wlast
    .m_axi_wvalid(m_axi_wvalid),    // output wire m_axi_wvalid
    .m_axi_wready(m_axi_wready),    // input wire m_axi_wready
    .m_axi_bid(m_axi_bid),          // input wire [3 : 0] m_axi_bid
    .m_axi_bresp(m_axi_bresp),      // input wire [1 : 0] m_axi_bresp
    .m_axi_bvalid(m_axi_bvalid),    // input wire m_axi_bvalid
    .m_axi_bready(m_axi_bready),    // output wire m_axi_bready
    .m_axi_arid(m_axi_arid),        // output wire [3 : 0] m_axi_arid
    .m_axi_araddr(m_axi_araddr),    // output wire [31 : 0] m_axi_araddr
    .m_axi_arlen(m_axi_arlen),      // output wire [7 : 0] m_axi_arlen
    .m_axi_arsize(m_axi_arsize),    // output wire [2 : 0] m_axi_arsize
    .m_axi_arburst(m_axi_arburst),  // output wire [1 : 0] m_axi_arburst
    .m_axi_arlock(m_axi_arlock),    // output wire m_axi_arlock
    .m_axi_arcache(m_axi_arcache),  // output wire [3 : 0] m_axi_arcache
    .m_axi_arprot(m_axi_arprot),    // output wire [2 : 0] m_axi_arprot
    .m_axi_arvalid(m_axi_arvalid),  // output wire m_axi_arvalid
    .m_axi_arready(m_axi_arready),  // input wire m_axi_arready
    .m_axi_rid(m_axi_rid),          // input wire [3 : 0] m_axi_rid
    .m_axi_rdata(m_axi_rdata),      // input wire [31 : 0] m_axi_rdata
    .m_axi_rresp(m_axi_rresp),      // input wire [1 : 0] m_axi_rresp
    .m_axi_rlast(m_axi_rlast),      // input wire m_axi_rlast
    .m_axi_rvalid(m_axi_rvalid),    // input wire m_axi_rvalid
    .m_axi_rready(m_axi_rready)     // output wire m_axi_rready
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




// this test is not working and does not yet investigate the reason.
module testbench_integrate_all_d2s_check_led;
   bit          clk = 0;
   bit          rstn = 0;
   logic ui_clk, ui_rstn, cpu_reset;
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

      $display("halt=%h", dut.halt);
      $display("mem[3]=%h", dut.u_mips_sram_dmac_led.DataMem.SRAM[3]);

      wait(dut.halt);

      assert(led === 3'b101) else $error("led wrong, %b", led);
      // assert(ledval === 3'b111) else $error("ledval wrong, %b", ledval);


      #1us;
      $stop(0);
   end

   glbl glbl();


   arty_top dut (
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
