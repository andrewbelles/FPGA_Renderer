library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 

entity multiplier_16x16 is 
port (
  clk_port   : in std_logic;
  load_port  : in std_logic;  
  reset_port : in std_logic; 
  A, B       : in std_logic_vector(15 downto 0);
  A_dig      : in std_logic_vector(3 downto 0);
  B_dig      : in std_logic_vector(3 downto 0); 
  AB         : out std_logic_vector(15 downto 0);
  AB_dig     : out std_logic_vector(3 downto 0);
  set_port   : out std_logic); 
end multiplier_16x16; 

architecture behavioral of multiplier_16x16 is 
  -- type declarations 
  type accumul_array is array (0 to 3) of unsigned(31 downto 0); 
  type shift_array is array (0 to 15) of unsigned(31 downto 0);
  type state_type is ( idle, first, second, third, done );

  -- for accumulator
  -- structure signals 
  signal partials      : accumul_array := (others => (others => '0')); 
  signal mag32_shifts  : shift_array := (others => (others => '0'));

  -- base type signals 
  signal shift_count   : unsigned(4 downto 0) := (others => '0'); 
  signal A_mag32    : unsigned(31 downto 0) := (others => '0');    
  signal B_mag16       : unsigned(15 downto 0) := (others => '0');
  signal negative_flag, reset : std_logic := '0';
  -- for fsm 
  signal current_state, next_state : state_type := idle; 
begin 
-------- 
-- FSM 
--------
update_state: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    current_state <= next_state;
  end if; 
end process update_state; 

next_state_logic: process( current_state, load_port, reset_port ) 
begin
  if reset_port = '1' then
    next_state <= idle; 
  else 
    case (current_state) is 
      when idle =>
        next_state <= idle; 
        if load_port = '1' then 
          next_state <= first; 
        end if; 
      when first =>
        next_state <= second; 
      when second =>  
        next_state <= third; 
      when third => 
        next_state <= done; 
      when done => 
        -- stay static in done state, must assert reset to return
        next_state <= done;     
    end case; 
  end if;
end process next_state_logic; 

output_logic: process ( current_state, partials, negative_flag, shift_count )
  variable S : unsigned(31 downto 0) := (others => '0');
begin
  reset <= '0';
  set_port <= '0';
  case ( current_state) is 
    when idle => 
      reset <= '1'; 
    when done => 
      set_port <= '1';
      S := partials(0);
      if negative_flag = '0' then 
        AB <= std_logic_vector( signed(S(15 downto 0)) );
      else 
        AB <= std_logic_vector(-signed(S(15 downto 0)) );
      end if; 
      -- 5 bits - value 8 guarentees value is 4 bits or less 
      AB_dig <= std_logic_vector((shift_count(3 downto 0)));
    when others => 
      null;
  end case; 
end process output_logic; 

--------------- 
-- synchronous 
---------------
load_magnitudes: process( clk_port )
begin 
  if rising_edge( clk_port ) then 
    if reset = '1' then 

      A_mag32 <= (others => '0'); 
      B_mag16 <= (others => '0');
      partials <= (others => (others => '0'));
      mag32_shifts <= (others => (others => '0'));
      AB <= (others => '0');

    elsif load_port = '1' then 
      -- get 2's complement of input values if negative 
      -- store in flip flop
      if (A(15) = '1') then 
        A_mag32 <= x"0000" & unsigned(not(A)) + 1; 
      else 
        A_mag32 <= x"0000" & unsigned(A);
      end if; 

      if (B(15) = '1') then 
        B_mag16 <= unsigned(not(B)) + 1; 
      else 
        B_mag16 <= unsigned(B);
      end if; 

    end if; 
  end if;
end process load_magnitudes;

load_auxilliary: process( clk_port )
begin 
  if rising_edge( clk_port) then 
    if reset = '1' then 
      negative_flag <= '0'; 
      shift_count <= (others => '0');

    elsif load_port = '1' then 
      if (A(15) xor B(15)) = '1' then 
        negative_flag <= '1';
      else 
        negative_flag <= '0';
      end if;  

      -- if number of decimals is less than 8 then we shouldn't shift
      if (('0' & unsigned(A_dig)) + ('0' & unsigned(B_dig))) < 8 then
        shift_count <= (others => '0');
      else 
        shift_count <= (('0' & unsigned(A_dig)) +
                        ('0' & unsigned(B_dig))) - 8;
      end if;
    end if; 
  end if; 
end process load_auxilliary;

-- pipelines the sum across 3 cycles 
-- sum is stored in 0th of partials array
pipeline_sum: process( clk_port )
  variable partial_sum : unsigned(31 downto 0) := (others => '0');   
  variable to_shift : integer := 0; 
begin 
  if rising_edge( clk_port ) then
    case current_state is 
      -- get four partial sums 
      when first => 
        for i in 0 to 3 loop 
          partial_sum := (others => '0');
          to_shift := to_integer( shift_left(to_unsigned(i, 4), 2) );
          for j in 0 to 3 loop 
            if B_mag16(j + to_shift) = '1' then
              partial_sum := partial_sum + mag32_shifts(j + to_shift);
            end if; 
          end loop; 
          partials(i) <= partial_sum;
        end loop; 
      -- accumulate down to 2
      when second => 
          partials(0) <= partials(0) + partials(1);
          partials(2) <= partials(2) + partials(3);
      -- final sum 
      when third => 
        partials(0) <= partials(0) + partials(2);
      when others => 
        null;
      end case; 
  end if;
end process pipeline_sum;

----------
-- async
----------

-- we need to compute four separate partial sums and pipeline to avoid giant 
-- critical path. 
set_shifts : process ( A_mag32 ) is
begin
  for i in 0 to 15 loop
    mag32_shifts(i) <= shift_left(A_mag32, i); 
  end loop;
end process;

end behavioral;  
