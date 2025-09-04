% 
% Generates seed values for newton-rhapson's method for root finding 
% Takes high 10 fractional bits from normalized 1.22 to index into  
% Outputs table in 6.17 notation 

N = 1024;                % 10-bit index
scale = 2^17;            % Q6.17 scaling
max_pos = 2^23 - 1;      % max positive for 24-bit signed two's complement

% Precompute LUT values
lut_u24 = zeros(N, 1, 'uint32');
for i = 0:N-1
    % Bin midpoint over [1,2): 1 + (i+0.5)/N
    m = 1 + (i + 0.5) / N;       
    y = 1 / m;                   
    q = round(y * scale);  % scale to Q6.17
    lut_u24(i+1) = uint32(q);
end

fptr = fopen("newton_q6d17.hex", 'w');
for i = 1:4:N
    fprintf(fptr, 'x"%06X", x"%06X", x"%06X", x"%06X",\n', ...
        lut_u24(i), lut_u24(i+1), lut_u24(i+2), lut_u24(i+3));
end

fclose(fptr);
