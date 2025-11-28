# **README — VHDL Testbench (`tb_top`)**

## 📌 Overview

This testbench (`tb_top`) is designed to simulate the **`top`** module of the project.
It performs the following tasks:

* Generates a **50 MHz clock**
* Applies a **reset pulse** at the beginning of simulation
* Drives different **switch patterns (`sw`)** to test:

 * Frequency changes
 * Sine/PWM mode selection
 * Captures and observes:

  * `pwm_out` waveform
  * `ledr1` indicator

The testbench provides an automated and repeatable way to validate the behaviour of the design under different switch configurations.

---

## 📂 Files

| File         | Description                                              |
| ------------ | -------------------------------------------------------- |
| `tb_top.vhd` | VHDL testbench that simulates the `top` module           |
| `top.vhd`    | Design under test (DUT) — not included here but required |
| `README.md`  | This document                                            |

---

## ⚙️ Features of the Testbench

### ✔ **1. Clock Generator**

A 50 MHz clock is produced by toggling a signal every 10 ns:

```vhdl
clk <= not clk after 10 ns;
```

### ✔ **2. Reset Generator**

Reset (`rst_n`) is held low for 100 ns, then released:

```vhdl
rst_n <= '0';
wait for 100 ns;
rst_n <= '1';
```

This guarantees the DUT begins in a known state.

---

## 🔧 Switch (SW) Stimulus

The testbench automatically cycles through three `sw` settings to test different operating modes:

### **0–5 ms: `sw = "0000"`**

* Low-frequency sine mode
* DUT should output slow sine-based PWM

### **5–10 ms: `sw = "0100"`**

* Frequency change
* Still in sine mode
* Useful for verifying frequency scaling logic

### **10 ms onward: `sw = "0110"`**

* PWM-only mode (`SW1 = 1`)
* Should bypass sine logic and output raw PWM behavior

This timed sequence allows waveform comparison between modes.

---

## 🧪 DUT Instantiation

The testbench instantiates the design under test:

```vhdl
uut: entity work.top
    port map (
        clk     => clk,
        rst_n   => rst_n,
        sw      => sw,
        pwm_out => pwm_out,
        ledr1   => ledr1
    );
```

Outputs such as `pwm_out` and `ledr1` can be inspected in the waveform viewer.

---

## ▶️ How to Run the Simulation

### Using **ModelSim / QuestaSim**:

1. Compile all files:

   ```
   vlog top.vhd tb_top.vhd
   ```

2. Start simulation:

   ```
   vsim tb_top
   ```

3. Add signals to the waveform:

   ```
   add wave *
   run 15 ms
   ```


---

## 📈 Expected Results

During simulation:

* The clock runs at 50 MHz.
* Reset clears the DUT state in the first 100 ns.
* The PWM output frequency and waveform shape change at:

  * 5 ms
  * 10 ms
* `ledr1` should reflect internal mode changes depending on your `top` module logic.

---

## 📝 Notes

* No user interaction is required — the testbench is **fully automated**.
* Timing values (5 ms, 10 ms) are chosen to make waveform inspection easy.
* The testbench does *not* include assertions, but they can be added if desired.

---


