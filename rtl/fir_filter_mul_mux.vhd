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

entity fir_filter_mul_mux is
    generic (
        g_BITDEPTH           : integer := 24;
        --test g_COEFFICIENTS       : array_of_integers := (175599, -346118, -485164, 616495, 912270, -1212929, -1685061, 2214040, 3064533, -4217038, -6341839, 10925493, 33554431, 33554431, 10925493, -6341839, -4217038, 3064533, 2214040, -1685061, -1212929, 912270, 616495, -485164, -346118, 175599);
        
        g_COEFFICIENTS       : array_of_integers := (7144, 0, -12554, 0, 24430, 0, -49872, 0, 164898, 262143, 164898, 0, -49872, 0, 24430, 0, -12554, 0, 7144);
        g_DECIMATION_RATE    : integer := 2;
        g_CLOCK_DIVIDER      : integer := 128
        );
    Port ( 
        i_SIGNAL_IN  : in STD_LOGIC_VECTOR (g_BITDEPTH-1 downto 0);
        o_SIGNAL_OUT : out STD_LOGIC_VECTOR (g_BITDEPTH-1 downto 0);
        i_clk_div    : in STD_LOGIC;
        i_clk        : in STD_LOGIC
        );

    constant g_STAGES : integer := g_COEFFICIENTS'LENGTH-1;
end fir_filter_mul_mux;

architecture Behavioral of fir_filter_mul_mux is

    type t_fir_stage is array (0 to g_STAGES) of signed(g_BITDEPTH-1 downto 0);
    
    signal r_taps    : t_fir_stage  := (others => to_signed(0, g_BITDEPTH));
    signal r_counter : integer := 0;

begin
    process (i_clk_div)
    begin
        if (i_clk_div'event and i_clk_div = '1') then
            for STAGE in 0 to g_STAGES loop
                if STAGE = 0 then
                    r_taps(STAGE) <= signed(i_SIGNAL_IN);
                else
                    r_taps(STAGE) <= r_taps(STAGE-1);
                end if;
            end loop;
        end if;
    end process;

    process (i_clk)
        variable sum : signed((g_BITDEPTH*2)-1 downto 0) := (others => '0');
    begin
        if (i_clk'event and i_clk = '1') then
            if r_counter <= g_STAGES then
                sum := sum + (r_taps(r_counter) * g_COEFFICIENTS(r_counter));
            end if;

            if r_counter = g_CLOCK_DIVIDER then
                r_counter <= 0;
                o_SIGNAL_OUT <= STD_LOGIC_VECTOR(sum(47-5 downto 24-5)); -- TODO: Calculate right range based on filter length. rounding... 
                sum := (others => '0');
            else
                r_counter <= r_counter + 1;
            end if;
        end if;
    end process;

end Behavioral;
