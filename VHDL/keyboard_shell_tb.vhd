----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/22/2025 02:22:39 AM
-- Design Name: 
-- Module Name: keyboard_shell_tb - Behavioral
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

entity keyboard_shell_tb is
--  Port ( );
end keyboard_shell_tb;

architecture Behavioral of keyboard_shell_tb is
component keyboard_7seg_test_shell is
Port ( clk_ext_port : in STD_LOGIC;
           RsRx_ext_port       : in std_logic;
           seg_ext_port : out std_logic_vector(0 to 6);
           dp_ext_port  : out std_logic;
           an_ext_port  : out std_logic_vector(3 downto 0)
           );
end component;
signal RsRx_ext_port : std_logic := '1';
signal clk : std_logic;
signal seg_ext_port_sg : std_logic_vector(0 to 6);
signal dp_ext_port_sg : std_logic;
signal an_ext_port_sg  : std_logic_vector(3 downto 0);

constant CLK_PERIOD : time := 10 ns; -- 1/100,000,000
constant BAUD_PERIOD : time := 104.2 us; -- 1/9600
begin
uut: keyboard_7seg_test_shell 
Port Map(
         clk_ext_port => clk,
         RsRx_ext_port => RsRx_ext_port,
         seg_ext_port => seg_ext_port_sg,
         dp_ext_port => dp_ext_port_sg,
         an_ext_port => an_ext_port_sg);
         
         
process 
begin
wait for CLK_PERIOD /2;
clk <= '1';
wait for CLK_PERIOD /2;
clk <= '0';
end process;

process 
begin
    RsRx_ext_port <= '1';
    wait for BAUD_PERIOD;
    
    wait for BAUD_PERIOD; 
    -- start bit (0)
    RsRx_ext_port <= '0';
    wait for BAUD_PERIOD;
    -- first data bit
    RsRx_ext_port <= '1';
    wait for BAUD_PERIOD;
    RsRx_ext_port <= '0';
    wait for BAUD_PERIOD;
    RsRx_ext_port <= '0';
    wait for BAUD_PERIOD;
    RsRx_ext_port <= '0';
    wait for BAUD_PERIOD;
    RsRx_ext_port <= '0';
    wait for BAUD_PERIOD;
    RsRx_ext_port <= '1';
    wait for BAUD_PERIOD;
    RsRx_ext_port <= '1';
    wait for BAUD_PERIOD;
    RsRx_ext_port <= '0';
    wait for BAUD_PERIOD;
    -- stop bit (1)
    RsRx_ext_port <= '1';
    wait;
    
end process;
end Behavioral;
