----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Sean Pierce
-- 
-- Create Date: 04/01/2022 09:21:13 AM
-- Design Name: 
-- Module Name: modal_microphone_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Top Module for modal microphone
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.data_types.ALL;

entity modal_microphone_top is
    Generic( 
        g_MIC_BITDEPTH        : integer := 24;
        g_ORDER               : integer := 2;
        g_NUMBER_MICS         : integer := 20
        );
    Port ( 
        i_clock     : in STD_LOGIC;
        i_pdm_in    : in std_logic_vector(g_NUMBER_MICS-1 downto 0);       --TODO: input array for mics
        o_output    : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0);
        o_output_comp    : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
    );
end modal_microphone_top;

architecture Behavioral of modal_microphone_top is

    constant c_CLOCK_3072E3_DIV  : integer := 25;  -- 384MHz to 3.072MHz
    constant c_CLOCK_192E3_DIV   : integer := 400; -- 384MHz to 192kHz
    
    component clk_wiz_0
        port(
            reset    : in  std_logic;
            clk_in1  : in  std_logic;
            clk_out1 : out std_logic;
            locked   : out std_logic
        );
    end component;

    component microphone_channel is
        port (
            i_clk_768e5     : in STD_LOGIC;
            i_clk_3072e3_en : in STD_LOGIC;
            i_clk_192e3_en  : in STD_LOGIC;
            i_pdm           : in std_logic;
            o_output        : out std_logic_vector(g_MIC_BITDEPTH-1 downto 0)
        );
    end component microphone_channel;

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

    signal r_clk_384e6        : std_logic;
    signal r_clk_384e6_reset  : std_logic := '0';
    signal r_clk_384e6_locked : std_logic;
    signal r_clk_3072e3_en    : std_logic := '0';
    signal r_clk_192e3_en     : std_logic := '0';
    signal r_clk_3072e3_count : integer   := 0;
    signal r_clk_192e3_count  : integer   := 0;

    signal r_mic_outs           : array_of_std_logic_vector(g_NUMBER_MICS-1 downto 0);

    -- TODO
    signal r_mode_output        : signed((g_MIC_BITDEPTH)-1 downto 0) := (others => '0');

    -- TODO delete
    signal s_axis_data_tvalid             : std_logic := '0';
    signal s_axis_data_tready             : std_logic := '1';
    signal m_axis_data_tvalid             : std_logic := '0';
    signal cic_output_comp   : std_logic_vector(23 downto 0) := (others => '0');


begin
    clk_wiz_0_inst : clk_wiz_0
        port map ( 
            clk_out1 => r_clk_384e6,
            reset    => r_clk_384e6_reset,
            locked   => r_clk_384e6_locked,
            clk_in1  => i_clock
        );


    process (r_clk_384e6)
    begin
        if rising_edge(r_clk_384e6) and r_clk_384e6_locked = '1' then
            if r_clk_3072e3_count = c_CLOCK_3072E3_DIV-1 then
                r_clk_3072e3_en <= '1';
                r_clk_3072e3_count <= 0;
            else
                r_clk_3072e3_en <= '0';
                r_clk_3072e3_count <= r_clk_3072e3_count + 1;
            end if;
        end if;
    end process;


    process (r_clk_384e6)
    begin
        if rising_edge(r_clk_384e6)  and r_clk_384e6_locked = '1' then
            if r_clk_192e3_count = c_CLOCK_192E3_DIV-1 then
                r_clk_192e3_en <= '1';
                r_clk_192e3_count <= 0;
            else
                r_clk_192e3_en <= '0';
                r_clk_192e3_count <= r_clk_192e3_count + 1;
            end if;
        end if;
    end process;


    g_GEN_MICS: for mic in 0 to g_NUMBER_MICS-1 generate
    microphone_channel_inst_1 : microphone_channel
        port map (
            i_clk_768e5  => r_clk_384e6,
            i_clk_3072e3_en => r_clk_3072e3_en,
            i_clk_192e3_en  => r_clk_192e3_en,
            i_pdm        => i_pdm_in(mic),
            o_output     => r_mic_outs(mic)
        );
    end generate g_GEN_MICS;


    process(r_mic_outs)
        variable sum : signed((g_MIC_BITDEPTH*2)-1 downto 0) := (others => '0');
    begin
        sum := (others => '0');
        
        for mic in 0 to g_NUMBER_MICS-1 loop
            sum := signed(r_mic_outs(mic)) + sum;
        end loop;

        o_output <= std_logic_vector(sum(g_MIC_BITDEPTH-1downto 0));
    end process;

    cic_compiler_0_instance : cic_compiler_0
        PORT MAP (
        aclk => r_clk_384e6,
        s_axis_data_tdata => i_pdm_in(7 downto 0),
        s_axis_data_tvalid => s_axis_data_tvalid,
        s_axis_data_tready => s_axis_data_tready,
        m_axis_data_tdata => cic_output_comp,
        m_axis_data_tvalid => m_axis_data_tvalid
        );

    o_output_comp <= cic_output_comp;

end Behavioral;
