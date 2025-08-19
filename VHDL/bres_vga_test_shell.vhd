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
use work.array_types.all;
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

component framebuffer is
      Port (clk                 :   in std_logic;
          reset               :   in std_logic;
          write_x, write_y    :   in std_logic_vector(7 downto 0); -- addess to write
          write_en            :   in std_logic;
          buffer_write_sel    :   in std_logic;
          read_x, read_y      :   in std_logic_vector(9 downto 0); -- address to read
          video_on            :   in std_logic;
          -- note takes in HS and VS unlike the VGA setup because need to slow them down by 1 clock cycle due to reading BRAM
          HS_in               :   in std_logic;
          VS_in               :   in std_logic;
        
          VGA_HS              :   out std_logic;
          VGA_VS              :   out std_logic;
          VGA_out             :   out std_logic_vector(11 downto 0) -- framebuffer data, 8 bit for an 8 bit color
           );
end component;

component graphics_manager is
    Port (clk                  :       in std_logic;
      new_vertices         :       in  std_logic; -- from central controller, signals there are new verticies ready
      vertices             :       in  array_4x16_t;
      buffer_write_sel     :       out std_logic;
      load_mem             :       out std_logic;
      x, y                 :       out std_logic_vector(7 downto 0)
       );
end component;

-- signal declarations
signal video_on : STD_LOGIC;
signal HS_sig, VS_sig   : std_logic;
signal color    : STD_LOGIC_VECTOR(11 downto 0);

signal write_x, write_y : std_logic_vector(7 downto 0);
signal write_en, buffer_write_sel         : std_logic;
signal read_x, read_y : std_logic_vector(9 downto 0);
signal dummy_reset, dummy_nv : std_logic;
signal dummy_vertices : array_4x16_t;

begin

-- wire the controller
controller : vga_controller 
    Port Map(
        clk => clk_ext_port, -- uses the 100MHz FPGA clock
        video_on => video_on,
        H_sync => HS_sig,
        V_sync => VS_sig,
        pixel_x => read_x,
        pixel_y => read_y);
datapath : framebuffer
    Port Map(clk => clk_ext_port,
          reset => dummy_reset,
          write_x => write_x ,
          write_y => write_y,
          write_en => write_en,
          buffer_write_sel => buffer_write_sel,
          read_x => read_x,
          read_y => read_y,
          video_on => video_on,
          HS_in => HS_sig, 
          VS_in => VS_sig,
        
          VGA_HS => HS, -- final VS/HS
          VGA_VS => VS,
          VGA_out => color);
manager : graphics_manager
    Port Map(
    clk => clk_ext_port,
    new_vertices => dummy_nv,
    vertices => dummy_vertices,
    buffer_write_sel => buffer_write_sel,
    load_mem => write_en,
    x => write_x,
    y => write_y
    );
-- wire the correct colors by slicing up color vector into groups of 4
red <= color(11) & color(10) & color(9) & color(8);
green <= color(7) & color(6) & color(5) & color(4);
blue <= color(3) & color(2) & color(1) & color(0);
end Behavioral;
