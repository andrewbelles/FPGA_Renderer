library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity reciprocal_24b is 
  port (
    clk_port   : in std_logic; 
    load_port  : in std_logic;
    reset_port : in std_logic; 
    value      : in std_logic_vector(23 downto 0);    -- q11.12 value to mul invert    
    reciprocal : out std_logic_vector(23 downto 0);   -- q11.12
    set_port   : out std_logic); 
end entity reciprocal_24b;

architecture behavioral of reciprocal_24b is 
----------------------- components ---------------------------------------
component newton_lut  -- gets seed for newtons method 
  port (
    clk_port   : in std_logic; 
    reset_port : in std_logic; 
    addr       : in std_logic_vector(9 downto 0); 
    seed       : out std_logic_vector(23 downto 0); -- 6.17 signed fixed point 
    set_port   : out std_logic);  
end component newton_lut; 

component newton_24b  -- interface that executes 2 step newtons-rhapson   
  port (
    clk_port   : in std_logic; 
    load_port  : in std_logic; 
    reset_port : in std_logic;
    mantissa   : in std_logic_vector(23 downto 0); 
    seed       : in std_logic_vector(23 downto 0);   -- q6.17
    root       : out std_logic_vector(23 downto 0);  -- q6.17
    set_port   : out std_logic); 
end component newton_24b;
----------------------- declarations -------------------------------------
-- state declarations 
  type state_type is ( idle, load, find_msb, normalize, seed, newtons, shift, done );   
  signal current_state : state_type := idle; 
  signal next_state    : state_type := idle; 

-- enables set by output of fsm
  signal load_en       : std_logic := '0'; 
  signal msb_en        : std_logic := '0'; 
  signal seed_en       : std_logic := '0';
  signal reset_en      : std_logic := '0'; 
  signal normalize_en  : std_logic := '0';
  signal newton_en     : std_logic := '0';
  signal shift_en      : std_logic := '0'; 
  signal set_en        : std_logic := '0';

-- set_port signal from newton_24b 
  signal newton_set    : std_logic := '0';
  signal shift_set     : std_logic := '0'; 
  signal msb_set       : std_logic := '0'; 

-- constant addr,seed pair being fetched. only right once state > seed  
  signal addr          : std_logic_vector(9 downto 0)  := (others => '0');
  signal fetched_seed  : std_logic_vector(23 downto 0) := (others => '0');

-- intermediate signals 
  signal negative      : std_logic := '0';
  signal exponent      : signed(4 downto 0)            := (others => '0');
  signal magnitude     : unsigned(23 downto 0)         := (others => '0');
  signal norm          : unsigned(23 downto 0)         := (others => '0');
  signal reciprocal_sg : signed(23 downto 0)           := (others => '0'); 

  signal pidx          : unsigned(4 downto 0) := (others=>'0');
  signal right_flag    : std_logic := '0';
  signal shift_count   : unsigned(4 downto 0) := (others=>'0');

-- signals for newtons method 
  signal mantissa      : std_logic_vector(23 downto 0) := (others => '0');
  signal newton_seed   : std_logic_vector(23 downto 0) := (others => '0');
  signal root          : std_logic_vector(23 downto 0) := (others => '0');

-- ensure numeric stability
  constant epsilon     : unsigned(23 downto 0)         := x"00019A"; -- 0.1 in 11.12  
begin 

--------------------------------------------------------------------------
-- Input Loading. Compute Distance from 1.22 notation  
--------------------------------------------------------------------------
load_value: process( clk_port )
  variable abs_helper : unsigned(23 downto 0);
begin 

  abs_helper := (others => '0');
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

      magnitude <= abs_helper;
    end if; 
  end if; 
end process load_value;

process( clk_port )
  variable exp_helper : unsigned(23 downto 0) := (others => '0'); 
  variable p          : unsigned(4 downto 0)  := "11111"; 
