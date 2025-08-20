----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/15/2025 03:41:32 PM
-- Design Name: 
-- Module Name: bresenham_testbench - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bresenham_testbench is
--  Port ( );
end bresenham_testbench;

architecture Behavioral of bresenham_testbench is
    component bresenham is
        Port (clk, reset        :   in std_logic;
              start             :   in std_logic;
              x0, y0, x1, y1    :   in std_logic_vector(10 downto 0);
              plot              :   out std_logic;    
              x, y              :   out std_logic_vector(10 downto 0);
              done              :   out std_logic
             );    
    end component;
    
    constant PERIOD : time := 10 ns;
    signal clk, reset, start, plot, done      : std_logic;
    signal x0, y0, x1, y1, x, y               : std_logic_vector(10 downto 0);
begin
uut : bresenham
    Port Map(clk => clk, 
             reset => reset, 
             start => start, 
             plot => plot, 
             done => done, 
             x0 => x0, 
             y0 => y0, 
             x1 => x1, 
             y1 => y1, 
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
    -- test from (0,0) to (4,7)
    x0 <= x"20";
    y0 <= x"f0";
    x1 <= x"10";
    y1 <= x"82"; 
    
  --  start <= '1';
   -- wait for PERIOD;
   -- start <= '0';
   -- wait for 8*PERIOD;
   
   -- x0 <= "00000000101";
   -- y0 <= "00000000011";
  --  x1 <= "00000000110";
  --  y1 <= "00000000100";
  --  start <= '1';
  --  wait for PERIOD;
   -- start <= '0';
   -- wait for 8* period;
    
    -- testing from top left to bottom right of screen
    --x0 <= "00000000000"; -- 0
   -- y0 <= "00000000000"; -- 0
   -- x1 <= "01010000000"; -- 640
   -- y1 <= "00111100000"; -- 480
    --start <= '1';
  --  wait for PERIOD;
--    x0 <= "00000000";
--    y0 <= "00000000";
--    x1 <= "10000000";
--    y1 <= "10000000";
    
--    start <= '1';
--    wait for PERIOD;
--    start <= '0';
    wait;
end process stim_proc;

end Behavioral;
