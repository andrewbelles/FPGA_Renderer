library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 

entity multiplier_16b16_tb is 
end multiplier_16b16_tb; 

architecture testbench of multiplier_16b16_tb is 
  component multiplier_16b16 is 
    port(
      clk_port, load_port : in std_logic;
      A, B : in std_logic_vector(15 downto 0);
      A_dec_count : in std_logic_vector(3 downto 0);
      B_dec_count : in std_logic_vector(3 downto 0); 
      AB          : out std_logic_vector(15 downto 0));
  end component; 

signal clk_port, load_sample : std_logic := '0';
signal A_sample, B_sample : std_logic_vector(15 downto 0);
signal A_dec_count_sample : std_logic_vector(3 downto 0);
signal B_dec_count_sample : std_logic_vector(3 downto 0);
signal AB_sample : std_logic_vector(15 downto 0);

constant clk_period : time := 10 ns;

begin 
uut: multiplier_16b16 
port map(
  clk_port => clk_port,
  load_port => load_sample,
  A => A_sample, 
  B => B_sample, 
  A_dec_count => A_dec_count_sample,
  B_dec_count => B_dec_count_sample);

clock_proc: process 
begin
  clk_port <= not(clk_port);
  wait for clk_period/2;
end process clock_proc;

stim_proc: process 
begin 

end process stim_proc; 

end;
