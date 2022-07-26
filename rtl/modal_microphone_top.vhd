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
        g_NUMBER_MICS         : integer := 1
        );
    Port ( 
        i_clock     : in STD_LOGIC;
        -- i_pdm_in    : in STD_LOGIC;    --TODO: input array for mics
        i_pdm_in    : in std_logic_vector(g_NUMBER_MICS-1 downto 0);       --TODO: input array for mics
        o_output    : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
    );
end modal_microphone_top;

architecture Behavioral of modal_microphone_top is

    constant c_CLOCK_FREQ_HZ     : real := 384000000.0;
    constant c_CLOCK_3072E3_DIV  : integer := 125;  -- 384MHz to 3.072MHz
    constant c_CLOCK_192E3_DIV   : integer := 2000; -- 384MHz to 192kHz
    constant c_CLOCK_PERIOD      : real := (1.0 / c_CLOCK_FREQ_HZ);
    constant c_CLOCK_PERIOD_HALF : time := (c_CLOCK_PERIOD / 2) * 1 sec;
    constant c_CLOCK_DIV_PERIOD  : real := (c_CLOCK_3072E3_DIV *1.0) / c_CLOCK_FREQ_HZ;
    
    component clk_wiz_0
        port(
            clk_out1          : out    std_logic;
            reset             : in     std_logic;
            locked            : out    std_logic;
            clk_in1           : in     std_logic
        );
    end component;

    -- component clk_wiz_1
    --     port(
    --         clk_out1          : out    std_logic;
    --         clk_out2          : out    std_logic;
    --         reset             : in     std_logic;
    --         locked            : out    std_logic;
    --         i_clk_384e6       : in     std_logic
    --     );
    -- end component;

    component microphone_channel is
        port (
            i_clk_384e6  : in STD_LOGIC;
            i_clk_3072e3_en : in STD_LOGIC;
            i_clk_192e3_en  : in STD_LOGIC;
            i_pdm        : in std_logic;
            o_output     : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
        );
    end component microphone_channel;

    signal mic_outs : array_of_std_logic_vector(g_NUMBER_MICS-1 downto 0);
    signal mode_output : signed((g_MIC_BITDEPTH)-1 downto 0) := (others => '0');

    signal r_clk_384e6        : std_logic;
    signal r_clk_3072e2        : std_logic;
    signal r_clk_384e6_reset  : std_logic := '0';
    signal r_clk_384e6_locked : std_logic;

    signal r_clk_3072e3_en       : std_logic := '0';
    signal r_clk_192e3_en        : std_logic := '0';

    signal r_clk_2_reset  : std_logic := '0';
    signal r_clk_2_locked : std_logic;

    signal r_clk_3072e3_count : integer   := 0;
    signal r_clk_192e3_count  : integer   := 0;

begin
    
    r_clk_3072e2 <= i_clk_3072e2;


    clk_wiz_0_inst : clk_wiz_0
        port map ( 
            clk_out1 => r_clk_384e6,
            reset    => r_clk_384e6_reset,
            locked   => r_clk_384e6_locked,
            clk_in1  => i_clock
        );


    process (r_clk_384e6)
    begin
        if rising_edge(r_clk_384e6) then
            r_clk_3072e3_count <= r_clk_3072e3_count + 1;

            if r_clk_3072e3_count = c_CLOCK_3072E3_DIV-1 then
                r_clk_3072e3_en <= '1';
                r_clk_3072e3_count <= 0;
            else
                --if r_clk_3072e3_en_count = (c_CLOCK_3072E3_DIV-1)/2 then
                r_clk_3072e3_en <= '0';
                --end if;
                r_clk_3072e3_count <= r_clk_3072e3_count + 1;
            end if;
        end if;
    end process;


    process (r_clk_384e6)
    begin
        if rising_edge(r_clk_384e6) then
            r_clk_192e3_count <= r_clk_192e3_count + 1;

            if r_clk_192e3_count = c_CLOCK_192E3_DIV-1 then
                r_clk_192e3_en <= '1';
                r_clk_192e3_count <= 0;
            else
                -- if r_clk_192e3_en_count = (c_CLOCK_192E3_DIV-1)/2 then
                r_clk_192e3_en <= '0';
                -- end if;
                r_clk_192e3_count <= r_clk_192e3_count + 1;
            end if;
        end if;
    end process;


    g_GEN_MICS: for mic in 0 to g_NUMBER_MICS-1 generate
    microphone_channel_inst_1 : microphone_channel
        port map (
            i_clk_384e6  => r_clk_384e6,
            i_clk_3072e3_en => r_clk_3072e3_en,
            i_clk_192e3_en  => r_clk_192e3_en,
            i_pdm        => i_pdm_in(mic),
            o_output     => mic_outs(mic)
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
