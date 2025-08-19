--=============================================================================
--Library Declarations:
--=============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
library UNISIM;
use UNISIM.VComponents.all;

--=============================================================================
--Entity Declaration:
--=============================================================================
entity system_clock_generation is
    Generic( CLK_DIVIDER_RATIO : integer := 25  );
    Port (
        --External Clock:
        input_clk_port		: in std_logic;
        --System Clock:
        system_clk_port		: out std_logic);
end system_clock_generation;

--=============================================================================
--Architecture Type:
--=============================================================================
architecture behavioral_architecture of system_clock_generation is
    --=============================================================================
    --Signal Declarations: 
    --=============================================================================

    constant CLOCK_DIVIDER_TC: integer := CLK_DIVIDER_RATIO / 2;

    --Automatic register sizing:
    constant COUNT_LEN					: integer := integer(ceil( log2( real(CLOCK_DIVIDER_TC) ) ));
    signal system_clk_divider_counter	: unsigned(COUNT_LEN-1 downto 0) := (others => '0');
    signal system_clk_tog				: std_logic := '0';

    --=============================================================================
    --Processes: 
    --=============================================================================
begin
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --Clock (frequency) Divider):
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Clock_divider: process(input_clk_port)
    begin
        if rising_edge(input_clk_port) then
            if system_clk_divider_counter = CLOCK_DIVIDER_TC-1 then 	  -- Counts to 1/2 clk period
                system_clk_tog <= NOT(system_clk_tog);        		      -- T flip flop
                system_clk_divider_counter <= (others => '0');			  -- Reset
            else
                system_clk_divider_counter <= system_clk_divider_counter + 1; -- Count up
            end if;
        end if;
    end process Clock_divider;

    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- Clock buffer for the system clock
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- The BUFG component puts the system clock onto the FPGA clocking network
    Slow_clock_buffer: BUFG
        port map (I => system_clk_tog,
                 O => system_clk_port );

end behavioral_architecture;
