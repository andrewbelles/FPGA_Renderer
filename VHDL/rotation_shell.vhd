library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 

entity matmul_shell is 
port( 
  clk_port   : in std_logic; 
  angle      : in std_logic_vector(15 downto 0);
  dir        : in std_logic_vector(1 downto 0);
  x, y, z    : in std_logic_vector(15 downto 0); 
  nx, ny, nz : out std_logic_vector(15 downto 0));
end matmul_shell; 

architecture behavioral of matmul_shell is 
----------------------- component declarations ---------------------------
component set_operands_m16x16 is 
  port (
    clk_port : in std_logic;
    dir      : in std_logic_vector(1 downto 0);
    x,y,z    : in std_logic_vector(15 downto 0);
    operand1 : out std_logic_vector(15 downto 0);
    operand2 : out std_logic_vector(15 downto 0);
    set_port : out std_logic);
end set_operands_m16x16;

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
    sine     : out std_logic_vector(15 downto 0); 
    set_port : out std_logic); 
end component;

----------------------- local declarations -------------------------------
-- types 
  type product_4x16_t is array (0 to 3) of std_logic_vector(15 downto 0);  

-- signals
  signal sine, cosine         : std_logic_vector(15 downto 0);
  signal inv_sine             : std_logic_vector(15 downto 0);
  signal operand1, operand2   : std_logic_vector(15 downto 0);
  signal cosine_set, sine_set : std_logic;
  signal operand_set, load_en : std_logic; 
  signal products             : product_4x16_t := (others => (others => '0'));

-- constants 
  -- digit counts 
  constant dig14 : std_logic_vector(3 downto 0) := x"E";
  constant dig8  : std_logic_vector(3 downto 0) := x"8";
begin 

get_sin: sine_lut
  port map(
    clk_port => clk_port,
    cos_en   => '0',
    rads     => angle,
    sine     => sine,
    set_port => sine_set); 

get_cos: sine_lut
  port map(
    clk_port => clk_port,
    cos_en   => '1',
    rads     => angle,
    sine     => cosine,
    set_port => cosine_set); 

get_operands: set_operands_m16x16
  port map(
    clk_port => clk_port, 
    dir      => dir, 
    x        => x, 
    y        => y, 
    z        => z, 
    operand1 => operand1, 
    operand2 => operand2,
    set_port => operand_set); 


-- TODO: Write without variable? 
-- sensitive to sine and cosine
invert_sine: process( sine )
  variable invert_helper : signed(15 downto 0) := (others => '0');
begin 
  invert_helper := -signed(sine); 
  inv_sine      <= std_logic_vector(invert_helper); 
end process invert_sine; 

-- sets load_en once all values are set, pulled from rom 
set_load: process( sine_set, cosine_set, operand_set )
begin 
  load_en <= '0';
  if (sine_set = '1' and cosine_set = '1' and operand_set = '1') then 
    load_en <= '1';
  end if;
end process set_load; 

-- Once we've loaded operators and have trig values proceed with matmul

prod1: multipler_16x16
  port map(
    clk_port   => clk_port, 
    load_port  => load_en, 
    reset_port => OPEN,
    A          => operand1,
    B          => cosine,
    A_dig      => dig8,
    B_dig      => dig14,
    AB         => products(0), 
    AB_dig     => OPEN);

prod2: multipler_16x16
  port map(
    clk_port   => clk_port, 
    load_port  => load_en, 
    reset_port => OPEN,
    A          => operand1,
    B          => sine,
    A_dig      => dig8,
    B_dig      => dig14,
    AB         => products(1), 
    AB_dig     => OPEN);

prod3: multipler_16x16
  port map(
    clk_port   => clk_port, 
    load_port  => load_en, 
    reset_port => OPEN,
    A          => operand2,
    B          => cosine,
    A_dig      => dig8,
    B_dig      => dig14,
    AB         => products(2), 
    AB_dig     => OPEN);

prod4: multipler_16x16
  port map(
    clk_port   => clk_port, 
    load_port  => load_en, 
    reset_port => OPEN,
    A          => operand2,
    B          => inv_sine,
    A_dig      => dig8,
    B_dig      => dig14,
    AB         => products(3), 
    AB_dig     => OPEN);

update_point: 

end behavioral; 
