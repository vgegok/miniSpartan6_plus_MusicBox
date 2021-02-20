Thanks for the code provided by [gszakacs](https://forums.xilinx.com/t5/Xilinx-Evaluation-Boards/Scarab-Hardware-s-miniSpartan6-Audio-example/m-p/588595/highlight/true) , I have verified it in minispartan6+(xc6slx9).

ISE 14.7 Project:

synth/Audio_test.xise

  This is a simple project to demonstrate the audio output
on the miniSpartan6+ board.  I have found that using the
amplified speakers built into my computer monitor gives
reasonable sound reproduction.  As delivered the project
is a 2-voice music box that plays J.S. Bach's Invention
number 8 in F major.

  Music is held in a BRAM-based ROM, as are the tone frequencies
(well-tempered scale), and output waveform.  Output is 12-bit
PWM at 48 KHz on each of the two audio outputs.  This music
conveniently has only two voices and one is played on each
channel (left or right).

Verilog Sources:

Source/Scarab_Top.v - Top level source
Source/music_ROM.v - Music ROM.  Uses Bach.hex
Source/tone_gen_dual.v - Simple tone generator for two channels.  Uses tones.hex
Source/sinelut.v - Waveform ROM.  Uses sine_lut.hex or harmonic_lut.hex
Source/pwm_out_ddr.v - Output PWM drive, one per channel.

Other Project files:

Constraints/miniSpartan6-plus.ucf

  This is a full UCF including a lot of pins that aren't used in
this project.  Note that the project settings allow unused LOC
constraints, so any unused pins don't generate an error during
translate.

cores/clk50_wiz.xco

  This is basically a clock doubler to generate 100 MHz from the
50 MHz on-board clock.

docs/BachTwoPartInventionNumber8.xls

  This was used to enter the music by hand using decimal numbers
and convert it to hex.  Bach.hex was made by pasting columns D and
E into a text editor and removing tabs to form 16-bit hex numbers.

docs/SineLUT.xls

  This was used to generate sine_lut.hex, tones and harmonic_lut.hex
using values from column D of the appropriate sheet.

docs/KeyboardWithNumbers.pdf

  This illustrates the number encoding of notes used in preparing
the music.  In the actual music ROM, there are also two special
values.  0 encodes a rest.  1 encodes a continuation of the previous
tone so there will be no articulation.  The tempo and articulation
time are in the top level code.  Look in Scarab_Top.v for more
explanation about tempo.  As delivered, the articulation period
between "beats" is hardcoded at 20 milliseconds.

Build options:

As delivered, the synthesis options define the Verilog macro
HARMONICS.  This uses the waveform from harmonic_lut.hex rather
than sine_lut.hex.  Remove this option to get sine wave output.

Programming:

You will need the following in order to load the program into the
Scarab MiniSpartan6+ board using the supplied batch files:

1) xc3sprog.exe - You can download this at:

http://sourceforge.net/projects/xc3sprog/

Unzip the executable and place it in the synth folder or somewhere in
your execution path if you intend to use it for other projects.

2) bscan_spi_s6lx25_ftg256.bit or bscan_spi_s6lx9_ftg256.bit depending
on the chip on your MiniSpartan6+ board.  You can download them at:

http://www.hamsterworks.co.nz/mediawiki/index.php/File:Bscan_spi_s6lx25_ftg256.zip
http://www.hamsterworks.co.nz/mediawiki/index.php/File:Bscan_spi_s6lx9_ftg256.zip

There is a lot more info at:

http://www.hamsterworks.co.nz/mediawiki/index.php/MiniSpartan6%2B_bringup

The batch files in the synth folder expect the bit files to be there.
They are written for the LX25, so if you have the LX9 board you need
to make adjustments to flash.bat to use the correct bit file.

Batch files assume you have built the project using the ISE GUI and the
project bit file is in the synth folder.  Again you will need to change
the project settings if you use the LX9 version of the board.

Batch files are:

prog.bat - Program the FPGA directly with JTAG, does not affect flash.

flash.bat - Program the FPGA bit file into flash and then reload from flash.

load_from_flash.bat - just load the FPGA from the flash.  Same as pushing the
button on the board.
