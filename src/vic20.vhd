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
-- 200x-xx-xx  version 001 initial release
-- 2008-xx-xx  version 002 spartan3e release
-- 2009-02-15  changed the clocksignal generator code. The original DCM required a 50MHz input, this was not really accurate to be used as a base for the PAL and VGA signals, but addequate enough. Unfortunately on the spartan3 the DCM used to generate the 8.66 MHz signal is too low for the DCM, the DCM's output cannot function at such a low freq. On a spartan 3E this is not a problem but the minimig uses a spartan3, so this needed to be changed
--      the new code uses the input clock freq of 4.433MHz and multiplies that x8 and devides it then outside the DCM to the required 8 and 4 MHz clockfreqs that are needed for the core
-- 2009-02-16  added an automatic reset sequence, the system resets for 0.1 second after configuration. This elliminates the need for an external reset signal.
--    if the user wants to reset the core, then reconfigure the FPGA (by pressing the minimig's reset) (which takes approx. 4 seconds).
-- 2009-02-17  added the IEC-bus (and it really works)  
--  2009-02-20  joystick is now correctly mapped (in UCF), this now works

library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity VIC20 is 
port 
  (
   LED           :out std_logic_vector(5 downto 0);
   --
   I_PS2_CLK     :in  std_logic;
   I_PS2_DATA    :in  std_logic;
   --
   O_VIDEO_R     :out  std_logic_vector(4 downto 0);
   O_VIDEO_G     :out  std_logic_vector(5 downto 0);
   O_VIDEO_B     :out  std_logic_vector(4 downto 0);
   O_HSYNC       :out  std_logic;
   O_VSYNC       :out  std_logic;
   LCD_CLK       :out  std_logic; 
   LCD_DEN       :out  std_logic;
   --
   O_AUDIO       :out  std_logic;

   --
   I_CLK_REF     :in    std_logic;
  --
  IEC_ATN        :out  std_logic;
  IEC_CLOCK      :inout  std_logic;
  IEC_DATA       :inout  std_logic;
  
  push_reset_n   :in std_logic;
  User_Button_n  :in std_logic;

  joy_up         :in  std_logic;
  joy_down       :in  std_logic;
  joy_left       :in  std_logic;
  joy_right      :in  std_logic;
  joy_fire       :in  std_logic
  );
end;

architecture RTL of VIC20 is

  -- default
   constant K_OFFSET : std_logic_vector (4 downto 0) := "10000"; -- h position of screen to centre on your telly

    signal clock_35MHz        : std_logic;
    signal clock_div        : std_logic_vector(2 downto 0);
    signal clock_8MHz         : std_logic;
    signal ena_4              : std_logic;
    signal auto_reset         : std_logic;
    
    -- cpu
    signal c_ena              : std_logic;
    signal c_addr             : std_logic_vector(23 downto 0);
    signal c_din              : std_logic_vector(7 downto 0);
    signal c_dout             : std_logic_vector(7 downto 0);
    signal c_rw_l             : std_logic;
    signal c_irq_l            : std_logic;
    signal c_nmi_l            : std_logic;
    --
    signal io_sel_l           : std_logic_vector(3 downto 0);
    signal blk_sel_l          : std_logic_vector(7 downto 0);
    signal ram_sel_l          : std_logic_vector(7 downto 0);

    -- vic
    signal vic_addr           : std_logic_vector(13 downto 0);
    signal vic_oe_l           : std_logic;
    signal vic_dout           : std_logic_vector( 7 downto 0);
    signal vic_din            : std_logic_vector(11 downto 0);
    signal p2_h               : std_logic;
    signal ena_1mhz           : std_logic;
    signal vic_audio          : std_logic_vector( 3 downto 0);
    signal audio_pwm          : std_logic;
    signal via1_dout          : std_logic_vector( 7 downto 0);
    signal via2_dout          : std_logic_vector( 7 downto 0);
    -- video system
    signal v_addr             : std_logic_vector(13 downto 0);
    signal v_data             : std_logic_vector( 7 downto 0);
    signal v_data_oe_l        : std_logic;
    signal v_data_read_mux    : std_logic_vector( 7 downto 0);
    signal v_data_read_muxr   : std_logic_vector( 7 downto 0);
    signal v_rw_l             : std_logic;
    signal col_ram_sel_l      : std_logic;

    -- ram
    signal ram0_dout          : std_logic_vector(7 downto 0);
    signal ram12_dout         : std_logic_vector(7 downto 0);
    signal ram3_dout          : std_logic_vector(7 downto 0);
    signal ram45_dout         : std_logic_vector(7 downto 0);
    signal ram5_dout          : std_logic_vector(7 downto 0);
    signal ram67_dout         : std_logic_vector(7 downto 0);
    signal ram7_dout          : std_logic_vector(7 downto 0);
    --
    signal col_ram_dout       : std_logic_vector(7 downto 0);

    signal char_rom_dout      : std_logic_vector(7 downto 0);
    signal basic_rom_dout     : std_logic_vector(7 downto 0);
    signal kernal_rom_dout    : std_logic_vector(7 downto 0);

    signal ext_rom_din        : std_logic_vector(7 downto 0);
    signal expansion_din      : std_logic_vector(7 downto 0);
    signal expansion_nmi_l    : std_logic;
    signal expansion_irq_l    : std_logic;

    -- VIAs
    signal via1_nmi_l         : std_logic;
    signal via1_pa_in         : std_logic_vector(7 downto 0);
    signal via1_pa_out        : std_logic_vector(7 downto 0);

    signal via2_irq_l         : std_logic;

    signal cass_write         : std_logic;
    signal cass_read          : std_logic;
    signal cass_motor         : std_logic;
    signal cass_sw            : std_logic;

    signal keybd_col_out      : std_logic_vector(7 downto 0);
    signal keybd_col_in       : std_logic_vector(7 downto 0);
    signal keybd_col_oe_l     : std_logic_vector(7 downto 0);
    signal keybd_row_in       : std_logic_vector(7 downto 0);
    signal keybd_restore      : std_logic;

    signal serial_srq_in      : std_logic;
    signal serial_atn_out     : std_logic; -- the vic does not listen to atn_in
    signal serial_clk_out     : std_logic;
    signal serial_clk_in      : std_logic;
    signal serial_data_out    : std_logic;
    signal serial_data_in     : std_logic;

    -- user port
    signal user_port_cb1_in   : std_logic;
    signal user_port_cb1_out  : std_logic;
    signal user_port_cb1_oe_l : std_logic;
    signal user_port_cb2_in   : std_logic;
    signal user_port_cb2_out  : std_logic;
    signal user_port_cb2_oe_l : std_logic;
    signal user_port_in       : std_logic_vector(7 downto 0);
    signal user_port_out      : std_logic_vector(7 downto 0);
    signal user_port_oe_l     : std_logic_vector(7 downto 0);
    -- misc

    signal video_r            : std_logic_vector(3 downto 0);
    signal video_g            : std_logic_vector(3 downto 0);
    signal video_b            : std_logic_vector(3 downto 0);
    signal hsync              : std_logic;
    signal vsync              : std_logic;
    signal csync              : std_logic;
    signal video_r_x2         : std_logic_vector(3 downto 0);
    signal video_g_x2         : std_logic_vector(3 downto 0);
    signal video_b_x2         : std_logic_vector(3 downto 0);
    signal hsync_x2           : std_logic;
    signal vsync_x2           : std_logic;
    signal blanking           : std_logic;
    signal blanking_x2        : std_logic;

    signal cart_data          : std_logic_vector(7 downto 0) := (0 => '1', others => '0');
   
    signal we            : std_logic;
    signal we0           : std_logic; 
    signal we1           : std_logic; 
    signal we15          : std_logic; 
    signal we2           : std_logic; 
    signal we27          : std_logic; 
    signal we3           : std_logic; 
    signal we4           : std_logic; 
    signal we5           : std_logic; 

   component Gowin_rPLL
   port (
         clkout: out std_logic;
         clkoutd: out std_logic;
         clkin: in std_logic
     );
   end component;

component CLKDIV
    generic (
        DIV_MODE : STRING := "2";
        GSREN: in string := "false"
    );
    port (
        CLKOUT: out std_logic;
        HCLKIN: in std_logic;
        RESETN: in std_logic;
        CALIB: in std_logic
    );
end component;

component Gowin_pROM_kernal
   port (
       dout: out std_logic_vector(7 downto 0);
       clk: in std_logic;
       oce: in std_logic;
       ce: in std_logic;
       reset: in std_logic;
       ad: in std_logic_vector(12 downto 0)
   );
end component;

component Gowin_pROM_char
   port (
       dout: out std_logic_vector(7 downto 0);
       clk: in std_logic;
       oce: in std_logic;
       ce: in std_logic;
       reset: in std_logic;
       ad: in std_logic_vector(11 downto 0)
   );
end component;

component Gowin_pROM_basic
   port (
       dout: out std_logic_vector(7 downto 0);
       clk: in std_logic;
       oce: in std_logic;
       ce: in std_logic;
       reset: in std_logic;
       ad: in std_logic_vector(12 downto 0)
   );
end component;

component Gowin_pROM_cart_rom
    port (
        dout: out std_logic_vector(7 downto 0);
        clk: in std_logic;
        oce: in std_logic;
        ce: in std_logic;
        reset: in std_logic;
        ad: in std_logic_vector(12 downto 0)
    );
end component;

component Gowin_pROM
    port (
        dout: out std_logic_vector(7 downto 0);
        clk: in std_logic;
        oce: in std_logic;
        ce: in std_logic;
        reset: in std_logic;
        ad: in std_logic_vector(12 downto 0)
    );
end component;

component Gowin_SP_1kb
    port (
        dout: out std_logic_vector(7 downto 0);
        clk: in std_logic;
        oce: in std_logic;
        ce: in std_logic;
        reset: in std_logic;
        wre: in std_logic;
        ad: in std_logic_vector(9 downto 0);
        din: in std_logic_vector(7 downto 0)
    );
end component;

component Gowin_SP_2kb
    port (
        dout: out std_logic_vector(7 downto 0);
        clk: in std_logic;
        oce: in std_logic;
        ce: in std_logic;
        reset: in std_logic;
        wre: in std_logic;
        ad: in std_logic_vector(10 downto 0);
        din: in std_logic_vector(7 downto 0)
    );
end component;

component T65 
  port(
  Mode    : in  std_logic_vector(1 downto 0);      -- "00" => 6502, "01" => 65C02, "10" => 65C816
  Res_n   : in  std_logic;
  Enable  : in  std_logic;
  Clk     : in  std_logic;
  Rdy     : in  std_logic;
  Abort_n : in  std_logic;
  IRQ_n   : in  std_logic;
  NMI_n   : in  std_logic;
  SO_n    : in  std_logic;
  R_W_n   : out std_logic;
  Sync    : out std_logic;
  EF      : out std_logic;
  MF      : out std_logic;
  XF      : out std_logic;
  ML_n    : out std_logic;
  VP_n    : out std_logic;
  VDA     : out std_logic;
  VPA     : out std_logic;
  A       : out std_logic_vector(23 downto 0);
  DI      : in  std_logic_vector(7 downto 0);
  DO      : out std_logic_vector(7 downto 0)
  );
end component T65;

component VIC20_VIC
  generic (
    K_OFFSET          : in    std_logic_vector(4 downto 0) := "10000"
    );
  port (
    I_RW_L            : in    std_logic;

    I_ADDR            : in    std_logic_vector(13 downto 0);
    O_ADDR            : out   std_logic_vector(13 downto 0);

    I_DATA            : in    std_logic_vector(11 downto 0);
    O_DATA            : out   std_logic_vector( 7 downto 0);
    O_DATA_OE_L       : out   std_logic;
    --
    O_AUDIO           : out   std_logic_vector(3 downto 0);

    O_VIDEO_R         : out   std_logic_vector(3 downto 0);
    O_VIDEO_G         : out   std_logic_vector(3 downto 0);
    O_VIDEO_B         : out   std_logic_vector(3 downto 0);

    O_HSYNC           : out   std_logic;
    O_VSYNC           : out   std_logic;
    O_COMP_SYNC_L     : out   std_logic;
    O_BLANK           : out std_logic;
    --
    --
    I_LIGHT_PEN       : in    std_logic;
    I_POTX            : in    std_logic;
    I_POTY            : in    std_logic;

    O_ENA_1MHZ        : out   std_logic; -- 1.1 MHz strobe
    O_P2_H            : out   std_logic; -- 2.2 MHz cpu access
    ENA_4             : in    std_logic; -- 4.436 MHz clock enable
    CLK               : in    std_logic
    );
end component;

component M6522
  port (
    I_RS              : in    std_logic_vector(3 downto 0);
    I_DATA            : in    std_logic_vector(7 downto 0);
    O_DATA            : out   std_logic_vector(7 downto 0);
    O_DATA_OE_L       : out   std_logic;

    I_RW_L            : in    std_logic;
    I_CS1             : in    std_logic;
    I_CS2_L           : in    std_logic;

    O_IRQ_L           : out   std_logic; -- note, not open drain
    -- port a
    I_CA1             : in    std_logic;
    I_CA2             : in    std_logic;
    O_CA2             : out   std_logic;
    O_CA2_OE_L        : out   std_logic;

    I_PA              : in    std_logic_vector(7 downto 0);
    O_PA              : out   std_logic_vector(7 downto 0);
    O_PA_OE_L         : out   std_logic_vector(7 downto 0);

    -- port b
    I_CB1             : in    std_logic;
    O_CB1             : out   std_logic;
    O_CB1_OE_L        : out   std_logic;

    I_CB2             : in    std_logic;
    O_CB2             : out   std_logic;
    O_CB2_OE_L        : out   std_logic;

    I_PB              : in    std_logic_vector(7 downto 0);
    O_PB              : out   std_logic_vector(7 downto 0);
    O_PB_OE_L         : out   std_logic_vector(7 downto 0);

    I_P2_H            : in    std_logic; -- high for phase 2 clock  ____----__
    RESET_L           : in    std_logic;
    ENA_4             : in    std_logic; -- clk enable
    CLK               : in    std_logic
    );
end component;

component VIC20_DBLSCAN 
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
    ENA               : in    std_logic;
    reset_n           : in    std_logic;
    PixelClk          : in    std_logic;
    CLK               : in    std_logic
  );
