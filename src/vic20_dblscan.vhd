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

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity VIC20_DBLSCAN is
  port (
  I_R               : in    std_logic_vector( 3 downto 0);
  I_G               : in    std_logic_vector( 3 downto 0);
  I_B               : in    std_logic_vector( 3 downto 0);
  I_HSYNC           : in    std_logic;
  I_VSYNC           : in    std_logic;
  --
  O_R               : out   std_logic_vector( 3 downto 0);
  O_G               : out   std_logic_vector( 3 downto 0);
  O_B               : out   std_logic_vector( 3 downto 0);
  O_HSYNC           : out   std_logic;
  O_VSYNC           : out   std_logic;
  LCD_DEN           : out   std_logic;
  LCD_CLK           : out   std_logic;
  --
  ENA               : in    std_logic;  -- 4 Mhz
  reset_n           : in    std_logic;
  PixelClk          : in    std_logic;  -- 33.3 MHz 
  CLK               : in    std_logic   -- 8 Mhz
  );
end;

architecture RTL of VIC20_DBLSCAN is
  constant      H_Area       : integer := 800;
  constant      V_Area       : integer := 480;

  constant      V_BackPorch  : integer := 21; 
  constant      V_Pulse      : integer := 4; 
  constant      V_FrontPorch : integer := 1; 

  constant      H_BackPorch  : integer := 88; 
  constant      H_Pulse      : integer := 128; 
  constant      H_FrontPorch : integer := 40;

  constant      PixelForHS   : integer :=   H_Pulse + H_FrontPorch + H_Area + H_BackPorch;    
  constant      LineForVS    : integer :=   V_Pulse + V_FrontPorch + V_Area + V_BackPorch;

  constant      PixelStartData : integer := H_Pulse + H_FrontPorch;
  constant      PixelEndData   : integer := PixelStartData + H_Area;
  constant      LineStartData  : integer := V_Pulse + V_FrontPorch;
  constant      LineEndData    : integer := LineStartData + V_Area;

  signal LineCount   : std_logic_vector(15 downto 0) := (others => '0');
  --
  -- input timing
  --
  signal hsync_in_t1 : std_logic;
  signal vsync_in_t1 : std_logic;  signal hpos_i      : std_logic_vector(8 downto 0) := (others => '0');    -- input capture postion
  signal rgb_in      : std_logic_vector(15 downto 0);
  --
  -- output timing
  --
  signal xcount      : std_logic_vector(15 downto 0) := (others => '0');
  signal ycount      : std_logic_vector(15 downto 0) := (others => '0');
  signal PixelCount  : std_logic_vector(15 downto 0) := (others => '0');
  signal hpos_o      : std_logic_vector(15 downto 0) := (others => '0');
  signal ohs         : std_logic;
  signal ohs_t1      : std_logic;
  signal ovs         : std_logic;
  signal ovs_t1      : std_logic;
  signal bank_o      : std_logic;
  --
  signal rgb_out     : std_logic_vector(15 downto 0) := (0 => '1', others => '0');
  signal DPBRAM_Addr : std_logic_vector(9 downto 0) := (others => '0');
  signal rising_hx   : std_logic;
  signal rising_vx   : std_logic;
  signal hsync_in_tx, hsync_in_tx_t1 : std_logic;
  signal vsync_in_tx, vsync_in_tx_t1 : std_logic;
  signal vs_cnt      : std_logic_vector(2 downto 0);

component Gowin_DPB
    port (
        douta: out std_logic_vector(15 downto 0);
        doutb: out std_logic_vector(15 downto 0);
        clka: in std_logic;
        ocea: in std_logic;
        cea: in std_logic;
        reseta: in std_logic;
        wrea: in std_logic;
        clkb: in std_logic;
        oceb: in std_logic;
        ceb: in std_logic;
        resetb: in std_logic;
        wreb: in std_logic;
        ada: in std_logic_vector(9 downto 0);
        dina: in std_logic_vector(15 downto 0);
        adb: in std_logic_vector(9 downto 0);
        dinb: in std_logic_vector(15 downto 0)
    );
