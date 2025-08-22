----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/21/2025 05:41:27 PM
-- Design Name: 
-- Module Name: uart_receiver - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_receiver is
    Port ( clk : in STD_LOGIC;
           rx : in STD_LOGIC;
           data : out STD_LOGIC_VECTOR(7 downto 0);
           data_valid : out STD_LOGIC);
end uart_receiver;

architecture Behavioral of uart_receiver is



signal shift_reg    : std_logic_vector(7 downto 0) := (others => '0'); -- holds 8 bits of data
signal baud_counter : unsigned(13 downto 0) := (others => '0'); -- need 14 bits to count to 10416 (approx. ratio of clk rate to baud rate -- 100,000,000 / 9600)
signal bit_counter  : unsigned(3 downto 0) := (others => '0');  -- need 4 bits to count 0 to 8 (8 bits of data). We shift 8 bits in, and increment as we shift so need to go 1 to 8

signal baud_reset, bit_reset, shift_en : std_logic;
signal baud_en, bit_inc : std_logic;
signal tc_baud2, tc_baud, tc_bit : std_logic;
-- for double synch input
signal rx_delayed : std_logic_vector(1 downto 0);

type state is (IDLE, WAIT_TC2, RECENTER_TIMING, WAIT_TC, SHIFT2, DATA_READY, DONE, WAIT_FOR_STOP);
signal current_state, next_state : state;

begin

-- double synchronize input rx for safety
synchronizing: process(clk)
begin
    if(rising_edge(clk)) then
        rx_delayed(0) <= rx;
        rx_delnayed(1) <= rx_delayed(0);
    end if;
end process;

shift: process(clk)
begin
    if(rising_edge(clk)) then
        if(shift_en = '1') then
            shift_reg <= rx_delayed(1) & shift_reg(7 downto 1); -- assumes UART sends LSB first
        end if;
    end if;
end process;

counters: process(clk)
begin
    if(rising_edge(clk)) then   
        if(baud_reset = '1') then
            baud_counter <= (others => '0');
        elsif(baud_en = '1') then        
            baud_counter <= baud_counter + 1;
        end if;
                
        if(bit_reset = '1') then
            bit_counter <= (others => '0');
        elsif(bit_inc = '1') then
            bit_counter <= bit_counter + 1;
        end if;
    end if;
end process;

-- terminal counts
tc_baud <= '1' when baud_counter = 10416 else '0'; -- count 0 to 10416 (approx one baud period)
tc_baud2 <= '1' when baud_counter = 5207 else '0'; -- count 0 to 5207 (approxhalf of baud period)
tc_bit <= '1' when bit_counter = 7 else '0'; -- count 1 to 8

---------------------------------------------------------------------------------------------------------------------------------------------
-- FSM
state_update : process(clk) 
begin
    if(rising_edge(clk)) then
        current_state <= next_state;
    end if;
end process;

ns_logic : process(current_state, rx_delayed, tc_baud2, tc_baud, tc_bit)
begin
    next_state <= current_state;
    case current_state is
        when IDLE =>
            if(rx_delayed(1) = '0') then
                next_state <= WAIT_TC2; -- wait baud period/2 so that you are in center of data
            end if;
        when WAIT_TC2 =>
            if(tc_baud2 = '1') then
                next_state <= RECENTER_TIMING;
            end if;
        when RECENTER_TIMING =>
            next_state <= WAIT_TC;
        when WAIT_TC =>
            if(tc_baud = '1') then
                next_state <= SHIFT2;
            end if;
        when SHIFT2 =>
            if(tc_bit = '0') then
                next_state <= WAIT_TC;
            elsif(tc_bit = '1') then
                next_state <= DONE;
            end if;
        when DONE =>
            next_state <= DATA_READY;
        when DATA_READY =>
            next_state <= WAIT_FOR_STOP;
        when WAIT_FOR_STOP =>
            if(tc_baud = '1') then
                next_state <= IDLE;
            end if;
        when others =>
            next_state <= IDLE;
    end case;
end process;

output_logic : process(current_state)
begin
    baud_reset <= '0';
    bit_reset <= '0';
    baud_en <= '0';
    bit_inc <= '0';
    shift_en <= '0';
    data_valid <= '0';
    case current_state is
        when IDLE =>
            -- 
            baud_reset <= '1';
            bit_reset <= '1';
        when WAIT_TC2 =>
            baud_en <= '1';
        when RECENTER_TIMING =>
            baud_reset <= '1'; -- reset baud counter
        when WAIT_TC =>
            baud_en <= '1';
        when SHIFT2 =>
            baud_reset <= '1'; -- again reset baud counter when shifting
            shift_en <= '1';
            bit_inc <= '1';
        when WAIT_FOR_STOP =>
            baud_en <= '1';
        when DATA_READY =>
            data_valid <= '1';
            bit_reset <= '1'; -- reset bit counter
            baud_reset <= '1'; -- reset baud counter
        when others =>
            null;
    end case;
end process;

-- assign output
data <= shift_reg;

end Behavioral;
