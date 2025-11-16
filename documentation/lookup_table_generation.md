# Lookup Table Generation

This document explains how the main lookup tables in the project were generated
using simple MATLAB scripts, and how they relate to the VHDL design, including sine_lut and dac_test which is an extra project using much elements as possible.

The three main tables are:

- `sine_lut.vhd` – 64-sample sine wave for PWM
- `SINE_ROM` (in `dac_test`) – 256-sample sine wave for DAC testing
- `INC_TAB8` – NCO increment values for different output frequencies

---

## 1. Sine LUT for PWM (`sine_lut.vhd`)

The file `sine_lut.vhd` contains 64 unsigned 8-bit values (0–255). These values
represent one full period of a sine wave, sampled uniformly.

A normal sine wave has values between -1 and +1. To use it in 8-bit unsigned
logic, it is scaled and shifted into the range 0–255 using:
```
> y(k) = round(127.5 * (1 + sin(2*pi*k/N)))  
> where N = 64, and k = 0…63
```
This maps:
- sin = -1 → y = 0  
- sin =  0 → y ≈ 128  
- sin = +1 → y = 255  

These samples are then stored as `to_unsigned(value, 8)` entries in VHDL.

## MATLAB script used (64-sample sine_lut)

```matlab
% generate_sine_lut_64.m
% Generates the 64-sample, 8-bit sine table for sine_lut.vhd

N = 64;                 % number of samples
k = 0:N-1;              % sample indices

values = round(127.5 * (1 + sin(2*pi*k/N)));  % 0..255

fprintf('constant T : lut_t := (\n');
for i = 1:N
    fprintf('  to_unsigned(%3d, 8)', values(i));
    if i < N
        fprintf(',');
    end
    if mod(i,4) == 0 || i == N
        fprintf('\n');
    else
        fprintf(' ');
    end
end
fprintf(');\n');
```
Running this script prints the VHDL constant T : lut_t, which was copied into
sine_lut.vhd.

# 2. 256-sample DAC Sine ROM (dac_test → SINE_ROM)

The dac_test project uses a higher-resolution sine table with 256 samples.
The same idea is used as for sine_lut, but with N = 256 instead of 64.

The formula is:
```
y(k) = round(127.5 * (1 + sin(2pik/256)))
```
These 8-bit values are printed in hexadecimal form (for example x"80",
x"83", etc.) and stored in a VHDL ROM.

## MATLAB script used (256-sample SINE_ROM)
```matlab
% generate_sine_rom_256.m
% Generates 256-sample sine ROM values for dac_test

N = 256;
k = 0:N-1;

values = round(127.5 * (1 + sin(2*pi*k/N)));

fprintf('constant SINE_ROM : rom_t := (\n');
for i = 1:N
    if mod(i-1, 8) == 0
        fprintf('    ');  % indent each line
    end
    fprintf('x"%02X"', values(i));
    if i < N
        fprintf(', ');
    end
    if mod(i-1, 8) == 7 || i == N
        fprintf('\n');
    end
end
fprintf(');\n');
```
The output from this script matches the VHDL SINE_ROM used in the DAC test
design.
# 3. NCO Increment Table (INC_TAB8 in top.vhd)

Frequency control is implemented using a 24-bit Numerically Controlled
Oscillator (NCO). The NCO output frequency is:
```
f_out = (f_clk * Increment) / 2^24
```
In this project:
```
f_clk = 50 MHz
```
The phase accumulator is 24 bits wide

Rearranging the formula gives the required increment for a chosen output
frequency:
```
Increment = round( f_out * 2^24 / f_clk )
```
The table INC_TAB8 contains eight such increment values, for output
frequencies between about 10 Hz and 10 kHz.

## MATLAB script used (INC_TAB8 generation)
```matlab
% generate_inc_tab8.m
% Computes NCO increment values for 8 preset frequencies

freqs = [10 25 63 160 400 1000 2500 10000];  % target frequencies (Hz)
Fclk = 50e6;          % 50 MHz
PHASE_BITS = 24;      % phase accumulator width

incs = round(freqs * 2^PHASE_BITS / Fclk);

fprintf('constant INC_TAB8 : u24 := (\n');
for i = 1:numel(incs)
    fprintf('  to_unsigned(%5d, 24)', incs(i));
    if i < numel(incs)
        fprintf(',  %% %.0f Hz\n', freqs(i));
    else
        fprintf('   %% %.0f Hz\n', freqs(i));
    end
end
fprintf('\n);\n');
```
This script prints the VHDL initialisation for INC_TAB8, with a comment next
to each entry showing the corresponding target frequency.

# 4. Seven-segment Decoder (extra project)

The seven-segment display driver uses a fixed lookup from a 4-bit hexadecimal
value to a 7-bit active-low segment pattern (gfedcba). This is not generated
from a formula, but defined once and reused.
```
Example VHDL mapping:
when "0000" => segs <= "1000000"; -- 0
when "0001" => segs <= "1111001"; -- 1
when "0010" => segs <= "0100100"; -- 2
when "0011" => segs <= "0110000"; -- 3
when "0100" => segs <= "0011001"; -- 4
when "0101" => segs <= "0010010"; -- 5
when "0110" => segs <= "0000010"; -- 6
when "0111" => segs <= "1111000"; -- 7
when "1000" => segs <= "0000000"; -- 8
when "1001" => segs <= "0010000"; -- 9
when "1010" => segs <= "0001000"; -- A
when "1011" => segs <= "0000011"; -- b
when "1100" => segs <= "1000110"; -- C
when "1101" => segs <= "0100001"; -- d
when "1110" => segs <= "0000110"; -- E
when "1111" => segs <= "0001110"; -- F
```

This table is based on the standard seven-segment display convention.

5. Summary

sine_lut.vhd and SINE_ROM store precomputed sine samples in 8-bit unsigned
format, generated in MATLAB.

INC_TAB8 stores NCO increment values computed from the desired output
frequencies and the NCO equation.

The seven-segment decoder uses a fixed lookup for hexadecimal to segment
patterns.

Precomputing these tables allows the FPGA to generate accurate waveforms
without doing real-time sine or frequency calculations in hardware.




