library IEEE; 
use IEEE.std_logic_1164.all; 

package array_types is 
  type array_3x16_t is array (0 to 2) of std_logic_vector(15 downto 0);
  type array_4x16_t is array (0 to 3) of std_logic_vector(15 downto 0);

  type array_3x24_t is array (0 to 2) of std_logic_vector(23 downto 0);
  type array_4x24_t is array (0 to 3) of std_logic_vector(23 downto 0);

  type array_2048x16_t is array(0 to 2047) of std_logic_vector(15 downto 0); -- sin lookup table
  type buf256x256 is array(0 to 65535) of std_logic; -- inferred block ram

end package; 

-- empty body
package body array_types is 
end package body array_types;