end component;

begin

  p_input_timing : process
  variable rising_h : boolean;
  variable rising_v : boolean;
  begin
  wait until rising_edge (CLK);
  if (ENA = '1') then
    hsync_in_t1 <= I_HSYNC;
    vsync_in_t1 <= I_VSYNC;

    rising_h := (I_HSYNC = '1') and (hsync_in_t1 = '0');
    rising_v := (I_VSYNC = '1') and (vsync_in_t1 = '0');

    if rising_h then
     hpos_i <= (others => '0');
    else
     hpos_i <= hpos_i + 1;
    end if;
  end if;
  end process;

  rgb_in <= "0000" & I_B & I_G & I_R;
  LCD_CLK <= PixelClk;

u_ram: Gowin_DPB
    port map (
        dina            => rgb_in,
--      douta => ,
    clka            => clk,
        ocea            => '1',
        cea             => ENA,
        reseta          => not reset_n,
        wrea            => '1',
        ada(9)          => '0',
        ada(8 downto 0) => hpos_i(8 downto 0),
        clkb            => PixelClk,
        oceb            => '1',
        ceb             => '1',
        resetb          => not reset_n,
        wreb            => '0',
        ADB             => DPBRAM_Addr,
        dinb            => x"0000", 
        doutb           => rgb_out
    );

  p_lcd : process
  begin
  wait until rising_edge (PixelClk);
      O_B            <= rgb_out(11 downto 8);
      O_G            <= rgb_out(7 downto 4);
      O_R            <= rgb_out(3 downto 0);
      rising_hx      <= hsync_in_tx and not hsync_in_tx_t1;
      rising_vx      <= vsync_in_tx and not vsync_in_tx_t1;
      hsync_in_tx    <= I_HSYNC;
      hsync_in_tx_t1 <= hsync_in_tx;
      vsync_in_tx    <= I_VSYNC;
      vsync_in_tx_t1 <= vsync_in_tx;
  end process;

  p_output_timing : process
  variable rising_h : boolean;
  begin
  wait until rising_edge (CLK);
    rising_h := ((ohs = '1') and (ohs_t1 = '0'));

    if rising_h  then
      hpos_o <= (others => '0');
    else
      hpos_o <= hpos_o + "1";
    end if;

    if (ovs = '1') and (ovs_t1 = '0') then -- rising_v
      vs_cnt <= "000";
    elsif rising_h then
      if (vs_cnt(2) = '0') then
        vs_cnt <= vs_cnt + "1";
      end if;
    end if;

    ohs <= I_HSYNC; -- reg on clk_12
    ohs_t1 <= ohs;

    ovs <= I_VSYNC; -- reg on clk_12
    ovs_t1 <= ovs;
  end process;

  p_lcd_output_timing : process(PixelClk, reset_n)
  begin
    if reset_n = '0' then 
       LineCount       <= (others => '0');    
      PixelCount      <= (others => '0');
      elsif rising_edge(PixelClk) then 
          if PixelCount = PixelForHS then 
            PixelCount <= (others => '0'); 
            LineCount  <= LineCount + 1;
      elsif rising_vx then
        LineCount    <= (others => '0');    
        PixelCount   <= (others => '0');
      else
        PixelCount  <= PixelCount + 1; 
        DPBRAM_Addr <= std_logic_vector(to_unsigned(to_integer(unsigned(( PixelCount - PixelStartData ))/2), DPBRAM_Addr'LENGTH)); 
      end if;
    end if;
  end process;

  LCD_DEN <= '1' when 
     PixelCount >= PixelStartData and 
     PixelCount < PixelEndData and
     LineCount >= LineStartData and 
     LineCount < LineEndData
  else '0';

  O_HSYNC <= '0' when
     PixelCount < H_Pulse 
  else '1';

  O_VSYNC <= '0' when
    LineCount  >= V_Pulse 
  else '1';

  end architecture RTL;
