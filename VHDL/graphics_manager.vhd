----------------------------------------------------------------------------------
-- Ben Sheppard
-- Ties the vga_controller, framebuffer, and Bresenham_receiver modules together
-- Note that graphics_manager provides convenient simulation and hardware validation.
-- It is also the module that is exposed to the top level controller.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use work.array_types.all;
entity graphics_manager is
Port ( sys_clk	           : in  std_logic;	-- mapped to external IO device (100 MHz Clock)
       packets             : in array_4x16_t;
       draw_new_points     : in std_logic;
       ready_to_draw       : out std_logic;
       done_drawing        : out std_logic;
       red                 : out std_logic_vector(3 downto 0);
       green               : out std_logic_vector(3 downto 0);
       blue                : out std_logic_vector(3 downto 0);
       HS                  : out std_logic;
       VS                  : out std_logic 		
 );
end graphics_manager;

architecture Behavioral of graphics_manager is

component vga_controller is 
    Port ( clk      : in STD_LOGIC; --100 MHz clock
           video_on : out STD_LOGIC;
           V_sync   : out STD_LOGIC;
           H_sync   : out STD_LOGIC;
           pixel_x  : out STD_LOGIC_VECTOR(9 downto 0);
           pixel_y  : out STD_LOGIC_VECTOR(9 downto 0));
end component;

component framebuffer is
        Port (clk                 :   in std_logic;
              clear_request       :   in std_logic; -- tells framebuffer to clear back 
              tet_drawn           :   in std_logic; -- tells framebuffer tet is complete
              write_x, write_y    :   in std_logic_vector(7 downto 0); -- address to write
              write_en            :   in std_logic;
              pixel_x, pixel_y    :   in std_logic_vector(9 downto 0); -- address to read
              video_on            :   in std_logic;
              -- note takes in HS and VS unlike the VGA setup because need to slow them down due to reading BRAM
              HS_in               :   in std_logic;
              VS_in               :   in std_logic;
              ready_to_draw       :   out std_logic;
              clear_fulfilled     :   out std_logic; -- tells manager back buff is cleared
              done_drawing        :   out std_logic;
              VGA_HS              :   out std_logic;
              VGA_VS              :   out std_logic;
              VGA_out             :   out std_logic_vector(11 downto 0) -- framebuffer data, 8 bit for an 8 bit color
           );
end component;

component bresenham_receiver is
    Port (clk              :       in std_logic;
      new_vertices         :       in  std_logic; -- from central controller, signals there are new verticies ready
      vertices             :       in  array_4x16_t;
      clear_request        :       out std_logic;
      clear_fulfilled      :       in std_logic;
      tet_drawn            :       out std_logic; -- tells framebuffer that we have finished drawing tet
      load_mem             :       out std_logic;
      x, y                 :       out std_logic_vector(7 downto 0)
       );
end component;

-- signal declarations
signal video_on          : STD_LOGIC;
signal HS_sig, VS_sig    : std_logic;
signal color             : STD_LOGIC_VECTOR(11 downto 0);

signal write_x, write_y  : std_logic_vector(7 downto 0);
signal write_en          : std_logic;
signal pixel_x, pixel_y  : std_logic_vector(9 downto 0);

signal clear_fulfilled, clear_request, tet_drawn_sg, ready_to_draw_sg, done_drawing_sg : std_logic;

begin

vga_control : vga_controller 
    Port Map(
        clk => sys_clk, 
        video_on => video_on,
        H_sync => HS_sig,
        V_sync => VS_sig,
        pixel_x => pixel_x,
        pixel_y => pixel_y);
framebuff : framebuffer
    Port Map(clk => sys_clk,
          write_x => write_x,
          write_y => write_y,
          write_en => write_en,
          pixel_x => pixel_x,
          pixel_y => pixel_y,
          video_on => video_on,
          HS_in => HS_sig, 
          VS_in => VS_sig,
          
          tet_drawn => tet_drawn_sg,
          clear_request => clear_request,
          clear_fulfilled => clear_fulfilled,
          ready_to_draw    => ready_to_draw_sg,
          done_drawing    => done_drawing_sg,
          VGA_HS => HS, -- final (delayed) VS/HS
          VGA_VS => VS,
          VGA_out => color);
bres_rec : bresenham_receiver
    Port Map(
    clk => sys_clk,
    new_vertices => draw_new_points,
    vertices => packets,
    clear_request => clear_request,
    clear_fulfilled => clear_fulfilled,
    tet_drawn => tet_drawn_sg,
    load_mem => write_en,
    x => write_x,
    y => write_y
    );

-- tie output signals
ready_to_draw <= ready_to_draw_sg;
done_drawing <= done_drawing_sg;

-- wire the correct colors by slicing up color vector into groups of 4
red <= color(11) & color(10) & color(9) & color(8);
green <= color(7) & color(6) & color(5) & color(4);
blue <= color(3) & color(2) & color(1) & color(0);

end Behavioral;
