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
          clear_request       :   in std_logic; -- tells framebuffer to clear back 
          tet_drawn           :   in std_logic; -- tells framebuffer bres is complete
          write_x, write_y    :   in std_logic_vector(7 downto 0); -- address to write
          write_en            :   in std_logic;
          pixel_x, pixel_y    :   in std_logic_vector(9 downto 0); -- address to read
          video_on            :   in std_logic;
          -- note takes in HS and VS unlike the VGA setup because need to slow them down by 1 clock cycle due to reading BRAM
          HS_in               :   in std_logic;
          VS_in               :   in std_logic;
        
          clear_fulfilled     :   out std_logic; -- tells manager back buff is cleared
          VGA_HS              :   out std_logic;
          VGA_VS              :   out std_logic;
          VGA_out             :   out std_logic_vector(11 downto 0) -- framebuffer data, 8 bit for an 8 bit color
           );
end framebuffer;

architecture Behavioral of framebuffer is
-- BRAM component, width 1, depth 65536
COMPONENT blk_mem_gen_0
  PORT (
    clka    : IN STD_LOGIC;
    ena     : IN STD_LOGIC;
    wea     : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dina    : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    douta   : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END COMPONENT;

-- read and write addresses computed based on pixel_x and pixel_y input
signal write_addr : std_logic_vector(15 downto 0) := (others => '0'); 
signal read_addr  : std_logic_vector(15 downto 0) := (others => '0');

-- address for clearing cycle
signal clear_addr    : unsigned(15 downto 0) := (others => '0');

-- buffer address
signal buff0_addr : std_logic_vector(15 downto 0);
signal buff1_addr : std_logic_vector(15 downto 0);

-- buffer write enable
signal buff0_wea  : std_logic_vector(0 downto 0);
signal buff1_wea  : std_logic_vector(0 downto 0);

-- buffer data to write
signal write_data : std_logic_vector(0 downto 0) := (others => '0');

-- buffer outputs
signal buff0_output : std_logic_vector(0 downto 0);
signal buff1_output : std_logic_vector(0 downto 0);

-- buffer select
signal front_buff : std_logic := '0'; -- says which buffer is currently drawing to screen

-- VGA output value is 12 bits, for now just doing all 0s or 1s
signal VGA_out_sg : std_logic_vector(11 downto 0) := (others => '0');

-- Pipelining signals (using shift register method
signal video_on_delayed : std_logic_vector(3 downto 0);
signal HS_delayed       : std_logic_vector(3 downto 0);
signal VS_delayed       : std_logic_vector(3 downto 0);
signal buff0_output_reg : std_logic_vector(1 downto 0);
signal buff1_output_reg : std_logic_vector(1 downto 0);

signal pixel_x_delayed : std_logic_vector(39 downto 0);
signal pixel_y_delayed : std_logic_vector(39 downto 0);

-- FSM signals
type state is (IDLE, CB, CLEARED, RECEIVE, WAITING, SWAP);
signal current_state, next_state : state := IDLE;

signal clear_tc : std_logic; -- from logic to fsm to say that the local clear of back is at addr 2^16-1 (it is finished)
signal blanking : std_logic; -- from logic to fsm to say that we are in a blanking region

signal clearing : std_logic; -- from fsm to clearing logic says to start clearing memory
signal receiving : std_logic; -- -- from fsm to logic to say that we are receiving and writing to memory
signal am_waiting   : std_logic; -- from fsm to logic to say that we are waiting for blanking region
signal go_swap         : std_logic; -- from fsm to logic to say to swap which one is drawing to vga


begin

-- INSTANTIATE BRAM
buff0 : blk_mem_gen_0
  PORT MAP (
    clka => clk,
    ena => '1', -- tie enable to 1 for now
    wea => buff0_wea,
    addra => buff0_addr,
    dina => write_data,
    douta => buff0_output
  );
  
  buff1 : blk_mem_gen_0
  PORT MAP (
    clka => clk,
    ena => '1', -- tie enable to 1 for now
    wea => buff1_wea,
    addra => buff1_addr,
    dina => write_data,
    douta => buff1_output
  );
  
------------------------------------------------------------------------------------------------------------------------------------
-- LOGIC

-- slows down video on, VS, and HS by 4 sclock cycles 
-- slows down buffer output by 2 clock cycles (note, needed output register due to sub-clock cycle latency issue)
-- slows down pixel_x and pixel_y by 4 sclock (1 VGA pixel) for determining addr early enough in raddr process
pipeline : process(clk)
begin
    if(rising_edge(clk)) then
        --delay video_on, HS, VS by 4 cycles
        video_on_delayed(0) <= video_on; -- cycle t
        video_on_delayed(1) <= video_on_delayed(0); -- cycle t+1
        video_on_delayed(2) <= video_on_delayed(1); -- cycle t+1
        video_on_delayed(3) <= video_on_delayed(2); -- cycle t+1

        HS_delayed(0) <= HS_in;
        HS_delayed(1) <= HS_delayed(0);
        HS_delayed(2) <= HS_delayed(1);
        HS_delayed(3) <= HS_delayed(2);

        VS_delayed(0) <= VS_in;
        VS_delayed(1) <= VS_delayed(0);
        VS_delayed(2) <= VS_delayed(1);
        VS_delayed(3) <= VS_delayed(2);
        
        -- delay BRAM output by 2 clock cycles
        buff0_output_reg(0) <= buff0_output(0);
        buff0_output_reg(1) <= buff0_output_reg(0);
        buff1_output_reg(0) <= buff1_output(0);
        buff1_output_reg(1) <= buff1_output_reg(0);
        
        -- delay pixel_x and pixel_y by 4 clock cycles to match delay from addr to output: BRAM (2) + output (2) = 4
        pixel_x_delayed(9 downto 0) <= pixel_x;
        pixel_x_delayed(19 downto 10) <= pixel_x_delayed(9 downto 0);
        pixel_x_delayed(29 downto 20) <= pixel_x_delayed(19 downto 10);
        pixel_x_delayed(39 downto 30) <= pixel_x_delayed(29 downto 20);
        pixel_y_delayed(9 downto 0) <= pixel_y;
        pixel_y_delayed(19 downto 10) <= pixel_y_delayed(9 downto 0);
        pixel_y_delayed(29 downto 20) <= pixel_y_delayed(19 downto 10);
        pixel_y_delayed(39 downto 30) <= pixel_y_delayed(29 downto 20);
        
    end if;
end process;


-- swaps which buffer is active (synchronous) when go_swap control signal from FSM goes high
swapproc : process(clk)
begin
    if(rising_edge(clk)) then
        if(go_swap = '1') then
            front_buff <= NOT front_buff;
        end if;
    end if;
end process;


-- Clear entire BRAM  by looping over every address and setting them to 0. Takes in signal from fsm called clearing
clrmem : process(clk)
begin
    if(rising_edge(clk)) then
        if(clearing = '1') then
            if(clear_tc = '0') then
                clear_addr <= clear_addr + 1;
            else
                clear_addr <= (others => '0');
            end if;
        end if;
    end if;
end process;

-- terminal count for clear process
clear_tc <= '1' when clear_addr = 65535 else '0';


-- process sets VGA_out_sg by setting it to all 1s or all 0s
-- chooses correct BRAM based on front_buff
-- FOR NOW: Just doing black or white (all 0s or all 1s). May add functionality in future 
-- 
--Notes: Had a lot of trouble with timing, but I believe it has been fixed now that I am running this VGA output off of the delayed
-- pixel. pixel_x_delayed is 4 system clock cycles behind pixel x, resulting in it being one 25 MHz (VGA) pixel behind. 
-- This is necessary so that due to the 2 cycle delay from the BRAM
setVGA: process(pixel_x_delayed, pixel_y_delayed, front_buff, buff0_output_reg, buff1_output_reg)
begin
   if (unsigned(pixel_x_delayed(39 downto 30)) >= 192 and unsigned(pixel_x_delayed(39 downto 30)) < 448 and
    unsigned(pixel_y_delayed(39 downto 30)) >= 112 and unsigned(pixel_y_delayed(39 downto 30)) < 368) then
        if(front_buff = '0') then -- if writing to buffer 1, read from buffer 0
            if(buff0_output_reg(1) = '1') then
                VGA_out_sg <= (others => '1');
            else 
                VGA_out_sg <= (others => '0');
            end if;
        elsif(front_buff = '1') then -- if writing to buffer 0, read from buffer 1
            if(buff1_output_reg(1) = '1') then
                VGA_out_sg <= (others => '1');
            else 
                VGA_out_sg <= (others => '0');
            end if;
        end if;
    else 
        VGA_out_sg <= (others => '0'); -- if not in center of screen, just print black
    end if;
end process;

-- computes write address 
-- address is y*256+x which can be done by shifting y left 8 times, then OR with x

write_addr <= std_logic_vector(
           (unsigned(write_y) & unsigned(write_x))
        );
        
-- process to find address to read by shifting the pixel_x and pixel_y so that they only activate when in the
-- 256x256 window in the center of the screen
raddr: process(pixel_x, pixel_y)
begin
    -- in center 256x256 window of screen
    if (unsigned(pixel_x) >= 192 and unsigned(pixel_x) < 448 and -- start reading 1 25MHz cycle early
        unsigned(pixel_y) >= 112 and unsigned(pixel_y) < 368) then
        -- offsets the read_x and read_y so that (192,112) is (0,0) address in the buffer.
        -- must then resize result to be 8 bit to match size of read_addr
        -- finally, as with write address, shifts y left by 8 (*256), then adds x
        read_addr <= std_logic_vector(
                resize(unsigned(pixel_y) - to_unsigned(112,10),8) & 
                resize(unsigned(pixel_x) - to_unsigned(192,10),8) -- +1 makes it read the 192 address at 191, will be pipelined into the ram
            ); 
    else
        read_addr <= (others => '0'); -- if not in center of screen, read_address is 0 (not using)
    end if;
end process;

-- Connects up the addresses for the BRAMs. When clearing, the back buffer should be lined to the clear_addr which simply counts from 
-- 0 to 2^16-1. When receiving, back buffer linked to the write address. The front buffer is always linked to the read address.
  addr_logic : process(front_buff, read_addr, write_addr, clearing, clear_addr)
      begin
       -- defaults
        buff0_addr <= (others => '0');
        buff1_addr <= (others => '0');

        if(front_buff = '0') then -- read 0, write to 1
            -- write address
            if(clearing = '1') then
                buff1_addr <= std_logic_vector(clear_addr);
            else -- receiving
                buff1_addr <= write_addr;
            end if;
            
            -- read address
            buff0_addr <= read_addr;
            
        elsif(front_buff = '1') then -- read 1, write to 0
            -- write address
            if(clearing = '1') then
                buff0_addr <= std_logic_vector(clear_addr);
            else
                buff0_addr <= write_addr;
            end if;
            
            -- read address
            buff1_addr <= read_addr;

        end if;
  end process;


-- detects blanking region by simply asserting signal blanking when read_x and read_y are outside of 256x256 region in center of screen
-- note: changed it to go off of VS_delayed because before it was going off VS_in, so may have swapped frames a little early.
-- I think that it doesn't really matter though because you can swap as soon as you are outside of the frame buffer without
-- experiencing tearing. It just makes sense to swap at VS low because then it is true 60 Hz

blanking <= '1' when VS_Delayed(3) = '0' else '0';

 -- enable write on start clear high, select which one to write to
 -- write_en solved the problem of having a pixel illuminated in the top left corner. This probelm stems from the fact that by default, 
 -- I set the write address to 0. This means when we go to the RECEIVE state, it would write a 1 to 0,0 right away, then go to the correct address.
 -- I believe it is solved now.
buff1_wea(0) <= '1' when ((clearing = '1' OR (write_en = '1' and receiving = '1')) and front_buff = '0')  else '0';
buff0_wea(0) <= '1' when ((clearing = '1' OR (write_en = '1' and receiving = '1')) and front_buff = '1')  else '0';


-- write_data is presented to the appropriate BRAM. It writes a 0 when clearing, else writes a 1 along the line addresses
write_data(0) <= '0' when clearing = '1' else '1';



---------------------------------------------------------------------------------------------------------------------------------------------
-- FSM for writing to back buffer
state_update : process(clk) 
begin
    if(rising_edge(clk)) then
        current_state <= next_state;
    end if;
end process;

ns_logic : process(current_state, clear_request, clear_tc, tet_drawn, blanking)
begin
    next_state <= current_state;
    case current_state is
        when IDLE =>
            if(clear_request = '1') then
                next_state <= CB;
            end if;
        when CB =>
            if(clear_tc = '1') then
                next_state <= CLEARED;
            end if;
        when CLEARED =>
            next_state <= RECEIVE;
        when RECEIVE => 
            if(tet_drawn = '1') then -- done receiving when bres_complete
                next_state <= WAITING;
            end if;
        when WAITING =>
            if(blanking = '1') then
                next_state <= SWAP;
            end if;
        when SWAP => 
            next_state <= IDLE;
        when others =>
            next_state <= IDLE;
    end case;
end process;

output_logic : process(current_state)
begin
    clearing <= '0';
    clear_fulfilled <= '0';
    receiving <= '0';
    am_waiting <= '0';
    go_swap <= '0';
    case current_state is
        when CB =>
            clearing <= '1'; -- to clearing logic (local)
        when CLEARED =>
            clear_fulfilled <= '1'; -- to bresenham_receiver
            clear_fulfilled <= '1'; -- to bresenham_receiver
        when RECEIVE =>
            receiving <= '1';
        when WAITING =>
            am_waiting <= '1';
        when SWAP =>
            go_swap <= '1';
        when others =>
            null;
    end case;
end process;



-- Tie up outputs 
-- Note takes the 4 cycle delayed video_on, HS, and VS
VGA_out <= VGA_out_sg when video_on_delayed(3) = '1' else (others => '0'); -- only display when video is on
VGA_HS <= HS_delayed(3);
VGA_VS <= VS_delayed(3);


end Behavioral;
