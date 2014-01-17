`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    
// Design Name: 
// Module Name:    instr_outrir
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
module instr_outrir
  ( clk, reset, outrir, operand, regbus1, regbus2,
    outbus_addr, outbus_data, outbus_we );

   input          clk;
   input          reset;
   input          outrir;
   input [15:0]   operand;
   input [15:0]   regbus1;
   input [15:0]   regbus2;
   output [7:0]  outbus_addr;
   output [7:0]  outbus_data;
   output         outbus_we;

   reg [7:0]      outbus_addr;
   reg [7:0]      outbus_data;
   reg            outbus_we;

   wire [15:0]    outbus_addr_instr = operand + regbus2;

   always @(posedge clk) begin
      if (reset) begin
         outbus_addr <= 8'b0;
         outbus_data <= 8'b0;
         outbus_we <= 1'b0;
      end else begin
         if (outrir) begin
            outbus_addr <= outbus_addr_instr[7:0];
            outbus_data <= regbus1[7:0];
            outbus_we <= 1'b1;
         end else begin
            outbus_addr <= 8'b0;
            outbus_data <= 8'b0;
            outbus_we <= 1'b0;
         end
      end
   end

endmodule
