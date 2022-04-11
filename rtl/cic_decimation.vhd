----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity cic_decimation is
    generic (
        g_INPUT_BITDEPTH     : integer := 1;
        g_STAGES             : integer := 6;
        g_DECIMATION_RATE    : integer := 16;
        g_DIFFERENTIAL_DELAY : integer := 1;
        g_OUTPUT_BITDEPTH    : integer := 24
        );
    port ( 
        i_clk     : in STD_LOGIC;
        i_CIC_IN  : in STD_LOGIC;
        o_clk_dec : out STD_LOGIC;
        o_CIC_OUT : out STD_LOGIC_VECTOR(g_OUTPUT_BITDEPTH-1 downto 0) := (others => '0');
        o_CIC_OUT_RND : out STD_LOGIC_VECTOR(g_OUTPUT_BITDEPTH-1 downto 0) := (others => '0')
        );
end cic_decimation;

architecture Behavioral of cic_decimation is

    constant c_CIC_BIT_DEPTH          : integer := integer( ceil(real(g_STAGES) * 
        LOG2(real(g_DECIMATION_RATE * g_DIFFERENTIAL_DELAY)) + real(g_INPUT_BITDEPTH )));
    constant c_CIC_REG_MAX            : integer := c_CIC_BIT_DEPTH - 1;
    
    type t_cic_stage_array is array (0 to g_STAGES-1) of signed(c_CIC_REG_MAX downto 0);
    type t_comb_delay_array is array (0 to g_STAGES-1, 0 to g_DIFFERENTIAL_DELAY-1) of signed(c_CIC_REG_MAX downto 0);
    
    signal w_integrators       : t_cic_stage_array := (others => to_signed(0, (c_CIC_BIT_DEPTH)));
    signal w_combs             : t_cic_stage_array := (others => to_signed(0, (c_CIC_BIT_DEPTH)));

    signal r_integrator_delays : t_cic_stage_array := (others => to_signed(0, (c_CIC_BIT_DEPTH)));
    signal r_comb_delays       : t_comb_delay_array := (others => (others => to_signed(0, (c_CIC_BIT_DEPTH))));
    signal r_pdm_buff          : std_logic := '0';
    signal r_pdm               : signed(c_CIC_REG_MAX downto 0):= (others => '0');
    signal r_decimator_counter : unsigned(6 downto 0) := (others => '0');
    signal r_decimator_clk     : std_logic := '0';
    signal r_decimated_signal  : signed(c_CIC_REG_MAX downto 0) := (others => '0');

    signal rounded      : signed(c_CIC_REG_MAX downto 0) := (others => '0');
    signal round_vector : signed(c_CIC_REG_MAX downto 0) := (others => '0');

