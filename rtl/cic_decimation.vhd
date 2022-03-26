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

    constant c_CIC_INPUT_BIT_DEPTH    : integer := 2;
    constant c_CIC_DECIMATION_RATE    : integer := 16;
    constant c_CIC_DIFFERENTIAL_DELAY : integer := 1;
    constant c_CIC_STAGES             : integer := 6;
    constant c_CIC_BIT_DEPTH          : integer := 1 + integer( ceil(real(c_CIC_STAGES) * LOG2(real(c_CIC_DECIMATION_RATE * c_CIC_DIFFERENTIAL_DELAY)) + real(c_CIC_INPUT_BIT_DEPTH )));
    constant c_OUTPUT_BIT_DEPTH       : integer := 24;
    
    signal r_pdm               : signed((c_CIC_BIT_DEPTH-1) downto 0):= (others => '0');
    signal r_integrator_delays : signed((c_CIC_BIT_DEPTH * c_CIC_STAGES) downto 0) := (others => '0');
    signal r_comb_delays       : signed((c_CIC_BIT_DEPTH * c_CIC_STAGES * c_CIC_DIFFERENTIAL_DELAY) downto 0) := (others => '0');
    signal r_decimator_counter : unsigned(6 downto 0) := (others => '0');
    signal r_decimator_clk     : std_logic := '0';
    signal r_decimated_signal  : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');

    signal w_integrators : signed((c_CIC_BIT_DEPTH * c_CIC_STAGES) downto 0);
    signal w_combs       : signed((c_CIC_BIT_DEPTH * c_CIC_STAGES) downto 0);

begin
    process_r_pdm : PROCESS (i_clk)
    begin
        if (i_clk'event and i_clk = '1') then
            -- cast PDM 0/1 input to -1/1
            if (i_pdm = '1') then
                r_pdm <= to_signed(1, (c_CIC_BIT_DEPTH));
            else
                r_pdm <= to_signed(-1, (c_CIC_BIT_DEPTH));
            end if;
            r_integrator_delays(c_CIC_BIT_DEPTH-1 downto 0) <= w_integrators(c_CIC_BIT_DEPTH-1 downto 0);
        end if;
    end process;

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
                r_decimated_signal <= w_integrators((c_CIC_BIT_DEPTH * c_CIC_STAGES)-2 downto (c_CIC_BIT_DEPTH * c_CIC_STAGES) - (c_CIC_BIT_DEPTH)-1);
                r_comb_delays(c_CIC_BIT_DEPTH-1 downto 0) <= r_decimated_signal;              
            else
                r_decimator_clk <= '0';
            end if;
        end if;
    end process;
    
    -- Comb Stages
    g_GENERATE_w_combs: for i in 2 to c_CIC_STAGES generate
        process_comb : PROCESS (r_decimator_clk)
        begin
            if (r_decimator_clk'event and r_decimator_clk = '1') then
                -- TODO: Differential delay > 1
                for j in 1 to c_CIC_DIFFERENTIAL_DELAY loop
                    r_comb_delays((i*c_CIC_BIT_DEPTH)-1 downto (i-1)*c_CIC_BIT_DEPTH) <= w_combs(((i-1)*c_CIC_BIT_DEPTH)-1 downto (i-2)*c_CIC_BIT_DEPTH);
                end loop;
            end if;
        end process;
        w_combs((i*c_CIC_BIT_DEPTH)-1 downto ((i-1)*c_CIC_BIT_DEPTH)) <= w_combs(((i-1)*c_CIC_BIT_DEPTH)-1 downto (i-2)*c_CIC_BIT_DEPTH) - r_comb_delays((i*c_CIC_BIT_DEPTH)-1 downto (i-1)*c_CIC_BIT_DEPTH);
    end generate g_GENERATE_w_combs;

    w_integrators(c_CIC_BIT_DEPTH-1 downto 0) <= r_integrator_delays(c_CIC_BIT_DEPTH-1 downto 0) + r_pdm(c_CIC_BIT_DEPTH-1 downto 0); 
    w_combs(c_CIC_BIT_DEPTH-1 downto 0) <= r_decimated_signal - r_comb_delays(c_CIC_BIT_DEPTH-1 downto 0);
    o_recovered_waveform <= w_combs((c_CIC_BIT_DEPTH * c_CIC_STAGES) - (c_CIC_BIT_DEPTH-1 - c_OUTPUT_BIT_DEPTH) downto (c_CIC_BIT_DEPTH * c_CIC_STAGES) - (c_OUTPUT_BIT_DEPTH-1) - (c_CIC_BIT_DEPTH-1 - c_OUTPUT_BIT_DEPTH));
end Behavioral;
