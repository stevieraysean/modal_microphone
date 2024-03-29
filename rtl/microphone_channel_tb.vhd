library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.data_types.ALL;

entity microphone_channel_tb is
end microphone_channel_tb;

architecture Behavioral of microphone_channel_tb is       
    constant c_CLOCK_FREQ_HZ     : real := 76800000.0;
    constant c_CLOCK_3072E3_DIV  : integer := 25;  -- 384MHz to 3.072MHz
    constant c_CLOCK_192E3_DIV   : integer := 400; -- 384MHz to 192kHz
    constant c_CLOCK_PERIOD      : real := (1.0 / c_CLOCK_FREQ_HZ);
    constant c_CLOCK_PERIOD_HALF : time := (c_CLOCK_PERIOD / 2) * 1 sec;
    constant c_CLOCK_DIV_PERIOD  : real := (c_CLOCK_3072E3_DIV *1.0) / c_CLOCK_FREQ_HZ;
    constant c_SIM_BIT_DEPTH     : integer := 24;

    component microphone_channel is
        Generic( 
            g_MIC_BITDEPTH : integer := 24
        );
        Port ( 
            i_clk_768e5     : in STD_LOGIC;
            i_clk_3072e3_en : in STD_LOGIC;
            i_clk_192e3_en  : in STD_LOGIC;
            i_pdm           : in STD_LOGIC;       
            o_output        : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
        );
    end component microphone_channel;

    signal r_clock            : std_logic := '0';
    signal r_clk_3072e3       : std_logic := '1';
    signal r_clk_192e3        : std_logic := '1';
    signal r_clk_3072e3_count : integer   := 0;
    signal r_clk_192e3_count  : integer   := 0;

    signal r_adc             : std_logic := '0';
    signal r_mic_output      : std_logic_vector((c_SIM_BIT_DEPTH-1) downto 0) := (others => '0');
    signal r_sim_sine_wave   : std_logic_vector((c_SIM_BIT_DEPTH-1) downto 0) := (others => '0');
    signal r_sine_wave_freq  : real := 100.0;

begin        
    
    r_clock <= not r_clock after c_CLOCK_PERIOD_HALF;

    process (r_clock)
    begin
        if rising_edge(r_clock) then
            r_clk_3072e3_count <= r_clk_3072e3_count + 1;

            if r_clk_3072e3_count = c_CLOCK_3072E3_DIV-1 then
                r_clk_3072e3 <= '1';
                r_clk_3072e3_count <= 0;
            else
                r_clk_3072e3 <= '0';
                r_clk_3072e3_count <= r_clk_3072e3_count + 1;
            end if;
        end if;
    end process;

    process (r_clock)
    begin
        if rising_edge(r_clock) then
            r_clk_192e3_count <= r_clk_192e3_count + 1;

            if r_clk_192e3_count = c_CLOCK_192E3_DIV-1 then
                r_clk_192e3 <= '1';
                r_clk_192e3_count <= 0;
            else
                r_clk_192e3 <= '0';
                r_clk_192e3_count <= r_clk_192e3_count + 1;
            end if;
        end if;
    end process;


    sine_wave : process(r_clk_3072e3)
        variable v_analog_sig      : real := 0.0;
        variable v_amp             : real := 0.93; -- prevent clipping, TODO: fix & remove
        variable v_difference      : real := 0.0;
        variable v_integrator      : real := 0.0;
        variable v_dac             : real := 0.0;
        variable v_tstep           : real := 0.0;

    begin
        if rising_edge(r_clk_3072e3) then
            v_tstep := v_tstep + c_CLOCK_DIV_PERIOD;

            -- Chirp signal -- TODO: import better test signal
            if r_sine_wave_freq < 24000.0 then
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
    
    microphone_microphone_inst : microphone_channel
        port map (
            i_clk_768e5     => r_clock,
            i_clk_3072e3_en => r_clk_3072e3,
            i_clk_192e3_en  => r_clk_192e3,
            i_pdm           => r_adc,     
            o_output        => r_mic_output
        );

end Behavioral;
