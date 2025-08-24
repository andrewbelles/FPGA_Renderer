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
--library UNISIM;
--use UNISIM.VComponents.all;

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

component graphics_manager is
    Port ( clk_ext_port	   : in  std_logic;	-- mapped to external IO device (100 MHz Clock)
       points              : in array_4x16_t;
       draw_new_points     : in std_logic;
       ready_to_draw            : out std_logic;
       done_drawing             : out std_logic;
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
  addr       : in std_logic_vector(7 downto 0); 
  dirs       : out array_2x2_t; 
  angles     : out array_2x16_t;
  lut_ready : out std_logic);
end component;
-- signals 
signal data : std_logic_vector(7 downto 0);
signal data_valid, HS_sig, VS_sig : std_logic;
signal red_sg, green_sg, blue_sg : std_logic_vector(3 downto 0);

signal load_port_sg, reset_port_sg, set_port_sg : std_logic;
signal angle_sg : array_2x16_t;
signal dir_sg : array_2x2_t;
signal points_sg : array_4x3x24_t; 
signal draw_new_points_sg : std_logic;
signal packets_sg : array_4x16_t := (others => (others => '0'));                 -- currently sending these to graphics
signal ready_to_draw_sg, done_drawing_sg : std_logic;
signal new_points_sg : array_4x3x24_t;

signal start_math : std_logic;
-- lut
signal addr_reg       : std_logic_vector(7 downto 0) := (others => '0'); 
signal lut_ready : std_logic;

signal current_points : array_4x3x24_t;
-- FSM
type state is (INIT, IDLE, MAP_PRESS, MATH, WAIT_SCREEN, START_DRAW, DRAW);
signal next_state, current_state : state := INIT;
signal map_press_control, init_control : std_logic;
begin
rec : uart_receiver
    Port Map(clk => clk_ext_port,
             rx => RsRx_ext_port,
             data => data,
             data_valid => data_valid);

graphics_man : graphics_manager
    Port Map(clk_ext_port => clk_ext_port,
         points      => packets_sg,
         draw_new_points  => draw_new_points_sg, 
         ready_to_draw => ready_to_draw_sg,
         done_drawing  => done_drawing_sg,
         red => red_sg,
         green => green_sg,
         blue => blue_sg,
         HS => HS_sig,
         VS => VS_sig);

math_man : parallel_math 
    Port Map(clk_port => clk_ext_port,
             load_port => load_port_sg,
             reset_port => reset_port_sg,
             angle => angle_sg,
             dir => dir_sg,
             points => points_sg, 
             new_points => new_points_sg, 
             packets => packets_sg,
             set_port => set_port_sg);

angle_dir: angle_dir_lut 
    Port Map(clk_port => clk_ext_port,
             addr => addr_reg,
             dirs => dir_sg,
             angles => angle_sg,
             lut_ready => lut_ready);
---------------------------------------------------------------------------------------------------------------------------------------------------------------    
-- FSM controller
state_update : process(clk_ext_port) 
begin
    if(rising_edge(clk_ext_port)) then
        current_state <= next_state;
    end if;
end process;

ns_logic : process(current_state, lut_ready, data_valid, set_port_sg, ready_to_draw_sg, done_drawing_sg)
begin
    next_state <= current_state;
    case current_state is
        when INIT => 
            if(lut_ready = '1') then
                next_state <= MATH;
            end if;
        when IDLE =>
            if (data_valid = '1') then
                next_state <= MAP_PRESS;
            end if;
        when MAP_PRESS =>
            if(lut_ready = '1') then
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
    start_math <= '0';
    reset_port_sg <= '0';
    draw_new_points_sg <= '0';
    case current_state is
        when INIT =>
            init_control <= '1';
        when MAP_PRESS =>
            map_press_control <= '1';
        when MATH =>
            start_math <= '1';
        when START_DRAW =>
            reset_port_sg <= '1'; -- reset math for next time
            draw_new_points_sg <= '1';
        when others =>
            null;
    end case;
end process;

point_proc : process(clk_ext_port)
begin
    if(rising_edge(clk_ext_port)) then
        load_port_sg <= '0';
        if(init_control = '1') then
            current_points(0)(0 to 2) <= (x"014000", x"014000", x"014000");
            current_points(1)(0 to 2) <= (x"014000", x"FEC000", x"FEC000");
            current_points(2)(0 to 2) <= (x"FEC000", x"014000", x"FEC000");
            current_points(3)(0 to 2) <= (x"FEC000", x"FEC000", x"014000"); 
        -- update current_points when done with math
        elsif(set_port_sg = '1') then
            current_points <= new_points_sg;
        end if;
        
        if(start_math = '1') then
           points_sg <= current_points;
           load_port_sg <= '1';
        end if;
    end if;
end process;
           
address : process(clk_ext_port)
begin
    if(rising_edge(clk_ext_port)) then
        if(init_control = '1') then
            addr_reg <= (others => '0'); -- set address to 0 if initializing
        elsif(map_press_control = '1') then
            addr_reg <= data; -- set address to data if in map press state
        end if;
    end if;
end process;
           
--curr_points : process(clk_ext_port)
--begin
--    if(rising_edge(clk_ext_port)) then
--        if(init_control = '0' and start_math = '0') then -- if not in init state
--            current_points <= new_points_sg;
--        end if;
--    end if;
--end process;
-- vga outputs
red <= red_sg;
green <= green_sg;
blue <= blue_sg;
HS <= HS_sig;
VS <= VS_sig;
end Behavioral;
