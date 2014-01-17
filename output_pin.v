`timescale 1ns / 1ps

module outputPin
  #( parameter PIN_WIDTH = 1,
     parameter DEVADDR = 0 )
   ( clk, reset, OUTBUS_ADDR, OUTBUS_DATA, OUTBUS_WE, OUTPUT_PIN );

   input                      clk;
   input                      reset;
   input [7:0]                OUTBUS_ADDR;
   input [PIN_WIDTH-1:0]      OUTBUS_DATA;
   input                      OUTBUS_WE;
   output reg [PIN_WIDTH-1:0] OUTPUT_PIN;

   always @(posedge clk) begin
      if (reset) begin
         OUTPUT_PIN <= 0;
      end else begin
         if (OUTBUS_WE) begin
            if (OUTBUS_ADDR == DEVADDR) begin
               OUTPUT_PIN <= OUTBUS_DATA[PIN_WIDTH-1:0];
            end
         end
      end
   end

endmodule
