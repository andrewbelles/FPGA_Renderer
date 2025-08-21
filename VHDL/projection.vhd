library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity projection is 
port( 
  clk_port     : in std_logic;
  load_port    : in std_logic; 
  reset_port   : in std_logic; 
  x, y, z      : in std_logic_vector(23 downto 0); 
  point_packet : out std_logic_vector(15 downto 0); -- (8 high x),(8 low y)
  set_port     : out std_logic);
end projection; 

architecture behavioral of projection is 
----------------------- component declarations ---------------------------
component reciprocal_24b 
  port (
    clk_port   : in std_logic; 
    load_port  : in std_logic;
    reset_port : in std_logic; 
    value      : in std_logic_vector(23 downto 0);  -- q11.12 value to mul invert    
    reciprocal : out std_logic_vector(23 downto 0); -- q11.12 reciprocal 
    set_port   : out std_logic); 
end component reciprocal_24b; 

component multiplier_24x24 
  port (
    clk_port   : in std_logic;
    load_port  : in std_logic;  
    reset_port : in std_logic; 
    A, B       : in std_logic_vector(23 downto 0);
    A_dig      : in std_logic_vector(4 downto 0);
    B_dig      : in std_logic_vector(4 downto 0); 
    AB         : out std_logic_vector(23 downto 0);
    AB_dig     : out std_logic_vector(4 downto 0);
    set_port   : out std_logic); 
end component multiplier_24x24; 
  type state_type is ( idle, pool_vals, divide, intercept, done );
  signal current_state, next_state : state_type := idle; 

  signal inv_z          : signed(23 downto 0)           := (others => '0'); 
  signal perspective    : std_logic_vector(23 downto 0) := (others => '0');
  signal points         : array_2x24_t := (others => (others => '0'));
  signal divided_points : array_2x24_t := (others => (others => '0'));
  signal transl_points  : std_logic_vector(15 downto 0) := (others => '0');
  signal pool_set       : std_logic_vector(2 downto 0)  := (others => '0');
  signal divide_set     : std_logic_vector(1 downto 0)  := (others => '0');
  signal pool_done      : std_logic := '0';
  signal divide_done    : std_logic := '0';
  signal intercept_done : std_logic := '0'; 

  signal pool_en        : std_logic := '0';
  signal reset_en       : std_logic := '0';
  signal divide_en      : std_logic := '0'; 
  signal intercept_en   : std_logic := '0';
  signal set_en         : std_logic := '0';

  constant m00          : std_logic_vector(23 downto 0) := x"0014c9";
  constant m11          : std_logic_vector(23 downto 0) := x"001BB6";
  constant d12          : std_logic_vector(4 downto 0)  := "01100";
  constant b            : signed(23 downto 0) := x"000080";
begin 
--------------------------------------------------------------------------
-- Get perspective from 1/z   
--------------------------------------------------------------------------
get_reciprocal: reciprocal_24b 
  port map( 
    clk_port   => clk_port, 
    load_port  => pool_en,
    reset_port => reset_en, 
    value      => z,
    reciprocal => perspective,
    set_port   => pool_set(0));

inv_z <= -signed(z);
--------------------------------------------------------------------------
-- Multiply Perspective Matrix against points  
--------------------------------------------------------------------------
Xc: multiplier_24x24
 port map(
    clk_port   => clk_port,
    load_port  => pool_en,
    reset_port => reset_en,
    A          => x,
    B          => m00,
    A_dig      => d12,
    B_dig      => d12,
    AB         => points(0),
    AB_dig     => OPEN,
    set_port   => pool_set(1)); 

Yc: multiplier_24x24
 port map(
    clk_port   => clk_port,
    load_port  => pool_en,
    reset_port => reset_en,
    A          => y,
    B          => m11,
    A_dig      => d12,
    B_dig      => d12,
    AB         => points(1),
    AB_dig     => OPEN,
    set_port   => pool_set(2)); 

pool_done <= '1' when pool_set = "111" else '0';

