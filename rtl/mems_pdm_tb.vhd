library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.data_types.ALL;

entity mems_pdm_tb is
end mems_pdm_tb;

architecture Behavioral of mems_pdm_tb is       
    component microphone_channel is
        port (
            i_clk     : in std_logic;
            i_clk_div : in std_logic;
            i_pdm     : in std_logic
        );
    end component microphone_channel;

    constant c_CLOCK_FREQ_HZ     : real := 24576000.0;
    constant c_CLOCK_DIVIDER     : integer := 8; -- 24.576MHz to 3.072MHz
    constant c_CLOCK_PERIOD      : real := (1.0 / c_CLOCK_FREQ_HZ);
    constant c_CLOCK_PERIOD_HALF : time := (c_CLOCK_PERIOD / 2) * 1 sec;
    constant c_CLOCK_DIV_PERIOD  : real := (c_CLOCK_DIVIDER * 1.0 ) / c_CLOCK_FREQ_HZ;
    constant c_SIM_BIT_DEPTH     : integer := 24;

    signal r_clock           : std_logic := '0';
    signal r_clock_div       : std_logic := '1';
    signal r_clock_div_count : integer   := 0;
    signal r_adc             : std_logic := '0';
    signal r_cic_output      : std_logic_vector((c_SIM_BIT_DEPTH-1) downto 0) := (others => '0');
    signal r_sim_sine_wave   : std_logic_vector((c_SIM_BIT_DEPTH-1) downto 0) := (others => '0');
    signal r_sine_wave_freq  : real := 100.0;

begin        
    
    r_clock <= not r_clock after c_CLOCK_PERIOD_HALF;

    process (r_clock)
    begin
        if rising_edge(r_clock) then
            r_clock_div_count <= r_clock_div_count + 1;

            if r_clock_div_count = c_CLOCK_DIVIDER-1 then
                r_clock_div <= '1';
                r_clock_div_count <= 0;
            else
                if r_clock_div_count = (c_CLOCK_DIVIDER-1)/2 then
                    r_clock_div <= '0';
                end if;
                r_clock_div_count <= r_clock_div_count + 1;
            end if;
        end if;
    end process;


    sine_wave : process(r_clock_div)
        variable v_analog_sig      : real := 0.0;
        variable v_amp             : real := 0.95; -- prevent clipping, TODO: fix & remove
        variable v_difference      : real := 0.0;
        variable v_integrator      : real := 0.0;
        variable v_dac             : real := 0.0;
        variable v_tstep           : real := 0.0;
        

    begin
        if rising_edge(r_clock_div) then
            v_tstep := v_tstep + c_CLOCK_DIV_PERIOD;

            -- Chirp signal -- TODO: import better test signal
            if r_sine_wave_freq < 30000.0 then
                r_sine_wave_freq <= r_sine_wave_freq + 0.125;
            else
                v_amp := 0.0;
                v_tstep := 0.0;
            end if;

            -- NOTE: should be MATH_2_PI
            -- However the accumulation of change in time and frequency makes it look like filter cutoff
            -- half what it should be, using PI instead of 2_PI here is a cheap fix.
            -- verified by measuring and calculating frequencies of the waveform in simulation, they match r_sine_wave_freq 
            v_analog_sig := v_amp * sin(MATH_PI * v_tstep * r_sine_wave_freq);
            -- If testing single static frequency use:
            --v_analog_sig := v_amp * sin(MATH_2_PI * v_tstep * r_sine_wave_freq);


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
            r_sim_sine_wave <= std_logic_vector(to_signed(integer(v_analog_sig*((2 ** (c_SIM_BIT_DEPTH-1)) -1)), c_SIM_BIT_DEPTH));
        end if;
    end process;
    
    microphone_channel_inst : microphone_channel
        port map (
            i_clk     => r_clock,
            i_clk_div => r_clock_div,
            i_pdm     => r_adc
        );

end Behavioral;
