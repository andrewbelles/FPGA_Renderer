library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity projection_24b is 
port( 
  clk_port     : in std_logic;
  load_port    : in std_logic; 
  reset_port   : in std_logic; 
  x, y, z      : in std_logic_vector(23 downto 0); 
  point_packet : out std_logic_vector(15 downto 0); -- (8 high x),(8 low y)
  set_port     : out std_logic);
end projection_24b; 

architecture behavioral of projection_24b is 
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

  type state_type is ( idle, load, wait_reciprocal, load_reciprocal, dividing, shift, done);
  signal current_state, next_state : state_type := idle; 

  signal load_rec_en    : std_logic := '0'; 
  signal reset_en       : std_logic := '0'; 
  signal load_en        : std_logic := '0'; 
  signal set_en         : std_logic := '0'; 
  signal shift_en       : std_logic := '0'; 
  signal shift_set      : std_logic := '0'; 
  signal reciprocal_en  : std_logic := '0'; 
  signal reciprocal_set : std_logic := '0'; 
  signal divide_en      : std_logic := '0'; 
  signal divide_set     : std_logic := '0';
  signal inv_z_raw      : signed(23 downto 0) := (others => '0');
  signal inv_z          : std_logic_vector(23 downto 0) := (others => '0'); 
  signal reciprocal_sg  : std_logic_vector(23 downto 0) := (others => '0'); 
  signal Wc_reciprocal  : signed(23 downto 0) := (others => '0');
  signal xndc, yndc     : signed(23 downto 0) := (others => '0'); 
  signal Xc, Yc         : signed(23 downto 0) := (others => '0');

  constant m00          : signed(23 downto 0) := x"001000";
  constant m11          : signed(23 downto 0) := x"001000";
  constant b            : signed(23 downto 0) := x"000080";
  constant near_clip    : signed(23 downto 0) := x"002000";
begin 
--------------------------------------------------------------------------
-- Get perspective from 1/z   
--------------------------------------------------------------------------
inv_z <= std_logic_vector(near_clip) when abs(inv_z_raw) < near_clip else 
         std_logic_vector(inv_z_raw);  

get_reciprocal: reciprocal_24b 
  port map( 
    clk_port   => clk_port, 
    load_port  => reciprocal_en,
    reset_port => reset_en, 
    value      => inv_z,
    reciprocal => reciprocal_sg,
    set_port   => reciprocal_set);

--------------------------------------------------------------------------
-- Multiply Perspective Matrix against points  
--------------------------------------------------------------------------
process( clk_port )
  variable wide_bus : signed(47 downto 0); 
begin
  wide_bus := (others => '0'); 
  if rising_edge( clk_port ) then 
    if reset_en = '1' then 
      Xc <= (others => '0');
      Yc <= (others => '0');
    elsif load_en = '1' then 
      wide_bus := m00 * signed(x); 
      Xc <= shift_right(wide_bus, 12)(23 downto 0); 
      wide_bus := m11 * signed(y);
      Yc <= shift_right(wide_bus, 12)(23 downto 0); 
    end if;  
  end if; 
end process; 

process( clk_port ) 
begin 
  if rising_edge(clk_port) then 
    if reset_en = '1' then 
      Wc_reciprocal <= (others => '0'); 
    elsif load_rec_en = '1' then 
      Wc_reciprocal <= signed(reciprocal_sg); 
    end if; 
  end if; 
end process; 


process( clk_port )
  variable round  : signed(23 downto 0) := x"000800"; 
  variable tx, ty : signed(23 downto 0) := (others => '0');
  variable ndc_helper : signed(47 downto 0) := (others => '0'); 
begin 
  round := x"000800";
  tx    := (others => '0'); 
  ty    := (others => '0');
  ndc_helper := (others => '0'); 

  if rising_edge(clk_port) then 
    if reset_en = '1' then 
      xndc <= (others => '0');
      yndc <= (others => '0');
      divide_set <= '0';
      shift_set  <= '0'; 
    elsif divide_en = '1' then
      ndc_helper := Xc * Wc_reciprocal;  
      xndc <= shift_right(ndc_helper, 12)(23 downto 0);
      ndc_helper := Yc * Wc_reciprocal;  
      yndc <= shift_right(ndc_helper, 12)(23 downto 0);
      divide_set <= '1'; 
    elsif shift_en = '1' then 
      tx := xndc; 
      if tx(23) = '1' then 
        round := -round; 
      end if; 
      tx := shift_right( shift_left(tx, 4) + round, 12) + b;

      round := x"000800";
      ty := yndc; 
      if ty(23) = '1' then 
        round := -round; 
      end if; 
      ty := shift_right( shift_left(-ty, 4) + round, 12) + b;

      -- latch point packet 
      point_packet <= std_logic_vector(tx(7 downto 0)) & std_logic_vector(ty(7 downto 0));
      shift_set <= '1'; 
    end if; 
  end if; 
end process;

set_port <= '1' when set_en = '1' else '0';

next_state_logic: process ( current_state, reset_port, load_port, reciprocal_set, shift_set, divide_set )
begin 
  if reset_port = '1' then 
    next_state <= idle; 
  else 
    next_state <= current_state; 
    case ( current_state ) is 
      when idle => 
        if load_port = '1' then 
          next_state <= load;
        end if; 
      when load => 
        next_state <= wait_reciprocal; 
      when wait_reciprocal => 
        if reciprocal_set = '1' then 
          next_state <= load_reciprocal; 
        end if; 
      when load_reciprocal => 
        next_state <= dividing;         
      when dividing => 
        if divide_set = '1' then 
          next_state <= shift; 
        end if; 
      when shift => 
        if shift_set = '1' then 
          next_state <= done; 
        end if; 
      when done => 
        next_state <= done; -- stay in done till reset(?)
      when others => 
        null; 
    end case; 
  end if;
end process next_state_logic; 

output_logic: process( current_state )
begin 
  reset_en      <= '0'; 
  load_en       <= '0'; 
  reciprocal_en <= '0'; 
  divide_en     <= '0'; 
  shift_en      <= '0';
  set_en        <= '0'; 
  load_rec_en   <= '0';

  case ( current_state ) is 
    when idle => 
      reset_en <= '1'; 
    when load => 
      load_en <= '1'; 
    when wait_reciprocal => 
      reciprocal_en <= '1';
    when load_reciprocal => 
      load_rec_en <= '1';  
    when dividing => 
      divide_en <= '1'; 
    when shift => 
      shift_en <= '1';
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
