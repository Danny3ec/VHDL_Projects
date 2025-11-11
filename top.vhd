-- top.vhd  (SW1 = mode, SW0,SW2,SW3 = frequency)
-- SW1=0 : Sine via LUT -> PWM (LEDR1 breathes at selected frequency) 
-- SW1=1 : Plain PWM (steady brightness)
-- SW0   : selects low or high brightness
-- SW3,SW2,SW0 : select one of 8 NCO frequency presets (10Hz -> 10 KHz)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    clk     : in  std_logic;                    -- 50 MHz (PIN_AF14)
    rst_n   : in  std_logic;                    -- KEY0, active-low (PIN_AA14)
    sw      : in  std_logic_vector(3 downto 0); -- SW3..SW0 + mode control
    pwm_out : out std_logic;                    -- LEDR0 (from funcgen_micro)
    ledr1   : out std_logic                     -- LEDR1
  );
end entity;

architecture rtl of top is
  -- NCO core
  signal rst_high  : std_logic;
  signal nco_inc   : unsigned(23 downto 0);
  signal nco_phase : unsigned(23 downto 0);

  -- Sine LUT + PWM
  signal sine_addr : unsigned(5 downto 0);
  signal sine_samp : unsigned(7 downto 0);
  signal duty_sel  : unsigned(7 downto 0);      -- muxed duty fed to PWM
  
  -- STEP 6: NCO frequency presets (8 entries, 10 Hz → 10 kHz)
type u24     is array (natural range <>) of unsigned(23 downto 0);
constant INC_TAB8 : u24 := (
  to_unsigned(    3,24),  -- 10 Hz
  to_unsigned(    8,24),  -- 25 Hz
  to_unsigned(   21,24),  -- 63 Hz
  to_unsigned(   54,24),  -- 160 Hz
  to_unsigned(  134,24),  -- 400 Hz
  to_unsigned(  336,24),  -- 1 kHz
  to_unsigned(  839,24),  -- 2.5 kHz
  to_unsigned( 3355,24)   -- 10 kHz
);

signal freq_idx : unsigned(2 downto 0);     -- uses SW3,SW2,SW0 (ignore SW1 so mode still works)
signal duty_plain : unsigned(7 downto 0);   -- plain-PWM brightness

begin
  
  -- Reset polarity
    rst_high <= not rst_n;

  -- The tiny blinker driving LEDR0 (independent of switches now)
   u_micro: entity work.funcgen_micro
    port map (
      clk     => clk,
      rst_n   => rst_n,
      sw0     => sw(0),          -- still wired in; not used if your micro ignores it
      pwm_out => pwm_out
    );

  
  -- NCO: frequency presets by SW3,SW2,SW0
  -- freq_idx builds a 3-bit index for INC_TAB8 (10 Hz -> 10 KHz)
  -- Build 3-bit index from SW3,SW2,SW0 (SW1 is mode → ignored for frequency)
freq_idx(2) <= sw(3);
freq_idx(1) <= sw(2);
freq_idx(0) <= sw(0);

-- Look up tuning word (drives ≈10 Hz → 10 kHz)
nco_inc  <= INC_TAB8(to_integer(freq_idx));


  u_nco: entity work.nco
    generic map (PHASE_WIDTH => 24)
    port map (
      clk   => clk,
      rst   => rst_high,
      inc   => nco_inc,
      phase => nco_phase
		
);

 -- Sine LUT address from top 6 phase bits (64 samples / period)
 
  sine_addr <= nco_phase(23 downto 18);

  u_lut: entity work.sine_lut
    port map (
      addr => sine_addr,
      dout => sine_samp
    );

  -- Mode select on SW1:
  -- SW1=0 -> duty = sine_samp                 (Sine mode, “breathing”)
  -- SW1=1 -> duty = fixed level from SW0      (Plain PWM: low or high brightness)
  -- Plain-PWM duty: SW0=0 -> 25 (64); SW0=1 -> ~75% (192)
  duty_plain <= to_unsigned(64,8)  when sw(0) = '0'
				  else to_unsigned(192,8);
             
  -- Mode select: SW1=0 -> sine duty; SW1=1 -> plain PWM duty
  duty_sel <= sine_samp when sw(1) = '0'
              else duty_plain;


   -- 8-bit PWM driving LEDR1
    u_pwm: entity work.pwm
    port map (
      clk  => clk,
      rst  => rst_high,
      duty => duty_sel,
      outp => ledr1
    );
end architecture;
