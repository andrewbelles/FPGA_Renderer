library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity rotation is 
port( 
  clk_port   : in std_logic;
  en_port    : in std_logic; 
  reset_port : in std_logic; 
  angle      : in std_logic_vector(15 downto 0);
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

component rotation_mul_24b is 
  port (
    clk_port   : in std_logic; 
    load_en    : in std_logic; 
    dir        : in std_logic_vector(1 downto 0);
    static     : in std_logic_vector(23 downto 0);
    products   : in array_4x24_t; 
    nx, ny, nz : out std_logic_vector(23 downto 0);
    set_port   : out std_logic); 
end component rotation_mul_24b; 

----------------------- local declarations -------------------------------
-- signals
  signal sine, cosine    : std_logic_vector(23 downto 0) := (others => '0');
  signal sin16, cos16    : std_logic_vector(15 downto 0) := (others => '0'); 
  signal inv_sine        : std_logic_vector(23 downto 0) := (others => '0');
  signal operands_sg     : array_3x24_t  := (others => (others => '0'));
  signal operands        : signed_3x24_t := (others => (others => '0'));
  signal products_sg     : array_4x24_t  := (others => (others => '0'));
  signal mul48b          : signed_4x48_t := (others => (others => '0')); 
  signal products        : signed_4x24_t := (others => (others => '0'));
  signal cosine_set      : std_logic := '0'; 
  signal sine_set        : std_logic := '0';
  signal operand_set     : std_logic := '0'; 
  signal multiplier_load : std_logic := '0'; 
  signal rotation_load   : std_logic := '0'; 
  signal update_set      : std_logic := '0';
begin 

get_sin: sine_lut
  port map(
    clk_port => clk_port,
    cos_en   => '0',
    rads     => angle,
    sine     => sin16,
    set_port => sine_set); 

get_cos: sine_lut
  port map(
    clk_port => clk_port,
    cos_en   => '1',
    rads     => angle,
    sine     => cos16,
    set_port => cosine_set); 

get_operands: set_operands_m24x24
  port map(
    clk_port => clk_port, 
    dir      => dir, 
    x        => x, 
    y        => y, 
    z        => z, 
    operands => operands_sg, 
    set_port => operand_set); 

zero_extend_trig: process( sin16, cos16 )
begin 
  sine <= std_logic_vector(resize(signed(sin16), 24));
  cosine <= std_logic_vector(resize(signed(cos16), 24));
end process zero_extend_trig; 

-- sensitive to sine and cosine
invert_sine: process( sine )
  variable invert_helper : signed(23 downto 0) := (others => '0');
begin 
  invert_helper := -signed(sine); 
  inv_sine      <= std_logic_vector(invert_helper); 
end process invert_sine; 

-- sets load_en once all values are set, pulled from rom 
set_load: process( en_port, sine_set, cosine_set, operand_set )
begin 
  multiplier_load <= '0';
  if (en_port = '1' and sine_set = '1'
      and cosine_set = '1' and operand_set = '1') then 
    multiplier_load <= '1';
  end if;
end process set_load; 

-- Once we've loaded operators and have trig values proceed with matmul
mul48b(0) <= resize(operands(1), 48) * resize(signed(cosine), 48); 
mul48b(1) <= resize(operands(1), 48) * resize(signed(sine), 48);
mul48b(2) <= resize(operands(2), 48) * resize(signed(cosine), 48);
mul48b(3) <= resize(operands(2), 48) * resize((-signed(sine)), 48);

products(0) <= shift_right(mul48b(0), 14); 
products(1) <= shift_right(mul48b(1), 14); 
products(2) <= shift_right(mul48b(2), 14); 
products(3) <= shift_right(mul48b(3), 14); 

buffer_enable: process ( clk_port )
begin 
  if rising_edge( clk_port ) then 
    if reset_port = '1' then 
      rotation_load <= '0'; 
    elsif en_port = '1' then 
      rotation_load <= '1'; 
    else 
      rotation_load <= '0';
    end if; 
  end if; 
end process buffer_enable;

update_point: rotation_mul_24b 
  port map(
    clk_port => clk_port,
    load_en  => rotation_load, 
    dir      => dir, 
    static   => operands_sg(0),
    products => products_sg, 
    nx       => nx, 
    ny       => ny, 
    nz       => nz, 
    set_port => update_set); 

process( clk_port ) 
begin 
  if rising_edge( clk_port ) then 
    if reset_port = '1' then 
      set_port <= '0'; 
    elsif update_set = '1' then 
      set_port <= '1';
    else 
      set_port <= '0'; 
    end if; 
  end if; 
end process; 

end behavioral; 
