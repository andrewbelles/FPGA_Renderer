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
  constant two_1112 : signed(23 downto 0) := x"002000";
begin 

-- load constant values
x0 <= signed(seed);
m  <= signed(mantissa);

newtons_method: process( clk_port ) 
  variable x48bus : signed(47 downto 0) := (others => '0'); 
begin 
  x48bus := (others => '0'); 
  if rising_edge( clk_port ) then  
    if reset_port = '1' then 
      x1 <= (others => '0'); 
      x2 <= (others => '0');
    elsif iter = 2 then 
      iter <= "00"; -- go back to low one cycle after  
    elsif load_port = '1' then 
      if iter = "00" then 
        x48bus := resize(m, 48) * resize(x0, 48); 
        x48bus := shift_right(x48bus, 17); 
        x48bus := resize(two_1112, 48) - x48bus; 
        x48bus := resize(x0, 48) * x48bus; 
        x1 <= shift_right(x48bus, 17);     -- 17 + 12 -> 12 
        iter <= iter + 1; 
      elsif iter = "01" then 
        x48bus := resize(m, 48) * resize(x1, 48);
        x48bus := shift_right(x48bus, 12); 
        x48bus := resize(two_1112, 48) - x48bus; 
        x48bus := resize(x1, 48) * x48bus; 
        x2 <= shift_right(x48bus, 12);     -- 17 + 12 -> 12 
        iter <= iter + 1; 
      end if; 
    end if; 
  end if; 
end process newtons_method;

--- enable set once iter goes high 
set_port <= '1' when iter = "10" else '0'; 
root <= std_logic_vector(x2);

end architecture behavioral;
