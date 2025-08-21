library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity update_point_tb is 
end entity update_point_tb;

architecture testbench of update_point_tb is 
component update_point_24b is 
port (
  clk_port     : in std_logic; 
  load_port    : in std_logic; 
  reset_port   : in std_logic; 
  angle        : in array_2x16_t;   -- 3.12 fixed point
  dir          : in array_2x2_t;
  angle_count  : in std_logic_vector(1 downto 0);
  x, y, z      : in std_logic_vector(23 downto 0);  
  nx, ny, nz   : out std_logic_vector(23 downto 0);
  point_packet : out std_logic_vector(15 downto 0);
  set_port     : out std_logic);
end component update_point_24b;

  signal clk_port     : std_logic := '0'; 
  signal load_port    : std_logic := '0'; 
  signal reset_port   : std_logic := '0'; 
  signal angle        : array_2x16_t := (others => (others => '0'));
  signal dir          : array_2x2_t  := (others => (others => '0'));
  signal angle_count  : std_logic_vector(1 downto 0)  := (others => '0');
  signal x, y, z      : std_logic_vector(23 downto 0) := (others => '0');
  signal nx, ny, nz   : std_logic_vector(23 downto 0) := (others => '0');
  signal point_packet : std_logic_vector(15 downto 0) := (others => '0');
  signal set_port     : std_logic := '0'; 

  constant clk_period : time := 10 ns; 
begin 

clock_proc: process 
begin 
  clk_port <= not(clk_port);
  wait for clk_period/2; 
end process clock_proc; 

stim_proc: process 
begin 
  load_port <= '1'; 
  x <= x"FF6000";      -- -10 
  y <= x"FF6000";      -- -10 
  z <= x"FD8000";      -- -40
  angle(0) <= x"0861"; --  30
  angle(1) <= x"1922"; --  90
  dir(0)   <= "00";    -- x
  dir(1)   <= "01";    -- y
  angle_count <= "01";
  wait for 50*clk_period; 

  load_port  <= '0';
  reset_port <= '1'; 
  wait for 2*clk_period; 
  load_port  <= '1'; 
  reset_port <= '0';
  x <= x"00A000";      --  10 
  y <= x"FF6000";      -- -10 
  z <= x"FD8000";      -- -40
  angle(0) <= x"0861"; --  30
  angle(1) <= x"1922"; --  90
  dir(0)   <= "00";    -- x
  dir(1)   <= "01";    -- y
  angle_count <= "01";
  wait for 50*clk_period; 

  load_port  <= '0';
  reset_port <= '1'; 
  wait for 2*clk_period; 
  load_port  <= '1'; 
  reset_port <= '0';
  x <= x"000000";      --   0 
  y <= x"00A000";      --  10 
  z <= x"FD8000";      -- -40
  angle(0) <= x"0861"; --  30
  angle(1) <= x"1922"; --  90
  dir(0)   <= "00";    -- x
  dir(1)   <= "01";    -- y
  angle_count <= "01";
  wait for 50*clk_period; 

  load_port  <= '0';
  reset_port <= '1'; 
  wait for 2*clk_period; 
  load_port  <= '1'; 
  reset_port <= '0';
  x <= x"000000";      --  0 
  y <= x"000000";      --  0 
  z <= x"FEC000";      -- -20
  angle(0) <= x"0861"; --  30
  angle(1) <= x"1922"; --  90
  dir(0)   <= "00";    -- x
  dir(1)   <= "01";    -- y
  angle_count <= "01";
  wait; 
end process stim_proc;

end architecture testbench ;
