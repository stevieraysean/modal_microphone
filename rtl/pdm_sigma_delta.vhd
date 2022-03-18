----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/23/2022 08:52:22 PM
-- Design Name: 
-- Module Name: pdm_sigma_delta - Behavioral
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

entity pdm_sigma_delta is
    Port ( i_clk, i_pdm: in STD_LOGIC;
           o_recovered_waveform: out SIGNED(23 downto 0));
end pdm_sigma_delta;

architecture Behavioral of pdm_sigma_delta is

     -- Enough head room to avoid saturation
    constant c_BIT_DEPTH : integer := 32;

    signal integrator1_delay : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
    signal integrator2_delay : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
    signal integrator3_delay : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
    signal integrator4_delay : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
    signal integrator_out: signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
    signal decimated_sig : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
    signal comb1_delay : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
    signal comb2_delay : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
    signal comb3_delay : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
    signal comb4_delay : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');

begin
    process_integrator : PROCESS (i_clk)
        variable integrator1 : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
        variable integrator2 : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
        variable integrator3 : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
        variable integrator4 : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
        variable pdm : signed((c_BIT_DEPTH-1) downto 0):= (others => '0');
    begin
        if (i_clk'event and i_clk = '1') then
            if (i_pdm = '1') then
                pdm := to_signed(1, c_BIT_DEPTH);
            else
                pdm := to_signed(-1, c_BIT_DEPTH);
            end if;
            integrator1_delay <= integrator1;
            integrator1 := integrator1 + pdm;

            integrator2_delay <= integrator2;
            integrator2 := integrator2 + integrator1;

            integrator3_delay <= integrator3;
            integrator3 := integrator3 + integrator2;

            integrator4_delay <= integrator4;
            integrator4 := integrator4 + integrator3;
            
            integrator_out <= integrator4;
        end if;
    end process;

    process_decimate : PROCESS (i_clk)
        variable counter : unsigned(6 downto 0) := (others => '0');
    begin
        if (i_clk'event and i_clk = '1') then
            counter := counter + 1;
            -- TODO: better way to handle multiple clock rates?
            if (counter = "1000000") then
                decimated_sig <= integrator_out;
                counter := "0000000";
            end if;
        end if;
    end process;

    process_comb : PROCESS (i_clk)
        variable comb1 : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
        variable comb2 : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
        variable comb3 : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
        variable comb4 : signed((c_BIT_DEPTH-1) downto 0) := (others => '0');
        variable counter : unsigned(6 downto 0) := (others => '0');
    begin
        if (i_clk'event and i_clk = '1') then
            counter := counter + 1;
            -- TODO: better way to handle multiple clock rates?
            if (counter = "1000000") then
                comb1_delay <= decimated_sig;
                comb1 := decimated_sig - comb1_delay;

                comb2_delay <= comb1;
                comb2 := comb1 - comb2_delay;

                comb3_delay <= comb2;
                comb3 := comb2 - comb3_delay;

                comb4_delay <= comb3;
                comb4 := comb3 - comb4_delay;

                o_recovered_waveform <= comb4(c_BIT_DEPTH-1-7 downto c_BIT_DEPTH-24-7);
                counter := "0000000";
            end if;
        end if;
    end process;

end Behavioral;
