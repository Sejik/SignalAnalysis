%reference
stimulus.x(1,:) = sin(2*pi*f(class)*stimulus_t);
stimulus.x(2,:) = cos(2*pi*f(class)*stimulus_t);

%CCA
[ A, B, r_classic(class,:), U, V ] = canoncorr(data, stimulus.x);