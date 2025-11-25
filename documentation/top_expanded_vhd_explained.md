# Top-Level Design Explanation (`top_expanded.vhd`)
top_expanded.vhd is the enhanced version of the function generator.
Compared to top_original.vhd, it uses the full DE1-SoC front panel:
- All 10 switches (SW0–SW9)
- 3 push-buttons (KEY0–KEY2)
- 10 LEDs (LEDR0–LEDR9)
- Three 7-segment displays (HEX0–HEX2)
This expanded design adds:
Frequency stepping using keys
4-bit amplitude control
Multi-bit waveform mode system
Real-time visualisation on LEDs and HEX displays
Cleaner user interface
More flexible signal routing
# 1. External Ports
| Port |	Dir  |	Description |
|----------|------|----------------------------------------------------------------------|
|CLOCK_50  |	in  |Global 50 MHz system clock                                            |
|KEY(3:0)  |	in  |Push-buttons; KEY0 = reset (active-low), KEY1/KEY2 = frequency step   |
|SW(9:0)   |	in  |Front panel switches used for mode, amplitude, and frequency selection|
|LEDR(9:0) |	out	|Displays mode, amplitude, frequency, and PWM output                   |
|HEX0..HEX5|	out	|Seven-segment displays (active-low)                                   |
|pwm_out	 |  out	|Heartbeat output from funcgen_micro                                   |
|ledr1	   |  out	|Main PWM output                                                       |
# 2. Switch & Key Functions (Full Table)
## 2.1 Mode Selection – SW9..SW8
|Mode (SW9 SW8)|Behaviour        |	Display                           |
|--------------|-----------------|------------------------------------|
|00	           | Sine-PWM mode	 | HEX1/HEX2 show 00, LEDR9–8 = 00    |
|01            | Plain PWM mode	 | HEX1/HEX2 show 01                  | 
|10	           | Reserved (currently acts like sine)|	LED/HEX still show mode bits|
|11	           | Reserved	       | Same as above|
## 2.2 Amplitude Control – SW7..SW4
amp4 = SW7..SW4 → expanded to 8-bit:
amp8 <= amp4 & amp4
|SW7..SW4|Amplitude|Effect on LEDR1|
|--------|---------|---------------|
|0000|0	|Off / minimum|
|0001|	17	|very dim|
|1111	|255|	maximum amplitude|

LEDR7..4 mirror the amplitude bits.

## 2.3 Frequency Select (Base Preset) – SW2..SW0
Defines freq_idx = base preset from switches.
|SW2 SW1 SW0|	Index|	Frequency (approx.)|
|---|--|-------|
|000|	0|	10 Hz|
|001|	1|	25 Hz|
|010|	2|	63 Hz|
|011|	3|	160 Hz|
|100|	4|	400 Hz|
|101|	5|	1 kHz|
|110|	6|	2.5 kHz|
|111|	7|	10 kHz|

Displayed on HEX0 and on LEDR3..1.

## 2.4 Frequency Stepping – KEY1 and KEY2
KEY1 = step UP

KEY2 = step DOWN

This modifies freq_idx_r:

`if KEY1 pressed → freq_idx_r++`
`if KEY2 pressed → freq_idx_r--`
`else freq_idx_r = freq_idx (from switches)`

This allows fine frequency changes without touching switches.

## 2.5 Reset – KEY0
Active-low reset.
Resets:
- NCO
- Frequency stepping
- Displays
- PWM
# 3. Internal Modules Used
|Module	|Function|
|-------|------------------|
|funcgen_micro|	Heartbeat PWM on LEDR0|
|nco	|24-bit numerically-controlled oscillator; generates phase accumulator|
|sine_lut	|64-entry 8-bit sine table (0–255)|
|pwm	|8-bit PWM generator for LEDR1|
|hex_to_7seg()|	Converts hex digit → seven-segment pattern|

Extra logic:
-Frequency stepping register (freq_idx_r)
-Amplitude scaler (amp4 → amp8)
-7-seg display forming
-LED mappings for diagnostics

# 4. Signal Flow Diagram (GitHub-friendly)

```text

                   ┌────────────────────┐
                   │   SW9..SW8         │
                   │   (mode bits)      │
                   └─────────┬──────────┘
                             │
                             ▼
                      ┌────────────┐
                      │  mode MUX  │
                      └──────┬─────┘
                             │
                             ▼
                          duty_sel
                             ▲
                             │
            ┌────────────────┼──────────────────┐
            │                │                  │
            │                │                  │
            ▼                ▼                  ▼
   ┌─────────────────┐   ┌──────────────┐  ┌─────────────────┐
   │  SW7..SW4       │   │ SW2..SW0     │  │ funcgen_micro   │
   │ (amplitude bits)│   │ (freq preset)│  └────────┬────────┘
   └───────┬─────────┘   └──────┬───────┘           │
           │                     │                   ▼
           ▼                     ▼                pwm_out
   amp4 → amp8            freq_idx (3-bit)
           │                     │
           ▼                     ▼
   ┌──────────────┐      ┌──────────────┐
   │ Amplitude    │      │ INC_TAB8     │
   │ scaling      │      │ lookup table │
   └──────┬───────┘      └──────┬───────┘
          │                     │
          ▼                     ▼
     samp_scaled          nco_inc (24-bit)
                                 │
                                 ▼
                          ┌──────────────┐
                          │     NCO      │
                          │ (phase[23:0])│
                          └──────┬───────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │  sine_lut    │
                          │64-sample ROM │
                          └─────┬────────┘
                                │
                                ▼
                            sine_samp
                                │
                                ▼
                           ┌─────────┐
                           │  PWM    │
                           └────┬────┘
                                 │
                                 ▼
                               LEDR1
```

# 5. Seven-Segment Displays
|Display	|Meaning|
|-------|---------|
|HEX0	|Frequency preset (0–7)|
|HEX1	|Mode bit 0 (SW8)|
|HEX2	|Mode bit 1 (SW9)|
|HEX3–HEX5|	Always blank|

# 6. LED Indicators
|LEDR Bits	|Meaning|
|-----------|--------|
|9..8	Mode bits|
|7..4	Amplitude bits|
|3..1	Frequency index|
|0	PWM output (mirror of LEDR1)|

# 7. Behaviour Summary
- Sine-PWM mode (00): LEDR1 breathes smoothly; amplitude controlled by SW7–SW4
- Plain PWM mode (01): LEDR1 stable brightness; amplitude sets duty cycle
- Frequency preset via SW2..SW0; fine stepping via KEY1/2
- HEX displays show mode + frequency
- LEDR gives full diagnostic information
- funcgen_micro continues running as independent heartbeat

# 8. Why this version is “expanded”
Compared to top_original, it adds:
- Full amplitude control (4-bit)
- 2-bit mode system
- Frequency stepping via buttons
- HEX display visualisation
- LED-based feedback
- Cleaner, user-friendly front-panel control
- Better structure for further extensions (DAC, waveform selection, etc.)
