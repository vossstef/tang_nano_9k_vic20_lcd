--Copyright (C)2014-2022 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: IP file
--GOWIN Version: V1.9.8.09 Education
--Part Number: GW1NR-LV9QN88PC6/I5
--Device: GW1NR-9C
--Created Time: Fri Jan 20 20:51:19 2023

library IEEE;
use IEEE.std_logic_1164.all;

entity Gowin_CLKDIV_2 is
    port (
        clkout: out std_logic;
        hclkin: in std_logic;
        resetn: in std_logic
    );
end Gowin_CLKDIV_2;

architecture Behavioral of Gowin_CLKDIV_2 is

    signal gw_gnd: std_logic;

    --component declaration
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

begin
    gw_gnd <= '0';

    clkdiv_inst: CLKDIV
        generic map (
            DIV_MODE => "2",
            GSREN => "false"
        )
        port map (
            CLKOUT => clkout,
            HCLKIN => hclkin,
            RESETN => resetn,
            CALIB => gw_gnd
        );

end Behavioral; --Gowin_CLKDIV_2