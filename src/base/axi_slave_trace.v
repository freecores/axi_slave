
OUTFILE PREFIX_trace.v

INCLUDE def_axi_slave.txt
  
module PREFIX_trace(PORTS);
   parameter                  SLAVE_NUM = 0;
      
   input 		      clk;
   input 		      reset;

   input                      GROUP_STUB_MEM;
   

   reg                        RD_d;
   reg [ADDR_BITS-1:0] 	      ADDR_RD_d;

   wire [31:0] 		      ADDR_WR_disp =  ADDR_WR;	
   wire [31:0] 		      ADDR_RD_disp =  ADDR_RD_d;

   reg [64*8-1:0]             filename;
   integer                    file_ptr;
   
   
   initial
     begin
        //erase trace
        file_ptr = $fopen({"PREFIX.trc"}, "w");
        $fwrite(file_ptr, "\n");
        $fclose(file_ptr);
     end
   
   always @(posedge clk or posedge reset)
     if (reset)
       begin
          ADDR_RD_d <= #FFD 'd0;
          RD_d <= #FFD 'd0;
       end
     else
       begin
          ADDR_RD_d <= #FFD ADDR_RD;
          RD_d <= #FFD RD;
       end
   
   always @(posedge clk)
     if (WR)
       begin
          file_ptr = $fopen({"PREFIX.trc"}, "a");
          $fwrite(file_ptr, "%16d: PREFIX%0d WR: Addr: 0x%EXPR(ADDR_BITS/4)h, Data: 0x%EXPR(DATA_BITS/4)h, Bsel: 0x%EXPR(DATA_BITS/32)h\n", $time, SLAVE_NUM, ADDR_WR_disp, DIN, BSEL);
          $fclose(file_ptr);
       end
   
   always @(posedge clk)
     if (RD_d)
       begin
          file_ptr = $fopen({"PREFIX.trc"}, "a");
          $fwrite(file_ptr, "%16d: PREFIX%0d RD: Addr: 0x%EXPR(ADDR_BITS/4)h, Data: 0x%EXPR(DATA_BITS/4)h\n", $time, SLAVE_NUM, ADDR_RD_disp, DOUT);
          $fclose(file_ptr);
       end
      
endmodule

   
