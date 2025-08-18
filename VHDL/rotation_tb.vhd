library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity rotation_tb is 
end rotation_tb;

architecture testbench of rotation_tb is 
----------------------- component declarations ---------------------------
component rotation is 
  port (
    clk_port   : in std_logic; 
    angle      : in std_logic_vector(15 downto 0);
    dir        : in std_logic_vector(1 downto 0);
    x, y, z    : in std_logic_vector(15 downto 0); 
nx, ny, nz : out std_logic_vector(15 downto 0);
    set_port   : out std_logic);
end component; 

----------------------- local declarations -------------------------------
-- signals 
  signal clk_port   : std_logic := '0'; 
  signal angle      : std_logic_vector(15 downto 0) := (others => '0');
  signal dir        : std_logic_vector(1 downto 0)  := (others => '0');
  signal x, y, z    : std_logic_vector(15 downto 0) := (others => '0');
  signal nx, ny, nz : std_logic_vector(15 downto 0) := (others => '0');
  signal set_port   : std_logic := '0';
-- constants 
  constant clk_period : time := 100 ns; 

begin 

uut: rotation 
  port map(
    clk_port => clk_port, 
    angle    => angle, 
    dir      => dir, 
    x        => x, 
    y        => y, 
    z        => z, 
    nx       => nx, 
    ny       => ny, 
    nz       => nz, 
    set_port => set_port);

clock_proc: process 
begin 
  clk_port <= not(clk_port);
  wait for clk_period/2; 
end process clock_proc; 

stim_proc: process 
begin 
  -- x,y,z will remain constant the entire tb 
  x <= x"3200"; -- 50.0
  y <= x"4600"; -- 70.0
  z <= x"2800";

  -- 30 degree rotation about x 
  angle <= x"0861"; 
  dir   <= x"0"; 
  wait for 5*clk_period;

  -- (-30) degree rotation about x 
  angle <= x"5c27"; 
  dir   <= x"0"; 
  --wait for 5*clk_period;
  wait; 
end process stim_proc; 

end;  
