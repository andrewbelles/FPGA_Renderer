----------------------------------------------------------------------------------
-- Ben Sheppard
--Top-level controller for the FPGA rotating tetrahedron project. Coordinates the user input,
-- math, and graphics modules of the project.
-- Runs all systems on 25 MHz clock from clock divider used in class

----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.array_types.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity top_level_controller is
  Port (clk_ext_port   : in std_logic;
        RsRx_ext_port  : in std_logic;
        red            : out std_logic_vector(3 downto 0);
        green          : out std_logic_vector(3 downto 0);
        blue           : out std_logic_vector(3 downto 0);
        HS             : out std_logic;
        VS             : out std_logic 
         );
end top_level_controller;

architecture Behavioral of top_level_controller is
component uart_receiver is
    Port (     clk : in STD_LOGIC;
               rx : in STD_LOGIC;
               data : out STD_LOGIC_VECTOR(7 downto 0);
               data_valid : out STD_LOGIC);
end component;
component system_clock_generation is
    Generic( CLK_DIVIDER_RATIO : integer := 4  );
    Port (
        --External Clock:
        input_clk_port		: in std_logic;
        --System Clock:
        system_clk_port		: out std_logic);
end component;
component graphics_manager is
    Port (
       sys_clk	           : in  std_logic;	-- mapped to external IO device (100 MHz Clock)
       packets              : in array_4x16_t;
       draw_new_points     : in std_logic;
       ready_to_draw       : out std_logic;
       done_drawing        : out std_logic;
       red                 : out std_logic_vector(3 downto 0);
       green               : out std_logic_vector(3 downto 0);
       blue                : out std_logic_vector(3 downto 0);
       HS                  : out std_logic;
       VS                  : out std_logic);
end component;
component parallel_math is
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
end component;

component angle_dir_lut is
    port( 
  clk_port      : in std_logic; 
  request       : in std_logic;
  addr          : in std_logic_vector(7 downto 0); 
  reset_press   : out std_logic;
  dirs          : out array_2x2_t; 
  angles        : out array_2x16_t;
  lut_valid     : out std_logic;
  lut_invalid : out std_logic);
end component;

signal sys_clk : std_logic := '0';
signal data : std_logic_vector(7 downto 0) := (others => '0');
-- graphics
signal data_valid, HS_sig, VS_sig : std_logic := '0';
signal red_sg, green_sg, blue_sg  : std_logic_vector(3 downto 0) := (others => '0');
signal draw_new_points_sg : std_logic := '0';

-- math 
signal load_port_sg, set_port_sg : std_logic := '0';
signal reset_port_sg : std_logic := '1';
signal angle_sg : array_2x16_t := (others => (others => '0'));
signal dir_sg : array_2x2_t := (others => (others => '0'));
signal points_sg : array_4x3x24_t  := (others => (others => (others => '0'))); 
signal packets_sg, packets_reg : array_4x16_t := (others => (others => '0'));
signal ready_to_draw_sg, done_drawing_sg : std_logic := '0';
signal new_points_sg : array_4x3x24_t := (others => (others => (others => '0')));
signal wait_en, wait_tc : std_logic := '0';
signal math_wait_counter : unsigned(4 downto 0) := (others => '0');
signal map_press_control, init_control : std_logic := '0';

-- lut
signal addr_reg       : std_logic_vector(7 downto 0) := (others => '0'); 
signal request_sg, lut_valid, lut_invalid, reset_press_sg : std_logic := '0';
signal current_points : array_4x3x24_t := (
    0 => (0 => x"01A000", 1 => x"01A000", 2 => x"FE6000"),
    1 => (0 => x"01A000", 1 => x"FE6000", 2 => x"01A000"),
    2 => (0 => x"FE6000", 1 => x"01A000", 2 => x"01A000"),
    3 => (0 => x"FE6000", 1 => x"FE6000", 2 => x"FE6000")
);

-- FSM
type state is (INIT, IDLE, MAP_PRESS, WAIT_MATH, MATH, WAIT_SCREEN, START_DRAW, DRAW);
signal next_state, current_state : state := INIT;

begin
clock : system_clock_generation
Port Map(input_clk_port => clk_ext_port,
         system_clk_port => sys_clk);
rec : uart_receiver
    Port Map(clk => sys_clk, -- using 100Mhz clock for uart
             rx => RsRx_ext_port,
             data => data,
             data_valid => data_valid);

graphics_man : graphics_manager
    Port Map(sys_clk => sys_clk,
         packets      => packets_reg,
         draw_new_points  => draw_new_points_sg, 
         ready_to_draw => ready_to_draw_sg,
         done_drawing  => done_drawing_sg,
         red => red_sg,
         green => green_sg,
         blue => blue_sg,
         HS => HS_sig,
         VS => VS_sig);

math_man : parallel_math 
    Port Map(clk_port => sys_clk,
             load_port => load_port_sg,
             reset_port => reset_port_sg,
             angle => angle_sg,
             dir => dir_sg,
             points => current_points, 
             new_points => new_points_sg, 
             packets => packets_sg,
             set_port => set_port_sg);

