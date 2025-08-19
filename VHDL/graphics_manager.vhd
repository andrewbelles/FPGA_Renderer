----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/18/2025 01:54:53 PM
-- Design Name: 
-- Module Name: graphics_manager - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use work.array_types.all;


entity graphics_manager is
Port (clk                  :       in std_logic;
      new_vertices         :       in  std_logic; -- from central controller, signals there are new verticies ready
      vertices             :       in  array_4x16_t;
      buffer_write_sel     :       out std_logic;
      load_mem             :       out std_logic;
      x, y                 :       out std_logic_vector(7 downto 0)
       );
end graphics_manager;

architecture Behavioral of graphics_manager is
-- counter keeps track of drawing each line; there are 6 pairs of verticies that need to run bresenham
signal counter    : unsigned(2 downto 0) := (others => '0');
signal counter_tc : std_logic := '0';
signal inc_counter : std_logic := '0';
signal reset_counter : std_logic := '0';

-- Points
type point8_array is array(0 to 3) of std_logic_vector(7 downto 0); -- holds the 4 8 bit x/y coords
signal x_points, y_points : point8_array := (others => (others => '0'));

-- keep track of which buffer is active
signal buffer_write_sel_sg  : std_logic := '0'; -- holds which buffer is active for framebuffer module to write to
signal flip_buffer : std_logic := '0'; -- signal from FSM to flip buffer

-- bresenham signals
signal reset_bres, plot_bres, start_bres, done_bres :  std_logic := '0';
signal x0_bres, y0_bres, x1_bres, y1_bres, x_bres, y_bres         : std_logic_vector(7 downto 0) := (others => '0');



type state is (IDLE, ACTIVATE, LOAD, DRAW);
signal current_state, next_state : state := IDLE;

component bresenham is
    Port (clk, reset        :   in std_logic;
          start             :   in std_logic;
          x0, y0, x1, y1    :   in std_logic_vector(7 downto 0);
          plot              :   out std_logic;    
          x, y              :   out std_logic_vector(7 downto 0);
          done              :   out std_logic
         );    
end component;
begin
----------------------------------------------------------------------------------------------------------------------------------------
-- PORT MAP for the bresenham module
bres : bresenham 
    Port Map(
        clk => clk, 
        reset => reset_bres,
        start => start_bres,
        x0 => x0_bres,
        y0 => y0_bres,
        x1 => x1_bres,
        y1 => y1_bres,
        plot => plot_bres,
        x => x_bres,
        y => y_bres,
        done => done_bres);
------------------------------------------------------------------------------------------------------------------------------------
-- DATAPATH

-- Sync
xy_proc   : process(clk)
begin
    if(rising_edge(clk))) then
-- counter for how many times Bresenham module has been run. Maxes out at 6 times for 6 pairs of points
count_proc : process(clk) 
begin
    if(rising_edge(clk)) then
        if(reset_counter = '1') then
            counter <= (others => '0'); -- start at 0
        elsif(done_bres = '1') then -- if bresenham is done
                counter <= counter + 1;
        end if;
    end if;
end process;

-- register for which buffer the framebuffer module should write to
buffer_proc : process(clk)
begin
    if(rising_edge(clk) then
        if(flip_buffer = '1') then
            buffer_write_sel_sg <= NOT buffer_write_sel_sg;
        end if;
    end if;
end process;

-- assign the x_points and y_points into array so that can easily access them by index
process(clk)
begin
    if(rising_edge(clk)) then
        if(new_vertices = '1') then -- captures the points on new_vertices
            x_points(0) <= vertices(0)(15 downto 8);
            y_points(0) <= vertices(0)(7 downto 0);
            x_points(1) <= vertices(1)(15 downto 8);
            y_points(1) <= vertices(1)(7 downto 0);
            x_points(2) <= vertices(2)(15 downto 8);
            y_points(2) <= vertices(2)(7 downto 0);
            x_points(3) <= vertices(3)(15 downto 8);
            y_points(3) <= vertices(3)(7 downto 0);
        end if;
    end if;
end process;      


-- process wires up the bresenham module to the correct pairs of points. There are 6 pairs of lines that we want to draw, so have 6 cases
-- counter represents how many times Bresenhan has been run so far. 
-- NOTE: This is clearly very hard-coded. Look into more general version that could do arbitrary number of points, such as with cube.
bres_wiring : process(clk)
begin
    if rising_edge(clk) then
        if start_bres = '1' then
            case counter is
                when "000" =>  -- line 0: point0 -> point1
                    x0_bres <= x_points(0);
                    y0_bres <= y_points(0);
                    x1_bres <= x_points(1);
                    y1_bres <= y_points(1);
                when "001" =>  -- line 1: point0 -> point2
                    x0_bres <= x_points(0);
                    y0_bres <= y_points(0);
                    x1_bres <= x_points(2);
                    y1_bres <= y_points(2);
                when "010" =>  -- line 2: point0 -> point3
                    x0_bres <= x_points(0);
                    y0_bres <= y_points(0);
                    x1_bres <= x_points(3);
                    y1_bres <= y_points(3);
                when "011" =>  -- line 3: point1 -> point2
                    x0_bres <= x_points(1);
                    y0_bres <= y_points(1);
                    x1_bres <= x_points(2);
                    y1_bres <= y_points(2);
                when "100" =>  -- line 4: point1 -> point3
                    x0_bres <= x_points(1);
                    y0_bres <= y_points(1);
                    x1_bres <= x_points(3);
                    y1_bres <= y_points(3);
                when "101" =>  -- line 5: point2 -> point3
                    x0_bres <= x_points(2);
                    y0_bres <= y_points(2);
                    x1_bres <= x_points(3);
                    y1_bres <= y_points(3);
                when others =>
                    x0_bres <= (others=>'0');
                    y0_bres <= (others=>'0');
                    x1_bres <= (others=>'0');
                    y1_bres <= (others=>'0');
            end case;
        end if;
    end if;
end process;

-- Async

-- buffer write select signal 
buffer_write_sel <= buffer_write_sel_sg;
-- counter terminal count
counter_tc <= '1' when counter = 6 else '0';

------------------------------------------------------------------------------------------------------------------------------------
-- FSM waits for new_vertices signal from central controller to assert. Then it activates bresenham 6 times, one
-- for each of the 6 combinations of vertex endpoints. After running it 6 times, it flips which buffer is active 
-- so that the graphics driver will swap to what was just written.
state_update : process(clk) 
begin
    if(rising_edge(clk)) then
        current_state <= next_state;
    end if;
end process;

ns_logic : process(current_state, counter_tc, plot_bres, new_vertices)
begin
    next_state <= current_state;
    case current_state is
        when IDLE =>
            if(new_vertices = '1') then
                next_state <= ACTIVATE;
            end if;
        when ACTIVATE =>
            next_state <= LOAD;
        when LOAD => 
            if(counter_tc = '0' and plot_bres = '0') then
                next_state <= ACTIVATE;
            elsif(counter_tc = '1' and plot_bres = '0') then
                next_state <= DRAW;
            end if;
        when DRAW =>
            next_state <= IDLE;
        when others =>
            next_state <= IDLE;
    end case;
end process;

output_logic : process(current_state)
begin
    start_bres <= '0';
    reset_counter <= '0';
    flip_buffer <= '0';
    case current_state is
        when IDLE =>
            reset_counter <= '1';
        when ACTIVATE =>
            start_bres <= '1';
        when LOAD =>
            load_mem <= '1';
        when DRAW =>
            flip_buffer <= '1';
        when others =>
            null;
    end case;
end process;
end Behavioral;
