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
        -- g_COEFFICIENTS       : array_of_integers := (41104,111568,106535,-15100,-95631,6710,119118,6710,-156029,-29361,202165,65431,-260886,-119119,333866,203843,-430336,-342256,569586,602302,-796079,-1249064,1191182,4334393,4334393,1191182,-1249064,-796079,602302,569586,-342256,-430336,203843,333866,-119119,-260886,65431,202165,-29361,-156029,6710,119118,6710,-95631,-15100,106535,111568,41104);
        
        -- good, tho Fpb *2 what it should be
        --g_COEFFICIENTS          : array_of_integers := (-8389,838,22649,20971,-14261,-28522,16777,49492,-7550,-71304,-10067,94791,41104,-115763,-87242,130023,150994,-130024,-236559,106535,344771,-46138,-484862,-79692,670249,339738,-942880,-999084,1380764,4109579,4109579,1380764,-999084,-942880,339738,670249,-79692,-484862,-46138,344771,106535,-236559,-130024,150994,130023,-87242,-115763,41104,94791,-10067,-71304,-7550,49492,16777,-28522,-14261,20971,22649,838,-8389);
        
        g_COEFFICIENTS       : array_of_integers := (-1678,-2517,-2517,838,7549,13421,14260,6710,-5873,-16778,-15939,-839,20132,31037,19293,-11745,-41105,-44460,-11745,38587,69625,51170,-14261,-83048,-99825,-37749,69625,144284,117440,-13422,-164417,-216427,-99825,130862,317089,290245,5872,-389232,-607336,-387554,332188,1332110,2201170,2544264,2201170,1332110,332188,-387554,-607336,-389232,5872,290245,317089,130862,-99825,-216427,-164417,-13422,117440,144284,69625,-37749,-99825,-83048,-14261,51170,69625,38587,-11745,-44460,-41105,-11745,19293,31037,20132,-839,-15939,-16778,-5873,6710,14260,13421,7549,838,-2517,-2517,-1678);
        --g_COEFFICIENTS       : array_of_integers := (45298,123312,117440,-15939,-105697,6710,130862,8388,-171967,-33555,222298,73819,-286052,-135057,364065,229847,-468085,-385038,613207,676960,-838022,-1389154,1154272,4482872,4482872,1154272,-1389154,-838022,676960,613207,-385038,-468085,229847,364065,-135057,-286052,73819,222298,-33555,-171967,8388,130862,6710,-105697,-15939,117440,123312,45298);
        
        -- g_COEFFICIENTS       : array_of_integers := (7144, 0, -12554, 0, 24430, 0, -49872, 0, 164898, 262143, 164898, 0, -49872, 0, 24430, 0, -12554, 0, 7144);
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
