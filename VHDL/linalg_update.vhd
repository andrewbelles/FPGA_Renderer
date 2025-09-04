library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity update_point is 
port(
  clk_port     : in std_logic; 
  load_port    : in std_logic; 
  reset_port   : in std_logic; 
  angle        : in array_2x16_t;
  dir          : in array_2x2_t;
  x, y, z      : in std_logic_vector(23 downto 0);  
  nx, ny, nz   : out std_logic_vector(23 downto 0);
  point_packet : out std_logic_vector(15 downto 0);
  set_port     : out std_logic);
end update_point; 

architecture behavioral of update_point is 
----------------------- component declarations ---------------------------
component rotation is 
port( 
  clk_port   : in std_logic;
  en_port    : in std_logic; 
  reset_port : in std_logic; 
  angle      : in std_logic_vector(15 downto 0);
  dir        : in std_logic_vector(1 downto 0);
  x, y, z    : in std_logic_vector(23 downto 0); 
  nx, ny, nz : out std_logic_vector(23 downto 0);
  set_port   : out std_logic);
end component rotation; 

component project_point is 
port( 
  clk_port     : in std_logic;
  load_port    : in std_logic; 
  reset_port   : in std_logic; 
  x, y, z      : in std_logic_vector(23 downto 0); 
  point_packet : out std_logic_vector(15 downto 0); -- (8 high x),(8 low y)
  set_port     : out std_logic);
end component project_point;
----------------------- declarations -------------------------------------
  
  signal rx, ry, rz : std_logic_vector(23 downto 0) := (others => '0');
  signal cx, cy, cz : std_logic_vector(23 downto 0) := (others => '0');
  signal ox, oy, oz : std_logic_vector(23 downto 0) := (others => '0');
  signal rot1_en    : std_logic := '0';
  signal rot1_set   : std_logic := '0'; 
  signal rot2_set   : std_logic := '0';
begin 

-- Allow no-opts to run without performing any rotation math 
process ( clk_port ) 
begin 
  if rising_edge( clk_port ) then 
    if reset_port = '1' then 
      ox <= (others => '0');
      oy <= (others => '0');
      oz <= (others => '0');
    elsif angle(0) /= x"0000" and angle(1) /= x"0000" then 
      ox <= cx; 
      oy <= cy; 
      oz <= cz; 
    else 
      ox <= x; 
      oy <= y; 
      oz <= z; 
    end if; 
  end if; 
end process;

rot1: rotation
 port map(
    clk_port   => clk_port,
    en_port    => load_port, 
    reset_port => reset_port,
    angle      => angle(0),
    dir        => dir(0),
    x          => x,
    y          => y,
    z          => z,
    nx         => rx,
    ny         => ry,
    nz         => rz,
    set_port   => rot1_set); 

rot2: rotation
 port map(
    clk_port   => clk_port,
    en_port    => rot1_set,
    reset_port => reset_port,
    angle      => angle(1),
    dir        => dir(1),
    x          => rx,
    y          => ry,
    z          => rz,
    nx         => cx,
    ny         => cy,
    nz         => cz,
    set_port   => rot2_set); 

project: project_point 
port map( 
  clk_port     => clk_port, 
  load_port    => rot2_set, 
  reset_port   => reset_port, 
  x            => ox,
  y            => oy,
  z            => oz,
  point_packet => point_packet, 
  set_port     => set_port); 

nx <= ox; 
ny <= oy; 
nz <= oz; 

end architecture behavioral; 
