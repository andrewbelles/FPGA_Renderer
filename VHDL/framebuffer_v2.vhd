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
          clear_request          :   in std_logic; -- tells framebuffer to clear back 
          tet_drawn       :   in std_logic; -- tells framebuffer bres is complete
          write_x, write_y    :   in std_logic_vector(7 downto 0); -- address to write
          
          -- Needs to have a data in line
          write_en            :   in std_logic;
          pixel_x, pixel_y      :   in std_logic_vector(9 downto 0); -- address to read
          video_on            :   in std_logic;
          -- note takes in HS and VS unlike the VGA setup because need to slow them down by 1 clock cycle due to reading BRAM
          HS_in               :   in std_logic;
          VS_in               :   in std_logic;
        
          clear_fulfilled        :   out std_logic; -- tells manager back is cleared
          VGA_HS              :   out std_logic;
          VGA_VS              :   out std_logic;
          VGA_out             :   out std_logic_vector(11 downto 0) -- framebuffer data, 8 bit for an 8 bit color
           );
end framebuffer;

architecture Behavioral of framebuffer is
-- BRAM component, width 1, depth 65536
COMPONENT blk_mem_gen_0
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END COMPONENT;

-- addresses that we compute
signal write_addr : std_logic_vector(15 downto 0) := (others => '0'); 
signal read_addr  : std_logic_vector(15 downto 0) := (others => '0');

-- signals that are tied to BRAM
signal buff0_addr : std_logic_vector(15 downto 0);
signal buff1_addr : std_logic_vector(15 downto 0);
signal buff0_wea  : std_logic_vector(0 downto 0);
signal buff1_wea  : std_logic_vector(0 downto 0);

signal write_data : std_logic_vector(0 downto 0) := (others => '0'); -- data to write.


-- buffer select
signal front_buff : std_logic := '0'; -- says which buffer is currently drawing to screen
-- buffer outputs
signal buff0_output : std_logic_vector(0 downto 0);
signal buff1_output : std_logic_vector(0 downto 0);

-- VGA output value is 12 bits, for now just doing all 0s or 1s
signal VGA_out_sg : std_logic_vector(11 downto 0) := (others => '0');
signal VGA_out_en : std_logic_vector(1 downto 0) := (others => '0');

-- signals to hold delayed value of video_on, etc (because read introduces a 1 cycle delay)


signal video_on_delayed : std_logic_vector(3 downto 0);
signal HS_delayed       : std_logic_vector(3 downto 0);
signal VS_delayed       : std_logic_vector(3 downto 0);

signal read_addr_delayed : std_logic_vector(15 downto 0) := (others => '0');
signal clear_addr    : unsigned(15 downto 0) := (others => '0');

-- fsm signals
type state is (IDLE, CB, CLEARED, RECEIVE, WAITING, SWAP);
signal current_state, next_state : state := IDLE;

signal clear_tc : std_logic; -- from logic to fsm to say that the local clear of back is at addr 2^16-1 (it is finished)
signal blanking : std_logic; -- from logic to fsm to say that we are in a blanking region

signal start_clear : std_logic; -- from fsm to clearing logic says to start clearing memory
signal receiving : std_logic; -- -- from fsm to logic to say that we are receiving and writing to memory
signal am_waiting   : std_logic; -- from fsm to logic to say that we are waiting for blanking region
signal go_swap         : std_logic; -- from fsm to logic to say to swap which one is drawing to vga

signal buff0_output_reg : std_logic_vector(0 downto 0);
signal buff1_output_reg : std_logic_vector(0 downto 0);

signal pixel_x_delayed : std_logic_vector(39 downto 0);
signal pixel_y_delayed : std_logic_vector(39 downto 0);

-- debug

begin
buff0 : blk_mem_gen_0
  PORT MAP (
    clka => clk,
    ena => '1', -- tie enable to 1
    wea => buff0_wea,
    addra => buff0_addr,
    dina => write_data,
    douta => buff0_output
  );
  
  buff1 : blk_mem_gen_0
  PORT MAP (
    clka => clk,
    ena => '1', -- tie enable to 1
    wea => buff1_wea,
    addra => buff1_addr,
    dina => write_data,
    douta => buff1_output
  );
  


-- process sets VGA_out_sg by setting it to all 1s or all 0s
-- chooses correct BRAM based on buffer_write_sel
-- uses that BRAM's output port as its data
-- FOR NOW: Just doing black or white (all 0s or all 1s). May add functionality in future 

