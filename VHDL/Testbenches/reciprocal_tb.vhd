library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity reciprocal_tb is 
end reciprocal_tb; 
 
architecture testbench of reciprocal_tb is 
----------------------- component declarations ---------------------------
component reciprocal is 
  port (
    clk_port   : in std_logic; 
    load_port  : in std_logic;
    reset_port : in std_logic; 
    value      : in std_logic_vector(23 downto 0);    -- q11.12 value to mul invert    
    reciprocal : out std_logic_vector(23 downto 0);   -- q11.12 reciprocal 
    set_port   : out std_logic); 
end component reciprocal;
----------------------- declarations -------------------------------------
-- signal declarations 
  signal clk_port   : std_logic := '0';
  signal load_port  : std_logic := '0';
  signal reset_port : std_logic := '0';
  signal value      : std_logic_vector(23 downto 0); 
  signal divisor    : std_logic_vector(23 downto 0); 
  signal set_port   : std_logic := '0';

-- constant declarations
  constant clk_period : time := 10 ns; 
begin 

uut: reciprocal 
  port map(
    clk_port   => clk_port, 
    load_port  => load_port,
    reset_port => reset_port,
    value      => value,
    reciprocal => divisor,
    set_port   => set_port);

clock_proc: process 
begin 
  clk_port <= not(clk_port);
  wait for clk_period/2; 
end process clock_proc; 

stim_proc: process 
begin 

  reset_port <= '1';
  wait for 2*clk_period; 
  value <= x"001000"; -- 1.0 
  reset_port <= '0';
  load_port  <= '1'; 
  wait for clk_period;
  load_port  <= '0';
  wait for 15*clk_period;

  -- 0.5 
  reset_port <= '1';
  reset_port <= '1';
  wait for 2*clk_period; 
  value <= x"002000"; -- 2.0 
  reset_port <= '0';
  load_port  <= '1'; 
  wait for clk_period;
  load_port  <= '0';
  wait for 15*clk_period;

  -- 0.1818
  reset_port <= '1';
  wait for 2*clk_period; 
  value <= x"005800"; -- 5.5 
  reset_port <= '0';
  load_port  <= '1'; 
  wait for clk_period;
  load_port  <= '0';
  wait for 15*clk_period;

  -- expect x000141
  reset_port <= '1';
  wait for 2*clk_period; 
  value <= x"00CC00"; -- 12.75
  reset_port <= '0';
  load_port  <= '1'; 
  wait for clk_period;
  load_port  <= '0';
  wait for 15*clk_period;

  -- expect x000029
  reset_port <= '1';
  wait for 2*clk_period; 
  value <= x"063E66"; -- 99.9
  reset_port <= '0';
  load_port  <= '1'; 
  wait for clk_period;
  load_port  <= '0';
  wait for 15*clk_period;

  -- expect x0013FB0
  reset_port <= '1';
  wait for 2*clk_period; 
  value <= x"0000CD"; -- 0.05
  reset_port <= '0';
  load_port  <= '1'; 
  wait for clk_period;
  load_port  <= '0';
  wait for 15*clk_period;

  -- expect FFE000
  reset_port <= '1';
  wait for 2*clk_period; 
  value <= x"FFF800"; -- -0.5 
  reset_port <= '0';
  load_port  <= '1'; 
  wait for clk_period;
  load_port  <= '0';
  wait for 15*clk_period;

  -- expect FFFE70
  reset_port <= '1';
  wait for 2*clk_period; 
  value <= x"FF5C00"; -- -10.25
  reset_port <= '0';
  load_port  <= '1'; 
  wait for clk_period;
  load_port  <= '0';
  wait for 15*clk_period;

  -- expect FFFFD7
  reset_port <= '1';
  wait for 2*clk_period; 
  value <= x"F9C000"; -- -100.0
  reset_port <= '0';
  load_port  <= '1'; 
  wait for clk_period;
  load_port  <= '0';
  wait; 
end process stim_proc; 

end architecture testbench; 
