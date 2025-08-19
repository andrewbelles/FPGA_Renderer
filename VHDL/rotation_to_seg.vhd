library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity rotation_seg_shell is 
generic (
  clk_divider_ratio : integer := 4); -- got it to work at ratio 4 
port (
  clk_ext_port     : in std_logic; 
  -- for 7 seg 
  seg_ext_port : out std_logic_vector(0 to 6);
  dp_ext_port  : out std_logic; 
  an_ext_port  : out std_logic_vector(3 downto 0));
end rotation_seg_shell; 

architecture behavioral of rotation_seg_shell is 
----------------------- component declarations ---------------------------
component system_clock_generation is  -- engs 31 provided module for clock dividing  
generic ( clk_divider_ratio : integer );
port (
  input_clk_port  : in std_logic;
  system_clk_port : out std_logic);
end component system_clock_generation; 

component rotation is 
port( 
  clk_port   : in std_logic; 
  angle      : in std_logic_vector(15 downto 0);
  dir        : in std_logic_vector(1 downto 0);
  x, y, z    : in std_logic_vector(15 downto 0); 
  nx, ny, nz : out std_logic_vector(15 downto 0);
  set_port   : out std_logic);
end component rotation; 

component mux7seg is  -- engs 31 provided module for 7 seg display 
    Port ( 
         clk_port 	      : in  std_logic;
         y3_port 		  : in  std_logic_vector(3 downto 0);	  --left most digit
         y2_port 		  : in  std_logic_vector(3 downto 0);	  --center left digit
         y1_port 		  : in  std_logic_vector(3 downto 0);	  --center right digit
         y0_port 		  : in  std_logic_vector(3 downto 0);	  --right most digit
         dp_set_port 	  : in  std_logic_vector(3 downto 0);     --decimal points
         seg_port 	      : out  std_logic_vector(0 to 6);		  --segments (a...g)
         dp_port 		  : out  std_logic;						  --decimal point
         an_port 		  : out  std_logic_vector (3 downto 0) ); --anodes
end component mux7seg;

  signal system_clk_port : std_logic := '0';
  signal new_y           : std_logic_vector(15 downto 0) := (others => '0'); 
  signal nx, nz          : std_logic_vector(15 downto 0) := (others => '0');
  signal set_port        : std_logic := '0'; 
  signal dp_set          : std_logic_vector(3 downto 0)  := (others => '0');

begin 

clocking: system_clock_generation 
  generic map (
    clk_divider_ratio => clk_divider_ratio)
  port map (
    input_clk_port    => clk_ext_port,
    system_clk_port   => system_clk_port);

find_rotation: rotation 
  port map(
    clk_port => system_clk_port,
    angle    => x"0861",
    dir      => "00",
    x        => x"3200",
    y        => x"4600",
    z        => x"2800",
    nx       => nx,
    ny       => new_y,  -- only one we are displaying 
    nz       => nz, 
    set_port => set_port); 

dp_set <= "000" & set_port;
display: mux7seg 
  port map(
    clk_port    => system_clk_port,
    y3_port     => new_y(15 downto 12),
    y2_port     => new_y(11 downto 8),
    y1_port     => new_y(7 downto 4),
    y0_port     => new_y(3 downto 0),
    dp_set_port => dp_set, 
    seg_port    => seg_ext_port, 
    dp_port     => dp_ext_port,
    an_port     => an_ext_port);

end architecture behavioral; 
