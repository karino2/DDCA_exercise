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
    output logic m_axi_rready
    );

    typedef enum logic [3:0] {DORMANT, READ_ARSEND, READ_VALUE, READ_DONE,  WRITE_AWSEND, WRITE_DATA, WRITE_RESPONSE, WRITE_DONE} statetype;
    statetype state, nextstate;

    // 0: awready
    // 1: wready
    // 2: bready
    // 3: arready
    // 4: rready
    logic [4:0] completion;

    always_ff @(posedge clk, posedge reset)
        if(reset) begin
             state <= DORMANT;
             completion <= 5'b0;
             dramReadData <= 32'b0;
        end
        else begin
            state <= nextstate;
            if(m_axi_rvalid)
                dramReadData <= m_axi_rdata;

        end

    always_comb
        case(state)
            DORMANT: 
                nextstate = writeEnable ? WRITE_AWSEND : (readEnable? READ_ARSEND: DORMANT);
            READ_ARSEND:
                nextstate = (m_axi_arready & m_axi_arvalid) ? READ_VALUE: READ_ARSEND;
            READ_VALUE:
                nextstate = (m_axi_rready & m_axi_rvalid) ? READ_DONE : READ_VALUE; 
            READ_DONE:
                nextstate = DORMANT;
            WRITE_AWSEND:
                nextstate = (m_axi_awready & m_axi_awvalid) ? WRITE_DATA : WRITE_AWSEND;
            WRITE_DATA:
                nextstate = (m_axi_wready & m_axi_wvalid) ? WRITE_RESPONSE : WRITE_DATA;
            WRITE_RESPONSE:
                nextstate = (m_axi_bready & m_axi_bvalid) ? WRITE_DONE : WRITE_RESPONSE;
            WRITE_DONE:
                nextstate = DORMANT;
            default:
                nextstate = DORMANT;
        endcase


    assign m_axi_awid =  writeEnable? 4'b1 : 0;
    assign m_axi_awaddr = writeEnable ? dramAddress : 0;

    // assign m_axi_awlen = writeEnable ? 8'b1 : 0;
    assign m_axi_awlen = 0; // burst size is awlen+1
    assign m_axi_awsize = writeEnable? 3'b10 : 0; // 4 byte.
    assign m_axi_awburst = 2'b00; // FIXED.
    assign m_axi_awlock = 0;
    assign m_axi_awcache = 4'b0; // Non-bufferable.
    assign m_axi_awprot = 3'b000; // Unprevileged, secure, data access.
    assign m_axi_awvalid = (state==WRITE_AWSEND);

    assign dramValid = (state == WRITE_DONE) | (state == READ_DONE);

    assign m_axi_wdata = writeEnable? dramWriteData : 0;
    assign m_axi_wstrb = writeEnable ? 4'b1111 : 0;
    assign m_axi_wlast = writeEnable;
    assign m_axi_wvalid = (state == WRITE_DATA);
    /*
    input logic [3:0]m_axi_bid,
    input logic [1:0]m_axi_bresp,
    */
    // assign m_axi_bready = writeEnable;
    assign m_axi_bready = (state==WRITE_RESPONSE);

    assign m_axi_arid = readEnable ? 4'b10 : 0;    
    assign m_axi_araddr = readEnable ? dramAddress : 0;
//    assign m_axi_arlen = readEnable ? 8'b1: 0;
    assign m_axi_arlen = 0;
    assign m_axi_arsize = readEnable ? 3'b10: 0; // 4byte
    assign m_axi_arburst = 2'b00; // FIXED
    assign m_axi_arlock = 0;
    assign m_axi_arcache = 4'b0; // Non-bufferable.
    assign m_axi_arprot = 3'b000; // Unprevileged, secure, data access.
    assign m_axi_arvalid = (state == READ_ARSEND);

    /*
    input logic [3:0]m_axi_rid,
    input logic [1:0]m_axi_rresp,
    input logic m_axi_rlast,
    */
    assign m_axi_rready = (state == READ_VALUE);

endmodule

module dma_ctrl(input logic clk, reset, 
                input logic [1:0] cmd,
                input logic [31:0] srcAddress, dstAddress,
                input logic [9:0] width,
                input logic [31:0] sramReadData, dramReadData, 
                output logic [13:0] sramAddress,
                output logic [31:0] sramWriteData,
                output logic sramWriteEnable,
                output logic [31:0] dramAddress, dramWriteData,
                output logic dramWriteEnable, dramReadEnable,
                input logic dramValid,
                output logic stall);

    typedef enum logic [2:0] {DORMANT, D2S_BEGIN, D2S_READ_REQUEST, D2S_WRITE, D2S_ONE_COMP, D2S_DONE_OR_NEXT, DONE} statetype;
    statetype state, nextstate;
    logic [31:0] curData, nextSramAddress, nextDramAddress;
    logic [9:0] rest;

    /*
    always @(posedge clk)
        $display("dmac: state=%h", state);
        */


    always_ff @(posedge clk, posedge reset)
        if(reset) begin
             state <= DORMANT;
        end
        else begin
            state <= nextstate;
            case(nextstate)
                D2S_BEGIN:
                    begin
                        rest <= width;
                        nextSramAddress <= dstAddress;
                        nextDramAddress <= srcAddress;
                    end
                D2S_READ_REQUEST:
                    begin
                        // read request to dram, wait until dramValid.
                        sramAddress <= nextSramAddress[15:2];
                        dramAddress <= nextDramAddress;
                        curData <= dramReadData;
                    end
                D2S_WRITE:
                    begin
                        // TODO: how to fix this more correctly?
                        if(dramValid)
                            begin
                                curData <= dramReadData;
                                sramWriteData <= dramReadData;
                            end
                        else
                            sramWriteData <= curData;
                    end
                D2S_ONE_COMP:
                    begin
                        rest <= rest-1;
                        nextDramAddress <= nextDramAddress+4;
                        nextSramAddress <= nextSramAddress+4;
                    end
            endcase
        end

    /*
    always @(posedge clk)
        $display("state=%b, address. %h, %h, %h, %h", state, nextSramAddress, nextDramAddress, curSramAddress, curDramAddress);
    */

    // assign dmaValid = (state == DONE);
    assign dramWriteEnable = 1'b0; // (state == S2D_WRITE);
    assign sramWriteEnable = (state == D2S_WRITE);
    assign dramReadEnable = (state == D2S_READ_REQUEST);

    // assign nextstate = (cmd == 2'b01) ? D2S_BEGIN: DORMANT;

    always_comb
        case(state)
            DORMANT:
                case(cmd)
                    2'b01: nextstate = D2S_BEGIN;
                    default: nextstate = DORMANT;
                endcase
            D2S_BEGIN:
                nextstate = D2S_READ_REQUEST;
            D2S_READ_REQUEST:
                // read request to dram
                nextstate = dramValid? D2S_WRITE: D2S_READ_REQUEST;
            D2S_WRITE:
                nextstate = D2S_ONE_COMP;
            D2S_ONE_COMP:
                nextstate = D2S_DONE_OR_NEXT;
            D2S_DONE_OR_NEXT:
                if(rest == 10'b0)
                    nextstate = DONE;
                else
                    nextstate = D2S_READ_REQUEST;
            DONE:
                nextstate = DORMANT;
            default:
                nextstate = DORMANT;
        endcase

    assign stall = (state != DORMANT);

endmodule
