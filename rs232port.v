`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:        
//
// Create Date:    
// Design Name:    
// Module Name:    
// Project Name:   
// Target Device:  
// 
// Description: 
//
////////////////////////////////////////////////////////////////////////////////
module rs232port
  #( parameter DEVADDR = 8'h00 )
  ( reset, reset_complete,
    rs232_clk, rs232_rx_clk_en, rs232_tx_clk_en, 
    rx_pin, tx_pin,
    cpu_clk,
    outbus_addr, outbus_data, outbus_we,
    inbus_addr, inbus_data, inbus_re );

   parameter  write_data_port   = (DEVADDR + 0);
   parameter  write_status_port = (DEVADDR + 1);
   parameter  read_data_port    = (DEVADDR + 2);
   parameter  read_status_port  = (DEVADDR + 3);

   input             reset;
   output            reset_complete;
   input             rs232_clk;
   input             rs232_rx_clk_en;
   input             rs232_tx_clk_en;
   input             rx_pin;
   output reg        tx_pin;
   input             cpu_clk;
   input [7:0]       outbus_addr;
   input [7:0]       outbus_data;
   input             outbus_we;
   input [7:0]       inbus_addr;
   output reg [7:0]  inbus_data;
   input             inbus_re;

   reg [7:0]         tx_data_from_cpu;
   reg               tx_data_from_cpu_en;
   wire              tx_fifo_empty;
   wire              tx_fifo_full;
   wire [7:0]        tx_data_out;
   reg               tx_data_enable;

   reg               cpu_reset_complete = 0;
   reg               rx_reset_complete = 0;
   reg               tx_reset_complete = 0;

   assign reset_complete
     = (cpu_reset_complete & rx_reset_complete & tx_reset_complete);

   fifo
     #( .DATA_WIDTH(8),
        .FIFO_POWER(4) )
   tx_fifo
     ( .reset(reset),
       .clk_in(cpu_clk),
       .data_in(tx_data_from_cpu),
       .enable_in(tx_data_from_cpu_en),
       .full_in(tx_fifo_full),
       .clk_out(rs232_clk),
       .data_out(tx_data_out),
       .enable_out(tx_data_enable), 
       .empty_out(tx_fifo_empty) );

   wire [7:0]        rx_fifo_out;
   reg               rx_fifo_enable_out;
   wire              rx_fifo_empty;
   wire              rx_fifo_full;
   wire [7:0]        rx_data_in;
   reg               rx_enable_in;

   fifo
     #( .DATA_WIDTH(8),
        .FIFO_POWER(4) )
   rx_fifo
     ( .reset(reset),
       .clk_in(rs232_clk),
       .data_in(rx_data_in),
       .enable_in(rx_enable_in),
       .full_in(rx_fifo_full),
       .clk_out(cpu_clk),
       .data_out(rx_fifo_out),
       .enable_out(rx_fifo_enable_out),
       .empty_out(rx_fifo_empty) );

   // implement CPU interfacing.
   always @(posedge cpu_clk) begin
      if (reset) begin
         inbus_data <= 0;
         tx_data_from_cpu <= 0;
         tx_data_from_cpu_en <= 0;
         rx_fifo_enable_out <= 0;
         cpu_reset_complete <= 1;
      end else begin
         tx_data_from_cpu_en <= 0;
         if (outbus_we) begin
            if (outbus_addr == write_data_port) begin
               tx_data_from_cpu <= outbus_data;
               tx_data_from_cpu_en <= 1;
            end
         end
         inbus_data <= 0;
         rx_fifo_enable_out <= 0;
         if (inbus_re) begin
            case (inbus_addr)
              write_status_port : begin
                 inbus_data <= { 6'b0, tx_fifo_full, ~tx_fifo_empty };
              end
              read_data_port : begin
                 if (rx_fifo_empty) begin
                    inbus_data <= 8'hFF;
                 end else begin
                    inbus_data <= rx_fifo_out;
                    rx_fifo_enable_out <= 1;
                 end
              end
              read_status_port : begin
                 inbus_data <= { 6'b0, rx_fifo_full, ~rx_fifo_empty };
              end
            endcase // case (inbus_addr)
         end // if (inbus_re)
      end // else: !if(reset)
   end // always @ (posedge cpu_clk)

   parameter [10:0]
     tx_state_idle      = 11'b00000000001,
     tx_state_startbit  = 11'b00000000010,
     tx_state_bit7      = 11'b00000000100,
     tx_state_bit6      = 11'b00000001000,
     tx_state_bit5      = 11'b00000010000,
     tx_state_bit4      = 11'b00000100000,
     tx_state_bit3      = 11'b00001000000,
     tx_state_bit2      = 11'b00010000000,
     tx_state_bit1      = 11'b00100000000,
     tx_state_bit0      = 11'b01000000000,
     tx_state_stop      = 11'b10000000000;

   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="NO" *)
   reg [10:0]    tx_state = tx_state_idle;
   reg [7:0]     output_data;

   //implement transmitter.
   always @(posedge rs232_clk) begin
      if (reset) begin
         tx_state <= tx_state_idle;
         tx_pin <= 1;
         output_data <= 8'b0;
         tx_data_enable <= 0;
         tx_reset_complete <= 1;
      end else begin
         (* FULL_CASE, PARALLEL_CASE *)
         case (tx_state)
           tx_state_idle : begin
              if (tx_fifo_empty == 0 && rs232_tx_clk_en) begin
                 output_data <= tx_data_out;
                 tx_data_enable <= 1;
                 tx_pin <= 0; // start bit
                 tx_state <= tx_state_startbit;
              end else begin
                 tx_pin <= 1; // idle
                 tx_state <= tx_state_idle;
              end
           end // case: tx_state_idle
           tx_state_startbit : begin
              tx_data_enable <= 0;
              if (rs232_tx_clk_en) begin
                 tx_pin <= output_data[0];
                 tx_state <= tx_state_bit7;
              end
           end
           tx_state_bit7 : begin
              if (rs232_tx_clk_en) begin
                 tx_pin <= output_data[1];
                 tx_state <= tx_state_bit6;
              end
           end
           tx_state_bit6 : begin
              if (rs232_tx_clk_en) begin
                 tx_pin <= output_data[2];
                 tx_state <= tx_state_bit5;
              end
           end
           tx_state_bit5 : begin
              if (rs232_tx_clk_en) begin
                 tx_pin <= output_data[3];
                 tx_state <= tx_state_bit4;
              end
           end
           tx_state_bit4 : begin
              if (rs232_tx_clk_en) begin
                 tx_pin <= output_data[4];
                 tx_state <= tx_state_bit3;
              end
           end
           tx_state_bit3 : begin
              if (rs232_tx_clk_en) begin
                 tx_pin <= output_data[5];
                 tx_state <= tx_state_bit2;
              end
           end
           tx_state_bit2 : begin
              if (rs232_tx_clk_en) begin
                 tx_pin <= output_data[6];
                 tx_state <= tx_state_bit1;
              end
           end
           tx_state_bit1 : begin
              if (rs232_tx_clk_en) begin
                 tx_pin <= output_data[7];
                 tx_state <= tx_state_bit0;
              end
           end
           tx_state_bit0 : begin
              if (rs232_tx_clk_en) begin
                 tx_pin <= 1; // stop bit
                 tx_state <= tx_state_stop;
              end
           end
           tx_state_stop : begin
              if (rs232_tx_clk_en) begin
                 tx_state <= tx_state_idle;
              end
           end
         endcase // case (tx_state)
      end // else: !if(reset)
   end // always @ (posedge rs232_clk)



   parameter [9:0]
     rx_state_idle      = 10'b0000000001,
     rx_state_halfbit   = 10'b0000000010,
     rx_state_bit1      = 10'b0000000100,
     rx_state_bit2      = 10'b0000001000,
     rx_state_bit3      = 10'b0000010000,
     rx_state_bit4      = 10'b0000100000,
     rx_state_bit5      = 10'b0001000000,
     rx_state_bit6      = 10'b0010000000,
     rx_state_bit7      = 10'b0100000000,
     rx_state_stop      = 10'b1000000000;

   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="NO" *)
   reg [9:0]    rx_state = rx_state_idle;
   reg [3:0]    rx_count;
   reg [7:0]    input_data;

   assign rx_data_in = input_data;

   // implement receiver.
   always @(posedge rs232_clk) begin
      if (reset) begin
         rx_state <= rx_state_idle;
         input_data <= 0;
         rx_enable_in <= 0;
         rx_reset_complete <= 1;
      end else begin
         (* FULL_CASE, PARALLEL_CASE *)
         case (rx_state)
           rx_state_idle : begin
              rx_enable_in <= 0;
              if (rx_pin == 0 && rs232_rx_clk_en) begin
                 rx_count <= 0;
                 rx_state <= rx_state_halfbit;
              end else begin
                 rx_state <= rx_state_idle;
              end
           end // case: rx_state_idle
           rx_state_halfbit : begin
              if (rs232_rx_clk_en) begin
                 if (rx_count == 4'd11) begin
                    // we're in the middle of the first data bit now
                    input_data[0] <= rx_pin;
                    rx_count <= 0;
                    rx_state <= rx_state_bit1;
                 end else begin
                    rx_count <= rx_count + 1;
                    rx_state <= rx_state_halfbit;
                 end
              end
           end // case: rx_state_halfbit
           rx_state_bit1 : begin
              if (rs232_rx_clk_en) begin
                 if (rx_count == 4'd7) begin
                    input_data[1] <= rx_pin;
                    rx_count <= 0;
                    rx_state <= rx_state_bit2;
                 end else begin
                    rx_count <= rx_count + 1;
                    rx_state <= rx_state_bit1;
                 end
              end
           end // case: rx_state_bit1
           rx_state_bit2 : begin
              if (rs232_rx_clk_en) begin
                 if (rx_count == 4'd7) begin
                    input_data[2] <= rx_pin;
                    rx_count <= 0;
                    rx_state <= rx_state_bit3;
                 end else begin
                    rx_count <= rx_count + 1;
                    rx_state <= rx_state_bit2;
                 end
              end
           end // case: rx_state_bit2
           rx_state_bit3 : begin
              if (rs232_rx_clk_en) begin
                 if (rx_count == 4'd7) begin
                    input_data[3] <= rx_pin;
                    rx_count <= 0;
                    rx_state <= rx_state_bit4;
                 end else begin
                    rx_count <= rx_count + 1;
                    rx_state <= rx_state_bit3;
                 end
              end
           end // case: rx_state_bit3
           rx_state_bit4 : begin
              if (rs232_rx_clk_en) begin
                 if (rx_count == 4'd7) begin
                    input_data[4] <= rx_pin;
                    rx_count <= 0;
                    rx_state <= rx_state_bit5;
                 end else begin
                    rx_count <= rx_count + 1;
                    rx_state <= rx_state_bit4;
                 end
              end
           end // case: rx_state_bit4
           rx_state_bit5 : begin
              if (rs232_rx_clk_en) begin
                 if (rx_count == 4'd7) begin
                    input_data[5] <= rx_pin;
                    rx_count <= 0;
                    rx_state <= rx_state_bit6;
                 end else begin
                    rx_count <= rx_count + 1;
                    rx_state <= rx_state_bit5;
                 end
              end
           end // case: rx_state_bit5
           rx_state_bit6 : begin
              if (rs232_rx_clk_en) begin
                 if (rx_count == 4'd7) begin
                    input_data[6] <= rx_pin;
                    rx_count <= 0;
                    rx_state <= rx_state_bit7;
                 end else begin
                    rx_count <= rx_count + 1;
                    rx_state <= rx_state_bit6;
                 end
              end
           end // case: rx_state_bit6
           rx_state_bit7 : begin
              if (rs232_rx_clk_en) begin
                 if (rx_count == 4'd7) begin
                    input_data[7] <= rx_pin;
                    rx_count <= 0;
                    rx_state <= rx_state_stop;
                 end else begin
                    rx_count <= rx_count + 1;
                    rx_state <= rx_state_bit7;
                 end
              end
           end // case: rx_state_bit7
           rx_state_stop : begin
              if (rs232_rx_clk_en) begin
                 if (rx_count == 4'd7) begin
                    rx_count <= 0;
                    rx_enable_in <= 1;
                    rx_state <= rx_state_idle;
                 end else begin
                    rx_count <= rx_count + 1;
                    rx_state <= rx_state_stop;
                 end
              end
           end // case: rx_state_stop
         endcase // case (rx_state)
      end // else: !if(reset)
   end // always @ (posedge rs232_clk)

endmodule
