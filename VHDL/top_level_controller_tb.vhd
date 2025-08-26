----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/23/2025 09:27:04 PM
-- Design Name: 
-- Module Name: top_level_controller_tb - Behavioral
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_level_controller_tb is
--  Port ( );
end top_level_controller_tb;

architecture Behavioral of top_level_controller_tb is
component top_level_controller is
      Port (clk_ext_port   : in std_logic;
        RsRx_ext_port  : in std_logic;
        red            : out std_logic_vector(3 downto 0);
        green          : out std_logic_vector(3 downto 0);
        blue           : out std_logic_vector(3 downto 0);
        HS             : out std_logic;
        VS             : out std_logic 
         );
end component;
signal clk, HS, VS : std_logic;
signal rx : std_logic := '1';
signal red, green, blue : std_logic_vector(3 downto 0);


constant CLK_PERIOD : time := 10 ns; -- 1/100,000,000
constant BAUD_PERIOD : time := 104.2 us; -- 1/9600
begin
uut : top_level_controller
    Port Map(clk_ext_port => clk,
             RsRx_ext_port => rx,
             red => red, 
             green => green,
             blue => blue,
             HS => HS,
             VS => VS);
clock: process 
begin
clk <= '0';
wait for CLK_PERIOD / 2;
clk <= '1';
wait for CLK_PERIOD / 2;
end process;

--stim: process
--begin
------ note since clk period and buad period dont line up, no need to shift starting
--    wait for 29 ms;
--    wait for BAUD_PERIOD; 
--    -- start bit (0)
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    -- first data bit
--    rx <= '1';
--    wait for BAUD_PERIOD;
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    rx <= '1';
--    wait for BAUD_PERIOD;
--    rx <= '1';
--    wait for BAUD_PERIOD;
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    -- stop bit (1)
--    rx <= '1';
--    wait for 30 ms;
    
--    -- start bit (0)
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    -- first data bit
--    rx <= '1';
--    wait for BAUD_PERIOD;
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    rx <= '1';
--    wait for BAUD_PERIOD;
--    rx <= '1';
--    wait for BAUD_PERIOD;
--    rx <= '0';
--    wait for BAUD_PERIOD;
--    -- stop bit (1)
--    rx <= '1';
--    wait;
--END PROCESS;
end Behavioral;
