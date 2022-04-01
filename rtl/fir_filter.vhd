----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2022 08:04:59 PM
-- Design Name: 
-- Module Name: fir_filter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: FIR Filter
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

use work.data_types.ALL;

entity fir_filter is
    generic (
        g_BITDEPTH           : integer := 24;
        --g_COEFFICIENTS       : array_of_integers := ( 11, -7, -33, 113, 255, 113, -33,  -7,  11); -- TODO: half-band w/  zeros 
        g_COEFFICIENTS       : array_of_integers := (176, 0, -299, 0, 1023,  817, 1023, 0, -299, 0, 176);
        g_DECIMATION_RATE    : integer := 2
        );
    Port ( 
        i_SIGNAL_IN  : in STD_LOGIC_VECTOR (g_BITDEPTH-1 downto 0);
        o_SIGNAL_OUT : out STD_LOGIC_VECTOR (g_BITDEPTH-1 downto 0);
        i_clk        : in STD_LOGIC
        );

    constant g_STAGES : integer := g_COEFFICIENTS'LENGTH-1;
end fir_filter;

architecture Behavioral of fir_filter is

    type t_fir_stage is array (0 to g_STAGES-1) of signed(g_BITDEPTH-1 downto 0);
    type t_mult_stage is array (0 to g_STAGES-1) of signed((g_BITDEPTH * 2)-1 downto 0);

    signal r_taps    : t_fir_stage  := (others => to_signed(0, g_BITDEPTH));
    signal r_mults   : t_mult_stage := (others => to_signed(0, g_BITDEPTH*2));
    signal r_sums    : t_mult_stage := (others => to_signed(0, g_BITDEPTH*2));

begin
    -- delays
    process_integrator : PROCESS (i_clk)
    begin
        if (i_clk'event and i_clk = '1') then
            for STAGE in 0 to g_STAGES-1 loop
                if STAGE = 0 then
                    r_taps(STAGE) <= signed(i_SIGNAL_IN);
                else
                    r_taps(STAGE) <= r_taps(STAGE-1);
                end if;
            end loop;
        end if;
    end process;

    -- multiplies
    g_GENERATE_mult : for STAGE in 0 to g_STAGES-1 generate
        r_mults(STAGE)  <= r_taps(STAGE) * g_COEFFICIENTS(STAGE+1);
    end generate g_GENERATE_mult;

    -- sums
    r_sums(0)  <= (signed(i_SIGNAL_IN) * g_COEFFICIENTS(0)) + r_mults(0);
    g_GENERATE_sum : for STAGE in 1 to g_STAGES-1 generate
        r_sums(STAGE)  <= r_sums(STAGE-1) + r_mults(STAGE);
    end generate g_GENERATE_sum;

    o_SIGNAL_OUT <= STD_LOGIC_VECTOR(r_sums(g_STAGES-1)(35 downto 12));
end Behavioral;
