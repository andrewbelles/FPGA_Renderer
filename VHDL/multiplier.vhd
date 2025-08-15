library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 

entity multiplier_16b16 is 
port (
  clk         : in std_logic;
  load        : in std_logic;  
  A, B        : in std_logic_vector(15 downto 0);
  A_dec_count : in std_logic_vector(3 downto 0);
  B_dec_count : in std_logic_vector(3 downto 0); 
  AB          : out std_logic_vector(15 downto 0));
end multiplier_16b16; 

architecture behavioral of multiplier_16b16 is 
  signal shift_count   : unsigned(4 downto 0) := (others => '0'); 
  signal S, uint32_A : unsigned(31 downto 0) := (others => '0');    
  signal uint16_B      : unsigned(15 downto 0) := (others => '0');
  signal negative_flag : std_logic := '0';

begin 
-- 
-- synchronous 
--
load_magnitudes: process( clk, load )
begin 
  if rising_edge( clk ) then 
    -- enable
    if load = '1' then 
      -- get magnitude of A into 32 bits (16 low)
      uint32_A <= (others => '0') & unsigned(abs(signed(A))); 
      -- get magnitude of B (no extend)
      uint16_B <= unsigned(abs(signed(B)));
    end if; 
  end if;
end process load_magnitudes;

-- main accumulator of product, 
accumulator: process( uint32_A, uint16_B, shift_count ) is 
  variable partial_sum : unsigned(31 downto 0) := (others => '0'); 
begin 
  partial_sum := (others => '0'); 
  for i in 0 to 15 loop 
    if uint16_B(i) = '1' then
      partial_sum := partial_sum + uint32_A; 
    end if;
    
    -- left shift for A, right shift for B 
    uint32_A <= uint32_A(30 downto 0) & '0';
    uint16_B <= '0' & uint16_B(15 downto 1); 
  end loop; 
  -- shift by decimal count 
  S <= shift_right(partial_sum, to_integer(shift_count) );
end process accumulator; 

--
-- async 
--
negative_flag <= '1' when A(15) XOR B(15) else '0';  

get_shift_count: process( A_dec_count, B_dec_count )
begin 
  if (unsigned(A_dec_count) + unsigned(B_dec_count)) < 8 then
    shift_count <= (others => '0');
  else 
    shift_count <= (unsigned(A_dec_count) + unsigned(B_dec_count)) - 8;
  end if;
end process get_shift_count;

set_product: process( S, negative_flag )
begin 
  AB <= std_logic_vector(S(15 downto 0)); -- low 16 bits is output 
  if negative_flag = '1' then 
    -- value -> signed -> 2's complement -> std_logic_vector
    AB <= std_logic_vector(-(signed(S(15 downto 0))));  
  end if; 
end process set_product;

end behavioral;  
