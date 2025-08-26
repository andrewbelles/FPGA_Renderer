----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/22/2025 12:29:24 PM
-- Design Name: 
-- Module Name: top_level_controller - Behavioral
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
       points              : in array_4x16_t;
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
  clk_port   : in std_logic; 
  request    : in std_logic;
  addr       : in std_logic_vector(7 downto 0); 
  dirs       : out array_2x2_t; 
  angles     : out array_2x16_t;
  lut_valid : out std_logic;
  lut_invalid : out std_logic);
end component;
-- signals 
signal sys_clk : std_logic := '0';
signal data : std_logic_vector(7 downto 0) := (others => '0');
-- graphics
signal data_valid, HS_sig, VS_sig : std_logic := '0';
signal red_sg, green_sg, blue_sg  : std_logic_vector(3 downto 0) := (others => '0');
signal draw_new_points_sg : std_logic := '0';

-- math signals
signal load_port_sg, reset_port_sg, set_port_sg : std_logic := '0';
signal angle_sg : array_2x16_t := (others => (others => '0'));
signal dir_sg : array_2x2_t := (others => (others => '0'));
signal points_sg : array_4x3x24_t  := (others => (others => (others => '0'))); 
signal packets_sg, packets_reg : array_4x16_t := (others => (others => '0'));                 -- currently sending these to graphics
signal ready_to_draw_sg, done_drawing_sg : std_logic := '0';
signal new_points_sg : array_4x3x24_t := (others => (others => (others => '0')));

-- lut
signal addr_reg       : std_logic_vector(7 downto 0) := (others => '0'); 
signal request_sg, lut_valid, lut_invalid : std_logic := '0';

signal current_points : array_4x3x24_t := (
    0 => (0 => x"00C000", 1 => x"00C000", 2 => x"FF4000"),
    1 => (0 => x"000000", 1 => x"FF4000", 2 => x"FF4000"),
    2 => (0 => x"FF4000", 1 => x"00C000", 2 => x"FF4000"),
    3 => (0 => x"000000", 1 => x"000000", 2 => x"00C000")
);

-- FSM
type state is (INIT, IDLE, MAP_PRESS, MATH, WAIT_SCREEN, START_DRAW, DRAW);
signal next_state, current_state : state := INIT;
signal map_press_control, init_control : std_logic := '0';
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
         points      => packets_reg,
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
             angles => angle_sg,
             lut_valid => lut_valid,
             lut_invalid => lut_invalid);
             
-- store packet in register to ensure it gets loaded properly  
process(sys_clk)
begin
    if(rising_edge(sys_clk)) then
        if(set_port_sg = '1') then
            packets_reg <= packets_sg;
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

ns_logic : process(current_state, lut_valid, lut_invalid, data_valid, set_port_sg, ready_to_draw_sg, done_drawing_sg)
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
                next_state <= MATH;
            elsif(lut_invalid = '1'and lut_valid = '0') then -- invalid index from LUT (go back to IDLE)
                next_state <= IDLE;
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
                next_state <= IDLE;
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
    case current_state is
        when INIT =>
            init_control <= '1';
        when MAP_PRESS =>
            map_press_control <= '1';
        when MATH =>
            load_port_sg <= '1';
            reset_port_sg <= '0';
        when START_DRAW =>
            draw_new_points_sg <= '1';
        when others =>
            null;
    end case;
end process;

point_proc : process(sys_clk)
begin
    if(rising_edge(sys_clk)) then
        if(init_control = '1') then
            current_points(0)(0 to 2) <= (x"032000", x"032000", x"00A000");
            current_points(1)(0 to 2) <= (x"032000", x"FCE000", x"FF6000");
            current_points(2)(0 to 2) <= (x"FCE000", x"032000", x"FF6000");
            current_points(3)(0 to 2) <= (x"FCE000", x"FCE000", x"00A000"); 
        -- update current_points when done with math
        elsif(set_port_sg = '1') then
            current_points <= new_points_sg;
        end if;
    end if;
end process;
           
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

red <= red_sg;
green <= green_sg;
blue <= blue_sg;
HS <= HS_sig;
VS <= VS_sig;
end Behavioral;
