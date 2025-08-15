----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/14/2025 10:39:27 AM
-- Design Name: 
-- Module Name: vga_testbench - Behavioral
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
-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;

entity VGA_tb is
end VGA_tb;

architecture testbench of VGA_tb is

    component vga_controller is
        port (
            clk      : in  STD_LOGIC; --100 MHz clock
            V_sync   : out STD_LOGIC;
            H_sync   : out STD_LOGIC;
            pixel_x  : out STD_LOGIC_VECTOR(9 downto 0);
            pixel_y  : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    signal clk      : STD_LOGIC; --100 MHz clock
    signal V_sync   : STD_LOGIC;
    signal H_sync   : STD_LOGIC;
    signal pixel_x  : STD_LOGIC_VECTOR(9 downto 0);
    signal pixel_y  : STD_LOGIC_VECTOR(9 downto 0);

begin

    uut : vga_controller
        port map (
            clk      => clk,
            V_sync   => V_sync,
            H_sync   => H_sync,
            pixel_x  => pixel_x,
            pixel_y  => pixel_y
        );

    clk_proc : process
    begin
        clk <= '0';
        wait for 5 ns;  

        clk <= '1';
        wait for 5 ns;
    end process clk_proc;

    stim_proc : process
    begin
        wait;
    end process stim_proc;

end testbench;

