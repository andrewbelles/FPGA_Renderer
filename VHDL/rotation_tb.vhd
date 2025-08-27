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
    en_port    : in std_logic; 
    reset_port : in std_logic; 
    angle      : in std_logic_vector(15 downto 0);
    dir        : in std_logic_vector(1 downto 0);
    x, y, z    : in std_logic_vector(23 downto 0); 
    nx, ny, nz : out std_logic_vector(23 downto 0);
    set_port   : out std_logic);
end component; 

----------------------- local declarations -------------------------------
-- signals 
  signal clk_port   : std_logic := '0'; 
  signal en_port    : std_logic := '0'; 
  signal reset_port : std_logic := '0'; 
  signal angle      : std_logic_vector(15 downto 0) := (others => '0');
  signal dir        : std_logic_vector(1 downto 0)  := (others => '0');
  signal nx, ny, nz : std_logic_vector(23 downto 0) := (others => '0');
  signal set_port   : std_logic := '0';
-- constants 
  constant clk_period : time := 10 ns; 
  constant x          : std_logic_vector(23 downto 0) := x"01A000";
  constant y          : std_logic_vector(23 downto 0) := x"01A000";
  constant z          : std_logic_vector(23 downto 0) := x"FE6000";

begin 

uut: rotation 
  port map(
    clk_port   => clk_port,
    en_port    => en_port,
    reset_port => reset_port,  
    angle      => angle, 
    dir        => dir, 
    x          => x, 
    y          => y, 
    z          => z, 
    nx         => nx, 
    ny         => ny, 
    nz         => nz, 
    set_port   => set_port);

clock_proc: process 
begin 
  clk_port <= not(clk_port);
  wait for clk_period/2; 
end process clock_proc; 

stim_proc: process 
begin 
  -- x,y,z will remain constant the entire tb 
  -- 30 degree rotation about x 
  -- Expect ~ 0x023844, 0xff67bc
  en_port <= '1';  
  angle   <= x"0861"; 
  dir     <= "00"; 
  wait for 8*clk_period;

  reset_port <= '1';
  en_port    <= '0'; 
  wait for 2*clk_period; 
  reset_port <= '0';
  en_port    <= '1'; 
  -- (-30) degree rotation about x 
  -- Expect ~ 0x009844, 0xfdc7bc
  angle <= x"5c27"; 
  dir   <= "00"; 
  wait for 8*clk_period;
  
  reset_port <= '1';
  en_port <= '0';
  wait for 2*clk_period; 
  reset_port <= '0';
  en_port <= '1'; 
  -- 45 degree rotation about y
  -- Expect ~ 0x0, 0xfdb3b0
  angle <= x"0c91"; 
  dir   <= "01"; 
  wait for 8*clk_period;
  
  reset_port <= '1';
  en_port <= '0'; 
  wait for 2*clk_period; 
  reset_port <= '0';
  en_port <= '1'; 
  -- 15 degree rotation about z
  -- Expect 0x012628, 0x01fd7e
  angle <= x"0430"; 
  dir   <= "10"; 
  wait; 
end process stim_proc; 

end;  
