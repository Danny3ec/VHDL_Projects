-- sine_lut.vhd : 64-entry sine table, 8-bit unsigned 0..255
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sine_lut is
  port (
    addr : in  unsigned(5 downto 0);      -- 0..63
    dout : out unsigned(7 downto 0)       -- 0..255
  );
end entity;

architecture rtl of sine_lut is
  type lut_t is array (0 to 63) of unsigned(7 downto 0);
  constant T : lut_t := (
    -- round((sin(2*pi*n/64)*0.5+0.5)*255)
    to_unsigned(128,8), to_unsigned(140,8), to_unsigned(153,8), to_unsigned(165,8),
    to_unsigned(177,8), to_unsigned(188,8), to_unsigned(199,8), to_unsigned(209,8),
    to_unsigned(218,8), to_unsigned(226,8), to_unsigned(233,8), to_unsigned(238,8),
    to_unsigned(242,8), to_unsigned(245,8), to_unsigned(247,8), to_unsigned(248,8),
    to_unsigned(248,8), to_unsigned(247,8), to_unsigned(245,8), to_unsigned(242,8),
    to_unsigned(238,8), to_unsigned(233,8), to_unsigned(226,8), to_unsigned(218,8),
    to_unsigned(209,8), to_unsigned(199,8), to_unsigned(188,8), to_unsigned(177,8),
    to_unsigned(165,8), to_unsigned(153,8), to_unsigned(140,8), to_unsigned(128,8),
    to_unsigned(116,8), to_unsigned(103,8), to_unsigned( 91,8), to_unsigned( 79,8),
    to_unsigned( 68,8), to_unsigned( 57,8), to_unsigned( 47,8), to_unsigned( 38,8),
    to_unsigned( 30,8), to_unsigned( 23,8), to_unsigned( 18,8), to_unsigned( 14,8),
    to_unsigned( 11,8), to_unsigned(  9,8), to_unsigned(  8,8), to_unsigned(  8,8),
    to_unsigned(  8,8), to_unsigned(  9,8), to_unsigned( 11,8), to_unsigned( 14,8),
    to_unsigned( 18,8), to_unsigned( 23,8), to_unsigned( 30,8), to_unsigned( 38,8),
    to_unsigned( 47,8), to_unsigned( 57,8), to_unsigned( 68,8), to_unsigned( 79,8),
    to_unsigned( 91,8), to_unsigned(103,8), to_unsigned(116,8), to_unsigned(128,8)
  );
begin
  dout <= T(to_integer(addr));
end architecture;
