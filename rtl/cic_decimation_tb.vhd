library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.data_types.ALL;

entity cic_decimation_tb is
end cic_decimation_tb;

architecture Behavioral of cic_decimation_tb is       
    constant c_CLOCK_FREQ_HZ     : real := 76800000.0;
    constant c_CLOCK_3072E3_DIV  : integer := 25;  -- 384MHz to 3.072MHz
    constant c_CLOCK_192E3_DIV   : integer := 400; -- 384MHz to 192kHz
    constant c_CLOCK_PERIOD      : real := (1.0 / c_CLOCK_FREQ_HZ);
    constant c_CLOCK_PERIOD_HALF : time := (c_CLOCK_PERIOD / 2) * 1 sec;
    constant c_CLOCK_DIV_PERIOD  : real := (c_CLOCK_3072E3_DIV *1.0) / c_CLOCK_FREQ_HZ;
    constant c_SIM_BIT_DEPTH     : integer := 24;

    component cic_decimation is
        generic (
            g_STAGES             : integer := 6;
            g_DECIMATION_RATE    : integer := 16;
            g_DIFFERENTIAL_DELAY : integer := 1;
            g_OUTPUT_BITDEPTH    : integer := 24
            );
        port ( 
            i_clk_768e5     : in std_logic;
            i_clk_3072e3_en : in std_logic; -- 3.071 MHZ
            i_clk_192e3_en  : in std_logic; -- 192 kHz
            i_cic_in        : in std_logic;
            o_cic_out       : out std_logic_vector(g_OUTPUT_BITDEPTH-1 downto 0) := (others => '0')
            );
    end component cic_decimation;

    COMPONENT cic_compiler_0
        PORT (
            aclk : IN STD_LOGIC;
            s_axis_data_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            s_axis_data_tvalid : IN STD_LOGIC;
            s_axis_data_tready : OUT STD_LOGIC;
            m_axis_data_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
            m_axis_data_tvalid : OUT STD_LOGIC 
        );
    END COMPONENT;

    signal r_clock            : std_logic := '0';
    signal r_clk_3072e3       : std_logic := '0';
    signal r_clk_192e3        : std_logic := '0';
    signal r_clk_3072e3_count : integer   := 0;
    signal r_clk_192e3_count  : integer   := 0;

    signal r_adc             : std_logic := '1';
    signal r_adc_cic_comp    : std_logic_vector(7 downto 0) := "11111111";
    signal cic_output        : std_logic_vector((c_SIM_BIT_DEPTH-1) downto 0) := (others => '0');
    signal cic_output_comp   : std_logic_vector(23 downto 0) := (others => '0');
    signal r_sim_sine_wave   : std_logic_vector((c_SIM_BIT_DEPTH-1) downto 0) := (others => '0');
    signal r_sine_wave_freq  : real := 100.0;

    signal s_axis_data_tvalid             : std_logic := '0';
    signal s_axis_data_tready             : std_logic := '1';
    signal m_axis_data_tvalid             : std_logic := '0';


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

            if r_clk_192e3_count = c_CLOCK_192E3_DIV-18 then
                s_axis_data_tvalid <= '1';
            end if;


        end if;
    end process;


    sine_wave : process(r_clk_3072e3)
        variable v_analog_sig      : real := 0.0;
        variable v_amp             : real := 1.0; -- prevent clipping, TODO: fix & remove
        variable v_difference      : real := 0.0;
        variable v_integrator      : real := 0.0;
        variable v_dac             : real := 0.0;
        variable v_tstep           : real := 0.0;

    begin
        if rising_edge(r_clk_3072e3) then
            v_tstep := v_tstep + c_CLOCK_DIV_PERIOD;

            -- Chirp signal -- TODO: import better test signal
            if r_sine_wave_freq < 30000.0 then
                r_sine_wave_freq <= r_sine_wave_freq;-- + 0.125;
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
                r_adc_cic_comp <= "00000001";
                v_dac := 1.0;
            else
                r_adc <= '0';
                r_adc_cic_comp <= "11111111";
                v_dac := -1.0;
            end if;
            -- scale up to desired bit-depth for audio
            r_sim_sine_wave <= std_logic_vector(to_signed(integer(v_analog_sig*((2 ** (c_SIM_BIT_DEPTH-1)) -1)), c_SIM_BIT_DEPTH));       
        end if;
    end process;
    
    cic_decimation_inst : cic_decimation
        port map (
            i_clk_768e5     => r_clock,
            i_clk_3072e3_en => r_clk_3072e3,
            i_clk_192e3_en  => r_clk_192e3,
            i_cic_in        => r_adc,     
            o_cic_out       => cic_output
        );

    your_instance_name : cic_compiler_0
        PORT MAP (
          aclk => r_clock,
          s_axis_data_tdata => r_adc_cic_comp,
          s_axis_data_tvalid => s_axis_data_tvalid,
          s_axis_data_tready => s_axis_data_tready,
          m_axis_data_tdata => cic_output_comp,
          m_axis_data_tvalid => m_axis_data_tvalid
        );

end Behavioral;
