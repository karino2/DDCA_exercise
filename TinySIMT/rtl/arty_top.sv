
module ddr_io (
  output logic ui_clk,  // ui_clk 83.333MHz
  output logic ui_rstn,
  inout [15:0]  ddr3_dq,
  inout [1:0]   ddr3_dqs_n,
  inout [1:0]   ddr3_dqs_p,
  output [13:0] ddr3_addr,
  output [2:0]  ddr3_ba,
  output        ddr3_ras_n,
  output        ddr3_cas_n,
  output        ddr3_we_n,
  output        ddr3_reset_n,
  output [0:0]  ddr3_ck_p,
  output [0:0]  ddr3_ck_n,
  output [0:0]  ddr3_cke,
  output [0:0]  ddr3_cs_n,
  output [1:0]  ddr3_dm,
  output [0:0]  ddr3_odt,
  input         sys_clk,
  input         sys_rstn,
  // jtag like signal.
  input logic [3:0]   m_axi_awid,
  input logic [31:0]  m_axi_awaddr,
  input logic [7:0]   m_axi_awlen,
  input logic [2:0]   m_axi_awsize,
  input logic [1:0]   m_axi_awburst,
  input logic         m_axi_awlock,
  input logic [3:0]   m_axi_awcache,
  input logic [2:0]   m_axi_awprot,
  input logic         m_axi_awvalid,
  output logic         m_axi_awready,
  input logic [31:0]  m_axi_wdata,
  input logic [3:0]   m_axi_wstrb,
  input logic         m_axi_wlast,
  input logic         m_axi_wvalid,
  output logic         m_axi_wready,
  input logic         m_axi_bready,
  output logic [3:0]   m_axi_bid,
  output logic [1:0]   m_axi_bresp,
  output logic         m_axi_bvalid,
  input logic [3:0]   m_axi_arid,
  input logic [31:0]  m_axi_araddr,
  input logic [7:0]   m_axi_arlen,
  input logic [2:0]   m_axi_arsize,
  input logic [1:0]   m_axi_arburst,
  input logic         m_axi_arlock,
  input logic [3:0]   m_axi_arcache,
  input logic [2:0]   m_axi_arprot,
  input logic         m_axi_arvalid,
  output logic         m_axi_arready,
  input logic         m_axi_rready,
  output logic [3:0]   m_axi_rid,
  output logic [31:0]  m_axi_rdata,
  output logic [1:0]   m_axi_rresp,
  output logic         m_axi_rlast,
  output logic         m_axi_rvalid
);
   logic        sys_clk_i; // 166MHz
   logic        clk_ref_i; // 200MHz
   logic        locked;
   logic        mem_rstn;

   logic        srst;
   logic        init_calib_complete;
   logic        tg_compare_error;
   logic        mig_locked;


   logic [3:0]   s_axi_awid;
   logic [27:0]  s_axi_awaddr;
   logic [7:0]   s_axi_awlen;
   logic [2:0]   s_axi_awsize;
   logic [1:0]   s_axi_awburst;
   logic [0:0]   s_axi_awlock;
   logic [3:0]   s_axi_awcache;
   logic [2:0]   s_axi_awprot;
   logic         s_axi_awvalid;
   logic         s_axi_awready;
   logic [127:0] s_axi_wdata;
   logic [15:0]  s_axi_wstrb;
   logic         s_axi_wlast;
   logic         s_axi_wvalid;
   logic         s_axi_wready;
   logic         s_axi_bready;
   logic [3:0]   s_axi_bid;
   logic [1:0]   s_axi_bresp;
   logic         s_axi_bvalid;
   logic [3:0]   s_axi_arid;
   logic [27:0]  s_axi_araddr;
   logic [7:0]   s_axi_arlen;
   logic [2:0]   s_axi_arsize;
   logic [1:0]   s_axi_arburst;
   logic [0:0]   s_axi_arlock;
   logic [3:0]   s_axi_arcache;
   logic [2:0]   s_axi_arprot;
   logic         s_axi_arvalid;
   logic         s_axi_arready;
   logic         s_axi_rready;
   logic [3:0]   s_axi_rid;
   logic [127:0] s_axi_rdata;
   logic [1:0]   s_axi_rresp;
   logic         s_axi_rlast;
   logic         s_axi_rvalid;

//-------------------------------------------------------------------------------
// Clock/Reset
//-------------------------------------------------------------------------------
logic [7:0]      r_locked;

always @(posedge sys_clk, negedge sys_rstn)
  if (!sys_rstn)
    r_locked <= 0;
  else if (!locked)
    r_locked <= 0;
  else if (locked && r_locked != 8'hff)
    r_locked <= r_locked + 1;

always @(posedge sys_clk, negedge sys_rstn)
  if (!sys_rstn)
    mem_rstn <= 0;
  else if (r_locked[7])
    mem_rstn <= 1;
  else
    mem_rstn <= 0;

always @(posedge ui_clk)
  if (mig_locked)
  // if (mig_locked & !ui_rstn)
//    ui_rstn <= srst;
    ui_rstn <= ~srst;
  else
    ui_rstn <= 1'b0;

//-------------------------------------------------------------------------------
// MMCM
//-------------------------------------------------------------------------------
mmcm u_mmcm(
  .clk_in1  (sys_clk),
  .resetn   (sys_rstn),
  .clk_out1 (sys_clk_i), // 166MHz
  .clk_out2 (clk_ref_i), // 200MHz
  .clk_out3 (),          // 25MHz for ether clock
  .locked   (locked)
);

//-------------------------------------------------------------------------------
// AXI
//-------------------------------------------------------------------------------

// AW/W
logic  awf_full;
logic  awf_empty;
logic  w_awready;
logic  [1:0] w_wsel;
logic  [3:0] w_wstrb;
logic  w_wready;

assign w_awready     = s_axi_awready && !awf_full;
assign s_axi_awvalid = m_axi_awvalid && w_awready;
assign m_axi_awready = w_awready;

assign s_axi_awid    = m_axi_awid;
assign s_axi_awaddr  = {m_axi_awaddr[27:4], 4'b0};
assign s_axi_awlen   = m_axi_awlen;
assign s_axi_awsize  = m_axi_awsize;
assign s_axi_awburst = m_axi_awburst;
assign s_axi_awlock  = m_axi_awlock;
assign s_axi_awcache = m_axi_awcache;
assign s_axi_awprot  = m_axi_awprot;

cmn_fifo #(.DW(4+2), .AW(1))
u_awfifo(
  .clk      (ui_clk),
  .rstn     (ui_rstn),
  .we       (m_axi_awvalid && m_axi_awready),
  .wdata    ({m_axi_wstrb, m_axi_awaddr[3:2]}),
  .re       (s_axi_wvalid && s_axi_wready),
  .rdata    ({w_wstrb, w_wsel}),
  .full     (awf_full),
  .empty    (awf_empty)
);

assign w_wready     = s_axi_wready && !awf_empty;
assign s_axi_wvalid = m_axi_wvalid && w_wready;
assign m_axi_wready = w_wready;

assign s_axi_wdata = {4{m_axi_wdata}};
   
always_comb
   case (w_wsel)
     2'h0: s_axi_wstrb = {12'b0, w_wstrb};
     2'h1: s_axi_wstrb = { 8'b0, w_wstrb, 4'b0};
     2'h2: s_axi_wstrb = { 4'b0, w_wstrb, 8'b0};
     2'h3: s_axi_wstrb = {w_wstrb, 12'b0};
   endcase
   
assign s_axi_wlast = m_axi_wlast;

// B
assign m_axi_bid    = s_axi_bid;
assign m_axi_bresp  = s_axi_bresp;
assign m_axi_bvalid = s_axi_bvalid;
assign s_axi_bready = m_axi_bready;