end component;

component VIC20_PS2_IF 
  port (
    I_PS2_CLK       : in    std_logic;
    I_PS2_DATA      : in    std_logic;

    I_COL           : in    std_logic_vector(7 downto 0);
    O_ROW           : out   std_logic_vector(7 downto 0);
    O_RESTORE       : out   std_logic;

    I_ENA_1MHZ      : in    std_logic;
    I_P2_H          : in    std_logic; -- high for phase 2 clock  ____----__
    RESET_L         : in    std_logic;
    ENA_4           : in    std_logic; -- 4x system clock (4HZ)   _-_-_-_-_-
    CLK             : in    std_logic
    );
end component;

component  dac 
  generic (
    msbi_g : integer := 7
  );
  port (
    clk_i   : in  std_logic;
    res_n_i : in  std_logic;
    dac_i   : in  std_logic_vector(msbi_g downto 0);
    dac_o   : out std_logic
  );
end component;


COMPONENT GSR
 PORT (
 GSRI:IN std_logic
 );
end component;

begin

clock_generator: Gowin_rPLL
port map (
    clkoutd => clock_35MHz,
    clkin => I_CLK_REF
);

clock_divider0: CLKDIV
generic map (
    DIV_MODE => "4",
    GSREN  => "false"
)
port map (
    CALIB  => '0',
    clkout => clock_8MHz,
    hclkin => clock_35MHz,
    resetn => auto_reset
    );

