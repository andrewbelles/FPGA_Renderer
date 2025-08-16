library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;; 

entity sine_lut is 
  port (
    clk_port   : in std_logic; 
    addr       : in std_logic_vector(15 downto 0); 
    sine_out   : out std_logic_vector(15 downto 0)); -- 2.14 fixed point 
end entity sine_lut; 

architecture behavioral of sine_lut is 
  -- 256 entries of 16 bit , 14 dec precision signed fixed point sine values 
  type rom_256x16_t is array (0 to 255) of std_logic_vector(15 downto 0);

  -- generate table from regfile decleration 
  constant table : rom_256x16_t := (
    x"0000", x"0065", x"00C9", x"012E",
    x"0065", x"00C9", x"012E", x"0192",
    x"00C9", x"012E", x"0192", x"01F7",
    x"012E", x"0192", x"01F7", x"025B",
    x"0192", x"01F7", x"025B", x"02C0",
    x"01F7", x"025B", x"02C0", x"0324",
    x"025B", x"02C0", x"0324", x"0388",
    x"02C0", x"0324", x"0388", x"03ED",
    x"0324", x"0388", x"03ED", x"0451",
    x"0388", x"03ED", x"0451", x"04B5",
    x"03ED", x"0451", x"04B5", x"051A",
    x"0451", x"04B5", x"051A", x"057E",
    x"04B5", x"051A", x"057E", x"05E2",
    x"051A", x"057E", x"05E2", x"0646",
    x"057E", x"05E2", x"0646", x"06AA",
    x"05E2", x"0646", x"06AA", x"070E",
    x"0646", x"06AA", x"070E", x"0772",
    x"06AA", x"070E", x"0772", x"07D6",
    x"070E", x"0772", x"07D6", x"0839",
    x"0772", x"07D6", x"0839", x"089D",
    x"07D6", x"0839", x"089D", x"0901",
    x"0839", x"089D", x"0901", x"0964",
    x"089D", x"0901", x"0964", x"09C7",
    x"0901", x"0964", x"09C7", x"0A2B",
    x"0964", x"09C7", x"0A2B", x"0A8E",
    x"09C7", x"0A2B", x"0A8E", x"0AF1",
    x"0A2B", x"0A8E", x"0AF1", x"0B54",
    x"0A8E", x"0AF1", x"0B54", x"0BB7",
    x"0AF1", x"0B54", x"0BB7", x"0C1A",
    x"0B54", x"0BB7", x"0C1A", x"0C7C",
    x"0BB7", x"0C1A", x"0C7C", x"0CDF",
    x"0C1A", x"0C7C", x"0CDF", x"0D41",
    x"0C7C", x"0CDF", x"0D41", x"0DA4",
    x"0CDF", x"0D41", x"0DA4", x"0E06",
    x"0D41", x"0DA4", x"0E06", x"0E68",
    x"0DA4", x"0E06", x"0E68", x"0ECA",
    x"0E06", x"0E68", x"0ECA", x"0F2B",
    x"0E68", x"0ECA", x"0F2B", x"0F8D",
    x"0ECA", x"0F2B", x"0F8D", x"0FEE",
    x"0F2B", x"0F8D", x"0FEE", x"1050",
    x"0F8D", x"0FEE", x"1050", x"10B1",
    x"0FEE", x"1050", x"10B1", x"1112",
    x"1050", x"10B1", x"1112", x"1173",
    x"10B1", x"1112", x"1173", x"11D3",
    x"1112", x"1173", x"11D3", x"1234",
    x"1173", x"11D3", x"1234", x"1294",
    x"11D3", x"1234", x"1294", x"12F4",
    x"1234", x"1294", x"12F4", x"1354",
    x"1294", x"12F4", x"1354", x"13B4",
    x"12F4", x"1354", x"13B4", x"1413",
    x"1354", x"13B4", x"1413", x"1473",
    x"13B4", x"1413", x"1473", x"14D2",
    x"1413", x"1473", x"14D2", x"1531",
    x"1473", x"14D2", x"1531", x"1590",
    x"14D2", x"1531", x"1590", x"15EE",
    x"1531", x"1590", x"15EE", x"164C",
    x"1590", x"15EE", x"164C", x"16AB",
    x"15EE", x"164C", x"16AB", x"1709",
    x"164C", x"16AB", x"1709", x"1766",
    x"16AB", x"1709", x"1766", x"17C4",
    x"1709", x"1766", x"17C4", x"1821",
    x"1766", x"17C4", x"1821", x"187E",
    x"17C4", x"1821", x"187E", x"18DB",
    x"1821", x"187E", x"18DB", x"1937"); 
begin 

sine_out <= table(addr);

end architecture behavioral; 
