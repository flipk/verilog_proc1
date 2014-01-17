`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:45:06 06/10/2012 
// Design Name: 
// Module Name:    memController 
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

module memController
  ( clk, reset,
    addr1, readdat1, request1, done1,
    addr2, writedat2, request2, done2,
    addr3, readdat3, request3, done3,
    memory_address, memory_write_enable,
    memory_write_data, memory_read_data );

   // note this treats memory as big-endian, that is,
   // dat[15:8] is the even addresses (addr[0] == 0) and
   // dat[ 7:0] is the  odd addresses (addr[0] == 1).

   // path 1 is connected to the instruction fetcher.
   // the fetcher will never do byte-oriented transfers,
   // thus byte support is not required here.

   // path 2 is connected to the store unit.  due to the
   // read-modify-write necessity, byte-oriented writes must
   // be handled here, thus request3 requires two selects
   // for byte-lanes. request2[0] is for the low byte (odd addrs),
   // request2[1] is for the high-byte (even).  when storing in
   // byte mode, the store unit will place the byte in the lowest 8
   // bits of writedat2[7:0], so we must shift it up for the high
   // byte.  note that byte-writes are a cycle
   // slower than word-writes, due to the read-modify-write cycle.

   // path 3 is connected to the load unit.  the load unit
   // will do the byte-separation. thus byte support is not
   // required here.

   // TODO :
   //   - check if two cycles are really needed for each thing.
   //   - check if there is a shortcut to bypass idle when another
   //     request is pending.

   input         clk;
   input         reset;
   input [15:0]  addr1;
   output [15:0] readdat1;
   input         request1;
   output        done1;
   input [15:0]  addr2;
   input [15:0]  writedat2;
   input [1:0]   request2;
   output        done2;
   input [15:0]  addr3;
   output [15:0] readdat3;
   input         request3;
   output        done3;

   output [15:0] memory_address;
   output        memory_write_enable;
   output [15:0] memory_write_data;
   input [15:0]  memory_read_data;

   reg           done1;
   reg           done2;
   reg           done3;
   reg [15:0]    readdat1;
   reg [15:0]    readdat3;
   reg [15:0]    memory_address;
   reg           memory_write_enable;
   reg [15:0]    memory_write_data;

   parameter [14:0]
     idle            = 15'b000000000000001,
     waitForRead1    = 15'b000000000000010,
     waitForRead11   = 15'b000000000000100,
     waitForWrite2   = 15'b000000000001000,
     waitForWrite21  = 15'b000000000010000,
     waitForWrite2u  = 15'b000000000100000,
     waitForWrite2u1 = 15'b000000001000000,
     waitForWrite2u2 = 15'b000000010000000,
     waitForWrite2u3 = 15'b000000100000000,
     waitForWrite2l  = 15'b000001000000000,
     waitForWrite2l1 = 15'b000010000000000,
     waitForWrite2l2 = 15'b000100000000000,
     waitForWrite2l3 = 15'b001000000000000,
     waitForRead3    = 15'b010000000000000,
     waitForRead31   = 15'b100000000000000;

   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="NO" *)
   reg [14:0]     state;

   always @(posedge clk) begin
      if (reset) begin
         done1 <= 1'b0;
         done2 <= 1'b0;
         done3 <= 1'b0;
         readdat1 <= 16'b0;
         readdat3 <= 16'b0;
         memory_address <= 0;
         memory_write_enable <= 0;
         memory_write_data <= 0;
         state <= idle;
      end else begin
         (* FULL_CASE, PARALLEL_CASE *)
         case (state)
           idle : begin
              done1 <= 1'b0;
              done2 <= 1'b0;
              done3 <= 1'b0;
              if (request3 & ~done3) begin
                 memory_address <= addr3;
                 state <= waitForRead3;
              end else if (request2[0] & request2[1] & ~done2) begin
                 // write word
                 memory_address <= addr2;
                 memory_write_data <= writedat2;
                 memory_write_enable <= 1'b1;
                 state <= waitForWrite2;
              end else if (~request2[0] & request2[1] & ~done2) begin
                 // write top byte
                 memory_address <= addr2;
                 state <= waitForWrite2u;
              end else if (request2[0] & ~request2[1] & ~done2) begin
                 // write bottom byte
                 memory_address <= addr2;
                 state <= waitForWrite2l;
              end else if (request1 & ~done1) begin
                 memory_address <= addr1;
                 state <= waitForRead1;
              end else
                state <= idle;
           end
           waitForRead1 : begin
              state <= waitForRead11;
           end
           waitForRead11 : begin
              readdat1 <= memory_read_data;
              done1 <= 1'b1;
              state <= idle;
           end
           waitForWrite2 : begin
              state <= waitForWrite21;
           end
           waitForWrite21 : begin
              done2 <= 1'b1;
              memory_write_enable <= 1'b0;
              state <= idle;
           end
           waitForWrite2u : begin
              state <= waitForWrite2u1;
           end
           waitForWrite2u1 : begin
              memory_write_data <= { writedat2[7:0], memory_read_data[7:0] };
              memory_write_enable <= 1'b1;
              state <= waitForWrite2u2;
           end
           waitForWrite2u2 : begin
              state <= waitForWrite2u3;
           end
           waitForWrite2u3 : begin
              done2 <= 1'b1;
              memory_write_enable <= 1'b0;
              state <= idle;
           end
           waitForWrite2l : begin
              state <= waitForWrite2l1;
           end
           waitForWrite2l1 : begin
              memory_write_data <= { memory_read_data[15:8], writedat2[7:0] };
              memory_write_enable <= 1'b1;
              state <= waitForWrite2l2;
           end
           waitForWrite2l2 : begin
              state <= waitForWrite2l3;
           end
           waitForWrite2l3 : begin
              done2 <= 1'b1;
              memory_write_enable <= 1'b0;
              state <= idle;
           end
           waitForRead3 : begin
              state <= waitForRead31;
           end
           waitForRead31 : begin
              readdat3 <= memory_read_data;
              done3 <= 1'b1;
              state <= idle;
           end
         endcase
      end
   end
   
endmodule
