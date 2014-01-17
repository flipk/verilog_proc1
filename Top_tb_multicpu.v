`timescale 1ns / 1ps

module Top_multicpu_tb;
   
   reg         CLKPROC1;
   wire [7:0]  PIN56;
   wire        TX;
   wire        RX;

   wire        RESET_CLKGEN;
   wire        RESET_PROC1;
   wire        RESET_RS232;

   parameter CYCLE_COUNTER_DEVADDR = 8'h30;
   parameter PROCVER_DEVADDR = 8'h00;
   parameter RS232_PORT0_DEVADDR = 8'h20;
   parameter DROPBOX_DEVADDR = 8'h28;

   wire [7:0]  OUTBUS_ADDR;
   wire [7:0]  OUTBUS_DATA;
   wire        OUTBUS_WE;
   wire [7:0]  INBUS_ADDR;
   wire [7:0]  INBUS_DATA_proc;
   wire [7:0]  INBUS_DATA_rs232;
   wire [7:0]  INBUS_DATA_cycle;
   wire [7:0]  INBUS_DATA_procver;
   wire [7:0]  INBUS_DATA_dropbox;
   wire        INBUS_RE;
   
   assign INBUS_DATA_proc
     = INBUS_DATA_rs232 | INBUS_DATA_cycle |
       INBUS_DATA_procver | INBUS_DATA_dropbox;

   resetCtrl  resetControl
     ( .clk                  (CLKPROC1),
       .reset_clkgen         (RESET_CLKGEN),
       .locked_proc1         (1'b1),
       .locked_rs232         (1'b1),
       .reset_rs232_complete (RESET_RS232_COMPLETE),
       .reset_rs232          (RESET_RS232),
       .reset_proc1          (RESET_PROC1) );

   processorTop
     #( .MEMORY_SIZE(8192),
//        .MEMORY_FILE("bootloader.hex")
        .MEMORY_FILE("dropbox-test.hex")
        )
   proc1
     ( .CLK                 (CLKPROC1),
       .RESET               (RESET_PROC1),
       .OUTBUS_ADDR         (OUTBUS_ADDR),
       .OUTBUS_DATA         (OUTBUS_DATA),
       .OUTBUS_WE           (OUTBUS_WE),
       .INBUS_ADDR          (INBUS_ADDR),
       .INBUS_DATA          (INBUS_DATA_proc),
       .INBUS_RE            (INBUS_RE) );

   cycleCounter
     #( .DEVADDR(CYCLE_COUNTER_DEVADDR) )
   cycleCounter
     ( .clk                 (CLKPROC1),
       .reset               (RESET_PROC1),
       .OUTBUS_ADDR         (OUTBUS_ADDR),
       .OUTBUS_DATA         (OUTBUS_DATA),
       .OUTBUS_WE           (OUTBUS_WE),
       .INBUS_ADDR          (INBUS_ADDR),
       .INBUS_DATA          (INBUS_DATA_cycle),
       .INBUS_RE            (INBUS_RE) );

   processorVersion
     #( .DEVADDR( PROCVER_DEVADDR ),
        .VERSION( 8'h02 ),
        .CPUID  ( 8'h01 ) )
   proc1ver
     ( .clk                 (CLKPROC1),
       .reset               (RESET_PROC1),
       .OUTBUS_ADDR         (OUTBUS_ADDR),
       .OUTBUS_DATA         (OUTBUS_DATA),
       .OUTBUS_WE           (OUTBUS_WE),
       .INBUS_ADDR          (INBUS_ADDR),
       .INBUS_DATA          (INBUS_DATA_procver),
       .INBUS_RE            (INBUS_RE) );

   //   outputPin
   //     #( .PIN_WIDTH   (8),
   //        .PIN_ADDRESS (8'h56) )
   //   pin56
   //     ( .clk         (CLKPROC1),
   //       .reset       (RESET_PROC1),
   //       .OUTBUS_ADDR (OUTBUS_ADDR),
   //       .OUTBUS_DATA (OUTBUS_DATA),
   //       .OUTBUS_WE   (OUTBUS_WE),
   //       .OUTPUT_PIN  (PIN56) );

   wire        CLKRS232_TX_EN;
   wire        CLKRS232_RX_EN;

   clk_div_lots
     #( .counterbits (5), .wholeway (16) )
   clk_div_rs232_tx
     ( .clk       (CLKPROC1),
       .reset     (RESET_CLKGEN),
       .clk_out   (CLKRS232_TX_EN) );

   clk_div_lots
     #( .counterbits (3), .wholeway (2) )
   clk_div_rs232_rx
     ( .clk       (CLKPROC1),
       .reset     (RESET_CLKGEN),
       .clk_out   (CLKRS232_RX_EN) );

   rs232port
     #( .DEVADDR (RS232_PORT0_DEVADDR) )
   rs232_port0
     (  .cpu_clk          (CLKPROC1),
        .reset            (RESET_RS232),
        .rs232_clk        (CLKPROC1),
        .rs232_tx_clk_en  (CLKRS232_TX_EN),
        .rs232_rx_clk_en  (CLKRS232_RX_EN),
        .reset_complete   (RESET_RS232_COMPLETE),
        .rx_pin           (RX),
        .tx_pin           (TX),
        .outbus_addr      (OUTBUS_ADDR),
        .outbus_data      (OUTBUS_DATA),
        .outbus_we        (OUTBUS_WE),
        .inbus_addr       (INBUS_ADDR),
        .inbus_data       (INBUS_DATA_rs232),
        .inbus_re         (INBUS_RE) );

   assign RX = TX;

   wire [7:0]  OUTBUS_ADDR2;
   wire [7:0]  OUTBUS_DATA2;
   wire        OUTBUS_WE2;
   wire [7:0]  INBUS_ADDR2;
   wire [7:0]  INBUS_DATA_proc2;
   wire [7:0]  INBUS_DATA_cycle2;
   wire [7:0]  INBUS_DATA_procver2;
   wire [7:0]  INBUS_DATA_dropbox2;
   wire        INBUS_RE2;
 
   assign INBUS_DATA_proc2
     = INBUS_DATA_cycle2 | INBUS_DATA_procver2 | INBUS_DATA_dropbox2;

   dropbox_channel
     #( .DEVADDR1(DROPBOX_DEVADDR+0),
        .DEVADDR2(DROPBOX_DEVADDR+0) )
   dropbox1
     ( .clk(CLKPROC1),
       .reset(RESET_PROC1),
       .OUTBUS_ADDR1(OUTBUS_ADDR),
       .OUTBUS_DATA1(OUTBUS_DATA),
       .OUTBUS_WE1(OUTBUS_WE),
       .INBUS_ADDR1(INBUS_ADDR),
       .INBUS_DATA1(INBUS_DATA_dropbox),
       .INBUS_RE1(INBUS_RE),
       .OUTBUS_ADDR2(OUTBUS_ADDR2),
       .OUTBUS_DATA2(OUTBUS_DATA2),
       .OUTBUS_WE2(OUTBUS_WE2),
       .INBUS_ADDR2(INBUS_ADDR2),
       .INBUS_DATA2(INBUS_DATA_dropbox2),
       .INBUS_RE2(INBUS_RE2)
      );

   processorTop
     #( .MEMORY_SIZE(8192),
//        .MEMORY_FILE("bootloader.hex")
        .MEMORY_FILE("dropbox-test.hex")
        )
   proc2
     ( .CLK                 (CLKPROC1),
       .RESET               (RESET_PROC1),
       .OUTBUS_ADDR         (OUTBUS_ADDR2),
       .OUTBUS_DATA         (OUTBUS_DATA2),
       .OUTBUS_WE           (OUTBUS_WE2),
       .INBUS_ADDR          (INBUS_ADDR2),
       .INBUS_DATA          (INBUS_DATA_proc2),
       .INBUS_RE            (INBUS_RE2) );

   cycleCounter
     #( .DEVADDR(CYCLE_COUNTER_DEVADDR) )
   cycleCounter2
     ( .clk                 (CLKPROC1),
       .reset               (RESET_PROC1),
       .OUTBUS_ADDR         (OUTBUS_ADDR2),
       .OUTBUS_DATA         (OUTBUS_DATA2),
       .OUTBUS_WE           (OUTBUS_WE2),
       .INBUS_ADDR          (INBUS_ADDR2),
       .INBUS_DATA          (INBUS_DATA_cycle2),
       .INBUS_RE            (INBUS_RE2) );

   processorVersion
     #( .DEVADDR( PROCVER_DEVADDR ),
        .VERSION( 8'h02 ),
        .CPUID  ( 8'h02 ) )
   proc2ver
     ( .clk                 (CLKPROC1),
       .reset               (RESET_PROC1),
       .OUTBUS_ADDR         (OUTBUS_ADDR2),
       .OUTBUS_DATA         (OUTBUS_DATA2),
       .OUTBUS_WE           (OUTBUS_WE2),
       .INBUS_ADDR          (INBUS_ADDR2),
       .INBUS_DATA          (INBUS_DATA_procver2),
       .INBUS_RE            (INBUS_RE2) );

   initial begin
      CLKPROC1 = 0;
   end

   always begin
      #10 CLKPROC1 = ~CLKPROC1;
   end
   
endmodule
