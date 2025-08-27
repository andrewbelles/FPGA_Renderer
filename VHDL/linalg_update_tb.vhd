library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity update_point_tb is 
end entity update_point_tb;

architecture testbench of update_point_tb is 
component update_point is 
port (
  clk_port     : in std_logic; 
  load_port    : in std_logic; 
  reset_port   : in std_logic; 
  angle        : in array_2x16_t;   -- 3.12 fixed point
  dir          : in array_2x2_t;
  x, y, z      : in std_logic_vector(23 downto 0);  
  nx, ny, nz   : out std_logic_vector(23 downto 0);
  point_packet : out std_logic_vector(15 downto 0);
  set_port     : out std_logic);
end component update_point;

  signal clk_port     : std_logic := '0'; 
  signal load_port    : std_logic := '0'; 
  signal reset_port   : std_logic := '0'; 
  signal angle        : array_2x16_t := (others => (others => '0'));
  signal dir          : array_2x2_t  := (others => (others => '0'));
  signal x, y, z      : std_logic_vector(23 downto 0) := (others => '0');
  signal nx, ny, nz   : std_logic_vector(23 downto 0) := (others => '0');
  signal point_packet : std_logic_vector(15 downto 0) := (others => '0');
  signal set_port     : std_logic := '0'; 

  constant clk_period : time := 10 ns; 
  constant deg5       : std_logic_vector(15 downto 0) := x"0165";
begin 

uut: update_point 
port map( 
  clk_port => clk_port, 
  load_port => load_port, 
  reset_port => reset_port, 
  angle => angle, 
  dir => dir, 
  x => x,
  y => y, 
  z => z, 
  nx => nx, 
  ny => ny, 
  nz => nz, 
  point_packet => point_packet, 
  set_port => set_port); 

clock_proc: process 
begin 
  clk_port <= not(clk_port);
  wait for clk_period/2; 
end process clock_proc; 

stim_proc: process 
begin 
  load_port  <= '0';
  reset_port <= '1'; 
  wait for 2*clk_period; 
  load_port <= '1'; 
  reset_port <= '0'; 
  x <= x"01A000"; -- 12.0  
  y <= x"01A000"; -- 12.0 
  z <= x"FE6000"; -- -12.0
  angle(0) <= deg5; -- 5
  angle(1) <= deg5; -- 5
  dir(0)   <= "01";    -- x
  dir(1)   <= "00";    -- y 
  wait for 25*clk_period; 

  load_port  <= '0';
  reset_port <= '1'; 
  wait for 2*clk_period; 
  load_port  <= '1'; 
  reset_port <= '0';
  x <= x"01A000"; -- 12.0 
  y <= x"FE6000"; -- -12.0
  z <= x"01A000"; -- 12.0
  angle(0) <= deg5; --  5
  angle(1) <= deg5; --  5
  dir(0)   <= "00";    -- x
  dir(1)   <= "01";    -- y
  wait for 25*clk_period; 

  load_port  <= '0';
  reset_port <= '1'; 
  wait for 2*clk_period; 
  load_port  <= '1'; 
  reset_port <= '0';
  x <= x"FE6000"; -- -12.0 
  y <= x"01A000"; -- -12.0
  z <= x"FE6000"; -- -12.0
  angle(0) <= deg5; --  5
  angle(1) <= deg5; --  5
  dir(0)   <= "00";    -- x
  dir(1)   <= "01";    -- y
  wait for 25*clk_period; 

  load_port  <= '0';
  reset_port <= '1'; 
  wait for 2*clk_period; 
  load_port  <= '1'; 
  reset_port <= '0';
  x <= x"FE6000"; -- -12.0 
  y <= x"FE6000"; -- -12.0
  z <= x"FE6000"; -- -12.0
  angle(0) <= deg5; --  5
  angle(1) <= deg5; --  5
  dir(0)   <= "00";    -- x
  dir(1)   <= "01";    -- y
  wait for 25*clk_period; 
  
  load_port  <= '0';
  reset_port <= '1'; 
  wait for 2*clk_period; 
  load_port <= '1'; 
  reset_port <= '0'; 
  x <= x"01A000"; -- 12.0  
  y <= x"01A000"; -- 12.0 
  z <= x"FE6000"; -- -12.0
  angle(0) <= deg5; -- 5
  angle(1) <= deg5; -- 5
  dir(0)   <= "01";    -- x
  dir(1)   <= "10";    -- y 
  wait for 25*clk_period; 

  load_port  <= '0';
  reset_port <= '1'; 
  wait for 2*clk_period; 
  load_port  <= '1'; 
  reset_port <= '0';
  x <= x"01A000"; -- 12.0 
  y <= x"FE6000"; -- -12.0
  z <= x"01A000"; -- 12.0
  angle(0) <= deg5; --  5
  angle(1) <= deg5; --  5
  dir(0)   <= "01";    -- x
  dir(1)   <= "10";    -- y
  wait for 25*clk_period; 

  load_port  <= '0';
  reset_port <= '1'; 
  wait for 2*clk_period; 
  load_port  <= '1'; 
  reset_port <= '0';
  x <= x"FE6000"; -- -12.0 
  y <= x"01A000"; -- -12.0
  z <= x"FE6000"; -- -12.0
  angle(0) <= deg5; --  5
  angle(1) <= deg5; --  5
  dir(0)   <= "01";    -- x
  dir(1)   <= "10";    -- y
  wait for 25*clk_period; 

  load_port  <= '0';
  reset_port <= '1'; 
  wait for 2*clk_period; 
  load_port  <= '1'; 
  reset_port <= '0';
  x <= x"FE6000"; -- -12.0 
  y <= x"FE6000"; -- -12.0
  z <= x"FE6000"; -- -12.0
  angle(0) <= deg5; --  5
  angle(1) <= deg5; --  5
  dir(0)   <= "01";    -- x
  dir(1)   <= "10";    -- y
  wait; 
end process stim_proc;

end architecture testbench ;
