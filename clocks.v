`timescale 1ns / 1ps

module clock_generator
  ( CLKIN_IN, RST_IN, CLKIN_IBUFG_OUT,
    CLKPROC1, PROC1_LOCKED_OUT,
    CLKRS232, RS232_LOCKED_OUT,
    CLKRS232_TX_EN, CLKRS232_RX_EN );

   input  CLKIN_IN;
   input  RST_IN;
   output CLKIN_IBUFG_OUT;
   output CLKPROC1;
   output PROC1_LOCKED_OUT;
   output CLKRS232;
   output RS232_LOCKED_OUT;
   output CLKRS232_TX_EN;
   output CLKRS232_RX_EN;
   wire   CLKFX_PROC1_BUF;
   wire   ZERO_BIT;
   assign ZERO_BIT = 0;

   assign CLKIN_IBUFG_OUT = CLKIN_IN;

   // 32,000,000 * 12 / 16 =  24,000,000 for processor clock
   // 32,000,000 * 25 / 16 =  50,000,000 for processor clock
   // 32,000,000 *  8 /  4 =  64,000,000 for processor clock
   // 32,000,000 * 25 / 12 =  66,600,000 for processor clock
   // 32,000,000 *  5 /  2 =  80,000,000 for processor clock
   // 32,000,000 * 25 /  8 = 100,000,000 for processor clock

   DCM_SP
     #( .CLK_FEEDBACK("NONE"),
        .CLKDV_DIVIDE(2.0),
        .CLKFX_DIVIDE(16), 
        .CLKFX_MULTIPLY(12),
        .CLKIN_DIVIDE_BY_2("FALSE"), 
        .CLKIN_PERIOD(31.250), //   (1 / 32 * 1000)
        .CLKOUT_PHASE_SHIFT("NONE"), 
        .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
        .DFS_FREQUENCY_MODE("LOW"), 
        .DLL_FREQUENCY_MODE("LOW"),
        .DUTY_CYCLE_CORRECTION("TRUE"), 
        .FACTORY_JF(16'hC080),
        .PHASE_SHIFT(0),
        .STARTUP_WAIT("FALSE") ) 
   DCM_PROC1
     ( .CLKFB(ZERO_BIT),
       .CLKIN(CLKIN_IN),
       .DSSEN(ZERO_BIT), 
       .PSCLK(ZERO_BIT), 
       .PSEN(ZERO_BIT), 
       .PSINCDEC(ZERO_BIT), 
       .RST(RST_IN), 
       .CLKDV(), 
       .CLKFX(CLKFX_PROC1_BUF), 
       .CLKFX180(), 
       .CLK0(), 
       .CLK2X(), 
       .CLK2X180(), 
       .CLK90(), 
       .CLK180(), 
       .CLK270(), 
       .LOCKED(PROC1_LOCKED_OUT), 
       .PSDONE(), 
       .STATUS());

   BUFGCE  CLKFX_PROC1_BUFG_INST
     ( .I(CLKFX_PROC1_BUF), 
       .O(CLKPROC1),
       .CE(PROC1_LOCKED_OUT) );

   // 32,000,000 * 9 / 13 = 22,153,846
   // if you divide that by 24, you get 923076
   // which is 0.15% off from an 8x115200=921600 baud clock for rs232.

   // 32,000,000 * 7 / 27 = 8,296,296
   // if you divide that by 9, you get 921810
   // which is 0.02% off from an 8x115200=921600 baud clock for rs232.

   wire   CLKFX_RS232_DCM;

   DCM_SP
     #( .CLK_FEEDBACK("NONE"),
        .CLKDV_DIVIDE(2.0),
        .CLKFX_DIVIDE(27), 
        .CLKFX_MULTIPLY(7),
        .CLKIN_DIVIDE_BY_2("FALSE"), 
        .CLKIN_PERIOD(31.250),
        .CLKOUT_PHASE_SHIFT("NONE"), 
        .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
        .DFS_FREQUENCY_MODE("LOW"), 
        .DLL_FREQUENCY_MODE("LOW"),
        .DUTY_CYCLE_CORRECTION("TRUE"), 
        .FACTORY_JF(16'hC080),
        .PHASE_SHIFT(0),
        .STARTUP_WAIT("FALSE") ) 
   DCM_RS232
     ( .CLKFB(ZERO_BIT), 
       .CLKIN(CLKIN_IN),
       .DSSEN(ZERO_BIT), 
       .PSCLK(ZERO_BIT), 
       .PSEN(ZERO_BIT), 
       .PSINCDEC(ZERO_BIT), 
       .RST(RST_IN), 
       .CLKDV(), 
       .CLKFX(CLKFX_RS232_DCM),
       .CLKFX180(), 
       .CLK0(), 
       .CLK2X(), 
       .CLK2X180(), 
       .CLK90(), 
       .CLK180(), 
       .CLK270(), 
       .LOCKED(RS232_LOCKED_OUT), 
       .PSDONE(), 
       .STATUS());

   BUFGCE  CLKFX_RS232_BUFG_INST
     ( .I(CLKFX_RS232_DCM), 
       .O(CLKRS232),
       .CE(RS232_LOCKED_OUT) );

   clk_div_lots
     #( .counterbits (7), .wholeway (72) )  // 1x clock
   clk_div_rs232_tx
     ( .clk       (CLKRS232),
       .reset     (~RS232_LOCKED_OUT),
       .clk_out   (CLKRS232_TX_EN) );

   clk_div_lots
     #( .counterbits (4), .wholeway (9) ) // 8x clock
   clk_div_rs232_rx
     ( .clk       (CLKRS232),
       .reset     (~RS232_LOCKED_OUT),
       .clk_out   (CLKRS232_RX_EN) );

endmodule
