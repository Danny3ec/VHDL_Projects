library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_expanded is
  port (
    CLOCK_50 : in  std_logic;
    KEY      : in  std_logic_vector(3 downto 0);  -- KEY3..KEY0
    SW       : in  std_logic_vector(9 downto 0);  -- SW9..SW0
    LEDR     : out std_logic_vector(9 downto 0);
    HEX0     : out std_logic_vector(6 downto 0);
    HEX1     : out std_logic_vector(6 downto 0);
    HEX2     : out std_logic_vector(6 downto 0);
    HEX3     : out std_logic_vector(6 downto 0);
    HEX4     : out std_logic_vector(6 downto 0);
    HEX5     : out std_logic_vector(6 downto 0);
    pwm_out  : out std_logic;  -- heartbeat LEDR0 if you want
    ledr1    : out std_logic   -- main PWM output
  );
end entity;

architecture rtl of top_expanded is


  -- Reset + sync
  
  signal rst_high : std_logic;
  signal sw_sync  : std_logic_vector(9 downto 0);
  signal key_sync : std_logic_vector(3 downto 0);
  signal pwm_led  : std_logic;
  signal mult16   : unsigned(15 downto 0);
  

  
  -- Waveform / control
  
  signal mode       : std_logic_vector(1 downto 0);   -- SW9..SW8
  signal amp4       : unsigned(3 downto 0);           -- SW7..SW4
  signal amp8       : unsigned(7 downto 0);           -- scaled amplitude
  signal freq_idx   : unsigned(2 downto 0);           -- SW2..SW0 preset
  signal freq_idx_r : unsigned(2 downto 0);           -- can be stepped by keys

  
  -- NCO core

  signal nco_inc   : unsigned(23 downto 0);
  signal nco_phase : unsigned(23 downto 0);

  type u24 is array (natural range <>) of unsigned(23 downto 0);
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


  -- LUT + PWM
  
  signal sine_addr : unsigned(5 downto 0);
  signal sine_samp : unsigned(7 downto 0);
  signal samp_scaled : unsigned(7 downto 0);
  signal duty_plain  : unsigned(7 downto 0);
  signal duty_sel    : unsigned(7 downto 0);
  
  -- 7-segment decoder (active-low), segments = a b c d e f g
  
  function hex_to_7seg(x: std_logic_vector(3 downto 0))
      return std_logic_vector is
      variable segs : std_logic_vector(6 downto 0);
  begin
    case x is
    when "0000" => segs := "1000000"; -- 0
    when "0001" => segs := "1111001"; -- 1
    when "0010" => segs := "0100100"; -- 2
    when "0011" => segs := "0110000"; -- 3
    when "0100" => segs := "0011001"; -- 4
    when "0101" => segs := "0010010"; -- 5
    when "0110" => segs := "0000010"; -- 6
    when "0111" => segs := "1111000"; -- 7
    when "1000" => segs := "0000000"; -- 8
    when "1001" => segs := "0010000"; -- 9
	 when "1010" => segs := "0001000"; -- a
    when "1011" => segs := "0000011"; -- b
    when "1100" => segs := "1000110"; -- C
    when "1101" => segs := "0100001"; -- d
    when "1110" => segs := "0000110"; -- e
    when "1111" => segs := "0001110"; -- f
    when others => segs := "1111111"; -- blank
  end case;
  return segs;
end function;
   
begin


  -- Reset polarity
  
  rst_high <= not KEY(0);  -- KEY0 active-low on DE1-SoC

  
  -- Simple 1-clock synchroniser for SW/KEY (polish)
  
  process(CLOCK_50, rst_high)
  begin
    if rst_high='1' then
      sw_sync  <= (others=>'0');
      key_sync <= (others=>'1');
    elsif rising_edge(CLOCK_50) then
      sw_sync  <= SW;
      key_sync <= KEY;
    end if;
  end process;

  
  -- Map controls
  
  mode    <= sw_sync(9 downto 8);        -- waveform mode
  amp4    <= unsigned(sw_sync(7 downto 4));
  freq_idx <= unsigned(sw_sync(2 downto 0));

  -- Expand 4-bit amplitude to 8-bit (0..255)
  amp8 <= amp4 & amp4;  -- simple scaling (0,17,34,...,255)

  
  -- Frequency index register with key stepping
  -- KEY1 = up, KEY2 = down

  process(CLOCK_50, rst_high)
  begin
    if rst_high='1' then
      freq_idx_r <= (others=>'0');
    elsif rising_edge(CLOCK_50) then
      if key_sync(1)='0' then         -- KEY1 pressed
        freq_idx_r <= freq_idx_r + 1;
      elsif key_sync(2)='0' then      -- KEY2 pressed
        freq_idx_r <= freq_idx_r - 1;
      else
        freq_idx_r <= freq_idx;       -- default from switches
      end if;
    end if;
  end process;

  nco_inc <= INC_TAB8(to_integer(freq_idx_r));

  -- Heartbeat (keep your micro)
 
  u_micro: entity work.funcgen_micro
    port map (
      clk     => CLOCK_50,
      rst_n   => KEY(0),
      sw0     => '0',
      pwm_out => pwm_out
    );

  
  -- NCO
  
  u_nco: entity work.nco
    generic map (PHASE_WIDTH => 24)
    port map (
      clk   => CLOCK_50,
      rst   => rst_high,
      inc   => nco_inc,
      phase => nco_phase
    );

 
  -- Sine LUT
  
  sine_addr <= nco_phase(23 downto 18);

  u_lut: entity work.sine_lut
    port map (
      addr => sine_addr,
      dout => sine_samp
    );

  
  -- Amplitude scaling for sine (simple multiply then shift)
  -- samp_scaled = sine_samp * amp8 / 255
  
  mult16      <= sine_samp * amp8;        -- 16-bit product
  samp_scaled <= mult16(15 downto 8);     -- scaled back to 8-bit

  
  -- Plain PWM duty from amplitude
  
  duty_plain <= amp8;  -- amplitude directly sets duty

  
  -- Mode selection:
  -- 00: sine-PWM
  -- 01: plain PWM
  -- 10/11 reserved for future waveforms
  
  with mode select
    duty_sel <= samp_scaled when "00",
                duty_plain  when "01",
                samp_scaled when others;

  
  -- PWM output to LEDR1
  
  u_pwm: entity work.pwm
    port map (
      clk  => CLOCK_50,
      rst  => rst_high,
      duty => duty_sel,
      outp => pwm_led
    );
  ledr1 <= pwm_led;

  
  -- LED visualisation
  
  LEDR(9 downto 8) <= mode;                          -- show mode
  LEDR(7 downto 4) <= std_logic_vector(amp4);        -- show amplitude
  LEDR(3 downto 1) <= std_logic_vector(freq_idx_r);  -- show freq preset
  LEDR(0)          <= pwm_led;                       -- mirror output

  
  -- 7-segment display (simple demo):
  -- HEX0..HEX2 show freq preset as hex, HEX5..HEX3 blank

  HEX0 <= hex_to_7seg('0' & std_logic_vector(freq_idx_r)); -- rough show
  HEX1 <= hex_to_7seg("000" & mode(0));
  HEX2 <= hex_to_7seg("000" & mode(1));
  HEX3 <= "1111111";
  HEX4 <= "1111111";
  HEX5 <= "1111111";

end architecture;
