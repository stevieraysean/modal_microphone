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
    Port ( i_clk, i_pdm: in STD_LOGIC;
           o_recovered_waveform: out SIGNED(23 downto 0) := (others => '0'));
end cic_decimation;

architecture Behavioral of cic_decimation is

    constant c_CIC_INPUT_BIT_DEPTH    : integer := 1;
    constant c_CIC_DECIMATION_RATE    : integer := 16;
    constant c_CIC_DIFF_DELAY         : integer := 1;
    constant c_CIC_STAGES             : integer := 6;
    constant c_CIC_BIT_DEPTH          : integer := integer( ceil(real(c_CIC_STAGES) * 
        LOG2(real(c_CIC_DECIMATION_RATE * c_CIC_DIFF_DELAY)) + real(c_CIC_INPUT_BIT_DEPTH )));
    constant c_CIC_REG_MAX            : integer := c_CIC_BIT_DEPTH - 1;
    constant c_OUTPUT_BIT_DEPTH       : integer := 24;
    
    signal r_pdm_buff          : std_logic := '0';
    signal r_pdm               : signed(c_CIC_REG_MAX downto 0):= (others => '0');
    signal r_decimator_counter : unsigned(6 downto 0) := (others => '0');
    signal r_decimator_clk     : std_logic := '0';
    signal r_decimated_signal  : signed(c_CIC_REG_MAX downto 0) := (others => '0');

    type t_cic_stage_array is array (0 to c_CIC_STAGES-1) of signed(c_CIC_REG_MAX downto 0);
    signal r_combs             : t_cic_stage_array:= (others => to_signed(0, (c_CIC_BIT_DEPTH)));
    signal r_integrator_delays : t_cic_stage_array:= (others => to_signed(0, (c_CIC_BIT_DEPTH)));
    signal w_integrators       : t_cic_stage_array:= (others => to_signed(0, (c_CIC_BIT_DEPTH)));

    type t_comb_delay_array is array (0 to c_CIC_STAGES-1, 0 to c_CIC_DIFF_DELAY-1) of signed(c_CIC_REG_MAX downto 0);
    signal r_comb_delays : t_comb_delay_array := (others => (others => to_signed(0, (c_CIC_BIT_DEPTH))));

begin
    -- PDM Input
    process_r_pdm : PROCESS (i_clk)
    begin
        if (i_clk'event and i_clk = '1') then
            -- cast PDM 0/1 input to -1/1

            r_pdm_buff <= i_pdm;

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
    -- TODO: not sure this is the way, but it works for reg and wire logic
    g_GENERATE_w_integrators: for STAGE in 1 to c_CIC_STAGES-1 generate
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

            if (r_decimator_counter = c_CIC_DECIMATION_RATE) then
                r_decimator_counter <= "0000001";
                r_decimator_clk <= '1';
            end if;
            if (r_decimator_counter = c_CIC_DECIMATION_RATE/2) then
                r_decimator_clk <= '0';
            end if;
        end if;
    end process;

    process_decimated_signals : PROCESS (r_decimator_clk)
    begin
        if (r_decimator_clk'event and r_decimator_clk = '1') then
            r_decimated_signal <= w_integrators(c_CIC_STAGES-1);
        end if;
    end process;

    -- Decimation Comb Filters
    process_comb_filters : PROCESS (r_decimator_clk)
    begin
        if (r_decimator_clk'event and r_decimator_clk = '1') then
            for STAGE in 0 to c_CIC_STAGES-1 loop
                if (STAGE = 0) then
                    r_combs(STAGE) <= r_decimated_signal - r_comb_delays(STAGE, c_CIC_DIFF_DELAY-1 );
                    for DEL in 0 to c_CIC_DIFF_DELAY-1 loop
                        if DEL = 0 then
                            r_comb_delays(STAGE, DEL) <= r_decimated_signal;
                        else
                            r_comb_delays(STAGE, DEL) <= r_comb_delays(STAGE, DEL-1);
                        end if;
                    end loop;
                else
                    for DEL in 0 to c_CIC_DIFF_DELAY-1 loop
                        if DEL = 0 then
                            r_comb_delays(STAGE, DEL) <= r_combs(STAGE-1);
                        else
                            r_comb_delays(STAGE, DEL) <= r_comb_delays(STAGE, DEL-1);
                        end if;
                    end loop;
                    r_combs(STAGE) <= r_combs(STAGE-1) - r_comb_delays(STAGE, c_CIC_DIFF_DELAY-1 );
                end if;
            end loop;
        end if;
    end process;

    -- CIC Filter Output
    -- grab the MSB's of the last comb stage
    o_recovered_waveform <= r_combs(c_CIC_STAGES-1)(c_CIC_BIT_DEPTH - 1 downto c_CIC_BIT_DEPTH - c_OUTPUT_BIT_DEPTH);
end Behavioral;
