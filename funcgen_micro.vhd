-- funcgen_micro.vhd  (manual speed select via SW0)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity funcgen_micro is
  port (
    clk     : in  std_logic;   -- 50 MHz CLOCK_50
    rst_n   : in  std_logic;   -- KEY0 (active-low)
    sw0     : in  std_logic;   -- SW0 (slide switch)
    pwm_out : out std_logic    -- LEDR0
  );
end entity;

architecture rtl of funcgen_micro is
  signal counter : unsigned(23 downto 0) := (others => '0');
  signal pwm     : std_logic := '0';
begin
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      counter <= (others => '0');
    elsif rising_edge(clk) then
      counter <= counter + 1;
    end if;
  end process;

  -- If SW0=1 -> slow blink from bit 23
  -- If SW0=0 -> faster blink from bit 18
  pwm <= counter(23) when sw0 = '1' else counter(18);

  pwm_out <= pwm;
end architecture;