clock_divider1: CLKDIV
generic map (
    DIV_MODE => "2",
    GSREN  => "false"
)
port map (
    CALIB  => '0',
    clkout => ena_4,
    hclkin => clock_8MHz,
    resetn => auto_reset
    );

  LED(0) <= '1';
  LED(1) <= '1';
  LED(2) <= '1';
  LED(3) <= '1';
  LED(4) <= '1';
  LED(5) <= '1';

  c_ena <= ena_1mhz and ena_4; -- clk ena

-----------------------------------------------------------------------------
  -- Reset generation
  -----------------------------------------------------------------------------
  gsr_inst: GSR
    PORT MAP(
    GSRI => push_reset_n
  );

   auto_reset <= push_reset_n;

  IECbusclk : process         -- IEC-bus clock signal (aka: serial bus)
  begin
  wait until rising_edge(clock_8MHz);
  if (serial_clk_out = '0') then  -- keep in mind that the signals are inverted by the open-collector buffer in the real VIC20
    IEC_CLOCK <= 'Z';      -- so that's what we do here as well. 'Z' simply means making the output high-impedance (floating), and the pull-up (as defined in the UCF) will make it a logic '1'
  else
    IEC_CLOCK <= '0';
  end if;
  end process;
  
  IECbusdat : process         -- IEC-bus data signal (aka: serial bus)
  begin
    wait until rising_edge(clock_8MHz);
    if (serial_data_out = '0') then  -- keep in mind that the signals are inverted by the open-collector buffer in the real VIC20
      IEC_DATA  <= 'Z';      -- so that's what we do here as well. 'Z' simply means making the output high-impedance (floating), and the pull-up (as defined in the UCF) will make it a logic '1'
    else
      IEC_DATA  <= '0';
    end if;
  end process;

  IEC_ATN <= not serial_atn_out;  -- the ATN signal is NOT a bidirectional signal, so this is easy programming. The inverting is required because in the real VIC20, this signal is buffered by an inverting buffer
  serial_clk_in <= IEC_CLOCK;
  serial_data_in <= IEC_DATA;
  serial_srq_in <= '0';  

  
  --
  --
  -- IO connect these to the outside world if you wish ...
  --
