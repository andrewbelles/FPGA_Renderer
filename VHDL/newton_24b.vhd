library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.array_types.all; 

entity newton_24b is 
  port (
    clk_port   : in std_logic; 
    load_port  : in std_logic; 
    reset_port : in std_logic;
    mantissa   : in std_logic_vector(23 downto 0); 
    seed       : in std_logic_vector(23 downto 0);   -- q6.17
    root       : out std_logic_vector(23 downto 0);  -- 11.12
    set_port   : out std_logic); 
end entity newton_24b; 

architecture behavioral of newton_24b is 
----------------------- declarations -------------------------------------
-- state declarations 
  signal counter : unsigned(1 downto 0) := "00";
  signal x0      : signed(23 downto 0) := (others => '0');
  signal x1, x2  : signed(23 downto 0) := (others => '0');
  signal m       : signed(23 downto 0) := (others => '0');

-- 2 represented as a 11.12 fixed point value 
  constant two_1112 : signed(23 downto 0) := x"002000";
begin 

-- load constant values
x0 <= signed(seed);
m  <= signed(mantissa);

newtons_method: process( clk_port ) 
  variable x48bus : signed(47 downto 0) := (others => '0'); 
  variable x24bus : signed(23 downto 0) := (others => '0'); 
begin 
  x48bus := (others => '0'); 
  if rising_edge( clk_port ) then  
    if reset_port = '1' then 
      x1 <= (others => '0'); 
      x2 <= (others => '0');
    elsif counter = "10" then 
      counter <= "00"; -- go back to low one cycle after  
    elsif load_port = '1' then 
      if counter = "00" then 
        x48bus := m * x0; -- 1.22 * 6.17 -> 11.12 requires 22+17=39, 27 shifts
        x24bus := shift_right(x48bus, 22)(23 downto 0); 
        x24bus := two_1112 - x24bus; 
        x48bus := x0 * x24bus; 
        x1 <= shift_right(x48bus, 17)(23 downto 0); -- 17 + 12 -> 12 
        counter <= counter + 1; 
      elsif counter = "01" then 
        x48bus := m * x1; 
        x24bus := shift_right(x48bus, 22)(23 downto 0); 
        x24bus := two_1112 - x24bus; 
        x48bus := x1 * x24bus; 
        x2 <= shift_right(x48bus, 17)(23 downto 0); -- 17 + 12 -> 12 
        counter <= counter + 1; 
      end if; 
    end if; 
  end if; 
end process newtons_method;

--- enable set once counter goes high 
set_port <= '1' when counter = "10" else '0'; 
root <= std_logic_vector(x2);

end architecture behavioral;
