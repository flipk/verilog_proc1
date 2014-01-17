`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:50:12 06/21/2012 
// Design Name: 
// Module Name:    mem1 
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
module mem1
  #(parameter MEMORY_SIZE = 256)
  ( clk, reset, address, write_data, read_data, write_enable );

   input         clk;
   input         reset;
   input [15:0]  address;
   input [15:0]  write_data;
   output [15:0] read_data;
   input         write_enable;

   reg [15:0] 	 memory [0:(MEMORY_SIZE/2)-1];

   initial $readmemh("memory1.hex", memory, 0, (MEMORY_SIZE/2)-1);

   reg [15:0] 	 read_data_reg;
   assign read_data = read_data_reg;

   always @(posedge clk) begin
      if (reset) begin
         read_data_reg <= 0;
      end else begin
         if (write_enable)
           memory[address[15:1]] <= write_data;
         if (address < MEMORY_SIZE)
           read_data_reg <= memory[address[15:1]];
         else
           read_data_reg <= 16'b0;
      end
   end   

endmodule
