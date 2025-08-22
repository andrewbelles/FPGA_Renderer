----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/21/2025 11:58:33 PM
-- Design Name: 
-- Module Name: keyboard_7seg_test_shell - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity keyboard_7seg_test_shell is
    Port ( clk_ext_port : in STD_LOGIC;
           RsRx_ext_port       : in std_logic;
           seg_ext_port : out std_logic_vector(0 to 6);
           dp_ext_port  : out std_logic;
           an_ext_port  : out std_logic_vector(3 downto 0)
           );
end keyboard_7seg_test_shell;

architecture Behavioral of keyboard_7seg_test_shell is
component uart_receiver is
Port (     clk : in STD_LOGIC;
           rx : in STD_LOGIC;
           data : out STD_LOGIC_VECTOR(7 downto 0);
           data_valid : out STD_LOGIC);
end component;

component mux7seg is 
Port ( clk_port 	: in  std_logic;						-- runs on a fast (1 MHz or so) clock
         y3_port 		: in  std_logic_vector (3 downto 0);	-- digits
         y2_port 		: in  std_logic_vector (3 downto 0);	-- digits
         y1_port 		: in  std_logic_vector (3 downto 0);	-- digits
         y0_port 		: in  std_logic_vector (3 downto 0);	-- digits
         dp_set_port 	: in  std_logic_vector(3 downto 0);     -- decimal points
         seg_port 	    : out  std_logic_vector(0 to 6);		-- segments (a...g)
         dp_port 		: out  std_logic;						-- decimal point
         an_port 		: out  std_logic_vector (3 downto 0) );	-- anodes
end component;

-- for slower (1Mhz) clock for 7 seg, using 100 divider ratio
component system_clock_generation is 
Generic( CLK_DIVIDER_RATIO : integer := 100  );
    Port (
        --External Clock:
        input_clk_port		: in std_logic;
        --System Clock:
        system_clk_port		: out std_logic);
end component;

signal clk_7seg    : std_logic;
signal data_valid : std_logic;
signal data : std_logic_vector(7 downto 0);
signal y3_port, y2_port, y1_port, y0_port : std_logic_vector(3 downto 0) := (others => '0');
signal dp_set_port, an_port : std_logic_vector(3 downto 0);
signal seg_port : std_logic_vector(0 to 6);

signal y0_sync, y1_sync : std_logic_vector(3 downto 0);
begin

process(clk_7seg) 
begin
    if(rising_edge(clk_7seg)) then
        y0_sync <= y0_port;
        y1_sync <= y1_port;
    end if;
end process;
rec : uart_receiver 
    Port Map (clk => clk_ext_port, 
              rx => RsRx_ext_port,
              data => data,
              data_valid => data_valid);
seg : mux7seg 
    Port Map(clk_port => clk_7seg,
             y3_port => y3_port,
             y2_port => y2_port,
             y1_port => y1_sync,
             y0_port => y0_sync,
             dp_set_port => dp_set_port,
             seg_port => seg_port,
             dp_port => dp_ext_port,
             an_port => an_port);
clkgen: system_clock_generation
    Port Map(input_clk_port => clk_ext_port,
             system_clk_port => clk_7seg);



-- 7 seg: 
seg_ext_port <= seg_port;
an_ext_port <= an_port;
y0_port <= "0001";
y1_port <= "0110";
y2_port <= (others => '0');
y3_port <= (others => '0');
dp_set_port <= (others => '0'); 

---- purposely making a latch so that y0_port and y1_port are stable until next data_valid
--process(clk_ext_port)
--begin
--    if(rising_edge(clk_ext_port)) then
--            if(data_valid = '1') then
--                y0_port <= data(3 downto 0);
--                y1_port <= data(7 downto 4);
--            end if;
--    end if;
--end process;
end Behavioral;
