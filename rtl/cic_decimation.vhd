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

    -- TODO: diff value for bit-width and register (downto..) size
    constant c_CIC_BIT_DEPTH          : integer := integer( ceil(real(c_CIC_STAGES) * LOG2(real(c_CIC_DECIMATION_RATE * c_CIC_DIFF_DELAY)) + real(c_CIC_INPUT_BIT_DEPTH )));
    constant c_CIC_REG_MAX            : integer := c_CIC_BIT_DEPTH - 1;
    constant c_OUTPUT_BIT_DEPTH       : integer := 24;
    
    signal r_pdm_buff          : std_logic := '0';

    signal r_pdm               : signed(c_CIC_REG_MAX downto 0):= (others => '0');
    --signal r_pdm_buff          : signed(c_CIC_REG_MAX downto 0):= (others => '0');

    signal r_integrator_delays : signed((c_CIC_BIT_DEPTH * c_CIC_STAGES)-1 downto 0)                    := (others => '0');
    signal r_comb_delays       : signed((c_CIC_BIT_DEPTH * c_CIC_STAGES * c_CIC_DIFF_DELAY)-1 downto 0) := (others => '0');
    signal r_decimator_counter : unsigned(6 downto 0) := (others => '0');
    signal r_decimator_clk     : std_logic := '0';
    signal r_decimated_signal  : signed(c_CIC_REG_MAX downto 0) := (others => '0');

    signal w_integrators : signed((c_CIC_BIT_DEPTH * c_CIC_STAGES)-1 downto 0) := (others => '0');
    signal w_combs       : signed((c_CIC_BIT_DEPTH * c_CIC_STAGES)-1 downto 0) := (others => '0');

    -- TODO: remove
    signal w_test_diff       : integer := 1;
    signal w_test_i       : integer := 2;
    signal w_test_j       : integer := 1;
    signal w_test1       : integer := 0;
    signal w_test2       : integer := 0;
    signal w_test3       : integer := 0;
    signal w_test4       : integer := 0;

begin
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

            r_integrator_delays(c_CIC_REG_MAX downto 0) <= w_integrators(c_CIC_REG_MAX downto 0);

        end if;
    end process;
    w_integrators(c_CIC_REG_MAX downto 0) <= r_integrator_delays(c_CIC_REG_MAX downto 0) + r_pdm;--(c_CIC_REG_MAX downto 0); 

    -- Integration Stages
    g_GENERATE_w_integrators: for ii in 2 to c_CIC_STAGES generate
        process_integrator : PROCESS (i_clk)
        begin
            if (i_clk'event and i_clk = '1') then
                r_integrator_delays((ii*c_CIC_BIT_DEPTH)-1 downto (ii-1)*c_CIC_BIT_DEPTH) <= w_integrators((ii*c_CIC_BIT_DEPTH)-1 downto (ii-1)*c_CIC_BIT_DEPTH);
            end if;
        end process;
        w_integrators((ii*c_CIC_BIT_DEPTH)-1 downto ((ii-1)*c_CIC_BIT_DEPTH)) <= r_integrator_delays((ii*c_CIC_BIT_DEPTH)-1 downto (ii-1)*c_CIC_BIT_DEPTH) + w_integrators(((ii-1)*c_CIC_BIT_DEPTH)-1 downto (ii-2)*c_CIC_BIT_DEPTH);
    end generate g_GENERATE_w_integrators; 

    -- Decimation Stage
    process_decimate : PROCESS (i_clk)
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
            r_decimated_signal <= w_integrators((c_CIC_BIT_DEPTH * c_CIC_STAGES)-1 downto (c_CIC_BIT_DEPTH * c_CIC_STAGES) - (c_CIC_BIT_DEPTH));
        end if;
    end process;


    process_comb_dels : PROCESS (r_decimator_clk)
    begin
        if (r_decimator_clk'event and r_decimator_clk = '1') then
            for STAGE in 1 to c_CIC_STAGES loop
                if (STAGE = 1) then
                    w_combs(c_CIC_BIT_DEPTH-1 downto 0) <= r_decimated_signal - r_comb_delays((c_CIC_BIT_DEPTH*c_CIC_DIFF_DELAY)-1 downto (c_CIC_DIFF_DELAY-1)*c_CIC_BIT_DEPTH);
                    for DEL in 1 to c_CIC_DIFF_DELAY loop
                        if DEL = 1 then
                            r_comb_delays(c_CIC_REG_MAX downto 0) <= r_decimated_signal;
                        else
                            r_comb_delays((DEL*c_CIC_BIT_DEPTH)-1 downto ((DEL-1)*c_CIC_BIT_DEPTH)) <= r_comb_delays(((DEL-1)*c_CIC_BIT_DEPTH)-1 downto ((DEL-2)*c_CIC_BIT_DEPTH));
                        end if;
                    end loop;
                else
                    for DEL in 1 to c_CIC_DIFF_DELAY loop
                        if DEL = 1 then
                            r_comb_delays(((DEL+((STAGE-1)*c_CIC_DIFF_DELAY))*c_CIC_BIT_DEPTH)-1 downto (DEL+((STAGE-1)*c_CIC_DIFF_DELAY)-1)*c_CIC_BIT_DEPTH) <= w_combs(((STAGE-1)*c_CIC_BIT_DEPTH)-1 downto (STAGE-2)*c_CIC_BIT_DEPTH);
                        else
                            r_comb_delays(((DEL+((STAGE-1)*c_CIC_DIFF_DELAY))*c_CIC_BIT_DEPTH)-1 downto (DEL+((STAGE-1)*c_CIC_DIFF_DELAY)-1)*c_CIC_BIT_DEPTH) <= r_comb_delays((((DEL-1)+((STAGE-1)*c_CIC_DIFF_DELAY))*c_CIC_BIT_DEPTH)-1 downto ((((DEL-1)+((STAGE-1)*c_CIC_DIFF_DELAY))-1)*c_CIC_BIT_DEPTH) );
                        end if;
                    end loop;
                    w_combs((STAGE*c_CIC_BIT_DEPTH)-1 downto ((STAGE-1)*c_CIC_BIT_DEPTH)) <= w_combs((((STAGE-1)*c_CIC_BIT_DEPTH)-1) downto (STAGE-2)*c_CIC_BIT_DEPTH) - r_comb_delays(((STAGE*c_CIC_DIFF_DELAY)*c_CIC_BIT_DEPTH)-1 downto ((STAGE*c_CIC_DIFF_DELAY)-1)*c_CIC_BIT_DEPTH);
                end if;
            end loop;
        end if;
    end process;


    -- TODO:
    o_recovered_waveform <= w_combs((c_CIC_BIT_DEPTH * c_CIC_STAGES) - 1 downto (c_CIC_BIT_DEPTH * c_CIC_STAGES) - c_OUTPUT_BIT_DEPTH);
end Behavioral;
