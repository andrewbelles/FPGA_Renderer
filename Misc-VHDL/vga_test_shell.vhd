----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/13/2025 06:24:13 PM
-- Design Name: 
-- Module Name: vga_test_shell - Behavioral
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

entity vga_test_shell is
Port ( clk_ext_port	  : in  std_logic;	-- mapped to external IO device (100 MHz Clock)
       red            : out std_logic_vector(3 downto 0);
       green          : out std_logic_vector(3 downto 0);
       blue           : out std_logic_vector(3 downto 0);
       HS             : out std_logic;
       VS             : out std_logic 		
 );
end vga_test_shell;

architecture Behavioral of vga_test_shell is

component vga_controller is 
    Port ( clk : in STD_LOGIC; --100 MHz clock
           video_on : out STD_LOGIC;
           V_sync : out STD_LOGIC;
           H_sync : out STD_LOGIC;
           pixel_x : out STD_LOGIC_VECTOR(9 downto 0);
           pixel_y : out STD_LOGIC_VECTOR(9 downto 0));
end component;

component vga_test_pattern is
     port(video_on       : in STD_LOGIC;
          row,column     : in std_logic_vector(9 downto 0);
          color          : out std_logic_vector(11 downto 0));
end component;
component system_clock_generation is
    Generic( CLK_DIVIDER_RATIO : integer := 4  );
    Port (
        --External Clock:
        input_clk_port		: in std_logic;
        --System Clock:
        system_clk_port		: out std_logic);
end component;

-- signal declarations
signal system_clk : STD_LOGIC;
signal video_on : STD_LOGIC;
signal pixel_x  : STD_LOGIC_VECTOR(9 downto 0);
signal pixel_y  : STD_LOGIC_VECTOR(9 downto 0);
signal color    : STD_LOGIC_VECTOR(11 downto 0);


begin

clock : system_clock_generation 
    Port Map(
        input_clk_port => clk_ext_port,
        system_clk_port => system_clk);
-- wire the controller
controller : vga_controller 
    Port Map(
        clk => system_clk, -- uses the 100MHz FPGA clock
        video_on => video_on,
        H_sync => HS, -- send HS to vga port on FPGA
        V_sync => VS, -- send VS to vga port on FPGA
        -- send pixel to signals which will be sent to the datapath (vga_test_pattern)
        pixel_x => pixel_x,
        pixel_y => pixel_y);
datapath : vga_test_pattern
    Port Map(
        video_on => video_on,
        column => pixel_x,
        row => pixel_y,
        color => color); -- wire color signal, will be assigned to output of shell in separate line

-- wire the correct colors by slicing up color vector into groups of 4
red <= color(11) & color(10) & color(9) & color(8);
green <= color(7) & color(6) & color(5) & color(4);
blue <= color(3) & color(2) & color(1) & color(0);
end Behavioral;
