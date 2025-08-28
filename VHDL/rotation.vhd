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

component set_operands_rot is 
  port (
    clk_port : in std_logic;
    dir      : in std_logic_vector(1 downto 0);
    x,y,z    : in std_logic_vector(23 downto 0);
    operands : out array_3x24_t; 
    set_port : out std_logic);
end component set_operands_rot;

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
end component accumulate_rotation; 

----------------------- local declarations -------------------------------
-- signals
  signal sine, cosine    : std_logic_vector(23 downto 0) := (others => '0');
  signal sin_sg, cos_sg  : signed(23 downto 0) := (others => '0');
  signal inv_sin_sg      : signed(23 downto 0) := (others => '0');
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
  signal trig_load       : std_logic := '0'; 
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

get_operands: set_operands_rot
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
set_load: process( clk_port )
begin 
  if rising_edge(clk_port) then
    if reset_port = '1' then 
      trig_load <= '0'; 
      operands <= (others => (others => '0'));
    elsif (en_port = '1' and sine_set = '1'
        and cosine_set = '1' and operand_set = '1') then 
      trig_load <= '1';
      for i in 0 to 2 loop  
        operands(i) <= signed(operands_sg(i));
      end loop; 
    else  
      trig_load <= '0'; 
    end if;
  end if; 
end process set_load; 

process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    if reset_port = '1' then 
      sin_sg     <= (others => '0');
      inv_sin_sg <= (others => '0');
      cos_sg  <= (others => '0');
      multiplier_load <= '0';
    elsif trig_load = '1' then 
      sin_sg <= signed(sine);
      cos_sg <= signed(cosine);
      inv_sin_sg <= signed(inv_sine);
      multiplier_load <= '1'; 
    else 
      multiplier_load <= '0'; 
    end if; 
  end if; 
end process;

-- Once we've loaded operators and have trig values proceed with matmul
process ( clk_port ) 
begin 
  if rising_edge( clk_port ) then 
    if reset_port = '1' then 
      mul48b <= (others => (others => '0')); 
      rotation_load <= '0'; 
    elsif multiplier_load = '1' then 
      rotation_load <= '1'; 
      mul48b(0) <= operands(1) * cos_sg; 
      mul48b(1) <= operands(1) * sin_sg;
      mul48b(2) <= operands(2) * cos_sg;
      mul48b(3) <= operands(2) * inv_sin_sg;
    else
      rotation_load <= '0'; 
    end if; 
  end if; 
end process; 

process ( mul48b ) 
begin 
  for i in 0 to 3 loop 
    products(i) <= shift_right(mul48b(i), 14)(23 downto 0);   
  end loop; 
end process; 

process ( products ) 
begin 
  for i in 0 to 3 loop 
    products_sg(i) <= std_logic_vector(products(i));
  end loop; 
end process; 

update_point: accumulate_rotation 
  port map(
    clk_port   => clk_port,
    reset_port => reset_port, 
    load_en    => rotation_load, 
    dir        => dir, 
    static     => operands_sg(0),
    products   => products_sg, 
    nx         => nx, 
    ny         => ny, 
    nz         => nz, 
    set_port   => update_set); 

process( clk_port ) 
begin 
  if rising_edge( clk_port ) then 
    if reset_port = '1' then 
      set_port <= '0'; 
    elsif update_set = '1' then 
      set_port <= '1';
    end if; 
  end if; 
end process; 

end behavioral; 
