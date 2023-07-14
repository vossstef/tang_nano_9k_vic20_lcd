--Copyright (C)2014-2022 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--GOWIN Version: V1.9.8.09 Education
--Part Number: GW1NR-LV9QN88PC6/I5
--Device: GW1NR-9C
--Created Time: Fri Jan 13 22:36:49 2023

--Change the instance name and port connections to the signal names
----------Copy here to design--------

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

your_instance_name: Gowin_SP_1kb
    port map (
        dout => dout_o,
        clk => clk_i,
        oce => oce_i,
        ce => ce_i,
        reset => reset_i,
        wre => wre_i,
        ad => ad_i,
        din => din_i
    );

----------Copy end-------------------
