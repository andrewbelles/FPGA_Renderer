library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity newtons_method_tb is 
end newtons_method_tb;

architecture testbench of newtons_method_tb is 

component newtons_method is 
  port ( 
    clk_port   : in std_logic; 
    load_port  : in std_logic; 
    reset_port : in std_logic;
    mantissa   : in std_logic_vector(23 downto 0); 
    seed       : in std_logic_vector(23 downto 0);   -- q6.17
    root       : out std_logic_vector(23 downto 0);  -- 11.12
    set_port   : out std_logic); 
end component; 

component newton_lut is  
  port (
    clk_port   : in std_logic; 
    reset_port : in std_logic; 
    addr       : in std_logic_vector(9 downto 0); 
    seed       : out std_logic_vector(23 downto 0); -- 6.17 signed fixed point 
    set_port   : out std_logic);  
end component; 

  signal clk_port     : std_logic := '0'; 
  signal reset_port   : std_logic := '0'; 
  signal lut_set      : std_logic := '0'; 
  signal set_port     : std_logic := '0';
  signal addr         : std_logic_vector(9 downto 0)  := (others => '0'); 
  signal mantissa     : std_logic_vector(23 downto 0) := (others => '0'); 
  signal seed         : std_logic_vector(23 downto 0) := (others => '0'); 
  signal root         : std_logic_vector(23 downto 0) := (others => '0');

  constant clk_period : time := 10 ns; 

begin 

-- NB: We must test both simultaneously as the newtons_method entity is highly dependent upon the lut 
lut_uut: newton_lut 
  port map(
    clk_port   => clk_port,
    reset_port => reset_port, 
    addr       => addr, 
    seed       => seed, 
    set_port   => lut_set);

uut: newtons_method
 port map(
    clk_port   => clk_port,
    load_port  => lut_set,
    reset_port => reset_port, 
    mantissa   => mantissa,
    seed       => seed,
    root       => root,
    set_port   => set_port);


clock_proc: process 
begin 
  clk_port <= not(clk_port);
  wait for clk_period/2;
end process; 

stim_proc: process 
begin 

  -- Expected: Seed = 0x020000, Root = 0x001000
  reset_port <= '1'; 
  wait for clk_period; 
  reset_port <= '0'; 
  mantissa <= x"400000"; -- 1.0 
  addr <= mantissa(21 downto 12);
  wait for 15*clk_period; 

  -- Expected: Seed = 0x01F0B7, Root = 0x00107E
  reset_port <= '1'; 
  wait for clk_period; 
  reset_port <= '0'; 
  mantissa <= x"440000"; -- 1.0625
  addr <= mantissa(21 downto 12);
  wait for 15*clk_period; 

  -- Expected: Seed = 0x01E2B8, Root = 0x0010F8
  reset_port <= '1'; 
  wait for clk_period; 
  reset_port <= '0'; 
  mantissa <= x"480000"; -- 1.125 
  addr <= mantissa(21 downto 12);
  wait for 15*clk_period; 

  -- Expected: Seed = 0x018309, Root = 0x00152A
  reset_port <= '1'; 
  wait for clk_period; 
  reset_port <= '0'; 
  mantissa <= x"700000"; -- 1.75
  addr <= mantissa(21 downto 12);
  wait; 
end process; 

end architecture testbench; 
