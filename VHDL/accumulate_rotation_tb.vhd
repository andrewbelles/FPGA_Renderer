library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity accumulate_rotation_tb is 
end accumulate_rotation_tb;

architecture testbench of accumulate_rotation_tb is 

component accumulate_rotation is 
  port ( 
    clk_port   : in std_logic; 
    load_en    : in std_logic; 
    reset_port : in std_logic; 
    dir        : in std_logic_vector(1 downto 0); 
    static     : in std_logic_vector(23 downto 0);
    products   : in array_4x24_t;  
    nx, ny, nz : out std_logic_vector(23 downto 0);
    set_port   : out std_logic); 
end component; 

  signal clk_port     : std_logic := '0'; 
  signal reset_port   : std_logic := '0'; 
  signal load_en      : std_logic := '0'; 
  signal dir          : std_logic_vector(1 downto 0) := "00";
  signal nx, ny, nz   : std_logic_vector(23 downto 0) := (others => '0');
  signal set_port     : std_logic := '0'; 

  constant static     : std_logic_vector(23 downto 0) := x"014000";
  constant products   : array_4x24_t := (x"00A0000", x"011521", x"00A0000", x"FEEADF");
  constant clk_period : time := 10 ns; 
begin 

uut: accumulate_rotation 
port map (
    clk_port   => clk_port,
    reset_port => reset_port, 
    load_en    => load_en, 
    dir        => dir, 
    static     => static,
    products   => products, 
    nx         => nx, 
    ny         => ny, 
    nz         => nz, 
    set_port   => set_port); 

clock_proc: process 
begin 
  clk_port <= not(clk_port);
  wait for clk_period/2; 
end process; 

stim_proc: process 
begin 
  -- Products will be computed from 20.0 * trig(pi/4)
  -- That is, (x,y,z) => (20.0, 20.0, 20.0) and products remains const 
  -- Expect -7.32 ~ FF8ADF and 27.32 ~ 01B521 for non-static outputs in nr 

  reset_port <= '1'; 
  load_en    <= '0'; 
  wait for clk_period; 
  reset_port <= '0'; 
  load_en    <= '1'; 
  dir        <= "00";     -- Accumulate in x 
  wait for 7*clk_period; 
  
  reset_port <= '1'; 
  load_en    <= '0'; 
  wait for clk_period; 
  reset_port <= '0'; 
  load_en    <= '1'; 
  dir        <= "01";     -- y
  wait for 7*clk_period; 

  reset_port <= '1'; 
  load_en    <= '0'; 
  wait for clk_period; 
  reset_port <= '0'; 
  load_en    <= '1'; 
  dir        <= "10";     -- z 
  wait; 
end process; 

end architecture testbench; 
