library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity update_point_24b is 
port(
  clk_port     : in std_logic; 
  load_port    : in std_logic; 
  reset_port   : in std_logic; 
  angle        : in array_2x16_t;
  dir          : in array_2x2_t;
  angle_count  : in std_logic_vector(1 downto 0);
  x, y, z      : in std_logic_vector(23 downto 0);  
  nx, ny, nz   : out std_logic_vector(23 downto 0);
  point_packet : out std_logic_vector(15 downto 0);
  set_port     : out std_logic);
end update_point_24b; 

architecture behavioral of update_point_24b is 
----------------------- component declarations ---------------------------
component rotation is 
port( 
  clk_port   : in std_logic;
  reset_port : in std_logic; 
  angle      : in std_logic_vector(15 downto 0);
  dir        : in std_logic_vector(1 downto 0);
  x, y, z    : in std_logic_vector(23 downto 0); 
  nx, ny, nz : out std_logic_vector(23 downto 0);
  set_port   : out std_logic);
end component rotation; 

component projection is 
port( 
  clk_port     : in std_logic;
  load_port    : in std_logic; 
  reset_port   : in std_logic; 
  x, y, z      : in std_logic_vector(23 downto 0); 
  point_packet : out std_logic_vector(15 downto 0); -- (8 high x),(8 low y)
  set_port     : out std_logic);
end component projection;
----------------------- declarations -------------------------------------
  type state_type is ( idle, rotating, projecting, done );
  signal current_state, next_state : state_type := idle; 

  signal curr_angle     : std_logic_vector(15 downto 0) := (others => '0');
  signal curr_dir       : std_logic_vector(1 downto 0)  := (others => '0');
  signal reset_en       : std_logic := '0';
  signal rotation_en    : std_logic := '0';
  signal projection_en  : std_logic := '0'; 
  signal set_en         : std_logic := '0';
  signal rotation_set   : std_logic := '0'; 
  signal projection_set : std_logic := '0';
  signal count_max      : unsigned(1 downto 0) := "00";
  signal counter        : unsigned(1 downto 0) := "00";

  signal rx, ry, rz     : std_logic_vector(23 downto 0) := (others => '0');
  signal rotated_coords : array_3x24_t := (others => (others => '0'));

  signal points         : std_logic_vector(15 downto 0) := (others => '0');

begin 

count_max <= unsigned(angle_count);

rotate: rotation
 port map(
    clk_port   => clk_port,
    reset_port => reset_en,
    angle      => curr_angle,
    dir        => curr_dir,
    x          => x,
    y          => y,
    z          => z,
    nx         => rx,
    ny         => ry,
    nz         => rz,
    set_port   => rotation_set); 

set_current_rotate: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    if reset_en = '1' then 
      curr_angle <= (others => '0');
      curr_dir   <= (others => '0');
    elsif rotation_set = '1' then 
      curr_angle <= angle(to_integer(counter));
      curr_dir   <= dir(to_integer(counter));
    end if; 
  end if; 

end process set_current_rotate;


set_values: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    if reset_en = '1' then 
      rotated_coords <= (others => (others => '0'));
      counter <= "00";
    else 
      if rotation_set = '1' then 
        rotated_coords(0) <= rx; 
        rotated_coords(1) <= ry; 
        rotated_coords(2) <= rz;
        counter <= counter + 1;
      elsif projection_set = '1' then 
        point_packet <= points; 
      end if; 
    end if; 
  end if; 
end process set_values; 

nx <= rotated_coords(0);
ny <= rotated_coords(1);
nz <= rotated_coords(2);

project: projection 
port map( 
  clk_port     => clk_port, 
  load_port    => projection_en, 
  reset_port   => reset_en, 
  x            => rotated_coords(0),
  y            => rotated_coords(1),
  z            => rotated_coords(2),
  point_packet => points, 
  set_port     => projection_set); 

set_port <= set_en;

--------------------------------------------------------------------------
-- FSM Logic 
--------------------------------------------------------------------------
next_state_logic: process ( current_state, reset_port, load_port, 
                            rotation_set, projection_set, counter, count_max  )
begin 
  if reset_port = '1' then 
    next_state <= idle; 
  else 
    case ( current_state ) is 
      when idle => 
        next_state <= idle; 
        if load_port = '1' then 
          next_state <= rotating; 
        end if; 
      when rotating => 
        next_state <= rotating; 
        if rotation_set = '1' then 
          next_state <= projecting; 
        end if; 
      when projecting => 
        next_state <= projecting; 
        if projection_set = '1' then
          if counter = count_max then 
            next_state <= done; 
          else 
            next_state <= rotating; 
          end if;
        end if; 
      when done => 
        next_state <= idle; 
      when others => 
        null; 
    end case; 
  end if; 
end process next_state_logic; 

output_logic: process( current_state )
begin 
  reset_en      <= '0';
  projection_en <= '0'; 
  rotation_en   <= '0'; 
  set_en        <= '0';

  case ( current_state ) is 
    when idle => 
      reset_en <= '1';
    when rotating => 
      rotation_en <= '1'; 
    when projecting => 
      projection_en <= '1'; 
    when done => 
      set_en <= '1';
    when others => 
      null; 
  end case; 
end process output_logic;

update_state: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    current_state <= next_state; 
  end if; 
end process update_state; 

end architecture behavioral; 
