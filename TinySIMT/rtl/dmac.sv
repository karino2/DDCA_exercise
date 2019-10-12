module jtag_adapter(input logic clk, reset, 
    input logic [31:0] dramAddress, dramWriteData,
    input logic readEnable, writeEnable,
    output logic [31:0] dramReadData,
    output logic dramValid,
    // jtag like axi.
    output logic [3:0]m_axi_awid,
    output logic [31:0]m_axi_awaddr,
    output logic [7:0]m_axi_awlen,
    output logic [2:0]m_axi_awsize,
    output logic [1:0]m_axi_awburst,
    output logic m_axi_awlock,
    output logic [3:0]m_axi_awcache,
    output logic [2:0]m_axi_awprot,
    output logic m_axi_awvalid,
    input logic m_axi_awready,
    output logic [31:0]m_axi_wdata,
    output logic [3:0]m_axi_wstrb,
    output logic m_axi_wlast,
    output logic m_axi_wvalid,
    input logic m_axi_wready,
    input logic [3:0]m_axi_bid,
    input logic [1:0]m_axi_bresp,
    input logic m_axi_bvalid,
    output logic m_axi_bready,
    output logic [3:0]m_axi_arid,
    output logic [31:0]m_axi_araddr,
    output logic [7:0]m_axi_arlen,
    output logic [2:0]m_axi_arsize,
    output logic [1:0]m_axi_arburst,
    output logic m_axi_arlock,
    output logic [3:0]m_axi_arcache,
    output logic [2:0]m_axi_arprot,
    output logic [3:0]m_axi_arqos,
    output logic m_axi_arvalid,
    input logic m_axi_arready,
    input logic [3:0]m_axi_rid,
    input logic [31:0]m_axi_rdata,
    input logic [1:0]m_axi_rresp,
    input logic m_axi_rlast,
    input logic m_axi_rvalid,
    output logic m_axi_rready,                                       
    );
    assign m_axi_awid =  writeEnable? 4'b1 : 0;
    assign m_axi_awaddr = writeEnable ? dramAddress : 0;

    assign m_axi_awlen = writeEnable ? 8'b1 : 0;
    assign m_axi_awsize = writeEnable? 3'b10 : 0, // 4 byte.
    assign m_axi_awburst = 2'b00; // FIXED.
    assign m_axi_awlock = 0;
    assign m_axi_awcache = 4'b0; // Non-bufferable.
    assign m_axi_awprot = 3'b000; // Unprevileged, secure, data access.
    assign m_axi_awvalid = writeEnable;

    assign dramValid = writeEnable ? 
            (m_axi_awready & m_axi_wvalid & m_axi_bvalid) :
             (m_axi_arready & m_axi_rvalid);
    assign m_axi_wdata = writeEnable? dramWriteData : 0;
    assign m_axi_wstrb = writeEnable ? 4'b1111 : 0;
    assign m_axi_wlast = writeEnable;
    assign m_axi_wvalid = writeEnable;
    /*
    input logic [3:0]m_axi_bid,
    input logic [1:0]m_axi_bresp,
    */
    assign m_axi_bready = writeEnable;

    assign m_axi_arid = readEnable ? 4'b10 : 0;    
    assign m_axi_araddr = readEnable ? dramAddress : 0;
    assign m_axi_arlen = readEnable ? 8'b1: 0;
    assign m_axi_arsize = readEnable ? 3'b10: 0; // 4byte
    assign m_axi_arburst = 2'b00; // FIXED
    assign m_axi_arlock = 0;
    assign m_axi_arcache = 4'b0; // Non-bufferable.
    assign m_axi_arprot = 3'b000; // Unprevileged, secure, data access.
    assign m_axi_arvalid = readEnable;
    assign dramReadData = m_axi_rdata;
    /*
    input logic [3:0]m_axi_rid,
    input logic [1:0]m_axi_rresp,
    input logic m_axi_rlast,
    */
    assign m_axi_rready = readEnable;

endmodule

module dma_ctrl(input logic clk, reset, 
                input logic [1:0] cmd,
                input logic [31:0] srcAddr, destAddr,
                input logic [9:0] width,
                input logic [31:0] sramReadData, dramReadData, 
                output logic [13:0] sramAddress,
                output logic [31:0] sramWriteData,
                output logic sramWriteEnable,
                output logic [31:0] dramAddress, dramWriteData,
                output logic dramWriteEnable, dramReadEnable,
                input logic dramValid,
                output logic stall, dmaValid);

    typedef enum logic [2:0] {DORMANT, D2S_BEGIN, D2S_READ_REQUEST, D2S_WRITE, D2S_ONE_COMP, DONE} statetype;
    statetype [2:0] state, nextstate;
    logic [31:0] curSramAddress, curDramAddress, curData, nextSramAddress, nextDramAddress,;
    logic [9:0] rest;

    always_ff @(posedge clk, posedge reset)
        if(reset) begin
             state <= DORMANT;
             sramWriteEnable = 0;
             dramWriteEnable = 0;
             dramReadEnable = 0;
             dmaValid = 0;
        end
        else begin
            state <= nextstate;
            curSramAddress <= nextSramAddress;
            curDramAddress <= nextDramAddress;
        end

    always_comb
        case(state)
            DORMANT:
                dmaValid = 0;
                case(cmd):
                    2'b01: nextstate = D2S_BEGIN;
                    default: nextstate = DORMAN;
                endcase
            D2S_BEGIN:
                begin
                    rest = width
                    nextSramAddress = destAddress;
                    nextDramAddress = srcAddress;
                    nextstate = D2S_READ_REQUEST;
                end
            D2S_READ_REQUEST:
                begin
                    // read request to dram
                    dramAddress = nextDramAddress;
                    dramReadEnable = 1;
                    nextstate = dramValid? D2S_WRITE D2S_READ_REQUEST;
                    curData = dramReadData;
                end
            D2S_WRITE:
                begin
                    sramAddress = curSramAddress;
                    sramWriteData = curData;
                    sramWriteEnable = 1;
                    nextstate = D2S_ONE_COMP;
                end
            D2S_ONE_COMP:
                begin
                    sramWriteEnable = 0;
                    rest = rest-1;
                    case(rest)
                        0:
                            nextstate = DONE;                            
                        default:
                            begin
                                nextDramAddress = curDramAddress+4;
                                nextSramAddress = curSramAddress+4;
                                nextstate = D2S_READ_REQUEST;
                            end
                end
            DONE:
                begin
                    dmaValid = 1;
                    nextstate = DORMANT;
                end

            default: nextstate = DORMANT;
        endcase

    assign stall = (nextstate != DORMANT);

endmodule
