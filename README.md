# VHDL_Projects
<p align="left">
  <img src="wolverine.png" alt="Project Logo" width="200"/>
</p>
> ### 🔷 Block Diagram (Brief Assignment Version)
> The diagram below shows the conceptual architecture of the waveform generator, including frequency selection, NCO operation, sine LUT, PWM generation, and top-level output routing.
<div align="center" style="
  border: 2px solid #1f6feb;
  border-radius: 8px;
  padding: 10px;
">
  <strong>Brief Assignment Block Diagram</strong><br><br>
  <img src="block_diagram_overview.png" width="600">
</div>

![VHDL](https://img.shields.io/badge/Language-VHDL-blue)
![Quartus](https://img.shields.io/badge/Tool-Quartus_Prime_24.1-green)
![FPGA](https://img.shields.io/badge/Target-FPGA-lightgrey)
![TOP.VHD](https://img.shields.io/badge/File-TOP.VHD-whiteblue)

Collection of VHDL designs and testbenches for my course work
# FPGA Function Generator (NCO + PWM + 7-segment display)

This project implements a simple digital function generator on an FPGA using VHDL.  
It includes:

- A numerically controlled oscillator (NCO) for phase generation
- A sine lookup table (LUT) to convert phase to amplitude
- An 8-bit PWM block to generate a PWM signal based on the sine values
- A small micro blinker module
- A top-level design that connects everything to board switches, LEDs and 7-segment displays
- A HEX7SEG.vhd  Binary-to-7-segment decoder. Displays hexadecimal values.

Tested with: Quartus Prime Version 24.1 std. 1077 03/04/2025 SC Lite Edition.

---

### File overview

**top.vhd** 
  - Top-level entity. Connects board I/O:
  - clk – 50 MHz system clock  
  - rst_n – active-low reset (KEY0)  
  - sw(3 downto 0) – switches  
  - pwm_out – LEDR0 (output of funcgen_micro)  
  - ledr1 – LEDR1 (sine-wave PWM with SW1 override)  
  - hex0, hex1 – 7-segment displays
   

**funcgen_micro.vhd**  
  - Simple “micro” function generator that uses a counter to blink pwm_out.  
  - Intended to use (sw0) to select between two blink speeds.

**nco.vhd**  
  - Numerically Controlled Oscillator.  
  - Generic PHASE_WIDTH sets accumulator width  
  - Port inc is the tuning word (controls frequency)  
  - Port phase outputs the current phase value.

**sine_lut.vhd**  
  - 64-entry sine lookup table.  
  - Input: addr (6-bit address)  
  - Output: dout (8-bit unsigned 0..255 sine sample)

 **pwm.vhd**  
  - 8-bit PWM generator.  
  - Input: duty (..255)  
  - Output: outp (PWM signal)

**HEX7SEG (HEX7SEG.vhd)**  
  - Binary-to-7-segment decoder.
  - Displays hexadecimal values (0–F) on the board’s HEX displays.



## How it works
1. NCO  
   - The nco module has a phase accumulator that adds inc every clock cycle.  
   - In top.vhd, nco_inc is selected by (SW0):
   - SW0 = 0 → nco_inc = 1  (lower frequency)  
   - SW0 = 1 → nco_inc = 8  (higher frequency)

2. Sine LUT  
   - The upper 6 bits of nco_phase (nco_phase(23 downto 18)) are used as the LUT address.  
   - sine_lut converts this address into an 8-bit sine sample sine_samp.

3. PWM  
   - pwm takes sine_samp as the duty cycle and outputs pwm_led.  
   - This produces a PWM signal whose duty cycle follows a sine wave.

4. LED outputs  
   - pwm_out (LEDR0) is driven by funcgen_micro (a separate simple blinker).  
   - ledr1 (LEDR1) is normally pwm_led, but:
   - If SW1 = 1, ledr1 is forced ON.

5.  HEX7SEG (HEX7SEG.vhd) 
    - Converts 4-bit input to 7-segment pattern (active-low).  
    - Displays hexadecimal 0–F.



## How to simulate

1. Add all VHDL files (top.vhd, funcgen_micro.vhd, nco.vhd, sine_lut.vhd, pwm.vhd, hex7seg.vhd) to your simulation project.
2. Set top as the top-level entity.
3. Apply a 50 MHz clock on clk and toggle rst_n low then high.
4. Change sw(0) and sw(1) to observe:
   - Different frequencies from the NCO path
   - LEDR1 override when SW1 = 1.



## How to synthesize / run on hardware

1. Create a new FPGA project in *[Quartus / Vivado / etc.]*.
2. Add all VHDL source files.
3. Set "top" as the top-level entity.
4. Assign pins according to your board (as commented in top.vhd).
5. Compile, program the FPGA and observe LEDs and 7-segment display.


## Repository

All design files and documentation are available at:  
[https://github.com/Danny3ec/VHDL_Projects](https://github.com/Danny3ec/VHDL_Projects)



