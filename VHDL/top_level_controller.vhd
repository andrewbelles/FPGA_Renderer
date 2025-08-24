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

-- signals 
signal data : std_logic_vector(7 downto 0);
signal data_valid, HS_sig, VS_sig : std_logic;
signal red_sg, green_sg, blue_sg : std_logic_vector(3 downto 0);

signal load_port, reset_port, set_port : std_logic;
signal angle : array_2x16_t;
signal dir : array_2x2_t;
signal points_sg : array_4x3x24_t; 
signal draw_new_points_sg : std_logic;
signal packets_sg : array_4x16_t;                 -- currently sending these to graphics
signal ready_to_draw_sg, done_drawing_sg : std_logic;
signal new_points_unused : array_4x3x24_t;
type state is (INIT, IDLE, MAP_PRESS, MATH, WAIT_SCREEN, DRAW);
signal next_state, current_state : state := INIT;
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
             load_port => load_port,
             reset_port => reset_port,
             angle => angle,
             dir => dir,
             points => points_sg, 
             new_points => new_points_unused , -- will be unused since we are using packets???
             packets => packets_sg,
             set_port => set_port);


---------------------------------------------------------------------------------------------------------------------------------------------------------------    
-- FSM controller
state_update : process(clk_ext_port) 
begin
    if(rising_edge(clk_ext_port)) then
        current_state <= next_state;
    end if;
end process;

ns_logic : process(current_state)
begin
    next_state <= current_state;
    case current_state is
        when INIT => 
            next_state <= IDLE;
        when IDLE =>
            if (data_valid = '1') then
                next_state <= MAP_PRESS;
            end if;
        when MAP_PRESS =>
            next_state <= MATH;
        when MATH => 
            if(set_port = '1') then
                next_state <= WAIT_SCREEN;
            end if;
        when WAIT_SCREEN =>
            if(ready_to_draw_sg = '1') then
                next_state <= DRAW;
            end if;
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
    
    case current_state is
        when others =>
            null;
    end case;
end process;

         
-- vga outputs
red <= red_sg;
green <= green_sg;
blue <= blue_sg;
HS <= HS_sig;
VS <= VS_sig;
end Behavioral;
