library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity reciprocal is 
  port (
    clk_port   : in std_logic; 
    load_port  : in std_logic;
    reset_port : in std_logic; 
    value      : in std_logic_vector(23 downto 0);    -- q11.12 value to mul invert    
    reciprocal : out std_logic_vector(23 downto 0);   -- q11.12
    set_port   : out std_logic); 
end entity reciprocal;

architecture behavioral of reciprocal is 
----------------------- components ---------------------------------------
component newton_lut  -- gets seed for newtons method 
  port (
    clk_port   : in std_logic; 
    reset_port : in std_logic; 
    addr       : in std_logic_vector(9 downto 0); 
    seed       : out std_logic_vector(23 downto 0); -- 6.17 signed fixed point 
    set_port   : out std_logic);  
end component newton_lut; 

component newtons_method  -- interface that executes 2 step newtons-rhapson   
  port (
    clk_port   : in std_logic; 
    load_port  : in std_logic; 
    reset_port : in std_logic;
    mantissa   : in std_logic_vector(23 downto 0); 
    seed       : in std_logic_vector(23 downto 0);   -- q6.17
    root       : out std_logic_vector(23 downto 0);  -- q6.17
    set_port   : out std_logic); 
end component newtons_method;
----------------------- declarations -------------------------------------
-- state declarations 
  type state_type is ( idle, load, normalize, seed, newtons, done );   
  signal current_state : state_type := idle; 
  signal next_state    : state_type := idle; 

-- enables set by output of fsm
  signal load_en       : std_logic := '0'; 
  signal seed_en       : std_logic := '0';
  signal reset_en      : std_logic := '0'; 
  signal normalize_en  : std_logic := '0';
  signal newton_en     : std_logic := '0';
  signal set_en        : std_logic := '0';

-- set_port signal from newtons_method 
  signal newton_set    : std_logic := '0';

-- constant addr,seed pair being fetched. only right once state > seed  
  signal addr          : std_logic_vector(9 downto 0)  := (others => '0');
  signal fetched_seed  : std_logic_vector(23 downto 0) := (others => '0');

-- intermediate signals 
  signal negative      : std_logic := '0';
  signal exponent      : signed(4 downto 0)            := (others => '0');
  signal magnitude     : unsigned(23 downto 0)         := (others => '0');
  signal norm          : unsigned(23 downto 0)         := (others => '0');

-- signals for newtons method 
  signal mantissa      : std_logic_vector(23 downto 0) := (others => '0');
  signal newton_seed   : std_logic_vector(23 downto 0) := (others => '0');
  signal bufr_seed     : std_logic_vector(23 downto 0) := (others => '0');
  signal root          : std_logic_vector(23 downto 0) := (others => '0');

-- ensure numeric stability
  constant epsilon     : unsigned(23 downto 0)         := x"00019A"; -- 0.1 in 11.12  
begin 

--------------------------------------------------------------------------
-- Input Loading. Compute Distance from 1.22 notation  
--------------------------------------------------------------------------
load_value: process( clk_port )
  variable abs_helper : unsigned(23 downto 0);
  variable p          : unsigned(4 downto 0) := "11111";
begin 

  abs_helper := (others => '0');
  p          := "11111";

  if rising_edge( clk_port ) then  
    if reset_en = '1' then 
      magnitude <= (others => '0');
    elsif load_en = '1' then 

      -- get 2's complement magnitude of value 
      if (value(23) = '1') then 
        negative   <= '1';
        abs_helper := unsigned(not(value)) + 1; 
      else 
        negative   <= '0';
        abs_helper := unsigned(value);
      end if; 

      -- avoid division by small number 
      if abs_helper < epsilon then 
        abs_helper := epsilon;  
      end if; 

      -- get count for normalization 
      for i in 22 downto 0 loop 
        -- if p is not set it is at 31, only flags for msb high bit  
        if p = 31 and abs_helper(i) = '1' then 
          p := to_unsigned(i, 5);
        end if; 
      end loop; 

      -- exponent is how far first high bit is from perceived decimal point 
      magnitude <= abs_helper;
      exponent  <= signed(p) - 12; 
    end if; 
  end if; 
end process load_value;

--------------------------------------------------------------------------
-- Input normalization  
--------------------------------------------------------------------------
get_norm: process( clk_port )
  variable shift_count : integer := 0; 
  variable norm_helper : unsigned(23 downto 0) := (others => '0'); 
