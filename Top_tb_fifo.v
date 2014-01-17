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
module Top_tb_fifo;

   reg         reset;
   reg         clk_in;
   reg [7:0]   in_data;
   reg         in_enable;
   wire        in_full;

   reg         clk_out;
   reg         out_enable;
   wire        out_empty;
   wire [7:0]  out_data;

   fifo
     #( .DATA_WIDTH(8),
        .FIFO_POWER(4) )
   FIFO1
     ( .reset(reset),
       .clk_in(clk_in),
       .data_in(in_data),
       .enable_in(in_enable),
       .full_in(in_full),
       .clk_out(clk_out),
       .data_out(out_data),
       .enable_out(out_enable),
       .empty_out(out_empty) );

   initial begin
      reset = 1;
      clk_in = 0;
      clk_out = 0;
      in_data = 8'h35;
      in_enable = 0;
      out_enable = 0;
      #50 reset = 0;
   end

   always begin
      #9 clk_in = ~clk_in;
   end

   always begin
      #10 clk_out = ~clk_out;
   end

   reg [2:0] in_state;
   parameter [2:0]
     waitfor_notfull = 3'b000,
     enable_setto1   = 3'b001;

   always @(posedge clk_in) begin
      if (reset) begin
         in_state <= waitfor_notfull;
      end else begin
         (* FULL_CASE, PARALLEL_CASE *)
         case (in_state)
           waitfor_notfull : begin
              if (in_full == 0) begin
                 in_state <= enable_setto1;
                 in_enable <= 1;
              end
           end
           enable_setto1 : begin
              in_data <= in_data + 1;
              if (in_full == 1) begin
                 in_enable <= 0;
                 in_state <= waitfor_notfull;
              end
           end
         endcase
      end
   end

   reg [7:0] out_data_retrieved;
   reg [2:0] out_state;
   reg       verify_failed;
   parameter [2:0]
     waitfor_notempty = 3'b000,
     renable_setto1   = 3'b001;

   wire [7:0] out_data_retrplusone = out_data_retrieved + 8'd1;

   always @(posedge clk_out) begin
      if (reset) begin
         out_state <= waitfor_notempty;
         out_data_retrieved <= 8'h34;
         verify_failed <= 0;
      end else begin
         (* FULL_CASE, PARALLEL_CASE *)
         case (out_state)
           waitfor_notempty : begin
              if (out_empty == 0) begin
                 out_state <= renable_setto1;
                 out_enable <= 1;
              end
           end
           renable_setto1 : begin
              out_data_retrieved <= out_data;
              if (out_data != out_data_retrplusone) begin
                 verify_failed <= 1;
              end
              if (out_empty == 1) begin
                 out_state <= waitfor_notempty;
                 out_enable <= 0;
              end
           end
         endcase
      end
   end

endmodule
