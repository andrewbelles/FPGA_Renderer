----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/18/2025 11:58:51 AM
-- Design Name: 
-- Module Name: bres_pixel_plotter - Behavioral
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

entity bres_pixel_plotter is
    Port (  clk, ready         :    in    std_logic;
    
            x0, y0, x1, y1     :    in    std_logic_vector(10 downto 0);
            memory             :    out);
end bres_pixel_plotter

architecture Behavioral of bres_pixel_plotter is

begin


end Behavioral;
