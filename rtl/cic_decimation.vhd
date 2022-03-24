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
use IEEE.MATH_REAL.ALL;

entity cic_decimation is
    Port ( i_clk, i_pdm: in STD_LOGIC;
           o_recovered_waveform: out SIGNED(23 downto 0));
end cic_decimation;

architecture Behavioral of cic_decimation is

     -- Enough head room to avoid saturation
    constant c_CIC_INPUT_BIT_DEPTH : integer := 2;
    constant c_CIC_DECIMATION_RATE : integer := 16;
    constant c_CIC_DIFFERENTIAL_DELAY : integer := 1;
    constant c_CIC_STAGES : integer := 6;
    constant c_CIC_BIT_DEPTH : integer := integer(ceil(real(c_CIC_STAGES) * LOG2(real(c_CIC_DECIMATION_RATE * c_CIC_DIFFERENTIAL_DELAY)) + real(c_CIC_INPUT_BIT_DEPTH )));
    --constant c_CIC_BIT_DEPTH : integer := 32;

    signal integrator1_delay : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal integrator2_delay : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal integrator3_delay : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal integrator4_delay : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal integrator5_delay : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal integrator6_delay : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');

    signal integrator_out: signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal decimated_sig : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal comb1_delay1 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal comb2_delay1 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal comb3_delay1 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal comb4_delay1 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal comb5_delay1 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
    signal comb6_delay1 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');

begin
    process_integrator : PROCESS (i_clk)
        variable integrator1 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable integrator2 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable integrator3 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable integrator4 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable integrator5 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable integrator6 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable pdm : signed((c_CIC_BIT_DEPTH) downto 0):= (others => '0');
    begin
        if (i_clk'event and i_clk = '1') then
            if (i_pdm = '1') then
                pdm := to_signed(1, (c_CIC_BIT_DEPTH+1));
            else
                pdm := to_signed(-1, (c_CIC_BIT_DEPTH+1));
            end if;
            
            integrator1 := integrator1_delay + pdm;
            integrator1_delay <= integrator1;

            integrator2 := integrator2_delay + integrator1;
            integrator2_delay <= integrator2;

            integrator3 := integrator3_delay + integrator2;
            integrator3_delay <= integrator3;

            integrator4 := integrator4_delay + integrator3;
            integrator4_delay <= integrator4;

            integrator5 := integrator5_delay + integrator4;
            integrator5_delay <= integrator5;

            integrator6 := integrator6_delay + integrator5;
            integrator6_delay <= integrator6;

            integrator_out <= integrator6;
        end if;
    end process;

    process_decimate : PROCESS (i_clk)
        variable counter : unsigned(6 downto 0) := (others => '0');
    begin
        if (i_clk'event and i_clk = '1') then
            counter := counter + 1;
            -- TODO: better way to handle multiple clock rates
            if (counter = c_CIC_DECIMATION_RATE) then
                decimated_sig <= integrator_out;
                counter := "0000000";
            end if;
        end if;
    end process;

    process_comb : PROCESS (i_clk)
        variable comb1 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable comb2 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable comb3 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable comb4 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable comb5 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable comb6 : signed((c_CIC_BIT_DEPTH) downto 0) := (others => '0');
        variable counter : unsigned(6 downto 0) := (others => '0');
    begin
        if (i_clk'event and i_clk = '1') then
            counter := counter + 1;
            -- TODO: better way to handle multiple clock rates?
            if (counter = c_CIC_DECIMATION_RATE) then
                comb1_delay1 <= decimated_sig;
                comb1 := decimated_sig - comb1_delay1;

                comb2_delay1 <= comb1;
                comb2 := comb1 - comb2_delay1;

                comb3_delay1 <= comb2;
                comb3 := comb2 - comb3_delay1;

                comb4_delay1 <= comb3;
                comb4 := comb3 - comb4_delay1;

                comb5_delay1 <= comb4;
                comb5 := comb4 - comb5_delay1;

                comb6_delay1 <= comb5;
                comb6 := comb5 - comb6_delay1;

                o_recovered_waveform <= comb6(c_CIC_BIT_DEPTH-c_CIC_INPUT_BIT_DEPTH downto (c_CIC_BIT_DEPTH-c_CIC_INPUT_BIT_DEPTH - 23));
                counter := "0000000";
            end if;
        end if;
    end process;

end Behavioral;
