library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 

entity multiplier_16x16_tb is 
end multiplier_16x16_tb; 

architecture testbench of multiplier_16x16_tb is 
  component multiplier_16x16 is 
    port(
      clk_port    : in std_logic;  
      load_port   : in std_logic;
      A, B        : in std_logic_vector(15 downto 0);
      A_dig       : in std_logic_vector(3 downto 0);
      B_dig       : in std_logic_vector(3 downto 0); 
      AB          : out std_logic_vector(15 downto 0));
  end component; 

signal clk_port, load_sample : std_logic := '0';
signal A_sample, B_sample    : std_logic_vector(15 downto 0);
signal A_dig_sample          : std_logic_vector(3 downto 0);
signal B_dig_sample          : std_logic_vector(3 downto 0);
signal AB_sample             : std_logic_vector(15 downto 0);

constant clk_period : time := 10 ns;

begin 
uut: multiplier_16x16 
port map(
  clk_port => clk_port,
  load_port => load_sample,
  A => A_sample, 
  B => B_sample, 
  A_dig => A_dig_sample,
  B_dig => B_dig_sample,
  AB => AB_sample);
clock_proc: process 
begin
  clk_port <= not(clk_port);
  wait for clk_period/2;
end process clock_proc;

stim_proc: process 
begin  
  -- 10.5 x 12.3 -> 7.8
  -- A  := 4.625
  -- B  := 16.125 
  -- AB := 74.57812500 : 0x4a94 
  A_sample <= x"0094";
  A_dig_sample <= x"5";
  B_sample <= x"0081";
  B_dig_sample <= x"3";
  load_sample <= '1'; 
  wait for 3*clk_period;

  -- (-)2.14 x 7.8 -> (-)7.8
  -- A  := -0.70710678118655
  -- B  := 43.78125
  -- AB := -30.95801876 : 0xe10b
  A_sample <= x"d2bf";
  A_dig_sample <= x"E";
  B_sample <= x"2bc8";
  B_dig_sample <= x"8";
  load_sample <= '1'; 
  wait for 3*clk_period;

  -- 7.8 x (-)7.8 -> (-)7.8
  -- A  := 18.421875 
  -- B  := -4.12475191
  -- AB := -75.98566409 : 0xb404
  A_sample <= x"126c";
  A_dig_sample <= x"8";
  B_sample <= x"fbe0";
  B_dig_sample <= x"8";
  load_sample <= '1'; 
  wait for 3*clk_period;

end process stim_proc; 

end;
