`timescale 1 ns / 1 ps

`default_nettype none

// This module uses 100 MHz clock in DDR output mode to provide
// 12-bit resolution PWM at 48 KHz using default parameters

module pwm_out_ddr
#(
  parameter     CLK_DIV = 2083,
  parameter     NBITS = 12
)
(
  input wire  [NBITS-1:0] data_in,    // Nominally 12-bit input data
  input wire              sys_clk,
  input wire              sys_rst,
  output wire             pwm_out_p,  // Positive side of quasi-differential PWM output
  output wire             pwm_out_n,  // Negative side of quasi-differential PWM output
  output reg              next_val=0  // Request to update input data at nominally 48 KHz
);

// Workaround to broken $clog2 function in ISE 13
// From Answer Record #44586
function integer clog2;
  input integer value;
  begin
    value = value-1;
    for (clog2=0; value>0; clog2=clog2+1)
      value = value>>1;
  end
endfunction

reg  [clog2(CLK_DIV)-1:0] div_ctr = CLK_DIV - 6;
reg           [NBITS-1:0] data = 1 << (NBITS - 1);
reg                       switch_time = 0;
reg                       switch_off = 1;
reg                       off_dly = 1;
reg                       high_time = 0;
reg                       high_dly = 0;
reg                       pwm_r = 0;
reg                       pwm_f = 0;
reg           [NBITS-1:0] ramp_up = 0;  // startup ramp to avoid "pop" at power-on
reg           [NBITS-1:0] low_lim = 1 << (NBITS - 1);
reg           [NBITS-1:0] high_lim = 1 << (NBITS - 1);

always @ (posedge sys_clk)
if (sys_rst)  // use as a synchronous reset
  begin
    div_ctr <= CLK_DIV - 6;
    data <= 1 << (NBITS - 1); // Mid-scale is DC 0 for differential signal
    ramp_up <= 0;
    low_lim <= 1 << (NBITS - 1);
    high_lim <= 1 << (NBITS - 1);
    switch_time <= 0;
    switch_off <= 1;
    off_dly <= 1;
    high_time <= 0;
    high_dly <= 0;
    pwm_r <= 0;
    pwm_f <= 0;
  end
else
  begin
    if (next_val)
      begin
        if (!ramp_up[NBITS-1])  // Still warming up
          begin
            ramp_up <= ramp_up + 1;
            low_lim <= low_lim - 1;
            high_lim <= high_lim + 1;
            if (data_in < low_lim) data <= low_lim;
            else if (data_in > high_lim) data <= high_lim;
            else data <= data_in;
          end
        else
          begin
            data <= data_in;
          end
      end
    div_ctr <= next_val ? 0 : div_ctr + 1;
    next_val <= div_ctr == CLK_DIV - 2;
    switch_time <= div_ctr == data[NBITS-1:1];
    switch_off <= div_ctr[NBITS-1];
    off_dly <= switch_off;
    if (next_val) high_time <= 1;
    else if (switch_time) high_time <= 0;
    high_dly <= high_time & !switch_time;
    pwm_f <= high_dly & !switch_time;
    pwm_r <= high_dly & !switch_time | switch_time & data[0];
  end

// Two DDR outputs implement quasi-differential PWM.  Both sides
// initialize low to start without DC bias.  Also both sides are
// low during the "extra" count period if the clock divisor
// is not a power of 2.  For nominal settings, this is 35 clock
// cycles of 100 MHz.

ODDR2
#(
  .DDR_ALIGNMENT  ("C0"),     // Sets output alignment to "NONE", "C0" or "C1"
  .INIT           (1'b0),     // Sets initial state of the Q output to 1'b0 or 1'b1
  .SRTYPE         ("ASYNC")   // Specifies "SYNC" or "ASYNC" set/reset
) POS_ODDR
(
  .Q    (pwm_out_p),
  .C0   (sys_clk),
  .C1   (~sys_clk),
  .CE   (1'b1),
  .D0   (pwm_r),
  .D1   (pwm_f),
  .R    (1'b0),
  .S    (1'b0)
);

ODDR2
#(
  .DDR_ALIGNMENT  ("C0"),     // Sets output alignment to "NONE", "C0" or "C1"
  .INIT           (1'b0),     // Sets initial state of the Q output to 1'b0 or 1'b1
  .SRTYPE         ("ASYNC")   // Specifies "SYNC" or "ASYNC" set/reset
) NEG_ODDR
(
  .Q    (pwm_out_n),
  .C0   (sys_clk),
  .C1   (~sys_clk),
  .CE   (1'b1),
  .D0   (~pwm_r & ~off_dly),
  .D1   (~pwm_f & ~off_dly),
  .R    (1'b0),
  .S    (1'b0)
);

endmodule

`default_nettype wire


