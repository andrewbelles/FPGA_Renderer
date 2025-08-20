library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity newton_24b is 
  port (
    clk_port   : in std_logic; 
    load_port  : in std_logic; 
    reset_port : in std_logic;
    mantissa   : in std_logic_vector(23 downto 0); 
    seed       : in std_logic_vector(23 downto 0);   -- q6.17
    root       : out std_logic_vector(23 downto 0);  -- 11.12
    set_port   : out std_logic); 
end entity newton_24b; 

architecture behavioral of newton_24b is 
----------------------- components ---------------------------------------
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
----------------------- declarations -------------------------------------
-- state declarations 
  type state_type is ( idle, prod1, bufr, prod2, done ); 
  signal current_state, next_state : state_type := idle;

-- enables 
  signal reset_en      : std_logic := '0';
  signal set_en        : std_logic := '0';
  signal mul_en        : std_logic := '0';
  signal first_mul_en  : std_logic := '0';
  signal second_mul_en : std_logic := '0';

-- auxilliary signals 
  signal mul_set       : std_logic := '0'; 
  signal clear_mul     : std_logic := '0';

-- signals for multiplication 
  signal A, B          : std_logic_vector(23 downto 0) := (others => '0'); 
  signal A_dig, B_dig  : std_logic_vector(4 downto 0) := (others => '0'); 
  signal AB_dig        : std_logic_vector(4 downto 0) := (others => '0'); 
  signal AB            : std_logic_vector(23 downto 0) := (others => '0');
  signal diff, sRoot   : signed(23 downto 0) := (others => '0');
  signal prod_helper   : signed(23 downto 0) := (others => '0');

-- 2 represented as a 11.12 fixed point value 
  constant two_1112    : signed(23 downto 0) := x"002000";
begin 

--------------------------------------------------------------------------
-- Call to multiplier  
--------------------------------------------------------------------------
multiply: multiplier_24x24
 port map(
    clk_port   => clk_port,
    load_port  => mul_en,
    reset_port => clear_mul, 
    A          => A,
    B          => B,
    A_dig      => A_dig,
    B_dig      => B_dig,
    AB         => AB, -- 11.12
    AB_dig     => AB_dig,
    set_port   => mul_set);

-- set as flopped output values 
root     <= std_logic_vector(sRoot);
set_port <= set_en; 

--------------------------------------------------------------------------
-- Select proper operands for multiplication (Async) 
--------------------------------------------------------------------------
A <= mantissa               when first_mul_en = '1' else 
     std_logic_vector(diff) when second_mul_en = '1' else 
     (others => '0'); 
A_dig <= "10110" when first_mul_en = '1' else 
         "01100" when second_mul_en = '1' else 
         "00000";
B     <= seed; 
B_dig <= "10001";

--------------------------------------------------------------------------
-- Set intermediate and final values in memory 
--------------------------------------------------------------------------

prod_helper <= signed(AB);
set_prods: process( clk_port )
begin 

  if rising_edge( clk_port ) then 
    if reset_en = '1' then 
      diff <= (others => '0');
      sRoot <= (others => '0');

    elsif mul_set = '1' then 
      -- safe to clear now 
      if first_mul_en = '1' then 
        diff <= two_1112 - prod_helper;

      elsif second_mul_en = '1' then 
        sRoot <= prod_helper;
      end if; 
    end if; 
  end if; 
end process set_prods; 

--------------------------------------------------------------------------
-- FSM Logic 
--------------------------------------------------------------------------
next_state_logic: process( current_state, reset_port, load_port, mul_set )
begin 
  if reset_port = '1' then 
    next_state <= idle; 
  else 
    case ( current_state ) is
      when idle => 
        next_state <= idle; 
        if load_port = '1' then 
          next_state <= prod1; 
        end if; 
      when prod1 => 
        next_state <= prod1; 
        if mul_set = '1' then 
          next_state <= bufr; 
        end if; 
      when bufr => 
        next_state <= bufr; 
        -- mul set must go low from clear before proceeding 
        if mul_set = '0' then 
          next_state <= prod2;
        end if; 
      when prod2 => 
        next_state <= prod2; 
        if mul_set = '1' then 
          next_state <= done; 
        end if; 
      when done => 
        next_state <= done; 
    end case; 
  end if; 
end process next_state_logic; 

output_logic: process( current_state )
begin 
  reset_en      <= '0';
  first_mul_en  <= '0';
  second_mul_en <= '0';
  mul_en        <= '0';
  set_en        <= '0';
  clear_mul     <= '0';

  case ( current_state ) is 
    when idle => 
      reset_en <= '1'; 
    when prod1 => 
      first_mul_en <= '1';
      mul_en   <= '1';
    when bufr => 
      clear_mul <= '1';
    when prod2 =>
      second_mul_en <= '1';
      mul_en   <= '1';
    when done => 
      set_en   <= '1';
  end case; 
end process output_logic; 

update_state: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    current_state <= next_state; 
  end if; 
end process update_state; 

end architecture behavioral;
