function [z, p] = corrdiff(r1, r2, n1, n2)

% Fisher's z-transform to normalize correlation coefficients
z1 = 0.5 * log((1 + r1) / (1 - r1));
z2 = 0.5 * log((1 + r2) / (1 - r2));
zdiff = z1 - z2;

% Calculate sigma given the number of trials
se = sqrt((1 / (n1 - 3)) + (1 / (n2 - 3)));

% Get z-score of the differences between correlation coefficients
z = zdiff / se;

% Calculate p-value
p = 1 - normcdf(abs(z));

clear r1 r2 n1 n2 z1 z2 zdiff se

