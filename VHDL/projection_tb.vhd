library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity projection_tb is 
end projection_tb;

architecture testbench of projection_tb is 

component projection is 
  port( 
    clk_port     : in std_logic;
    load_port    : in std_logic; 
    reset_port   : in std_logic; 
    x, y, z      : in std_logic_vector(23 downto 0); 
    point_packet : out std_logic_vector(15 downto 0); -- (8 high x),(8 low y)
    set_port     : out std_logic);
end component projection; 

  signal clk_port     : std_logic := '0'; 
  signal load_port    : std_logic := '0'; 
  signal reset_port   : std_logic := '0'; 
  signal x, y, z      : std_logic_vector(23 downto 0) := (others => '0');
  signal point_packet : std_logic_vector(15 downto 0) := (others => '0');
  signal set_port     : std_logic := '0'; 

  constant clk_period : time := 10 ns; 
begin 

uut: projection 
  port map( 
    clk_port     => clk_port, 
    load_port    => load_port, 
    reset_port   => reset_port, 
    x            => x, 
    y            => y, 
    z            => z, 
    point_packet => point_packet, 
    set_port     => set_port);
  
clock_proc: process 
begin
  clk_port <= not(clk_port); 
  wait for clk_period/2; 
end process clock_proc; 

stim_proc: process 
begin 

  load_port  <= '1';
  wait for clk_period; 
  load_port <= '0';
  x <= x"FF6000"; -- 5.0 
  y <= x"FF6000"; -- 5.0 
  z <= x"FD8000"; -- -20.0
  wait for 49*clk_period; 

  -- (45, 73) := (0x2D, 0x49)
  reset_port <= '1'; 
  load_port  <= '0';
  wait for 2*clk_period; 
  reset_port <= '0'; 
  load_port  <= '1';
  wait for clk_period; 
  load_port  <= '0';
  x <= x"00A000"; -- -20.0 
  y <= x"FF6000"; -- 10.0
  z <= x"FD8000"; -- -40.0
  wait for 50*clk_period; 
  
  -- (45, 73) := (0x2D, 0x49)
  reset_port <= '1'; 
  load_port  <= '0';
  wait for 2*clk_period; 
  reset_port <= '0'; 
  load_port  <= '1';
  wait for clk_period; 
  load_port  <= '0';
  x <= x"000000"; -- -20.0 
  y <= x"00A000"; -- 10.0
  z <= x"FD8000" ; -- -40.0
  -- wait for 50*clk_period; 
  wait for 50*clk_period; 
  
  -- (45, 73) := (0x2D, 0x49)
  reset_port <= '1'; 
  load_port  <= '0';
  wait for 2*clk_period; 
  reset_port <= '0'; 
  load_port  <= '1';
  wait for clk_period; 
  load_port  <= '0';
  x <= x"000000"; -- -20.0 
  y <= x"000000"; -- 10.0
  z <= x"FEC000"; -- -40.0
  -- wait for 50*clk_period; 
  wait; 


end process stim_proc;

end architecture testbench; 
