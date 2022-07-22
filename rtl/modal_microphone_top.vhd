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
        g_MIC_BITDEPTH        : integer := 24;
        g_ORDER               : integer := 2;
        g_NUMBER_MICS         : integer := 20
        --g_SPHERICAL_HARMONICS : array_of_integers :=    
        );
    Port ( 
        i_clock     : in STD_LOGIC;
        i_clock_div : in STD_LOGIC;
        i_pdm_in    : in std_logic_vector(g_NUMBER_MICS-1 downto 0);       
        o_output    : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
    );
end modal_microphone_top;

architecture Behavioral of modal_microphone_top is

    component microphone_channel is
        port (
            i_clk     : in std_logic;
            i_clk_div : in std_logic;
            --i_clk_cic : in std_logic;
            i_pdm     : in std_logic;
            o_output  : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
        );
    end component microphone_channel;

    signal mic_outs : array_of_std_logic_vector(g_NUMBER_MICS-1 downto 0);
    signal mode_output : signed((g_MIC_BITDEPTH)-1 downto 0) := (others => '0');

begin

    g_GEN_MICS: for mic in 0 to g_NUMBER_MICS-1 generate
    microphone_channel_inst_1 : microphone_channel
        port map (
            i_clk     => i_clock,
            i_clk_div => i_clock_div,
            i_pdm     => i_pdm_in(mic),
            o_output  => mic_outs(mic)
        );
    end generate g_GEN_MICS;

    process(mic_outs)
        variable sum : signed((g_MIC_BITDEPTH*2)-1 downto 0) := (others => '0');
    begin
        --if rising_edge(i_clock_div) then
            sum := (others => '0');
            
            for mic in 0 to g_NUMBER_MICS-1 loop
                sum := signed(mic_outs(mic)) + sum;
            end loop;
            -- mode_output <= signed(mic_outs(0)) + signed(mic_outs(1)) + signed(mic_outs(2)) + signed(mic_outs(3)) + signed(mic_outs(4)) + signed(mic_outs(5));

            -- o_output <= std_logic_vector(mode_output);
            o_output <= std_logic_vector(sum(g_MIC_BITDEPTH-1downto 0));

        --end if;
    end process;


end Behavioral;
