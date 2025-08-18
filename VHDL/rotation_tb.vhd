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
  signal signed

begin 

uut: rotation 
  port map(
    
          );

clock_proc: process 
begin 

end process clock_proc; 

stim_proc: process 
begin 

end process stim_proc; 

end;  
