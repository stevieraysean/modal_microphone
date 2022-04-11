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
--     Due to limited DSP multipliers in FPGA, this filter has been create to multiplex ~30 FIR coefficients through a single mult
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
        g_BITDEPTH           : integer := 24;
        
        g_COEFFICIENTS : array_of_integers := (-171,335,-102,-828,1828,-1278,-1892,5878,-5874,-1790,13617,-17977,4100,23875,-42344,24460,30499,-82009,72111,19510,-135290,164519,-35148,-194161,334027,-191825,-245531,712476,-733991,-275634,4752871,4752871,-275634,-733991,712476,-245531,-191825,334027,-194161,-35148,164519,-135290,19510,72111,-82009,30499,24460,-42344,23875,4100,-17977,13617,-1790,-5874,5878,-1892,-1278,1828,-828,-102,335,-171);
        
        --g_COEFFICIENTS       : array_of_integers := (-782,974,632,-3989,5554,-490,-10899,18653,-8996,-19827,46180,-36280,-22008,91208,-99164,2307,150203,-222222,92365,211488,-464782,361847,258360,-1240923,2150484,5868370,2150484,-1240923,258360,361847,-464782,211488,92365,-222222,150203,2307,-99164,91208,-22008,-36280,46180,-19827,-8996,18653,-10899,-490,5554,-3989,632,974,-782);
        
        -- good:
        --g_COEFFICIENTS       : array_of_integers := (921,-1,-2862,0,6970,-1,-14502,0,27159,-1,-47162,0,77451,-1,-122280,0,188709,-1,-290989,0,465659,-1,-847443,0,2655697,4194303,2655697,0,-847443,-1,465659,0,-290989,-1,188709,0,-122280,-1,77451,0,-47162,-1,27159,0,-14502,-1,6970,0,-2862,-1,921);        
        
        -- og:
        -- g_COEFFICIENTS       : array_of_integers := (7144, 0, -12554, 0, 24430, 0, -49872, 0, 164898, 262143, 164898, 0, -49872, 0, 24430, 0, -12554, 0, 7144);
        g_DECIMATION_RATE : integer := 2;
        g_CLOCK_DIVIDER   : integer := 128
        );
    Port (
        i_clk        : in  STD_LOGIC;
        i_clk_div    : in  STD_LOGIC;
        i_SIGNAL_IN  : in  STD_LOGIC_VECTOR (g_BITDEPTH-1 downto 0);
        o_SIGNAL_OUT : out STD_LOGIC_VECTOR (g_BITDEPTH-1 downto 0);
        o_DATA_READY : out STD_LOGIC
        );

    constant g_STAGES : integer := g_COEFFICIENTS'LENGTH-1;
end fir_filter_mul_mux;

architecture Behavioral of fir_filter_mul_mux is

    type t_fir_stage is array (0 to g_STAGES) of signed(g_BITDEPTH-1 downto 0);
    
    signal r_taps    : t_fir_stage  := (others => to_signed(0, g_BITDEPTH));
    signal r_counter : integer := 0;
    signal r_sync : std_logic := '0';

    signal sum_debug : signed((g_BITDEPTH*2)-1 downto 0) := (others => '0');

begin
    process (i_clk_div)
    begin
        if rising_edge(i_clk_div) then
            r_sync <= '1';
            for STAGE in 0 to g_STAGES loop
                if STAGE = 0 then
                    r_taps(STAGE) <= signed(i_SIGNAL_IN);
                else
                    r_taps(STAGE) <= r_taps(STAGE-1);
                end if;
            end loop;
        end if;
    end process;

    process (i_clk, r_sync)
        variable sum : signed((g_BITDEPTH*2)-1 downto 0) := (others => '0');
    begin
        if rising_edge(i_clk) and r_sync = '1' then
            if r_counter <= g_STAGES then
                sum := sum + (r_taps(r_counter) * g_COEFFICIENTS(r_counter));
            end if;

            sum_debug <= sum;

            if r_counter = g_CLOCK_DIVIDER-1 then
                r_counter <= 0;
                o_SIGNAL_OUT <= STD_LOGIC_VECTOR(sum(47-1 downto 24-1)); -- TODO: Calculate right range based on filter length. rounding... 
                sum := (others => '0');
            else
                r_counter <= r_counter + 1;
            end if;
        end if;
    end process;


end Behavioral;
