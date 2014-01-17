`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:18:06 06/15/2012 
// Design Name: 
// Module Name:    processorTop 
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
module processorTop
  #( parameter MEMORY_SIZE = 1024,
     parameter MEMORY_FILE = "bootloader.hex" )
   ( CLK, RESET,
     OUTBUS_ADDR, OUTBUS_DATA, OUTBUS_WE,
     INBUS_ADDR, INBUS_DATA, INBUS_RE );

   input         CLK;
   input         RESET;
   output [7:0]  OUTBUS_ADDR;
   output [7:0]  OUTBUS_DATA;
   output        OUTBUS_WE;
   output [7:0]  INBUS_ADDR;
   input [7:0]   INBUS_DATA;
   output        INBUS_RE;

   reg [7:0]     OUTBUS_ADDR;
   reg [7:0]     OUTBUS_DATA;
   reg           OUTBUS_WE;
   reg [7:0]     INBUS_ADDR;
   reg           INBUS_RE;

   reg [15:0]    memory [0:(MEMORY_SIZE/2)-1];
   reg [15:0]    regs [0:15];

   reg           flag_c; // carry/borrow
   reg           flag_z; // zero
   reg           in_pending;

   initial $readmemh(MEMORY_FILE, memory, 0, (MEMORY_SIZE/2)-1);

   reg [15:0]    pc;
   reg [15:0]    opcode;

   reg [15:0]    mem_r_addr;
   wire [15:0]   mem_r_contents = memory[mem_r_addr[15:1]];
   reg           mem_w_enable;
   reg [15:0]    mem_w_addr;
   reg [15:0]    mem_w_contents;

   always @(posedge CLK) begin
      if (mem_w_enable)
        memory[mem_w_addr[15:1]] <= mem_w_contents;
   end

   // these are only valid in the first clock, since
   // they're based on mem_r_contents.
   wire [3:0]    reg_x1 = mem_r_contents[3:0];
   wire [3:0]    reg_y1 = mem_r_contents[7:4];
   wire [15:0]   rx1 = regs[reg_x1];
   wire [15:0]   ry1 = regs[reg_y1];
   wire [15:0]   orrr  = rx1 | ry1;
   wire [15:0]   andrr = rx1 & ry1;
   wire [15:0]   xorrr = rx1 ^ ry1;
   wire [15:0]   negr  = (~rx1) + 1;
   wire [16:0]   sumrr = {1'b0,rx1} + {1'b0,ry1};
   wire [16:0]   subrr = {1'b1,rx1} - {1'b0,ry1};

   // these are only valid in the second clock, since
   // they're based on opcode and mem_r_contents
   wire [3:0]    reg_x = opcode[3:0];
   wire [3:0]    reg_y = opcode[7:4];
   wire [15:0]   rx = regs[reg_x];
   wire [15:0]   ry = regs[reg_y];
   wire [16:0]   sumri = {1'b0,rx} + {1'b0,mem_r_contents};
   wire [16:0]   subri = {1'b1,rx} - {1'b0,mem_r_contents};
   wire [15:0]   orri  = rx | mem_r_contents;
   wire [15:0]   andri = rx & mem_r_contents;
   wire [15:0]   xorri = rx ^ mem_r_contents;

   parameter [5:0] 
     state_decode_single = 6'b000001,
     state_decode_double = 6'b000010,
     state_in1           = 6'b000100,
     state_load          = 6'b001000,
     state_loadb         = 6'b010000,
     state_storeb        = 6'b100000;

   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="NO" *)
   reg [5:0]     state = state_decode_single;

   always @(posedge CLK) begin
      if (RESET) begin
         pc <= 0;
         flag_c <= 0;
         flag_z <= 0;
         opcode <= 0;
         OUTBUS_ADDR <= 0;
         OUTBUS_DATA <= 0;
         OUTBUS_WE <= 0;
         INBUS_ADDR <= 0;
         INBUS_RE <= 0;
         state <= state_decode_single;
         mem_w_enable <= 0;
         mem_r_addr <= 0;
         in_pending <= 0;
      end else begin
         (* FULL_CASE, PARALLEL_CASE *)
         case (state)
           state_decode_single : begin
              OUTBUS_ADDR <= 0;
              OUTBUS_DATA <= 0;
              OUTBUS_WE <= 0;
              INBUS_ADDR <= 0;
              INBUS_RE <= 0;
              opcode <= mem_r_contents;
              pc <= pc + 2;
              mem_r_addr <= pc + 2;
              mem_w_enable <= 0;
              state <= state_decode_single;
              if (in_pending) begin
                 INBUS_ADDR <= 0;
                 regs[reg_x] <= { 8'b0, INBUS_DATA };
                 in_pending <= 0;
              end

              // note that we look at mem_r_contents because
              // the results won't appear in opcode until
              // the next clock.
              if (mem_r_contents[11]) begin // opcode
                 state <= state_decode_double;
              end

              // note that [11] is not set in any of these
              // because they are all single-word instructions.
              case (mem_r_contents[15:10]) // opcode
                6'b000000 : begin // or r,r
                   regs[reg_x1] <= orrr;
                   flag_c <= 0;
                   flag_z <= (orrr == 0);
                   state <= state_decode_single;
                end
                6'b000001 : begin // mr rx, ry
                   regs[reg_x1] <= ry1;
                   flag_c <= 0;
                   flag_z <= (regs[reg_y1] == 0);
                   state <= state_decode_single;
                end
                6'b000100 : begin // and r,r
                   regs[reg_x1] <= andrr;
                   flag_c <= 0;
                   flag_z <= (andrr == 0);
                   state <= state_decode_single;
                end
                6'b001000 : begin // xor r,r
                   regs[reg_x1] <= xorrr;
                   flag_c <= 0;
                   flag_z <= (xorrr == 0);
                   state <= state_decode_single;
                end
                6'b001100 : begin // add r,r
                   regs[reg_x1] <= sumrr[15:0];
                   flag_c <= sumrr[16];
                   flag_z <= (sumrr[15:0] == 0);
                   state <= state_decode_single;
                end
                6'b001101 : begin // addb r,r
                   regs[reg_x1] <= { {8{sumrr[7]}}, sumrr[7:0] };
                   flag_c <= sumrr[8];
                   flag_z <= (sumrr[7:0] == 0);
                   state <= state_decode_single;
                end
                6'b010000 : begin // sub rx, ry
                   regs[reg_x1] <= subrr[15:0];
                   flag_c <= ~subrr[16];
                   flag_z <= (subrr[15:0] == 0);
                   state <= state_decode_single;
                end
                6'b010001 : begin // subb rx ,ry
                   regs[reg_x1] <= { {8{subrr[7]}}, subrr[7:0] };
                   flag_c <= subrr[8]; // validate?
                   flag_z <= (subrr[7:0] == 0);
                   state <= state_decode_single;
                end
                6'b010100 : begin // rol r,r
                   case (ry1[3:0])
                     4'd0  : regs[reg_x1] <= {rx1[15:0]          };
                     4'd1  : regs[reg_x1] <= {rx1[14:0],rx1[15   ]};
                     4'd2  : regs[reg_x1] <= {rx1[13:0],rx1[15:14]};
                     4'd3  : regs[reg_x1] <= {rx1[12:0],rx1[15:13]};
                     4'd4  : regs[reg_x1] <= {rx1[11:0],rx1[15:12]};
                     4'd5  : regs[reg_x1] <= {rx1[10:0],rx1[15:11]};
                     4'd6  : regs[reg_x1] <= {rx1[ 9:0],rx1[15:10]};
                     4'd7  : regs[reg_x1] <= {rx1[ 8:0],rx1[15:9 ]};
                     4'd8  : regs[reg_x1] <= {rx1[ 7:0],rx1[15:8 ]};
                     4'd9  : regs[reg_x1] <= {rx1[ 6:0],rx1[15:7 ]};
                     4'd10 : regs[reg_x1] <= {rx1[ 5:0],rx1[15:6 ]};
                     4'd11 : regs[reg_x1] <= {rx1[ 4:0],rx1[15:5 ]};
                     4'd12 : regs[reg_x1] <= {rx1[ 3:0],rx1[15:4 ]};
                     4'd13 : regs[reg_x1] <= {rx1[ 2:0],rx1[15:3 ]};
                     4'd14 : regs[reg_x1] <= {rx1[ 1:0],rx1[15:2 ]};
                     4'd15 : regs[reg_x1] <= {rx1[ 0  ],rx1[15:1 ]};
                   endcase
                   state <= state_decode_single;
                end
                6'b010101 : begin // rolb r,r
                   case (ry1[2:0])
                     3'd0  : regs[reg_x1] <= {8'b0,rx1[7:0]        };
                     3'd1  : regs[reg_x1] <= {8'b0,rx1[6:0],rx1[7  ]};
                     3'd2  : regs[reg_x1] <= {8'b0,rx1[5:0],rx1[7:6]};
                     3'd3  : regs[reg_x1] <= {8'b0,rx1[4:0],rx1[7:5]};
                     3'd4  : regs[reg_x1] <= {8'b0,rx1[3:0],rx1[7:4]};
                     3'd5  : regs[reg_x1] <= {8'b0,rx1[2:0],rx1[7:3]};
                     3'd6  : regs[reg_x1] <= {8'b0,rx1[1:0],rx1[7:2]};
                     3'd7  : regs[reg_x1] <= {8'b0,rx1[0  ],rx1[7:1]};
                   endcase
                   state <= state_decode_single;
                end
                6'b011000 : begin // cmp r,r
                   flag_c <= ~subrr[16];
                   flag_z <= (subrr[15:0] == 0);
                   state <= state_decode_single;
                end
                6'b011001 : begin // cmpb r,r
                   flag_c <= subrr[8];
                   flag_z <= (subrr[7:0] == 0);
                   state <= state_decode_single;
                end
                6'b011100 : begin // neg r
                   regs[reg_x1] <= negr;
                   state <= state_decode_single;
                end
                6'b011101 : begin // negb r
                   regs[reg_x1] <= { {8{negr[7]}}, negr[7:0] };
                   state <= state_decode_single;
                end
                6'b110100 : begin // br rx
                   pc <= rx1;
                   mem_r_addr <= rx1;
                   state <= state_decode_single;
                end
                6'b110101 : begin // brl rx
                   regs[reg_x1] <= pc + 2;
                   pc <= rx1;
                   mem_r_addr <= rx1;
                   state <= state_decode_single;
                end
              endcase // case (op)
           end // case: state_decode_single
           
           state_decode_double : begin
              pc <= pc + 2;
              mem_r_addr <= pc + 2;
              case (opcode[15:10])
                6'b000010 : begin // ori r,i
                   regs[reg_x] <= orri;
                   flag_c <= 0;
                   flag_z <= (orri == 0);
                   state <= state_decode_single;
                end
                6'b000110 : begin // andi r,i
                   regs[reg_x] <= andri;
                   flag_c <= 0;
                   flag_z <= (andri == 0);
                   state <= state_decode_single;
                end
                6'b001010 : begin // xori r,i
                   regs[reg_x] <= xorri;
                   flag_c <= 0;
                   flag_z <= (xorri == 0);
                   state <= state_decode_single;
                end
                6'b001110 : begin // addi r,i
                   regs[reg_x] <= sumri;
                   flag_c <= sumri[16];
                   flag_z <= (sumri[15:0] == 0);
                   state <= state_decode_single;
                end
                6'b001111 : begin // addbi r,i
                   regs[reg_x] <= { {8{sumri[7]}}, sumri[7:0] };
                   flag_c <= sumri[8];
                   flag_z <= (sumri[7:0] == 0);
                   state <= state_decode_single;
                end
                6'b010010 : begin // subi rx, i
                   regs[reg_x] <= subri[15:0];
                   flag_c <= ~subri[16];
                   flag_z <= (subri[15:0] == 0);
                   state <= state_decode_single;
                end
                6'b010011 : begin // subbi rx, i
                   regs[reg_x] <= { {8{subri[7]}}, subri[7:0] };
                   flag_c <= subri[8];
                   flag_z <= (subri[7:0] == 0);
                   state <= state_decode_single;
                end
                6'b010110 : begin // roli rx,i
                   case (mem_r_contents[3:0]) // operand
                     4'd0  : regs[reg_x] <= {rx[15:0]          };
                     4'd1  : regs[reg_x] <= {rx[14:0],rx[15   ]};
                     4'd2  : regs[reg_x] <= {rx[13:0],rx[15:14]};
                     4'd3  : regs[reg_x] <= {rx[12:0],rx[15:13]};
                     4'd4  : regs[reg_x] <= {rx[11:0],rx[15:12]};
                     4'd5  : regs[reg_x] <= {rx[10:0],rx[15:11]};
                     4'd6  : regs[reg_x] <= {rx[ 9:0],rx[15:10]};
                     4'd7  : regs[reg_x] <= {rx[ 8:0],rx[15:9 ]};
                     4'd8  : regs[reg_x] <= {rx[ 7:0],rx[15:8 ]};
                     4'd9  : regs[reg_x] <= {rx[ 6:0],rx[15:7 ]};
                     4'd10 : regs[reg_x] <= {rx[ 5:0],rx[15:6 ]};
                     4'd11 : regs[reg_x] <= {rx[ 4:0],rx[15:5 ]};
                     4'd12 : regs[reg_x] <= {rx[ 3:0],rx[15:4 ]};
                     4'd13 : regs[reg_x] <= {rx[ 2:0],rx[15:3 ]};
                     4'd14 : regs[reg_x] <= {rx[ 1:0],rx[15:2 ]};
                     4'd15 : regs[reg_x] <= {rx[ 0  ],rx[15:1 ]};
                   endcase // case (operand[3:0])
                   state <= state_decode_single;
                end
                6'b010111 : begin // rolbi rx,i
                   case (mem_r_contents[2:0]) // operand
                     3'd0 : regs[reg_x] <= {8'b0,rx[7:0]        };
                     3'd1 : regs[reg_x] <= {8'b0,rx[6:0],rx[7  ]};
                     3'd2 : regs[reg_x] <= {8'b0,rx[5:0],rx[7:6]};
                     3'd3 : regs[reg_x] <= {8'b0,rx[4:0],rx[7:5]};
                     3'd4 : regs[reg_x] <= {8'b0,rx[3:0],rx[7:4]};
                     3'd5 : regs[reg_x] <= {8'b0,rx[2:0],rx[7:3]};
                     3'd6 : regs[reg_x] <= {8'b0,rx[1:0],rx[7:2]};
                     3'd7 : regs[reg_x] <= {8'b0,rx[0  ],rx[7:1]};
                   endcase // case (operand[2:0])
                   state <= state_decode_single;
                end
                6'b011010 : begin // cmpi r,i
                   flag_c <= ~subri[16];
                   flag_z <= (subri[15:0] == 0);
                   state <= state_decode_single;
                end
                6'b011011 : begin // cmpbi r,i
                   flag_c <= subri[8];
                   flag_z <= (subri[7:0] == 0);
                   state <= state_decode_single;
                end
                6'b100010 : begin // li rx, i
                   regs[reg_x] <= mem_r_contents; // operand
                   flag_c <= 0;
                   flag_z <= (mem_r_contents == 0); // operand
                   state <= state_decode_single;
                end
                6'b100011 : begin // lib rx, i
                   regs[reg_x] <= { 8'b0, mem_r_contents[7:0] }; // operand
                   flag_c <= 0;
                   flag_z <= (mem_r_contents[7:0] == 0); // operand
                   state <= state_decode_single;
                end
                6'b100110 : begin // ld rx, i(ry)
                   mem_r_addr <= mem_r_contents + ry;
                   state <= state_load;
                end
                6'b100111 : begin // ldb rx, i(ry)
                   mem_r_addr <= mem_r_contents + ry;
                   state <= state_loadb;
                end
                6'b101010 : begin // st rx, i(ry)
                   mem_w_addr <= mem_r_contents + ry;
                   mem_w_contents <= rx;
                   mem_w_enable <= 1;
                   state <= state_decode_single;
                end
                6'b101011 : begin // stb rx, i(ry)
                   mem_r_addr <= mem_r_contents + ry;
                   state <= state_storeb;
                end
                6'b101110 : begin // in rx, i(ry)
                   INBUS_ADDR <= mem_r_contents + ry;
                   INBUS_RE <= 1;
                   state <= state_in1;
                end
                6'b110010 : begin // out rx, i(ry)
                   OUTBUS_ADDR <= mem_r_contents + ry;
                   OUTBUS_DATA <= rx[7:0];
                   OUTBUS_WE <= 1;
                   state <= state_decode_single;
                end
                6'b111010 : begin // ba thru bge
                   case (opcode[2:0])
                     3'b000 : begin // ba : always
                        pc <= pc + 2 + mem_r_contents;
                        mem_r_addr <= pc + 2 + mem_r_contents;
                     end
                     3'b001 : begin // beq : equal
                        if (flag_z) begin
                           pc <= pc + 2 + mem_r_contents;
                           mem_r_addr <= pc + 2 + mem_r_contents;
                        end
                     end
                     3'b010 : begin // bne : not equal
                        if (!flag_z) begin
                           pc <= pc + 2 + mem_r_contents;
                           mem_r_addr <= pc + 2 + mem_r_contents;
                        end
                     end
                     3'b011 : begin // blt : less than
                        if (flag_c) begin
                           pc <= pc + 2 + mem_r_contents;
                           mem_r_addr <= pc + 2 + mem_r_contents;
                        end
                     end
                     3'b100 : begin // bgt : greator than
                        if (!flag_z && !flag_c) begin
                           pc <= pc + 2 + mem_r_contents;
                           mem_r_addr <= pc + 2 + mem_r_contents;
                        end
                     end
                     3'b101 : begin // ble : less than or equal
                        if (flag_z || flag_c) begin
                           pc <= pc + 2 + mem_r_contents;
                           mem_r_addr <= pc + 2 + mem_r_contents;
                        end
                     end
                     3'b110 : begin // bge : greator than or equal
                        if (!flag_z) begin
                           pc <= pc + 2 + mem_r_contents;
                           mem_r_addr <= pc + 2 + mem_r_contents;
                        end
                     end
                   endcase // case (opcode[2:0])
                   state <= state_decode_single;
                end
                6'b111110 : begin // jmp
                   pc <= mem_r_contents;
                   mem_r_addr <= mem_r_contents;
                   state <= state_decode_single;
                end
                6'b111111 : begin // jmpl
                   regs[reg_x] <= pc + 2;
                   pc <= mem_r_contents;
                   mem_r_addr <= mem_r_contents;
                   state <= state_decode_single;
                end
              endcase // case (op)
           end // case: state_decode_double

           state_in1 : begin
              // need to wait 2 clocks for the response to an IN
              mem_r_addr <= pc;
              state <= state_decode_single;
              INBUS_RE <= 0;
              in_pending <= 1;
           end

           state_load : begin
              regs[reg_x] <= mem_r_contents;
              flag_c <= 0;
              mem_r_addr <= pc;
              state <= state_decode_single;
           end

           state_loadb : begin
              if (mem_r_addr[0] == 1'b0) begin
                 regs[reg_x] <= { 8'b0, mem_r_contents[15:8] };
              end else begin
                 regs[reg_x] <= { 8'b0, mem_r_contents[7:0] };
              end
              flag_c <= 0;
              mem_r_addr <= pc;
              state <= state_decode_single;
           end

           state_storeb : begin
              mem_w_enable <= 1;
              if (mem_w_addr[0] == 1'b0) begin
                 mem_w_contents <= { rx[7:0], mem_r_contents[7:0] };
              end else begin
                 mem_w_contents <= { mem_r_contents[15:8], rx[7:0] };
              end
              mem_r_addr <= pc;
              state <= state_decode_single;
           end

         endcase // case (state)
      end // else: !if(RESET)
   end // always @ (posedge CLK)

endmodule
