`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    
// Design Name: 
// Module Name:    
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
///////////////////////////////////////////////////////////////////////////////
module cycleCounter
  #( parameter DEVADDR = 0 )
  ( clk, reset,
    OUTBUS_ADDR, OUTBUS_DATA, OUTBUS_WE,
    INBUS_ADDR, INBUS_DATA, INBUS_RE );

   input        clk;
   input        reset;
   input [7:0]  OUTBUS_ADDR;
   input [7:0]  OUTBUS_DATA;
   input        OUTBUS_WE;
   input [7:0]  INBUS_ADDR;
   output [7:0] INBUS_DATA;
   input        INBUS_RE;

   reg [7:0]    INBUS_DATA;

   reg [63:0]   counter;
   reg          counter_enabled;

   always @(posedge clk) begin
      if (reset) begin
         INBUS_DATA <= 0;
         counter_enabled <= 0;
         counter <= 0;
      end else begin
         if (counter_enabled)
           counter <= counter + 1;
         if (OUTBUS_WE) begin
            if (OUTBUS_ADDR == DEVADDR) begin
               counter_enabled <= OUTBUS_DATA[0];
               if (OUTBUS_DATA[1])
                 counter <= 0;
            end
         end
         INBUS_DATA <= 0;
         if (INBUS_RE) begin
            if (INBUS_ADDR == (DEVADDR+0)) begin
               INBUS_DATA <= counter[63:56];
            end
            if (INBUS_ADDR == (DEVADDR+1)) begin
               INBUS_DATA <= counter[55:48];
            end
            if (INBUS_ADDR == (DEVADDR+2)) begin
               INBUS_DATA <= counter[47:40];
            end
            if (INBUS_ADDR == (DEVADDR+3)) begin
               INBUS_DATA <= counter[39:32];
            end
            if (INBUS_ADDR == (DEVADDR+4)) begin
               INBUS_DATA <= counter[31:24];
            end
            if (INBUS_ADDR == (DEVADDR+5)) begin
               INBUS_DATA <= counter[23:16];
            end
            if (INBUS_ADDR == (DEVADDR+6)) begin
               INBUS_DATA <= counter[15: 8];
            end
            if (INBUS_ADDR == (DEVADDR+7)) begin
               INBUS_DATA <= counter[ 7: 0];
            end
         end
      end
   end


endmodule // cycleCounter