p_expansion : process(blk_sel_l, cart_data)
  begin
    expansion_din <= x"FF";
    if (blk_sel_l(5) = '0') then
      expansion_din <= cart_data;
    end if;
  end process;
  
  -- expansion port
  -- <= c_addr;
  -- <= c_rw_l;
  -- <= v_rw_l;
  expansion_nmi_l <= '1';
  expansion_irq_l <= '1';
  -- <= ram_sel_l;
  -- <= io_sel_l;
  -- <= reset_l_sampled;

  -- user port
  user_port_cb1_in <= '0';
  user_port_cb2_in <= '0';
  user_port_in <= x"00";
  -- <= user_port_out
  -- <= user_port_out_oe_l

  -- tape
  cass_read <= '0';
  --<= cass_write;
  --<= cass_motor
  cass_sw <= '1'; -- motor off



cpu : T65
    port map (
        Mode    => "00",
        Res_n   => auto_reset,
        Enable  => c_ena,
        Clk     => clock_8MHz,
        Rdy     => '1',
        Abort_n => '1',
        IRQ_n   => c_irq_l,
        NMI_n   => c_nmi_l,
        SO_n    => '1',
        R_W_n   => c_rw_l,
        Sync    => open,
        EF      => open,
        MF      => open,
        XF      => open,
        ML_n    => open,
        VP_n    => open,
        VDA     => open,
        VPA     => open,
        A       => c_addr,
        DI      => c_din,
        DO      => c_dout
    );

  vic : VIC20_VIC
    generic map (
      K_OFFSET        => K_OFFSET
      )
    port map (
      I_RW_L          => v_rw_l,

      I_ADDR          => v_addr(13 downto 0),
      O_ADDR          => vic_addr(13 downto 0),

      I_DATA          => vic_din,
      O_DATA          => vic_dout,
      O_DATA_OE_L     => vic_oe_l,
      --
      O_AUDIO         => vic_audio,

      O_VIDEO_R       => video_r,
      O_VIDEO_G       => video_g,
      O_VIDEO_B       => video_b,

      O_HSYNC         => hsync,
      O_VSYNC         => vsync,
      O_COMP_SYNC_L   => csync,
      O_BLANK         => blanking,
      --
      --
      I_LIGHT_PEN     => joy_fire,
      I_POTX          => '0',
      I_POTY          => '0',

      O_ENA_1MHZ      => ena_1mhz,
      O_P2_H          => p2_h,
      ENA_4           => ena_4,
      CLK             => clock_8MHz
      );

  via1 : M6522
    port map (
      I_RS            => c_addr(3 downto 0),
      I_DATA          => v_data(7 downto 0),
      O_DATA          => via1_dout,
      O_DATA_OE_L     => open,

      I_RW_L          => c_rw_l,
      I_CS1           => c_addr(4),
      I_CS2_L         => io_sel_l(0),

      O_IRQ_L         => via1_nmi_l, -- note, not open drain

      I_CA1           => keybd_restore,
      I_CA2           => cass_motor,
      O_CA2           => cass_motor,
      O_CA2_OE_L      => open,

      I_PA            => via1_pa_in,
      O_PA            => via1_pa_out,
      O_PA_OE_L       => open,

      -- port b
      I_CB1           => user_port_cb1_in,
      O_CB1           => user_port_cb1_out,
      O_CB1_OE_L      => user_port_cb1_oe_l,

      I_CB2           => user_port_cb2_in,
      O_CB2           => user_port_cb2_out,
      O_CB2_OE_L      => user_port_cb2_oe_l,

      I_PB            => user_port_in,
      O_PB            => user_port_out,
      O_PB_OE_L       => user_port_oe_l,

      I_P2_H          => p2_h,
      RESET_L         => auto_reset,
      ENA_4           => ena_4,
      CLK             => clock_8MHz
      );

  serial_atn_out <= via1_pa_out(7);
  via1_pa_in(7) <= via1_pa_out(7);
  via1_pa_in(6) <= cass_sw;
  via1_pa_in(5) <= joy_fire;	
  via1_pa_in(4) <= joy_down;
  via1_pa_in(3) <= joy_left;
  via1_pa_in(2) <= joy_right;
  via1_pa_in(1) <= serial_data_in;
  via1_pa_in(0) <= serial_clk_in;

