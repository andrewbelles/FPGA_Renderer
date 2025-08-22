----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/21/2025 10:28:20 PM
-- Design Name: 
-- Module Name: uart_receiver_tb - Behavioral
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

use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_receiver_tb is

end uart_receiver_tb;

architecture Behavioral of uart_receiver_tb is

component uart_receiver is
    Port ( clk : in STD_LOGIC;
           rx : in STD_LOGIC;
           data : out STD_LOGIC_VECTOR(7 downto 0);
           data_valid : out STD_LOGIC);
end component;

signal clk : std_logic;
signal rx  : std_logic := '1'; -- default rx to 1
signal data : std_logic_vector(7 downto 0);
signal data_valid : std_logic;

constant CLK_PERIOD : time := 10 ns; -- 1/100,000,000
constant BAUD_PERIOD : time := 104.2 us; -- 1/9600
begin

uut: uart_receiver
Port Map(
    clk => clk,
    rx => rx,
    data => data,
    data_valid => data_valid);

clock: process 
begin
clk <= '0';
wait for CLK_PERIOD / 2;
clk <= '1';
wait for CLK_PERIOD / 2;
end process;

stim: process
begin
-- note since clk period and buad period dont line up, no need to shift starting

wait for BAUD_PERIOD; 
-- start bit (0)
rx <= '0';
wait for BAUD_PERIOD;
-- first data bit
rx <= '1';
wait for BAUD_PERIOD;
rx <= '0';
wait for BAUD_PERIOD;
rx <= '1';
wait for BAUD_PERIOD;
rx <= '0';
wait for BAUD_PERIOD;
rx <= '1';
wait for BAUD_PERIOD;
rx <= '0';
wait for BAUD_PERIOD;
rx <= '1';
wait for BAUD_PERIOD;
rx <= '0';
wait for BAUD_PERIOD;
-- stop bit (1)
rx <= '1';
wait;

end process;
end Behavioral;
