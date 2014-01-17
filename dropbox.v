`timescale 1ns / 1ps

module dropbox_channel
  #( parameter DEVADDR1 = 8'h00,
     parameter DEVADDR2 = 8'h00 )
   ( clk, reset,
    OUTBUS_ADDR1, OUTBUS_DATA1, OUTBUS_WE1,
    INBUS_ADDR1, INBUS_DATA1, INBUS_RE1,
    OUTBUS_ADDR2, OUTBUS_DATA2, OUTBUS_WE2,
    INBUS_ADDR2, INBUS_DATA2, INBUS_RE2 );

   input        clk;
   input        reset;
   input [7:0]  OUTBUS_ADDR1;
   input [7:0]  OUTBUS_DATA1;
   input        OUTBUS_WE1;
   input [7:0]  INBUS_ADDR1;
   output reg [7:0] INBUS_DATA1;
   input        INBUS_RE1;
   input [7:0]  OUTBUS_ADDR2;
   input [7:0]  OUTBUS_DATA2;
   input        OUTBUS_WE2;
   input [7:0]  INBUS_ADDR2;
   output reg [7:0] INBUS_DATA2;
   input        INBUS_RE2;

   reg [7:0]    one2two;
   reg [7:0]    two2one;   

   always @(posedge clk) begin
      if (reset) begin
         INBUS_DATA1 <= 0;
         INBUS_DATA2 <= 0;
         one2two <= 8'd0;
         two2one <= 8'd0;
      end else begin
         if (OUTBUS_WE1) begin
            case (OUTBUS_ADDR1)
              (DEVADDR1+0) : begin
                 one2two <= OUTBUS_DATA1;
              end
            endcase
         end
         INBUS_DATA1 <= 0;
         if (INBUS_RE1) begin
            case (INBUS_ADDR1)
              (DEVADDR1+0) : begin
                 INBUS_DATA1 <= two2one;
              end
            endcase
         end
         if (OUTBUS_WE2) begin
            case (OUTBUS_ADDR2)
              (DEVADDR2+0) : begin
                 two2one <= OUTBUS_DATA2;
              end
            endcase
         end
         INBUS_DATA2 <= 0;
         if (INBUS_RE2) begin
            case (INBUS_ADDR2)
              (DEVADDR2+0) : begin
                 INBUS_DATA2 <= one2two;
              end
            endcase
         end
      end
   end

endmodule
