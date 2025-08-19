----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/18/2025 12:24:52 PM
-- Design Name: 
-- Module Name: framebuffer_manager - Behavioral
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

entity framebuffer_manager is
    Port (sys_clk    :   in std_logic;
          reset      :   in std_logic;
          pixel_x, pixel_y    :   in std_logic_vector(9 downto 0);
          pixel_out           :   out std_logic_vector(7 downto 0);
          
          write_x, write_y           : in  unsigned(7 downto 0);
          write_en                   : in std_logic
           );
end framebuffer_manager;

architecture Behavioral of framebuffer_manager is

begin


end Behavioral;
