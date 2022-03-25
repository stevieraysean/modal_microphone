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
           o_recovered_waveform: out SIGNED(23 downto 0));
end cic_decimation;

architecture Behavioral of cic_decimation is

     -- Enough head room to avoid saturation
    constant c_CIC_INPUT_BIT_DEPTH : integer := 2;
    constant c_CIC_DECIMATION_RATE : integer := 16;
    constant c_CIC_DIFFERENTIAL_DELAY : integer := 1;
    constant c_CIC_STAGES : integer := 6;
    constant c_CIC_BIT_DEPTH : integer := 1 + integer( ceil(real(c_CIC_STAGES) * LOG2(real(c_CIC_DECIMATION_RATE * c_CIC_DIFFERENTIAL_DELAY)) + real(c_CIC_INPUT_BIT_DEPTH )));

    signal r_pdm : signed((c_CIC_BIT_DEPTH-1) downto 0):= (others => '0');
    signal r_integrator_delays : signed((c_CIC_BIT_DEPTH * c_CIC_STAGES) downto 0) := (others => '0');
    signal w_integrators : signed((c_CIC_BIT_DEPTH * c_CIC_STAGES) downto 0) := (others => '0');

    signal integrator_out: signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
    signal decimated_sig : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
    signal comb1_delay1 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
    signal comb2_delay1 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
    signal comb3_delay1 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
    signal comb4_delay1 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
    signal comb5_delay1 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
    signal comb6_delay1 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');

begin
    process_r_pdm : PROCESS (i_clk)
    begin
        if (i_clk'event and i_clk = '1') then
            -- cast 0/1 to -1/1
            if (i_pdm = '1') then
                r_pdm <= to_signed(1, (c_CIC_BIT_DEPTH));
            else
                r_pdm <= to_signed(-1, (c_CIC_BIT_DEPTH));
            end if;
            r_integrator_delays(c_CIC_BIT_DEPTH-1 downto 0) <= w_integrators(c_CIC_BIT_DEPTH-1 downto 0);
        end if;
    end process;

    g_GENERATE_w_integrators: for ii in 2 to c_CIC_STAGES generate
        process_integrator : PROCESS (i_clk)
        begin
            if (i_clk'event and i_clk = '1') then
                r_integrator_delays((ii*c_CIC_BIT_DEPTH)-1 downto (ii-1)*c_CIC_BIT_DEPTH) <= w_integrators((ii*c_CIC_BIT_DEPTH)-1 downto (ii-1)*c_CIC_BIT_DEPTH);
            end if;
        end process;
        w_integrators((ii*c_CIC_BIT_DEPTH)-1 downto ((ii-1)*c_CIC_BIT_DEPTH)) <= r_integrator_delays((ii*c_CIC_BIT_DEPTH)-1 downto (ii-1)*c_CIC_BIT_DEPTH) + w_integrators(((ii-1)*c_CIC_BIT_DEPTH)-1 downto (ii-2)*c_CIC_BIT_DEPTH);
    end generate g_GENERATE_w_integrators; 

    w_integrators(c_CIC_BIT_DEPTH-1 downto 0) <= r_integrator_delays(c_CIC_BIT_DEPTH-1 downto 0) + r_pdm(c_CIC_BIT_DEPTH-1 downto 0); 
    integrator_out <= w_integrators((c_CIC_BIT_DEPTH * c_CIC_STAGES)-2 downto (c_CIC_BIT_DEPTH * c_CIC_STAGES) - (c_CIC_BIT_DEPTH)-1);

    process_comb : PROCESS (i_clk)
        variable comb1 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
        variable comb2 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
        variable comb3 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
        variable comb4 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
        variable comb5 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
        variable comb6 : signed((c_CIC_BIT_DEPTH-1) downto 0) := (others => '0');
        variable counter : unsigned(6 downto 0) := (others => '0');
    begin
        if (i_clk'event and i_clk = '1') then
            counter := counter + 1;
            -- TODO: better way to handle multiple clock rates?
            if (counter = c_CIC_DECIMATION_RATE) then
                comb1_delay1 <= integrator_out;
                comb1 := integrator_out - comb1_delay1;

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
