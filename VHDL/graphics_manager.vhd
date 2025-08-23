----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/13/2025 06:24:13 PM
-- Design Name: 
-- Module Name: graphics_manager - Behavioral
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
entity graphics_manager is
Port ( clk_ext_port	  : in  std_logic;	-- mapped to external IO device (100 MHz Clock)
       points         : in array_4x16_t;
       draw_new_points     : in std_logic;
       tet_drawn      : out std_logic;
       can_draw            : out std_logic;
       red            : out std_logic_vector(3 downto 0);
       green          : out std_logic_vector(3 downto 0);
       blue           : out std_logic_vector(3 downto 0);
       HS             : out std_logic;
       VS             : out std_logic 		
 );
end graphics_manager;

architecture Behavioral of graphics_manager is

component vga_controller is 
    Port ( clk : in STD_LOGIC; --100 MHz clock
           video_on : out STD_LOGIC;
           V_sync : out STD_LOGIC;
           H_sync : out STD_LOGIC;
           pixel_x : out STD_LOGIC_VECTOR(9 downto 0);
           pixel_y : out STD_LOGIC_VECTOR(9 downto 0));
end component;

component framebuffer is
      Port (clk               :   in std_logic;
          write_x, write_y    :   in std_logic_vector(7 downto 0); -- addess to write
          write_en            :   in std_logic;
          pixel_x, pixel_y    :   in std_logic_vector(9 downto 0); -- address to read
          video_on            :   in std_logic;
          -- note takes in HS and VS unlike the VGA setup because need to slow them down by 1 clock cycle due to reading BRAM
          HS_in               :   in std_logic;
          VS_in               :   in std_logic;
        
          VGA_HS              :   out std_logic;
          VGA_VS              :   out std_logic;
          VGA_out             :   out std_logic_vector(11 downto 0); -- framebuffer data
          
          clear_fulfilled : out std_logic;
          clear_request : in std_logic;
          tet_drawn : in std_logic;
          ready_to_start : out std_logic
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
--signal dummy_reset       : std_logic;
--signal dummy_nv          : std_logic;
--signal dummy_vertices    : array_4x16_t;

signal clear_fulfilled, clear_request, tet_drawn_sg, ready_to_start_sg : std_logic;

-- test signal 
signal pulse_counter : integer := 0;

begin

-- wire the controller
vga_control : vga_controller 
    Port Map(
        clk => clk_ext_port, -- uses the 100MHz FPGA clock
        video_on => video_on,
        H_sync => HS_sig,
        V_sync => VS_sig,
        pixel_x => pixel_x,
        pixel_y => pixel_y);
framebuff : framebuffer
    Port Map(clk => clk_ext_port,
          write_x => write_x,
          write_y => write_y,
          write_en => write_en,
          -- give framebuffer the delayed pixel_x and pixel_y because BRAM read takes 2 cycles
          pixel_x => pixel_x,
          pixel_y => pixel_y,
          video_on => video_on,
          HS_in => HS_sig, 
          VS_in => VS_sig,
          
          tet_drawn => tet_drawn_sg,
          clear_request => clear_request,
          clear_fulfilled => clear_fulfilled,
          ready_to_start    => ready_to_start_sg,
          VGA_HS => HS, -- final VS/HS
          VGA_VS => VS,
          VGA_out => color);
bres_rec : bresenham_receiver
    Port Map(
    clk => clk_ext_port,
    new_vertices => draw_new_points,
    vertices => points,
    clear_request => clear_request,
    clear_fulfilled => clear_fulfilled,
    tet_drawn => tet_drawn_sg,
    load_mem => write_en,
    x => write_x,
    y => write_y
    );

-- tie output signal 
tet_drawn <= tet_drawn_sg;
ready <= ready_to_start_sg;
--test_vertices: process(clk_ext_port)
--begin
--    if rising_edge(clk_ext_port) then
--        -- hold dummy vertices
--            dummy_vertices(0) <= x"d3a2";
--            dummy_vertices(1) <= x"d9a2";
--            dummy_vertices(2) <= x"d35d";
--            dummy_vertices(3) <= x"d95d";

--        -- increment counter
--        pulse_counter <= pulse_counter + 1;

--        -- generate one-clock pulse for new_vertices
--        if pulse_counter = 1000000 then  -- adjust for timing
--            dummy_nv <= '1';
--            pulse_counter <= 0;
--        else
--            dummy_nv <= '0';
--        end if;
--    end if;
--end process;

-- PROBLEM POINT: 
--dummy_vertices(0) <= x"2937";
--dummy_vertices(1) <= x"d637";
--dummy_vertices(2) <= x"00c8";
--dummy_vertices(3) <= x"0000";
-- Doesn't work for 215,55 to 0,0 but worked for all other ones. Very horizonatl slope 


-- worked (from ANDY
--dummy_vertices(0) <= x"a948";
--dummy_vertices(1) <= x"5648";
--dummy_vertices(2) <= x"80b7";
----dummy_vertices(3) <= x"8080";



---- Animation driver: loads a new 4-vertex set every TICKS_PER_FRAME clocks,
---- pulses dummy_nv for exactly one clock.
--test_vertices : process(clk_ext_port)
--begin
--  if rising_edge(clk_ext_port) then
--    if frame_tick_cnt = TICKS_PER_FRAME-1 then
--      frame_tick_cnt <= 0;

--      dummy_vertices(0) <= FRAMES(frame_idx)(0);
--      dummy_vertices(1) <= FRAMES(frame_idx)(1);
--      dummy_vertices(2) <= FRAMES(frame_idx)(2);
--      dummy_vertices(3) <= FRAMES(frame_idx)(3);

--      dummy_nv <= '1';

--      if frame_idx = NUM_FRAMES-1 then
--        frame_idx <= 0;
--      else
--        frame_idx <= frame_idx + 1;
--      end if;
--    else
--      frame_tick_cnt <= frame_tick_cnt + 1;
--      dummy_nv <= '0';
--    end if;
--  end if;
--end process;
    
-- wire the correct colors by slicing up color vector into groups of 4
red <= color(11) & color(10) & color(9) & color(8);
green <= color(7) & color(6) & color(5) & color(4);
blue <= color(3) & color(2) & color(1) & color(0);

end Behavioral;
