library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity rotation_16b is 
port( 
  clk_port   : in std_logic; 
  load_en    : in std_logic; 
  dir        : in std_logic_vector(1 downto 0); 
  static     : in std_logic_vector(15 downto 0);
  products   : in array_4x16_t;  
  nx, ny, nz : out std_logic_vector(15 downto 0);
  set_port   : out std_logic); 
end rotation_16b;

architecture behavioral of rotation_16b is 
  type signed_4x16_t is array (0 to 3) of signed(15 downto 0); 

  signal sProducts : signed_4x16_t := (others => (others => '0'));
begin 

-- set signed products for ease 
sProducts(0) <= signed(products(0));
sProducts(1) <= signed(products(1));
sProducts(2) <= signed(products(2));
sProducts(3) <= signed(products(3));

-- comptue sums at start 

compute_rotation: process( clk_port )
  variable s1, s2 : signed(15 downto 0);
begin
  s1 := (others => '0');
  s2 := (others => '0');
  if rising_edge( clk_port ) then 
    if load_en = '1' then 
      s1 := sProducts(0) + sProducts(3);
      s2 := sProducts(1) + sProducts(2);
      set_port <= '1';
      case ( dir ) is 
        when "00" => -- x 
          nx <= static; 
          ny <= std_logic_vector(s1);
          nz <= std_logic_vector(s2);
        when "01" => -- y 
          nx <= std_logic_vector(s2);
          ny <= static; 
          nz <= std_logic_vector(s1);
        when "10" => -- z  
          nx <= std_logic_vector(s1);
          ny <= std_logic_vector(s2);
          nz <= static; 
      end case; 
    end if; 
  end if; 

end process compute_rotation; 

end architecture behavioral;
