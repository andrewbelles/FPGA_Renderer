library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 

entity rotation_16b is 
port( 
  clk_port   : in std_logic; 
  dir        : in std_logic; 
  x, y, z    : in std_logic_vector(15 downto 0);
  products   : 
  nx, ny, nz : out std_logic_vector(15 downto 0));
end rotation_16b;

architecture behavioral of rotation_16b is 

begin 

end architecture behavioral;
