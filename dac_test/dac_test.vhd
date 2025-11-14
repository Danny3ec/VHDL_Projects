library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--====================================================
-- Top-level entity
--====================================================
entity dac_test is
    port (
        -- 50 MHz clock
        CLOCK_50 : in  std_logic;

        -- Push buttons (KEY0 will be used as reset, active-low)
        KEY      : in  std_logic_vector(3 downto 0);

        -- Slide switches
        SW       : in  std_logic_vector(9 downto 0);

        -- Red LEDs
        LEDR     : out std_logic_vector(9 downto 0);

        -- Seven segment displays (active-low)
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);

        -- DAC interface (TLC7524 on GPIO-1)
        DAC_DB   : out std_logic_vector(7 downto 0);  -- DB0..DB7
        DAC_WR_N : out std_logic;                     -- WR̅ (active-low)
        DAC_CS_N : out std_logic                      -- CS̅ (active-low)
    );
end entity dac_test;

--====================================================
-- Architecture
--====================================================
architecture rtl of dac_test is

    --------------------------------------------------------------------
    -- Internal signals
    --------------------------------------------------------------------
    signal reset_n     : std_logic;                                 -- internal reset (active-low)
    signal clk_div     : unsigned(23 downto 0) := (others => '0');  -- clock divider / counter
    signal dac_value   : std_logic_vector(7 downto 0);
    signal mode_auto   : std_logic;                                 -- '1' = auto ramp, '0' = manual from switches

                                                                    -- Nibbles for 7-seg
    signal low_nibble  : std_logic_vector(3 downto 0);
    signal high_nibble : std_logic_vector(3 downto 0);

    --------------------------------------------------------------------
    -- 7-segment decoder function (active-low segments)
    -- segments order: (6 downto 0) = {g, f, e, d, c, b, a}
    --------------------------------------------------------------------
    function hex_to_7seg (x : std_logic_vector(3 downto 0))
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

                                                           -- "A" and "M" symbols for HEX2 (approximate)
    function char_A return std_logic_vector is
    begin
                                                           -- segments g f e d c b a
        return "0001000";                                  -- looks like 'A'
    end function;

    function char_M return std_logic_vector is
    begin
        
                                                           -- looks like 'H'
    return "0001001";

    end function;
	 --------------------------------------------------------------------
    -- 256-sample 8-bit sine lookup table (one full period)
    -- Output range: 0..255
    --------------------------------------------------------------------
    type rom_t is array (0 to 255) of std_logic_vector(7 downto 0);

    constant SINE_ROM : rom_t := (
        x"80", x"83", x"86", x"89", x"8C", x"8F", x"92", x"95",
        x"98", x"9B", x"9E", x"A2", x"A5", x"A7", x"AA", x"AD",
        x"B0", x"B3", x"B6", x"B9", x"BC", x"BE", x"C1", x"C4",
        x"C6", x"C9", x"CB", x"CE", x"D0", x"D3", x"D5", x"D7",
        x"DA", x"DC", x"DE", x"E0", x"E2", x"E4", x"E6", x"E8",
        x"EA", x"EB", x"ED", x"EE", x"F0", x"F1", x"F3", x"F4",
        x"F5", x"F6", x"F8", x"F9", x"FA", x"FA", x"FB", x"FC",
        x"FD", x"FD", x"FE", x"FE", x"FE", x"FF", x"FF", x"FF",
        x"FF", x"FF", x"FF", x"FF", x"FE", x"FE", x"FE", x"FD",
        x"FD", x"FC", x"FB", x"FA", x"FA", x"F9", x"F8", x"F6",
        x"F5", x"F4", x"F3", x"F1", x"F0", x"EE", x"ED", x"EB",
        x"EA", x"E8", x"E6", x"E4", x"E2", x"E0", x"DE", x"DC",
        x"DA", x"D7", x"D5", x"D3", x"D0", x"CE", x"CB", x"C9",
        x"C6", x"C4", x"C1", x"BE", x"BC", x"B9", x"B6", x"B3",
        x"B0", x"AD", x"AA", x"A7", x"A5", x"A2", x"9E", x"9B",
        x"98", x"95", x"92", x"8F", x"8C", x"89", x"86", x"83",
        x"80", x"7C", x"79", x"76", x"73", x"70", x"6D", x"6A",
        x"67", x"64", x"61", x"5D", x"5A", x"58", x"55", x"52",
        x"4F", x"4C", x"49", x"46", x"43", x"41", x"3E", x"3B",
        x"39", x"36", x"34", x"31", x"2F", x"2C", x"2A", x"28",
        x"25", x"23", x"21", x"1F", x"1D", x"1B", x"19", x"17",
        x"15", x"14", x"12", x"11", x"0F", x"0E", x"0C", x"0B",
        x"0A", x"09", x"07", x"06", x"05", x"05", x"04", x"03",
        x"02", x"02", x"01", x"01", x"01", x"00", x"00", x"00",
        x"00", x"00", x"00", x"00", x"01", x"01", x"01", x"02",
        x"02", x"03", x"04", x"05", x"05", x"06", x"07", x"09",
        x"0A", x"0B", x"0C", x"0E", x"0F", x"11", x"12", x"14",
        x"15", x"17", x"19", x"1B", x"1D", x"1F", x"21", x"23",
        x"25", x"28", x"2A", x"2C", x"2F", x"31", x"34", x"36",
        x"39", x"3B", x"3E", x"41", x"43", x"46", x"49", x"4C",
        x"4F", x"52", x"55", x"58", x"5A", x"5D", x"61", x"64",
        x"67", x"6A", x"6D", x"70", x"73", x"76", x"79", x"7C"
    );


