`timescale 1ns / 1ps

module processorVersion
  #( parameter DEVADDR = 0,
     parameter VERSION = 0,
     parameter CPUID = 0 )
  ( clk,
    INBUS_ADDR, INBUS_DATA, INBUS_RE );

   input             clk;
   input [7:0]       INBUS_ADDR;
   output reg [7:0]  INBUS_DATA;
   input             INBUS_RE;

   always @(posedge clk) begin
      INBUS_DATA <= 0;
      if (INBUS_RE) begin
         case (INBUS_ADDR)
           (DEVADDR+0) : begin
              INBUS_DATA <= VERSION;
           end
           (DEVADDR+1) : begin
              INBUS_DATA <= CPUID;
           end
         endcase
      end
   end

endmodule // processorVersion
