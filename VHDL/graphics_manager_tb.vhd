----------------------------------------------------------------------------------
-- Ben Sheppard 
-- Testbench for graphics_manager module. Loads two sets of vertices to show that it
-- successfully swaps front buffer from 0 to 1, then 1 to 0.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;
use work.array_types.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity graphics_manager_tb is
end graphics_manager_tb;


architecture Behavioral of graphics_manager_tb is
component graphics_manager is
Port ( sys_clk	          : in  std_logic;	-- mapped to external IO device (100 MHz Clock)
       packets            : in array_4x16_t;
       draw_new_points    : in std_logic;
       ready_to_draw      : out std_logic;
       done_drawing       : out std_logic;
       red                : out std_logic_vector(3 downto 0);
       green              : out std_logic_vector(3 downto 0);
       blue               : out std_logic_vector(3 downto 0);
       HS                 : out std_logic;
       VS                 : out std_logic 	
 );
end component;
signal clk_ext_port     : std_logic;
signal red, green, blue : std_logic_vector(3 downto 0);
signal HS, VS           : std_logic := '1';

signal packets                       : array_4x16_t := (others => (others => '0'));
signal draw_new_points               : std_logic := '0';
signal ready_to_draw, done_drawing   : std_logic;
constant PERIOD                      : time := 40 ns;
begin
uut: graphics_manager
Port Map(sys_clk => clk_ext_port,
         packets => packets,
         draw_new_points => draw_new_points,
         ready_to_draw => ready_to_draw,
         red => red,
         green => green,
         blue => blue,
         HS => HS,
         VS => VS);

clk_proc : process
begin
    clk_ext_port <= '1';
    wait for PERIOD / 2;  
    
    clk_ext_port <= '0';
    wait for PERIOD / 2;
end process clk_proc;

stim_proc : process
begin
-- load points
wait for PERIOD - 2ns;
packets(0) <= x"2937";
packets(1) <= x"d637";
packets(2) <= x"00c8";
packets(3) <= x"0000";
draw_new_points <= '1';
wait for PERIOD;
draw_new_points <= '0';

-- load new points  to show that buffer switches back
wait for 10 ms;
packets(0) <= x"2337";
packets(1) <= x"d607";
packets(2) <= x"10c8";
packets(3) <= x"0100";
draw_new_points <= '1';
wait for PERIOD;
draw_new_points <= '0';
wait;

end process;
end Behavioral;
