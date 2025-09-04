----------------------------------------------------------------------------------
-- Ben Sheppard
-- Testbench for framebuffer module.

-- NOTE: not submitting this file because I realized that there is really no point in testing it without receiving appropriate points from bresenham receiver.
-- Instead, will show graphics manager testbench
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

entity framebuffer_tb is
--  Port ( );
end framebuffer_tb;

architecture Behavioral of framebuffer_tb is
component framebuffer is 
    Port (clk                 :   in std_logic;
          clear_request       :   in std_logic; -- tells framebuffer to clear back 
          tet_drawn           :   in std_logic; -- tells framebuffer tet is complete
          write_x, write_y    :   in std_logic_vector(7 downto 0); -- address to write
          write_en            :   in std_logic;
          pixel_x, pixel_y    :   in std_logic_vector(9 downto 0); -- address to read
          video_on            :   in std_logic;
          -- note takes in HS and VS unlike the VGA setup because need to slow them down by 1 clock cycle due to reading BRAM
          HS_in               :   in std_logic;
          VS_in               :   in std_logic;
          ready_to_draw      :   out std_logic;
          clear_fulfilled     :   out std_logic; -- tells manager back buff is cleared
          done_drawing        :   out std_logic;
          VGA_HS              :   out std_logic;
          VGA_VS              :   out std_logic;
          VGA_out             :   out std_logic_vector(11 downto 0) -- framebuffer data, 4 bit for an 4 bit color
        );
end component;

signal clk, clear_request, tet_drawn, write_en, video_on, HS_in, VS_in : std_logic := '0';
signal write_x, write_y                                                : std_logic_vector(7 downto 0) := (others => '0');
signal pixel_x, pixel_y                                                : std_logic_vector(9 downto 0) := (others => '0');
signal ready_to_draw, clear_fulfilled, done_drawing, VGA_HS, VGA_VS    : std_logic;
signal VGA_out                                                         : std_logic_vector(11 downto 0);

constant PERIOD : time := 40 ns;

begin
uut : framebuffer
    Port Map(
        clk => clk,
        clear_request => clear_request, 
        tet_drawn => tet_drawn,
        write_x => write_x,
        write_y => write_y, 
        write_en => write_en,
        pixel_x => pixel_x, 
        pixel_y => pixel_y,
        video_on => video_on,
        HS_in => HS_in,
        VS_in => VS_in,
        ready_to_draw => ready_to_draw,
        clear_fulfilled => clear_fulfilled,
        done_drawing => done_drawing,
        VGA_HS => VGA_HS,
        VGA_out => VGA_out);

clk_proc : process
begin
    clk <= '1';
    wait for PERIOD / 2;  
    
    clk <= '0';
    wait for PERIOD / 2;
end process clk_proc;

stim_proc : process
begin
    wait for PERIOD - 1 ns;
    
    -- bring us to CB state
    clear_request <= '1'; 
    wait for PERIOD; 
    clear_request <= '0';
    
    -- simulate a full clear
    wait for 65536*PERIOD; -- clear fully
    
    -- simulate receiving points
    wait for 10*PERIOD;
    
    -- done drawing
    tet_drawn <= '1';
    wait for PERIOD;
    tet_drawn <= '0';
    
    -- simulates waiting for swap opportunity and asserting done
    wait for 1000*PERIOD;
end process;
    
end Behavioral;
