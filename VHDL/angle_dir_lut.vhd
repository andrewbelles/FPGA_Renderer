library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity angle_dir_lut is 
port( 
  clk_port   : in std_logic; 
  addr       : in std_logic_vector(7 downto 0); 
  dirs       : out array_2x2_t; 
  angles     : out array_2x16_t;
  data_ready : out std_logic);
end entity angle_dir_lut;

architecture behavioral of angle_dir_lut is 

  signal idx         : integer := 0;
  signal ascii_idx   : integer := 0;
  signal op_set      : std_logic := '0';
  signal read_angles : array_2x16_t := (others => (others => '0'));
  signal read_dirs   : array_2x2_t  := (others => (others => '0'));

  constant ascii_table : ascii_rom_t := (
    0 to 96 => 0,
    97  => 1,
    98  => 0, 
    99  => 0,
    100 => 2,
    101 => 3,
    102 => 0,
    103 => 0,
    104 => 0,
    105 => 4,
    106 => 5,
    107 => 6,
    108 => 7, 
    109 => 0,
    110 => 0, 
    111 => 8,
    112 => 0,
    113 => 9, 
    114 => 0, 
    115 => 10, 
    116 => 0,
    117 => 11,
    118 => 0, 
    119 => 12, 
    120 => 0, 
    121 => 0,
    122 => 0,
    123 to 255 => 0);
    
  constant direction_table : dirs_rom_t := (
    -- idx : (rot0_dir, rot1_dir)
    0  => ("00", "00"),       -- no-op
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
    12 => ("10", "10"));      -- w +Z

  constant angles_table : angles_rom_t := (
    -- idx : (rot0_dir, rot1_dir)
    0  => (x"0000", x"0000"),       -- no-op
    1  => (x"02CB", x"02CB"),       -- a +Y
    2  => (x"61BD", x"61BD"),       -- d -Y
    3  => (x"61BD", x"61BD"),       -- e -X
    4  => (x"02CB", x"02CB"),       -- i +X & +Y
    5  => (x"02CB", x"02CB"),       -- j +Y & +Z
    6  => (x"61BD", x"61BD"),       -- k -X & -Y
    7  => (x"61BD", x"61BD"),       -- l -Y & -Z
    8  => (x"61BD", x"61BD"),       -- o -X & -Z
    9  => (x"02CB", x"02CB"),       -- q +X
    10 => (x"61BD", x"61BD"),       -- s -Z
    11 => (x"02CB", x"02CB"),       -- u +X & +Z
    12 => (x"02CB", x"02CB"));      -- w +Z
  
begin 

ascii_idx <= ascii_table(idx);
op_set <= '0' when ascii_idx = 0 else '1';
idx <= to_integer( unsigned( addr ));
read_dirs   <= direction_table(ascii_idx);
read_angles <= angles_table(ascii_idx);

set_data: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    if op_set = '1' then 
      data_ready <= '1'; 
      dirs   <= read_dirs; 
      angles <= read_angles;
    else 
      data_ready <= '0'; 
    end if; 
  end if;
end process set_data; 

end architecture behavioral;

