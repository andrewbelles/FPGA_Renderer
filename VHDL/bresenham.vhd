----------------------------------------------------------------------------------
-- From Prof. Stephen A. Edwards's lecture "Drawing Lines with SystemVerilog", Columbia University, Spring 2015 
-- Converted to VHDL by Ben Sheppard, only modifications were to bus widths for our project
-- Outputs pixel on rising edge at (x,y) that should be drawn to connect (x0,y0) to (x1,y2)

----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity bresenham is
Port (clk, reset        :   in std_logic;
      start             :   in std_logic;
      x0, y0, x1, y1    :   in std_logic_vector(7 downto 0);
      plot              :   out std_logic;    
      x, y              :   out std_logic_vector(7 downto 0);
      done              :   out std_logic);
end bresenham;

architecture Behavioral of bresenham is
-- signal declarations

-- know that x0, y0, ... are all positve so pad with leading 0; then cast to signed for arithmetic
--variable x0_sg : signed(11 downto 0) := signed('0' & x0);
--variable x1_sg : signed(11 downto 0) := signed('0' & x1);
---variable y0_sg : signed(11 downto 0) := signed('0' & y0);
--variable y1_sg : signed(11 downto 0) := signed('0' & y1);  

-- signals for registers
signal x_sg : signed(8 downto 0);
signal y_sg : signed(8 downto 0);

type state is (IDLE, RUN);
signal current_state, next_state : state := IDLE;

begin

process(clk)
variable dx, dy, err, e2 : signed(15 downto 0); -- made this 16 bits (definitely overkill) just to avoid any problem of ever overflowing
variable right, down     : std_logic;
variable x0_var : signed(8 downto 0);
variable x1_var : signed(8 downto 0);
variable y0_var : signed(8 downto 0);
variable y1_var : signed(8 downto 0);
begin
    if(rising_edge(clk)) then
        done <= '0';
        plot <= '0';
        if(reset = '1') then
            current_state <= IDLE;
        else
            case (current_state) is
                when IDLE =>
                    if(start = '1') then
                        x0_var := signed('0' & x0); 
                        y0_var := signed('0' & y0); 
                        x1_var := signed('0' & x1); 
                        y1_var := signed('0' & y1); 
                        
                        dx := resize(x1_var, 16) - resize(x0_var, 16);
                        if(dx >= 0) then right := '1'; else right := '0'; end if;
                        if(right /= '1') then dx := -dx; end if;
                        
                        dy := resize(y1_var, 16) - resize(y0_var, 16);
                        if(dy >= 0) then down := '1'; else down := '0'; end if;
                        if(down = '1') then dy := -dy; end if;
                        
                        err := dx + dy;
                        x_sg <= signed('0' & x0);
                        y_sg <= signed('0' & y0);
                        
                        plot <= '1';
                        current_state <= RUN;
                    end if;
                when RUN => 
                    if(x_sg = x1_var and y_sg = y1_var) then
                        done <= '1';
                        current_state <= IDLE;
                    else
                        plot <= '1';
                        e2 := err sll 1; -- shift left, preserves sign
                        if(e2 > dy) then
                            err := err + resize(dy, 16);
                            if(right = '1') then
                                x_sg <= x_sg + 1;
                            else
                                x_sg <= x_sg - 1;
                            end if;
                        end if;
                        if(e2 < dx) then
                            err := err + resize(dx, 16);
                            if(down = '1') then
                                y_sg <= y_sg + 1;
                            else
                                y_sg <= y_sg - 1;
                            end if;
                        end if;
                    end if;
                when others =>
                    current_state <= IDLE;
            end case;
        end if;
    end if;
end process;

x <= std_logic_vector(x_sg(7 downto 0));
y <= std_logic_vector(y_sg(7 downto 0));


end Behavioral;
