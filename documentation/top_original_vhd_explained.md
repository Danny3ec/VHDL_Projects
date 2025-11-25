# Top-Level Design Explanation (`top_original.vhd`)

## 1. Role of `top_original.vhd`
The `top_original.vhd`file serves as the main integration module for the function generator. It connects the 50 MHz clock, user switches, reset input, and output LEDs to internal building blocks such as the NCO, sine lookup table, PWM module, and heartbeat generator. Together, these modules produce a selectable sine-PWM or fixed-duty PWM waveform on the DE1-SoC board.

## 2. External Ports

| Signal  | Dir | Description                                   |
|---------|-----|-----------------------------------------------|
| clk     | in  | 50 MHz board clock                            |
| rst_n   | in  | Active-low reset from KEY0                    |
| sw[3:0] | in  | User switches (mode and frequency selection)  |
| pwm_out | out | LEDR0 – heartbeat output from `funcgen_micro` |
| ledr1   | out | LEDR1 – main PWM waveform output              |

## 3. Internal Modules Connected

- `funcgen_micro.vhd` – small auxiliary PWM used as a heartbeat indicator on LEDR0.
- `nco.vhd` – 24-bit Numerically Controlled Oscillator (NCO). Its frequency is selected from the INC_TAB8 lookup table using SW3, SW2, and SW0.
- `sine_lut.vhd` – 64-entry ROM holding one sine wave period (8-bit samples). The top six bits of the NCO phase drive the address.
- `pwm.vhd` – 8-bit PWM generator that converts amplitude values into a duty-cycle-controlled output for LEDR1.

## 4. Switch Functions

- **SW1** – Mode select  
  - `0`: Sine mode. LEDR1 brightness follows the sine LUT (breathing effect).  
  - `1`: LEDR1 uses a fixed duty cycle (duty_plain), with SW0 selecting low or high brightness.

- **SW3, SW2, SW0** – Frequency select  
  These switches form a 3-bit index used to select one of eight NCO increments in INC_TAB8, producing frequencies from approximately 10 Hz to 10 kHz. 
## 5. Signal Flow (Simplified)

```text
                ┌──────────────┐
 SW3, SW2, SW0 →│  freq_idx    │
                └──────┬───────┘
                       │
                       v
                ┌──────────────┐
                │   INC_TAB8   │  (tuning words)
                └──────┬───────┘
                       │  nco_inc
                       v
                ┌──────────────┐
      clk,rst → │     NCO      │ → nco_phase[23:0]
                └──────┬───────┘
                       │  phase[23:18]
                       v
                ┌──────────────┐
                │   sine_lut   │ → sine_samp[7:0]
                └──────┬───────┘
                       │
          SW1 ─────┐   │
                   │   v
                   │ ┌──────────────┐
                   ├→│   duty_sel   │
                   │ └──────┬───────┘
          SW0 ──┐  │        │
                │  │        v
                v  │  ┌──────────────┐
        ┌──────────────┐│     PWM      │ → LEDR1
        │ duty_plain   │└──────────────┘
        └──────────────┘

```
   funcgen_micro runs independently and drives pwm_out on LEDR0 as a heartbeat indicator.

## 6. Summary

top_original.vhd integrates all functional blocks—NCO, sine LUT, PWM engine, and heartbeat generator—into a compact top-level design. The module maps the DE1-SoC switches to mode and frequency control and generates either a sine-modulated or fixed-duty PWM output using a common 50 MHz system clock.
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

> The switch SW1 controls the waveform mode, while SW3,SW2, and SW0 form the 3 bit frequency index used to select one of the eight tuning words in`INC_TAB8`
> while SW3–SW0 select the frequency index (0–7) into the `INC_TAB8` table.

### Summary
`INC_TAB8` provides discrete tuning words that give the waveform generator precise, stable frequencies over a wide range without modifying hardware.  
This modular approach allows easy extension—additional entries could be added for finer frequency control or different clock rates.

