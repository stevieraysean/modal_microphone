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
           o_waveform: out SIGNED(23 downto 0));

end pdm_sigma_delta;

architecture Behavioral of pdm_sigma_delta is

begin
    process_clock : PROCESS (i_clk)
        variable memory : UNSIGNED(23 downto 0) := (others => '0');
        variable sum : SIGNED(23 downto 0) := (others => '0');

    begin
        if (i_clk'event and i_clk = '1') then
            
            memory := shift_left(memory,1);
            memory(0) := i_pdm;
            sum := (others => '0');

            for i in 0 to 23 loop
                if memory(i) = '1' then
                    sum := sum + 1;
                else
                    sum := sum -1;
                end if;
            end loop;    

            o_waveform <= sum;
        end if;
    end process;

end Behavioral;
