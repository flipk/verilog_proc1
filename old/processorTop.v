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
  ( input         CLK,
    input         RESET,
    output [15:0] MEMORY_ADDRESS,
    output        MEMORY_WRITE_ENABLE,
    output [15:0] MEMORY_WRITE_DATA,
    input [15:0]  MEMORY_READ_DATA,
    output [7:0]  OUTBUS_ADDR,
    output [7:0]  OUTBUS_DATA,
    output        OUTBUS_WE,
    output [7:0]  INBUS_ADDR,
    input [7:0]   INBUS_DATA,
    output        INBUS_RE
    );

   wire [15:0]    ADDR1;
   wire [15:0]    READDAT1;
   wire           REQUEST1;
   wire           DONE1;
   wire [15:0]    ADDR2;
   wire [15:0]    WRITEDAT2;
   wire [1:0]     REQUEST2; // byte lanes
   wire           DONE2;
   wire [15:0]    ADDR3;
   wire [15:0]    READDAT3;
   wire           REQUEST3;
   wire           DONE3;
   
   memController memctrl
     ( .clk                 (CLK),
       .reset               (RESET), 
       .addr1               (ADDR1), 
       .readdat1            (READDAT1),  
       .request1            (REQUEST1),
       .done1               (DONE1),
       .addr2               (ADDR2),
       .writedat2           (WRITEDAT2),
       .request2            (REQUEST2),
       .done2               (DONE2),
       .addr3               (ADDR3), 
       .readdat3            (READDAT3),  
       .request3            (REQUEST3),
       .done3               (DONE3),
       .memory_address      (MEMORY_ADDRESS),
       .memory_write_enable (MEMORY_WRITE_ENABLE),
       .memory_write_data   (MEMORY_WRITE_DATA),
       .memory_read_data    (MEMORY_READ_DATA) );

   wire [15:0]    INSTRUCTION;
   wire           INSTRUCTION_READY;
   wire [15:0]    OPERANDBUS;
   wire [1:0]     FLAGS;
   wire [15:0]    REGBUS1;
   wire [15:0]    REGBUS2;
   wire [1:0]     FLAGSBUS;
   wire           BRR;

   wire [15:0]    REGBUS3_regfile;
   wire [15:0]    REGBUS3_decoder;
   wire [15:0]    REGBUS3_ldrir;
   wire [15:0]    REGBUS3_inrir;
   wire [15:0]    REGBUS3_fetcher;

   assign REGBUS3_regfile
     = REGBUS3_decoder | REGBUS3_ldrir
       | REGBUS3_inrir | REGBUS3_fetcher;

   wire           R3WRITEENABLE_regfile;
   wire           R3WRITEENABLE_decoder;
   wire           R3WRITEENABLE_ldrir;
   wire           R3WRITEENABLE_inrir;
   wire           R3WRITEENABLE_fetcher;

   assign R3WRITEENABLE_regfile
     = R3WRITEENABLE_decoder | R3WRITEENABLE_ldrir
       | R3WRITEENABLE_inrir | R3WRITEENABLE_fetcher;

   wire           EXECUTE_BUSY_fetcher;
   wire           EXECUTE_BUSY_ldrir;

   assign EXECUTE_BUSY_fetcher = EXECUTE_BUSY_ldrir;

   instructionFetcher fetcher
     ( .clk              (CLK),
       .reset            (RESET),
       .memoryAddress    (ADDR1),
       .memoryReadData   (READDAT1),
       .memoryRequest    (REQUEST1),
       .memoryDone       (DONE1),
       .executeBusy      (EXECUTE_BUSY_fetcher),
       .instruction      (INSTRUCTION),
       .instructionReady (INSTRUCTION_READY),
       .operand          (OPERANDBUS),
       .flags            (FLAGS),
       .reg1bus          (REGBUS1),
       .r3we             (R3WRITEENABLE_fetcher),
       .reg3bus          (REGBUS3_fetcher),
       .brr              (BRR) );

   wire           LDRIR;
   wire           LDRIRB;
   wire           STRIR;
   wire           STRIRB;
   wire           OUTRIR;
   wire           INRIR;
   wire           FLAGSWRITEENABLE;
   
   instructionDecoder decoder
     ( .clk                (CLK),
       .instruction        (INSTRUCTION),
       .instruction_ready  (INSTRUCTION_READY),
       .brr                (BRR),
       .ldrir              (LDRIR),
       .ldrirb             (LDRIRB),
       .strir              (STRIR),
       .strirb             (STRIRB),
       .outrir             (OUTRIR),
       .inrir              (INRIR),
       .operand            (OPERANDBUS),
       .regbus1            (REGBUS1),
       .regbus2            (REGBUS2),
       .r3we               (R3WRITEENABLE_decoder),
       .regbus3            (REGBUS3_decoder),
       .flagswriteenable   (FLAGSWRITEENABLE),
       .flagsbus           (FLAGSBUS) );

   registerFile registers
     ( .clk                (CLK),
       .reset              (RESET),
       .instruction        (INSTRUCTION),
       .regbus3writeenable (R3WRITEENABLE_regfile),
       .regbus1            (REGBUS1),
       .regbus2            (REGBUS2),
       .regbus3            (REGBUS3_regfile),
       .flagswriteenable   (FLAGSWRITEENABLE),
       .flagsbus           (FLAGSBUS),
       .flags              (FLAGS) );
   
   instr_ldrir inst_ldrir
     ( .clk             (CLK),
       .reset           (RESET),
       .ldrir           (LDRIR),
       .ldrirb          (LDRIRB),
       .executeBusy     (EXECUTE_BUSY_ldrir),
       .operand         (OPERANDBUS),
       .regbus2         (REGBUS2),
       .r3we            (R3WRITEENABLE_ldrir),
       .regbus3         (REGBUS3_ldrir),
       .memory_address  (ADDR3),
       .memory_data     (READDAT3),
       .memory_request  (REQUEST3),
       .memory_done     (DONE3) );

   instr_strir inst_strir
     ( .clk            (CLK),
       .reset          (RESET),
       .strir          (STRIR),
       .strirb         (STRIRB),
       .operand        (OPERANDBUS),
       .regbus1        (REGBUS1),
       .regbus2        (REGBUS2),
       .memory_address (ADDR2),
       .memory_data    (WRITEDAT2),
       .memory_request (REQUEST2),
       .memory_done    (DONE2) );

   instr_outrir inst_outrir
     ( .clk            (CLK),
       .reset          (RESET),
       .outrir         (OUTRIR),
       .operand        (OPERANDBUS),
       .regbus1        (REGBUS1),
       .regbus2        (REGBUS2),
       .outbus_addr    (OUTBUS_ADDR),
       .outbus_data    (OUTBUS_DATA),
       .outbus_we      (OUTBUS_WE) );

   instr_inrir inst_inrir
     ( .clk            (CLK),
       .reset          (RESET),
       .inrir          (INRIR),
       .operand        (OPERANDBUS),
       .regbus2        (REGBUS2),
       .r3we           (R3WRITEENABLE_inrir),
       .regbus3        (REGBUS3_inrir),
       .inbus_addr     (INBUS_ADDR),
       .inbus_data     (INBUS_DATA),
       .inbus_re       (INBUS_RE) );

endmodule
