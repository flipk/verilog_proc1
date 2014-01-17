`timescale 1ns / 1ps

module inputPin
  #( parameter PIN_WIDTH = 1,
     parameter PIN_ADDRESS = 0 )
   ( clk, reset, INBUS_ADDR, INBUS_DATA, INBUS_RE, INPUT_PIN );

   input                      clk;
   input                      reset;
   input [7:0]                INBUS_ADDR;
   output reg [PIN_WIDTH-1:0] INBUS_DATA;
   input                      INBUS_WE;
   input [PIN_WIDTH-1:0]      INPUT_PIN;

   always @(posedge clk) begin
      INBUS_DATA <= 8'b0;
      if (INBUS_RE) begin
         if (INBUS_ADDR == PIN_ADDRESS) begin
            INBUS_DATA <= { 7'b0, INPUT_PIN };
         end
      end
   end

endmodule
