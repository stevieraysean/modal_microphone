
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity mems_pdm_tb is
end mems_pdm_tb;

architecture Behavioral of mems_pdm_tb is       
    component pdm_sigma_delta is
        port (
            i_clk       : in std_logic;
            i_pdm       : in std_logic;
            i_sine_wave : in STD_LOGIC_VECTOR(23 downto 0)
        );
    end component pdm_sigma_delta;

    constant c_CLOCK_PERIOD : real := 1.00/10000.0;
    constant c_SINE_PERIOD : real := 100.0; -- 10 Hz
    constant c_BIT_DEPTH : integer := 24;

    signal r_Clock : std_logic := '0';
    signal r_adc : STD_LOGIC := '0';
    signal r_sine_wave : STD_LOGIC_VECTOR((c_BIT_DEPTH-1) downto 0);

begin        
    
    r_Clock <= not r_Clock after 50 ns;

    sine_wave : process(r_Clock)
        variable v_tstep : real := 0.0;
        variable v_analog_sig : real := 0.0;
        variable v_difference : real := 0.0;
        variable v_integrator : real := 0.0;
        --variable v_adc : STD_LOGIC := '0';
        variable v_dac : real := 0.0;
    begin
        if (r_Clock = '1') then
            v_tstep := v_tstep + c_CLOCK_PERIOD;
            v_analog_sig := 0.5*sin(MATH_2_PI * v_tstep * (1.0 /c_SINE_PERIOD)) + 0.5*sin(MATH_2_PI * v_tstep * (1.0 /(0.25*c_SINE_PERIOD)));

            v_difference := v_analog_sig - v_dac;
            v_integrator := v_difference + v_integrator;
            
            if (v_integrator > 0.0) then 
                r_adc <= '1';
                v_dac := 1.0;
            else
                r_adc <= '0';
                v_dac := -1.0;
            end if;

            r_sine_wave <= STD_LOGIC_VECTOR(to_signed(INTEGER(v_analog_sig*((2 ** (c_BIT_DEPTH-1)) -1)),c_BIT_DEPTH));
        end if;
    end process;
    
    pdm_sigma_delta_inst : pdm_sigma_delta
        port map (
            i_clk       => r_Clock,
            i_pdm       => r_adc,
            i_sine_wave => r_sine_wave
        );
end Behavioral;
