----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/18/2025 01:54:53 PM
-- Design Name: 
-- Module Name: bresenham_receiver - Behavioral
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


entity bresenham_receiver is
Port (clk                  :       in std_logic;
      new_vertices         :       in  std_logic; -- from central controller, signals there are new vertices ready
      vertices             :       in  array_4x16_t;
      clear_fulfilled      :       in std_logic;
      
      clear_request        :       out std_logic; -- control signal to tell framebuffer to clear back
      tet_drawn            :       out std_logic; -- control signal to tell framebuffer bres is finished
      load_mem             :       out std_logic;
      x, y                 :       out std_logic_vector(7 downto 0)
       );
end bresenham_receiver;

architecture Behavioral of bresenham_receiver is
-- counter keeps track of how many lines have been drawn; there are 6 pairs of verticies that need to run bresenham
signal counter    : unsigned(2 downto 0) := (others => '0');
signal counter_tc : std_logic := '0';
signal inc_counter : std_logic := '0';
signal reset_counter : std_logic := '0';

-- New Points
type point8_array is array(0 to 3) of std_logic_vector(7 downto 0); -- holds the four 8 bit x/y coords
signal x_points, y_points : point8_array := (others => (others => '0'));
signal load_new_pts : std_logic := '0';
--
-- Buffer writing
signal load_mem_sg : std_logic := '0';
signal flip_buffer : std_logic := '0'; -- signal from FSM to flip buffer

-- bresenham signals
signal reset_bres, plot_bres, start_bres, done_bres :  std_logic := '0';
signal x0_bres, y0_bres, x1_bres, y1_bres, x_bres, y_bres         : std_logic_vector(7 downto 0) := (others => '0');



type state is (IDLE, CB, ACTIVATE, COMPUTE, INC, DONE);
signal current_state, next_state : state := IDLE;
signal tet_drawn_sg : std_logic;
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

-- SYNCHRONOUS

        
-- counter for how many times Bresenham module has been run. Maxes out at 5 for 6 pairs of points
count_proc : process(clk) 
begin
    if(rising_edge(clk)) then
        if(reset_counter = '1') then
            counter <= (others => '0'); -- start at 0
        elsif(inc_counter = '1') then -- if bresenham algorithm is completed between 2 points
                counter <= counter + 1;
        end if;
    end if;
end process;

-- deleted -- cant just flip buffer right away
---- register for which buffer the framebuffer module should write to
--buffer_proc : process(clk)
--begin
--    if(rising_edge(clk)) then
--        if(flip_buffer = '1') then
--            buffer_write_sel_sg <= NOT buffer_write_sel_sg; -- go to the other buffer
--        end if;
--    end if;
--end process;

-- assign the x_points and y_points into array so that can easily access them by index
load_pts: process(clk)
begin
    if(rising_edge(clk)) then
        if(load_new_pts = '1') then -- captures the points on new_vertices
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


-- ASYNCHRONOUS 

-- process wires up the bresenham module to the correct pairs of points. There are 6 pairs of lines that we want to draw, so have 6 cases
-- counter represents how many times Bresenhan has been run so far. 
-- NOTE: This is clearly very hard-coded. Look into more general version that could do arbitrary number of points, such as with cube.

-- put current state on it to ensure that it checks every state that bresneham module is wired correctly



-- DO I NEED TO PUT X_POINTS ETC ON SENSITIVITY LIST????????
bres_input : process(current_state, counter)
begin
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
end process;

-- Async
  
-- assign x and y (memory address output) (address to read/write to) 
xy_proc : process(plot_bres, x_bres, y_bres)
begin
    -- load while plot_bres is high
    load_mem_sg <= plot_bres;

    -- x and y are only valid when plot_bres (from bresenham module) is high
    if(plot_bres = '1') then
        x <= x_bres;
        y <= y_bres;
    else
        x <= (others => '0');
        y <= (others => '0');
    end if;
end process;

-- load_mem signal
load_mem <= load_mem_sg;

-- counter terminal count
counter_tc <= '1' when counter = 5 else '0';

tet_drawn <= tet_drawn_sg;
------------------------------------------------------------------------------------------------------------------------------------
-- FSM waits for new_vertices signal from central controller to assert. Then it activates bresenham 6 times, one
-- for each of the 6 combinations of vertex endpoints. After running it 6 times, it flips which buffer is active 
-- so that the graphics driver will swap to displaying what was just written.
state_update : process(clk) 
begin
    if(rising_edge(clk)) then
        current_state <= next_state;
    end if;
end process;

ns_logic : process(current_state, clear_fulfilled, counter_tc, done_bres, plot_bres, new_vertices)
begin
    next_state <= current_state;
    case current_state is
        when IDLE =>
            if(new_vertices = '1') then
                next_state <= CB;
            end if;
        when CB =>
            if(clear_fulfilled  = '1') then
                next_state <= ACTIVATE;
            end if;
        when ACTIVATE =>
            next_state <= COMPUTE;
        when COMPUTE => 
            if(counter_tc = '0' and done_bres = '1') then
                next_state <= INC;
            elsif(counter_tc = '1' and done_bres = '1') then
                next_state <= DONE;
            end if;
        when INC =>
            next_state <= ACTIVATE;
        when DONE => 
            next_state <= IDLE;
        when others =>
            next_state <= IDLE;
    end case;
end process;

output_logic : process(current_state)
begin
    start_bres <= '0';
    reset_counter <= '0';
    inc_counter <= '0';
    load_new_pts <= '0';
    clear_request <= '0';
    tet_drawn_sg <= '0';
    case current_state is
        when IDLE =>
            reset_counter <= '1';
            load_new_pts <= '1';
        when CB =>
            clear_request <= '1';
        when ACTIVATE =>
            start_bres <= '1';
        when INC =>
            inc_counter <= '1';
        when DONE =>
            tet_drawn_sg <= '1';
        when others =>
            null;
    end case;
end process;


end Behavioral;
