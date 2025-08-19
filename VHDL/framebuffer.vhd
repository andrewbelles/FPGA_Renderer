----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/18/2025 12:24:52 PM
-- Design Name: 
-- Module Name: framebuffer_manager - Behavioral
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
entity framebuffer is
    Port (clk                 :   in std_logic;
          reset               :   in std_logic;
          write_x, write_y    :   in std_logic_vector(7 downto 0); -- addess to write
          write_en            :   in std_logic;
          buffer_write_sel    :   in std_logic;
          read_x, read_y      :   in std_logic_vector(9 downto 0); -- address to read
          video_on            :   in std_logic;
          -- note takes in HS and VS unlike the VGA setup because need to slow them down by 1 clock cycle due to reading BRAM
          HS_in               :   in std_logic;
          VS_in               :   in std_logic;
        
          VGA_HS              :   out std_logic;
          VGA_VS              :   out std_logic;
          VGA_out             :   out std_logic_vector(11 downto 0) -- framebuffer data, 8 bit for an 8 bit color
           );
end framebuffer;

architecture Behavioral of framebuffer is
signal buf0, buf1 : buf256x256 := (others => '0'); -- 2 buffers 
signal write_addr : std_logic_vector(15 downto 0) := (others => '0'); -- address to write 
signal read_addr  : std_logic_vector(15 downto 0) := (others => '0'); -- address to read
-- buffer output value is 12 bits, for now just doing all 0s or 1s
signal buffer_out : std_logic_vector(11 downto 0) := (others => '0');

-- signals to hold delayed value of video_on, etc (because read introduces a 1 cycle delay)
signal video_on_delayed : std_logic := '0';
signal HS_delayed       : std_logic := '0';
signal VS_delayed       : std_logic := '0';

begin

-- Resets both buffers if reset goes high. if write_en is high, it will choose which buffer to write to.
write: process(clk)
begin
    if(rising_edge(clk)) then
        if(reset = '1') then
            buf0 <= (others => '0');
            buf1 <= (others => '0');
        elsif(write_en = '1') then
            if(buffer_write_sel = '0') then
                buf0(to_integer(unsigned(write_addr))) <= '1';
            elsif(buffer_write_sel = '1') then
                buf1(to_integer(unsigned(write_addr))) <= '1';
            end if;
        end if;
    end if;
end process;



-- FOR NOW: Just doing black or white (all 0s or all 1s). May add functionality in future 
read: process(clk)
begin
    if(rising_edge(clk)) then
        -- in center of screen
        if (unsigned(read_x) >= 192 and unsigned(read_x) < 448 and
            unsigned(read_y) >= 112 and unsigned(read_y) < 368) then
           
            if(buffer_write_sel = '1') then -- if writing to buffer 1, read from buffer 0
                if(buf0(to_integer(unsigned(read_addr))) = '1') then
                    buffer_out <= (others => '1');
                else 
                    buffer_out <= (others => '0');
                end if;
            elsif(buffer_write_sel = '0') then -- if writing to buffer 0, read from buffer 1
                if(buf1(to_integer(unsigned(read_addr))) = '1') then
                    buffer_out <= (others => '1');
                else 
                    buffer_out <= (others => '0');
                end if;
            end if;
        else 
            buffer_out <= (others => '0');
        end if;
    end if;
end process;


pipeline : process(clk)
begin
    if(rising_edge(clk)) then
        video_on_delayed <= video_on;
        HS_delayed <= HS_in;
        VS_delayed <= VS_in;
    end if;
end process;

-- asynchronous computes address 
-- address is y*256+x which can be done by shifting y left 8 times, oring it with x
-- need to prepend 8 0s to x/y since they are only 8 bits 
write_addr <= std_logic_vector(
           (unsigned(write_y) & unsigned(write_x))
        );
        
-- process to find address to read
raddr: process(read_x, read_y)
    variable x_offset, y_offset : unsigned(9 downto 0);
begin
    -- in center 256x256 window of screen
    if (unsigned(read_x) >= 192 and unsigned(read_x) < 448 and
        unsigned(read_y) >= 112 and unsigned(read_y) < 368) then

        x_offset := unsigned(read_x) - 192;
        y_offset := unsigned(read_y) - 112;
        read_addr <= std_logic_vector(y_offset(7 downto 0) & x_offset(7 downto 0)); -- performs shift by 8 and then OR with x 

    else
        read_addr <= (others => '0');
    end if;
end process;

VGA_out <= buffer_out when video_on_delayed = '1' else (others => '0'); -- only display when video is on
VGA_HS <= HS_delayed;
VGA_VS <= VS_delayed;


end Behavioral;
