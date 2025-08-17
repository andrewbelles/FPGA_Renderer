library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 

entity sine_lut_tb is 
  end sine_lut_tb; 

architecture testbench of sine_lut_tb is 
  component sine_lut is 
    port( 
      clk_port   : in std_logic;
      cos_en     : in std_logic; 
      rads       : in std_logic_vector(15 downto 0);
      sine_out   : out std_logic_vector(15 downto 0));
  end component; 

signal clk_port : std_logic := '0'; 
signal rads     : std_logic_vector(15 downto 0) := (others => '0');
signal sine_out : std_logic_vector(15 downto 0) := (others => '0');

constant clk_period : time := 10 ns; 

begin 
uut: sine_lut 
port map(
  clk_port => clk_port, 
  cos_en => cos_en, 
  rads => rads, 
  sine_out => sine_out);

clock_stim: process
begin
  clk_port <= not(clk_port);
  wait for clk_period/2;
end process clock_stim;

stim_proc: process 
begin
  -- pi/2 
  cos_en <= '0'; 
  rads <= x"3244";
  wait for 2*clk_period; 

  -- -pi/2
  rads <= x"cdbc";
  wait for 2*clk_period; 

  -- pi/3 
  rads <= x"2183";
  wait for 2*clk_period; 

  -- -pi/3
  rads <= x"de7d";
  wait for 2*clk_period; 

  -- pi/4 
  rads <= x"1922";
  wait for 2*clk_period; 

  -- -pi/4
  rads <= x"e6de";
  wait for 2*clk_period; 

  -- pi/6
  rads <= x"10c1";
  wait for 2*clk_period; 

  -- -pi/6
  rads <= x"ef3f";
  wait for 2*clk_period; 

  -- pi 
  rads <= x"6488";
  wait for 2*clk_period; 

  -- -pi
  rads <= x"9b78";
  wait for 2*clk_period;

  -- pi/2 
  cos_en <= '1'; 
  rads <= x"3244";
  wait for 2*clk_period; 

  -- -pi/2
  rads <= x"cdbc";
  wait for 2*clk_period; 

  -- pi/3 
  rads <= x"2183";
  wait for 2*clk_period; 

  -- -pi/3
  rads <= x"de7d";
  wait for 2*clk_period; 

  -- pi/4 
  rads <= x"1922";
  wait for 2*clk_period; 

  -- -pi/4
  rads <= x"e6de";
  wait for 2*clk_period; 

  -- pi/6
  rads <= x"10c1";
  wait for 2*clk_period; 

  -- -pi/6
  rads <= x"ef3f";
  wait for 2*clk_period; 

  -- pi 
  rads <= x"6488";
  wait for 2*clk_period; 

  -- -pi
  rads <= x"9b78";
  wait; 
end process stim_proc;

end;
