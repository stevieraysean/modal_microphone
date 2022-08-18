----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Sean Pierce
-- 
-- Create Date: 02/23/2022 08:52:22 PM
-- Design Name: 
-- Module Name: r_pdm_sigma_delta - Behavioral
-- Project Name: Modal Microphone
-- Target Devices: Arty-A7 35T
-- Tool Versions: 
-- Description: 
--     Takes a 1-bit Pulse-Desity-Modulated stream and converts it back to 
--     a signed 24-bit, 1/64 sample rate signal, using a Cascaded Integrating
--     Comb (CIC) Filter.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity cic_decimation is
    generic (
        g_INPUT_BITDEPTH     : integer := 2;
        g_STAGES             : integer := 6;
        g_DECIMATION_RATE    : integer := 16;
        g_DIFFERENTIAL_DELAY : integer := 1;
        g_OUTPUT_BITDEPTH    : integer := 24
        );
    port ( 
        i_clk_768e5     : in std_logic;
        i_clk_3072e3_en : in std_logic;
        i_clk_192e3_en  : in std_logic;
        i_cic_in        : in std_logic;
        o_cic_out       : out std_logic_vector(g_OUTPUT_BITDEPTH-1 downto 0) := (others => '0')
        );
end cic_decimation;

architecture Behavioral of cic_decimation is

    constant c_CIC_BIT_DEPTH          : integer := integer( ceil(real(g_STAGES) * 
        LOG2(real(g_DECIMATION_RATE * g_DIFFERENTIAL_DELAY)) + real(g_INPUT_BITDEPTH)));

    constant c_CIC_REG_MAX            : integer := c_CIC_BIT_DEPTH - 1;
    
    type t_cic_stage_array is array (0 to g_STAGES-1) of signed(c_CIC_REG_MAX downto 0);
    type t_comb_delay_array is array (0 to g_STAGES-1, 0 to g_DIFFERENTIAL_DELAY-1) of signed(c_CIC_REG_MAX downto 0);
    
    signal w_integrators       : t_cic_stage_array := (others => to_signed(0, (c_CIC_BIT_DEPTH)));
    signal w_combs             : t_cic_stage_array := (others => to_signed(0, (c_CIC_BIT_DEPTH)));

    signal r_integrator_delays : t_cic_stage_array := (others => to_signed(0, (c_CIC_BIT_DEPTH)));
    signal r_comb_delays       : t_comb_delay_array := (others => (others => to_signed(0, (c_CIC_BIT_DEPTH))));
    signal r_pdm_buff1         : std_logic := '0';
    signal r_pdm_buff2         : std_logic := '0';
    signal r_pdm               : signed(1 downto 0):= (others => '0');
    signal r_decimator_counter : unsigned(6 downto 0) := (others => '0');
    signal r_decimator_clk     : std_logic := '0';
    signal r_decimated_signal  : signed(c_CIC_REG_MAX downto 0) := (others => '0');
    signal r_rounded_out       : std_logic_vector(7 downto 0);

begin
    -- PDM Input
    process_r_pdm : PROCESS (i_clk_768e5)
    begin
        if rising_edge(i_clk_768e5) then
            if i_clk_3072e3_en = '1' then
                r_integrator_delays(0) <= w_integrators(0);
            end if;
            -- r_pdm_buff2 <= i_cic_in;
            -- cast PDM 0/1 input to -1/1
            if i_cic_in = '1' then
                r_pdm <= to_signed(1, (2));   
            else
                r_pdm <= to_signed(-1, (2));
            end if;
        end if;
    end process;

    w_integrators(0) <= r_integrator_delays(0) + r_pdm;
    -- Integration Stages
    g_GENERATE_w_integrators: for stage in 1 to g_STAGES-1 generate
        process_integrator : PROCESS (i_clk_768e5)
        begin
            if rising_edge(i_clk_768e5) then 
                if i_clk_3072e3_en = '1' then
                    r_integrator_delays(stage) <= w_integrators(stage);
                end if;
            end if;
        end process;
        w_integrators(stage) <= r_integrator_delays(stage) + w_integrators(stage-1);
    end generate g_GENERATE_w_integrators; 

    -- Decimation
    process_decimated_signals : PROCESS (i_clk_768e5)
    begin
        if rising_edge(i_clk_768e5) and i_clk_192e3_en = '1' then
            r_decimated_signal <= w_integrators(g_STAGES-1);
        end if;
    end process;

    -- Comb Filters Stage
    w_combs(0) <= r_decimated_signal - r_comb_delays(0, g_DIFFERENTIAL_DELAY-1 );
    g_GENERATE_w_combs: for stage in 1 to g_STAGES-1 generate
        w_combs(STAGE) <= w_combs(stage-1) - r_comb_delays(stage, g_DIFFERENTIAL_DELAY-1);
    end generate g_GENERATE_w_combs; 

    process_comb_delays : PROCESS (i_clk_768e5)
    begin
        if rising_edge(i_clk_768e5) then 
            if i_clk_192e3_en = '1' then
                for stage in 0 to g_STAGES-1 loop
                    if stage = 0 then
                        for delay in 0 to g_DIFFERENTIAL_DELAY-1 loop
                            if delay = 0 then
                                r_comb_delays(stage, delay) <= r_decimated_signal;
                            else
                                r_comb_delays(stage, delay) <= r_comb_delays(stage, delay-1);
                            end if;
                        end loop;
                    else
                        for delay in 0 to g_DIFFERENTIAL_DELAY-1 loop
                            if delay = 0 then
                                r_comb_delays(stage, delay) <= w_combs(stage-1);
                            else
                                r_comb_delays(stage, delay) <= r_comb_delays(stage, delay-1);
                            end if;
                        end loop;
                    end if;
                end loop;
            end if;
        end if;
    end process;
    -- CIC Filter Output
    -- grab the MSB's of the last comb stage
    -- TODO: Rounding, calc bit growth etc..
    --r_rounded_out <= (c_CIC_BIT_DEPTH-1 to 4 => w_combs(g_STAGES-1)(10), others => not w_combs(g_STAGES-1)(10));

    o_cic_out <= std_logic_vector(w_combs(g_STAGES-1)(c_CIC_BIT_DEPTH - 1 downto c_CIC_BIT_DEPTH - g_OUTPUT_BITDEPTH));
    -- o_cic_out <= std_logic_vector(w_combs(g_STAGES-1)(c_CIC_BIT_DEPTH - 1 downto 0));
end Behavioral;
