# DAC Test (Hexadecimal + Sine Wave Demo)

This VHDL project tests an **8-bit DAC (TLC7524)** using the DE-series FPGA board.  
It drives the DAC data bus with either a **manual hexadecimal value** (from switches) or a **generated sine wave** (from a ROM lookup table).  
The current output value is shown on **LEDs** and **7-segment displays** in hexadecimal.

---

## ⚙️ Features

- Manual or automatic (sine wave) output mode selected by `SW9`
- Speed control for DAC write rate and sine frequency using `SW8`
- Real-time output display:
  - **LEDR[7:0]** → binary DAC value  
  - **HEX0–HEX1** → hexadecimal value  
  - **HEX2** → shows “A” (auto) or “H” (manual)
- 8-bit DAC data (`DAC_DB[7:0]`) and strobe (`DAC_WR_N`) outputs
- Active-low reset using `KEY0`

---

## 🔌 Board connections

| Signal | Description |
|--------|--------------|
| `CLOCK_50` | 50 MHz board clock |
| `KEY(0)` | Active-low reset |
| `SW(9)` | Mode: 0 = manual, 1 = auto (sine) |
| `SW(8)` | Speed control (faster/slower sine & strobe) |
| `SW(7:0)` | Manual DAC value |
| `LEDR(7:0)` | DAC value display |
| `LEDR(9)` | Mode indicator |
| `HEX0`–`HEX1` | Hexadecimal value display |
| `HEX2` | Mode indicator (A/H) |
| `DAC_DB[7:0]` | DAC data output |
| `DAC_WR_N` | DAC write strobe |
| `DAC_CS_N` | DAC chip select (always active low) |

---

## 🧠 How it works

1. A 24-bit counter `clk_div` divides the 50 MHz clock to generate slower control signals.  
2. If `SW9 = 1` (**auto mode**):
   - `dac_value` is taken from an internal 256-entry sine lookup table (`SINE_ROM`).  
   - Bit selection of the counter (`clk_div`) changes the sine frequency.  
3. If `SW9 = 0` (**manual mode**):
   - `dac_value <= SW(7 downto 0)` — direct control from switches.  
4. `DAC_WR_N` pulses periodically to update the DAC.  
5. The current value is shown on LEDs and HEX displays.

---

## 🧰 Tools

- Quartus Prime Lite Edition 24.1  
- Target: Intel/Altera FPGA board (Cyclone V)

---

## 📄 File

| File | Description |
|------|--------------|
| `dac_test.vhd` | Main VHDL test design with sine ROM, DAC interface, and display logic |

---



For educational coursework use only.  
© 2025 Danny3ec [8A]
