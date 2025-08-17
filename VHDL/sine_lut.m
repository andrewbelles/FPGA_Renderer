%
% Generates sine values for the specified N to be used in a LUT 
%

N = 4096;
k = 0:N-1;
theta = 2*pi*k/N;

scale = 2^14;
val = sin(theta); 
sval = val * scale; 
s = round(sval);

% Saturate to signed Q1.14 range [−16384, +16383]
s(s >  16383) =  16383;
s(s < -16384) = -16384;

% Two's-complement 16-bit
lut_u16 = typecast(int16(s), 'uint16');

% Write hex for vhdl file  
fid = fopen('sine_p14.hex','w');
for i = 1:4:N
    fprintf(fid,'x"%04X", x"%04X", x"%04X", x"%04X",\n', ...
        lut_u16(i), lut_u16(i+1), lut_u16(i+2), lut_u16(i+3));
end
fclose(fid);
