----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2022 09:21:13 AM
-- Design Name: 
-- Module Name: microphone_channel - Behavioral
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

entity microphone_channel is
    Generic( 
        g_MIC_BITDEPTH : integer := 24
    );
    Port ( 
        i_clk_768e5     : in STD_LOGIC;
        i_clk_3072e3_en : in STD_LOGIC;
        i_clk_192e3_en  : in STD_LOGIC;
        i_pdm           : in STD_LOGIC;       
        o_output        : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
    );
end microphone_channel;

architecture Behavioral of microphone_channel is
    component cic_decimation is
        port (
            i_clk_768e5     : in std_logic;
            i_clk_3072e3_en : in std_logic;
            i_clk_192e3_en  : in std_logic;
            i_cic_in        : in std_logic;
            o_cic_out       : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
        );
    end component cic_decimation;

    component fir_filter_mul_mux is
        generic (
            g_BITDEPTH : integer;
            g_COEFFICIENTS : array_of_integers
        );
        port (
            i_clk_768e5    : in std_logic;
            i_clk_192e3_en : in std_logic;
            i_signal_in    : in std_logic_vector(23 downto 0);
            o_signal_out   : out std_logic_vector(23 downto 0)
        );
    end component fir_filter_mul_mux;

    signal r_cic_output         : std_logic_vector(23 downto 0) := (others => '0');
    signal r_fir_output         : std_logic_vector(23 downto 0) := (others => '0');
    signal r_fir_mul_mux_output : std_logic_vector(23 downto 0) := (others => '0');
    signal r_dec_clk            : std_logic := '0';

begin
    cic_decimation_inst : cic_decimation
        port map (
            i_clk_768e5     => i_clk_768e5,
            i_clk_3072e3_en => i_clk_3072e3_en,
            i_clk_192e3_en  => i_clk_192e3_en,
            i_cic_in        => i_pdm,
            o_cic_out       => r_cic_output
        );

    fir_filter_mul_mux_inst : fir_filter_mul_mux
        generic map(
            g_BITDEPTH => g_MIC_BITDEPTH,
            -- CIC Compensator, Fpb = 24kHz
            -- TODO: check/revisit coefficients. lots of PB ripple..
            g_COEFFICIENTS => (-1678,-2517,-2517,838,7549,13421,14260,6710,-5873,-16778,-15939,-839,20132,31037,19293,-11745,-41105,-44460,-11745,38587,69625,51170,-14261,-83048,-99825,-37749,69625,144284,117440,-13422,-164417,-216427,-99825,130862,317089,290245,5872,-389232,-607336,-387554,332188,1332110,2201170,2544264,2201170,1332110,332188,-387554,-607336,-389232,5872,290245,317089,130862,-99825,-216427,-164417,-13422,117440,144284,69625,-37749,-99825,-83048,-14261,51170,69625,38587,-11745,-44460,-41105,-11745,19293,31037,20132,-839,-15939,-16778,-5873,6710,14260,13421,7549,838,-2517,-2517,-1678)
        )
        port map (
            i_clk_768e5  => i_clk_768e5,
            i_clk_192e3_en  => i_clk_192e3_en,
            i_signal_in  => r_cic_output,
            o_signal_out => r_fir_mul_mux_output
        );

    o_output <= r_fir_mul_mux_output;
end Behavioral;
