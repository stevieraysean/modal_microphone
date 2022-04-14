----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Sean Pierce
-- 
-- Create Date: 03/31/2022 08:04:59 PM
-- Design Name: 
-- Module Name: fir_filter - Behavioral
-- Project Name: modal_microphone
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
        -- half band filter, calculated for zeros every other coefficient to save multipliers
        g_COEFFICIENTS       : array_of_integers := (7144, 0, -12554, 0, 24430, 0, -49872, 0, 164898, 262143, 164898, 0, -49872, 0, 24430, 0, -12554, 0, 7144);
        g_DECIMATION_RATE    : integer := 2
        );
    Port ( 
        i_clk        : in STD_LOGIC;
        i_signal_in  : in STD_LOGIC_VECTOR (g_BITDEPTH-1 downto 0);
        o_signal_out : out STD_LOGIC_VECTOR (g_BITDEPTH-1 downto 0)
        );

    constant g_STAGES : integer := g_COEFFICIENTS'LENGTH-1;
end fir_filter;

architecture Behavioral of fir_filter is

    type t_fir_stage  is array (0 to g_STAGES) of signed(g_BITDEPTH-1 downto 0);
    type t_mult_stage is array (0 to g_STAGES) of signed((g_BITDEPTH * 2)-1 downto 0);

    signal r_taps    : t_fir_stage  := (others => to_signed(0, g_BITDEPTH));
    signal r_mults   : t_mult_stage := (others => to_signed(0, g_BITDEPTH*2));
    signal r_sums    : t_mult_stage := (others => to_signed(0, g_BITDEPTH*2));

begin
    -- delays
    process (i_clk)
    begin
        if (i_clk'event and i_clk = '1') then
            for stage in 0 to g_STAGES loop
                if stage = 0 then
                    r_taps(stage) <= signed(i_SIGNAL_IN);
                else
                    r_taps(stage) <= r_taps(stage-1);
                end if;
            end loop;
        end if;
    end process;

    -- multiplers
    g_GENERATE_mult : for stage in 0 to g_STAGES-1 generate
        r_mults(stage)  <= r_taps(stage) * g_COEFFICIENTS(stage+1);
    end generate g_GENERATE_mult;

    -- sums
    r_sums(0)  <= (signed(i_SIGNAL_IN) * g_COEFFICIENTS(0)) + r_mults(0);
    g_GENERATE_sum : for stage in 1 to g_STAGES generate
        r_sums(stage)  <= r_sums(stage-1) + r_mults(stage);
    end generate g_GENERATE_sum;

    -- TODO: Calc bit growth, do rounding before truncation
    o_signal_out <= STD_LOGIC_VECTOR(r_sums(g_STAGES)(42 downto 42-23));

end Behavioral;
