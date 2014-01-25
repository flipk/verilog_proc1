`timescale 1ns / 1ps

module Top
  ( input  CLKIN,
    input  RX,
    output TX,
    output [7:0] pin_oW1A
    );

   wire          CLKIN_IBUF;
   wire          CLKPROC1;
   wire          CLKRS232;
   wire          CLKRS232_TX_EN;
   wire          CLKRS232_RX_EN;
   wire          RESET_CLK_GENERATOR;
   wire          RESET_RS232;
   wire          RESET_RS232_COMPLETE;
   wire          RESET_PROC1;    
   wire          LOCKED_PROC1;
   wire          LOCKED_RS232;

   clock_generator  clk1
     ( .CLKIN_IN            (CLKIN),
       .RST_IN              (RESET_CLK_GENERATOR),
       .CLKIN_IBUFG_OUT     (CLKIN_IBUF),
       .CLKPROC1            (CLKPROC1),
       .PROC1_LOCKED_OUT    (LOCKED_PROC1),
       .CLKRS232            (CLKRS232),
       .CLKRS232_RX_EN      (CLKRS232_RX_EN),
       .CLKRS232_TX_EN      (CLKRS232_TX_EN),
       .RS232_LOCKED_OUT    (LOCKED_RS232));

   parameter CYCLE_COUNTER_DEVADDR = 8'h30;
   parameter PROCVER_DEVADDR = 8'h00;
   parameter RS232_PORT0_DEVADDR = 8'h20;
   parameter DROPBOX_DEVADDR = 8'h28;
   parameter OUTPUT_PIN_W1A0_DEVADDR = 8'h56;

   wire [7:0]    OUTBUS_ADDR;
   wire [7:0]    OUTBUS_DATA;
   wire          OUTBUS_WE;
   wire [7:0]    INBUS_ADDR;
   wire [7:0]    INBUS_DATA_proc;
   wire [7:0]    INBUS_DATA_rs232;
   wire [7:0]    INBUS_DATA_cycle;
   wire [7:0]    INBUS_DATA_procver;
   wire [7:0]    INBUS_DATA_dropbox;
   wire          INBUS_RE;

   assign INBUS_DATA_proc
     = INBUS_DATA_rs232 | INBUS_DATA_cycle |
       INBUS_DATA_procver | INBUS_DATA_dropbox;

   resetCtrl resetControl
     ( .clk                  (CLKIN_IBUF),
       .reset_clkgen         (RESET_CLK_GENERATOR),
       .locked_proc1         (LOCKED_PROC1),
       .locked_rs232         (LOCKED_RS232),
       .reset_rs232_complete (RESET_RS232_COMPLETE),
       .reset_rs232          (RESET_RS232),
       .reset_proc1          (RESET_PROC1) );

   processorTop
     #( .MEMORY_SIZE(8192),
        .MEMORY_FILE("bootloader.hex") )
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
       .INBUS_ADDR          (INBUS_ADDR),
       .INBUS_DATA          (INBUS_DATA_procver),
       .INBUS_RE            (INBUS_RE) );

   rs232port
     #( .DEVADDR (RS232_PORT0_DEVADDR) )
   rs232_port0
     ( .cpu_clk              (CLKPROC1),
       .reset                (RESET_RS232),
       .rs232_clk            (CLKRS232),
       .rs232_tx_clk_en      (CLKRS232_TX_EN),
       .rs232_rx_clk_en      (CLKRS232_RX_EN),
       .reset_complete       (RESET_RS232_COMPLETE),
       .rx_pin               (RX),
       .tx_pin               (TX),
       .outbus_addr          (OUTBUS_ADDR),
       .outbus_data          (OUTBUS_DATA),
       .outbus_we            (OUTBUS_WE),
       .inbus_addr           (INBUS_ADDR),
       .inbus_data           (INBUS_DATA_rs232),
       .inbus_re             (INBUS_RE) );

   wire [7:0] sevensegvalue;

   sevensegment seg7
     ( .clk(CLKPROC1),
       .blank(sevensegvalue[4]),
       .value(sevensegvalue[3:0]),
       .segments({pin_oW1A[7:5],pin_oW1A[3:0]}) );

   assign pin_oW1A[4] = 0;

   outputPin
     #( .PIN_WIDTH(5), 
        .DEVADDR(OUTPUT_PIN_W1A0_DEVADDR) )
   pinW1A0
     ( .clk(CLKPROC1),
       .reset(RESET_PROC1),
       .OUTBUS_ADDR(OUTBUS_ADDR),
       .OUTBUS_DATA(OUTBUS_DATA),
       .OUTBUS_WE(OUTBUS_WE),
       .OUTPUT_PIN(sevensegvalue) );

`ifdef SECOND_PROC

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
        .MEMORY_FILE("bootloader.hex") )
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
       .INBUS_ADDR          (INBUS_ADDR2),
       .INBUS_DATA          (INBUS_DATA_procver2),
       .INBUS_RE            (INBUS_RE2) );
`endif //  `if 0

endmodule
