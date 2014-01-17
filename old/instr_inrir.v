`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    
// Design Name: 
// Module Name:    instr_inrir
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
module instr_inrir
  ( clk, reset, inrir,
    operand, regbus2, r3we, regbus3,
    inbus_addr, inbus_data, inbus_re );

   input          clk;
   input          reset;
   input          inrir;
   input [15:0]   operand;
   input [15:0]   regbus2;
   output         r3we;
   output [15:0]  regbus3;

   output [7:0]   inbus_addr;
   input [7:0]    inbus_data;
   output         inbus_re;

   reg            r3we;
   reg [15:0]     regbus3;
   reg [7:0]      inbus_addr;
   reg            inbus_re;

   parameter [1:0]
     idle       = 2'b01,
     waitfor_in = 2'b10;

   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="NO" *)
   reg [1:0]      state, nextstate;

   always @(posedge clk) begin
      if (reset)
        state <= idle;
      else
        state <= nextstate;
   end

   wire [15:0] inbus_addr_instr = operand + regbus2;

   always @(*) begin
      if (reset) begin
         r3we = 1'b0;
         regbus3 = 16'b0;
         inbus_addr = 8'b0;
         inbus_re = 1'b0;
         nextstate = idle;
      end else begin
         (* FULL_CASE, PARALLEL_CASE *)
         case (state)
           idle : begin
              if (inrir) begin
                 r3we = 1'b0;
                 regbus3 = 16'b0;
                 inbus_addr = inbus_addr_instr[7:0];
                 inbus_re = 1'b1;
                 nextstate = waitfor_in;
              end else begin
                 r3we = 1'b0;
                 regbus3 = 16'b0;
                 inbus_addr = 8'b0;
                 inbus_re = 1'b0;
                 nextstate = idle;
              end
           end
           waitfor_in : begin
              r3we = 1'b1;
              regbus3 = { 8'b0, inbus_data };
              inbus_addr = inbus_addr_instr[7:0];
              inbus_re = 1'b1;
              nextstate = idle;
           end
         endcase
      end
   end

endmodule
