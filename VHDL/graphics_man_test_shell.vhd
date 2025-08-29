--------------------------------------------------------------------------------------------------------------------------------------------
-- Ben Sheppard, with help of ChatGPT for writing the test inputs to the graphics_manager
-- Tests the graphics manager by loading two different tetrahedrons and alternating between them at a rate of 0.5 times per second
-------------------------------------------------------------------------------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.array_types.all;  -- for array_4x16_t

entity graphics_test_shell is
  Port (
    clk_ext_port : in  std_logic;  -- 100 MHz FPGA clock
    red          : out std_logic_vector(3 downto 0);
    green        : out std_logic_vector(3 downto 0);
    blue         : out std_logic_vector(3 downto 0);
    HS           : out std_logic;
    VS           : out std_logic
  );
end graphics_test_shell;

architecture RTL of graphics_test_shell is

  component graphics_manager is
    Port (
      sys_clk    : in  std_logic;
      packets          : in  array_4x16_t;
      draw_new_points : in  std_logic;
      ready_to_draw   : out std_logic;
      done_drawing    : out std_logic;
      red             : out std_logic_vector(3 downto 0);
      green           : out std_logic_vector(3 downto 0);
      blue            : out std_logic_vector(3 downto 0);
      HS              : out std_logic;
      VS              : out std_logic
    );
  end component;

component system_clock_generation is
    Generic( CLK_DIVIDER_RATIO : integer := 4  );
    Port (
        --External Clock:
        input_clk_port		: in std_logic;
        --System Clock:
        system_clk_port		: out std_logic);
end component;


  -- Alternation period: number of 25 MHz ticks between updates.
  -- 12,500,000 ticks ≈ 0.5 s; we toggle frames each update => ~1 Hz alternation.
  constant TICKS_PER_FRAME : natural := 12500000;

  -- Two frames, each with 4 vertices (X high byte, Y low byte).
  type frames_t is array(natural range <>) of array_4x16_t;
  constant FRAMES : frames_t(0 to 1) := (
    0 => (x"A948", x"5648", x"80B7", x"8080"),  -- Frame A
    1 => (x"A3A2", x"C9A2", x"D35D", x"B95D")   -- Frame B
  );

  signal packets_sg          : array_4x16_t := (others => (others => '0'));
  signal new_vertices_sg    : std_logic := '0';
  signal ready_to_draw_sg   : std_logic;
  signal done_drawing_sg    : std_logic;

  signal tick_counter      : unsigned(25 downto 0) := (others => '0'); -- up to ~67M
  signal frame_idx         : std_logic := '0';
  signal clk               : std_logic;
begin

  -- Instantiate the graphics manager
  u_gm : graphics_manager
    port map (
      sys_clk    => clk, -- USING the slower 25 MHz clock.
      packets          => packets_sg,
      draw_new_points => new_vertices_sg,
      ready_to_draw   => ready_to_draw_sg,
      done_drawing    => done_drawing_sg,
      red             => red,
      green           => green,
      blue            => blue,
      HS              => HS,
      VS              => VS
    );


clock : system_clock_generation
Port Map(input_clk_port => clk_ext_port,
         system_clk_port => clk);
         
  -- Frame alternator and one-clock pulse generator
  process(clk)
  begin
    if rising_edge(clk) then
      -- Default: no pulse
      new_vertices_sg <= '0';

      if tick_counter = to_unsigned(TICKS_PER_FRAME-1, tick_counter'length) then
        tick_counter <= (others => '0');

        -- Only issue new vertices when framebuffer is ready
        if ready_to_draw_sg = '1' then
          if frame_idx = '0' then
            packets_sg <= FRAMES(0);
            frame_idx <= '1';
          else
            packets_sg <= FRAMES(1);
            frame_idx <= '0';
          end if;

          -- One-cycle strobe to load new vertices
          new_vertices_sg <= '1';  -- pulses for exactly this clk
        end if;

      else
        tick_counter <= tick_counter + 1;
      end if;
    end if;
  end process;

end RTL;