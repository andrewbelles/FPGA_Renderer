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
  signal iter   : unsigned(1 downto 0) := "00";
  signal x0     : signed(23 downto 0) := (others => '0');
  signal x1, x2 : signed(23 downto 0) := (others => '0');
  signal m      : signed(23 downto 0) := (others => '0');

-- 2 represented as a 11.12 fixed point value 
  constant two_1112    : signed(23 downto 0) := x"002000";
begin 

-- load constant values
x0 <= signed(seed);
m  <= signed(mantissa);

newtons_method: process( clk_port ) 
begin 
  if rising_edge( clk_port ) then  
    if reset_port = '1' then 
      x1 <= (others => '0'); 
      x2 <= (others => '0');
    elsif iter = 2 then 
      iter <= "00"; -- go back to low one cycle after  
    elsif load_port = '1' then 
      if iter = 0 then 
        x1 <= x0 * (two_1112 - (m * x0)); 
        iter <= iter + 1; 
      else 
        x2 <= x1 * (two_1112 - (m * x1));
        iter <= iter + 1; 
      end if; 
    end if; 
  end if; 
end process newtons_method;

--- enable set once iter goes high 
set_port <= '1' when iter = 2 else '0'; 
root <= std_logic_vector(iter);

end architecture behavioral;
