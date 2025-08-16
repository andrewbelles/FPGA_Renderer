%
% Generates sine values for the specified N to be used in a LUT 
%

N = 256; 
k = 0:N-1; 
theta = k * (pi/2) / N; 

% 14 binary digits of decimal precision 
scale = 2^14; 
% Generates lut array 
lut = round(sin(theta) * scale); 

% Convert to 2's complement uint16 to write out as HEX 
lut_uint16 = uint16(mod(int32(lut), 2^16));

% Write to file Xilinx expects for LUT 
fid = fopen('sine_p14_lut.hex', 'w');
for i = 1:(N/4)
    fprintf(fid, 'x\"%04X\", x\"%04X\", x\"%04X\", x\"%04X\"\n', ...
        lut_uint16(i), ...
        lut_uint16(i + 1), ...
        lut_uint16(i + 2), ...
        lut_uint16(i + 3));
end
fclose(fid);