via2 : M6522
  port map (
    I_RS            => c_addr(3 downto 0),
    I_DATA          => v_data(7 downto 0),
    O_DATA          => via2_dout,
    O_DATA_OE_L     => open,

    I_RW_L          => c_rw_l,
    I_CS1           => c_addr(5),
    I_CS2_L         => io_sel_l(0),

    O_IRQ_L         => via2_irq_l, -- note, not open drain

    I_CA1           => cass_read,
    I_CA2           => serial_clk_out,
    O_CA2           => serial_clk_out,
    O_CA2_OE_L      => open,

    I_PA            => keybd_row_in,
    O_PA            => open,
    O_PA_OE_L       => open,

    -- port b
    I_CB1           => serial_srq_in,
    O_CB1           => open,
    O_CB1_OE_L      => open,

    I_CB2           => serial_data_out,
    O_CB2           => serial_data_out,
    O_CB2_OE_L      => open,

    I_PB            => keybd_col_in,
    O_PB            => keybd_col_out,
    O_PB_OE_L       => keybd_col_oe_l,

    I_P2_H          => p2_h,
    RESET_L         => auto_reset,
    ENA_4           => ena_4,
    CLK             => clock_8MHz
    );

  p_keybd_col_in : process(keybd_col_out, keybd_col_oe_l, joy_up)
  begin
    for i in 0 to 6 loop
      keybd_col_in(i) <= keybd_col_out(i);
    end loop;

    if (keybd_col_oe_l(7) = '0') then
      keybd_col_in(7) <= keybd_col_out(7);
    else
      keybd_col_in(7) <= joy_up;
    end if;
  end process;
  cass_write <= keybd_col_out(3);

  keybd : VIC20_PS2_IF
    port map (
      I_PS2_CLK       => I_PS2_CLK,
      I_PS2_DATA      => I_PS2_DATA,

      I_COL           => keybd_col_out,
      O_ROW           => keybd_row_in,
      O_RESTORE       => keybd_restore,

      I_ENA_1MHZ      => ena_1mhz,
      I_P2_H          => p2_h,
      RESET_L         => auto_reset,
      ENA_4           => ena_4,
      CLK             => clock_8MHz
      );

  p_irq_resolve : process(expansion_irq_l, expansion_nmi_l,
                          via2_irq_l, via1_nmi_l)
  begin
    c_irq_l <= '1';
    if (expansion_irq_l = '0') or (via2_irq_l = '0') then
      c_irq_l <= '0';
    end if;

    c_nmi_l <= '1';
    if (expansion_nmi_l = '0') or (via1_nmi_l = '0') then
      c_nmi_l <= '0';
    end if;
  end process;

  --
  -- decode
  --
  p_io_addr_decode : process(c_addr)
  begin

    io_sel_l <= "1111";
    if (c_addr(15 downto 13) = "100") then -- blk4
      case c_addr(12 downto 10) is
        when "000" => io_sel_l <= "1111";
        when "001" => io_sel_l <= "1111";
        when "010" => io_sel_l <= "1111";
        when "011" => io_sel_l <= "1111";
        when "100" => io_sel_l <= "1110";
        when "101" => io_sel_l <= "1101"; -- col
        when "110" => io_sel_l <= "1011";
        when "111" => io_sel_l <= "0111";
        when others => null;
      end case;
    end if;
  end process;

  p_blk_addr_decode : process(c_addr)
  begin
    blk_sel_l <= "11111111";
    case c_addr(15 downto 13) is
      when "000" => blk_sel_l <= "11111110";
      when "001" => blk_sel_l <= "11111101";
      when "010" => blk_sel_l <= "11111011";
      when "011" => blk_sel_l <= "11110111";
      when "100" => blk_sel_l <= "11101111";
      when "101" => blk_sel_l <= "11011111"; -- Cart
      when "110" => blk_sel_l <= "10111111"; -- basic
      when "111" => blk_sel_l <= "01111111"; -- kernal
      when others => null;
    end case;
  end process;

  p_v_mux : process(c_addr, c_dout, c_rw_l, p2_h, vic_addr, v_data_read_mux,
                    blk_sel_l, io_sel_l)
  begin
    -- simplified data source mux
    if (p2_h = '0') then
      v_addr(13 downto 0) <= vic_addr(13 downto 0);
      v_data <= v_data_read_mux(7 downto 0);
      v_rw_l <= '1';
      col_ram_sel_l <= '1'; -- colour ram has dedicated mux for vic, so disable
    else -- cpu
      v_addr(13 downto 0) <= blk_sel_l(4) & c_addr(12 downto 0);
      v_data <= c_dout;
      v_rw_l <= c_rw_l;
      col_ram_sel_l <= io_sel_l(1);
    end if;

  end process;

  p_ram_addr_decode : process(v_addr, blk_sel_l, p2_h)
  begin
    ram_sel_l <= "11111111";
    if ((p2_h = '1') and (blk_sel_l(0) = '0')) or -- cpu
       ((p2_h = '0') and (v_addr(13) = '1')) then
      case v_addr(12 downto 10) is
        when "000" => ram_sel_l <= "11111110";
        when "001" => ram_sel_l <= "11111101";
        when "010" => ram_sel_l <= "11111011";
        when "011" => ram_sel_l <= "11110111";
        when "100" => ram_sel_l <= "11101111";
        when "101" => ram_sel_l <= "11011111";
        when "110" => ram_sel_l <= "10111111";
        when "111" => ram_sel_l <= "01111111";
        when others => null;
      end case;
    end if;
  end process;

  p_vic_din_mux : process(p2_h, col_ram_dout, v_data)
  begin
    if (p2_h = '0') then
      vic_din(11 downto 8) <= col_ram_dout(3 downto 0);
    else
      vic_din(11 downto 8) <= v_data(3 downto 0);
    end if;

    vic_din(7 downto 0) <= v_data(7 downto 0);
  end process;

  p_v_read_mux : process(col_ram_sel_l, ram_sel_l, vic_oe_l, v_addr,
                         col_ram_dout, ram0_dout, ram45_dout, ram67_dout,
                         vic_dout, char_rom_dout, 
                         v_data_read_muxr)
  begin
    -- simplified data read mux
    -- nasty if statement but being lazy
    -- these are exclusive, but the tools may not spot this.

    v_data_oe_l <= '1';
    if (col_ram_sel_l = '0') then
      v_data_read_mux <= "0000" & col_ram_dout(3 downto 0);
      v_data_oe_l     <= '0';
    elsif (vic_oe_l = '0') then
      v_data_read_mux <= vic_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(0) = '0') then
      v_data_read_mux <= ram0_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(4) = '0') then
      v_data_read_mux <= ram45_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(5) = '0') then
      v_data_read_mux <= ram45_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(6) = '0') then
      v_data_read_mux <= ram67_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(7) = '0') then
      v_data_read_mux <= ram67_dout;
      v_data_oe_l     <= '0';
    elsif (v_addr(13 downto 12) = "00") then
      v_data_read_mux <= char_rom_dout;
      v_data_oe_l     <= '0';
    else
      -- emulate floating bus
      --v_data_read_mux <= "XXXXXXXX";
      v_data_read_mux <= v_data_read_muxr;
    end if;

  end process;

  p_v_bus_hold : process
  begin
    wait until rising_edge(clock_8MHz);
    if (ena_4 = '1') then
      v_data_read_muxr <= v_data_read_mux;
    end if;
  end process;

  p_cpu_read_mux : process(p2_h, c_addr, io_sel_l, ram_sel_l, blk_sel_l, 
                           v_data_read_mux, via1_dout, via2_dout, v_data_oe_l, 
                           basic_rom_dout, kernal_rom_dout, expansion_din)
  begin
    if (p2_h = '0') then -- vic is on the bus
      --c_din <= "XXXXXXXX";
      c_din <= "00000000";
    elsif (io_sel_l(0) = '0') and (c_addr(4) = '1') then -- blk4
      c_din <= via1_dout;
    elsif (io_sel_l(0) = '0') and (c_addr(5) = '1') then -- blk4
      c_din <= via2_dout;
    elsif (blk_sel_l(5) = '0') then
      c_din <= expansion_din;
    elsif (blk_sel_l(6) = '0') then
      c_din <= basic_rom_dout;
    elsif (blk_sel_l(7) = '0') then
      c_din <= kernal_rom_dout;
    elsif (v_data_oe_l = '0') then
      c_din <= v_data_read_mux;
    else
      c_din <= "11111111";
    end if;
  end process;

  -- main memory
  we0 <= not ram_sel_l(0) and not v_rw_l ; 
 
  rams0 : Gowin_SP_1kb
      port map (
          dout   => ram0_dout,
          clk    => clock_8MHz,
          oce    => '1',
          ce     => ena_4, 
          reset  => not auto_reset,
          wre    => we0, 
          ad     => v_addr(9 downto 0),
          din    => v_data
      );

  we1 <= ((not ram_sel_l(4)) or (not ram_sel_l(5))) and (not v_rw_l );

  rams45 : Gowin_SP_2kb 
    port map (
          dout   => ram45_dout,
          clk    => clock_8MHz,
          oce    => '1',
          ce     => ena_4, 
          reset  => not auto_reset,
          wre    => we1,
          ad     => v_addr(10 downto 0),
          din    => v_data
    );

  we2 <= ((not ram_sel_l(6)) or (not ram_sel_l(7))) and (not v_rw_l );

  rams67 : Gowin_SP_2kb 
      port map (
          dout   => ram67_dout,
          clk    => clock_8MHz,
          oce    => '1',
          ce     => ena_4, 
          reset  => not auto_reset,
          wre    => we2,
          ad     => v_addr(10 downto 0),
          din    => v_data
      );

  we3 <= not col_ram_sel_l and not v_rw_l ;

