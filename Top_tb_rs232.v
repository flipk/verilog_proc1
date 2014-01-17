`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:41:43 06/09/2012 
// Design Name: 
// Module Name:    Top_tb 
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
module Top_tb_rs232;

   reg reset;
   initial begin
      rs232clk = 0;
      reset = 1;
      #40 reset = 0;
   end

   reg rs232clk;
   always begin
      #10 rs232clk = ~rs232clk;
   end;

   reg cpuclk;
   initial begin
      cpuclk = 1;
   end
   always begin
      #5 cpuclk = ~cpuclk;
   end

   wire rs232clk_tx_en;
   wire rs232clk_rx_en;

   clk_div_lots
     #( .counterbits(5),  .wholeway(16) )
   clk_div_tx
     ( .clk(rs232clk),
       .reset(reset),
       .clk_out(rs232clk_tx_en) );

   clk_div_lots
     #( .counterbits(3), .wholeway(2) )
   clk_div_rx
     ( .clk(rs232clk),
       .reset(reset),
       .clk_out(rs232clk_rx_en) );

   wire rs232data;
   reg [7:0]  outbus_addr;
   reg [7:0]  outbus_data;
   reg        outbus_we;
   reg [7:0]  inbus_addr;
   wire [7:0] inbus_data;
   reg        inbus_re;

   rs232port
     #( .DEVADDR(0) )
   rs232_port_1 
     ( .reset(reset),
       .reset_complete(),
       .rs232_clk(rs232clk),
       .rs232_rx_clk_en(rs232clk_rx_en),
       .rs232_tx_clk_en(rs232clk_tx_en),
       .rx_pin(rs232data),
       .tx_pin(rs232data),
       .cpu_clk(cpuclk),
       .outbus_addr(outbus_addr),
       .outbus_data(outbus_data),
       .outbus_we(outbus_we),
       .inbus_addr(inbus_addr),
       .inbus_data(inbus_data),
       .inbus_re(inbus_re) );

   initial begin
      outbus_addr = 0;
      outbus_data = 0;
      outbus_we = 0;
      inbus_addr = 0;
      inbus_re = 0;

      #200 outbus_addr = 0; // write data port
      outbus_data = 8'h53;
      outbus_we = 1;
      #10 outbus_we = 0;

      #40 outbus_addr = 0; // write data port
      outbus_data = 8'h0d;
      outbus_we = 1;
      #10 outbus_we = 0;
   end

   always begin
      #10 inbus_addr = 1;
      inbus_re = 1;
      #10 inbus_re = 0;
      #10 inbus_addr = 3;
      inbus_re = 1;
      #10 if (inbus_data & 1) begin
         inbus_re = 0;
         #10 inbus_addr = 2;
         inbus_re = 1;
         #10 inbus_re = 0;
      end else begin
         inbus_re = 0;
      end
   end

endmodule