angle_dir: angle_dir_lut 
    Port Map(clk_port => sys_clk,
             request => request_sg,
             addr => addr_reg,
             dirs => dir_sg,
             reset_press => reset_press_sg,
             angles => angle_sg,
             lut_valid => lut_valid,
             lut_invalid => lut_invalid);
             
-- store packet in register to ensure it gets loaded properly and lasts entire draw cycle
storepacket: process(sys_clk)
begin
    if(rising_edge(sys_clk)) then
        if(set_port_sg = '1') then
            packets_reg <= packets_sg;
        end if;
    end if;
end process;

-- waits 20 cycles with reset_port (input to math) low before asserting load_port and going into math. 
-- do this because it lets the cycles propagate out of math, and we have plenty of time. 20 cycles is overkill, but it can't hurt
wait_tc <= '1' when math_wait_counter = 19 else '0';
waitformath: process(sys_clk)
begin
    if(rising_edge(sys_clk)) then
        if(wait_en = '1') then
            if(wait_tc = '1') then
                math_wait_counter <= (others => '0');
            else 
                math_wait_counter <= math_wait_counter + 1;
            end if;
        end if;
    end if;
end process;

-- assigns current_points, the register that holds the current 3D points
currpoints : process(sys_clk)
begin
    if(rising_edge(sys_clk)) then
        if(init_control = '1') then
            -- default points for init or after clicking reset key
            current_points(0)(0 to 2) <= (x"01A000", x"01A000", x"FE6000");
            current_points(1)(0 to 2) <= (x"01A000", x"FE6000", x"01A000");
            current_points(2)(0 to 2) <= (x"FE6000", x"01A000", x"01A000");
            current_points(3)(0 to 2) <= (x"FE6000", x"FE6000", x"FE6000"); 
        elsif(set_port_sg = '1') then
            current_points <= new_points_sg; -- current points are updated wtih result from math when math is done
        end if;
    end if;
end process;

-- assigns address for accessing angle_dir_LUT           
address : process(sys_clk)
begin
    if(rising_edge(sys_clk)) then
        -- default
        request_sg <= '0';
        if(init_control = '1') then
            addr_reg <= (others => '0'); -- set address to 0 if initializing to map to idx 13
            request_sg <= '1';
        elsif(map_press_control = '1') then
            addr_reg <= data; -- set address to data if in map press state
            request_sg <= '1'; -- send request
        end if;
    end if;
end process;

---------------------------------------------------------------------------------------------------------------------------------------------------------------    
-- FSM controller
state_update : process(sys_clk) 
begin
    if(rising_edge(sys_clk)) then
        current_state <= next_state;
    end if;
end process;

ns_logic : process(current_state, lut_valid, lut_invalid, data_valid, set_port_sg, ready_to_draw_sg, done_drawing_sg, wait_tc, reset_press_sg)
begin
    next_state <= current_state;
    case current_state is
        when INIT => 
            if(lut_valid = '1') then
                next_state <= MATH;
            end if;
        when IDLE =>
            if (data_valid = '1') then
                next_state <= MAP_PRESS;
            end if;
        when MAP_PRESS =>
            if(lut_valid = '1' and lut_invalid = '0') then -- valid index from LUT (proceed to MATH)
                if(reset_press_sg = '1') then --reset press
                    next_state <= INIT; 
                else -- not reset press
                    next_state <= WAIT_MATH;
                end if;
            elsif(lut_invalid = '1'and lut_valid = '0') then -- invalid index from LUT (go back to IDLE)
                next_state <= IDLE;
            end if;
        when WAIT_MATH => -- waits for cycle so that angle and dir propagate down math
            if(wait_tc = '1') then
                next_state <= MATH;
            end if;
        when MATH => 
            if(set_port_sg = '1') then
                next_state <= WAIT_SCREEN;
            end if;
        when WAIT_SCREEN =>
            if(ready_to_draw_sg = '1') then
                next_state <= START_DRAW;
            end if;
        when START_DRAW =>
            next_state <= DRAW;
        when DRAW =>
            if(done_drawing_sg = '1') then
                next_state <= IDLE; -- back to idle for new cycles
            end if;
        when others =>
            next_state <= IDLE;
    end case;
end process;


output_logic : process(current_state)
begin
    init_control <= '0';
    map_press_control <= '0';
    load_port_sg <= '0';
    reset_port_sg <= '1';
    draw_new_points_sg <= '0';
    wait_en <= '0';
    case current_state is
        when INIT =>
            init_control <= '1'; -- goes to clocked process
        when MAP_PRESS =>
            map_press_control <= '1'; -- goes to clocked process
        when WAIT_MATH =>
            reset_port_sg <= '0'; -- need to have reset low for a little before loading math
            wait_en <= '1';
        when MATH =>
            load_port_sg <= '1'; -- load points
            reset_port_sg <= '0'; -- need reset low in math
        when START_DRAW =>
            draw_new_points_sg <= '1'; -- kick off graphics manager
        when others =>
            null;
    end case;
end process;

-- assign outputs
red <= red_sg;
green <= green_sg;
blue <= blue_sg;
HS <= HS_sig;
VS <= VS_sig;
end Behavioral;
