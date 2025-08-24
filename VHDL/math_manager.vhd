library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity parallel_math is 
  port( 
    clk_port   : in std_logic; 
    load_port  : in std_logic; 
    reset_port : in std_logic; 
    angle      : in array_2x16_t; 
    dir        : in array_2x2_t; 
    points     : in array_4x3x24_t;
    new_points : out array_4x3x24_t; 
    packets    : out array_4x16_t; 
    set_port   : out std_logic);
end parallel_math; 

architecture behavioral of parallel_math is 
----------------------- component declarations ---------------------------
component update_point is 
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
end component update_point;
  signal update_set     : std_logic_vector(3 downto 0)  := (others => '0');
  signal local_new_p    : array_4x3x24_t := (others => (others => (others => '0')));
  signal local_packets  : array_4x16_t := (others => (others => '0'));
  signal update_done    : std_logic := '0';
begin 

-- Compute in series, proj3 waits for 1 and proj4 waits for 2 

get_proj1: update_point 
port map( 
  clk_port     => clk_port,  
  load_port    => load_port, 
  reset_port   => reset_port,  
  angle        => angle, 
  dir          => dir, 
  x            => points(0)(0), 
  y            => points(0)(1), 
  z            => points(0)(2), 
  nx           => local_new_p(0)(0),
  ny           => local_new_p(0)(1),
  nz           => local_new_p(0)(2),
  point_packet => local_packets(0),
  set_port     => update_set(0)); 


get_proj2: update_point 
port map( 
  clk_port     => clk_port,  
  load_port    => load_port, 
  reset_port   => reset_port,  
  angle        => angle, 
  dir          => dir, 
  x            => points(1)(0), 
  y            => points(1)(1), 
  z            => points(1)(2), 
  nx           => local_new_p(1)(0),
  ny           => local_new_p(1)(1),
  nz           => local_new_p(1)(2),
  point_packet => local_packets(1),
  set_port     => update_set(1)); 

-- doesn't get updated till update_set(0) goes high
get_proj3: update_point 
port map( 
  clk_port     => clk_port,  
  load_port    => update_set(0), 
  reset_port   => reset_port,  
  angle        => angle, 
  dir          => dir, 
  x            => points(2)(0), 
  y            => points(2)(1), 
  z            => points(2)(2), 
  nx           => local_new_p(2)(0),
  ny           => local_new_p(2)(1),
  nz           => local_new_p(2)(2),
  point_packet => local_packets(2),
  set_port     => update_set(2)); 

-- same idea here, waits for update_set(1)
get_proj4: update_point 
port map( 
  clk_port     => clk_port,  
  load_port    => update_set(1), 
  reset_port   => reset_port,  
  angle        => angle, 
  dir          => dir, 
  x            => points(3)(0), 
  y            => points(3)(1), 
  z            => points(3)(2), 
  nx           => local_new_p(3)(0),
  ny           => local_new_p(3)(1),
  nz           => local_new_p(3)(2),
  point_packet => local_packets(3),
  set_port     => update_set(3)); 

-- set_port goes high once all four have completed 
update_done <= '1' when update_set = "1111" else '0';

set_output: process( clk_port ) 
begin 
  if rising_edge( clk_port ) then 
    if reset_port = '1' then 
      
     new_points <= (others => (others => (others => '0')));
     packets    <= (others => (others => '0'));
     set_port   <= '0';

    elsif update_done = '1' then 

     new_points <= local_new_p;
     packets    <= local_packets;
     set_port   <= '1';
    end if;
  end if; 
end process set_output; 

end architecture behavioral;