col_ram: Gowin_SP_1kb
    port map (
      dout  => col_ram_dout,
      clk   => clock_8MHz,
      oce   => '1',
      ce    => ena_4,  
      reset => not auto_reset,
      wre   => we3,
      ad    => v_addr(9 downto 0),
      din   => v_data
    );

    -- VIC20's character ROM
  char_rom : Gowin_pROM_char
      port map (
          dout  => char_rom_dout,
          clk   => clock_8MHz,
          oce   => '1',
          ce    => ena_4,
          reset => not auto_reset,
          ad    => v_addr(11 downto 0)
      );

  -- VIC20's basic ROM
  basic_rom : Gowin_pROM_basic
      port map (
          dout  => basic_rom_dout,
          clk   => clock_8MHz,
          oce   => '1',
          ce    => ena_4,
          reset => not auto_reset,
          ad    => c_addr(12 downto 0)
      );

  -- VIC20's kernal ROM
  kernal_rom : Gowin_pROM_kernal
    port map (
          dout  => kernal_rom_dout,
          clk   => clock_8MHz,
          oce   => '1',
          ce    => ena_4,
          reset => not auto_reset,
          ad    => c_addr(12 downto 0)
    );

  u_dblscan : VIC20_DBLSCAN
    port map (
      I_R               => video_r,
      I_G               => video_g,
      I_B               => video_b,
      I_HSYNC           => hsync,
      I_VSYNC           => vsync,
      --
      O_R               => O_VIDEO_R(3 downto 0),
      O_G               => O_VIDEO_G(3 downto 0),
      O_B               => O_VIDEO_B(3 downto 0),
      O_HSYNC           => O_HSYNC,
      O_VSYNC           => O_VSYNC,
      LCD_DEN           => LCD_DEN,
      LCD_CLK           => LCD_CLK,
      --
      ENA               => ena_4,
      reset_n           => auto_reset,
      PixelClk          => clock_35MHz,
      CLK               => clock_8MHz
    );
  
    O_VIDEO_R(4)          <= O_VIDEO_R(3);
    O_VIDEO_G(5)          <= O_VIDEO_G(3);
    O_VIDEO_G(4)          <= O_VIDEO_G(3);
    O_VIDEO_B(4)          <= O_VIDEO_B(3);

  u_dac : dac
    generic map(
      msbi_g => 3
    )
    port  map(
      clk_i   => clock_35MHz,
      res_n_i => auto_reset,
      dac_i   => vic_audio,
      dac_o   => O_AUDIO
    );

  --
  -- cart slot 0xA000-0xBFFF (8K)
  --
cart: Gowin_pROM
    port map (
        dout  => cart_data,
        clk   => clock_8MHz,
        oce   => '1',
        ce    => ena_4,
        reset => not User_Button_n,
--        reset =>  auto_reset,
        ad    => c_addr(12 downto 0)
    );

end RTL;
