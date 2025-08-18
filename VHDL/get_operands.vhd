library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 

-- Considers direction, sets operands based on direction, captures value  
-- dir is axis we are rotating about: 
--    x == "00", 0
--    y == "01", 1 
--    z == "10", 2

entity set_operands_m16x16 is 
port(
  clk_port : in std_logic; 
  dir      : in std_logic_vector(1 downto 0);
  x,y,z    : in std_logic_vector(15 downto 0); 
  operand1 : out std_logic_vector(15 downto 0);
  operand2 : out std_logic_vector(15 downto 0);
  set_port : out std_logic); 
end set_operands_m16x16;

architecture behavioral of set_operands_m16x16 is 
  signal dir_uint : unsigned(1 downto 0) := (others => '0');
  signal set      : std_logic := '0'; 
begin 

dir_uint <= unsigned(dir);

get_operands: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    set <= '1'; 
    case ( dir_uint ) is 
      when "00" =>  
        operand1 <= y; 
        operand2 <= z; 
      when "01" => 
        -- might seem like an odd choice but in for rotation about the y
        -- x gets multiplied against -sine and in other two
        -- operand2 gets multiplied. So we treat it as operand2 
        operand1 <= z; 
        operand2 <= x;  -- operand2!`` 
      when "10" => 
        operand1 <= x; 
        operand2 <= y; 
    end case; 
  end if; 
end process get_operands;

end architecture behavioral;
