----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/18/2025 04:58:45 PM
-- Design Name: 
-- Module Name: graphics_manager_tb - Behavioral
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
entity graphics_manager_tb is
--  Port ( );
end graphics_manager_tb;

architecture Behavioral of graphics_manager_tb is
component graphics_manager is
Port (clk                  :       in std_logic;
      new_vertices         :       in  std_logic; -- from central controller, signals there are new vertices ready
      vertices             :       in  array_4x16_t;
      clear_fulfilled         :       in std_logic;
      
      clear_request           :       out std_logic; -- control signal to tell framebuffer to clear back
      tet_drawn   :       out std_logic; -- control signal to tell framebuffer bres is finished
      load_mem             :       out std_logic;
      x, y                 :       out std_logic_vector(7 downto 0)
);
end component;

-- signal declarations
constant PERIOD : time := 10 ns;
-- inputs
signal clk : std_logic;
signal new_vertices  : std_logic := '0';
signal vertices : array_4x16_t := (others => (others => '0')); 
-- outputs
signal load_mem : std_logic;
signal x, y : std_logic_vector(7 downto 0);
signal clear_fulfilled : std_logic := '1'; -- bypassign clear fulfilled by putting it to 1
begin
uut: graphics_manager
    Port Map(clk => clk,
             new_vertices => new_vertices,
             vertices => vertices,
             clear_fulfilled => clear_fulfilled,
             clear_request => open,
             tet_drawn => open,
             load_mem => load_mem, 
             x => x,
             y => y);

clk_proc : process
    begin
    clk <= '0';
    wait for PERIOD / 2;  

    clk <= '1';
    wait for PERIOD / 2;
end process clk_proc;

stim_proc : process
begin
    wait for PERIOD / 2 - 1 ns;
    -- Example 4 points (each 16-bit: x high byte, y low byte)
    vertices(0) <= x"2937"; -- x=16, y=32
    vertices(1) <= x"d637"; -- x=64, y=80
    vertices(2) <= x"00c8"; -- x=112, y=96
    vertices(3) <= x"0000"; -- x=48, y=16
    --vertices(0) <= x"10" & x"20"; -- x=16, y=32
    --vertices(1) <= x"40" & x"50"; -- x=64, y=80
    --vertices(2) <= x"70" & x"60"; -- x=112, y=96
    --vertices(3) <= x"30" & x"10"; -- x=48, y=16

    -- Trigger new_vertices
    new_vertices <= '1';
    wait for PERIOD;
    new_vertices <= '0';

    -- Wait long enough for all 6 lines to be drawn
    wait for 1000 ns;
--    vertices(0) <= x"10" & x"20"; -- x=16, y=32
--    vertices(1) <= x"40" & x"50"; -- x=64, y=80
--    vertices(2) <= x"70" & x"60"; -- x=112, y=96
--    vertices(3) <= x"30" & x"10"; -- x=48, y=16
--    new_vertices <= '1';
--    wait for PERIOD;
--    new_vertices <= '0';
    wait;
end process stim_proc;
end Behavioral;
