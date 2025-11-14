 generate_sine_rom.m

* This script generates a 256-sample, 8-bit sine lookup table for use in VHDL.
* The output values range from 0 to 255 and match the format:
*       x"80", x"83", ...
*
* HOW IT WORKS:
*   - A sine wave normally ranges from -1 to +1.
*   - The DAC expects an UNSIGNED 8-bit number (0 to 255).
*
*   So we scale and shift the sine wave:
*
*       y(k) = round(127.5 * (1 + sin(2*pi*k/256)))

*  This maps:
*       -1  ->  0
*        0  ->  128
*       +1  ->  255
*
*   The script prints the values in VHDL ROM format.


N = 256;                  % Number of samples (full sine period)
values = zeros(1, N);     % Pre-allocate output vector

for k = 0:N-1
    angle = 2*pi*(k/N);           % angle in radians
    s = sin(angle);               % sine wave: -1 to +1
    y = round(127.5 * (1 + s));   % scale to 0–255
    values(k+1) = y;              % store
end

% Print in VHDL table format
fprintf("SINE_ROM VHDL VALUES:\n\n");

for i = 1:N
    if mod(i-1, 8) == 0
        fprintf("    ");   % indent every line
    end
    
    fprintf('x"%02X", ', values(i));
    
    if mod(i-1, 8) == 7
        fprintf("\n");
    end
end

fprintf("\nDone.\n");
