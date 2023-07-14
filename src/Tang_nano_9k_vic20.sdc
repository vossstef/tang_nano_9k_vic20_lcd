//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.09 Education
//Created Time: 2023-01-24 07:42:19
create_clock -name I_CLK_REF -period 37 -waveform {0 18} [get_ports {I_CLK_REF}]
create_clock -name LCD_CLK -period 30 -waveform {0 15} [get_ports {LCD_CLK}]
