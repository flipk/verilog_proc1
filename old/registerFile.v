`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:16:17 06/13/2012 
// Design Name: 
// Module Name:    registerFile 
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
module registerFile
  ( clk, reset, instruction, regbus3writeenable,
    regbus1, regbus2, regbus3, flagswriteenable,
    flagsbus, flags);

   input         clk;
   input         reset;
   input [15:0]  instruction;
   input         regbus3writeenable;
   output [15:0] regbus1;
   output [15:0] regbus2;
   input [15:0]  regbus3;
   input         flagswriteenable;
   input [1:0]   flagsbus;
   output [1:0]  flags;

   reg [1:0]     flags; // 1 : carry/borrow ; 0 : zero
   reg [15:0]    registers [0:15];

   wire [3:0]    regbus1select;
   wire [3:0]    regbus2select;

   assign regbus1select = instruction[3:0];  // reg1 is 'Rx'
   assign regbus2select = instruction[7:4];  // reg2 is 'Ry'
   assign regbus1 = registers[regbus1select];
   assign regbus2 = registers[regbus2select];

   integer       ind;
 
   always @(posedge clk) begin
      if (reset) begin
         flags <= 2'b0;
         for (ind=0; ind < 16; ind = ind + 1)
           registers[ind] <= 16'b0;
      end else begin
         if (regbus3writeenable) 
           registers[regbus1select] <= regbus3;
         if (flagswriteenable)
           flags <= flagsbus;
      end
   end
   
endmodule
