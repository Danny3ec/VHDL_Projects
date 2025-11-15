library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top is
end entity;

architecture sim of tb_top is
    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';
    signal sw      : std_logic_vector(3 downto 0) := "0000";
    signal pwm_out : std_logic;
    signal ledr1   : std_logic;
begin

    -- 50 MHz clock (20 ns period)
    clk <= not clk after 10 ns;

    -- Reset pulse
    process
    begin
        rst_n <= '0';
        wait for 100 ns;
        rst_n <= '1';
        wait;
    end process;

    -- Switch patterns (change frequency / mode during sim)
    process
    begin
        sw <= "0000";       -- low frequency, sine mode
        wait for 5 ms;
        sw <= "0100";       -- different frequency, sine mode
        wait for 5 ms;
        sw <= "0110";       -- plain PWM mode (SW1=1) 
        wait;
    end process;

    -- DUT instance
    uut: entity work.top
        port map (
            clk     => clk,
            rst_n   => rst_n,
            sw      => sw,
            pwm_out => pwm_out,
            ledr1   => ledr1
        );
end architecture;
