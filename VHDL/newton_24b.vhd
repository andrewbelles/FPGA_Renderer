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
----------------------- declarations -------------------------------------
  type state_type is ( idle, mulA, diff, mulB, done ); 
  signal current_state, next_state : state_type := idle;

  signal mulA_en    : std_logic := '0';
  signal diff_en    : std_logic := '0'; 
  signal mulB_en    : std_logic := '0'; 
  signal set_en     : std_logic := '0'; 
  signal reset_en   : std_logic := '0'; 
  signal counter    : unsigned(1 downto 0) := "00";
  signal x0         : signed(23 downto 0) := (others => '0');
  signal x1, x2     : signed(23 downto 0) := (others => '0');
  signal x1_partial : signed(23 downto 0) := (others => '0');
  signal x1_diff    : signed(23 downto 0) := (others => '0');
  signal x2_partial : signed(23 downto 0) := (others => '0');
  signal x2_diff    : signed(23 downto 0) := (others => '0');
  signal m          : signed(23 downto 0) := (others => '0');

-- 2 represented as a 11.12 fixed point value 
  constant two_1112 : signed(23 downto 0) := x"002000";
begin 

-- load constant values
x0 <= signed(seed);
m  <= signed(mantissa);

newtons_method: process( clk_port ) 
  variable x48bus : signed(47 downto 0) := (others => '0'); 
begin 
  x48bus := (others => '0'); 
  if rising_edge( clk_port ) then  
    if reset_en = '1' then 
      counter <= (others => '0');
      x1 <= (others => '0'); 
      x1_partial <= (others => '0');
      x1_diff <= (others => '0');
      x2 <= (others => '0');
      x2_partial <= (others => '0');
      x2_diff <= (others => '0');
    elsif load_port = '1' then 
      if counter = "00" then 
        if mulA_en = '1' then 
          x48bus := m * x0; -- 1.22 * 6.17 -> 11.12 requires 22+17=39, 27 shifts
          x1_partial <= shift_right(x48bus, 22)(23 downto 0); 
        elsif diff_en = '1' then 
          x1_diff <= two_1112 - x1_partial; 
        elsif mulB_en = '1' then 
          x48bus := x0 * x1_diff; 
          x1 <= shift_right(x48bus, 17)(23 downto 0); -- 17 + 12 -> 12 
          counter <= counter + 1; 
        end if; 
      elsif counter = "01" then 
        if mulA_en = '1' then 
          x48bus := m * x1; -- 1.22 * 6.17 -> 11.12 requires 22+17=39, 27 shifts
          x2_partial <= shift_right(x48bus, 22)(23 downto 0); 
        elsif diff_en = '1' then 
          x2_diff <= two_1112 - x2_partial; 
        elsif mulB_en = '1' then 
          x48bus := x1 * x2_diff; 
          x2 <= shift_right(x48bus, 17)(23 downto 0); -- 17 + 12 -> 12 
          counter <= counter + 1; 
        end if; 
      end if; 
    end if; 
  end if; 
end process newtons_method;

--- enable set once counter goes high 
set_port <= '1' when set_en = '1' else '0'; 
root <= std_logic_vector(x2);

next_state_logic: process ( current_state, reset_port, counter )
begin 
  if reset_port = '1' then 
    next_state <= idle; 
  else 
    next_state <= current_state; 
    case ( current_state ) is 
      when idle =>
        next_state <= mulA;
      when mulA => 
        next_state <= diff;
      when diff => 
        next_state <= mulB; 
      when mulB => 
        if counter = "10" then 
          next_state <= done;
        else 
          next_state <= mulA;
        end if; 
      when done => 
        next_state <= done;
      when others => 
        null; 
    end case; 
  end if;
end process next_state_logic; 

output_logic: process( current_state )
begin 
  reset_en <= '0';
  mulA_en  <= '0'; 
  diff_en  <= '0'; 
  mulB_en  <= '0'; 
  set_en   <= '0'; 
  case ( current_state ) is 
    when idle => 
      reset_en <= '1';  
    when mulA => 
      mulA_en <= '1'; 
    when diff => 
      diff_en <= '1'; 
    when mulB => 
      mulB_en <= '1'; 
    when done => 
      set_en  <= '1'; 
  end case; 
end process output_logic; 

update_state: process( clk_port ) 
begin
    if rising_edge( clk_port ) then
        current_state <= next_state;
    end if;
end process update_state;

end architecture behavioral;
