--
-- A simulation model of VIC20 hardware
-- Copyright (c) MikeJ - March 2003
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email vic20@fpgaarcade.com
--
--
-- Revision list
--
-- version 001 initial release

use std.textio.ALL;
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity vic20_tb is
end;

architecture vic20_tb of vic20_tb is

  constant CLKPERIOD_27MHz : time := 37.037 ns;

  signal ps2_clk          :  std_logic;
  signal ps2_data         :  std_logic;
  --
  signal O_VIDEO_R        :  std_logic_vector(4 downto 0);
  signal O_VIDEO_G        :  std_logic_vector(5 downto 0);
  signal O_VIDEO_B        :  std_logic_vector(4 downto 0);
  signal O_HSYNC          :  std_logic;
  signal O_VSYNC          :  std_logic;
  signal LCD_CLK          :  std_logic; 
  signal LCD_DEN          :  std_logic;
  --
  signal O_AUDIO          :  std_logic;
  --
  signal I_CLK_REF        :  std_logic;
 --
  signal IEC_ATN          :  std_logic;
  signal IEC_CLOCK        :  std_logic;
  signal IEC_DATA         :  std_logic;
 
  signal push_reset_n     : std_logic;
  signal User_Button_n    : std_logic;

  signal joy             : std_logic_vector(3 downto 0);
  signal joy_fire        : std_logic;

  component VIC20
  port 
  (
   --
   I_PS2_CLK        :in  std_logic;
   I_PS2_DATA       :in  std_logic;
   --
   O_VIDEO_R        :out  std_logic_vector(4 downto 0);
   O_VIDEO_G        :out  std_logic_vector(5 downto 0);
   O_VIDEO_B        :out  std_logic_vector(4 downto 0);
   O_HSYNC          :out  std_logic;
   O_VSYNC          :out  std_logic;
   LCD_CLK          :out  std_logic; 
   LCD_DEN          :out  std_logic;
   --
   O_AUDIO          :out  std_logic;
   --
   I_CLK_REF        :in  std_logic;
  --
  IEC_ATN           :out    std_logic;
  IEC_CLOCK         :inout  std_logic;
  IEC_DATA          :inout  std_logic;
  
  push_reset_n      :in std_logic;
  User_Button_n     :in std_logic;
  
  joy               :in std_logic_vector(3 downto 0);
  joy_fire          :in std_logic
  );
  end component;

begin
  u0 : VIC20
    port map (
      I_PS2_CLK       => ps2_clk,
      I_PS2_DATA      => ps2_data,
      --
      O_VIDEO_R       => O_VIDEO_R,
      O_VIDEO_G       => O_VIDEO_G,
      O_VIDEO_B       => O_VIDEO_B,
      O_HSYNC         => O_HSYNC,
      O_VSYNC         => O_VSYNC,
      LCD_CLK         => LCD_CLK, 
      LCD_DEN         => LCD_DEN,
      --
      O_AUDIO         => O_AUDIO,
      --
      I_CLK_REF       => I_CLK_REF,
      --
      IEC_ATN         => IEC_ATN,
      IEC_CLOCK       => IEC_CLOCK,
      IEC_DATA        => IEC_DATA,
      
      push_reset_n    => push_reset_n,
      User_Button_n   => User_Button_n,

      joy             => joy,
      joy_fire        => joy_fire
    );


  p_clk_27mhz  : process
  begin
    I_CLK_REF <= '0';
    wait for CLKPERIOD_27MHz / 2;
    I_CLK_REF <= '1';
    wait for CLKPERIOD_27MHz - (CLKPERIOD_27MHz / 2);
  end process;

  p_rst : process
  begin
    push_reset_n <= '0';
    wait for 100 ns;
    push_reset_n <= '1';
    wait;
  end process;

  User_Button_n <= '1';

  joy           <= b"0000";
  joy_fire      <= '1';

  ps2_clk       <= '1';
  ps2_data      <= '1';

end vic20_tb;