begin
    -- PDM Input
    process_r_pdm : PROCESS (i_clk)
    begin
        if (i_clk'event and i_clk = '1') then
            -- cast PDM 0/1 input to -1/1
            -- TODO: double buffer?
            r_pdm_buff <= i_CIC_IN;

            if (r_pdm_buff = '1') then
                r_pdm <= to_signed(1, (c_CIC_BIT_DEPTH));
            else
                r_pdm <= to_signed(-1, (c_CIC_BIT_DEPTH));
            end if;

            r_integrator_delays(0) <= w_integrators(0);
        end if;
    end process;

    w_integrators(0) <= r_integrator_delays(0) + r_pdm;

    -- Integration Stages
    g_GENERATE_w_integrators: for STAGE in 1 to g_STAGES-1 generate
        process_integrator : PROCESS (i_clk)
        begin
            if (i_clk'event and i_clk = '1') then
                r_integrator_delays(STAGE) <= w_integrators(STAGE);
            end if;
        end process;
        w_integrators(STAGE) <= r_integrator_delays(STAGE) + w_integrators(STAGE-1);
    end generate g_GENERATE_w_integrators; 

    -- Decimation Stage
    process_decimator_clock : PROCESS (i_clk)
    begin
        if (i_clk'event and i_clk = '1') then
            r_decimator_counter <= r_decimator_counter + 1;

            if (r_decimator_counter = g_DECIMATION_RATE) then
                r_decimator_counter <= "0000001";
                r_decimator_clk <= '1';
            end if;
            if (r_decimator_counter = g_DECIMATION_RATE/2) then
                r_decimator_clk <= '0';
            end if;
        end if;
    end process;

    process_decimated_signals : PROCESS (r_decimator_clk)
    begin
        if (r_decimator_clk'event and r_decimator_clk = '1') then
            r_decimated_signal <= w_integrators(g_STAGES-1);
        end if;
    end process;

    -- Comb Filters
    w_combs(0) <= r_decimated_signal - r_comb_delays(0, g_DIFFERENTIAL_DELAY-1 );
    g_GENERATE_w_combs: for STAGE in 1 to g_STAGES-1 generate
        w_combs(STAGE) <= w_combs(STAGE-1) - r_comb_delays(STAGE, g_DIFFERENTIAL_DELAY-1);
    end generate g_GENERATE_w_combs; 

    process_comb_delays : PROCESS (r_decimator_clk)
    begin
        if (r_decimator_clk'event and r_decimator_clk = '1') then
            for STAGE in 0 to g_STAGES-1 loop
                if (STAGE = 0) then
                    for DEL in 0 to g_DIFFERENTIAL_DELAY-1 loop
                        if DEL = 0 then
                            r_comb_delays(STAGE, DEL) <= r_decimated_signal;
                        else
                            r_comb_delays(STAGE, DEL) <= r_comb_delays(STAGE, DEL-1);
                        end if;
                    end loop;
                else
                    for DEL in 0 to g_DIFFERENTIAL_DELAY-1 loop
                        if DEL = 0 then
                            r_comb_delays(STAGE, DEL) <= w_combs(STAGE-1);
                        else
                            r_comb_delays(STAGE, DEL) <= r_comb_delays(STAGE, DEL-1);
                        end if;
                    end loop;
                end if;
            end loop;
        end if;
    end process;

    o_clk_dec <= r_decimator_clk;
    -- CIC Filter Output
    -- grab the MSB's of the last comb stage
    
    
    --c_CIC_BIT_DEPTH-g_OUTPUT_BITDEPTH-1
    
    -- TODO: Rounding, calc bit growth etc..

    round_vector <= (c_CIC_BIT_DEPTH-1 downto c_CIC_BIT_DEPTH-g_OUTPUT_BITDEPTH => '0') & (w_combs(g_STAGES-1)(c_CIC_BIT_DEPTH-g_OUTPUT_BITDEPTH-1));-- &(not (w_combs(g_STAGES-1)(c_CIC_BIT_DEPTH-g_OUTPUT_BITDEPTH-1))); --(25-24)-1 => std_logic(w_combs(g_STAGES-1)(25-24-1)) , (25-24-1 downto 0) => not std_logic(w_combs(g_STAGES-1)(25-24-1)));

    rounded <= (w_combs(g_STAGES-1)(c_CIC_BIT_DEPTH - 1 downto 0) + round_vector);
    
        -- std_logic_vector(c_CIC_BIT_DEPTH to (c_CIC_BIT_DEPTH-g_OUTPUT_BITDEPTH) => '0', (c_CIC_BIT_DEPTH-g_OUTPUT_BITDEPTH)-1 => w_combs(g_STAGES-1) , (c_CIC_BIT_DEPTH-g_OUTPUT_BITDEPTH-1 downto 0) => not std_logic(w_combs(g_STAGES-1)));


    o_CIC_OUT_RND <= STD_LOGIC_VECTOR(rounded(c_CIC_BIT_DEPTH - 1 downto c_CIC_BIT_DEPTH - g_OUTPUT_BITDEPTH));

    o_CIC_OUT <= STD_LOGIC_VECTOR(w_combs(g_STAGES-1)(c_CIC_BIT_DEPTH - 1 downto c_CIC_BIT_DEPTH - g_OUTPUT_BITDEPTH));
end Behavioral;
