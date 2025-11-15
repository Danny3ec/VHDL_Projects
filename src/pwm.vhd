-- pwm.vhd : 8-bit PWM, duty in 0..255
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;                 -- active-high
    duty : in  unsigned(7 downto 0);      -- 0..255
    outp : out std_logic
  );
end entity;

architecture rtl of pwm is
  signal c : unsigned(7 downto 0) := (others => '0');
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        c <= (others => '0');
      else
        c <= c + 1;
      end if;
    end if;
  end process;

  outp <= '1' when c < duty else '0';
end architecture;