process(pixel_x_delayed, pixel_y_delayed, front_buff, buff0_output_reg, buff1_output_reg)
begin
   if (unsigned(pixel_x_delayed(39 downto 30)) >= 192 and unsigned(pixel_x_delayed(39 downto 30)) < 448 and
    unsigned(pixel_y_delayed(39 downto 30)) >= 112 and unsigned(pixel_y_delayed(39 downto 30)) < 368) then
        if(front_buff = '0') then -- if writing to buffer 1, read from buffer 0
            if(buff0_output_reg(0) = '1') then
                VGA_out_sg <= (others => '1');
            else 
                VGA_out_sg <= (others => '0');
            end if;
        elsif(front_buff = '1') then -- if writing to buffer 0, read from buffer 1
            if(buff1_output_reg(0) = '1') then
                VGA_out_sg <= (others => '1');
            else 
                VGA_out_sg <= (others => '0');
            end if;
        end if;
    else 
        VGA_out_sg <= (others => '0'); -- if not in center of screen, just print black
    end if;
end process;
  

-- slows down video on and HS by two clock cycle so that it is in sync with buffer_out (BRAM takes 2 cycle to read)
-- uses shift register to do this
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
        
        -- add register at output of BRAM
        buff0_output_reg(0) <= buff0_output(0);
        buff1_output_reg(0) <= buff1_output(0);
        
        -- delay address by 1 clock cycle to bring address change onto edge of pixel change
        read_addr_delayed <= read_addr;
        
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



-- Clear entire memory by looping over it and setting to 0. Takes in signal from fsm called start_clear
clrmem : process(clk)
begin
    if(rising_edge(clk)) then
        if(start_clear = '1') then
            if(clear_tc = '0') then
                clear_addr <= clear_addr + 1;
            else
                clear_addr <= (others => '0');
            end if;
        end if;
    end if;
end process;

clear_tc <= '1' when clear_addr = 65535 else '0';


 -- enable write on start clear high, select which one to write to
buff1_wea(0) <= '1' when ((start_clear = '1' OR receiving = '1') and front_buff = '0')  else '0';
buff0_wea(0) <= '1' when ((start_clear = '1' OR receiving = '1') and front_buff = '1')  else '0';




-- NEED ASYNCHRONOUS LOGIC TO LINK UP THE CORRECT ADDRESS
-- when start_clear = 1, need to have address linked to clear_counter
-- write a 1 to memory @ write_x and write_y

-- asynchronously computes write address 
-- address is y*256+x which can be done by shifting y left 8 times, or with x

write_addr <= std_logic_vector(
           (unsigned(write_y) & unsigned(write_x))
        );
        
-- process to find address to read
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
        read_addr <= (others => '0'); -- if not in center of screen, don't care because not reading at all
    end if;
end process;

-- connects up the addresses for the BRAMs
  addr_logic : process(front_buff, read_addr_delayed, write_addr, start_clear, clear_addr)
      begin
       -- safe defaults
        buff0_addr <= (others => '0');
        buff1_addr <= (others => '0');

        if(front_buff = '0') then -- read 0, write to 1
            -- write address
            if(start_clear = '1') then
                buff1_addr <= std_logic_vector(clear_addr);
            else -- receivigng?
                buff1_addr <= write_addr;
            end if;
            
            -- read addres
            buff0_addr <= read_addr_delayed; -- delayed by 1 100MHz cycle
        elsif(front_buff = '1') then -- read 1, write to 0
            -- write address
            if(start_clear = '1') then
                buff0_addr <= std_logic_vector(clear_addr);
            else
                buff0_addr <= write_addr;
            end if;
            
            -- read address
            buff1_addr <= read_addr_delayed;

        end if;
  end process;


-- swap

swapproc : process(clk)
begin
    if(rising_edge(clk)) then
        if(go_swap = '1') then
            front_buff <= NOT front_buff;
        end if;
    end if;
end process;

-- detects blanking region by simply asserting signal blanking when read_x and read_y are outside of 256x256 region in center of screen
blanking <= '1' when VS_in = '0' else '0';


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
    start_clear <= '0';
    clear_fulfilled <= '0';
    receiving <= '0';
    am_waiting <= '0';
    go_swap <= '0';
    case current_state is
        when CB =>
            start_clear <= '1'; -- to clearing logic (local)
        when CLEARED =>
            clear_fulfilled <= '1'; -- to graphics manager
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


-- takes signal from MSB of shift register (4 cycle delay)
VGA_out <= VGA_out_sg when video_on_delayed(3) = '1' else (others => '0'); -- only display when video is on
VGA_HS <= HS_delayed(3);
VGA_VS <= VS_delayed(3);


write_data(0) <= '0' when start_clear = '1' else '1';


end Behavioral;
