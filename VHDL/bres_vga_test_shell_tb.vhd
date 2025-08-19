----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/19/2025 11:34:22 AM
-- Design Name: 
-- Module Name: bres_vga_test_shell_tb - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bres_vga_test_shell_tb is
end bres_vga_test_shell_tb;


architecture Behavioral of bres_vga_test_shell_tb is
component vga_test_shell is
Port ( clk_ext_port	  : in  std_logic;	-- mapped to external IO device (100 MHz Clock)
       red            : out std_logic_vector(3 downto 0);
       green          : out std_logic_vector(3 downto 0);
       blue           : out std_logic_vector(3 downto 0);
       HS             : out std_logic;
       VS             : out std_logic 	
 );
end component;
signal clk_ext_port : std_logic;
signal red, green, blue : std_logic_vector(3 downto 0);
signal HS       : std_logic;
signal VS       : std_logic;
constant PERIOD : time := 10 ns;
begin
uut: vga_test_shell
Port Map(clk_ext_port => clk_ext_port,
         red => red,
         green => green,
         blue => blue,
         HS => HS,
         VS => VS);

clk_proc : process
begin
    clk_ext_port <= '0';
    wait for PERIOD / 2;  
    
    clk_ext_port <= '1';
    wait for PERIOD / 2;
end process clk_proc;

end Behavioral;
