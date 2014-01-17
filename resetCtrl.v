`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:35:59 06/28/2012 
// Design Name: 
// Module Name:    resetCtrl 
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
module resetCtrl
  ( clk, reset_clkgen,
    locked_proc1, locked_rs232,
    reset_rs232_complete,
    reset_rs232, reset_proc1 );

   input       clk;
   output      reset_clkgen;
   input       locked_proc1;
   input       locked_rs232;
   input       reset_rs232_complete;      
   output      reset_rs232;
   output      reset_proc1;

   // start out with reset_clkgen=1, reset_rs232=1, reset_proc1=1
   // count to 16, then release reset_clkgen
   // wait for locked_proc1 and locked_rs232
   // wait for first positive edge on rs232 clock
   // count to 64, then release reset_rs232
   // count to 16, then release reset_proc1

   reg         reset_clkgen_reg = 1;
   reg         reset_rs232_reg = 1;
   reg         reset_proc1_reg = 1;

   reg [6:0]   counter;

   assign reset_clkgen = reset_clkgen_reg;
   assign reset_rs232 = reset_rs232_reg;
   assign reset_proc1 = reset_proc1_reg;
   
   parameter [6:0]
     IN_RESET            = 7'b0000001,
     COUNT_CLKGEN        = 7'b0000010,
     WAIT_LOCKED         = 7'b0000100,
     WAIT_POSEDGE_RS232  = 7'b0001000,
     COUNT_RS232         = 7'b0010000,
     COUNT_PROC          = 7'b0100000,
     RUNNING             = 7'b1000000;

   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="NO" *)
   reg [6:0]   state = IN_RESET;

   always@(posedge clk)
     (* FULL_CASE, PARALLEL_CASE *)
     case (state)
       IN_RESET : begin
          state <= COUNT_CLKGEN;
          counter <= 7'd0;
          reset_clkgen_reg <= 1;
          reset_rs232_reg <= 1;
          reset_proc1_reg <= 1;
       end
       COUNT_CLKGEN : begin
          if (counter >= 7'd16) begin
             reset_clkgen_reg <= 0;
             state <= WAIT_LOCKED;
          end else begin
             counter <= counter + 1;
             state <= COUNT_CLKGEN;
          end
       end
       WAIT_LOCKED : begin
          if (locked_proc1 & locked_rs232) begin
             state <= WAIT_POSEDGE_RS232;
          end else begin
             state <= WAIT_LOCKED;
          end
       end
       WAIT_POSEDGE_RS232 : begin
          if (reset_rs232_complete) begin
             counter <= 7'd0;
             state <= COUNT_RS232;
          end else begin
             state <= WAIT_POSEDGE_RS232;
          end
       end
       COUNT_RS232 : begin
          if (counter >= 7'd64) begin
             reset_rs232_reg <= 0;
             counter <= 7'd0;
             state <= COUNT_PROC;
          end else begin
             counter <= counter + 1;
             state <= COUNT_RS232;
          end
       end
       COUNT_PROC : begin
          if (counter >= 7'd16) begin
             reset_proc1_reg <= 0;
             state <= RUNNING;
          end else begin
             counter <= counter + 1;
             state <= COUNT_PROC;
          end
       end
       RUNNING : begin
          state <= RUNNING;
       end
     endcase

endmodule