begin 
  p := "11111";
  exp_helper := magnitude; 

  if rising_edge(clk_port) then 
    if reset_en = '1' then 
      exponent <= (others => '0'); 
    elsif msb_en = '1' then
      -- get count for normalization 
      for i in 22 downto 0 loop 
        -- if p is not set it is at 31, only flags for msb high bit  
        if p = "11111" and exp_helper(i) = '1' then 
          p := to_unsigned(i, 5);
        end if; 
      end loop; 
      -- exponent is how far first high bit is from perceived decimal point   
      exponent  <= signed(p) - 12;
      msb_set <= '1';  

      pidx <= p;  -- registered MSB index
      if p >= 12 then
        right_flag <= '1';
        shift_count  <= p - 12;
      else
        right_flag <= '0';
        shift_count   <= 12 - p;
      end if;
    end if; 
  end if; 
end process; 

--------------------------------------------------------------------------
-- Input normalization  
--------------------------------------------------------------------------
get_norm: process( clk_port )
  variable norm_helper : unsigned(23 downto 0) := (others => '0'); 
  variable s           : integer := 0;
begin
  norm_helper := (others => '0'); 
  s := to_integer(shift_count);
  
  if rising_edge( clk_port ) then
    if reset_en = '1' then 
      norm <= (others => '0');
    elsif normalize_en = '1' then
      -- shift by distance from 1.22 
      if right_flag = '1' then 
        norm <= shift_left(shift_right(magnitude, s), 10);
      else 
        norm <= shift_left(shift_left(magnitude, s), 10); 
      end if; 
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
get_reciprocal: newton_24b
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
  variable helper        : signed(23 downto 0) := (others => '0');
  variable shift_helper  : signed(23 downto 0) := (others => '0');
begin 
  shift_count  := to_integer(exponent); 
  helper := (others => '0'); 
  shift_helper := (others => '0'); 
  
  if rising_edge( clk_port ) then 
    if reset_port = '1' then 
      reciprocal_sg <= (others => '0');
      shift_set <= '0'; 
    elsif shift_en = '1' then
      helper := signed(root); 
        
      if shift_count >= 0 then 
        shift_helper := shift_right(helper, shift_count); 
      else 
        shift_helper := shift_left(helper, -shift_count); 
      end if;
      reciprocal_sg <= shift_helper; 
      shift_set <= '1'; 
    end if; 
  end if; 
end process set_reciprocal;

process( clk_port ) 
  variable helper       : signed(23 downto 0) := (others => '0'); 
  variable round_helper : signed(23 downto 0) := (others => '0'); 
  constant round        : signed(23 downto 0) := x"000010";
begin 
  helper := (others => '0'); 
  if rising_edge(clk_port) then 
    if set_en = '1' then 
      helper := reciprocal_sg;
      if helper(23) = '1' then 
        round_helper := shift_right(helper - round, 5); 
      else 
        round_helper := shift_right(helper + round, 5); 
      end if;
      
      if negative = '1' then 
        reciprocal <= std_logic_vector(-round_helper);
      else
        reciprocal <= std_logic_vector(round_helper);
      end if; 
    end if; 
  end if; 
end process; 
--------------------------------------------------------------------------
-- FSM Logic 
--------------------------------------------------------------------------
next_state_logic: process ( current_state, reset_port, load_port, 
                            msb_set, shift_set, newton_set )
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
        next_state <= find_msb;  -- load takes a single cycle 
      when find_msb => 
        if msb_set = '1' then 
          next_state <= normalize; 
        end if; 
      when normalize => 
        next_state <= seed; 
      when seed => 
        next_state <= newtons;  
      when newtons => 
        if newton_set = '1' then  
          next_state <= shift; 
        end if; 
      when shift =>
        if shift_set = '1' then 
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
  reset_en     <= '0';
  load_en      <= '0'; 
  msb_en       <= '0';
  normalize_en <= '0';
  newton_en    <= '0';
  seed_en      <= '0';
  set_en       <= '0';
  shift_en     <= '0'; 
  case ( current_state ) is 
    when idle => 
      reset_en <= '1'; 
    when load => 
      load_en <= '1'; 
    when find_msb => 
      msb_en <= '1'; 
    when normalize => 
      normalize_en <= '1';
    when seed =>
      seed_en <= '1';
    when newtons => 
      newton_en <= '1';
    when shift => 
      shift_en <= '1'; 
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
