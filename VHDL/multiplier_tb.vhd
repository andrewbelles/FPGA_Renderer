library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 

entity multiplier_24x24_tb is 
end multiplier_24x24_tb; 

architecture testbench of multiplier_24x24_tb is 
  component multiplier_24x24 is 
    port(
      clk_port    : in std_logic;  
      load_port   : in std_logic;
      reset_port  : in std_logic; 
      A, B        : in std_logic_vector(23 downto 0);
      A_dig       : in std_logic_vector(4 downto 0);
      B_dig       : in std_logic_vector(4 downto 0); 
      AB          : out std_logic_vector(23 downto 0);
      AB_dig      : out std_logic_vector(4 downto 0);
      set_port    : out std_logic);
  end component; 

signal clk_port, load_en : std_logic := '0';
signal reset_port        : std_logic := '0'; 
signal A, B              : std_logic_vector(23 downto 0) := (others => '0');
signal A_dig             : std_logic_vector(4 downto 0)  := (others => '0');
signal B_dig             : std_logic_vector(4 downto 0)  := (others => '0');
signal AB                : std_logic_vector(23 downto 0) := (others => '0');
signal AB_dig            : std_logic_vector(4 downto 0) := (others => '0');
signal set_port          : std_logic := '0'; 

constant clk_period : time := 10 ns;

begin 
uut: multiplier_24x24 
port map(
  clk_port   => clk_port,
  load_port  => load_en,
  reset_port => reset_port,
  A          => A, 
  B          => B, 
  A_dig      => A_dig,
  B_dig      => B_dig,
  AB         => AB,
  AB_dig     => AB_dig,
  set_port   => set_port);

clock_proc: process 
begin
  clk_port <= not(clk_port);
  wait for clk_period/2;
end process clock_proc;

stim_proc : process
begin
  -- A: 4.625 B: 16.125 -> AB: 74.578125
  -- AB, 11.12 -> 0x04A940
  A       <= x"004A00";
  A_dig   <= "01100";          
  B       <= x"010200";
  B_dig   <= "01100";
  load_en <= '1';
  wait for 8*clk_period;

  reset_port    <= '1'; 
  wait for 2*clk_period; 
  reset_port    <= '0'; 

  -- A: -0.70710678 B: 43.78125 -> AB: -30.9580
  -- AB, 11.12 -> 0xFE10AC
  A       <= x"FFF4B0";
  A_dig   <= "01100";
  B       <= x"02BC80";
  B_dig   <= "01100";
  load_en <= '1';
  wait for 8*clk_period;
  
  reset_port    <= '1'; 
  wait for 2*clk_period; 
  reset_port    <= '0'; 
  
  -- A: 18.421875 B: -4.12475191 -> AB: -75.985664
  -- AB, 11.12 -> -75.98566 -> 0xFB403B
  A       <= x"0126C0";
  A_dig   <= "01100";
  B       <= x"FFBE01";
  B_dig   <= "01100";
  load_en <= '1';
  wait;
end process;

end;
