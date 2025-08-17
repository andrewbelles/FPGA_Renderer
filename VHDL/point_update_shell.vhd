library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 

entity matmul_shell is 
port( 
  clk__port  : in std_logic; 
  angle      : in std_logic_vector(15 downto 0);
  direction  : in std_logic_vector(1 downto 0);
  x, y, z    : in std_logic_vector(15 downto 0); 
  nx, ny, nz : out std_logic_vector(15 downto 0));
end matmul_shell; 

architecture behavioral of matmul_shell is 
component multipler_16x16
  port (
    clk_port     : in std_logic;
    load_port    : in std_logic; 
    reset_port   : in std_logic; 
    A, B         : in std_logic_vector(15 downto 0);
    A_dig, B_dig : in std_logic_vector(3 downto 0);
    AB           : out std_logic_vector(15 downto 0);
    AB_dig       : out std_logic_vector(3 downto 0));
end component; 

component sine_lut 
  port (
    clk_port : in std_logic; 
    cos_en   : in std_logic; 
    rads     : in std_logic_vector(15 downto 0); 
    sine     : out std_logic_vector(15 downto 0)); 
end component;

------------------------
-- signals
------------------------
signal load : std_logic := 0; 
signal cos, sin : signed(15 downto 0) := (others => '0');
signal p1, p2, p3, p4 : signed(15 downto 0) := (others => '0');
signal A, B : signed(15 downto 0) := (others => '0');
signal A_dig, B_dig : unsigned(3 downto 0) := (others => '0');

get_sin: sine_lut
  port map(
    clk_port => clk_port,
    cos_en => '0',
    rads => angle,
    sine => sin); 

get_cos: sine_lut
  port map(
    clk_port => clk_port,
    cos_en => '1',
    rads => angle,
    sine => cos); 

-- TODO: Build the interface that controls which values are sent to be multiplied 

prod1: multipler_16x16
  port map(
    clk_port => clk_port, 
    load_port => load, 
    reset_port => OPEN,
    A => std_logic_vector(A),
    B => std_logic_vector(B),
    A_dig => std_logic_vector(A_dig),
    B_dig => std_logic_vector(B_dig),
    AB => p1, 
    AB_dig => OPEN);

prod2: multipler_16x16
  port map(
    clk_port => clk_port, 
    load_port => load, 
    reset_port => OPEN,
    A => std_logic_vector(A),
    B => std_logic_vector(B),
    A_dig => std_logic_vector(A_dig),
    B_dig => std_logic_vector(B_dig),
    AB => p2, 
    AB_dig => OPEN);

prod3: multipler_16x16
  port map(
    clk_port => clk_port, 
    load_port => load, 
    reset_port => OPEN,
    A => std_logic_vector(A),
    B => std_logic_vector(B),
    A_dig => std_logic_vector(A_dig),
    B_dig => std_logic_vector(B_dig),
    AB => p2, 
    AB_dig => OPEN);

prod3: multipler_16x16
  port map(
    clk_port => clk_port, 
    load_port => load, 
    reset_port => OPEN,
    A => std_logic_vector(A),
    B => std_logic_vector(B),
    A_dig => std_logic_vector(A_dig),
    B_dig => std_logic_vector(B_dig),
    AB => p2, 
    AB_dig => OPEN);

-- TODO: Interface to take p1, p2, p3, p4, v and build the new point vector 

end behavioral; 
