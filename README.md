# tang_nano_9k_vc20
VIC-20 living in a Gowin GW1NR-9 FPGA on a Sipeed Tang Nano 9K board.<br>
<br>
**Video output is adapted for a 5" TFT-LCD module 800x480 Type SH500Q01Z **
[Datasheet](https://dl.sipeed.com/Accessories/LCD/500Q01Z-00%20spec.pdf)


Original VIC-20 core by MikeJ (Mike Johnson) and T65 WoS (Wolfgang Scherr)

Features
* TFT-LCD Video Output
* Speaker Sound
* PS2 Keyboard
* Joystick

*VIC-20 in a FPGA* <br>
![pinmap](\.assets/vic-20-tang.png)<br> <br>

## Push Button utilization
* S1 push button Reset
* S2 ROM Cardride disable (keep S2 pressed while power-on or do S1 push-button Reset )
## Powering
Entire prototype circuit with Keyboard and Audio can be powered by Tang USB-C connector from PC or a Power Supply Adapter. 
## Synthesis
Source code can be synthesized and fitted with GOWIN IDE under Windows and Linux.

## Simulation
Basic testbench as a starting point in the TB folder (*vic20_tb.vhd*)<br/>
Script for compiling the Gowin library, sources and testbench in the simulation folder (*sim_vic20.do*).<br/>
For a Simulation run execute_simulation.bat (*Windows*) or execute_simulation.sh (*Linux*)

## Pin mapping 
see pin configuration in .cst configuation file

## Tang LEDs
LED's so far unused.
## HW circuit considerations
- PS2 keyboard has to be connected to 3.3V tolerant FPGA via level shifter to avoid damage of inputs ! Use e.g. 2 pcs SN74LVC1G17DBVR 5V to 3V3 level shifter. My Keyboard has internal pull-up resistors to 5V for Clock and Data Signals so din't needed exteral ones. 
- Joystick interface is 3.3V tolerant for usual micro switches. Joystick 5V supply pin has to be left floating !
- The FPGA pin delivering the Audio PWM to the Amplifier input need a low pass filter. 3K3 series Resistor and 47nF Capacitor to GND.
- Tang Nano 5V output connected to Audio Amplifier and Keyboard supply. Tang 3V3 output to level shifter supply.

**Pinmap Joystick Interface** <br>
![pinmap](\.assets/vic20-Joystick.png)

| Joystick pin | Tang Nano pin | FPGA pin | Joystick Function |
| ----------- | ---   | --------  | ----- |
| 1 | J5 8  | 28   |  UP |
| 2 | J5 7  | 27 | DOWN |
| 3 | J5 6  | 26 | LEFT |
| 4 | J5 5 | 25 | RIGHT |
| 5 | n.c. | n.c. | POT Y |
| 6 | J5 9 | 29 | FIRE |
| 7 | n.c. | n.c. | 5V |
| 8 | J6 23 | - | GND |
| 9 | n.c. | n.c. | POT X |

**Pinmap PS2 Interface** <br>
![pinmap](\.assets/ps2conn.png)

| PS2 pin | Tang Nano pin | FPGA pin | PS2 Function |
| ----------- | ---   | --------  | ----- |
| 1 | J6 10  | 77   | DATA  |
| 2 | n.c.  | - | n.c. |
| 3 | J6 23 | - | GND |
| 4 | J6 18 | - | +5V |
| 5 | J6 11| 76 | CLK |
| 6 | n.c. | - | n.c |

**low pass filter for Audio Amplifier input** <br>
![pinmap](\.assets/audio_filter.png)<br>

### BOM
Tang Nano 9k<br>
SH500Q01Z LCD-TFT<br>
D-SUB 9 M connector<br> 
Commodore/Atari compatible Joystick<br> 
or alternatively 5D Rocker Joystick navigation button module<br>
3K3 Resistor<br>
47nF Ceramics<br>
Mini PAM8403 Audio Amplifier Module<br>
8...32R Speaker<br>
PS 2 Keyboard<br>
PS Socket Adapter module<br>
2 pcs SN74LVC1G17DBVR level shifter<br>
Double Sided Circuit Board<br>