begin
  shift_count := to_integer(exponent); 
  norm_helper := (others => '0'); 
  
  if rising_edge( clk_port ) then
    if reset_en = '1' then 
      norm <= (others => '0');
    elsif normalize_en = '1' then
      -- shift by distance from 1.22 
      if shift_count >= 0 then 
        norm_helper := shift_right(magnitude, shift_count);
      else 
        norm_helper := shift_left(magnitude, -shift_count); 
      end if; 
      norm <= shift_left(norm_helper, 10);  -- to 1.22
    end if; 
  end if; 
end process get_norm; 

--------------------------------------------------------------------------
-- Get seed from lut   
--------------------------------------------------------------------------
read_seed: newton_lut 
  port map(
    clk_port   => clk_port,
    reset_port => reset_port, 
    addr       => addr, 
    seed       => fetched_seed, 
    set_port   => OPEN);

-- constantly address, will only be correct once 
addr <= std_logic_vector(norm(21 downto 12));
newton_seed <= fetched_seed;

--------------------------------------------------------------------------
-- Newton's Method 
--------------------------------------------------------------------------
get_reciprocal: newtons_method
 port map(
    clk_port   => clk_port,
    load_port  => newton_en,
    reset_port => reset_port, 
    mantissa   => mantissa,
    seed       => newton_seed,
    root       => root,
    set_port   => newton_set
);

mantissa <= std_logic_vector(norm);

--------------------------------------------------------------------------
-- Interface Outputs 
--------------------------------------------------------------------------
set_port <= '1' when set_en = '1' else '0'; 

set_reciprocal: process( clk_port )
  variable shift_count   : integer := 0; 
  variable recip_helper  : signed(23 downto 0) := (others => '0'); 
  constant round         : signed(23 downto 0) := x"000010";
begin 
  shift_count  := to_integer(exponent); 
  recip_helper := (others => '0'); 
  
  if rising_edge( clk_port ) then 
    if reset_port = '1' then 
      reciprocal <= (others => '0');
    elsif set_en = '1' then
      recip_helper := signed(root); 
        
      if shift_count >= 0 then 
        recip_helper := shift_right(recip_helper, shift_count); 
      else 
        recip_helper := shift_left(recip_helper, -shift_count); 
      end if; 
      
      if recip_helper(23) = '1' then 
        recip_helper := shift_right(recip_helper - round, 5); 
      else 
        recip_helper := shift_right(recip_helper + round, 5); 
      end if;
      
      if negative = '1' then 
        reciprocal <= std_logic_vector(-recip_helper);
      else
        reciprocal <= std_logic_vector(recip_helper);
      end if; 
    end if; 
  end if; 
end process set_reciprocal;

--------------------------------------------------------------------------
-- FSM Logic 
--------------------------------------------------------------------------
next_state_logic: process ( current_state, reset_port, load_port, newton_set )
begin 
  if reset_port = '1' then 
    next_state <= idle; 
  else 
    next_state <= current_state;  -- tend to stay in current state 
    case ( current_state ) is 
      when idle => 
        if load_port = '1' then 
          next_state <= load; 
        end if; 
      when load => 
        next_state <= normalize;  -- load takes a single cycle 
      when normalize => 
        next_state <= seed; 
      when seed => 
        next_state <= newtons;  
      when newtons => 
        if newton_set = '1' then  
          next_state <= done; 
        end if; 
      when done => 
        next_state <= idle; 
      when others => 
        null;                     -- no reset & done means we stay done  
    end case; 
  end if; 
end process next_state_logic; 

output_logic: process( current_state )
begin 
  reset_en <= '0';
  load_en <= '0'; 
  normalize_en <= '0';
  newton_en <= '0';
  seed_en <= '0';
  set_en <= '0';
  case ( current_state ) is 
    when idle => 
      reset_en <= '1'; 
    when load => 
      load_en <= '1'; 
    when normalize => 
      normalize_en <= '1';
    when seed =>
      seed_en <= '1';
    when newtons => 
      newton_en <= '1';
    when done => 
      set_en <= '1';
    when others => 
      null;
  end case; 
end process output_logic; 

update_state: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    current_state <= next_state; 
  end if; 
end process update_state; 

end architecture behavioral;
