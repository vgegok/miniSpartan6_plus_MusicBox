`timescale 1ns / 1ps

// Prevent unintentional net creation:
`default_nettype none

// Provide a 12-bit sine LUT for two DDS units
// 2 clock latency.

module sinelut
(
// Inputs
  input wire         sys_rst,           // Global power-on reset
  input wire         sys_clk,           // 100 MHz system clock
  // Address from the DDS unit is 12 MSBs
  input wire  [11:0] dds1_iaddr,
  input wire  [11:0] dds2_iaddr,
  input wire         clk_ena,           // Line Valid in
  output reg  [11:0] dds1_odata,
  output reg  [11:0] dds2_odata
);

reg  [11:0] lut1_addr;                  // Normally dds1_iaddr (delayed) unless writing
reg  [11:0] lut2_addr;                  // dds2_iaddr (delayed)
reg  [11:0] sine_lut [0:4095];
reg  [11:0] dds1_lut;
reg  [11:0] dds2_lut;
reg   [2:0] cke_dly;
// Pipeline stages to match knock-out with input data

`ifdef HARMONICS
initial $readmemh ("../source/harmonic_lut.hex", sine_lut);
`else
initial $readmemh ("../source/sine_lut.hex", sine_lut);
`endif

always @ (posedge sys_clk)
if (cke_dly[0])
  begin
    dds1_lut <= sine_lut[lut1_addr];
    dds2_lut <= sine_lut[lut2_addr];
  end

always @ (posedge sys_clk or posedge sys_rst)
if (sys_rst)
  begin
    dds1_odata <= 12'h800;
    dds2_odata <= 12'h800;
    cke_dly <= 3'b0;
    lut1_addr <= 12'b0;
    lut2_addr <= 12'b0;
  end
else
  begin
    cke_dly <= {cke_dly,clk_ena};
    if (clk_ena)
      begin
        lut1_addr <= dds1_iaddr;
        lut2_addr <= dds2_iaddr;
      end
    if (cke_dly[1])
      begin
        dds1_odata <= dds1_lut;
        dds2_odata <= dds2_lut;
      end
  end

endmodule

// Prevent unintentional screw-up of other modules including
// Xilinx IP:
`default_nettype wire
