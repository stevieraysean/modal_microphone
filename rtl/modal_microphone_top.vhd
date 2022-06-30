----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2022 09:21:13 AM
-- Design Name: 
-- Module Name: modal_microphone_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.data_types.ALL;

entity modal_microphone_top is
    Generic( 
        g_MIC_BITDEPTH : integer := 24
    );
    Port ( 
        i_clock     : in STD_LOGIC;
        i_clock_div : in STD_LOGIC;
        i_pdm_in     : in std_logic_vector(1 downto 0);       
        o_output_mode1  : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0);
        o_output_mode2  : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
    );
end modal_microphone_top;

architecture Behavioral of modal_microphone_top is

    component microphone_channel is
        port (
            i_clk     : in std_logic;
            i_clk_div : in std_logic;
            i_pdm     : in std_logic;
            o_output  : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
        );
    end component microphone_channel;

    signal out1 : std_logic_vector(g_MIC_BITDEPTH-1 downto 0) := (others => '0');
    signal out2 : std_logic_vector(g_MIC_BITDEPTH-1 downto 0) := (others => '0');

begin

    microphone_channel_inst_1 : microphone_channel
        port map (
            i_clk     => i_clock,
            i_clk_div => i_clock_div,
            i_pdm     => i_pdm_in(0),
            o_output  => out1
        );
    
    microphone_channel_inst_2 : microphone_channel
        port map (
            i_clk     => i_clock,
            i_clk_div => i_clock_div,
            i_pdm     => i_pdm_in(1),
            o_output  => out2
        );

    o_output_mode1 <= out1;
    o_output_mode2 <= out2;
    
end Behavioral;
