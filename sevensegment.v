
module sevensegment
  ( clk, blank, value, segments );

   input            clk;
   input [3:0]      value;
   input            blank;
   output reg [6:0] segments;

   always @(posedge clk) begin
      if (blank)
        segments <= 7'd0;
      else begin
         case (value)
           4'b0000 : segments <= 7'h7d;
           4'b0001 : segments <= 7'h60;
           4'b0010 : segments <= 7'h3e;
           4'b0011 : segments <= 7'h7a;
           4'b0100 : segments <= 7'h63;
           4'b0101 : segments <= 7'h5b;
           4'b0110 : segments <= 7'h5f;
           4'b0111 : segments <= 7'h70;
           4'b1000 : segments <= 7'h7f;
           4'b1001 : segments <= 7'h7b;
           4'b1010 : segments <= 7'h77;
           4'b1011 : segments <= 7'h4f;
           4'b1100 : segments <= 7'h1d;
           4'b1101 : segments <= 7'h6e;
           4'b1110 : segments <= 7'h1f;
           4'b1111 : segments <= 7'h17;
         endcase
      end
   end

endmodule // sevensegment
