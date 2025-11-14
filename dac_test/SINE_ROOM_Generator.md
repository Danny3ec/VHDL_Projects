256-Sample 8-Bit Sine ROM – How It Was Generated

This project needs a digital sine wave that is sent to the DAC. Instead of calculating the sine function in real-time inside the FPGA (which is expensive), the design uses a lookup table (ROM) with 256 pre-computed sine values.

📌 Why 256 Samples?

One full sine period is divided into 256 equal steps.

256 = 2⁸ → perfect because the address is an 8-bit counter.

Very efficient for FPGA logic.

📌 Why 8-bit output?

The TLC7524 DAC takes 8-bit unsigned input (0–255).

📌 Converting a sine wave to DAC values

A normal sine wave ranges from:

sin(𝜃)∈[−1, +1]


But the DAC requires:

0≤𝑦≤2550≤y≤255

So we shift + scale:

𝑦𝑘 = round(127.5(1+sin(2𝜋𝑘/256)))

This maps:

+1	255
| Sine Value | Scaled Output |
| ---------- | ------------- |
| -1         | 0             |
| 0          | 128           |
| +1         | 255           |


📌 MATLAB Script Used

The entire lookup table was generated using this MATLAB script:
N = 256;
values = zeros(1, N);

for k = 0:N-1
    angle = 2*pi*(k/N);
    s = sin(angle);
    values(k+1) = round(127.5 * (1 + s));
end

for i = 1:N
    if mod(i-1, 8) == 0, fprintf("    "); end
    fprintf('x"%02X", ', values(i));
    if mod(i-1, 8) == 7, fprintf("\n"); end
end
This prints 256 hex values in the same format used in VHDL:
x"80", x"83", x"86", x"89", ...

📌 Summary

This file is a ROM containing 256 pre-computed sine samples.

Each sample is an 8-bit DAC value.

The FPGA simply cycles through addresses 0→255 to output a continuous sine wave.

MATLAB was used to generate these values mathematically.
