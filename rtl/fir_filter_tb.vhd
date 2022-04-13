library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.data_types.ALL;

entity fir_filter_tb is
end fir_filter_tb;

architecture Behavioral of fir_filter_tb is       
    component fir_filter is
        port (
            i_clk          : in std_logic;
            i_signal_in    : in std_logic_vector(23 downto 0);
            o_signal_out   : out std_logic_vector(23 downto 0)
        );
    end component fir_filter;

    component fir_filter_mul_mux is
        port (
            i_clk_div      : in std_logic;
            i_clk          : in std_logic;
            i_signal_in    : in std_logic_vector(23 downto 0);
            o_signal_out   : out std_logic_vector(23 downto 0)
        );
    end component fir_filter_mul_mux;

    constant c_SIM_BIT_DEPTH     : integer := 24;
    constant c_CLOCK_DIV         : integer := 128;
    constant c_CLOCK_FREQ_HZ     : real := 24576000.0;
    constant c_CLOCK_PERIOD      : real := (1.0 / c_CLOCK_FREQ_HZ);
    constant c_CLOCK_PERIOD_HALF : time := (c_CLOCK_PERIOD / 2) * 1 sec;
    constant c_CLOCK_PERIOD_DIV  : real := ((1.0 * c_CLOCK_DIV)/ (c_CLOCK_FREQ_HZ));

    signal r_clock              : std_logic := '0';
    signal r_clock_div          : std_logic := '0';
    signal r_clock_counter      : integer   := 0;
    signal r_adc                : std_logic := '0';
    signal r_sine_wave          : std_logic_vector((c_SIM_BIT_DEPTH-1) downto 0) := (others => '0');
    signal r_fir_output         : std_logic_vector((c_SIM_BIT_DEPTH-1) downto 0) := (others => '0');
    signal r_fir_mul_mux_output : std_logic_vector((c_SIM_BIT_DEPTH-1) downto 0) := (others => '0');

begin        
    
    r_clock <= not r_clock after c_CLOCK_PERIOD_HALF; --50 ns

    clock : process(r_clock)
    begin
        if rising_edge(r_clock) then
            r_clock_counter <= r_clock_counter + 1;
            if r_clock_counter >= (c_CLOCK_DIV-1) then
                r_clock_counter <= 0;
                r_clock_div <= '1';
            end if;
            if r_clock_counter = ((c_CLOCK_DIV-1)/2) then
                r_clock_div <= '0';
            end if;
        end if;
    end process;


    sine_wave : process(r_clock_div)
        variable v_tstep           : real    := 0.0;
        variable v_analog_sig      : real    := 0.0;
        variable v_amp             : real    := 0.95;
        variable v_analog_sig_sign : INTEGER := 1;
        variable v_difference      : real    := 0.0;
        variable v_integrator      : real    := 0.0;
        variable v_dac             : real    := 0.0;
        variable v_sine_wave_freq  : real    := 1.0;
    begin
        if rising_edge(r_clock) then
            v_tstep := v_tstep + c_CLOCK_PERIOD_DIV;
            
            -- Chirp signal
            if v_sine_wave_freq > 24000.0 then
                v_amp := 0.0;
            else
                -- report ("ROW = "  & to_string(r_fir_output)); //TODO: how?
                v_sine_wave_freq := v_sine_wave_freq + 2.0;
            end if;

            v_analog_sig := v_amp * sin(MATH_2_PI * v_tstep * v_sine_wave_freq);
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
            r_sine_wave <= std_logic_vector(to_signed(integer(v_analog_sig*((2 ** (c_SIM_BIT_DEPTH-1)) -1)), c_SIM_BIT_DEPTH));
        end if;
    end process;
    
    fir_filter_inst : fir_filter
        port map (
            i_clk        => r_clock_div,
            i_signal_in  => r_sine_wave,
            o_signal_out => r_fir_output
        );

    fir_filter_mul_mux_inst : fir_filter_mul_mux
        port map (
            i_clk        => r_clock,
            i_clk_div    => r_clock_div,
            i_signal_in  => r_sine_wave,
            o_signal_out => r_fir_mul_mux_output
        );
end Behavioral;

