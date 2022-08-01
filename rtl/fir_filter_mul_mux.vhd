----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Sean Pierce
-- 
-- Create Date: 04/04/2022 07:04:59 PM
-- Design Name: 
-- Module Name: fir_filter_mul_mux - Behavioral
-- Project Name: modal_microphone
-- Target Devices: 
-- Tool Versions: 
-- Description: FIR Filter with Multiplexed Multiplication
--     Due to limited DSP multipliers in FPGA, this filter has been create to multiplex up to 400 FIR coefficients through a single mult
--     currently limited by max Integer values for coefficients, it seems.. TODO: investigate floating point version?
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
        -- DEFFAULT half-band filter Fpb=0.2, Fsb=0.3, Apb=0.2 Asb=60dB (from memory)
        g_COEFFICIENTS       : array_of_integers := (7144, 0, -12554, 0, 24430, 0, -49872, 0, 164898, 262143, 164898, 0, -49872, 0, 24430, 0, -12554, 0, 7144);
        g_BITDEPTH           : integer := 24;        
        g_DECIMATION_RATE    : integer := 2; -- TODO
        g_CLOCK_DIVIDER      : integer := 128
        );
    Port ( 
        i_SIGNAL_IN  : in STD_LOGIC_VECTOR (g_BITDEPTH-1 downto 0);
        o_SIGNAL_OUT : out STD_LOGIC_VECTOR (g_BITDEPTH-1 downto 0);
        i_clk_192e3_en  : in STD_LOGIC;
        i_clk_768e5  : in STD_LOGIC
        );

    constant g_STAGES : integer := g_COEFFICIENTS'LENGTH-1;
end fir_filter_mul_mux;

architecture Behavioral of fir_filter_mul_mux is
    type t_fir_stage is array (0 to g_STAGES) of signed(g_BITDEPTH-1 downto 0);

    signal r_taps    : t_fir_stage  := (others => to_signed(0, g_BITDEPTH));
    signal r_counter : natural; --:= 0;
    --signal r_sync    : std_logic := '0';

    --signal r_output : STD_LOGIC_VECTOR (g_BITDEPTH-1 downto 0);
 
begin
    process (i_clk_768e5, i_clk_192e3_en)
    begin
        if rising_edge(i_clk_768e5) and i_clk_192e3_en = '1' then
            --r_sync <= '1';
            for stage in 0 to g_STAGES loop
                if stage = 0 then
                    r_taps(stage) <= signed(i_SIGNAL_IN);
                else
                    r_taps(stage) <= r_taps(stage-1);
                end if;
            end loop;
        end if;
    end process;


    process (i_clk_768e5, i_clk_192e3_en)
        variable sum : signed((g_BITDEPTH*2)-1 downto 0) := (others => '0');
    begin
        if rising_edge(i_clk_768e5) then -- and r_sync = '1' then
            if r_counter <= g_STAGES then
                sum := sum + (r_taps(r_counter) * g_COEFFICIENTS(r_counter));
            end if;

            if i_clk_192e3_en = '1' then
                r_counter <= 0;
                o_SIGNAL_OUT <= STD_LOGIC_VECTOR(sum(47-1 downto 24-1)); -- TODO: Calculate right range based on filter length. rounding... 
                sum := (others => '0');
            else
                if r_counter < g_COEFFICIENTS'LENGTH-1 then
                    r_counter <= r_counter + 1;
                end if;
            end if;
        end if;
    end process;

    --o_SIGNAL_OUT <= r_output;

end Behavioral;
