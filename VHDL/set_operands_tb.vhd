library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity set_operands_tb is 
end set_operands_tb;

architecture testbench of set_operands_tb is 

component set_operands_rot is 
  port ( 
  clk_port : in std_logic; 
  dir      : in std_logic_vector(1 downto 0);
  x,y,z    : in std_logic_vector(23 downto 0); 
  operands : out array_3x24_t; 
  set_port : out std_logic); 
end component; 

  signal clk_port     : std_logic := '0'; 
  signal dir          : std_logic_vector(1 downto 0)  := "00";
  signal operands     : array_3x24_t := (others => (others => '0'));
  signal set_port     : std_logic := '0';

  constant x          : std_logic_vector(23 downto 0) := x"014000"; --  20.0 
  constant y          : std_logic_vector(23 downto 0) := x"00A000"; --  10.0 
  constant z          : std_logic_vector(23 downto 0) := x"FF1000"; -- -15.0 
  constant clk_period : time := 10 ns; 

begin 

uut: set_operands_rot  
port map (
    clk_port => clk_port, 
    dir      => dir, 
    x        => x, 
    y        => y, 
    z        => z, 
    operands => operands, 
    set_port => set_port); 

clock_proc: process 
begin 
  clk_port <= not(clk_port);
  wait for clk_period/2;
end process; 

stim_proc: process 
begin 
  -- Keeping points constant, showing that it sets operators right for each rotation
  dir        <= "00";     -- Set for rotation about x 
  wait for 2*clk_period; 

  dir        <= "01";     -- rotation about y 
  wait for 2*clk_period; 

  dir        <= "10";     -- z 
  wait; 
end process; 

end architecture testbench; 
