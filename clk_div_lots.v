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
module clk_div_lots
  #( parameter counterbits = 8,
     parameter wholeway = 26214 )
  ( reset, clk, clk_out);

   input       reset;
   input       clk;
   output reg  clk_out;
   reg [counterbits-1:0]  cnt;

   always @(posedge clk or posedge reset)begin
      if (reset) begin
         clk_out <= 0;
         cnt <= 0;
      end else begin
         if (cnt >= (wholeway-1)) begin
            cnt <= 0;
            clk_out <= 0;
         end else if (cnt == (wholeway-2)) begin
            cnt <= cnt + 1;
            clk_out <= 1;
         end else begin
            cnt <= cnt + 1;
         end
      end
   end

endmodule
