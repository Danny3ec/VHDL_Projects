# Top-Level Design Explanation (`top.vhd`)

## 1. Role of `top.vhd`
The `top.vhd` file is the main integration module for the waveform generator implemented on the Intel DE1-SoC FPGA board. It connects the 50 MHz clock, reset button, user switches, and LEDs to the internal VHDL modules that generate the waveform.

## 2. External Ports

| Signal  | Dir | Description                                   |
|---------|-----|-----------------------------------------------|
| clk     | in  | 50 MHz board clock                            |
| rst_n   | in  | Active-low reset from KEY0                    |
| sw[3:0] | in  | User switches (mode and frequency selection)  |
| pwm_out | out | LEDR0 – heartbeat output from `funcgen_micro` |
| ledr1   | out | LEDR1 – main PWM waveform output              |

## 3. Internal Modules Connected

- `funcgen_micro.vhd` – small PWM/blinker used as a heartbeat on LEDR0.
- `nco.vhd` – 24-bit Numerically Controlled Oscillator. Increment (`nco_inc`) is selected from `INC_TAB8` using bits SW3, SW2 and SW0.
- `sine_lut.vhd` – ROM storing 64 samples of one sine wave period. The top six bits of the NCO phase word address this table.
- `pwm.vhd` – 8-bit PWM generator that converts amplitude values into a duty-cycle-controlled output for LEDR1.

## 4. Switch Functions

- **SW1** – Mode select  
  - `0`: Sine mode. Duty cycle comes from sine LUT (`sine_samp`), LEDR1 “breathes”.  
  - `1`: Plain PWM mode. Duty cycle comes from fixed value `duty_plain`, SW0 selects low or high brightness.

- **SW3, SW2, SW0** – Frequency select  
  These bits form a 3-bit index (`freq_idx`) into `INC_TAB8`, choosing one of eight preset NCO increments (≈10 Hz → 10 kHz).

## 5. Signal Flow (Simplified)

```text
SW3,SW2,SW0       SW1,SW0
     │              │
   freq_idx      duty_plain
     │              │
   INC_TAB8         │
     │              │
    nco_inc         │
       │            │
   NCO (phase)      │
       │            │
   sine_lut (sine_samp)
         │
       duty_sel → PWM → LEDR1
```
   funcgen_micro runs independently and drives pwm_out on LEDR0 as a heartbeat indicator.

## 6. Summary

top.vhd ties together the NCO, sine LUT, PWM, and micro blinker into one coherent design. 
It maps the DE1-SoC switches to mode and frequency control, sharing a 50 MHz clock and 
common reset logic across all modules.
## 7. INC_TAB8 Frequency Lookup Table

The **INC_TAB8** constant in the `top.vhd` file defines a lookup table of eight pre-calculated 24-bit increment values used by the Numerically Controlled Oscillator (NCO).  
Each value determines how quickly the phase accumulator advances on each clock cycle, directly controlling the output frequency according to:

**Formula:**
f_out = (f_clk × Increment) / 2^24

where  
- `f_clk` = 50 MHz system clock  
- `Increment` = value selected from the table based on the switch inputs (SW3–SW0)

### Frequency Table

| SW3 | SW2 | SW1 | SW0 | Decimal Increment | Approx. Frequency (Hz) | Mode Description        |
|:----:|:----:|:----:|:----:|:----------------:|:----------------------:|:------------------------|
| 0 | 0 | – | 0 | 3 | 10 Hz | Very slow blink / test |
| 0 | 0 | – | 1 | 8 | 25 Hz | Slow waveform |
| 0 | 1 | – | 0 | 21 | 63 Hz | Moderate waveform |
| 0 | 1 | – | 1 | 54 | 160 Hz | Medium frequency |
| 1 | 0 | – | 0 | 134 | 400 Hz | Fast waveform |
| 1 | 0 | – | 1 | 336 | 1 kHz | Faster waveform |
| 1 | 1 | – | 0 | 839 | 2.5 kHz | High speed |
| 1 | 1 | – | 1 | 3355 | 10 kHz | Maximum frequency |

> The switch SW1 acts as a mode select (sine-PWM or plain PWM),  
> while SW3–SW0 select the frequency index (0–7) into the `INC_TAB8` table.

### Summary
`INC_TAB8` provides discrete tuning words that give the waveform generator precise, stable frequencies over a wide range without modifying hardware.  
This modular approach allows easy extension—additional entries could be added for finer frequency control or different clock rates.

