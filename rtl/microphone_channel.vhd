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
        g_PHI          : real := 0.0;
        g_THETA        : real := 0.0; --Pi Radians
        g_MIC_BITDEPTH : integer := 24
    );
    Port ( 
        i_clk     : in STD_LOGIC;
        i_pdm     : in STD_LOGIC;       
        o_output  : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
    );
end microphone_channel;

architecture Behavioral of microphone_channel is
    component cic_decimation is
        port (
            i_clk       : in std_logic;
            i_CIC_IN    : in std_logic;
            o_clk_dec   : out std_logic;
            o_CIC_OUT   : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
        );
    end component cic_decimation;

    -- component fir_filter is
    --     generic (
    --         g_BITDEPTH : integer
    --     );
    --     port (
    --         i_clk          : in std_logic;
    --         i_SIGNAL_IN    : in std_logic_vector(23 downto 0);
    --         o_SIGNAL_OUT   : out std_logic_vector(23 downto 0)
    --     );
    -- end component fir_filter;

    component fir_filter_mul_mux is
        generic (
            g_BITDEPTH : integer
        );
        port (
            i_clk          : in std_logic;
            i_clk_div      : in std_logic;
            i_SIGNAL_IN    : in std_logic_vector(23 downto 0);
            o_SIGNAL_OUT   : out std_logic_vector(23 downto 0)
        );
    end component fir_filter_mul_mux;

    signal r_cic_output         : std_logic_vector(23 downto 0) := (others => '0');
    signal r_fir_output         : std_logic_vector(23 downto 0) := (others => '0');
    signal r_fir_mul_mux_output : std_logic_vector(23 downto 0) := (others => '0');
    signal r_dec_clk    : std_logic := '0';

begin
    cic_decimation_inst : cic_decimation
        port map (
            i_clk       => i_clk,
            i_CIC_IN    => i_pdm,
            o_clk_dec   => r_dec_clk,
            o_CIC_OUT   => r_cic_output
        );

    -- fir_filter_inst : fir_filter
    --     generic map(
    --         g_BITDEPTH => g_MIC_BITDEPTH
    --     )
    --     port map (
    --         i_clk        => r_dec_clk,
    --         i_SIGNAL_IN  => r_cic_output,
    --         o_SIGNAL_OUT => r_fir_output
    --     );

    fir_filter_mul_mux_inst : fir_filter_mul_mux
        generic map(
            g_BITDEPTH => g_MIC_BITDEPTH
        )
        port map (
            i_clk        => i_clk,
            i_clk_div    => r_dec_clk,
            i_SIGNAL_IN  => r_cic_output,
            o_SIGNAL_OUT => r_fir_mul_mux_output
        );

    o_output <= r_fir_mul_mux_output;
end Behavioral;
