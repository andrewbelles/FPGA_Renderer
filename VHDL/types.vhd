library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;

package array_types is 
  type array_2x2_t is array (0 to 1) of std_logic_vector(1 downto 0);
  type array_2x16_t is array (0 to 1) of std_logic_vector(15 downto 0);
  type array_3x16_t is array (0 to 2) of std_logic_vector(15 downto 0);
  type array_4x16_t is array (0 to 3) of std_logic_vector(15 downto 0);

  type array_2x24_t is array (0 to 1) of std_logic_vector(23 downto 0);
  type array_3x24_t is array (0 to 2) of std_logic_vector(23 downto 0);
  type array_4x24_t is array (0 to 3) of std_logic_vector(23 downto 0);
  type array_4x3x24_t is array (0 to 3) of array_3x24_t;

  type signed_2x24_t is array (0 to 1) of signed(23 downto 0);
  type signed_3x24_t is array (0 to 2) of signed(23 downto 0);
  type signed_4x24_t is array (0 to 3) of signed(23 downto 0);
  type signed_3x48_t is array (0 to 2) of signed(47 downto 0);
  type signed_4x48_t is array (0 to 3) of signed(47 downto 0);
  type array_2048x16_t is array(0 to 2047) of std_logic_vector(15 downto 0); -- sin lookup table
  type array_1024x24_t is array(0 to 1023) of std_logic_vector(23 downto 0); -- newtwon lookup table 

  type ascii_rom_t is array(0 to 255) of integer;
  type dirs_rom_t is array(0 to 14) of array_2x2_t;
  type angles_rom_t is array(0 to 14) of array_2x16_t;

  type buf256x256 is array(0 to 65535) of std_logic; -- inferred block ram

end package; 

-- empty body
package body array_types is 
end package body array_types;
