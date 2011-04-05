/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Author: Eyal Hochberg                                      ////
////          eyal@provartec.com                                 ////
////                                                             ////
////  Downloaded from: http://www.opencores.org                  ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2010 Provartec LTD                            ////
//// www.provartec.com                                           ////
//// info@provartec.com                                          ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
//// This source file is free software; you can redistribute it  ////
//// and/or modify it under the terms of the GNU Lesser General  ////
//// Public License as published by the Free Software Foundation.////
////                                                             ////
//// This source is distributed in the hope that it will be      ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied  ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR     ////
//// PURPOSE.  See the GNU Lesser General Public License for more////
//// details. http://www.gnu.org/licenses/lgpl.html              ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

OUTFILE PREFIX_ram.v

INCLUDE def_axi_slave.txt
  
module PREFIX_ram(PORTS);

   input 		      clk;
   input 		      reset;
   
   revport                    GROUP_STUB_AXI;

   port                       GROUP_STUB_MEM;
   
   
   //busy
   wire 		      ARREADY_pre;
   wire 		      RVALID_pre;
   wire 		      AWREADY_pre;
   wire 		      WREADY_pre;
   wire 		      BVALID_pre;
   wire 		      RBUSY;
   wire 		      BBUSY;
   
   //wcmd fifo
   wire [ADDR_BITS-1:0]       wcmd_addr;
   wire [ID_BITS-1:0] 	      wcmd_id;
   wire [1:0] 		      wcmd_size;
   wire [LEN_BITS-1:0]        wcmd_len;
   wire [1:0] 		      wcmd_resp;
   wire 		      wcmd_timeout;
   wire 		      wcmd_ready;
   wire 		      wcmd_empty;
   wire 		      wcmd_full;
   
   //rcmd fifo
   wire [ADDR_BITS-1:0]       rcmd_addr;
   wire [ID_BITS-1:0] 	      rcmd_id;
   wire [1:0] 		      rcmd_size;
   wire [LEN_BITS-1:0]        rcmd_len;
   wire [1:0] 		      rcmd_resp;
   wire 		      rcmd_timeout;
   wire 		      rcmd_ready;
   wire 		      rcmd_full;

   wire [ID_BITS-1:0] 	      rcmd_id2;
   wire [LEN_BITS-1:0]        rcmd_len2;

   wire 		      wresp_empty;
   wire 		      wresp_pending;
   wire 		      wresp_timeout;
   
   reg [ADDR_BITS-1:0] 	      TIMEOUT_AR_addr = {ADDR_BITS{1'b1}};
   reg [ADDR_BITS-1:0] 	      TIMEOUT_AW_addr = {ADDR_BITS{1'b1}};
   wire 		      AR_stall = ARVALID & (TIMEOUT_AR_addr == ARADDR);
   wire 		      AW_stall = AWVALID & (TIMEOUT_AW_addr == AWADDR);
   
   wire 		      RD_last;

   assign 		      RID   = rcmd_id2;


   assign 		      ARREADY_pre = (~rcmd_full) & (~AR_stall);
   assign 		      AWREADY_pre = (~wcmd_full) & (~AW_stall);
   assign 		      BVALID_pre  = (~wresp_timeout) & (wresp_pending ? (~wresp_empty) : (~wresp_empty) & (~BBUSY));

   CREATE axi_slave_busy.v
   PREFIX_busy
     PREFIX_busy (
		   .clk(clk),
		   .reset(reset),
		   .ARREADY_pre(ARREADY_pre),
		   .RVALID_pre(RVALID_pre),
		   .AWREADY_pre(AWREADY_pre),
		   .WREADY_pre(WREADY_pre),
		   .BVALID_pre(BVALID_pre),
		   .ARREADY(ARREADY),
		   .RVALID(RVALID),
		   .AWREADY(AWREADY),
		   .WREADY(WREADY),
		   .BVALID(BVALID),
		   .RBUSY(RBUSY),
		   .BBUSY(BBUSY)
		   );

   CREATE axi_slave_cmd_fifo.v
   PREFIX_cmd_fifo #(WCMD_DEPTH)
   PREFIX_wcmd_fifo (
		      .clk(clk),
		      .reset(reset),
		      .AADDR(AWADDR),
		      .AID(AWID),
		      .ASIZE(AWSIZE),
		      .ALEN(AWLEN),
		      .AVALID(AWVALID),
		      .AREADY(AWREADY),
		      .VALID(WVALID),
		      .READY(WREADY),
		      .LAST(WLAST),
		      .cmd_addr(wcmd_addr),
		      .cmd_id(wcmd_id), //not used
		      .cmd_size(wcmd_size),
		      .cmd_len(wcmd_len), //not used
		      .cmd_resp(),
		      .cmd_timeout(wcmd_timeout),
		      .cmd_ready(wcmd_ready),
		      .cmd_empty(wcmd_empty),
		      .cmd_full(wcmd_full)
		      );

   
   PREFIX_cmd_fifo #(RCMD_DEPTH)
   PREFIX_rcmd_fifo (
		      .clk(clk),
		      .reset(reset),
		      .AADDR(ARADDR),
		      .AID(ARID),
		      .ASIZE(ARSIZE),
		      .ALEN(ARLEN),
		      .AVALID(ARVALID),
		      .AREADY(ARREADY),
		      .VALID(RD_last),
		      .READY(1'b1),
		      .LAST(1'b1),
		      .cmd_addr(rcmd_addr),
		      .cmd_id(rcmd_id),
		      .cmd_size(rcmd_size),
		      .cmd_len(rcmd_len),
		      .cmd_resp(rcmd_resp),
		      .cmd_timeout(rcmd_timeout),
		      .cmd_ready(rcmd_ready),
		      .cmd_empty(),
		      .cmd_full()
		      );
   
   PREFIX_cmd_fifo #(RCMD_DEPTH)
   PREFIX_rcmd_fifo2 (
		       .clk(clk),
		       .reset(reset),
		       .AADDR(ARADDR),
		       .AID(ARID),
		       .ASIZE(ARSIZE),
		       .ALEN(ARLEN),
		       .AVALID(ARVALID),
		       .AREADY(ARREADY),
		       .VALID(RVALID),
		       .READY(RREADY),
		       .LAST(RLAST),
		       .cmd_addr(),
		       .cmd_id(rcmd_id2),
		       .cmd_size(),
		       .cmd_len(rcmd_len2),
		       .cmd_resp(),
		       .cmd_timeout(),
		       .cmd_ready(),
		       .cmd_empty(),
		       .cmd_full(rcmd_full)
		       );
   
   CREATE axi_slave_wresp_fifo.v
   PREFIX_wresp_fifo #(WCMD_DEPTH)
     PREFIX_wresp_fifo (
			 .clk(clk),
			 .reset(reset),
			 .AWVALID(AWVALID),
			 .AWREADY(AWREADY),
			 .AWADDR(AWADDR),
			 .WVALID(WVALID),
			 .WREADY(WREADY),
			 .WLAST(WLAST),
			 .WID(WID),
			 .BID(BID),
			 .BRESP(BRESP),
			 .BVALID(BVALID),
			 .BREADY(BREADY),
			 .empty(wresp_empty),
			 .pending(wresp_pending),
			 .timeout(wresp_timeout)
			 );
   
   CREATE axi_slave_addr_gen.v
   PREFIX_addr_gen
     PREFIX_addr_gen_wr (
			  .clk(clk),
			  .reset(reset),
			  .cmd_addr(wcmd_addr),
			  .cmd_size(wcmd_size),
			  .advance(WVALID & WREADY & (~WLAST)),
			  .restart(WVALID & WREADY & WLAST),
			  .ADDR(ADDR_WR)
			  );


   PREFIX_addr_gen
     PREFIX_addr_gen_rd (
			  .clk(clk),
			  .reset(reset),
			  .cmd_addr(rcmd_addr),
			  .cmd_size(rcmd_size),
			  .advance(RD),
			  .restart(RD_last),
			  .ADDR(ADDR_RD)
			  );
   
   CREATE axi_slave_rd_buff.v
   PREFIX_rd_buff #(DATA_BITS, ID_BITS) 
   PREFIX_rd_buff(
		   .clk(clk),
		   .reset(reset),
		   .RD(RD),
		   .DOUT(DOUT),
		   .rcmd_len(rcmd_len),
		   .rcmd_len2(rcmd_len2),
		   .rcmd_resp(rcmd_resp),
		   .rcmd_timeout(rcmd_timeout),
		   .rcmd_ready(rcmd_ready),
		   .RVALID(RVALID_pre),
		   .RREADY(RREADY),
		   .RLAST(RLAST),
		   .RDATA(RDATA),
		   .RD_last(RD_last),
		   .RRESP(RRESP),
		   .RBUSY(RBUSY)
		   );

   //wr_buff
   assign 		      WREADY_pre = (~wcmd_timeout) & (~wcmd_empty);
   assign 		      WR         = WVALID & WREADY & (~wcmd_empty);
   assign 		      DIN        = WDATA;
   assign 		      BSEL       = WSTRB;
   
   
endmodule


