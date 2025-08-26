----------------------------------------------------------------------------------
-- Angle dir LUT
-- Ben Sheppard and Andy Belles

-- Takes in an address (data for key pressed on keyboard) and returns the corresponding angle and direction for the rotation.
-- Outputs lut_valid when these outputs are valid to be read and correspond to a valid rotation.
-- Outputs lut_invalid when an invalid (unmapped) key has been pressed.
----------------------------------------------------------------------------------



library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity angle_dir_lut is 
port( 
  clk_port   : in std_logic; 
  request    : in std_logic;
  addr       : in std_logic_vector(7 downto 0); 
  dirs       : out array_2x2_t; 
  angles     : out array_2x16_t;
  lut_valid  : out std_logic;
  lut_invalid : out std_logic);
end entity angle_dir_lut;

architecture behavioral of angle_dir_lut is 

  --signal idx         : integer := 0;
  signal ascii_idx   : integer := 0;
  signal value       : unsigned(7 downto 0) := (others => '0'); 
  signal is_valid      : std_logic := '0';
  signal read_angles : array_2x16_t := (others => (others => '0'));
  signal read_dirs   : array_2x2_t  := (others => (others => '0'));
  constant ascii_table : ascii_rom_t := (
    0 => 13, -- for init
    1 to 96 => 0,
    97  => 1, -- a 
    98  => 0, 
    99  => 0,
    100 => 2, -- d
    101 => 3, -- e
    102 => 0,
    103 => 0,
    104 => 0,
    105 => 4, -- i
    106 => 5, -- j
    107 => 6, -- k
    108 => 7, -- l
    109 => 0,
    110 => 0, 
    111 => 8, -- o
    112 => 0,
    113 => 9,  -- q
    114 => 0, 
    115 => 10,  -- s
    116 => 0,
    117 => 11, -- u
    118 => 0, 
    119 => 12,  -- w
    120 => 0, 
    121 => 0,
    122 => 0,
    123 to 255 => 0);
    
  constant direction_table : dirs_rom_t := (
    -- idx : (rot0_dir, rot1_dir)
    0  => ("00", "00"), -- invalid
    1  => ("01", "01"),       -- a +Y
    2  => ("01", "01"),       -- d -Y
    3  => ("00", "00"),       -- e -X
    4  => ("00", "01"),       -- i +X & +Y
    5  => ("01", "10"),       -- j +Y & +Z
    6  => ("00", "01"),       -- k -X & -Y
    7  => ("01", "10"),       -- l -Y & -Z
    8  => ("00", "10"),       -- o -X & -Z
    9  => ("00", "00"),       -- q +X
    10 => ("10", "10"),       -- s -Z
    11 => ("00", "10"),       -- u +X & +Z
    12 => ("10", "10"),      -- w +Z
    13 => ("00", "00")); -- initialization (no direction)

  constant pos : std_logic_vector(15 downto 0) := x"0007";
  constant neg : std_logic_vector(15 downto 0) := x"FFF9";
  
  constant angles_table : angles_rom_t := (
    -- idx : (rot0_dir, rot1_dir)
    0  => (x"0000", x"0000"), -- invalid
    1  => (pos, pos),       -- a +Y
    2  => (neg, neg),       -- d -Y
    3  => (neg, neg),       -- e -X
    4  => (pos, pos),       -- i +X & +Y
    5  => (pos, pos),       -- j +Y & +Z
    6  => (neg, neg),       -- k -X & -Y
    7  => (neg, neg),       -- l -Y & -Z
    8  => (neg, neg),       -- o -X & -Z
    9  => (pos, pos),       -- q +X
    10 => (neg, neg),       -- s -Z
    11 => (pos, pos),       -- u +X & +Z
    12 => (pos, pos),       -- w +Z
    13 => (x"0000", x"0000")); -- initialization (rotation 0 degrees)
  
begin 
 
value <= unsigned(addr);
ascii_idx <= ascii_table(to_integer(value));
is_valid <= '0' when ascii_idx = 0 else '1';
read_dirs   <= direction_table(ascii_idx);
read_angles <= angles_table(ascii_idx);

set_data: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    -- defaults
      lut_valid <= '0';
      lut_invalid <= '0';
      if(request = '1') then -- turns on if we have a request from central controller
          if(is_valid = '1') then -- valid address (idx not 0)
            lut_valid <= '1'; 
            dirs   <= read_dirs; 
            angles <= read_angles;
          else -- invalid address (idx 0
            lut_invalid <= '1'; 
            dirs <= (others => (others => '0'));
            angles <= (others => (others => '0'));
          end if; 
      end if;
    end if;
end process set_data; 

end architecture behavioral;

