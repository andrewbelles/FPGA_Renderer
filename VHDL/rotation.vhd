library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity rotation is 
port( 
  clk_port   : in std_logic; 
  angle      : in std_logic_vector(23 downto 0);
  dir        : in std_logic_vector(1 downto 0);
  x, y, z    : in std_logic_vector(23 downto 0); 
  nx, ny, nz : out std_logic_vector(23 downto 0);
  set_port   : out std_logic);
end rotation; 

architecture behavioral of rotation is 
----------------------- component declarations ---------------------------
component sine_lut 
  port (
    clk_port : in std_logic; 
    cos_en   : in std_logic; 
    rads     : in std_logic_vector(15 downto 0); 
    sine     : out std_logic_vector(15 downto 0); 
    set_port : out std_logic); 
end component sine_lut;

component set_operands_m24x24 is 
  port (
    clk_port : in std_logic;
    dir      : in std_logic_vector(1 downto 0);
    x,y,z    : in std_logic_vector(23 downto 0);
    operands : out array_3x24_t; 
    set_port : out std_logic);
end component set_operands_m24x24;

component multiplier_24x24
  port (
    clk_port     : in std_logic;
    load_port    : in std_logic; 
    reset_port   : in std_logic; 
    A, B         : in std_logic_vector(23 downto 0);
    A_dig, B_dig : in std_logic_vector(4 downto 0);
    AB           : out std_logic_vector(23 downto 0);
    AB_dig       : out std_logic_vector(4 downto 0);
    set_port     : out std_logic);
end component multiplier_24x24; 

component rotation_mul_16b is 
  port (
    clk_port   : in std_logic; 
    load_en    : in std_logic; 
    dir        : in std_logic_vector(1 downto 0);
    static     : in std_logic_vector(23 downto 0);
    products   : in array_4x24_t; 
    nx, ny, nz : out std_logic_vector(23 downto 0);
    set_port   : out std_logic); 
end component rotation_mul_16b; 

----------------------- local declarations -------------------------------
-- signals
  signal sine, cosine    : std_logic_vector(23 downto 0);
  signal inv_sine        : std_logic_vector(23 downto 0);
  signal operands        : array_3x24_t := (others => (others => '0'));
  signal cosine_set      : std_logic; 
  signal sine_set        : std_logic;
  signal operand_set     : std_logic; 
  signal multiplier_load : std_logic; 
  signal rotation_load   : std_logic; 
  signal products_set    : std_logic_vector(3 downto 0);
  signal products        : array_4x24_t := (others => (others => '0'));

-- constants 
  -- digit counts 
  constant dig14 : std_logic_vector(4 downto 0)  := "01110";
  constant dig12  : std_logic_vector(4 downto 0) := "01100";
begin 

get_sin: sine_lut
  port map(
    clk_port => clk_port,
    cos_en   => '0',
    rads     => angle,
    sine     => sine(15 downto 0),
    set_port => sine_set); 

get_cos: sine_lut
  port map(
    clk_port => clk_port,
    cos_en   => '1',
    rads     => angle,
    sine     => cosine(15 downto 0),
    set_port => cosine_set); 

get_operands: set_operands_m24x24
  port map(
    clk_port => clk_port, 
    dir      => dir, 
    x        => x, 
    y        => y, 
    z        => z, 
    operands => operands, 
    set_port => operand_set); 

zero_extend_trig: process( sine, cosine )
  variable negative : std_logic := '0'; 
begin 

  negative := '0'; 
  if sine(23) = '1' then 
    negative := '1'; 
  end if; 

  sine(23 downto 16) <= negative & "0000000";

  negative := '0'; 
  if cosine(23) = '1' then 
    negative := '1'; 
  end if; 

  cosine(23 downto 16) <= negative & "0000000";
end process zero_extend_trig; 

-- sensitive to sine and cosine
invert_sine: process( sine )
  variable invert_helper : signed(23 downto 0) := (others => '0');
begin 
  invert_helper := -signed(sine); 
  inv_sine      <= std_logic_vector(invert_helper); 
end process invert_sine; 

-- sets load_en once all values are set, pulled from rom 
set_load: process( sine_set, cosine_set, operand_set )
begin 
  multiplier_load <= '0';
  if (sine_set = '1' and cosine_set = '1' and operand_set = '1') then 
    multiplier_load <= '1';
  end if;
end process set_load; 

-- Once we've loaded operators and have trig values proceed with matmul

prod1: multiplier_24x24
  port map(
    clk_port   => clk_port, 
    load_port  => multiplier_load, 
    reset_port => '0',
    A          => operands(1),
    B          => cosine,
    A_dig      => dig12,
    B_dig      => dig14,
    AB         => products(0), 
    AB_dig     => OPEN,
    set_port   => products_set(0));

prod2: multiplier_24x24
  port map(
    clk_port   => clk_port, 
    load_port  => multiplier_load, 
    reset_port => '0',
    A          => operands(1),
    B          => sine,
    A_dig      => dig12,
    B_dig      => dig14,
    AB         => products(1), 
    AB_dig     => OPEN,
    set_port   => products_set(1));

prod3: multiplier_24x24
  port map(
    clk_port   => clk_port, 
    load_port  => multiplier_load, 
    reset_port => '0',
    A          => operands(2),
    B          => cosine,
    A_dig      => dig12,
    B_dig      => dig14,
    AB         => products(2), 
    AB_dig     => OPEN,
    set_port   => products_set(2));

prod4: multiplier_24x24
  port map(
    clk_port   => clk_port, 
    load_port  => multiplier_load, 
    reset_port => '0',
    A          => operands(2),
    B          => inv_sine,
    A_dig      => dig12,
    B_dig      => dig14,
    AB         => products(3), 
    AB_dig     => OPEN,
    set_port   => products_set(3));

-- all products must assert completed for rotation to be executed 
set_rotation_load: process( products_set )
begin 
  rotation_load <= '0';
  if products_set = "1111" then 
    rotation_load <= '1';
  end if; 
end process set_rotation_load; 

update_point: rotation_mul_16b 
  port map(
    clk_port => clk_port,
    load_en  => rotation_load, 
    dir      => dir, 
    static   => operands(0),
    products => products, 
    nx       => nx, 
    ny       => ny, 
    nz       => nz, 
    set_port => set_port); 

end behavioral; 
