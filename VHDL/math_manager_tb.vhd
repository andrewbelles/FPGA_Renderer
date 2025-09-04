library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity parallel_math_tb is 
end parallel_math_tb;

architecture testbench of parallel_math_tb is 

component parallel_math is 
  port( 
    clk_port   : in std_logic; 
    load_port  : in std_logic; 
    reset_port : in std_logic; 
    angle      : in array_2x16_t; 
    dir        : in array_2x2_t; 
    points     : in array_4x3x24_t;
    new_points : out array_4x3x24_t; 
    packets    : out array_4x16_t; 
    set_port   : out std_logic);
end component parallel_math; 
  
  signal clk_port   : std_logic := '0'; 
  signal load_port  : std_logic := '0'; 
  signal reset_port : std_logic := '0'; 
  signal angle      : array_2x16_t := (others => (others => '0'));
  signal dir        : array_2x2_t  := (others => (others => '0'));
  signal points     : array_4x3x24_t := (others => (others => (others => '0')));
  signal new_points : array_4x3x24_t := (others => (others => (others => '0')));
  signal packets    : array_4x16_t   := (others => (others => '0'));
  signal set_port   : std_logic := '0'; 

  constant clk_period : time := 10 ns;

begin 


uut: parallel_math 
port map( 
  clk_port   => clk_port,  
  load_port  => load_port, 
  reset_port => reset_port,  
  angle      => angle, 
  dir        => dir, 
  points     => points, 
  new_points => new_points,
  packets    => packets, 
  set_port   => set_port); 

clock_proc: process 
begin 
  clk_port <= not(clk_port); 
  wait for clk_period/2; 
end process clock_proc; 

stim_proc: process 
begin 
  -- set points to be used for the entire test 
  points(0)(0 to 2) <= (x"014000", x"014000", x"014000");
  points(1)(0 to 2) <= (x"014000", x"FEC000", x"FEC000");
  points(2)(0 to 2) <= (x"FEC000", x"014000", x"FEC000");
  points(3)(0 to 2) <= (x"FEC000", x"FEC000", x"014000");
  
  -- Y 30 deg, X 15 deg 
  load_port  <= '1';
  reset_port <= '0';
  angle      <= (x"0861", x"0430");
  dir        <= ("01", "00");
  wait for 35*clk_period; 

  -- Z -30 deg, Y 60 deg 
  reset_port <= '1';
  load_port  <= '0';
  wait for 2*clk_period;
  load_port  <= '1';
  reset_port <= '0';
  angle      <= (x"F79F", x"10C1");
  dir        <= ("10", "01");
  wait for 35*clk_period; 

  -- X 10 deg, Y -60 deg  
  reset_port <= '1';
  load_port  <= '0';
  wait for 2*clk_period;
  load_port  <= '1';
  reset_port <= '0';
  angle      <= (x"02CB", x"EF3F");
  dir        <= ("00", "01");
  wait for 35*clk_period; 

  -- Z 90 deg, X -45 deg  
  reset_port <= '1';
  load_port  <= '0';
  wait for 2*clk_period;
  load_port  <= '1';
  reset_port <= '0';
  angle      <= (x"1922", x"F36F");
  dir        <= ("10", "00");
  wait for 35*clk_period; 

  -- Y 20 deg, Z 10 deg  
  reset_port <= '1';
  load_port  <= '0';
  wait for 2*clk_period;
  load_port  <= '1';
  reset_port <= '0';
  angle      <= (x"0596", x"0430");
  dir        <= ("01", "10");
  wait; 
end process stim_proc;  

end architecture testbench; 
