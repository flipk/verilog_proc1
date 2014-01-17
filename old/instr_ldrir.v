`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:31:53 06/15/2012 
// Design Name: 
// Module Name:    instr_ldrir 
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
module instr_ldrir
  ( clk, reset, ldrir, ldrirb, executeBusy, operand, regbus2,
    r3we, regbus3, memory_address, memory_data,
    memory_request, memory_done);

   input         clk;
   input         reset;
   input         ldrir;
   input         ldrirb;
   output        executeBusy;
   input [15:0]  operand;
   input [15:0]  regbus2;
   output        r3we;
   output [15:0] regbus3;
   output [15:0] memory_address;
   input [15:0]  memory_data;
   output        memory_request;
   input         memory_done;

   reg           executeBusy;
   reg [15:0]    memory_address;
   reg           memory_request;
   reg [15:0]    regbus3;
   reg           r3we;

   parameter [3:0]
     idle            = 4'b0001,
     waitForMemRead  = 4'b0010,
     waitForMemReadu = 4'b0100,
     waitForMemReadl = 4'b1000;
   
   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="NO" *)
   reg [3:0]     state;

   wire [15:0] address_sum = operand + regbus2;

   always @(posedge clk) begin
      if (reset) begin
         executeBusy <= 1'b0;
         memory_address <= 16'b0;
         memory_request <= 1'b0;
         regbus3 <= 16'b0;
         r3we <= 1'b0;
         state <= idle;
      end else begin
         (* FULL_CASE, PARALLEL_CASE *)
         case (state)
           idle : begin
              regbus3 <= 16'b0;
              r3we <= 1'b0;
              if (ldrir) begin
                 executeBusy <= 1'b1;
                 memory_address <= address_sum;
                 memory_request <= 1'b1;
                 state <= waitForMemRead;
              end else if (ldrirb) begin
                 executeBusy <= 1'b1;
                 // note that the memory discards bottom bit anyway.
                 memory_address <= address_sum;
                 memory_request <= 1'b1;
                 if (address_sum[0] == 0)
                   state <= waitForMemReadu;
                 else
                   state <= waitForMemReadl;
              end else begin
                 memory_address <= 16'b0;
                 memory_request <= 1'b0;
                 state <= idle;
              end
           end
           waitForMemRead : begin
              if (memory_done) begin
                 executeBusy <= 1'b0;
                 memory_address <= 16'b0;
                 memory_request <= 1'b0;
                 regbus3 <= memory_data;
                 r3we <= 1'b1;
                 state <= idle;
              end else begin
                 state <= waitForMemRead;
              end
           end
           waitForMemReadu : begin
              if (memory_done) begin
                 executeBusy <= 1'b0;
                 memory_address <= 16'b0;
                 memory_request <= 1'b0;
                 regbus3 <= { 8'b0, memory_data[15:8] };
                 r3we <= 1'b1;
                 state <= idle;
              end else begin
                 state <= waitForMemReadu;
              end
           end
           waitForMemReadl : begin
              if (memory_done) begin
                 executeBusy <= 1'b0;
                 memory_address <= 16'b0;
                 memory_request <= 1'b0;
                 regbus3 <= { 8'b0, memory_data[7:0] };
                 r3we <= 1'b1;
                 state <= idle;
              end else begin
                 state <= waitForMemReadl;
              end
           end
         endcase
      end
   end

endmodule
