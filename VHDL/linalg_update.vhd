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
  type state_type is ( idle, rotating, bufr_r, projecting, done );
  signal current_state, next_state : state_type := idle; 

  signal curr_angle       : std_logic_vector(15 downto 0) := (others => '0');
  signal curr_dir         : std_logic_vector(1 downto 0)  := (others => '0');
  signal reset_en         : std_logic := '0';
  signal rotation_en      : std_logic := '0';
  signal flag_en          : std_logic := '0';
  signal projection_en    : std_logic := '0'; 
  signal update_r_en      : std_logic := '0'; 
  signal update_packet_en : std_logic := '0'; 
  signal clear_rotate_en  : std_logic := '0'; 
  signal set_en           : std_logic := '0';
  signal rotation_set     : std_logic := '0'; 
  signal projection_set   : std_logic := '0';
  signal second_flag      : std_logic := '0';

  signal inx, iny, inz    : std_logic_vector(23 downto 0) := (others => '0'); 
  signal rx, ry, rz       : std_logic_vector(23 downto 0) := (others => '0');
  signal rotated_coords   : array_3x24_t := (others => (others => '0'));

  signal points           : std_logic_vector(15 downto 0) := (others => '0');

begin 

rotate: rotation
 port map(
    clk_port   => clk_port,
    reset_port => clear_rotate_en,
    angle      => curr_angle,
    dir        => curr_dir,
    x          => inx,
    y          => iny,
    z          => inz,
    nx         => rx,
    ny         => ry,
    nz         => rz,
    set_port   => rotation_set); 

-- Mux each value to be used by rotate 
inx        <= x when second_flag = '0' else rotated_coords(0);
iny        <= y when second_flag = '0' else rotated_coords(1);
inz        <= z when second_flag = '0' else rotated_coords(2);
curr_angle <= angle(0) when second_flag = '0' else angle(1);
curr_dir   <= dir(0)   when second_flag = '0' else dir(0);

set_values: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    if reset_en = '1' then 
      point_packet <= (others => '0');
      rotated_coords <= (others => (others => '0'));
      second_flag <= '0';
    else 
      if flag_en = '1' then 
        second_flag <= '1'; 
      end if; 

      if update_r_en = '1' then 
        rotated_coords(0) <= rx; 
        rotated_coords(1) <= ry; 
        rotated_coords(2) <= rz;

      elsif update_packet_en = '1' then 
        point_packet <= points; 
      end if; 
    end if; 
  end if; 
end process set_values; 

set_output: process( clk_port ) 
begin 
  if rising_edge( clk_port ) then 
     if reset_en = '1' then 
       nx <= (others => '0'); 
       ny <= (others => '0'); 
       nz <= (others => '0');
     elsif set_en = '1' then 
       nx <= rotated_coords(0);
       ny <= rotated_coords(1);
       nz <= rotated_coords(2);
     end if; 
  end if; 
end process set_output; 
  
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
                            rotation_set, projection_set, second_flag )
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
          next_state <= bufr_r; 
        end if; 
      when bufr_r => 
        if second_flag = '0' then 
          next_state <= rotating; 
        else 
          next_state <= projecting; 
        end if; 
      when projecting => 
        next_state <= projecting; 
        if projection_set = '1' then
          next_state <= done; 
        end if; 
      when done => 
        next_state <= idle; 
      when others => 
        null; 
    end case; 
  end if; 
end process next_state_logic; 

output_logic: process( current_state, second_flag )
begin 
  reset_en         <= '0';
  projection_en    <= '0'; 
  rotation_en      <= '0'; 
  set_en           <= '0';
  flag_en          <= '0';
  update_r_en      <= '0';
  update_packet_en <= '0';
  clear_rotate_en  <= '0'; 

  case ( current_state ) is 
    when idle => 
      reset_en <= '1';
    when bufr_r =>
      if second_flag = '1' then 
        projection_en <= '1'; 
      end if; 
      
      clear_rotate_en <= '1'; 
      update_r_en <= '1'; 
      if second_flag = '0' then 
        flag_en <= '1'; 
      end if; 
    when rotating => 
      rotation_en <= '1'; 
    when projecting => 
      projection_en <= '1'; 
    when done => 
      update_packet_en <= '1';
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
