library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

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
  operands : out array_3x16_t; 
  set_port : out std_logic); 
end set_operands_m16x16;

architecture behavioral of set_operands_m16x16 is 
  signal dir_uint : unsigned(1 downto 0) := (others => '0');
  signal set      : std_logic := '0'; 
begin 

set_port <= set; 
dir_uint <= unsigned(dir);

get_operands: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    set <= '1'; 
    case ( dir_uint ) is 
      when "00" =>  
        operands(0) <= x; 
        operands(1) <= y; 
        operands(2) <= z; 
      when "01" => 
        -- might seem like an odd choice but in for rotation about the y
        -- x gets multiplied against -sine and in other two
        -- operand2 gets multiplied. So we treat it as operand2 
        operands(0) <= y; 
        operands(1) <= z; 
        operands(2) <= x;  -- operand2!`` 
      when "10" => 
        operands(0) <= z; 
        operands(1) <= x; 
        operands(2) <= y; 
    end case; 
  end if; 
end process get_operands;

end architecture behavioral;