begin

    --------------------------------------------------------------------
    -- Reset (KEY0 active-low)
    --------------------------------------------------------------------
    reset_n <= KEY(0);  -- press KEY0 => reset_n = '0'

    --------------------------------------------------------------------
    -- Clock divider / free-running counter
    -- Used for auto ramp and DAC_WR_N pacing
    --------------------------------------------------------------------
    process (CLOCK_50, reset_n)
    begin
        if reset_n = '0' then
            clk_div <= (others => '0');
        elsif rising_edge(CLOCK_50) then
            clk_div <= clk_div + 1;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Mode selection
    -- SW(9) = 0 -> manual (from SW[7:0])
    -- SW(9) = 1 -> auto ramp (from clk_div)
    --------------------------------------------------------------------
    mode_auto <= SW(9);

    process (clk_div, SW, mode_auto)
    begin
        if mode_auto = '1' then
				                                                                        -- AUTO (sine) mode
				if SW(8) = '1' then
			                                                                        	-- faster sine: use lower bits of counter
				dac_value <= SINE_ROM(to_integer(unsigned(clk_div(21 downto 14))));
				else
					                                                                     -- slower sine: use higher bits of counter
					dac_value <= SINE_ROM(to_integer(unsigned(clk_div(23 downto 16))));
				end if;
		   else            
            -- Manual mode: directly from switches
            dac_value <= SW(7 downto 0);
        end if;
    end process;

    --------------------------------------------------------------------
    -- Drive DAC pins (TLC7524)
    --------------------------------------------------------------------
    -- Data bus: always drive current dac_value
    DAC_DB <= dac_value;
    --------------------------------------------------------------------
    -- Adjustable write strobe using SW8
    -- SW8 = 0 -> faster update
    -- SW8 = 1 -> slower update
    --------------------------------------------------------------------
    process (clk_div, SW)
    begin
		  if SW(8) = '1' then
        DAC_WR_N <= clk_div(20);                                -- slow pulse (bit 20 toggles slower)
    else
        DAC_WR_N <= clk_div(12);                                -- fast pulse (bit 12 toggles faster)
    end if;
end process;


                                                                -- Keep CS low (always selected)
    DAC_CS_N <= '0';                                            -- or tie CS to GND in hardware

    --------------------------------------------------------------------
    -- LEDs
    --------------------------------------------------------------------
    LEDR(7 downto 0) <= dac_value;   -- show current DAC value
    LEDR(8)          <= '0';
    LEDR(9)          <= mode_auto;   -- 1 = auto, 0 = manual

    --------------------------------------------------------------------
    -- Seven-seg displays
    --------------------------------------------------------------------
    low_nibble  <= dac_value(3 downto 0);
    high_nibble <= dac_value(7 downto 4);

    HEX0 <= hex_to_7seg(low_nibble);
    HEX1 <= hex_to_7seg(high_nibble);

    -- HEX2 shows 'A' or 'M' depending on mode
    HEX2 <= char_A when mode_auto = '1' else char_M;

    -- Others blank
    HEX3 <= "1111111";
    HEX4 <= "1111111";
    HEX5 <= "1111111";

end architecture rtl;


