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
          write_x, write_y    :   in std_logic_vector(7 downto 0); -- address to write
          
          -- Needs to have a data in line?
          
          
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

signal write_data : std_logic_vector(0 downto 0) := (others => '1'); -- data to write.

-- buffer outputs
signal buff0_output : std_logic_vector(0 downto 0);
signal buff1_output : std_logic_vector(0 downto 0);

-- VGA output value is 12 bits, for now just doing all 0s or 1s
signal VGA_out_sg : std_logic_vector(11 downto 0) := (others => '0');

-- signals to hold delayed value of video_on, etc (because read introduces a 1 cycle delay)
signal video_on_delayed : std_logic_vector(1 downto 0);
signal HS_delayed       : std_logic_vector(1 downto 0);
signal VS_delayed       : std_logic_vector(1 downto 0);

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
  
  -- glue logic to set which BRAM gets the write address and which gets the read address
  addr_logic : process(buffer_write_sel, write_addr, read_addr)
      begin
      if(buffer_write_sel = '0') then
        buff0_addr <= write_addr;
        buff1_addr <= read_addr;
      elsif(buffer_write_sel = '1') then
        buff0_addr <= read_addr;
        buff1_addr <= write_addr;
      end if;
  end process;
  
  -- glue logic to set which BRAM has its write enable asserted
wea_logic : process(buffer_write_sel, write_en)
begin
    -- default: disable both
    buff0_wea(0) <= '0';
    buff1_wea(0) <= '0';

    -- enable write to the selected buffer only if write_en is high
    if (write_en = '1') then
        if (buffer_write_sel = '0') then
            buff0_wea(0) <= '1';
        elsif(buffer_write_sel = '1') then
            buff1_wea(0) <= '1';
        end if;
    end if;
end process;


-- process sets VGA_out_sg by setting it to all 1s or all 0s
-- chooses correct BRAM based on buffer_write_sel
-- uses that BRAM's output port as its data
-- FOR NOW: Just doing black or white (all 0s or all 1s). May add functionality in future 

process(read_x, read_y, buffer_write_sel, buff0_output, buff1_output)
begin
   if (unsigned(read_x) >= 192 and unsigned(read_x) < 448 and
    unsigned(read_y) >= 112 and unsigned(read_y) < 368) then
        if(buffer_write_sel = '1') then -- if writing to buffer 1, read from buffer 0
            if(buff0_output(0) = '1') then
                VGA_out_sg <= (others => '1');
            else 
                VGA_out_sg <= (others => '0');
            end if;
        elsif(buffer_write_sel = '0') then -- if writing to buffer 0, read from buffer 1
            if(buff1_output(0) = '1') then
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
        video_on_delayed(0) <= video_on; -- cycle t
        video_on_delayed(1) <= video_on_delayed(0); -- cycle t+1
        HS_delayed(0) <= HS_in;
        HS_delayed(1) <= HS_delayed(0);
        VS_delayed(0) <= VS_in;
        VS_delayed(1) <= VS_delayed(0);
    end if;
end process;

-- asynchronously computes write address 
-- address is y*256+x which can be done by shifting y left 8 times, or with x

write_addr <= std_logic_vector(
           (unsigned(write_y) & unsigned(write_x))
        );
        
-- process to find address to read
raddr: process(read_x, read_y)
begin
    -- in center 256x256 window of screen
    if (unsigned(read_x) >= 192 and unsigned(read_x) < 448 and
        unsigned(read_y) >= 112 and unsigned(read_y) < 368) then

        -- offsets the read_x and read_y so that (192,112) is (0,0) address in the buffer.
        -- must then resize result to be 8 bit to match size of read_addr
        -- finally, as with write address, shifts y left by 8 (*256), then adds x
        read_addr <= std_logic_vector(
                resize(unsigned(read_y) - to_unsigned(112,10),8) & 
                resize(unsigned(read_x) - to_unsigned(192,10),8)
            ); 

    else
        read_addr <= (others => '0'); -- if not in center of screen, don't care because not reading at all
    end if;
end process;

-- takes signal from MSB of shift register (2 cycle delay)
VGA_out <= VGA_out_sg when video_on_delayed(1) = '1' else (others => '0'); -- only display when video is on
VGA_HS <= HS_delayed(1);
VGA_VS <= VS_delayed(1);


end Behavioral;
