library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.data_types.ALL;

entity fir_filter_tb is
end fir_filter_tb;

architecture Behavioral of fir_filter_tb is       
    component fir_filter is
        port (
            i_clk          : in std_logic;
            i_SIGNAL_IN    : in std_logic_vector(23 downto 0);
            o_SIGNAL_OUT   : out std_logic_vector(23 downto 0)
        );
    end component fir_filter;

    constant c_CLOCK_FREQ_HZ : real := 192000.0; -- 3.072 MHz
    constant c_CLOCK_PERIOD : real := (1.0 / c_CLOCK_FREQ_HZ);
    constant c_CLOCK_PERIOD_HALF : time := (c_CLOCK_PERIOD / 2) * 1 sec;
    constant c_SIM_BIT_DEPTH : integer := 24;

    signal r_Clock : std_logic := '0';
    signal r_adc : STD_LOGIC := '0';
    signal r_fir_output : STD_LOGIC_VECTOR((c_SIM_BIT_DEPTH-1) downto 0) := (others => '0');
    signal r_sine_wave : STD_LOGIC_VECTOR((c_SIM_BIT_DEPTH-1) downto 0) := (others => '0');

begin        
    
    r_Clock <= not r_Clock after c_CLOCK_PERIOD_HALF; --50 ns

    sine_wave : process(r_Clock)
        variable v_tstep : real := 0.0;
        variable v_analog_sig : real := 0.0;
        variable v_amp : real := 0.95; -- prevent clipping, TODO: fix & remove
        variable v_analog_sig_sign : INTEGER := 1;
        variable v_difference : real := 0.0;
        variable v_integrator : real := 0.0;
        variable v_dac : real := 0.0;

        variable c_SINE_FREQ_HZ: real := 1.0;
    begin
        if (r_Clock = '1' and r_Clock'EVENT) then
            v_tstep := v_tstep + c_CLOCK_PERIOD;
            
            -- Chirp signal
            if c_SINE_FREQ_HZ > 96000.0 then
                v_amp := 0.0;
            else
                c_SINE_FREQ_HZ := c_SINE_FREQ_HZ + 1.0;
            end if;

            v_analog_sig := v_amp * sin(MATH_2_PI * v_tstep * c_SINE_FREQ_HZ);

            v_difference := v_analog_sig - v_dac;
            v_integrator := v_difference + v_integrator;
            
            if (v_integrator > 0.0) then 
                r_adc <= '1';
                v_dac := 1.0;
            else
                r_adc <= '0';
                v_dac := -1.0;
            end if;

            -- scale up to desired bit-depth for audio
            r_sine_wave <= STD_LOGIC_VECTOR(to_signed(INTEGER(v_analog_sig*((2 ** (c_SIM_BIT_DEPTH-1)) -1)), c_SIM_BIT_DEPTH));
        end if;
    end process;
    
    fir_filter_inst : fir_filter
    port map (
        i_clk        => r_Clock,
        i_SIGNAL_IN  => r_sine_wave,
        o_SIGNAL_OUT => r_fir_output
    );

end Behavioral;
