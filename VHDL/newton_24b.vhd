library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity newton_24b is 
  port (
    clk_port   : in std_logic; 
    en_port    : in std_logic; 
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
end multiplier_24x24; 
  type state_type is ( reset, run, done ); 

  signal current_state, next_state : state_type := reset; 

  signal reset_en   : std_logic := '0';

  signal inner_set  : std_logic := '0'; 
  signal outer_set  : std_logic := '0';
  signal outer_en   : std_logic := '0';

  signal x          : signed_3x24_t := (others => (others => '0'));

  signal counter    : unsigned(1 downto 0) := (others => '0');
  signal counter_tc : std_logic := '0';
  signal idx        : integer   := 0;
  signal decimals   : std_logic_vector(4 downto 0) := (others => '0'); 

  signal prod       : signed(23 downto 0)  := (others => '0');
  signal diff       : signed(23 downto 0)  := (others => '0');
  
-- constant digit counts 
  constant m22      : std_logic_vector(4 downto 0) := "10110";
  constant s17      : std_logic_vector(4 downto 0) := "10001";
  constant s12      : std_logic_vector(4 downto 0) := "01100";
  constant c2_17    : signed(23 downto 0)          := x"002000";
begin 

-- dec count is 17 or b10001
x(0) <= signed(seed);

inner_prod: multiplier_24x24
 port map(
    clk_port   => clk_port,
    load_port  => en_port,
    reset_port => reset_en, 
    A          => mantissa,
    B          => std_logic_vector(x(idx)),
    A_dig      => m22,
    B_dig      => s17,
    AB         => std_logic_vector(prod), -- 11.12
    AB_dig     => decimals,
    set_port   => inner_set 
);

diff <= (c2_17 - prod); 
outer_en <= '1' when inner_set = '1' else 
            '0';

outer_prod: multiplier_24x24
 port map(
    clk_port   => clk_port,
    load_port  => outer_en,
    reset_port => reset_en,
    A          => std_logic_vector(diff),
    B          => std_logic_vector(x(idx)),
    A_dig      => s12,
    B_dig      => s17,
    AB         => std_logic_vector(prod), -- 11.12
    AB_dig     => decimals,
    set_port   => outer_set
);

counter_tc <= '1' when counter = 2 else 
              '0';
x(idx + 1) <= shift_left(prod, to_integer(17 - signed(decimals)));

inc_iter: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    if reset_port = '1' then 
      counter <= "00";
    elsif outer_set = '1' then 
      if counter_tc = '0' then 
        counter <= counter + 1; 
      end if;
    end if; 
  end if; 
end process inc_iter; 

idx  <= to_integer(counter);
root <= std_logic_vector(x(3));

update_state: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    current_state <= next_state; 
  end if; 
end process update_state; 

next_state_logic: process( current_state, reset_port, outer_set, counter_tc )
begin 
  if reset_port = '1' then 
    next_state <= reset; 
  else 
    case ( current_state ) is 
      when reset => 
        next_state <= run;
      when run =>
        next_state <= run;
        if counter_tc = '1' then 
          next_state <= done; 
        elsif outer_set = '1' then 
          next_state <= reset; 
        end if; 
      when done => 
        next_state <= done;
        if reset_port = '1' then 
          next_state <= reset; 
        end if; 
      when others => 
        null; 
    end case; 
  end if; 
end process next_state_logic; 

output_logic: process( current_state )
begin 
  case ( current_state ) is 
    when reset => 
      reset_en <= '1';
      set_port <= '0';
    when run => 
      reset_en <= '0';
      set_port <= '0';
    when done => 
      reset_en <= '0';
      set_port <= '1';
    when others => 
      null; 
  end case; 
end process output_logic; 

end architecture behavioral;
