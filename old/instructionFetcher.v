`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:48:47 06/12/2012 
// Design Name: 
// Module Name:    instructionFetcher 
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
////////////////////////////////////////////////////////////////////////////////
module instructionFetcher
  ( clk, reset, memoryAddress, memoryReadData,
    memoryRequest, memoryDone,
    executeBusy,
    instruction, instructionReady,
    operand, flags, reg1bus, reg3bus, r3we, brr);

   input         clk;
   input         reset;
   output [15:0] memoryAddress;
   input [15:0]  memoryReadData;
   output        memoryRequest;
   input         memoryDone;
   input         executeBusy;
   output [15:0] instruction;
   output        instructionReady;
   output [15:0] operand;
   input [1:0]   flags;
   input [15:0]  reg1bus;
   output [15:0] reg3bus;
   output        r3we;
   input         brr;

   reg [15:0]    memoryAddress;
   reg           memoryRequest;
   reg [15:0]    instruction;
   reg [15:0]    instructionHolding;
   reg           instructionReady;
   reg [15:0]    operand;
   reg [15:0]    reg3bus;
   reg           r3we;
   reg           withLink;           
   reg [15:0]    pc;
   
   parameter [8:0] 
     sendAddress       = 9'b000000001,
     waitForNotBusy1   = 9'b000000010,
     waitForMemDone    = 9'b000000100,
     waitForJumpPos    = 9'b000001000,
     waitForBranchPos  = 9'b000010000,
     waitForOperand    = 9'b000100000,
     waitForNotBusy3   = 9'b001000000,
     waitForNotBusy2   = 9'b010000000,
     waitForBRR        = 9'b100000000;

   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="NO" *)
   reg [8:0]     state;

   wire [15:0]   relative_pc = pc + memoryReadData;

   always@(posedge clk) begin
      if (reset) begin
         state <= sendAddress;
         pc <= 16'b0;
         memoryRequest <= 1'b0;
         memoryAddress <= 16'b0;
         instruction <= 16'b0;
         instructionReady <= 1'b0;
         operand <= 16'b0;
         reg3bus <= 16'b0;
         r3we <= 1'b0;
         withLink <= 1'b0;
      end
      else begin
         (* FULL_CASE, PARALLEL_CASE *)
         case (state)
           sendAddress : begin
              reg3bus <= 16'b0;
              r3we <= 1'b0;
              instructionReady <= 1'b0;
              memoryAddress <= pc;
              pc <= pc + 16'd2;
              memoryRequest <= 1'b1;
              state <= waitForMemDone;
              withLink <= 1'b0;
           end
           waitForMemDone : begin
              if (memoryDone) begin
                 memoryRequest <= 1'b0;
                 instructionHolding <= memoryReadData;
                 if (memoryReadData[15:10] == 6'b111010) begin
                    // ba thru bge
                    pc <= pc + 16'd2;
                    state <= waitForBranchPos;
                    memoryRequest <= 1'b1;
                    memoryAddress <= pc;
                 end else if (memoryReadData[15:11] == 5'b11111) begin
                    // jmp
                    pc <= pc + 16'd2;
                    withLink <= memoryReadData[10];
                    state <= waitForJumpPos;
                    memoryRequest <= 1'b1;
                    memoryAddress <= pc;
                    // decoder doesn't use instruction for a jmp,
                    // but we need it so regbus3 points in the right
                    // direction in case this is a jmpl
                    instruction <= memoryReadData;
                 end else if (memoryReadData[15:11] == 5'b11010) begin
                    // br
                    memoryRequest <= 1'b0;
                    instruction <= memoryReadData;
                    withLink <= memoryReadData[10];
                    if (executeBusy) begin
                       state <= waitForNotBusy2;
                    end else begin
                       instructionReady <= 1'b1;
                       state <= waitForBRR;
                    end
                 end else if (memoryReadData[11] == 1'b1) begin
                    // must fetch operand, all instructions with
                    // bit 7==1 have an operand byte
                    memoryAddress <= pc;
                    memoryRequest <= 1'b1;
                    pc <= pc + 16'd2;
                    state <= waitForOperand;
                 end else begin
                    instruction <= memoryReadData;
                    if (executeBusy) begin
                       state <= waitForNotBusy1;
                    end else begin
                       instructionReady <= 1'b1;
                       state <= sendAddress;
                    end
                 end
              end else
                state <= waitForMemDone;
           end
           waitForNotBusy1 : begin
              if (executeBusy) begin
                 state <= waitForNotBusy1;
              end else begin
                 instructionReady <= 1'b1;
                 state <= sendAddress;
              end
           end
           waitForJumpPos : begin
              if (memoryDone) begin
                 memoryRequest <= 1'b0;
                 if (withLink) begin
                    reg3bus <= pc;
                    r3we <= 1'b1;
                 end
                 pc <= memoryReadData;
                 state <= sendAddress;
              end else begin
                 state <= waitForJumpPos;
              end
           end
           waitForBranchPos : begin
              if (memoryDone) begin
                 memoryRequest <= 1'b0;
                 state <= sendAddress;
                 case (instructionHolding[2:0])
                   3'b000 : begin // ba : always
                      pc <= relative_pc;
                   end
                   3'b001 : begin // beq : equal
                      if (flags[0])
                        pc <= relative_pc;
                   end
                   3'b010 : begin // bne : not equal
                      if (!flags[0])
                        pc <= relative_pc;
                   end
                   3'b011 : begin // blt : less than
                      if (flags[1])
                        pc <= relative_pc;
                   end
                   3'b100 : begin // bgt : greator than
                      if (!flags[0] && !flags[1])
                        pc <= relative_pc;
                   end
                   3'b101 : begin // ble : less than or equal
                      if (flags[0] || flags[1])
                        pc <= relative_pc;
                   end
                   3'b110 : begin // bge : greator than or equal
                      if (!flags[0])
                        pc <= relative_pc;
                   end
                 endcase
              end else
                state <= waitForBranchPos;
           end
           waitForOperand : begin
              if (memoryDone) begin
                 memoryRequest <= 1'b0;
                 operand <= memoryReadData;
                 instruction <= instructionHolding;
                 if (executeBusy) begin
                    state <= waitForNotBusy3;
                 end else begin
                    instructionReady <= 1'b1;
                    state <= sendAddress;
                 end
              end else
                state <= waitForOperand;
           end
           waitForNotBusy3 : begin
              if (executeBusy) begin
                 state <= waitForNotBusy3;
              end else begin
                 instructionReady <= 1'b1;
                 state <= sendAddress;                 
              end
           end
           waitForNotBusy2 : begin
              if (executeBusy) begin
                 state <= waitForNotBusy2;
              end else begin
                 instructionReady <= 1'b1;
                 state <= waitForBRR;
              end
           end
           waitForBRR : begin
              instructionReady <= 1'b0;
              if (brr) begin
                 if (withLink) begin
                    reg3bus <= pc;
                    r3we <= 1'b1;
                 end
                 pc <= reg1bus;
                 state <= sendAddress;
              end else begin
                 state <= waitForBRR;
              end
           end
         endcase
      end
   end
endmodule
