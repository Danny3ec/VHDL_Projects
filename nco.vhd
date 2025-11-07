-- nco.vhd
-- Simple Numerically Controlled Oscillator
-- Generates a phase accumulator whose MSB can drive an LED for easy testing.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nco is
  generic (
    PHASE_WIDTH : integer := 24  -- Number of accumulator bits (controls resolution)
  );
  port (
    clk   : in  std_logic;                       -- system clock
    rst   : in  std_logic;                       -- active-high reset
    inc   : in  unsigned(PHASE_WIDTH-1 downto 0);-- tuning word (frequency control)
    phase : out unsigned(PHASE_WIDTH-1 downto 0) -- current phase value
  );
end entity;

architecture rtl of nco is
  signal acc : unsigned(PHASE_WIDTH-1 downto 0) := (others => '0');
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        acc <= (others => '0');
      else
        acc <= acc + inc;   -- phase accumulator adds tuning word every clock
      end if;
    end if;
  end process;

  phase <= acc;
end architecture;
