----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/23/2022 08:52:22 PM
-- Design Name: 
-- Module Name: pdm_sigma_delta - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pdm_sigma_delta is
    Port ( i_clk, i_pdm: in STD_LOGIC;
           i_sine_wave: in STD_LOGIC_VECTOR(23 downto 0);
           o_waveform: out SIGNED(24 downto 0));

end pdm_sigma_delta;

architecture Behavioral of pdm_sigma_delta is
signal integrator_out: signed(24 downto 0) := (others => '0');
signal integrator1_del : signed(24 downto 0) := (others => '0');
--signal comb1 : signed(24 downto 0) := (others => '0');
signal comb1_del : signed(24 downto 0) := (others => '0');

signal integrator2_del : signed(24 downto 0) := (others => '0');
signal integrator3_del : signed(24 downto 0) := (others => '0');
signal integrator4_del : signed(24 downto 0) := (others => '0');

signal decimated_sig : signed(24 downto 0) := (others => '0');

signal pdm : signed(16 downto 0):= (others => '0');

begin
    process_integrator : PROCESS (i_clk)
        variable integrator1 : signed(24 downto 0) := (others => '0');
        --variable integrator1_del : signed(24 downto 0) := (others => '0'); 
        variable pdm : signed(24 downto 0):= (others => '0');
    begin
        if (i_clk'event and i_clk = '1') then
            if (i_pdm = '1') then
                pdm := "0000000000000000000000001"; -- = 1 
            else
                pdm := "1111111111111111111111111"; -- = -1
            end if;
            integrator1_del <= integrator1;
            integrator1 := integrator1 + pdm;
        end if;
        integrator_out <= integrator1;
    end process;

    process_decimate : PROCESS (i_clk)
        variable counter : unsigned(6 downto 0) := (others => '0');
    begin
        if (i_clk'event and i_clk = '1') then
            counter := counter + 1;
            if (counter = "1000000") then
                decimated_sig <= integrator_out;
                counter := "0000000";
            else
                decimated_sig <= decimated_sig;
            end if;
        end if;
    end process;

    process_comb : PROCESS (i_clk)
        variable comb1 : signed(24 downto 0) := (others => '0');
        variable counter : unsigned(6 downto 0) := (others => '0');
        --variable comb1_del : signed(24 downto 0) := (others => '0'); 
    begin
        if (i_clk'event and i_clk = '1') then
            counter := counter + 1;
            if (counter = "1000000") then
                comb1_del <= decimated_sig;
                comb1 := decimated_sig - comb1_del;
            end if;
        end if;
        o_waveform <= comb1;
    end process;

end Behavioral;
