library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity _tb is 
end _tb;

architecture testbench of _tb is 

component  is 
  port ( 
       );
end component; 

  signal clk_port     : std_logic := '0'; 

  constant clk_period : time := 10 ns; 

begin 

uut:  
port map (

         );


clock_proc: process 
begin 
  clk_port <= not(clk_port);
  wait for clk_period/2;
end process; 

stim_proc: process 
begin 

end process; 

end architecture testbench; 
