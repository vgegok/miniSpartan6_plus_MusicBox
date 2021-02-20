`timescale 1ns / 1ps
`default_nettype none

module music_ROM
(
  input wire  [9:0] addr_in,    // Music address, location within tune in beats
  input wire        sys_clk,    // 100 MHz
  output reg  [6:0] note1,      // First of two concurrently played notes
  output reg  [6:0] note2       // Second of two concurrently played notes
);

reg  [15:0] music_lut [0:511];
integer i;
initial $readmemh ("../source/Bach.hex", music_lut);

reg         unused1;
reg         unused2;

always @ (posedge sys_clk)
  begin
    {unused1,note1,unused2,note2} <= music_lut[addr_in];
  end

endmodule
`default_nettype wire

