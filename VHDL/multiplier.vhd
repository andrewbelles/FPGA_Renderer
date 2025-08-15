library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 

entity multiplier_16b16 is 
port (
  clk_port          : in std_logic;
  load_port         : in std_logic;  
  A, B         : in std_logic_vector(15 downto 0);
  A_dec_count  : in std_logic_vector(3 downto 0);
  B_dec_count  : in std_logic_vector(3 downto 0); 
  AB           : out std_logic_vector(15 downto 0);
  AB_dec_count : out std_logic_vector(3 downto 0)); 
end multiplier_16b16; 

architecture behavioral of multiplier_16b16 is 
  signal shift_count   : unsigned(4 downto 0) := (others => '0'); 
  signal S, uint32_A : unsigned(31 downto 0) := (others => '0');    
  signal uint16_B      : unsigned(15 downto 0) := (others => '0');
  signal negative_flag : std_logic := '0';

begin 
--------------- 
-- synchronous 
---------------

-- loads the values into registers as the magnitude of inputs 
load_magnitudes: process( clk_port, load_port )
begin 
  if rising_edge( clk_port ) then 
    -- enable
    if load_port = '1' then 
      -- get 2's complement of input values if negative 
      -- store in flip flop
      if (A(15) = '1') then 
        uint32_A <= (others => '0') & unsigned(not(A)) + 1; 
      else 
        uint32_A <= (others => '0') & unsigned(A);
      end if; 

      if (B(15) = '1') then 
        uint16_B <= unsigned(not(A)) + 1; 
      else 
        uint16_B <= unsigned(A);
      end if; 

    end if; 
  end if;
end process load_magnitudes;

load_auxilliary: process( clk_port, load_port )
begin 
  if rising_edge( clk_port) then 
    if load_port = '1' then 
      negative_flag <= '1' when A(15) XOR B(15) else '0';  

      -- if number of decimals is less than 8 then we shouldn't shift
      if (('0' & unsigned(A_dec_count)) + ('0' & unsigned(B_dec_count))) < 8 then
        shift_count <= (others => '0');
      else 
        shift_count <= (('0' & unsigned(A_dec_count)) + ('0' & unsigned(B_dec_count))) - 8;
      end if;
    end if; 
  end if; 
end process load_auxilliary;

----------
-- async
----------

-- main accumulator of product, 
accumulator: process( uint32_A, uint16_B, shift_count ) is 
  variable luint_A : unsigned(31 downto 0) := (others => '0');
  variable luint_B : unsigned(15 downto 0) := (others => '0'); 
  variable partial_sum : unsigned(31 downto 0) := (others => '0'); 
begin 
  luint_A := uint32_A;
  luint_B := uint16_B; 
  partial_sum := (others => '0'); 
  for i in 0 to 15 loop 
    if luint_B(i) = '1' then
      partial_sum := partial_sum + luint_A; 
    end if;
    
    -- left shift for A, right shift for B 
    luint_A := luint_A(30 downto 0) & '0';
  end loop; 
  -- shift by decimal count 
  S <= shift_right(partial_sum, to_integer(shift_count));
end process accumulator; 

set_product: process( S, negative_flag )
begin 
  AB <= std_logic_vector(S(15 downto 0)); -- low 16 bits is output 
  if negative_flag = '1' then 
    -- value -> signed -> 2's complement -> std_logic_vector
    AB <= std_logic_vector(-(signed(S(15 downto 0))));  
  end if; 
end process set_product;

-- 5 bits - value 8 guarentees value is 4 bits or less 
AB_dec_count <= std_logic_vector((shift_count - 8));

end behavioral;  
