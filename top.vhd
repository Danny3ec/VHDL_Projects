library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    clk     : in  std_logic;                    -- 50 MHz (PIN_AF14)
    rst_n   : in  std_logic;                    -- KEY0 active-low (PIN_AA14)
    sw      : in  std_logic_vector(3 downto 0); -- SW3..SW0 (we use SW1, SW0)
    pwm_out : out std_logic;                    -- LEDR0 (PIN_V16)
    ledr1   : out std_logic;                     -- LEDR1 (PIN_W16)
	 hex0    : out std_logic_vector(6 downto 0);  -- HEX0 segments
	 hex1    : out std_logic_vector(6 downto 0)
  );
end entity;

architecture rtl of top is

  -- Reset (active-high for internal modules)
  signal rst_high  : std_logic;

  -- NCO
  signal nco_inc   : unsigned(23 downto 0);
  signal nco_phase : unsigned(23 downto 0);

  -- Sine LUT + PWM
  signal sine_addr : unsigned(5 downto 0);
  signal sine_samp : unsigned(7 downto 0);
  signal pwm_led   : std_logic;   -- PWM before SW1 override

begin
-- HEX display decoders
	u_hex0: entity work.hex7seg
  port map (
    bin => sw,
    seg => hex0
  );

	u_hex1: entity work.hex7seg
  port map (
    bin => (others => '0'),
    seg => hex1
  );

  -- Reset
 
  rst_high <= not rst_n;

  
  -- LEDR0: your tiny blinker (only driver of pwm_out)
 
  u_micro: entity work.funcgen_micro
    port map (
      clk     => clk,
      rst_n   => rst_n,
      sw0     => sw(0),   -- you can use SW0 in funcgen_micro if desired
      pwm_out => pwm_out
    );

  
  -- SW0 speed select for the sine PWM path (slow=1, fast=8)
  
  nco_inc <= to_unsigned(1,24) when sw(0) = '0' else to_unsigned(8,24);

  u_nco: entity work.nco
    generic map (PHASE_WIDTH => 24)
    port map (
      clk   => clk,
      rst   => rst_high,
      inc   => nco_inc,
      phase => nco_phase
    );

  -- Use top 6 bits of phase as LUT address (64 samples/period)
  sine_addr <= nco_phase(23 downto 18);

  u_lut: entity work.sine_lut
    port map (
      addr => sine_addr,
      dout => sine_samp
    );

  u_pwm: entity work.pwm
    port map (
      clk  => clk,
      rst  => rst_high,
      duty => sine_samp,  -- 0..255
      outp => pwm_led
    );

  
  -- SW1 override: force LEDR1 ON when SW1 = '1'
 
  ledr1 <= '1' when sw(1) = '1' else pwm_led;

  -- SW2 and SW3 are intentionally unused

end architecture;
