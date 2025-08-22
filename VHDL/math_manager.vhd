library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity parallel_math_24b is 
  port( 
    clk_port   : in std_logic; 
    load_port  : in std_logic; 
    reset_port : in std_logic; 
    angle      : in array_2x16_t; 
    dir        : in array_2x2_t; 
    points     : in array_4x72_t;
    new_points : out array_4x72_t; 
    packets    : out array_4x16_t; 
    set_port   : out std_logic);
end parallel_math_24b; 

architecture behavioral of parallel_math_24b is 
----------------------- component declarations ---------------------------
component update_point_24b is 
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
end component update_point_24b;
  signal update_set     : std_logic_vector(3 downto 0)  := (others => '0');
  signal p1, p2, p3, p4 : std_logic_vector(71 downto 0) := (others => '0');
  signal n1, n2, n3, n4 : std_logic_vector(71 downto 0) := (others => '0');
  signal local_packets  : array_4x16_t := (others => (others => '0'));
  signal update_done    : std_logic := '0';
begin 

p1 <= points(0);
p2 <= points(1);
p3 <= points(2);
p4 <= points(3);

get_proj1: update_point_24b 
port map( 
  clk_port     => clk_port,  
  load_port    => load_port, 
  reset_port   => reset_port,  
  angle        => angle, 
  dir          => dir, 
  x            => p1(71 downto 48), 
  y            => p1(47 downto 24), 
  z            => p1(23 downto 0), 
  nx           => n1(71 downto 48),
  ny           => n1(47 downto 24),
  nz           => n1(23 downto 0),
  point_packet => local_packets(0),
  set_port     => update_set(0)); 


get_proj2: update_point_24b 
port map( 
  clk_port     => clk_port,  
  load_port    => load_port, 
  reset_port   => reset_port,  
  angle        => angle, 
  dir          => dir, 
  x            => p2(71 downto 48), 
  y            => p2(47 downto 24), 
  z            => p2(23 downto 0), 
  nx           => n2(71 downto 48),
  ny           => n2(47 downto 24),
  nz           => n2(23 downto 0),
  point_packet => local_packets(1),
  set_port     => update_set(1)); 

get_proj3: update_point_24b 
port map( 
  clk_port     => clk_port,  
  load_port    => load_port, 
  reset_port   => reset_port,  
  angle        => angle, 
  dir          => dir, 
  x            => p3(71 downto 48), 
  y            => p3(47 downto 24), 
  z            => p3(23 downto 0), 
  nx           => n3(71 downto 48),
  ny           => n3(47 downto 24),
  nz           => n3(23 downto 0),
  point_packet => local_packets(2),
  set_port     => update_set(2)); 


get_proj4: update_point_24b 
port map( 
  clk_port     => clk_port,  
  load_port    => load_port, 
  reset_port   => reset_port,  
  angle        => angle, 
  dir          => dir, 
  x            => p4(71 downto 48), 
  y            => p4(47 downto 24), 
  z            => p4(23 downto 0), 
  nx           => n4(71 downto 48),
  ny           => n4(47 downto 24),
  nz           => n4(23 downto 0),
  point_packet => local_packets(3),
  set_port     => update_set(3)); 

update_done <= '1' when update_set = "1111" else '0';

set_output: process( clk_port ) 
begin 
  if rising_edge( clk_port ) then 
    if reset_port = '1' then 
      
     new_points <= (others => (others => '0'));
     packets    <= (others => (others => '0'));
     set_port   <= '0';

    elsif update_done = '1' then 

     new_points(0) <= n1;
     new_points(1) <= n2;
     new_points(2) <= n3;
     new_points(3) <= n4;
     packets    <= local_packets;
     set_port   <= '1';
    end if;
  end if; 
end process set_output; 

end architecture behavioral;
