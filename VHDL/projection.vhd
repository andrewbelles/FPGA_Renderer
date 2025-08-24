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

  signal reciprocal_set : std_logic := '0'; 
  signal divide_set     : std_logic := '0';
  signal reciprocal_sg  : std_logic_vector(23 downto 0) := (others => '0'); 
  signal Wc_reciprocal  : signed(23 downto 0) := (others => '0');
  signal xndc, yndc     : signed(23 downto 0) := (others => '0'); 
  signal Xc, Yc         : signed(47 downto 0) := (others => '0');

  constant m00          : signed(23 downto 0) := x"0014c9";
  constant m11          : signed(23 downto 0) := x"001BB6";
  constant b            : signed(23 downto 0) := x"000080";
begin 
--------------------------------------------------------------------------
-- Get perspective from 1/z   
--------------------------------------------------------------------------
get_reciprocal: reciprocal_24b 
  port map( 
    clk_port   => clk_port, 
    load_port  => load_port,
    reset_port => reset_port, 
    value      => z,
    reciprocal => reciprocal_sg,
    set_port   => reciprocal_set);

--------------------------------------------------------------------------
-- Multiply Perspective Matrix against points  
--------------------------------------------------------------------------
Xc <= shift_right(resize(m00, 48) * resize(signed(x), 48), 12); 
Yc <= shift_right(resize(m11, 48) * resize(signed(y), 48), 12); 
Wc_reciprocal <= signed(reciprocal_sg);
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
    if reset_port = '1' then 
      xndc <= (others => '0');
      yndc <= (others => '0');
      divide_set <= '0';
    elsif reciprocal_set = '1' then
      ndc_helper := Xc * resize(Wc_reciprocal, 48);  
      xndc <= shift_right(ndc_helper, 12);
      ndc_helper := Yc * resize(Wc_reciprocal, 48);  
      yndc <= shift_right(ndc_helper, 12);
      divide_set <= '1'; 
    elsif divide_set = '1' then 
      tx := xndc; 
      if tx(23) = '1' then 
        round := -round; 
      end if; 
      tx := shift_right( shift_left(tx, 7) + round, 12) + b;

      round := x"000800";
      ty := yndc; 
      if ty(23) = '1' then 
        round := -round; 
      end if; 
      ty := shift_right( shift_left(ty, 7) + round, 12) + b;

      -- latch point packet 
      point_packet <= std_logic_vector(ty(7 downto 0)) 
                      & std_logic_vector(tx(7 downto 0));
    end if; 
  end if; 
end process;

set_port <= '1' when divide_set = '1' else '0';

end architecture behavioral;
