----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/13/2025 06:18:50 PM
-- Design Name: 
-- Module Name: vga_controller - Behavioral
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
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY vga_controller IS
    PORT (
        clk       : in  STD_LOGIC; --100 MHz clock
        video_on  : out STD_LOGIC;
        V_sync    : out STD_LOGIC;
        H_sync    : out STD_LOGIC;
        pixel_x   : out STD_LOGIC_VECTOR(9 downto 0);
        pixel_y   : out STD_LOGIC_VECTOR(9 downto 0)
    );
END vga_controller;

architecture behavior of vga_controller is
    signal H_video_on : STD_LOGIC := '1';
    signal V_video_on : STD_LOGIC := '1';

    -- pclk generation

    signal clk_counter : unsigned(3 downto 0) := (others => '0');
    signal pclk_tc : std_logic := '0';
    -- VGA Constants (taken directly from VGA Class Notes)
    constant left_border : integer := 48;
    constant h_display   : integer := 640;
    constant right_border : integer := 16;
    constant h_retrace    : integer := 96;
    constant HSCAN        : integer := left_border + h_display + right_border + h_retrace - 1; --number of PCLKs in an H_sync period

    -- H_sync process
    --signal h_sync_sg     : STD_LOGIC := '1'; -- start at 1
    signal hscan_counter : unsigned(9 downto 0) := (others => '0');
    signal hscan_tc : std_logic := '0';
    -- V_sync process
    constant top_border   : integer := 29;
    constant v_display    : integer := 480;
    constant bottom_border : integer := 10;
    constant v_retrace    : integer := 2;
    constant VSCAN        : integer := top_border + v_display + bottom_border + v_retrace - 1; --number of H_syncs in an V_sync period

    -- V_sync process
   -- signal v_sync_sg     : STD_LOGIC := '1'; -- start at 1
    signal vscan_counter : unsigned(9 downto 0) := (others => '0');
BEGIN
    -- count clk cycles
    count_clk : process(clk)
    begin
        if rising_edge(clk) then
            if(clk_counter = 3) then
                clk_counter <= (others => '0');
            else
                clk_counter <= clk_counter + 1;
            end if;
        end if;
        
        
    end process count_clk;

    -- H_sync generating process
    hscan_counter_proc : process(clk)
    begin
        if rising_edge(clk) then
            -- hscan counter
            if (pclk_tc = '1') then -- detect rising edge on pclk
                if (hscan_counter = HSCAN) then -- reset counter
                    hscan_counter <= (others => '0');
                else
                    hscan_counter <= hscan_counter + 1; -- increment counter
                end if;
            end if;
        end if;
    end process hscan_counter_proc;

    -- V_sync generating process
    vscan_counter_proc : process(clk)
    begin
        if rising_edge(clk) then
            -- vscan counter
            if (pclk_tc = '1' and hscan_tc = '1') then -- detect the end of the HSync pulse
                if (vscan_counter = VSCAN) then -- reset counter
                    vscan_counter <= (others => '0');
                else
                    vscan_counter <= vscan_counter + 1; -- increment counter
                end if;
            end if;         
        end if;
    end process vscan_counter_proc;

    -- H_sync low between 656 and 751
    h_sync <= '0' when (hscan_counter >= h_display + right_border and hscan_counter < h_display + right_border + h_retrace) else '1';
    -- V_sync low between 480 and 482
    v_sync <= '0' when (vscan_counter >= v_display + bottom_border and vscan_counter < v_display + bottom_border + v_retrace) else '1';

    -- H_video_on high between 0 and 639
    h_video_on <= '1' when hscan_counter < h_display else '0';

    -- V_video high between 0 and 479
    v_video_on <= '1' when vscan_counter < v_display else '0'; 
    
    -- asynchronous tc for pclk and hscan
    pclk_tc <= '1' when clk_counter = 3 else '0';
    hscan_tc <= '1' when hscan_counter = HSCAN else '0';
    
    video_on <= H_video_on AND V_video_on; --Only enable video out when H_video_out and V_video_out are high. It's important to set the output to zero when you aren't actively displaying video. That's how the monitor determines the black level.

    pixel_x <= std_logic_vector(hscan_counter);
    pixel_y <= std_logic_vector(vscan_counter);

END behavior;
