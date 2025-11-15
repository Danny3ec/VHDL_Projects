## ModelSim Simulation Results

This document summarises the key simulation outputs captured during the verification of the FPGA-based function generator.
All waveforms were generated using ModelSim Intel FPGA Starter Edition with the testbench tb_top.vhd.

The purpose of these simulations was to confirm:

Correct system behaviour before hardware testing

Proper operation of the NCO, sine lookup table, mode selector, and PWM generator

Accurate mapping of switch inputs (SW3..SW0) to frequency presets and waveform modes

Stable reset and start-up behaviour

Each waveform screenshot included in this folder corresponds to a specific subsystem or mode of operation.

## 1. Reset and Clock Behaviour

File: reset_and_clock_waveform.png
Shows the system starting up with:

50 MHz clock toggling correctly

rst_n releasing the system after initialisation

Internal registers starting from known states

This confirms the design reacts properly to global reset.

## 2. Sine LUT Output (sine_samp)

File: sine_mode_sine_samp_waveform.png
Displays the output of the 8-bit sine lookup table, driven by the NCO phase accumulator.
The waveform shows a smooth discrete sine pattern, confirming:

Correct LUT addressing

Proper NCO stepping

Accurate sample generation

This is the core of the sine-wave mode.

## 3. Duty Cycle Selection (duty_sel)
Plain PWM Mode (SW1 = 1)

File: plain_pwm_duty_selection.png

Shows:

duty_plain switching between 25% (64) and 75% (192)

duty_sel following these fixed values

Frequency preset changes through SW3..SW0

Sine Mode (SW1 = 0)

File: sine_mode_sine_samp_waveform.png

Confirms:

duty_sel is fed directly from sine_samp

LEDR1 produces a “breathing” effect in hardware

## 4. PWM Output (pwm_out / ledr1)

File: pwm_output_waveform.png
Shows the high-frequency PWM bitstream generated from duty_sel.
The pulse width varies according to the duty cycle produced by either:

LUT (sine mode), or

Fixed duty values (plain PWM mode)

This verifies correct PWM behaviour.

## 5. Full System Integration

File: full_function_generator_simulation.png
This is the most comprehensive waveform, showing:

Clock and reset

Switch inputs

NCO increment lookup (INC_TAB8)

Phase accumulator (nco_phase)

LUT addressing (sine_addr)

LUT output (sine_samp)

Duty cycle mux (duty_sel)

PWM output

It confirms all subsystems operate correctly together in the final top-level design.

## 6. ModelSim Workspace Overview

File: modelsim_environment_overview.png
Provides a full screenshot of the simulation environment including:

Hierarchy

Loaded signals

Wave window

Testbench configuration

Included for reproducibility and academic documentation.

## Summary

The simulations validate:

Correct NCO frequency stepping

Accurate sine waveform lookup

Reliable PWM generation

Functional switch-controlled mode and frequency selection

Proper integration of all modules

These results fully match the behaviour later observed in hardware testing with LEDs, DAC output, and oscilloscope measurements.