// AR
logic  arf_full;
logic  arf_empty;
logic  w_arready;
logic  [1:0] w_rsel;

assign w_arready     = s_axi_arready && !arf_full;
assign s_axi_arvalid = m_axi_arvalid && w_arready;
assign m_axi_arready = w_arready;

assign s_axi_arid    = m_axi_arid;
assign s_axi_araddr  = {m_axi_araddr[27:4], 4'b0};
assign s_axi_arlen   = m_axi_arlen;
assign s_axi_arsize  = m_axi_arsize;
assign s_axi_arburst = m_axi_arburst;
assign s_axi_arlock  = m_axi_arlock;
assign s_axi_arcache = m_axi_arcache;
assign s_axi_arprot  = m_axi_arprot;

cmn_fifo #(.DW(2), .AW(1))
u_arfifo(
  .clk      (ui_clk),
  .rstn     (ui_rstn),
  .we       (m_axi_arvalid && m_axi_arready),
  .wdata    (m_axi_araddr[3:2]),
  .re       (m_axi_rvalid && m_axi_rready),
  .rdata    (w_rsel),
  .full     (arf_full),
  .empty    (arf_empty)
);

// R
assign m_axi_rvalid = s_axi_rvalid;
assign m_axi_rid    = s_axi_rid;
   
always_comb
   case (w_rsel)
     2'h0: m_axi_rdata = s_axi_rdata[31:0];
     2'h1: m_axi_rdata = s_axi_rdata[63:32];
     2'h2: m_axi_rdata = s_axi_rdata[95:64];
     2'h3: m_axi_rdata = s_axi_rdata[127:96];
   endcase
   
assign m_axi_rresp  = s_axi_rresp;
assign m_axi_rlast  = s_axi_rlast;
assign s_axi_rready = m_axi_rready;
//-------------------------------------------------------------------------------
// MIG
//-------------------------------------------------------------------------------
mig u_mig (
// Memory interface ports
  .ddr3_addr                      (ddr3_addr),
  .ddr3_ba                        (ddr3_ba),
  .ddr3_cas_n                     (ddr3_cas_n),
  .ddr3_ck_n                      (ddr3_ck_n),
  .ddr3_ck_p                      (ddr3_ck_p),
  .ddr3_cke                       (ddr3_cke),
  .ddr3_ras_n                     (ddr3_ras_n),
  .ddr3_we_n                      (ddr3_we_n),
  .ddr3_dq                        (ddr3_dq),
  .ddr3_dqs_n                     (ddr3_dqs_n),
  .ddr3_dqs_p                     (ddr3_dqs_p),
  .ddr3_reset_n                   (ddr3_reset_n),
  .init_calib_complete            (init_calib_complete),
  .ddr3_cs_n                      (ddr3_cs_n),
  .ddr3_dm                        (ddr3_dm),
  .ddr3_odt                       (ddr3_odt),
// Application interface ports
  .ui_clk                         (ui_clk),  // out
  .ui_clk_sync_rst                (srst), // out
  .mmcm_locked                    (mig_locked),
  .aresetn                        (ui_rstn),
  .app_sr_req                     (1'b0),
  .app_ref_req                    (1'b0),
  .app_zq_req                     (1'b0),
  .app_sr_active                  (),
  .app_ref_ack                    (),
  .app_zq_ack                     (),
// Slave Interface Write Address Ports
  .s_axi_awid                     (s_axi_awid),
  .s_axi_awaddr                   (s_axi_awaddr),
  .s_axi_awlen                    (s_axi_awlen),
  .s_axi_awsize                   (s_axi_awsize),
  .s_axi_awburst                  (s_axi_awburst),
  .s_axi_awlock                   (s_axi_awlock),
  .s_axi_awcache                  (s_axi_awcache),
  .s_axi_awprot                   (s_axi_awprot),
  .s_axi_awqos                    (4'h0),
  .s_axi_awvalid                  (s_axi_awvalid),
  .s_axi_awready                  (s_axi_awready),
// Slave Interface Write Data Ports
  .s_axi_wdata                    (s_axi_wdata),
  .s_axi_wstrb                    (s_axi_wstrb),
  .s_axi_wlast                    (s_axi_wlast),
  .s_axi_wvalid                   (s_axi_wvalid),
  .s_axi_wready                   (s_axi_wready),
// Slave Interface Write Response Ports
  .s_axi_bid                      (s_axi_bid),
  .s_axi_bresp                    (s_axi_bresp),
  .s_axi_bvalid                   (s_axi_bvalid),
  .s_axi_bready                   (s_axi_bready),
// Slave Interface Read Address Ports
  .s_axi_arid                     (s_axi_arid),
  .s_axi_araddr                   (s_axi_araddr),
  .s_axi_arlen                    (s_axi_arlen),
  .s_axi_arsize                   (s_axi_arsize),
  .s_axi_arburst                  (s_axi_arburst),
  .s_axi_arlock                   (s_axi_arlock),
  .s_axi_arcache                  (s_axi_arcache),
  .s_axi_arprot                   (s_axi_arprot),
  .s_axi_arqos                    (4'h0),
  .s_axi_arvalid                  (s_axi_arvalid),
  .s_axi_arready                  (s_axi_arready),
// Slave Interface Read Data Ports
  .s_axi_rid                      (s_axi_rid),
  .s_axi_rdata                    (s_axi_rdata),
  .s_axi_rresp                    (s_axi_rresp),
  .s_axi_rlast                    (s_axi_rlast),
  .s_axi_rvalid                   (s_axi_rvalid),
  .s_axi_rready                   (s_axi_rready),
// System Clock Ports
  .sys_clk_i                      (sys_clk_i),
// Reference Clock Ports
  .clk_ref_i                      (clk_ref_i),
  .device_temp                    (),
  .sys_rst                        (mem_rstn)
);

endmodule


module mux_axi(input logic control,
  // axi1
  input logic [3:0]   m1_axi_awid,
  input logic [31:0]  m1_axi_awaddr,
  input logic [7:0]   m1_axi_awlen,
  input logic [2:0]   m1_axi_awsize,
  input logic [1:0]   m1_axi_awburst,
  input logic         m1_axi_awlock,
  input logic [3:0]   m1_axi_awcache,
  input logic [2:0]   m1_axi_awprot,
  input logic         m1_axi_awvalid,
  output logic         m1_axi_awready,
  input logic [31:0]  m1_axi_wdata,
  input logic [3:0]   m1_axi_wstrb,
  input logic         m1_axi_wlast,
  input logic         m1_axi_wvalid,
  output logic         m1_axi_wready,
  input logic         m1_axi_bready,
  output logic [3:0]   m1_axi_bid,
  output logic [1:0]   m1_axi_bresp,
  output logic         m1_axi_bvalid,
  input logic [3:0]   m1_axi_arid,
  input logic [31:0]  m1_axi_araddr,
  input logic [7:0]   m1_axi_arlen,
  input logic [2:0]   m1_axi_arsize,
  input logic [1:0]   m1_axi_arburst,
  input logic         m1_axi_arlock,
  input logic [3:0]   m1_axi_arcache,
  input logic [2:0]   m1_axi_arprot,
  input logic         m1_axi_arvalid,
  output logic         m1_axi_arready,
  input logic         m1_axi_rready,
  output logic [3:0]   m1_axi_rid,
  output logic [31:0]  m1_axi_rdata,
  output logic [1:0]   m1_axi_rresp,
  output logic         m1_axi_rlast,
  output logic         m1_axi_rvalid,

  // axi2
  input logic [3:0]   m2_axi_awid,
  input logic [31:0]  m2_axi_awaddr,
  input logic [7:0]   m2_axi_awlen,
  input logic [2:0]   m2_axi_awsize,
  input logic [1:0]   m2_axi_awburst,
  input logic         m2_axi_awlock,
  input logic [3:0]   m2_axi_awcache,
  input logic [2:0]   m2_axi_awprot,
  input logic         m2_axi_awvalid,
  output logic         m2_axi_awready,
  input logic [31:0]  m2_axi_wdata,
  input logic [3:0]   m2_axi_wstrb,
  input logic         m2_axi_wlast,
  input logic         m2_axi_wvalid,
  output logic         m2_axi_wready,
  input logic         m2_axi_bready,
  output logic [3:0]   m2_axi_bid,
  output logic [1:0]   m2_axi_bresp,
  output logic         m2_axi_bvalid,
  input logic [3:0]   m2_axi_arid,
  input logic [31:0]  m2_axi_araddr,
  input logic [7:0]   m2_axi_arlen,
  input logic [2:0]   m2_axi_arsize,
  input logic [1:0]   m2_axi_arburst,
  input logic         m2_axi_arlock,
  input logic [3:0]   m2_axi_arcache,
  input logic [2:0]   m2_axi_arprot,
  input logic         m2_axi_arvalid,
  output logic         m2_axi_arready,
  input logic         m2_axi_rready,
  output logic [3:0]   m2_axi_rid,
  output logic [31:0]  m2_axi_rdata,
  output logic [1:0]   m2_axi_rresp,
  output logic         m2_axi_rlast,
  output logic         m2_axi_rvalid,

  // output
  output [3:0]m_axi_awid,
  output [31:0]m_axi_awaddr,
  output [7:0]m_axi_awlen,
  output [2:0]m_axi_awsize,
  output [1:0]m_axi_awburst,
  output m_axi_awlock,
  output [3:0]m_axi_awcache,
  output [2:0]m_axi_awprot,
  output m_axi_awvalid,
  input m_axi_awready,
  output [31:0]m_axi_wdata,
  output [3:0]m_axi_wstrb,
  output m_axi_wlast,
  output m_axi_wvalid,
  input m_axi_wready,
  input [3:0]m_axi_bid,
  input [1:0]m_axi_bresp,
  input m_axi_bvalid,
  output m_axi_bready,
  output [3:0]m_axi_arid,
  output [31:0]m_axi_araddr,
  output [7:0]m_axi_arlen,
  output [2:0]m_axi_arsize,
  output [1:0]m_axi_arburst,
  output m_axi_arlock,
  output [3:0]m_axi_arcache,
  output [2:0]m_axi_arprot,
  output m_axi_arvalid,
  input m_axi_arready,
  input [3:0]m_axi_rid,
  input [31:0]m_axi_rdata,
  input [1:0]m_axi_rresp,
  input m_axi_rlast,
  input m_axi_rvalid,
  output m_axi_rready
);
  assign m_axi_awid    = control? m2_axi_awid    : m1_axi_awid    ;
  assign m_axi_awaddr  = control? m2_axi_awaddr  : m1_axi_awaddr  ;
  assign m_axi_awlen   = control? m2_axi_awlen   : m1_axi_awlen   ;
  assign m_axi_awsize  = control? m2_axi_awsize  : m1_axi_awsize  ;
  assign m_axi_awburst = control? m2_axi_awburst : m1_axi_awburst ;
  assign m_axi_awlock  = control? m2_axi_awlock  : m1_axi_awlock  ;
  assign m_axi_awcache = control? m2_axi_awcache : m1_axi_awcache ;
  assign m_axi_awprot  = control? m2_axi_awprot  : m1_axi_awprot  ;
  assign m_axi_awvalid = control? m2_axi_awvalid : m1_axi_awvalid ;
  assign m2_axi_awready = control?  m_axi_awready: 0;
  assign m1_axi_awready = control?  0: m_axi_awready;
  assign m_axi_wdata   = control? m2_axi_wdata   : m1_axi_wdata   ;
  assign m_axi_wstrb   = control? m2_axi_wstrb   : m1_axi_wstrb   ;
  assign m_axi_wlast   = control? m2_axi_wlast   : m1_axi_wlast   ;
  assign m_axi_wvalid  = control? m2_axi_wvalid  : m1_axi_wvalid  ;
  assign m2_axi_wready = control?  m_axi_wready: 0;
  assign m1_axi_wready = control?  0: m_axi_wready;


  assign m2_axi_bid = control?  m_axi_bid: 4'b0;
  assign m1_axi_bid = control?  4'b0: m_axi_bid;
  assign m2_axi_bresp = control?  m_axi_bresp: 2'b0;
  assign m1_axi_bresp = control?  2'b0: m_axi_bresp;
  assign m2_axi_bvalid = control?  m_axi_bvalid: 0;
  assign m1_axi_bvalid = control?  0: m_axi_bvalid;

  assign m_axi_bready  = control? m2_axi_bready  : m1_axi_bready  ;
  assign m_axi_arid    = control? m2_axi_arid    : m1_axi_arid    ;
  assign m_axi_araddr  = control? m2_axi_araddr  : m1_axi_araddr  ;
  assign m_axi_arlen   = control? m2_axi_arlen   : m1_axi_arlen   ;
  assign m_axi_arsize  = control? m2_axi_arsize  : m1_axi_arsize  ;
  assign m_axi_arburst = control? m2_axi_arburst : m1_axi_arburst ;
  assign m_axi_arlock  = control? m2_axi_arlock  : m1_axi_arlock  ;
  assign m_axi_arcache = control? m2_axi_arcache : m1_axi_arcache ;
  assign m_axi_arprot  = control? m2_axi_arprot  : m1_axi_arprot  ;
  assign m_axi_arvalid = control? m2_axi_arvalid : m1_axi_arvalid ;

  assign m2_axi_arready = control?  m_axi_arready: 0;
  assign m1_axi_arready = control?  0: m_axi_arready;

  assign m2_axi_rid = control?  m_axi_rid: 4'b0;
  assign m1_axi_rid = control?  4'b0: m_axi_rid;

  assign m2_axi_rdata = control?  m_axi_rdata: 32'b0;
  assign m1_axi_rdata = control?  32'b0: m_axi_rdata;

  assign m2_axi_rresp = control?  m_axi_rresp: 2'b0;
  assign m1_axi_rresp = control?  2'b0: m_axi_rresp;

  assign m2_axi_rlast = control?  m_axi_rlast: 0;
  assign m1_axi_rlast = control?  0: m_axi_rlast;

  assign m2_axi_rvalid = control?  m_axi_rvalid: 0;
  assign m1_axi_rvalid = control?  0: m_axi_rvalid;

  assign m_axi_rready  = control? m2_axi_rready  : m1_axi_rready  ;

endmodule


// module arty_top_single #(parameter FILENAME="s2d_test.mem")  (
// module arty_top_single #(parameter FILENAME="d2s_simple_test.mem")  (
// module arty_top_single #(parameter FILENAME="dram2dram_copy_test.mem")  (
// module arty_top_single #(parameter FILENAME="d2s_simple_writeback_test.mem")  (
module arty_top_single #(parameter FILENAME="dram2dram_register_test.mem")  (
  inout [15:0]  ddr3_dq,
  inout [1:0]   ddr3_dqs_n,
  inout [1:0]   ddr3_dqs_p,
  output [13:0] ddr3_addr,
  output [2:0]  ddr3_ba,
  output        ddr3_ras_n,
  output        ddr3_cas_n,
  output        ddr3_we_n,
  output        ddr3_reset_n,
  output [0:0]  ddr3_ck_p,
  output [0:0]  ddr3_ck_n,
  output [0:0]  ddr3_cke,
  output [0:0]  ddr3_cs_n,
  output [1:0]  ddr3_dm,
  output [0:0]  ddr3_odt,
  output [3:0]  led,
  input [3:0] btn,
  input         sys_clk,
  input         sys_rstn
  );

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

  logic [3:0]   m1_axi_awid;
  logic [31:0]  m1_axi_awaddr;
  logic [7:0]   m1_axi_awlen;
  logic [2:0]   m1_axi_awsize;
  logic [1:0]   m1_axi_awburst;
  logic         m1_axi_awlock;
  logic [3:0]   m1_axi_awcache;
  logic [2:0]   m1_axi_awprot;
  logic         m1_axi_awvalid;
  logic         m1_axi_awready;
  logic [31:0]  m1_axi_wdata;
  logic [3:0]   m1_axi_wstrb;
  logic         m1_axi_wlast;
  logic         m1_axi_wvalid;
  logic         m1_axi_wready;
  logic         m1_axi_bready;
  logic [3:0]   m1_axi_bid;
  logic [1:0]   m1_axi_bresp;
  logic         m1_axi_bvalid;
  logic [3:0]   m1_axi_arid;
  logic [31:0]  m1_axi_araddr;
  logic [7:0]   m1_axi_arlen;
  logic [2:0]   m1_axi_arsize;
  logic [1:0]   m1_axi_arburst;
  logic         m1_axi_arlock;
  logic [3:0]   m1_axi_arcache;
  logic [2:0]   m1_axi_arprot;
  logic         m1_axi_arvalid;
  logic         m1_axi_arready;
  logic         m1_axi_rready;
  logic [3:0]   m1_axi_rid;
  logic [31:0]  m1_axi_rdata;
  logic [1:0]   m1_axi_rresp;
  logic         m1_axi_rlast;
  logic         m1_axi_rvalid;

  logic [3:0]   m2_axi_awid;
  logic [31:0]  m2_axi_awaddr;
  logic [7:0]   m2_axi_awlen;
  logic [2:0]   m2_axi_awsize;
  logic [1:0]   m2_axi_awburst;
  logic         m2_axi_awlock;
  logic [3:0]   m2_axi_awcache;
  logic [2:0]   m2_axi_awprot;
  logic         m2_axi_awvalid;
  logic         m2_axi_awready;
  logic [31:0]  m2_axi_wdata;
  logic [3:0]   m2_axi_wstrb;
  logic         m2_axi_wlast;
  logic         m2_axi_wvalid;
  logic         m2_axi_wready;
  logic         m2_axi_bready;
  logic [3:0]   m2_axi_bid;
  logic [1:0]   m2_axi_bresp;
  logic         m2_axi_bvalid;
  logic [3:0]   m2_axi_arid;
  logic [31:0]  m2_axi_araddr;
  logic [7:0]   m2_axi_arlen;
  logic [2:0]   m2_axi_arsize;
  logic [1:0]   m2_axi_arburst;
  logic         m2_axi_arlock;
  logic [3:0]   m2_axi_arcache;
  logic [2:0]   m2_axi_arprot;
  logic         m2_axi_arvalid;
  logic         m2_axi_arready;
  logic         m2_axi_rready;
  logic [3:0]   m2_axi_rid;
  logic [31:0]  m2_axi_rdata;
  logic [1:0]   m2_axi_rresp;
  logic         m2_axi_rlast;
  logic         m2_axi_rvalid;


  logic ui_clk, ui_rstn;



  jtag_axi u_jtag_axi (
    .aclk(ui_clk),                     // input wire aclk
    .aresetn(ui_rstn),                 // input wire aresetn
    .m_axi_awid(m2_axi_awid),        // output wire [3 : 0] m_axi_awid
    .m_axi_awaddr(m2_axi_awaddr),    // output wire [31 : 0] m_axi_awaddr
    .m_axi_awlen(m2_axi_awlen),      // output wire [7 : 0] m_axi_awlen
    .m_axi_awsize(m2_axi_awsize),    // output wire [2 : 0] m_axi_awsize
    .m_axi_awburst(m2_axi_awburst),  // output wire [1 : 0] m_axi_awburst
    .m_axi_awlock(m2_axi_awlock),    // output wire m_axi_awlock
    .m_axi_awcache(m2_axi_awcache),  // output wire [3 : 0] m_axi_awcache
    .m_axi_awprot(m2_axi_awprot),    // output wire [2 : 0] m_axi_awprot
    .m_axi_awqos(),                 // output wire [3 : 0] m_axi_awqos
    .m_axi_awvalid(m2_axi_awvalid),  // output wire m_axi_awvalid
    .m_axi_awready(m2_axi_awready),  // input wire m_axi_awready
    .m_axi_wdata(m2_axi_wdata),      // output wire [31 : 0] m_axi_wdata
    .m_axi_wstrb(m2_axi_wstrb),      // output wire [3 : 0] m_axi_wstrb
    .m_axi_wlast(m2_axi_wlast),      // output wire m_axi_wlast
    .m_axi_wvalid(m2_axi_wvalid),    // output wire m_axi_wvalid
    .m_axi_wready(m2_axi_wready),    // input wire m_axi_wready
    .m_axi_bid(m2_axi_bid),          // input wire [3 : 0] m_axi_bid
    .m_axi_bresp(m2_axi_bresp),      // input wire [1 : 0] m_axi_bresp
    .m_axi_bvalid(m2_axi_bvalid),    // input wire m_axi_bvalid
    .m_axi_bready(m2_axi_bready),    // output wire m_axi_bready
    .m_axi_arid(m2_axi_arid),        // output wire [3 : 0] m_axi_arid
    .m_axi_araddr(m2_axi_araddr),    // output wire [31 : 0] m_axi_araddr
    .m_axi_arlen(m2_axi_arlen),      // output wire [7 : 0] m_axi_arlen
    .m_axi_arsize(m2_axi_arsize),    // output wire [2 : 0] m_axi_arsize
    .m_axi_arburst(m2_axi_arburst),  // output wire [1 : 0] m_axi_arburst
    .m_axi_arlock(m2_axi_arlock),    // output wire m_axi_arlock
    .m_axi_arcache(m2_axi_arcache),  // output wire [3 : 0] m_axi_arcache
    .m_axi_arprot(m2_axi_arprot),    // output wire [2 : 0] m_axi_arprot
    .m_axi_arqos(),                 // output wire [3 : 0] m_axi_arqos
    .m_axi_arvalid(m2_axi_arvalid),  // output wire m_axi_arvalid
    .m_axi_arready(m2_axi_arready),  // input wire m_axi_arready
    .m_axi_rid(m2_axi_rid),          // input wire [3 : 0] m_axi_rid
    .m_axi_rdata(m2_axi_rdata),      // input wire [31 : 0] m_axi_rdata
    .m_axi_rresp(m2_axi_rresp),      // input wire [1 : 0] m_axi_rresp
    .m_axi_rlast(m2_axi_rlast),      // input wire m_axi_rlast
    .m_axi_rvalid(m2_axi_rvalid),    // input wire m_axi_rvalid
    .m_axi_rready(m2_axi_rready)     // output wire m_axi_rready
  );

  ddr_io u_ddr_io(
    .ui_clk(ui_clk),
    .ui_rstn(ui_rstn),
    .ddr3_dq(ddr3_dq),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dqs_p(ddr3_dqs_p),
    .ddr3_addr(ddr3_addr),
    .ddr3_ba(ddr3_ba),
    .ddr3_ras_n(ddr3_ras_n),
    .ddr3_cas_n(ddr3_cas_n),
    .ddr3_we_n(ddr3_we_n),
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_ck_p(ddr3_ck_p),
    .ddr3_ck_n(ddr3_ck_n),
    .ddr3_cke(ddr3_cke),
    .ddr3_cs_n(ddr3_cs_n),
    .ddr3_dm(ddr3_dm),
    .ddr3_odt(ddr3_odt),
    .sys_clk(sys_clk),
    .sys_rstn(sys_rstn & !btn[0]),

/*
    .m_axi_awid(m2_axi_awid),
    .m_axi_awaddr(m2_axi_awaddr),
    .m_axi_awlen(m2_axi_awlen),
    .m_axi_awsize(m2_axi_awsize),
    .m_axi_awburst(m2_axi_awburst),
    .m_axi_awlock(m2_axi_awlock),
    .m_axi_awcache(m2_axi_awcache),
    .m_axi_awprot(m2_axi_awprot),
    .m_axi_awvalid(m2_axi_awvalid),
    .m_axi_awready(m2_axi_awready),
    .m_axi_wdata(m2_axi_wdata),
    .m_axi_wstrb(m2_axi_wstrb),
    .m_axi_wlast(m2_axi_wlast),
    .m_axi_wvalid(m2_axi_wlast),
    .m_axi_wready(m2_axi_wready),
    .m_axi_bready(m2_axi_bready),
    .m_axi_bid(m2_axi_bid),
    .m_axi_bresp(m2_axi_bresp),
    .m_axi_bvalid(m2_axi_bvalid),
    .m_axi_arid(m2_axi_arid),
    .m_axi_araddr(m2_axi_araddr),
    .m_axi_arlen(m2_axi_arlen),
    .m_axi_arsize(m2_axi_arsize),
    .m_axi_arburst(m2_axi_arburst),
    .m_axi_arlock(m2_axi_arlock),
    .m_axi_arcache(m2_axi_arcache),
    .m_axi_arprot(m2_axi_arprot),
    .m_axi_arvalid(m2_axi_arvalid),
    .m_axi_arready(m2_axi_arready),
    .m_axi_rready(m2_axi_rready),
    .m_axi_rid(m2_axi_rid),
    .m_axi_rdata(m2_axi_rdata),
    .m_axi_rresp(m2_axi_rresp),
    .m_axi_rlast(m2_axi_rlast),
    .m_axi_rvalid(m2_axi_rvalid)
    */
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


    logic halt;
    logic dramWriteEnable, dramReadEnable, dramValid;
    logic [31:0] dramAddress, dramWriteData, dramReadData;

  // TODO: use sys_clk and cross domain to dma_ctrl.
    mips_single_sram_dmac_led #(FILENAME)
      u_mips_sram_dmac_led(ui_clk, !ui_rstn | btn[1], 
        halt,
        led[2:0],
        dramAddress, dramWriteData,
        dramWriteEnable, dramReadEnable,
        dramReadData,
        dramValid
    );


  /*
  logic [31:0] sramReadDataForDMAC, sramAddressForDMAC, sramWriteDataForDMAC;
  logic sramWriteEnableForDMAC;
  logic [31:0] sramReadDataForCPU, sramAddressForCPU, sramWriteDataForCPU;
  logic sramWriteEnableForCPU;
  logic [31:0] sramReadData, sramAddress, sramWriteData, dmaSrcAddress, dmaDstAddress;
  logic sramWriteEnable, halt, dmaValid, stall;
  logic [1:0] dmaCmd;
  logic [9:0] dmaWidth;
  */


  /*
  sram DataMem(ui_clk, sramAddress[13:0], sramWriteEnable, sramWriteData, sramReadData);

  mips_single #("d2s_test.mem") u_mps(ui_clk, ui_rstn, stall, sramReadDataForCPU, sramAddressForCPU, sramWriteDataForCPU, sramWriteEnableForCPU,
                                      dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, dmaValid, halt);
                                      */

/*
  mips_single #("halt_test.mem") u_mps(ui_clk, !ui_rstn, stall, sramReadDataForCPU, sramAddressForCPU, sramWriteDataForCPU, sramWriteEnableForCPU,
                                      dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth, dmaValid, halt);
                                      */

  // logic [2:0] ledval;
  // LED handling.
  // Assign 0x8000_000X for LED. led[3] is assign to show halt.

  /*
  always_ff @(posedge ui_clk, negedge ui_rstn)
    if(!ui_rstn)
      ledval <= 3'b0;
    else if(sramWriteEnableForCPU & sramAddressForCPU[31])
      case(sramAddressForCPU[3:0])
        4'b0: ledval[0] <= sramWriteDataForCPU[0];
        4'b100: ledval[1] <= sramWriteDataForCPU[0];
        4'b1000: ledval[2] <= sramWriteDataForCPU[0];
      endcase
      */


  // assign led[2:0] = ledval;
  /*
  assign led[0] = stall;
  assign led[1] = ui_rstn;
  assign led[2] = ui_clk;
  */
  assign led[3] = halt;

  /*
  always_comb
    if(stall)
      begin
        sramAddress = sramAddressForDMAC;
        sramWriteEnable = sramWriteEnableForDMAC;
        sramWriteData = sramWriteDataForDMAC;
        sramReadDataForDMAC = sramReadData;
      end
    else
      begin
        if(sramAddressForCPU[31])
          begin
            sramAddress = 32'b0;
            sramWriteEnable = 0;
            sramWriteData = 32'b0;
            sramReadDataForCPU = 32'b0;        
          end
        else
          begin
            sramAddress = sramAddressForCPU;
            sramWriteEnable = sramWriteEnableForCPU;
            sramWriteData = sramWriteDataForCPU;
            sramReadDataForCPU = sramReadData;        
          end
      end



  dma_ctrl u_dmac(ui_clk, !ui_rstn, dmaCmd, dmaSrcAddress, dmaDstAddress, dmaWidth,
              sramReadDataForDMAC, dramReadData,
              sramAddressForDMAC, sramWriteDataForDMAC, sramWriteEnableForDMAC,
              dramAddress, dramWriteData, dramWriteEnable, dramReadEnable,
              dramValid, stall, dmaValid);
  */

  jtag_adapter u_jtag_adapter (
    .clk(ui_clk),                     // input wire aclk
    .reset(!ui_rstn),
    .dramAddress(dramAddress), .dramWriteData(dramWriteData),
    .readEnable(dramReadEnable), .writeEnable(dramWriteEnable),
    .dramReadData(dramReadData),
    .dramValid(dramValid),

    .m_axi_awid(m1_axi_awid),        // output wire [3 : 0] m_axi_awid
    .m_axi_awaddr(m1_axi_awaddr),    // output wire [31 : 0] m_axi_awaddr
    .m_axi_awlen(m1_axi_awlen),      // output wire [7 : 0] m_axi_awlen
    .m_axi_awsize(m1_axi_awsize),    // output wire [2 : 0] m_axi_awsize
    .m_axi_awburst(m1_axi_awburst),  // output wire [1 : 0] m_axi_awburst
    .m_axi_awlock(m1_axi_awlock),    // output wire m_axi_awlock
    .m_axi_awcache(m1_axi_awcache),  // output wire [3 : 0] m_axi_awcache
    .m_axi_awprot(m1_axi_awprot),    // output wire [2 : 0] m_axi_awprot
    .m_axi_awvalid(m1_axi_awvalid),  // output wire m_axi_awvalid
    .m_axi_awready(m1_axi_awready),  // input wire m_axi_awready
    .m_axi_wdata(m1_axi_wdata),      // output wire [31 : 0] m_axi_wdata
    .m_axi_wstrb(m1_axi_wstrb),      // output wire [3 : 0] m_axi_wstrb
    .m_axi_wlast(m1_axi_wlast),      // output wire m_axi_wlast
    .m_axi_wvalid(m1_axi_wvalid),    // output wire m_axi_wvalid
    .m_axi_wready(m1_axi_wready),    // input wire m_axi_wready
    .m_axi_bid(m1_axi_bid),          // input wire [3 : 0] m_axi_bid
    .m_axi_bresp(m1_axi_bresp),      // input wire [1 : 0] m_axi_bresp
    .m_axi_bvalid(m1_axi_bvalid),    // input wire m_axi_bvalid
    .m_axi_bready(m1_axi_bready),    // output wire m_axi_bready
    .m_axi_arid(m1_axi_arid),        // output wire [3 : 0] m_axi_arid
    .m_axi_araddr(m1_axi_araddr),    // output wire [31 : 0] m_axi_araddr
    .m_axi_arlen(m1_axi_arlen),      // output wire [7 : 0] m_axi_arlen
    .m_axi_arsize(m1_axi_arsize),    // output wire [2 : 0] m_axi_arsize
    .m_axi_arburst(m1_axi_arburst),  // output wire [1 : 0] m_axi_arburst
    .m_axi_arlock(m1_axi_arlock),    // output wire m_axi_arlock
    .m_axi_arcache(m1_axi_arcache),  // output wire [3 : 0] m_axi_arcache
    .m_axi_arprot(m1_axi_arprot),    // output wire [2 : 0] m_axi_arprot
    .m_axi_arvalid(m1_axi_arvalid),  // output wire m_axi_arvalid
    .m_axi_arready(m1_axi_arready),  // input wire m_axi_arready
    .m_axi_rid(m1_axi_rid),          // input wire [3 : 0] m_axi_rid
    .m_axi_rdata(m1_axi_rdata),      // input wire [31 : 0] m_axi_rdata
    .m_axi_rresp(m1_axi_rresp),      // input wire [1 : 0] m_axi_rresp
    .m_axi_rlast(m1_axi_rlast),      // input wire m_axi_rlast
    .m_axi_rvalid(m1_axi_rvalid),    // input wire m_axi_rvalid
    .m_axi_rready(m1_axi_rready)     // output wire m_axi_rready
  );

// mux_axi u_mux_axi(1,
mux_axi u_mux_axi(halt,
   // axi1
   m1_axi_awid,
   m1_axi_awaddr,
   m1_axi_awlen,
   m1_axi_awsize,
   m1_axi_awburst,
   m1_axi_awlock,
   m1_axi_awcache,
   m1_axi_awprot,
   m1_axi_awvalid,
   m1_axi_awready,
   m1_axi_wdata,
   m1_axi_wstrb,
   m1_axi_wlast,
   m1_axi_wvalid,
   m1_axi_wready,
   m1_axi_bready,
   m1_axi_bid,
   m1_axi_bresp,
   m1_axi_bvalid,
   m1_axi_arid,
   m1_axi_araddr,
   m1_axi_arlen,
   m1_axi_arsize,
   m1_axi_arburst,
   m1_axi_arlock,
   m1_axi_arcache,
   m1_axi_arprot,
   m1_axi_arvalid,
   m1_axi_arready,
   m1_axi_rready,
   m1_axi_rid,
   m1_axi_rdata,
   m1_axi_rresp,
   m1_axi_rlast,
   m1_axi_rvalid,

  // axi2
  m2_axi_awid,
  m2_axi_awaddr,
  m2_axi_awlen,
  m2_axi_awsize,
  m2_axi_awburst,
  m2_axi_awlock,
  m2_axi_awcache,
  m2_axi_awprot,
  m2_axi_awvalid,
  m2_axi_awready,
  m2_axi_wdata,
  m2_axi_wstrb,
  m2_axi_wlast,
  m2_axi_wvalid,
  m2_axi_wready,
  m2_axi_bready,
  m2_axi_bid,
  m2_axi_bresp,
  m2_axi_bvalid,
  m2_axi_arid,
  m2_axi_araddr,
  m2_axi_arlen,
  m2_axi_arsize,
  m2_axi_arburst,
  m2_axi_arlock,
  m2_axi_arcache,
  m2_axi_arprot,
  m2_axi_arvalid,
  m2_axi_arready,
  m2_axi_rready,
  m2_axi_rid,
  m2_axi_rdata,
  m2_axi_rresp,
  m2_axi_rlast,
  m2_axi_rvalid,

  // output
  m_axi_awid,
  m_axi_awaddr,
  m_axi_awlen,
  m_axi_awsize,
  m_axi_awburst,
  m_axi_awlock,
  m_axi_awcache,
  m_axi_awprot,
  m_axi_awvalid,
  m_axi_awready,
  m_axi_wdata,
  m_axi_wstrb,
  m_axi_wlast,
  m_axi_wvalid,
  m_axi_wready,
  m_axi_bid,
  m_axi_bresp,
  m_axi_bvalid,
  m_axi_bready,
  m_axi_arid,
  m_axi_araddr,
  m_axi_arlen,
  m_axi_arsize,
  m_axi_arburst,
  m_axi_arlock,
  m_axi_arcache,
  m_axi_arprot,
  m_axi_arvalid,
  m_axi_arready,
  m_axi_rid,
  m_axi_rdata,
  m_axi_rresp,
  m_axi_rlast,
  m_axi_rvalid,
  m_axi_rready);

endmodule



module arty_top_pipeline #(parameter FILENAME="d2s_simple_writeback_test.mem")  (
  inout [15:0]  ddr3_dq,
  inout [1:0]   ddr3_dqs_n,
  inout [1:0]   ddr3_dqs_p,
  output [13:0] ddr3_addr,
  output [2:0]  ddr3_ba,
  output        ddr3_ras_n,
  output        ddr3_cas_n,
  output        ddr3_we_n,
  output        ddr3_reset_n,
  output [0:0]  ddr3_ck_p,
  output [0:0]  ddr3_ck_n,
  output [0:0]  ddr3_cke,
  output [0:0]  ddr3_cs_n,
  output [1:0]  ddr3_dm,
  output [0:0]  ddr3_odt,
  output [3:0]  led,
  input [3:0] btn,
  input         sys_clk,
  input         sys_rstn
  );

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

  logic [3:0]   m1_axi_awid;
  logic [31:0]  m1_axi_awaddr;
  logic [7:0]   m1_axi_awlen;
  logic [2:0]   m1_axi_awsize;
  logic [1:0]   m1_axi_awburst;
  logic         m1_axi_awlock;
  logic [3:0]   m1_axi_awcache;
  logic [2:0]   m1_axi_awprot;
  logic         m1_axi_awvalid;
  logic         m1_axi_awready;
  logic [31:0]  m1_axi_wdata;
  logic [3:0]   m1_axi_wstrb;
  logic         m1_axi_wlast;
  logic         m1_axi_wvalid;
  logic         m1_axi_wready;
  logic         m1_axi_bready;
  logic [3:0]   m1_axi_bid;
  logic [1:0]   m1_axi_bresp;
  logic         m1_axi_bvalid;
  logic [3:0]   m1_axi_arid;
  logic [31:0]  m1_axi_araddr;
  logic [7:0]   m1_axi_arlen;
  logic [2:0]   m1_axi_arsize;
  logic [1:0]   m1_axi_arburst;
  logic         m1_axi_arlock;
  logic [3:0]   m1_axi_arcache;
  logic [2:0]   m1_axi_arprot;
  logic         m1_axi_arvalid;
  logic         m1_axi_arready;
  logic         m1_axi_rready;
  logic [3:0]   m1_axi_rid;
  logic [31:0]  m1_axi_rdata;
  logic [1:0]   m1_axi_rresp;
  logic         m1_axi_rlast;
  logic         m1_axi_rvalid;

  logic [3:0]   m2_axi_awid;
  logic [31:0]  m2_axi_awaddr;
  logic [7:0]   m2_axi_awlen;
  logic [2:0]   m2_axi_awsize;
  logic [1:0]   m2_axi_awburst;
  logic         m2_axi_awlock;
  logic [3:0]   m2_axi_awcache;
  logic [2:0]   m2_axi_awprot;
  logic         m2_axi_awvalid;
  logic         m2_axi_awready;
  logic [31:0]  m2_axi_wdata;
  logic [3:0]   m2_axi_wstrb;
  logic         m2_axi_wlast;
  logic         m2_axi_wvalid;
  logic         m2_axi_wready;
  logic         m2_axi_bready;
  logic [3:0]   m2_axi_bid;
  logic [1:0]   m2_axi_bresp;
  logic         m2_axi_bvalid;
  logic [3:0]   m2_axi_arid;
  logic [31:0]  m2_axi_araddr;
  logic [7:0]   m2_axi_arlen;
  logic [2:0]   m2_axi_arsize;
  logic [1:0]   m2_axi_arburst;
  logic         m2_axi_arlock;
  logic [3:0]   m2_axi_arcache;
  logic [2:0]   m2_axi_arprot;
  logic         m2_axi_arvalid;
  logic         m2_axi_arready;
  logic         m2_axi_rready;
  logic [3:0]   m2_axi_rid;
  logic [31:0]  m2_axi_rdata;
  logic [1:0]   m2_axi_rresp;
  logic         m2_axi_rlast;
  logic         m2_axi_rvalid;


  logic ui_clk, ui_rstn;



  jtag_axi u_jtag_axi (
    .aclk(ui_clk),                     // input wire aclk
    .aresetn(ui_rstn),                 // input wire aresetn
    .m_axi_awid(m2_axi_awid),        // output wire [3 : 0] m_axi_awid
    .m_axi_awaddr(m2_axi_awaddr),    // output wire [31 : 0] m_axi_awaddr
    .m_axi_awlen(m2_axi_awlen),      // output wire [7 : 0] m_axi_awlen
    .m_axi_awsize(m2_axi_awsize),    // output wire [2 : 0] m_axi_awsize
    .m_axi_awburst(m2_axi_awburst),  // output wire [1 : 0] m_axi_awburst
    .m_axi_awlock(m2_axi_awlock),    // output wire m_axi_awlock
    .m_axi_awcache(m2_axi_awcache),  // output wire [3 : 0] m_axi_awcache
    .m_axi_awprot(m2_axi_awprot),    // output wire [2 : 0] m_axi_awprot
    .m_axi_awqos(),                 // output wire [3 : 0] m_axi_awqos
    .m_axi_awvalid(m2_axi_awvalid),  // output wire m_axi_awvalid
    .m_axi_awready(m2_axi_awready),  // input wire m_axi_awready
    .m_axi_wdata(m2_axi_wdata),      // output wire [31 : 0] m_axi_wdata
    .m_axi_wstrb(m2_axi_wstrb),      // output wire [3 : 0] m_axi_wstrb
    .m_axi_wlast(m2_axi_wlast),      // output wire m_axi_wlast
    .m_axi_wvalid(m2_axi_wvalid),    // output wire m_axi_wvalid
    .m_axi_wready(m2_axi_wready),    // input wire m_axi_wready
    .m_axi_bid(m2_axi_bid),          // input wire [3 : 0] m_axi_bid
    .m_axi_bresp(m2_axi_bresp),      // input wire [1 : 0] m_axi_bresp
    .m_axi_bvalid(m2_axi_bvalid),    // input wire m_axi_bvalid
    .m_axi_bready(m2_axi_bready),    // output wire m_axi_bready
    .m_axi_arid(m2_axi_arid),        // output wire [3 : 0] m_axi_arid
    .m_axi_araddr(m2_axi_araddr),    // output wire [31 : 0] m_axi_araddr
    .m_axi_arlen(m2_axi_arlen),      // output wire [7 : 0] m_axi_arlen
    .m_axi_arsize(m2_axi_arsize),    // output wire [2 : 0] m_axi_arsize
    .m_axi_arburst(m2_axi_arburst),  // output wire [1 : 0] m_axi_arburst
    .m_axi_arlock(m2_axi_arlock),    // output wire m_axi_arlock
    .m_axi_arcache(m2_axi_arcache),  // output wire [3 : 0] m_axi_arcache
    .m_axi_arprot(m2_axi_arprot),    // output wire [2 : 0] m_axi_arprot
    .m_axi_arqos(),                 // output wire [3 : 0] m_axi_arqos
    .m_axi_arvalid(m2_axi_arvalid),  // output wire m_axi_arvalid
    .m_axi_arready(m2_axi_arready),  // input wire m_axi_arready
    .m_axi_rid(m2_axi_rid),          // input wire [3 : 0] m_axi_rid
    .m_axi_rdata(m2_axi_rdata),      // input wire [31 : 0] m_axi_rdata
    .m_axi_rresp(m2_axi_rresp),      // input wire [1 : 0] m_axi_rresp
    .m_axi_rlast(m2_axi_rlast),      // input wire m_axi_rlast
    .m_axi_rvalid(m2_axi_rvalid),    // input wire m_axi_rvalid
    .m_axi_rready(m2_axi_rready)     // output wire m_axi_rready
  );

  ddr_io u_ddr_io(
    .ui_clk(ui_clk),
    .ui_rstn(ui_rstn),
    .ddr3_dq(ddr3_dq),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dqs_p(ddr3_dqs_p),
    .ddr3_addr(ddr3_addr),
    .ddr3_ba(ddr3_ba),
    .ddr3_ras_n(ddr3_ras_n),
    .ddr3_cas_n(ddr3_cas_n),
    .ddr3_we_n(ddr3_we_n),
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_ck_p(ddr3_ck_p),
    .ddr3_ck_n(ddr3_ck_n),
    .ddr3_cke(ddr3_cke),
    .ddr3_cs_n(ddr3_cs_n),
    .ddr3_dm(ddr3_dm),
    .ddr3_odt(ddr3_odt),
    .sys_clk(sys_clk),
    .sys_rstn(sys_rstn & !btn[0]),

/*
    .m_axi_awid(m2_axi_awid),
    .m_axi_awaddr(m2_axi_awaddr),
    .m_axi_awlen(m2_axi_awlen),
    .m_axi_awsize(m2_axi_awsize),
    .m_axi_awburst(m2_axi_awburst),
    .m_axi_awlock(m2_axi_awlock),
    .m_axi_awcache(m2_axi_awcache),
    .m_axi_awprot(m2_axi_awprot),
    .m_axi_awvalid(m2_axi_awvalid),
    .m_axi_awready(m2_axi_awready),
    .m_axi_wdata(m2_axi_wdata),
    .m_axi_wstrb(m2_axi_wstrb),
    .m_axi_wlast(m2_axi_wlast),
    .m_axi_wvalid(m2_axi_wlast),
    .m_axi_wready(m2_axi_wready),
    .m_axi_bready(m2_axi_bready),
    .m_axi_bid(m2_axi_bid),
    .m_axi_bresp(m2_axi_bresp),
    .m_axi_bvalid(m2_axi_bvalid),
    .m_axi_arid(m2_axi_arid),
    .m_axi_araddr(m2_axi_araddr),
    .m_axi_arlen(m2_axi_arlen),
    .m_axi_arsize(m2_axi_arsize),
    .m_axi_arburst(m2_axi_arburst),
    .m_axi_arlock(m2_axi_arlock),
    .m_axi_arcache(m2_axi_arcache),
    .m_axi_arprot(m2_axi_arprot),
    .m_axi_arvalid(m2_axi_arvalid),
    .m_axi_arready(m2_axi_arready),
    .m_axi_rready(m2_axi_rready),
    .m_axi_rid(m2_axi_rid),
    .m_axi_rdata(m2_axi_rdata),
    .m_axi_rresp(m2_axi_rresp),
    .m_axi_rlast(m2_axi_rlast),
    .m_axi_rvalid(m2_axi_rvalid)
    */
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


    logic halt;
    logic dramWriteEnable, dramReadEnable, dramValid;
    logic [31:0] dramAddress, dramWriteData, dramReadData;

    mips_pipeline_sram_dmac_led #(FILENAME)
      u_mips_sram_dmac_led(ui_clk, !ui_rstn | btn[1], 
        halt,
        led[2:0],
        dramAddress, dramWriteData,
        dramWriteEnable, dramReadEnable,
        dramReadData,
        dramValid
    );

  assign led[3] = halt;


  jtag_adapter u_jtag_adapter (
    .clk(ui_clk),                     // input wire aclk
    .reset(!ui_rstn),
    .dramAddress(dramAddress), .dramWriteData(dramWriteData),
    .readEnable(dramReadEnable), .writeEnable(dramWriteEnable),
    .dramReadData(dramReadData),
    .dramValid(dramValid),

    .m_axi_awid(m1_axi_awid),        // output wire [3 : 0] m_axi_awid
    .m_axi_awaddr(m1_axi_awaddr),    // output wire [31 : 0] m_axi_awaddr
    .m_axi_awlen(m1_axi_awlen),      // output wire [7 : 0] m_axi_awlen
    .m_axi_awsize(m1_axi_awsize),    // output wire [2 : 0] m_axi_awsize
    .m_axi_awburst(m1_axi_awburst),  // output wire [1 : 0] m_axi_awburst
    .m_axi_awlock(m1_axi_awlock),    // output wire m_axi_awlock
    .m_axi_awcache(m1_axi_awcache),  // output wire [3 : 0] m_axi_awcache
    .m_axi_awprot(m1_axi_awprot),    // output wire [2 : 0] m_axi_awprot
    .m_axi_awvalid(m1_axi_awvalid),  // output wire m_axi_awvalid
    .m_axi_awready(m1_axi_awready),  // input wire m_axi_awready
    .m_axi_wdata(m1_axi_wdata),      // output wire [31 : 0] m_axi_wdata
    .m_axi_wstrb(m1_axi_wstrb),      // output wire [3 : 0] m_axi_wstrb
    .m_axi_wlast(m1_axi_wlast),      // output wire m_axi_wlast
    .m_axi_wvalid(m1_axi_wvalid),    // output wire m_axi_wvalid
    .m_axi_wready(m1_axi_wready),    // input wire m_axi_wready
    .m_axi_bid(m1_axi_bid),          // input wire [3 : 0] m_axi_bid
    .m_axi_bresp(m1_axi_bresp),      // input wire [1 : 0] m_axi_bresp
    .m_axi_bvalid(m1_axi_bvalid),    // input wire m_axi_bvalid
    .m_axi_bready(m1_axi_bready),    // output wire m_axi_bready
    .m_axi_arid(m1_axi_arid),        // output wire [3 : 0] m_axi_arid
    .m_axi_araddr(m1_axi_araddr),    // output wire [31 : 0] m_axi_araddr
    .m_axi_arlen(m1_axi_arlen),      // output wire [7 : 0] m_axi_arlen
    .m_axi_arsize(m1_axi_arsize),    // output wire [2 : 0] m_axi_arsize
    .m_axi_arburst(m1_axi_arburst),  // output wire [1 : 0] m_axi_arburst
    .m_axi_arlock(m1_axi_arlock),    // output wire m_axi_arlock
    .m_axi_arcache(m1_axi_arcache),  // output wire [3 : 0] m_axi_arcache
    .m_axi_arprot(m1_axi_arprot),    // output wire [2 : 0] m_axi_arprot
    .m_axi_arvalid(m1_axi_arvalid),  // output wire m_axi_arvalid
    .m_axi_arready(m1_axi_arready),  // input wire m_axi_arready
    .m_axi_rid(m1_axi_rid),          // input wire [3 : 0] m_axi_rid
    .m_axi_rdata(m1_axi_rdata),      // input wire [31 : 0] m_axi_rdata
    .m_axi_rresp(m1_axi_rresp),      // input wire [1 : 0] m_axi_rresp
    .m_axi_rlast(m1_axi_rlast),      // input wire m_axi_rlast
    .m_axi_rvalid(m1_axi_rvalid),    // input wire m_axi_rvalid
    .m_axi_rready(m1_axi_rready)     // output wire m_axi_rready
  );

// mux_axi u_mux_axi(1,
mux_axi u_mux_axi(halt,
   // axi1
   m1_axi_awid,
   m1_axi_awaddr,
   m1_axi_awlen,
   m1_axi_awsize,
   m1_axi_awburst,
   m1_axi_awlock,
   m1_axi_awcache,
   m1_axi_awprot,
   m1_axi_awvalid,
   m1_axi_awready,
   m1_axi_wdata,
   m1_axi_wstrb,
   m1_axi_wlast,
   m1_axi_wvalid,
   m1_axi_wready,
   m1_axi_bready,
   m1_axi_bid,
   m1_axi_bresp,
   m1_axi_bvalid,
   m1_axi_arid,
   m1_axi_araddr,
   m1_axi_arlen,
   m1_axi_arsize,
   m1_axi_arburst,
   m1_axi_arlock,
   m1_axi_arcache,
   m1_axi_arprot,
   m1_axi_arvalid,
   m1_axi_arready,
   m1_axi_rready,
   m1_axi_rid,
   m1_axi_rdata,
   m1_axi_rresp,
   m1_axi_rlast,
   m1_axi_rvalid,

  // axi2
  m2_axi_awid,
  m2_axi_awaddr,
  m2_axi_awlen,
  m2_axi_awsize,
  m2_axi_awburst,
  m2_axi_awlock,
  m2_axi_awcache,
  m2_axi_awprot,
  m2_axi_awvalid,
  m2_axi_awready,
  m2_axi_wdata,
  m2_axi_wstrb,
  m2_axi_wlast,
  m2_axi_wvalid,
  m2_axi_wready,
  m2_axi_bready,
  m2_axi_bid,
  m2_axi_bresp,
  m2_axi_bvalid,
  m2_axi_arid,
  m2_axi_araddr,
  m2_axi_arlen,
  m2_axi_arsize,
  m2_axi_arburst,
  m2_axi_arlock,
  m2_axi_arcache,
  m2_axi_arprot,
  m2_axi_arvalid,
  m2_axi_arready,
  m2_axi_rready,
  m2_axi_rid,
  m2_axi_rdata,
  m2_axi_rresp,
  m2_axi_rlast,
  m2_axi_rvalid,

  // output
  m_axi_awid,
  m_axi_awaddr,
  m_axi_awlen,
  m_axi_awsize,
  m_axi_awburst,
  m_axi_awlock,
  m_axi_awcache,
  m_axi_awprot,
  m_axi_awvalid,
  m_axi_awready,
  m_axi_wdata,
  m_axi_wstrb,
  m_axi_wlast,
  m_axi_wvalid,
  m_axi_wready,
  m_axi_bid,
  m_axi_bresp,
  m_axi_bvalid,
  m_axi_bready,
  m_axi_arid,
  m_axi_araddr,
  m_axi_arlen,
  m_axi_arsize,
  m_axi_arburst,
  m_axi_arlock,
  m_axi_arcache,
  m_axi_arprot,
  m_axi_arvalid,
  m_axi_arready,
  m_axi_rid,
  m_axi_rdata,
  m_axi_rresp,
  m_axi_rlast,
  m_axi_rvalid,
  m_axi_rready);

endmodule