--------------------------------------------------------------------------
-- Perspective Divide  
--------------------------------------------------------------------------
divide_Xc: multiplier_24x24
 port map(
    clk_port   => clk_port,
    load_port  => divide_en,
    reset_port => reset_en,
    A          => points(0),
    B          => perspective,
    A_dig      => d12,
    B_dig      => d12,
    AB         => divided_points(0),
    AB_dig     => OPEN,
    set_port   => divide_set(0)); 

divide_Yc: multiplier_24x24
 port map(
    clk_port   => clk_port,
    load_port  => divide_en,
    reset_port => reset_en,
    A          => points(1),
    B          => perspective,
    A_dig      => d12,
    B_dig      => d12,
    AB         => divided_points(1),
    AB_dig     => OPEN,
    set_port   => divide_set(1)); 

divide_done <= '1' when divide_set = "11" else '0';

--------------------------------------------------------------------------
-- Intercept & Round Logic 
--------------------------------------------------------------------------
affine_points: process( divided_points, intercept_en ) 
  variable round    : signed(23 downto 0) := x"000800";
  variable x_round  : signed(23 downto 0) := (others => '0');
  variable y_round  : signed(23 downto 0) := (others => '0');

  variable x_packet : unsigned(7 downto 0) := (others => '0');
  variable y_packet : unsigned(7 downto 0) := (others => '0');
begin 
  round    := x"000800";
  x_packet := (others => '0');
  y_packet := (others => '0');
  x_round  := (others => '0');
  y_round  := (others => '0');

  if intercept_en = '1' then 
    x_round := signed(divided_points(0));
    if x_round(23) = '1' then 
      round := -round; 
    end if; 
   
    x_round := shift_right( shift_left(x_round, 7) + round, 12) + b;

    round := x"000800";
    y_round := -signed(divided_points(1));
    if y_round(23) = '1' then 
      round := -round; 
    end if; 
   
    y_round := shift_right( shift_left(y_round, 7) + round, 12) + b;
    
    transl_points(15 downto 8) <= std_logic_vector(x_round(7 downto 0));
    transl_points(7 downto 0)  <= std_logic_vector(y_round(7 downto 0));
  end if; 
end process affine_points; 

save_point: process( clk_port ) 
begin 
  if rising_edge( clk_port ) then 
    if reset_en = '1' then 
      intercept_done <= '0'; 
      point_packet <= (others => '0');
    elsif intercept_en = '1' or set_en = '1' then  
      intercept_done <= '1';  
      point_packet <= transl_points;
    end if; 
  end if; 
end process save_point; 

--------------------------------------------------------------------------
-- FSM Logic 
--------------------------------------------------------------------------
next_state_logic: process( current_state, reset_port, load_port, pool_done, divide_done, intercept_done )
begin 
  if reset_port = '1' then 
    next_state <= idle; 
  else 
    case ( current_state ) is 
      when idle => 
        next_state <= idle; 
        if load_port = '1' then 
          next_state <= pool_vals; 
        end if;
      when pool_vals =>
        next_state <= pool_vals; 
        if pool_done = '1' then 
          next_state <= divide; 
        end if; 
      when divide => 
        next_state <= divide; 
        if divide_done = '1' then 
          next_state <= intercept; 
        end if; 
      when intercept => 
        next_state <= intercept; 
        if intercept_done = '1' then 
          next_state <= done; 
        end if; 
      when done => 
        next_state <= idle; 
    end case; 
  end if; 
end process next_state_logic; 

set_port <= set_en; 

output_logic: process( current_state )
begin 
  divide_en    <= '0'; 
  pool_en      <= '0';
  intercept_en <= '0'; 
  set_en       <= '0';
  reset_en     <= '0';

  case ( current_state ) is 
    when idle => 
      reset_en <= '1';
    when pool_vals =>
      pool_en <= '1';
    when divide => 
      divide_en <= '1'; 
    when intercept => 
      intercept_en <= '1'; 
    when done => 
      set_en <= '1';
  end case; 

end process output_logic; 

update_state: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    current_state <= next_state; 
  end if; 
end process update_state; 

end architecture behavioral;
