`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:31:27 06/16/2012 
// Design Name: 
// Module Name:    instr_strir 
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
module instr_strir
  ( clk, reset, strir, strirb, operand, regbus1, regbus2,
    memory_address, memory_data, memory_request, memory_done);

   input          clk;
   input          reset;
   input          strir;
   input          strirb;
   input [15:0]   operand;
   input [15:0]   regbus1;
   input [15:0]   regbus2;
   output [15:0]  memory_address;
   output [15:0]  memory_data;
   output [1:0]   memory_request; // [0] : low (odd) [1] : high (even)
   input          memory_done;

   reg [15:0]     memory_address;
   reg [15:0]     memory_data;
   reg [1:0]      memory_request;

   parameter [1:0]
     idle            = 2'b01,
     waitForMemWrite = 2'b10;

   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="NO" *)
   reg [1:0]      state;

   wire [15:0]    address_sum = regbus2 + operand;

   always @(posedge clk) begin
      if (reset) begin
         state <= idle;
         memory_address <= 16'b0;
         memory_data <= 16'b0;
         memory_request <= 2'b0;
      end else begin
         (* FULL_CASE, PARALLEL_CASE *)
         case (state)
           idle: begin
              if (strir) begin
                 memory_address <= address_sum;
                 memory_data <= regbus1;
                 memory_request <= 2'b11;
                 state <= waitForMemWrite;
              end else if (strirb) begin
                 memory_address <= address_sum;
                 memory_data <= regbus1;
                 if (address_sum[0] == 0)
                   memory_request <= 2'b10;
                 else
                   memory_request <= 2'b01;
                 state <= waitForMemWrite;
              end else begin
                 memory_address <= 16'b0;
                 memory_data <= 16'b0;
                 memory_request <= 2'b0;
                 state <= idle;
              end
           end
           waitForMemWrite : begin
              if (memory_done) begin
                 memory_address <= 16'b0;
                 memory_data <= 16'b0;
                 memory_request <= 2'b0;
                 state <= idle;
              end else begin
                 state <= waitForMemWrite;
              end
           end
         endcase
      end
   end

endmodule
